<#
.SYNOPSIS
    Master karehane ikonunu tüm Android mipmap, Adaptive Icon, Splash ve Web ikonlarına dönüştürür.
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
    param([string]$OutPath, [int]$Width, [int]$Height, [int]$PadPercent = 0)
    $parent = Split-Path -Parent $OutPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $bmp = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $padX = [int]([math]::Round($Width * $PadPercent / 100.0))
    $padY = [int]([math]::Round($Height * $PadPercent / 100.0))
    $drawW = $Width - $padX * 2
    $drawH = $Height - $padY * 2
    $g.DrawImage($src, $padX, $padY, $drawW, $drawH)
    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

try {
    # Master Flutter branding asset
    Save-ResizedPng -OutPath (Join-Path $brandingDir "karehane_icon.png") -Width 512 -Height 512

    # Android Legacy Mipmaps
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-mdpi\ic_launcher.png") -Width 48 -Height 48
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-hdpi\ic_launcher.png") -Width 72 -Height 72
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-xhdpi\ic_launcher.png") -Width 96 -Height 96
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-xxhdpi\ic_launcher.png") -Width 144 -Height 144
    Save-ResizedPng -OutPath (Join-Path $resDir "mipmap-xxxhdpi\ic_launcher.png") -Width 192 -Height 192

    # Android Adaptive Icon Foreground (108dp -> 432px @ xxxhdpi with safe padding)
    Save-ResizedPng -OutPath (Join-Path $resDir "drawable-nodpi\ic_launcher_foreground.png") -Width 432 -Height 432 -PadPercent 8

    # Android Native Splash Logo (centered 260px PNG)
    Save-ResizedPng -OutPath (Join-Path $resDir "drawable-nodpi\splash_logo.png") -Width 260 -Height 260

    # Web icons
    Save-ResizedPng -OutPath (Join-Path $webDir "favicon.png") -Width 64 -Height 64
    Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-192.png") -Width 192 -Height 192
    Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-512.png") -Width 512 -Height 512
    Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-maskable-192.png") -Width 192 -Height 192 -PadPercent 8
    Save-ResizedPng -OutPath (Join-Path $webDir "icons\Icon-maskable-512.png") -Width 512 -Height 512 -PadPercent 8
}
finally {
    $src.Dispose()
}

Write-Host "[OK] Karehane Android Adaptive Icon, Splash ve Web ikonları üretildi!" -ForegroundColor Green
