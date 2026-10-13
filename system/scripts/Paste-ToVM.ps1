# "Paste into the VM": reads the Windows clipboard and TYPES it into the active VM window,
# through the local QMP control channel (127.0.0.1). One-way Windows -> VM (a workaround for the clipboard
# that this QEMU-Windows build does not support). The VM must be running with the control channel open
# (started from "Media Center.cmd").
#
# IMPORTANT: typing assumes a US keyboard layout in the VM (character -> US key mapping).
# Before pasting, click the target field in the VM (terminal, address bar, etc.).
param([int]$Port = 4455, [int]$DelayMs = 55)
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
$text = [System.Windows.Forms.Clipboard]::GetText()
if ([string]::IsNullOrEmpty($text)) { Write-Host 'Clipboard is empty (text). Nothing to paste.'; exit 0 }

# Character -> qcode sequence table (US layout).
$map = New-Object 'System.Collections.Generic.Dictionary[char,string[]]'
foreach ($i in 97..122) { $map[[char]$i] = @([string][char]$i) }                 # a-z
foreach ($i in 65..90)  { $map[[char]$i] = @('shift', [string][char]($i + 32)) } # A-Z
foreach ($d in 0..9)    { $map[[char][string]$d] = @([string]$d) }               # 0-9
$map[[char]' ']  = @('spc');           $map[[char]"`t"] = @('tab')
$map[[char]'-']  = @('minus');         $map[[char]'_'] = @('shift','minus')
$map[[char]'=']  = @('equal');         $map[[char]'+'] = @('shift','equal')
$map[[char]'[']  = @('bracket_left');  $map[[char]'{'] = @('shift','bracket_left')
$map[[char]']']  = @('bracket_right'); $map[[char]'}'] = @('shift','bracket_right')
$map[[char]'\']  = @('backslash');     $map[[char]'|'] = @('shift','backslash')
$map[[char]';']  = @('semicolon');     $map[[char]':'] = @('shift','semicolon')
$map[[char]0x27] = @('apostrophe');    $map[[char]'"'] = @('shift','apostrophe')
$map[[char]',']  = @('comma');         $map[[char]'<'] = @('shift','comma')
$map[[char]'.']  = @('dot');           $map[[char]'>'] = @('shift','dot')
$map[[char]'/']  = @('slash');         $map[[char]'?'] = @('shift','slash')
$map[[char]'`']  = @('grave_accent');  $map[[char]'~'] = @('shift','grave_accent')
$map[[char]'!']  = @('shift','1');     $map[[char]'@'] = @('shift','2')
$map[[char]'#']  = @('shift','3');     $map[[char]'$'] = @('shift','4')
$map[[char]'%']  = @('shift','5');     $map[[char]'^'] = @('shift','6')
$map[[char]'&']  = @('shift','7');     $map[[char]'*'] = @('shift','8')
$map[[char]'(']  = @('shift','9');     $map[[char]')'] = @('shift','0')

$c = New-Object Net.Sockets.TcpClient
try { $c.Connect('127.0.0.1', $Port) } catch { Write-Host "Control channel unreachable on 127.0.0.1:$Port. Is the VM running (started from Media Center.cmd)?"; exit 1 }
$s = $c.GetStream(); $r = New-Object IO.StreamReader($s); $w = New-Object IO.StreamWriter($s); $w.NewLine = "`n"; $w.AutoFlush = $true
Start-Sleep -Milliseconds 300; [void]$r.ReadLine(); $w.WriteLine('{"execute":"qmp_capabilities"}'); Start-Sleep -Milliseconds 200; [void]$r.ReadLine()

function Send-Qcodes([string[]]$names) {
  $keys = ($names | ForEach-Object { '{"type":"qcode","data":"' + $_ + '"}' }) -join ','
  $w.WriteLine('{"execute":"send-key","arguments":{"keys":[' + $keys + ']}}'); [void]$r.ReadLine()
  Start-Sleep -Milliseconds $DelayMs
}

$skipped = 0
foreach ($ch in [char[]]$text) {
  if ($ch -eq "`r") { continue }
  if ($ch -eq "`n") { Send-Qcodes @('ret'); continue }
  if ($map.ContainsKey($ch)) { Send-Qcodes $map[$ch] } else { $skipped++ }
}
$c.Close()
$n = ($text -replace "`r", '').Length
Write-Host "Pasted $n character(s) into the VM.$(if($skipped){" $skipped unsupported (non-ASCII) character(s) skipped."})"
