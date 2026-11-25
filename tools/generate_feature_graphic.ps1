<#
.SYNOPSIS
    eKare Bulmaca (fatalsoft.bulmaca) icin Google Play 1024x500 Ozellik Grafigi
    (Feature Graphic) ve magaza yukleme paketini uretir.
#>

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectDir = Split-Path -Parent $PSScriptRoot
$storeDir = Join-Path $projectDir "store_listing"
$storeShotsDir = Join-Path $storeDir "screenshots"
New-Item -ItemType Directory -Force -Path $storeDir | Out-Null
New-Item -ItemType Directory -Force -Path $storeShotsDir | Out-Null

$iconPath = Join-Path $projectDir "assets\branding\ekare_icon.png"
$homeShotPath = Join-Path $projectDir "tools\screenshots\screen_01_home.png"
$gameShotPath = Join-Path $projectDir "tools\screenshots\screen_08_mega_15x15_combo.png"
$fontDir = "C:\src\flutter\bin\cache\artifacts\material_fonts"

# PrivateFontCollection ile gercek Android Roboto fontlarini yukle
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
foreach ($f in @("roboto-regular.ttf", "roboto-medium.ttf", "roboto-bold.ttf", "roboto-black.ttf")) {
    $fp = Join-Path $fontDir $f
    if (Test-Path $fp) { $pfc.AddFontFile($fp) }
}
$robotoFamily = if ($pfc.Families.Count -gt 0) { $pfc.Families[0] } else { New-Object System.Drawing.FontFamily("Segoe UI") }

function New-RoundedRectPath {
    param([float]$X, [float]$Y, [float]$W, [float]$H, [float]$R)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $R * 2
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

$W = 1024
$H = 500
$bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Renk Paleti (Gazete Kagidi, Derin Murekkep & Antik Altin)
$cPaper     = [System.Drawing.Color]::FromArgb(244, 239, 228)
$cPaperDark = [System.Drawing.Color]::FromArgb(234, 226, 211)
$cInk       = [System.Drawing.Color]::FromArgb(24, 21, 18)
$cInkSoft   = [System.Drawing.Color]::FromArgb(88, 79, 69)
$cInkMuted  = [System.Drawing.Color]::FromArgb(132, 121, 108)
$cHairline  = [System.Drawing.Color]::FromArgb(215, 204, 185)
$cBrass     = [System.Drawing.Color]::FromArgb(168, 85, 19)
$cBrassSoft = [System.Drawing.Color]::FromArgb(251, 241, 222)
$cBrassLine = [System.Drawing.Color]::FromArgb(224, 194, 146)

try {
    # 1) Sicak gazete kagidi gradyan zemin
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)),
        (New-Object System.Drawing.Point($W, $H)),
        $cPaper,
        $cPaperDark
    )
    $g.FillRectangle($bgBrush, 0, 0, $W, $H)
    $bgBrush.Dispose()

    # 2) Hafif editoryal gazete bulmaca izgara dokusu (arka planda cok yumusak)
    $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(22, 24, 21, 18), 1.0)
    $blockBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(14, 24, 21, 18))
    $cell = 34
    for ($gx = 0; $gx -lt $W; $gx += $cell) {
        $g.DrawLine($gridPen, $gx, 0, $gx, $H)
    }
    for ($gy = 0; $gy -lt $H; $gy += $cell) {
        $g.DrawLine($gridPen, 0, $gy, $W, $gy)
    }
    foreach ($pos in @(@(0,0), @(1,4), @(3,13), @(15,1), @(17,12), @(28,2), @(26,11), @(12,13))) {
        $g.FillRectangle($blockBrush, $pos[0] * $cell, $pos[1] * $cell, $cell, $cell)
    }
    $gridPen.Dispose()
    $blockBrush.Dispose()

    # 3) Gazete ust ve alt cift murekkep cizgisi (cerceve hissi)
    $inkThickPen = New-Object System.Drawing.Pen($cInk, 3.0)
    $inkThinPen  = New-Object System.Drawing.Pen($cInk, 1.0)
    $g.DrawLine($inkThickPen, 36, 26, $W - 36, 26)
    $g.DrawLine($inkThinPen,  36, 32, $W - 36, 32)
    $g.DrawLine($inkThinPen,  36, $H - 32, $W - 36, $H - 32)
    $g.DrawLine($inkThickPen, 36, $H - 26, $W - 36, $H - 26)

    # 4) Sol Kolon: Marka, Gazete Logosu, Baslik ve Rozetler
    $kickerFont = New-Object System.Drawing.Font($robotoFamily, 11.5, [System.Drawing.FontStyle]::Bold)
    $kickerBrush = New-Object System.Drawing.SolidBrush($cBrass)
    $g.DrawString("FATALSOFT INC.   •   KONSEPT KARE BULMACA", $kickerFont, $kickerBrush, 52, 54)

    # Logo kutusu (88x88 siyah murekkep cerceveli)
    $iconImg = [System.Drawing.Image]::FromFile($iconPath)
    $logoX = 52; $logoY = 96; $logoSize = 96
    $logoClip = New-RoundedRectPath -X $logoX -Y $logoY -W $logoSize -H $logoSize -R 16
    $g.SetClip($logoClip)
    $g.DrawImage($iconImg, $logoX, $logoY, $logoSize, $logoSize)
    $g.ResetClip()
    $logoBorderPen = New-Object System.Drawing.Pen($cInk, 2.2)
    $g.DrawPath($logoBorderPen, $logoClip)
    $logoBorderPen.Dispose()
    $logoClip.Dispose()
    $iconImg.Dispose()

    # Ana Baslik: eKare Bulmaca
    $titleFont = New-Object System.Drawing.Font($robotoFamily, 38, [System.Drawing.FontStyle]::Bold)
    $inkBrush = New-Object System.Drawing.SolidBrush($cInk)
    $g.DrawString("eKare", $titleFont, $inkBrush, 166, 90)
    $subTitleFont = New-Object System.Drawing.Font($robotoFamily, 30, [System.Drawing.FontStyle]::Bold)
    $g.DrawString("Bulmaca", $subTitleFont, $inkBrush, 168, 144)

    # Ince ayirici cizgi
    $hairPen = New-Object System.Drawing.Pen($cHairline, 1.5)
    $g.DrawLine($hairPen, 52, 220, 565, 220)
    $hairPen.Dispose()

    # Aciklama satirlari
    $leadFont = New-Object System.Drawing.Font($robotoFamily, 16.5, [System.Drawing.FontStyle]::Bold)
    $bodyFont = New-Object System.Drawing.Font($robotoFamily, 13.5, [System.Drawing.FontStyle]::Regular)
    $softBrush = New-Object System.Drawing.SolidBrush($cInkSoft)
    $mutedBrush = New-Object System.Drawing.SolidBrush($cInkMuted)

    $g.DrawString("Gazete bulmacası tadında modern kelime dünyası.", $leadFont, $inkBrush, 52, 238)
    $g.DrawString("Yeşilçam  •  İngilizce (A1–B1)  •  Türkiye & Mutfak  •  Genel Kültür", $bodyFont, $softBrush, 52, 274)

    # 3 temiz editoryal ozellik etiketi
    $pillFont = New-Object System.Drawing.Font($robotoFamily, 12, [System.Drawing.FontStyle]::Bold)
    $pills = @(
        @{ Text = "117 Benzersiz Bulmaca"; Dark = $true },
        @{ Text = "90sn Mini Sprint"; Dark = $false },
        @{ Text = "EN–TR Sözlük"; Dark = $false }
    )
    $px = 52
    $py = 326
    foreach ($p in $pills) {
        $sz = $g.MeasureString($p.Text, $pillFont)
        $pw = [int][math]::Ceiling($sz.Width) + 28
        $ph = 40
        $pPath = New-RoundedRectPath -X $px -Y $py -W $pw -H $ph -R 10
        if ($p.Dark) {
            $b = New-Object System.Drawing.SolidBrush($cInk)
            $g.FillPath($b, $pPath)
            $b.Dispose()
            $tb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 198, 92))
            $g.DrawString($p.Text, $pillFont, $tb, $px + 14, $py + 10)
            $tb.Dispose()
        } else {
            $b = New-Object System.Drawing.SolidBrush($cBrassSoft)
            $g.FillPath($b, $pPath)
            $b.Dispose()
            $bp = New-Object System.Drawing.Pen($cBrassLine, 1.4)
            $g.DrawPath($bp, $pPath)
            $bp.Dispose()
            $g.DrawString($p.Text, $pillFont, $inkBrush, $px + 14, $py + 10)
        }
        $pPath.Dispose()
        $px += $pw + 12
    }

    # Alt kucuk bilgi satiri
    $footFont = New-Object System.Drawing.Font($robotoFamily, 11.0, [System.Drawing.FontStyle]::Bold)
    $g.DrawString("İnternetsiz (Çevrimdışı)  •  0 Kelime Tekrarı  •  5×5'ten 20×20'ye Dev Tahtalar", $footFont, $mutedBrush, 52, 404)

    # 5) Sag Kolon: Iki Sik Telefon Onizlemesi (Ana Ekran + Oyun Tahtasi)
    function Draw-PhoneMockup {
        param([string]$ImgPath, [int]$X, [int]$Y, [int]$W, [int]$H)
        # Yumusak golge
        $shPath = New-RoundedRectPath -X ($X + 6) -Y ($Y + 10) -W $W -H $H -R 24
        $shBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(46, 24, 21, 18))
        $g.FillPath($shBrush, $shPath)
        $shBrush.Dispose()
        $shPath.Dispose()

        # Siyah cerceve
        $framePath = New-RoundedRectPath -X $X -Y $Y -W $W -H $H -R 22
        $fBrush = New-Object System.Drawing.SolidBrush($cInk)
        $g.FillPath($fBrush, $framePath)
        $fBrush.Dispose()

        # Ekran goruntusu
        $pad = 6
        $scrPath = New-RoundedRectPath -X ($X + $pad) -Y ($Y + $pad) -W ($W - $pad * 2) -H ($H - $pad * 2) -R 17
        $img = [System.Drawing.Image]::FromFile($ImgPath)
        $g.SetClip($scrPath)
        $g.DrawImage($img, ($X + $pad), ($Y + $pad), ($W - $pad * 2), ($H - $pad * 2))
        $g.ResetClip()
        $img.Dispose()
        $scrPath.Dispose()

        $fPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 255, 255, 255), 1.0)
        $g.DrawPath($fPen, $framePath)
        $fPen.Dispose()
        $framePath.Dispose()
    }

    # Arka sag telefon: 15x15 Dev Bulmaca + Canli 2x Kombo
    if (Test-Path $gameShotPath) {
        Draw-PhoneMockup -ImgPath $gameShotPath -X 792 -Y 66 -W 182 -H 378
    }
    # On sol telefon: Yeni Editoryal Ana Ekran
    if (Test-Path $homeShotPath) {
        Draw-PhoneMockup -ImgPath $homeShotPath -X 626 -Y 46 -W 192 -H 398
    }

    # 1024x500 PNG kaydet
    $outFeature = Join-Path $storeDir "feature_graphic_1024x500.png"
    $bmp.Save($outFeature, [System.Drawing.Imaging.ImageFormat]::Png)

    # 512x512 magaza ikonu ve 6 secme ekran goruntusunu store_listing altina kopyala
    Copy-Item -Path $iconPath -Destination (Join-Path $storeDir "app_icon_512x512.png") -Force
    $shotMap = @(
        @("screen_01_home.png",             "01_ana_ekran.png"),
        @("screen_05_wrong_word_check.png", "02_bulmaca_ve_kontrol.png"),
        @("screen_11_word_notebook.png",    "03_ingilizce_turkce_sozluk.png"),
        @("screen_10_mini_sprint.png",      "04_90sn_mini_sprint.png"),
        @("screen_08_mega_15x15_combo.png", "05_dev_15x15_kombo.png"),
        @("screen_04_backgrounds.png",      "06_arka_plan_temalari.png")
    )
    foreach ($pair in $shotMap) {
        $srcShot = Join-Path $projectDir ("tools\screenshots\" + $pair[0])
        if (Test-Path $srcShot) {
            Copy-Item -Path $srcShot -Destination (Join-Path $storeShotsDir $pair[1]) -Force
        }
    }

    Write-Host "[OK] Feature Graphic (1024x500) ve store_listing paketi hazir: $outFeature" -ForegroundColor Green
}
finally {
    $inkThickPen.Dispose()
    $inkThinPen.Dispose()
    $kickerFont.Dispose()
    $kickerBrush.Dispose()
    $titleFont.Dispose()
    $subTitleFont.Dispose()
    $leadFont.Dispose()
    $bodyFont.Dispose()
    $pillFont.Dispose()
    $footFont.Dispose()
    $inkBrush.Dispose()
    $softBrush.Dispose()
    $mutedBrush.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    $pfc.Dispose()
}
