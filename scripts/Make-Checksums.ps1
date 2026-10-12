# Genere un fichier SHA256SUMS compatible `sha256sum -c`, avec des fins de ligne LF.
#
# Raison d'etre : genere a la main sous Windows, SHA256SUMS herite de fins de ligne CRLF.
# Le `\r` invisible casse l'ancre `$` d'un `grep '...$'` et fait echouer la verification
# sous Linux ("no properly formatted checksum lines found"). Ce script force du LF.
#
# Usage :
#   powershell -File scripts\Make-Checksums.ps1                 # tous les fichiers du dossier courant
#   powershell -File scripts\Make-Checksums.ps1 -Files a.zip,b.tar.gz
#   powershell -File scripts\Make-Checksums.ps1 -Directory .\release -OutFile .\release\SHA256SUMS
param(
    [string[]]$Files,
    [string]$Directory = '.',
    [string]$OutFile
)
$ErrorActionPreference = 'Stop'
if (-not $OutFile) { $OutFile = Join-Path $Directory 'SHA256SUMS' }

if (-not $Files -or $Files.Count -eq 0) {
    # Tous les fichiers du dossier, en excluant le SHA256SUMS lui-meme.
    $outName = [IO.Path]::GetFileName($OutFile)
    $Files = Get-ChildItem -File -Path $Directory |
        Where-Object { $_.Name -ne $outName } |
        ForEach-Object { $_.FullName }
}
if (-not $Files -or $Files.Count -eq 0) { throw 'Aucun fichier a sommer.' }

$lines = foreach ($f in $Files) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Fichier introuvable : $f" }
    $hash = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLower()
    $name = [IO.Path]::GetFileName($f)
    # Format sha256sum : <hash><2 espaces><nom de fichier>
    "$hash  $name"
}

# Ecrire en UTF-8 sans BOM, avec des fins de ligne LF uniquement, et un LF final.
$text = ($lines -join "`n") + "`n"
[IO.File]::WriteAllText($OutFile, $text, (New-Object Text.UTF8Encoding($false)))
Write-Host "SHA256SUMS ecrit (LF) : $OutFile"
$lines | ForEach-Object { Write-Host "  $_" }
