<#
.SYNOPSIS
    eKare Bulmaca (fatalsoft.bulmaca) imzali Google Play AAB ve Release APK derleme betigi.
.DESCRIPTION
    1) android/key.properties ve upload keystore varligini dogrular (imzasiz yayin engellenir).
    2) Windows Turkce 'Ş' karakter kisiti icin ust klasoru gecici ASCII surucuye baglar.
    3) Google Play Console icin imzali App Bundle (.aab) ve cihaz testi icin imzali APK (.apk) uretir.
    4) jarsigner ile AAB imzasini dogrular ve gecici surucuyu temizler.
#>

$ErrorActionPreference = "Stop"
$projectDir = Split-Path -Parent $PSScriptRoot
$parentDir = Split-Path -Parent $projectDir
$projectName = Split-Path -Leaf $projectDir

$keyPropsPath = Join-Path $projectDir "android\key.properties"
if (-not (Test-Path $keyPropsPath)) {
    throw "Imzalama yapilandirmasi bulunamadi: $keyPropsPath`nOnce keystore olusturulmalidir."
}

# Bos bir surucu harfi sec
$usedDrives = (Get-PSDrive -PSProvider FileSystem).Name
$driveLetter = $null
foreach ($letter in @('Z','Y','X','W','V','U','T','S','R','Q','P','K')) {
    if ($usedDrives -notcontains $letter) {
        $driveLetter = "${letter}:"
        break
    }
}
if (-not $driveLetter) {
    throw "Gecici derleme icin bos surucu harfi bulunamadi."
}

Write-Host "Klasor gecici surucuye baglaniyor: $driveLetter -> $parentDir" -ForegroundColor Cyan
subst $driveLetter "$parentDir"
if ($LASTEXITCODE -ne 0) {
    throw "subst komutu basarisiz oldu."
}

try {
    Push-Location "$driveLetter\$projectName"
    # Onceki derlemeden farkli bir gecici surucu harfine ait flutter_build.d
    # kaldiysa Gradle PreCreateOutputParentsStep hatasini onlemek icin temizle.
    $staleFlutterIntermediates = Join-Path "$driveLetter\$projectName" "build\app\intermediates\flutter"
    if (Test-Path $staleFlutterIntermediates) {
        Remove-Item -Recurse -Force $staleFlutterIntermediates
    }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "`n[1/2] Google Play imzali App Bundle (.aab) derleniyor..." -ForegroundColor Cyan
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "`n[2/2] Imzali Android Release APK (.apk) derleniyor..." -ForegroundColor Cyan
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
    subst $driveLetter /D | Out-Null
    Write-Host "Gecici surucu ($driveLetter) temizlendi." -ForegroundColor DarkGray
}

$aabPath = Join-Path $projectDir "build\app\outputs\bundle\release\app-release.aab"
$apkPath = Join-Path $projectDir "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $aabPath) {
    $aabMb = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
    Write-Host "`n[OK] Google Play AAB hazir: $aabPath ($aabMb MB)" -ForegroundColor Green
    $jarsigner = Get-Command jarsigner -ErrorAction SilentlyContinue
    if ($jarsigner) {
        & $jarsigner.Source -verify -certs "$aabPath" | Select-String -Pattern "jar verified|CN=FatalSoft"
    }
}
if (Test-Path $apkPath) {
    $apkMb = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Host "[OK] Imzali APK hazir:      $apkPath ($apkMb MB)" -ForegroundColor Green
}
