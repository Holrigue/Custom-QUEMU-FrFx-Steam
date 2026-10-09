# "Coller dans la VM" : lit le presse-papiers Windows et le TAPE dans la fenetre active de la VM,
# via le canal de controle local QMP (127.0.0.1). Sens unique Windows -> VM (contournement du presse-papiers
# non supporte par ce build QEMU-Windows). La VM doit tourner avec le canal de controle (Jouer-Presse-papiers.cmd).
#
# IMPORTANT : la frappe suppose la disposition clavier US dans la VM (mapping caractere -> touche US).
# Avant de coller, clique dans le champ cible de la VM (terminal, barre d'adresse, etc.).
param([int]$Port = 4455, [int]$DelayMs = 55)
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
$text = [System.Windows.Forms.Clipboard]::GetText()
if ([string]::IsNullOrEmpty($text)) { Write-Host 'Presse-papiers vide (texte). Rien a coller.'; exit 0 }

# Table caractere -> sequence de qcodes (disposition US).
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
try { $c.Connect('127.0.0.1', $Port) } catch { Write-Host "Canal de controle injoignable sur 127.0.0.1:$Port. La VM tourne-t-elle via Jouer-Presse-papiers.cmd ?"; exit 1 }
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
Write-Host "Colle $n caractere(s) dans la VM.$(if($skipped){" $skipped non pris en charge (hors ASCII) ignore(s)."})"
