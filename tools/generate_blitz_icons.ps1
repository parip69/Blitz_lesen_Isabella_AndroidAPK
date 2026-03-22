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

function Draw-BlitzScene {
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
        $shadowPath = New-RoundedRectanglePath (S 44) (S 58) (S 936) (S 936) (S 144)
        $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 4, 10, 18))
        $Graphics.FillPath($shadowBrush, $shadowPath)
        $shadowBrush.Dispose()
        $shadowPath.Dispose()

        $bgPath = New-RoundedRectanglePath (S 38) (S 38) (S 948) (S 948) (S 154)
        $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P 120 60),
            (P 880 980),
            [System.Drawing.Color]::FromArgb(255, 86, 103, 124),
            [System.Drawing.Color]::FromArgb(255, 13, 25, 39)
        )
        $Graphics.FillPath($bgBrush, $bgPath)
        $bgBrush.Dispose()

        $innerPath = New-RoundedRectanglePath (S 58) (S 58) (S 908) (S 908) (S 132)
        $innerBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P 120 120),
            (P 900 900),
            [System.Drawing.Color]::FromArgb(255, 64, 79, 97),
            [System.Drawing.Color]::FromArgb(255, 16, 29, 44)
        )
        $Graphics.FillPath($innerBrush, $innerPath)
        $innerBrush.Dispose()

        $glossPath = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P 620 48),
            (P 980 48),
            (P 980 420),
            (P 840 390)
        ))
        $glossBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(42, 255, 255, 255))
        $Graphics.FillPath($glossBrush, $glossPath)
        $glossBrush.Dispose()
        $glossPath.Dispose()

        $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 30, 47, 65), (S 10))
        $Graphics.DrawPath($borderPen, $bgPath)
        $borderPen.Dispose()

        $innerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 255, 255, 255), (S 3))
        $Graphics.DrawPath($innerPen, $innerPath)
        $innerPen.Dispose()

        $warmGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(38, 255, 215, 120))
        $Graphics.FillEllipse($warmGlow, (S 190), (S 180), (S 640), (S 640))
        $Graphics.FillEllipse($warmGlow, (S 320), (S 110), (S 360), (S 360))
        $warmGlow.Dispose()

        $bgPath.Dispose()
        $innerPath.Dispose()
    }
    else {
        $softGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(48, 255, 210, 110))
        $Graphics.FillEllipse($softGlow, (S 250), (S 120), (S 520), (S 520))
        $Graphics.FillEllipse($softGlow, (S 180), (S 470), (S 650), (S 270))
        $softGlow.Dispose()
    }

    Draw-GlowDot -Graphics $Graphics -X (S 388) -Y (S 224) -Size (S 10) -Color ([System.Drawing.Color]::FromArgb(255, 255, 224, 148))
    Draw-GlowDot -Graphics $Graphics -X (S 312) -Y (S 284) -Size (S 8) -Color ([System.Drawing.Color]::FromArgb(255, 255, 211, 138))
    Draw-GlowDot -Graphics $Graphics -X (S 726) -Y (S 252) -Size (S 9) -Color ([System.Drawing.Color]::FromArgb(255, 255, 228, 160))
    Draw-GlowDot -Graphics $Graphics -X (S 770) -Y (S 340) -Size (S 7) -Color ([System.Drawing.Color]::FromArgb(255, 255, 222, 146))
    Draw-GlowDot -Graphics $Graphics -X (S 248) -Y (S 392) -Size (S 6) -Color ([System.Drawing.Color]::FromArgb(255, 255, 214, 132))

    $bookShadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(110, 2, 7, 12))
    $Graphics.FillEllipse($bookShadow, (S 188), (S 742), (S 648), (S 132))
    $bookShadow.Dispose()

    $leftCoverPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 168 742),
        (P 486 690),
        (P 514 888),
        (P 140 910)
    ))
    $rightCoverPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 538 690),
        (P 856 742),
        (P 884 910),
        (P 510 888)
    ))
    $leftPagesPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 206 708),
        (P 496 666),
        (P 506 846),
        (P 190 860)
    ))
    $rightPagesPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 528 666),
        (P 818 708),
        (P 834 860),
        (P 518 846)
    ))

    $leftCoverBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 150 740),
        (P 520 920),
        [System.Drawing.Color]::FromArgb(255, 46, 119, 223),
        [System.Drawing.Color]::FromArgb(255, 14, 61, 145)
    )
    $rightCoverBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 500 680),
        (P 880 920),
        [System.Drawing.Color]::FromArgb(255, 37, 102, 205),
        [System.Drawing.Color]::FromArgb(255, 9, 49, 122)
    )
    $Graphics.FillPath($leftCoverBrush, $leftCoverPath)
    $Graphics.FillPath($rightCoverBrush, $rightCoverPath)
    $leftCoverBrush.Dispose()
    $rightCoverBrush.Dispose()

    $pageBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 240 650),
        (P 790 870),
        [System.Drawing.Color]::FromArgb(255, 255, 252, 244),
        [System.Drawing.Color]::FromArgb(255, 223, 228, 236)
    )
    $Graphics.FillPath($pageBrush, $leftPagesPath)
    $Graphics.FillPath($pageBrush, $rightPagesPath)
    $pageBrush.Dispose()

    $pageShade = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(38, 105, 118, 138))
    $Graphics.FillEllipse($pageShade, (S 250), (S 684), (S 520), (S 140))
    $pageShade.Dispose()

    $spineBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 470 840),
        (P 560 940),
        [System.Drawing.Color]::FromArgb(255, 8, 45, 115),
        [System.Drawing.Color]::FromArgb(255, 20, 86, 186)
    )
    $Graphics.FillEllipse($spineBrush, (S 414), (S 858), (S 188), (S 82))
    $spineBrush.Dispose()

    $highlightPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 255, 255, 255), (S 7))
    $Graphics.DrawLine($highlightPen, (S 196), (S 744), (S 458), (S 706))
    $Graphics.DrawLine($highlightPen, (S 560), (S 706), (S 820), (S 744))
    $highlightPen.Dispose()

    $pageLinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(58, 144, 151, 167), (S 4))
    foreach ($line in 0..4) {
        $yLeft = S (734 + ($line * 22))
        $yRight = S (720 + ($line * 18))
        $Graphics.DrawLine($pageLinePen, (S 248), $yLeft, (S 434), $yRight)
        $Graphics.DrawLine($pageLinePen, (S 596), $yRight, (S 776), $yLeft)
    }
    $pageLinePen.Dispose()

    $edgePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 170, 181, 197), (S 3))
    $Graphics.DrawPath($edgePen, $leftPagesPath)
    $Graphics.DrawPath($edgePen, $rightPagesPath)
    $Graphics.DrawPath($edgePen, $leftCoverPath)
    $Graphics.DrawPath($edgePen, $rightCoverPath)
    $edgePen.Dispose()

    $spinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 21, 64, 142), (S 4))
    $Graphics.DrawArc($spinePen, (S 414), (S 858), (S 188), (S 82), 0, 180)
    $spinePen.Dispose()

    $creasePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(110, 162, 171, 184), (S 4))
    $Graphics.DrawLine($creasePen, (S 510), (S 674), (S 512), (S 850))
    $creasePen.Dispose()

    $boltShadowPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 456 160),
        (P 650 182),
        (P 588 416),
        (P 756 420),
        (P 528 810),
        (P 590 542),
        (P 430 540)
    ))
    $boltShadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(62, 92, 44, 0))
    $Graphics.FillPath($boltShadowBrush, $boltShadowPath)
    $boltShadowBrush.Dispose()

    $boltGlowPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 430 134),
        (P 628 154),
        (P 560 396),
        (P 732 398),
        (P 510 792),
        (P 566 520),
        (P 406 518)
    ))
    $boltGlowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(44, 255, 214, 114))
    $Graphics.FillPath($boltGlowBrush, $boltGlowPath)
    $boltGlowBrush.Dispose()

    $boltPath = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 438 136),
        (P 638 158),
        (P 566 410),
        (P 744 410),
        (P 514 804),
        (P 572 524),
        (P 412 524)
    ))
    $boltBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 458 120),
        (P 664 840),
        [System.Drawing.Color]::FromArgb(255, 255, 250, 229),
        [System.Drawing.Color]::FromArgb(255, 247, 184, 53)
    )
    $Graphics.FillPath($boltBrush, $boltPath)
    $boltBrush.Dispose()

    $boltHighlightPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(160, 255, 255, 245), (S 8))
    $Graphics.DrawLine($boltHighlightPen, (S 500), (S 182), (S 598), (S 196))
    $Graphics.DrawLine($boltHighlightPen, (S 612), (S 204), (S 544), (S 390))
    $boltHighlightPen.Dispose()

    $boltEdgePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 208, 124, 22), (S 10))
    $Graphics.DrawPath($boltEdgePen, $boltPath)
    $boltEdgePen.Dispose()

    $boltWarmPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(84, 255, 227, 132), (S 18))
    $Graphics.DrawPath($boltWarmPen, $boltPath)
    $boltWarmPen.Dispose()

    $leftCoverPath.Dispose()
    $rightCoverPath.Dispose()
    $leftPagesPath.Dispose()
    $rightPagesPath.Dispose()
    $boltShadowPath.Dispose()
    $boltGlowPath.Dispose()
    $boltPath.Dispose()
}

function New-IconBitmap {
    param(
        [int]$Size,
        [bool]$TransparentBackground
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    Draw-BlitzScene -Graphics $graphics -Size $Size -TransparentBackground:$TransparentBackground
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

Write-Host "Blitz-Icons erfolgreich erzeugt."
