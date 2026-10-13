param(
    [ValidateSet('auto','whpx','tcg')][string]$Profile,
    [switch]$Install,
    [switch]$Live,
    [switch]$Gaming,
    [switch]$Control,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$lock = $null
try {
    if ($Install -and $Live) { throw 'Choose Install OR Live, not both.' }
    if ($Gaming -and ($Install -or $Live)) { throw 'Gaming mode only applies to a normal start (not Install/Live).' }
    $cfg = Get-Content (Join-Path $root 'config\settings.json') -Raw | ConvertFrom-Json
    $mouseMode = if ($cfg.mouseMode) { $cfg.mouseMode } else { 'absolute' }
    if ($mouseMode -notin @('relative','absolute')) { throw 'mouseMode must be relative or absolute.' }
    # Gaming mode: relative mouse is mandatory (clean deltas for an FPS camera), whatever the config says.
    if ($Gaming) { $mouseMode = 'relative' }
    if (!$Profile) { $Profile = $cfg.profile }
    if ($Profile -notin @('auto','whpx','tcg')) { throw 'Invalid profile.' }
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'This prototype requires 64-bit Windows on Intel/AMD.' }
    if ($cfg.memoryMiB -lt 2048 -or $cfg.memoryMiB -gt 16384 -or $cfg.cpus -lt 1 -or $cfg.cpus -gt 16) { throw 'Invalid RAM/CPU configuration.' }
    $qemu = Join-Path $root 'runtime\qemu\qemu-system-x86_64.exe'
    if (!(Test-Path $qemu)) { throw 'QEMU is missing. See system/docs/SETUP.md.' }
    New-Item -ItemType Directory -Force (Join-Path $root 'logs'),(Join-Path $root 'vm') | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $log = Join-Path $root "logs\$stamp.txt"
    # Real WHPX init test, with no disk and no window. No Windows feature is turned on.
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $qemu
    $psi.Arguments = '-machine q35,kernel-irqchip=off -accel whpx -cpu max -m 256 -nodefaults -display none -qmp stdio -monitor none -serial none -S'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $whpx = $false
    if ($Profile -ne 'tcg') {
        # The stdin StreamWriter inherits Console.InputEncoding; in UTF-8 WITH a BOM it prefixes a BOM that QMP
        # rejects ("stray <byte>"), wrongly failing WHPX detection. Force a BOM-less encoding around the probe.
        $prevInEnc = $null
        try { $prevInEnc = [Console]::InputEncoding; [Console]::InputEncoding = New-Object Text.UTF8Encoding($false) } catch {}
        $probe = New-Object Diagnostics.Process
        $probe.StartInfo = $psi
        [void]$probe.Start()
        $errTask = $probe.StandardError.ReadToEndAsync()
        $probeLines = New-Object 'System.Collections.Generic.List[string]'
        $probeOk = $false
        try {
            $probe.StandardInput.NewLine = "`n"
            $greeting = $probe.StandardOutput.ReadLineAsync()
            if (!$greeting.Wait(15000)) { throw 'QMP timeout.' }
            $probeLines.Add($greeting.Result)
            $probe.StandardInput.WriteLine('{"execute":"qmp_capabilities"}')
            $probe.StandardInput.Flush()
            $reply = $probe.StandardOutput.ReadLineAsync()
            if (!$reply.Wait(15000)) { throw 'QMP timeout.' }
            $probeLines.Add($reply.Result)
            $probeOk = $reply.Result -match '"return"'
            $probe.StandardInput.WriteLine('{"execute":"quit"}')
            $probe.StandardInput.Flush()
        } catch {
            $probeLines.Add($_.Exception.Message)
            if (!$probe.HasExited) { $probe.Kill(); $probe.WaitForExit() }
        }
        $outTask = $probe.StandardOutput.ReadToEndAsync()
        if (!$probe.WaitForExit(15000)) { $probe.Kill(); $probe.WaitForExit() }
        $probeText = ($probeLines -join "`n") + $outTask.GetAwaiter().GetResult() + $errTask.GetAwaiter().GetResult()
        $whpx = ($probe.ExitCode -eq 0 -and $probeOk)
        $probeText | Set-Content $log
        $probe.Dispose()
        if ($prevInEnc) { try { [Console]::InputEncoding = $prevInEnc } catch {} }
        if (!$whpx -and $Profile -eq 'whpx') { throw "WHPX unavailable. Check UEFI virtualization, Windows Hypervisor Platform, and reboot manually. Log: $log" }
    }
    $selected = if ($Profile -eq 'tcg' -or !$whpx) { 'tcg' } else { 'whpx' }
    Write-Host "Profile: $selected. RAM: $($cfg.memoryMiB) MiB; virtual CPUs: $($cfg.cpus)."
    if ($selected -eq 'tcg') { Write-Warning 'Software TCG fallback: startup and decoding may be too slow to play. No Windows feature changed.' }
    if ($CheckOnly) { exit 0 }
    try {
        $freeMiB = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory / 1024
        if ($freeMiB -lt ($cfg.memoryMiB + 1024)) { Write-Warning "Limited free RAM ($([int]$freeMiB) MiB). Close some apps before starting." }
    } catch { Write-Warning 'Free RAM could not be checked. Plan for the VM RAM plus headroom for Windows.' }
    $drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($root))
    if ($drive.AvailableFreeSpace -lt 2GB) { throw 'Less than 2 GB free. Free up space before starting.' }
    try { $lock = [IO.File]::Open((Join-Path $root 'vm\session.lock'), 'OpenOrCreate','ReadWrite','None') }
    catch { throw 'Another session is already using this VM.' }
    Push-Location $root
    try {
        $disk = 'vm/linux.vmdk'
        if (!$Live -and !(Test-Path $disk)) {
            if (!$Install) { throw 'Linux is not installed yet: open "Media Center.cmd" and choose First-time setup.' }
            if ($cfg.diskGiB -lt 8 -or $cfg.diskGiB -gt 128) { throw 'Invalid disk size.' }
            & (Join-Path $root 'runtime\qemu\qemu-img.exe') create -f vmdk -o subformat=twoGbMaxExtentSparse $disk "$($cfg.diskGiB)G"
            if ($LASTEXITCODE) { throw 'Could not create the disk.' }
        }
        $accel = if ($selected -eq 'tcg') { 'tcg,thread=multi' } else { 'whpx' }
        $machine = if ($selected -eq 'whpx') { 'q35,kernel-irqchip=off' } else { 'q35' }
        # Gaming mode: SDL backend (native Windows pointer lock) confines the mouse reliably, including on
        # multi-monitor setups where GTK lets the cursor escape to the other screen. Otherwise GTK for desktop use.
        $display = if ($Gaming) { 'sdl,gl=off' } else { 'gtk,gl=off' }
        $arguments = @('-name','Steam USB','-machine',$machine,'-accel',$accel,'-cpu','max',
            '-m',"$($cfg.memoryMiB)",'-smp',"$($cfg.cpus)",
            '-netdev','user,id=net0','-device','virtio-net-pci,netdev=net0',
            '-display',$display,
            '-audiodev','dsound,id=audio0','-device','intel-hda','-device','hda-duplex,audiodev=audio0',
            '-device','qemu-xhci','-nic','none')
        # VGA: in gaming mode, EDID forces 1920x1080 as the preferred mode -> the guest renders natively in 1080p,
        # so fullscreen is crisp 1:1 (no upscaling of 1280x800) and mouse coordinates are correct. Otherwise std.
        if ($Gaming) { $arguments += @('-device','VGA,edid=on,xres=1920,yres=1080') }
        else { $arguments += @('-vga','std') }
        # Local control channel (loopback 127.0.0.1 only) for the "Paste into the VM" tool (Paste-ToVM.ps1).
        # No network exposure, no admin, no install. Only opened when -Control is passed.
        if ($Control) { $arguments += @('-qmp','tcp:127.0.0.1:4455,server,nowait') }
        $pointer = if ($mouseMode -eq 'relative') { 'usb-mouse' } else { 'usb-tablet' }
        $arguments += @('-device',$pointer)
        if ($Gaming) {
            $arguments += '-full-screen'
            Write-Host 'Gaming mode: SDL fullscreen, relative mouse locked. Ctrl+Alt+G releases the mouse; Ctrl+Alt+F leaves fullscreen.'
        } else {
            Write-Host "Mouse: $mouseMode. Ctrl+Alt+G grabs/releases input in QEMU GTK."
        }
        if (!$Live) { $arguments += @('-drive',"file=$disk,format=vmdk,if=virtio,cache=writeback") }
        if ($Install -or $Live) {
            if ([IO.Path]::GetFileName($cfg.iso) -ne $cfg.iso) { throw 'Invalid ISO name.' }
            $iso = 'iso/' + $cfg.iso
            if (!(Test-Path $iso)) { throw "ISO not found: $iso" }
            $arguments += @('-cdrom',$iso,'-boot','order=d,menu=on')
        } else { $arguments += @('-boot','order=c') }
        Write-Host 'Shut down from the Linux menu. Do not force-close QEMU or pull out the drive.'
        "Start=$(Get-Date -Format o) Profile=$selected Mouse=$mouseMode Gaming=$($Gaming.IsPresent) Display=$display" | Add-Content $log
        # Capture native stderr directly: PowerShell 5 must not turn QEMU warnings into terminating errors.
        $runInfo = New-Object Diagnostics.ProcessStartInfo
        $runInfo.FileName = $qemu
        $runInfo.WorkingDirectory = $root
        $runInfo.Arguments = ($arguments | ForEach-Object {
            if ($_ -match '["\r\n]' -or $_.EndsWith('\')) { throw 'Unsupported QEMU argument.' }
            '"' + $_ + '"'
        }) -join ' '
        $runInfo.UseShellExecute = $false
        $runInfo.CreateNoWindow = $true
        $runInfo.RedirectStandardError = $true
        $runInfo.RedirectStandardOutput = $true
        $vm = New-Object Diagnostics.Process
        $vm.StartInfo = $runInfo
        [void]$vm.Start()
        $vmOut = $vm.StandardOutput.ReadToEndAsync()
        $vmErr = $vm.StandardError.ReadToEndAsync()
        $vm.WaitForExit()
        $vmOut.GetAwaiter().GetResult() | Add-Content $log
        $vmErr.GetAwaiter().GetResult() | Add-Content $log
        $code = $vm.ExitCode
        $vm.Dispose()
        "End=$(Get-Date -Format o) Exit=$code (does not prove a clean Linux shutdown)" | Add-Content $log
        if ($code) { throw "QEMU failed ($code). See $log" }
        Write-Host 'QEMU finished. Confirm Linux shut down, then eject the drive in Windows.'
    } finally { Pop-Location }
} catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
finally { if ($lock) { $lock.Dispose() } }
