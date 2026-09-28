param(
    [ValidateSet('auto','whpx','tcg')][string]$Profile,
    [switch]$Install,
    [switch]$Live,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$lock = $null
try {
    if ($Install -and $Live) { throw 'Choisir Install OU Live.' }
    $cfg = Get-Content (Join-Path $root 'config\settings.json') -Raw | ConvertFrom-Json
    $mouseMode = if ($cfg.mouseMode) { $cfg.mouseMode } else { 'absolute' }
    if ($mouseMode -notin @('relative','absolute')) { throw 'mouseMode doit etre relative ou absolute.' }
    if (!$Profile) { $Profile = $cfg.profile }
    if ($Profile -notin @('auto','whpx','tcg')) { throw 'Profil invalide.' }
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'Ce prototype exige Windows x64 Intel/AMD.' }
    if ($cfg.memoryMiB -lt 2048 -or $cfg.memoryMiB -gt 16384 -or $cfg.cpus -lt 1 -or $cfg.cpus -gt 16) { throw 'Configuration RAM/CPU invalide.' }
    $qemu = Join-Path $root 'runtime\qemu\qemu-system-x86_64.exe'
    if (!(Test-Path $qemu)) { throw 'QEMU absent. Voir docs/PREPARATION.md.' }
    New-Item -ItemType Directory -Force (Join-Path $root 'logs'),(Join-Path $root 'vm') | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $log = Join-Path $root "logs\$stamp.txt"
    # Test reel d'initialisation WHPX, sans disque ni fenetre. Aucune fonction Windows activee.
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
        $probe = New-Object Diagnostics.Process
        $probe.StartInfo = $psi
        [void]$probe.Start()
        $errTask = $probe.StandardError.ReadToEndAsync()
        $probeLines = New-Object 'System.Collections.Generic.List[string]'
        $probeOk = $false
        try {
            $probe.StandardInput.NewLine = "`n"
            $greeting = $probe.StandardOutput.ReadLineAsync()
            if (!$greeting.Wait(15000)) { throw 'Delai QMP depasse.' }
            $probeLines.Add($greeting.Result)
            $probe.StandardInput.WriteLine('{"execute":"qmp_capabilities"}')
            $probe.StandardInput.Flush()
            $reply = $probe.StandardOutput.ReadLineAsync()
            if (!$reply.Wait(15000)) { throw 'Delai QMP depasse.' }
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
        if (!$whpx -and $Profile -eq 'whpx') { throw "WHPX indisponible. Virtualisation UEFI, Windows Hypervisor Platform et redemarrage a verifier manuellement. Journal: $log" }
    }
    $selected = if ($Profile -eq 'tcg' -or !$whpx) { 'tcg' } else { 'whpx' }
    Write-Host "Profil: $selected. RAM: $($cfg.memoryMiB) MiB; CPU virtuels: $($cfg.cpus)."
    if ($selected -eq 'tcg') { Write-Warning 'Repli logiciel TCG: demarrage et decodage potentiellement trop lents pour jouer. Aucune fonction Windows modifiee.' }
    if ($CheckOnly) { exit 0 }
    try {
        $freeMiB = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory / 1024
        if ($freeMiB -lt ($cfg.memoryMiB + 1024)) { Write-Warning "RAM libre limitee ($([int]$freeMiB) MiB). Fermer des applications avant le test." }
    } catch { Write-Warning 'RAM libre non verifiable. Prevoir la RAM de la VM plus une marge pour Windows.' }
    $drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($root))
    if ($drive.AvailableFreeSpace -lt 2GB) { throw 'Moins de 2 Go libres. Liberer de la place avant de demarrer.' }
    try { $lock = [IO.File]::Open((Join-Path $root 'vm\session.lock'), 'OpenOrCreate','ReadWrite','None') }
    catch { throw 'Une autre session utilise deja cette VM.' }
    Push-Location $root
    try {
        $disk = 'vm/linux.vmdk'
        if (!$Live -and !(Test-Path $disk)) {
            if (!$Install) { throw 'Linux pas encore installe: lancer Installer-Linux.cmd.' }
            if ($cfg.diskGiB -lt 8 -or $cfg.diskGiB -gt 128) { throw 'Taille du disque invalide.' }
            & (Join-Path $root 'runtime\qemu\qemu-img.exe') create -f vmdk -o subformat=twoGbMaxExtentSparse $disk "$($cfg.diskGiB)G"
            if ($LASTEXITCODE) { throw 'Creation du disque impossible.' }
        }
        $accel = if ($selected -eq 'tcg') { 'tcg,thread=multi' } else { 'whpx' }
        $machine = if ($selected -eq 'whpx') { 'q35,kernel-irqchip=off' } else { 'q35' }
        $arguments = @('-name','Steam USB','-machine',$machine,'-accel',$accel,'-cpu','max',
            '-m',"$($cfg.memoryMiB)",'-smp',"$($cfg.cpus)",
            '-netdev','user,id=net0','-device','virtio-net-pci,netdev=net0',
            '-vga','std','-display','gtk,gl=off',
            '-audiodev','dsound,id=audio0','-device','intel-hda','-device','hda-duplex,audiodev=audio0',
            '-device','qemu-xhci','-nic','none')
        $pointer = if ($mouseMode -eq 'relative') { 'usb-mouse' } else { 'usb-tablet' }
        $arguments += @('-device',$pointer)
        Write-Host "Souris: $mouseMode. Ctrl+Alt+G capture/libere les entrees dans QEMU GTK."
        if (!$Live) { $arguments += @('-drive',"file=$disk,format=vmdk,if=virtio,cache=writeback") }
        if ($Install -or $Live) {
            if ([IO.Path]::GetFileName($cfg.iso) -ne $cfg.iso) { throw 'Nom ISO invalide.' }
            $iso = 'iso/' + $cfg.iso
            if (!(Test-Path $iso)) { throw "ISO absente: $iso" }
            $arguments += @('-cdrom',$iso,'-boot','order=d,menu=on')
        } else { $arguments += @('-boot','order=c') }
        Write-Host 'Arreter depuis le menu Linux. Ne pas fermer brutalement QEMU ni retirer la cle.'
        "Start=$(Get-Date -Format o) Profile=$selected Mouse=$mouseMode" | Add-Content $log
        # Capture native stderr directly: PowerShell 5 must not turn QEMU warnings into terminating errors.
        $runInfo = New-Object Diagnostics.ProcessStartInfo
        $runInfo.FileName = $qemu
        $runInfo.WorkingDirectory = $root
        $runInfo.Arguments = ($arguments | ForEach-Object {
            if ($_ -match '["\r\n]' -or $_.EndsWith('\')) { throw 'Argument QEMU non pris en charge.' }
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
        "End=$(Get-Date -Format o) Exit=$code (ne prouve pas un arret propre Linux)" | Add-Content $log
        if ($code) { throw "QEMU a echoue ($code). Voir $log" }
        Write-Host 'QEMU termine. Verifier extinction Linux, puis ejecter le support dans Windows.'
    } finally { Pop-Location }
} catch { Write-Host "ERREUR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
finally { if ($lock) { $lock.Dispose() } }
