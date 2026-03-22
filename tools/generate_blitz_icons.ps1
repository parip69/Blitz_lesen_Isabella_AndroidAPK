param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $Radius * 2

    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()

    return $path
}

function New-PolygonPath {
    param(
        [System.Drawing.PointF[]]$Points
    )

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddPolygon($Points)
    return $path
}

function Draw-GlowDot {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Size,
        [System.Drawing.Color]$Color
    )

    for ($i = 3; $i -ge 1; $i--) {
        $alpha = 18 * $i
        $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb($alpha, $Color))
        $Graphics.FillEllipse($brush, $X - ($Size * $i), $Y - ($Size * $i), $Size * $i * 2, $Size * $i * 2)
        $brush.Dispose()
    }

    $centerBrush = [System.Drawing.SolidBrush]::new($Color)
    $Graphics.FillEllipse($centerBrush, $X - $Size, $Y - $Size, $Size * 2, $Size * 2)
    $centerBrush.Dispose()
}

function Draw-LeselampeScene {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$Size,
        [bool]$TransparentBackground
    )

    $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $Graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $Graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = [double]$Size / 1024.0

    function S {
        param([double]$Value)
        return [float]($Value * $scale)
    }

    function P {
        param(
            [double]$X,
            [double]$Y
        )

        return [System.Drawing.PointF]::new((S $X), (S $Y))
    }

    if (-not $TransparentBackground) {
        $shadowPath = New-RoundedRectanglePath (S 42) (S 54) (S 940) (S 940) (S 146)
        $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 5, 12, 22))
        $Graphics.FillPath($shadowBrush, $shadowPath)
        $shadowBrush.Dispose()
        $shadowPath.Dispose()

        $bgPath = New-RoundedRectanglePath (S 36) (S 36) (S 952) (S 952) (S 156)
        $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P 80 30),
            (P 930 990),
            [System.Drawing.Color]::FromArgb(255, 88, 103, 121),
            [System.Drawing.Color]::FromArgb(255, 12, 26, 41)
        )
        $Graphics.FillPath($bgBrush, $bgPath)
        $bgBrush.Dispose()

        $innerPath = New-RoundedRectanglePath (S 58) (S 58) (S 908) (S 908) (S 132)
        $innerBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P 130 120),
            (P 910 910),
            [System.Drawing.Color]::FromArgb(255, 62, 78, 96),
            [System.Drawing.Color]::FromArgb(255, 16, 30, 45)
        )
        $Graphics.FillPath($innerBrush, $innerPath)
        $innerBrush.Dispose()

        $glossPath = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P 620 42),
            (P 980 42),
            (P 980 410),
            (P 844 386)
        ))
        $glossBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(44, 255, 255, 255))
        $Graphics.FillPath($glossBrush, $glossPath)
        $glossBrush.Dispose()
        $glossPath.Dispose()

        $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(182, 33, 49, 65), (S 10))
        $Graphics.DrawPath($borderPen, $bgPath)
        $borderPen.Dispose()

        $innerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(58, 255, 255, 255), (S 3))
        $Graphics.DrawPath($innerPen, $innerPath)
        $innerPen.Dispose()

        $bgPath.Dispose()
        $innerPath.Dispose()
    }

    $haloBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(42, 255, 196, 96))
    $Graphics.FillEllipse($haloBrush, (S 300), (S 188), (S 430), (S 360))
    $haloBrush.Dispose()

    $warmHaloBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(52, 255, 211, 134))
    $Graphics.FillEllipse($warmHaloBrush, (S 254), (S 362), (S 520), (S 310))
    $warmHaloBrush.Dispose()

    $lightCone = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 456 284),
        (P 584 284),
        (P 722 646),
        (P 316 646)
    ))
    $lightConeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(54, 255, 207, 116))
    $Graphics.FillPath($lightConeBrush, $lightCone)
    $lightConeBrush.Dispose()
    $lightCone.Dispose()

    $bookShadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(130, 0, 6, 14))
    $Graphics.FillEllipse($bookShadow, (S 176), (S 760), (S 672), (S 126))
    $bookShadow.Dispose()

    $backCoverLeft = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 176 694),
        (P 472 654),
        (P 520 830),
        (P 150 850)
    ))
    $backCoverRight = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 552 654),
        (P 848 694),
        (P 876 850),
        (P 504 830)
    ))
    $backCoverBrushLeft = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 150 700),
        (P 530 860),
        [System.Drawing.Color]::FromArgb(255, 20, 48, 72),
        [System.Drawing.Color]::FromArgb(255, 6, 20, 34)
    )
    $backCoverBrushRight = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 500 650),
        (P 876 860),
        [System.Drawing.Color]::FromArgb(255, 28, 60, 87),
        [System.Drawing.Color]::FromArgb(255, 7, 22, 37)
    )
    $Graphics.FillPath($backCoverBrushLeft, $backCoverLeft)
    $Graphics.FillPath($backCoverBrushRight, $backCoverRight)
    $backCoverBrushLeft.Dispose()
    $backCoverBrushRight.Dispose()

    foreach ($layer in 0..3) {
        $offset = $layer * 15
        $alpha = 255 - ($layer * 16)
        $pageBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P (244 - $layer * 6) (610 + $offset)),
            (P 784 (818 + $offset)),
            [System.Drawing.Color]::FromArgb($alpha, 255, 250, 237),
            [System.Drawing.Color]::FromArgb($alpha, 205, 214, 223)
        )
        $leftPages = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P (260 - $layer * 10) (612 + $offset)),
            (P 498 (584 + $offset / 2)),
            (P 510 (798 + $offset)),
            (P (224 - $layer * 8) (820 + $offset))
        ))
        $rightPages = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P 526 (584 + $offset / 2)),
            (P (764 + $layer * 10) (612 + $offset)),
            (P (800 + $layer * 8) (820 + $offset)),
            (P 514 (798 + $offset))
        ))
        $Graphics.FillPath($pageBrush, $leftPages)
        $Graphics.FillPath($pageBrush, $rightPages)
        $pageBrush.Dispose()
        $leftPages.Dispose()
        $rightPages.Dispose()
    }

    $mainPagesBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 252 590),
        (P 780 804),
        [System.Drawing.Color]::FromArgb(255, 255, 252, 241),
        [System.Drawing.Color]::FromArgb(255, 232, 227, 213)
    )
    $mainLeftPage = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 266 594),
        (P 500 560),
        (P 514 790),
        (P 228 814)
    ))
    $mainRightPage = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 524 560),
        (P 758 594),
        (P 798 814),
        (P 512 790)
    ))
    $Graphics.FillPath($mainPagesBrush, $mainLeftPage)
    $Graphics.FillPath($mainPagesBrush, $mainRightPage)
    $mainPagesBrush.Dispose()

    $pageLinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 181, 146, 102), (S 3))
    foreach ($line in 0..6) {
        $yTop = 636 + ($line * 20)
        $Graphics.DrawLine($pageLinePen, (S 306), (S $yTop), (S 456), (S ($yTop + 18)))
        $Graphics.DrawLine($pageLinePen, (S 564), (S ($yTop + 18)), (S 714), (S $yTop))
    }
    $pageLinePen.Dispose()

    $pageBorderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(118, 166, 174, 183), (S 3))
    $Graphics.DrawPath($pageBorderPen, $mainLeftPage)
    $Graphics.DrawPath($pageBorderPen, $mainRightPage)
    $Graphics.DrawPath($pageBorderPen, $backCoverLeft)
    $Graphics.DrawPath($pageBorderPen, $backCoverRight)
    $pageBorderPen.Dispose()

    $centerFoldPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 106, 114, 132), (S 4))
    $Graphics.DrawLine($centerFoldPen, (S 512), (S 566), (S 512), (S 792))
    $centerFoldPen.Dispose()

    $bookmarkLeft = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 318 774),
        (P 372 774),
        (P 372 902),
        (P 344 878),
        (P 318 902)
    ))
    $bookmarkMid = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 404 776),
        (P 460 776),
        (P 460 896),
        (P 432 872),
        (P 404 896)
    ))
    $bookmarkRight = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 592 774),
        (P 650 774),
        (P 650 904),
        (P 621 878),
        (P 592 904)
    ))
    $bookmarkBrushLeft = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 318 776), (P 372 902), [System.Drawing.Color]::FromArgb(255, 224, 142, 61), [System.Drawing.Color]::FromArgb(255, 145, 76, 28))
    $bookmarkBrushMid = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 404 776), (P 460 896), [System.Drawing.Color]::FromArgb(255, 204, 98, 73), [System.Drawing.Color]::FromArgb(255, 132, 51, 47))
    $bookmarkBrushRight = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 592 776), (P 650 904), [System.Drawing.Color]::FromArgb(255, 58, 181, 244), [System.Drawing.Color]::FromArgb(255, 17, 106, 168))
    $Graphics.FillPath($bookmarkBrushLeft, $bookmarkLeft)
    $Graphics.FillPath($bookmarkBrushMid, $bookmarkMid)
    $Graphics.FillPath($bookmarkBrushRight, $bookmarkRight)
    $bookmarkBrushLeft.Dispose()
    $bookmarkBrushMid.Dispose()
    $bookmarkBrushRight.Dispose()

    $spineBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 452 828),
        (P 572 908),
        [System.Drawing.Color]::FromArgb(255, 34, 31, 38),
        [System.Drawing.Color]::FromArgb(255, 10, 18, 29)
    )
    $Graphics.FillEllipse($spineBrush, (S 448), (S 796), (S 128), (S 60))
    $spineBrush.Dispose()

    $lampArmPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 56, 42, 34), (S 24))
    $lampArmPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $lampArmPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $Graphics.DrawBezier($lampArmPen, (P 316 560), (P 286 368), (P 286 160), (P 484 176))
    $lampArmPen.Dispose()

    $lampArmHighlight = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(150, 162, 123, 85), (S 8))
    $lampArmHighlight.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $lampArmHighlight.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $Graphics.DrawBezier($lampArmHighlight, (P 322 554), (P 294 368), (P 294 172), (P 478 184))
    $lampArmHighlight.Dispose()

    $mountBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 290 502), (P 356 566), [System.Drawing.Color]::FromArgb(255, 80, 63, 51), [System.Drawing.Color]::FromArgb(255, 37, 25, 20))
    $Graphics.FillRectangle($mountBrush, (S 286), (S 506), (S 56), (S 46))
    $mountBrush.Dispose()
    $mountPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200, 143, 112, 84), (S 4))
    $Graphics.DrawRectangle($mountPen, (S 286), (S 506), (S 56), (S 46))
    $mountPen.Dispose()

    $shadeBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 432 120),
        (P 626 304),
        [System.Drawing.Color]::FromArgb(255, 43, 55, 66),
        [System.Drawing.Color]::FromArgb(255, 8, 17, 28)
    )
    $Graphics.FillEllipse($shadeBrush, (S 392), (S 118), (S 252), (S 204))
    $shadeBrush.Dispose()

    $shadePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 20, 29, 39), (S 6))
    $Graphics.DrawEllipse($shadePen, (S 392), (S 118), (S 252), (S 204))
    $shadePen.Dispose()

    $openingBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 430 244),
        (P 616 324),
        [System.Drawing.Color]::FromArgb(255, 255, 207, 121),
        [System.Drawing.Color]::FromArgb(255, 143, 85, 34)
    )
    $Graphics.FillEllipse($openingBrush, (S 432), (S 232), (S 186), (S 76))
    $openingBrush.Dispose()

    $bulbGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(100, 255, 227, 140))
    $Graphics.FillEllipse($bulbGlow, (S 448), (S 176), (S 140), (S 140))
    $Graphics.FillEllipse($bulbGlow, (S 480), (S 206), (S 78), (S 78))
    $bulbGlow.Dispose()

    $bulbCore = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 248, 206))
    $Graphics.FillEllipse($bulbCore, (S 488), (S 206), (S 62), (S 62))
    $bulbCore.Dispose()

    $shadeRimPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(215, 208, 151, 79), (S 5))
    $Graphics.DrawEllipse($shadeRimPen, (S 432), (S 232), (S 186), (S 76))
    $shadeRimPen.Dispose()

    $topCapBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 486 98), (P 538 142), [System.Drawing.Color]::FromArgb(255, 44, 58, 70), [System.Drawing.Color]::FromArgb(255, 10, 18, 28))
    $Graphics.FillEllipse($topCapBrush, (S 500), (S 90), (S 38), (S 44))
    $topCapBrush.Dispose()

    Draw-GlowDot -Graphics $Graphics -X (S 456) -Y (S 332) -Size (S 8) -Color ([System.Drawing.Color]::FromArgb(255, 255, 195, 93))
    Draw-GlowDot -Graphics $Graphics -X (S 512) -Y (S 360) -Size (S 8) -Color ([System.Drawing.Color]::FromArgb(255, 255, 197, 99))
    Draw-GlowDot -Graphics $Graphics -X (S 566) -Y (S 338) -Size (S 7) -Color ([System.Drawing.Color]::FromArgb(255, 255, 190, 88))
    Draw-GlowDot -Graphics $Graphics -X (S 602) -Y (S 396) -Size (S 6) -Color ([System.Drawing.Color]::FromArgb(255, 255, 179, 78))
    Draw-GlowDot -Graphics $Graphics -X (S 430) -Y (S 404) -Size (S 6) -Color ([System.Drawing.Color]::FromArgb(255, 255, 187, 89))

    $backCoverLeft.Dispose()
    $backCoverRight.Dispose()
    $mainLeftPage.Dispose()
    $mainRightPage.Dispose()
    $bookmarkLeft.Dispose()
    $bookmarkMid.Dispose()
    $bookmarkRight.Dispose()
}

function New-IconBitmap {
    param(
        [int]$Size,
        [bool]$TransparentBackground
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    Draw-LeselampeScene -Graphics $graphics -Size $Size -TransparentBackground:$TransparentBackground
    $graphics.Dispose()
    return $bitmap
}

function Save-ScaledBitmap {
    param(
        [System.Drawing.Image]$Source,
        [int]$Size,
        [string]$Path,
        [bool]$RoundMask = $false
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    if ($RoundMask) {
        $clip = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $clip.AddEllipse(0, 0, $Size, $Size)
        $graphics.SetClip($clip)
        $clip.Dispose()
    }

    $graphics.DrawImage($Source, 0, 0, $Size, $Size)
    $graphics.Dispose()
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$fullIcon = New-IconBitmap -Size 1024 -TransparentBackground:$false
$foregroundIcon = New-IconBitmap -Size 1024 -TransparentBackground:$true

$webTargets = @{
    "app/src/main/assets/icons/icon-192.png" = 192
    "app/src/main/assets/icons/icon-512.png" = 512
    "app/src/main/assets/icons/apple-touch-icon.png" = 180
}

foreach ($target in $webTargets.GetEnumerator()) {
    Save-ScaledBitmap -Source $fullIcon -Size $target.Value -Path (Join-Path $ProjectRoot $target.Key)
}

$legacySizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($entry in $legacySizes.GetEnumerator()) {
    $folder = Join-Path $ProjectRoot ("app/src/main/res/{0}" -f $entry.Key)
    Save-ScaledBitmap -Source $fullIcon -Size $entry.Value -Path (Join-Path $folder "ic_launcher.png")
    Save-ScaledBitmap -Source $fullIcon -Size $entry.Value -Path (Join-Path $folder "ic_launcher_round.png") -RoundMask:$true
}

Save-ScaledBitmap -Source $foregroundIcon -Size 432 -Path (Join-Path $ProjectRoot "app/src/main/res/drawable/ic_launcher_foreground.png")

$fullIcon.Dispose()
$foregroundIcon.Dispose()

Write-Host "Leselampen-Icons erfolgreich erzeugt."
