<#
.SYNOPSIS
    Master eKare Bulmaca gazete kağıdı ikonunu tüm Android mipmap, Adaptive Icon, Splash ve Web ikonlarına dönüştürür.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceImage
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectDir = Split-Path -Parent $PSScriptRoot
$resDir = Join-Path $projectDir "android\app\src\main\res"
$webDir = Join-Path $projectDir "web"
$brandingDir = Join-Path $projectDir "assets\branding"
New-Item -ItemType Directory -Force -Path $brandingDir | Out-Null

$src = [System.Drawing.Image]::FromFile($SourceImage)

function Save-ResizedPng {
    param(
        [string]$OutPath,
        [int]$Width,
        [int]$Height,
        [int]$PadPercent = 0,
        [int]$CropPercent = 0
    )
    $parent = Split-Path -Parent $OutPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $bmp = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $cropX = [int]([math]::Round($src.Width * $CropPercent / 100.0))
    $cropY = [int]([math]::Round($src.Height * $CropPercent / 100.0))
    $srcRect = New-Object System.Drawing.Rectangle($cropX, $cropY, ($src.Width - $cropX * 2), ($src.Height - $cropY * 2))

    $padX = [int]([math]::Round($Width * $PadPercent / 100.0))
    $padY = [int]([math]::Round($Height * $PadPercent / 100.0))
    $dstRect = New-Object System.Drawing.Rectangle($padX, $padY, ($Width - $padX * 2), ($Height - $padY * 2))

    $g.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

try {
    # Master Flutter in-app icon (hafif %11 kenar kırpma ile 42dp başlıkta çok net 3x3 ızgara)
    Save-ResizedPng -OutPath (Join-Path $brandingDir "ekare_icon.png") -Width 512 -Height 512 -CropPercent 11
    Remove-Item -Path (Join-Path $brandingDir "karehane_icon.png") -ErrorAction SilentlyContinue

    # Android Legacy Mipmaps (sıkı %9 kırpma ile ana ekranda keskin okunurluk)
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-mdpi\ic_launcher.png") -Width 48 -Height 48 -CropPercent 9
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-hdpi\ic_launcher.png") -Width 72 -Height 72 -CropPercent 9
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-xhdpi\ic_launcher.png") -Width 96 -Height 96 -CropPercent 9
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-xxhdpi\ic_launcher.png") -Width 144 -Height 144 -CropPercent 9
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-xxxhdpi\ic_launcher.png") -Width 192 -Height 192 -CropPercent 9

    # Android Adaptive Icon Foreground (ızgara zaten %64 güvenli alanda, 0 kırpma ile tam uyum)
    Save-ResizedPng -OutPath (Join-Path $resDir "drawable-nodpi\ic_launcher_foreground.png") -Width 432 -Height 432 -PadPercent 0

    # Android Native Splash Logo (centered 260px PNG)
    Save-ResizedPng -OutPath (Join-Path $resDir "drawable-nodpi\splash_logo.png") -Width 260 -Height 260 -CropPercent 10

    # Web icons (varsa)
    if (Test-Path $webDir) {
        Save-ResizedPng -OutPath (Join-Path $webDir "favicon.png") -Width 64 -Height 64 -CropPercent 10
        Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-192.png") -Width 192 -Height 192 -CropPercent 9
        Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-512.png") -Width 512 -Height 512 -CropPercent 9
        Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-maskable-192.png") -Width 192 -Height 192
        Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-maskable-512.png") -Width 512 -Height 512
    }
}
finally {
    $src.Dispose()
}

Write-Host "[OK] eKare Bulmaca Android Adaptive Icon, Splash ve Web ikonları üretildi!" -ForegroundColor Green
