<#
.SYNOPSIS
    Konsept Bulmaca Android Release APK derleme betiği.
.DESCRIPTION
    Windows üzerinde Dart AOT snapshot aracının (gen_snapshot) klasör yolundaki
    Türkçe 'Ş' karakteriyle (Şahsi) yaşadığı bilinen kısıtı aşmak için üst
    klasörü geçici bir ASCII sürücü harfine bağlar, release APK'yı üretir
    ve işlem sonunda sürücü bağını temizler.
#>

$ErrorActionPreference = "Stop"
$projectDir = Split-Path -Parent $PSScriptRoot
$parentDir = Split-Path -Parent $projectDir
$projectName = Split-Path -Leaf $projectDir

# Boş bir sürücü harfi seç (Z'den geriye doğru)
$usedDrives = (Get-PSDrive -PSProvider FileSystem).Name
$driveLetter = $null
foreach ($letter in @('Z','Y','X','W','V','U','T','S','R','Q','P','K')) {
    if ($usedDrives -notcontains $letter) {
        $driveLetter = "${letter}:"
        break
    }
}

if (-not $driveLetter) {
    throw "Geçici derleme için boş sürücü harfi bulunamadı."
}

Write-Host "Klasör geçici sürücüye bağlanıyor: $driveLetter -> $parentDir" -ForegroundColor Cyan
subst $driveLetter "$parentDir"
if ($LASTEXITCODE -ne 0) {
    throw "subst komutu başarısız oldu."
}

try {
    Push-Location "$driveLetter\$projectName"
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
    subst $driveLetter /D | Out-Null
    Write-Host "Geçici sürücü ($driveLetter) temizlendi." -ForegroundColor DarkGray
}

$apkPath = Join-Path $projectDir "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $sizeMb = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Host "APK hazır: $apkPath ($sizeMb MB)" -ForegroundColor Green
}
