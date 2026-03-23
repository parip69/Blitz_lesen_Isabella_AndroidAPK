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
        $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(140, 2, 8, 16))
        $Graphics.FillPath($shadowBrush, $shadowPath)
        $shadowBrush.Dispose()
        $shadowPath.Dispose()

        $bgPath = New-RoundedRectanglePath (S 36) (S 36) (S 952) (S 952) (S 156)
        $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P 80 30),
            (P 930 990),
            [System.Drawing.Color]::FromArgb(255, 66, 78, 95),
            [System.Drawing.Color]::FromArgb(255, 7, 16, 27)
        )
        $Graphics.FillPath($bgBrush, $bgPath)
        $bgBrush.Dispose()

        $innerPath = New-RoundedRectanglePath (S 58) (S 58) (S 908) (S 908) (S 132)
        $innerBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P 130 120),
            (P 910 910),
            [System.Drawing.Color]::FromArgb(255, 38, 49, 61),
            [System.Drawing.Color]::FromArgb(255, 9, 16, 25)
        )
        $Graphics.FillPath($innerBrush, $innerPath)
        $innerBrush.Dispose()

        $glossPath = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P 620 42),
            (P 980 42),
            (P 980 410),
            (P 844 386)
        ))
        $glossBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(32, 255, 255, 255))
        $Graphics.FillPath($glossBrush, $glossPath)
        $glossBrush.Dispose()
        $glossPath.Dispose()

        $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 18, 29, 40), (S 10))
        $Graphics.DrawPath($borderPen, $bgPath)
        $borderPen.Dispose()

        $innerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(44, 255, 255, 255), (S 3))
        $Graphics.DrawPath($innerPen, $innerPath)
        $innerPen.Dispose()

        $vignetteBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new([System.Drawing.PointF[]]@(
            (P 180 210),
            (P 844 160),
            (P 906 852),
            (P 170 890)
        ))
        $vignetteBrush.CenterColor = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
        $vignetteBrush.SurroundColors = [System.Drawing.Color[]]@([System.Drawing.Color]::FromArgb(86, 2, 8, 16))
        $Graphics.FillRectangle($vignetteBrush, (S 58), (S 58), (S 908), (S 908))
        $vignetteBrush.Dispose()

        $bgPath.Dispose()
        $innerPath.Dispose()
    }

    $haloBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18, 255, 228, 172))
    $Graphics.FillEllipse($haloBrush, (S 410), (S 164), (S 240), (S 188))
    $haloBrush.Dispose()

    $warmHaloBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(34, 255, 214, 148))
    $Graphics.FillEllipse($warmHaloBrush, (S 308), (S 418), (S 440), (S 204))
    $warmHaloBrush.Dispose()

    $lightCone = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 518 320),
        (P 606 320),
        (P 704 654),
        (P 364 654)
    ))
    $lightConeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(42, 255, 219, 148))
    $Graphics.FillPath($lightConeBrush, $lightCone)
    $lightConeBrush.Dispose()
    $lightCone.Dispose()

    $bookShadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(156, 0, 4, 10))
    $Graphics.FillEllipse($bookShadow, (S 204), (S 786), (S 620), (S 96))
    $bookShadow.Dispose()

    $backCoverLeft = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 212 718),
        (P 480 688),
        (P 524 816),
        (P 194 832)
    ))
    $backCoverRight = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 544 688),
        (P 814 718),
        (P 830 832),
        (P 500 816)
    ))
    $backCoverBrushLeft = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 188 704),
        (P 534 838),
        [System.Drawing.Color]::FromArgb(255, 74, 82, 92),
        [System.Drawing.Color]::FromArgb(255, 28, 32, 40)
    )
    $backCoverBrushRight = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 492 676),
        (P 846 844),
        [System.Drawing.Color]::FromArgb(255, 88, 96, 106),
        [System.Drawing.Color]::FromArgb(255, 30, 34, 44)
    )
    $Graphics.FillPath($backCoverBrushLeft, $backCoverLeft)
    $Graphics.FillPath($backCoverBrushRight, $backCoverRight)
    $backCoverBrushLeft.Dispose()
    $backCoverBrushRight.Dispose()

    foreach ($layer in 0..4) {
        $offset = $layer * 11
        $alpha = 255 - ($layer * 14)
        $pageBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P (286 - $layer * 4) (626 + $offset)),
            (P 744 (802 + $offset)),
            [System.Drawing.Color]::FromArgb($alpha, 255, 255, 252),
            [System.Drawing.Color]::FromArgb($alpha, 216, 224, 232)
        )
        $leftPages = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P (288 - $layer * 7) (628 + $offset)),
            (P 502 (598 + $offset / 2)),
            (P 514 (784 + $offset)),
            (P (248 - $layer * 5) (800 + $offset))
        ))
        $rightPages = New-PolygonPath ([System.Drawing.PointF[]]@(
            (P 522 (598 + $offset / 2)),
            (P (736 + $layer * 7) (628 + $offset)),
            (P (774 + $layer * 5) (800 + $offset)),
            (P 510 (784 + $offset))
        ))
        $Graphics.FillPath($pageBrush, $leftPages)
        $Graphics.FillPath($pageBrush, $rightPages)
        $pageBrush.Dispose()
        $leftPages.Dispose()
        $rightPages.Dispose()
    }

    $mainPagesBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 290 602),
        (P 736 792),
        [System.Drawing.Color]::FromArgb(255, 255, 255, 254),
        [System.Drawing.Color]::FromArgb(255, 232, 237, 243)
    )
    $mainLeftPage = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 292 606),
        (P 502 576),
        (P 514 776),
        (P 256 794)
    ))
    $mainRightPage = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 522 576),
        (P 732 606),
        (P 770 794),
        (P 510 776)
    ))
    $Graphics.FillPath($mainPagesBrush, $mainLeftPage)
    $Graphics.FillPath($mainPagesBrush, $mainRightPage)
    $mainPagesBrush.Dispose()

    $pageGlowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(60, 255, 252, 236))
    $Graphics.FillEllipse($pageGlowBrush, (S 298), (S 584), (S 438), (S 118))
    $pageGlowBrush.Dispose()

    $pageLinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(48, 188, 175, 144), (S 2))
    foreach ($line in 0..6) {
        $yTop = 642 + ($line * 17)
        $Graphics.DrawLine($pageLinePen, (S 330), (S $yTop), (S 456), (S ($yTop + 12)))
        $Graphics.DrawLine($pageLinePen, (S 568), (S ($yTop + 12)), (S 694), (S $yTop))
    }
    $pageLinePen.Dispose()

    $pageBorderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(148, 178, 188, 198), (S 3))
    $Graphics.DrawPath($pageBorderPen, $mainLeftPage)
    $Graphics.DrawPath($pageBorderPen, $mainRightPage)
    $Graphics.DrawPath($pageBorderPen, $backCoverLeft)
    $Graphics.DrawPath($pageBorderPen, $backCoverRight)
    $pageBorderPen.Dispose()

    $pageHighlightPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(110, 255, 255, 255), (S 3))
    $Graphics.DrawLine($pageHighlightPen, (S 312), (S 632), (S 484), (S 606))
    $Graphics.DrawLine($pageHighlightPen, (S 540), (S 606), (S 712), (S 632))
    $pageHighlightPen.Dispose()

    $centerFoldPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 140, 149, 165), (S 4))
    $Graphics.DrawLine($centerFoldPen, (S 512), (S 582), (S 512), (S 778))
    $centerFoldPen.Dispose()

    $bookmarkLeftOuter = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 324 780),
        (P 372 780),
        (P 372 892),
        (P 348 870),
        (P 324 892)
    ))
    $bookmarkLeftInner = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 404 782),
        (P 454 782),
        (P 454 888),
        (P 429 866),
        (P 404 888)
    ))
    $bookmarkRightInner = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 580 782),
        (P 632 782),
        (P 632 892),
        (P 606 868),
        (P 580 892)
    ))
    $bookmarkRightOuter = New-PolygonPath ([System.Drawing.PointF[]]@(
        (P 668 780),
        (P 714 780),
        (P 714 888),
        (P 691 868),
        (P 668 888)
    ))
    $bookmarkLeftOuterBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 324 782), (P 372 892), [System.Drawing.Color]::FromArgb(255, 74, 58, 42), [System.Drawing.Color]::FromArgb(255, 34, 24, 18))
    $bookmarkLeftInnerBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 404 782), (P 454 888), [System.Drawing.Color]::FromArgb(255, 205, 60, 58), [System.Drawing.Color]::FromArgb(255, 126, 28, 30))
    $bookmarkRightInnerBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 580 782), (P 632 892), [System.Drawing.Color]::FromArgb(255, 84, 172, 240), [System.Drawing.Color]::FromArgb(255, 24, 104, 184))
    $bookmarkRightOuterBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new((P 668 780), (P 714 888), [System.Drawing.Color]::FromArgb(255, 82, 64, 48), [System.Drawing.Color]::FromArgb(255, 36, 24, 18))
    $Graphics.FillPath($bookmarkLeftOuterBrush, $bookmarkLeftOuter)
    $Graphics.FillPath($bookmarkLeftInnerBrush, $bookmarkLeftInner)
    $Graphics.FillPath($bookmarkRightInnerBrush, $bookmarkRightInner)
    $Graphics.FillPath($bookmarkRightOuterBrush, $bookmarkRightOuter)
    $bookmarkLeftOuterBrush.Dispose()
    $bookmarkLeftInnerBrush.Dispose()
    $bookmarkRightInnerBrush.Dispose()
    $bookmarkRightOuterBrush.Dispose()

    $spineBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 458 808),
        (P 564 866),
        [System.Drawing.Color]::FromArgb(255, 40, 40, 46),
        [System.Drawing.Color]::FromArgb(255, 10, 16, 24)
    )
    $Graphics.FillEllipse($spineBrush, (S 456), (S 792), (S 112), (S 46))
    $spineBrush.Dispose()

    $sparkles = @(
        @(214, 816, 1.5), @(232, 842, 1.2), @(252, 856, 1.0), @(278, 848, 1.1),
        @(300, 828, 1.4), @(330, 866, 1.2), @(362, 844, 1.0), @(388, 872, 1.3),
        @(420, 850, 1.1), @(454, 838, 1.4), @(486, 870, 1.2), @(520, 846, 1.0),
        @(556, 864, 1.3), @(592, 842, 1.2), @(626, 872, 1.0), @(664, 850, 1.4),
        @(706, 830, 1.7), @(742, 858, 1.2), @(306, 820, 3.2), @(652, 826, 2.8)
    )
    foreach ($sparkle in $sparkles) {
        Draw-GlowDot -Graphics $Graphics -X (S $sparkle[0]) -Y (S $sparkle[1]) -Size (S $sparkle[2]) -Color ([System.Drawing.Color]::FromArgb(255, 241, 211, 117))
    }

    $baseShadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(72, 0, 0, 0))
    $Graphics.FillEllipse($baseShadowBrush, (S 244), (S 518), (S 170), (S 34))
    $baseShadowBrush.Dispose()

    $basePlateBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 264 490),
        (P 418 526),
        [System.Drawing.Color]::FromArgb(255, 244, 248, 252),
        [System.Drawing.Color]::FromArgb(255, 72, 82, 92)
    )
    $Graphics.FillEllipse($basePlateBrush, (S 262), (S 492), (S 156), (S 30))
    $basePlateBrush.Dispose()

    $baseTopBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 278 482),
        (P 406 512),
        [System.Drawing.Color]::FromArgb(255, 255, 255, 255),
        [System.Drawing.Color]::FromArgb(255, 118, 126, 138)
    )
    $Graphics.FillEllipse($baseTopBrush, (S 278), (S 478), (S 126), (S 28))
    $baseTopBrush.Dispose()

    $baseRingPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200, 46, 52, 60), (S 4))
    $Graphics.DrawEllipse($baseRingPen, (S 262), (S 492), (S 156), (S 30))
    $Graphics.DrawEllipse($baseRingPen, (S 278), (S 478), (S 126), (S 28))
    $baseRingPen.Dispose()

    $rodShadowPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 30, 34, 40), (S 16))
    $rodShadowPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $rodShadowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $rodMetalPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 204, 212, 220), (S 10))
    $rodMetalPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $rodMetalPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $rodHighlightPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(170, 255, 255, 255), (S 2))
    $rodHighlightPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $rodHighlightPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    foreach ($segment in @(
        @((P 344 448), (P 292 336)),
        @((P 362 438), (P 310 326)),
        @((P 294 320), (P 432 252)),
        @((P 308 338), (P 446 270)),
        @((P 348 492), (P 348 444)),
        @((P 362 492), (P 362 438)),
        @((P 438 250), (P 478 218)),
        @((P 450 266), (P 492 234))
    )) {
        $Graphics.DrawLine($rodShadowPen, $segment[0], $segment[1])
        $Graphics.DrawLine($rodMetalPen, $segment[0], $segment[1])
        $Graphics.DrawLine($rodHighlightPen, $segment[0], $segment[1])
    }

    $rodShadowPen.Dispose()
    $rodMetalPen.Dispose()
    $rodHighlightPen.Dispose()

    foreach ($joint in @(
        @(332, 430, 42),
        @(270, 308, 46),
        @(420, 236, 34)
    )) {
        $jointBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
            (P $joint[0] $joint[1]),
            (P ($joint[0] + $joint[2]) ($joint[1] + $joint[2])),
            [System.Drawing.Color]::FromArgb(255, 250, 252, 255),
            [System.Drawing.Color]::FromArgb(255, 112, 122, 134)
        )
        $Graphics.FillEllipse($jointBrush, (S $joint[0]), (S $joint[1]), (S $joint[2]), (S $joint[2]))
        $jointBrush.Dispose()

        $jointPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 38, 42, 48), (S 4))
        $Graphics.DrawEllipse($jointPen, (S $joint[0]), (S $joint[1]), (S $joint[2]), (S $joint[2]))
        $jointPen.Dispose()

        $jointHighlight = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(130, 255, 255, 255))
        $Graphics.FillEllipse($jointHighlight, (S ($joint[0] + 8)), (S ($joint[1] + 6)), (S ($joint[2] * 0.34)), (S ($joint[2] * 0.28)))
        $jointHighlight.Dispose()
    }

    $shadeBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 454 154),
        (P 646 314),
        [System.Drawing.Color]::FromArgb(255, 248, 251, 255),
        [System.Drawing.Color]::FromArgb(255, 92, 102, 114)
    )
    $Graphics.FillEllipse($shadeBrush, (S 454), (S 154), (S 176), (S 150))
    $shadeBrush.Dispose()

    $shadeShadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(36, 30, 36, 48))
    $Graphics.FillEllipse($shadeShadow, (S 524), (S 170), (S 92), (S 126))
    $shadeShadow.Dispose()

    $shadeHighlight = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(118, 255, 255, 255))
    $Graphics.FillEllipse($shadeHighlight, (S 480), (S 168), (S 54), (S 42))
    $shadeHighlight.Dispose()

    $shadePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 42, 46, 54), (S 4))
    $Graphics.DrawEllipse($shadePen, (S 454), (S 154), (S 176), (S 150))
    $shadePen.Dispose()

    $openingBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 492 258),
        (P 620 320),
        [System.Drawing.Color]::FromArgb(255, 255, 242, 210),
        [System.Drawing.Color]::FromArgb(255, 188, 156, 103)
    )
    $Graphics.FillEllipse($openingBrush, (S 492), (S 260), (S 132), (S 52))
    $openingBrush.Dispose()

    $openingPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(188, 128, 110, 82), (S 4))
    $Graphics.DrawEllipse($openingPen, (S 492), (S 260), (S 132), (S 52))
    $openingPen.Dispose()

    $bulbGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(88, 255, 233, 178))
    $Graphics.FillEllipse($bulbGlow, (S 498), (S 198), (S 106), (S 104))
    $Graphics.FillEllipse($bulbGlow, (S 526), (S 226), (S 58), (S 56))
    $bulbGlow.Dispose()

    $bulbCore = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 251, 232))
    $Graphics.FillEllipse($bulbCore, (S 532), (S 232), (S 44), (S 44))
    $bulbCore.Dispose()

    $capBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        (P 500 118),
        (P 560 182),
        [System.Drawing.Color]::FromArgb(255, 244, 248, 255),
        [System.Drawing.Color]::FromArgb(255, 100, 110, 122)
    )
    $Graphics.FillEllipse($capBrush, (S 510), (S 116), (S 50), (S 62))
    $capBrush.Dispose()

    $capPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(210, 44, 48, 56), (S 4))
    $Graphics.DrawEllipse($capPen, (S 510), (S 116), (S 50), (S 62))
    $capPen.Dispose()

    $capPinBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 214, 220, 228))
    $Graphics.FillEllipse($capPinBrush, (S 498), (S 126), (S 20), (S 20))
    $capPinBrush.Dispose()

    $shadeRimHighlight = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(125, 255, 255, 255), (S 2))
    $Graphics.DrawArc($shadeRimHighlight, (S 464), (S 164), (S 96), (S 56), 210, 115)
    $shadeRimHighlight.Dispose()

    Draw-GlowDot -Graphics $Graphics -X (S 474) -Y (S 372) -Size (S 4.8) -Color ([System.Drawing.Color]::FromArgb(255, 247, 213, 122))
    Draw-GlowDot -Graphics $Graphics -X (S 518) -Y (S 392) -Size (S 5.2) -Color ([System.Drawing.Color]::FromArgb(255, 248, 217, 128))
    Draw-GlowDot -Graphics $Graphics -X (S 560) -Y (S 374) -Size (S 4.2) -Color ([System.Drawing.Color]::FromArgb(255, 245, 208, 116))
    Draw-GlowDot -Graphics $Graphics -X (S 596) -Y (S 420) -Size (S 3.4) -Color ([System.Drawing.Color]::FromArgb(255, 241, 200, 104))

    $backCoverLeft.Dispose()
    $backCoverRight.Dispose()
    $mainLeftPage.Dispose()
    $mainRightPage.Dispose()
    $bookmarkLeftOuter.Dispose()
    $bookmarkLeftInner.Dispose()
    $bookmarkRightInner.Dispose()
    $bookmarkRightOuter.Dispose()
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
