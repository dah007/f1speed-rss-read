<#
.SYNOPSIS
    Regenerates F1RssFeedRead/Assets/*.png from f1speed-rss-a-trail-arcs.svg at the
    exact pixel sizes MSIX packaging requires.
.DESCRIPTION
    Renders the icon's shapes directly via GDI+ instead of resampling a raster, so
    every size is crisp. This only works because the source SVG is simple enough to
    replicate exactly:
      - The three "arcs" are quarter-circles concentric on the dot at (8.5,23.5),
        with radii 9.5/16/21.5 (verified algebraically from the SVG's path data —
        each arc's endpoints are exactly radius-9.5/16/21.5 from that point).
      - The whole group has an SVG transform of
        translate(2.6,0) skewX(-10deg) translate(1.5,0), applied in that nested
        order, which combines to the single affine map
        x' = x - tan(10deg)*y + 4.1 ; y' = y  in the 32-unit viewBox space.
    If you ever redesign the icon (edit the .svg), this script needs updating to
    match — it does not parse the SVG, it hardcodes its shapes.
#>

Add-Type -AssemblyName System.Drawing

function New-IconBitmap {
    param(
        [int]$Width,
        [int]$Height,
        [bool]$Plated,
        [int]$IconSize = 0   # if >0, draws the plated icon at this size, centered in Width x Height (for banners)
    )

    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $bg = [System.Drawing.Color]::FromArgb(255, 0x0B, 0x0B, 0x0D)
    $orange = [System.Drawing.Color]::FromArgb(255, 0xE9, 0xA0, 0x3B)
    $orangeFaint = [System.Drawing.Color]::FromArgb(102, 0xE9, 0xA0, 0x3B) # 0.4 opacity

    if ($IconSize -gt 0) {
        # Banner: fill the whole canvas with the background color, then draw the
        # square plated icon centered horizontally, full height.
        $g.Clear($bg)
        $x = [int](($Width - $IconSize) / 2)
        Draw-Glyph -g $g -size $IconSize -offsetX $x -offsetY 0 -plated $true -bg $bg -orange $orange -orangeFaint $orangeFaint
    }
    else {
        Draw-Glyph -g $g -size $Width -offsetX 0 -offsetY 0 -plated $Plated -bg $bg -orange $orange -orangeFaint $orangeFaint
    }

    $g.Dispose()
    return $bmp
}

function Draw-Glyph {
    param($g, [int]$size, [int]$offsetX, [int]$offsetY, [bool]$plated, $bg, $orange, $orangeFaint)

    $scale = $size / 32.0

    if ($plated) {
        $r = 7.0 * $scale
        $d = $r * 2
        $x0 = $offsetX
        $y0 = $offsetY
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc($x0, $y0, $d, $d, 180, 90)
        $path.AddArc($x0 + $size - $d, $y0, $d, $d, 270, 90)
        $path.AddArc($x0 + $size - $d, $y0 + $size - $d, $d, $d, 0, 90)
        $path.AddArc($x0, $y0 + $size - $d, $d, $d, 90, 90)
        $path.CloseFigure()
        $brush = New-Object System.Drawing.SolidBrush($bg)
        $g.FillPath($brush, $path)
        $g.SetClip($path)
        $brush.Dispose()
        $path.Dispose()
    }

    # Local (32-unit viewBox) transform: translate(2.6,0) . skewX(-10deg) . translate(1.5,0)
    # combines to x' = x - tan(10deg)*y + 4.1 ; y' = y  (derived by hand from the SVG)
    $tan10 = [math]::Tan(10.0 * [math]::PI / 180.0)
    $local = New-Object System.Drawing.Drawing2D.Matrix(1, 0, (-$tan10), 1, 4.1, 0)
    $final = New-Object System.Drawing.Drawing2D.Matrix($scale, 0, 0, $scale, 0, 0)
    $final.Multiply($local, [System.Drawing.Drawing2D.MatrixOrder]::Prepend)
    $offset = New-Object System.Drawing.Drawing2D.Matrix(1, 0, 0, 1, $offsetX, $offsetY)
    $final.Multiply($offset, [System.Drawing.Drawing2D.MatrixOrder]::Append)
    $g.Transform = $final

    # Dot
    $dotBrush = New-Object System.Drawing.SolidBrush($orange)
    $g.FillEllipse($dotBrush, 8.5 - 3.1, 23.5 - 3.1, 6.2, 6.2)
    $dotBrush.Dispose()

    # Three concentric quarter-arcs centered at (8.5, 23.5), sweeping from
    # straight-up (-90deg) to straight-right (0deg) in GDI+'s clockwise/y-down convention.
    $arcs = @(
        @{ R = 9.5;  W = 3.6; Color = $orange }
        @{ R = 16.0; W = 3.6; Color = $orange }
        @{ R = 21.5; W = 2.6; Color = $orangeFaint }
    )
    foreach ($a in $arcs) {
        $pen = New-Object System.Drawing.Pen($a.Color, $a.W)
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawArc($pen, 8.5 - $a.R, 23.5 - $a.R, $a.R * 2, $a.R * 2, -90, 90)
        $pen.Dispose()
    }

    $g.ResetTransform()
    $g.ResetClip()
}

function Save-Png {
    param($bmp, [string]$path)
    $dir = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Wrote $path"
}

$assetsDir = Join-Path $PSScriptRoot "..\F1RssFeedRead\Assets"

Save-Png (New-IconBitmap -Width 88   -Height 88  -Plated $true)                "$assetsDir\Square44x44Logo.scale-200.png"
Save-Png (New-IconBitmap -Width 24   -Height 24  -Plated $false)               "$assetsDir\Square44x44Logo.targetsize-24_altform-unplated.png"
Save-Png (New-IconBitmap -Width 300  -Height 300 -Plated $true)                "$assetsDir\Square150x150Logo.scale-200.png"
Save-Png (New-IconBitmap -Width 300  -Height 300 -Plated $true)                "$assetsDir\StoreLogo.png"
Save-Png (New-IconBitmap -Width 48   -Height 48  -Plated $true)                "$assetsDir\LockScreenLogo.scale-200.png"
Save-Png (New-IconBitmap -Width 620  -Height 300 -Plated $true -IconSize 300)  "$assetsDir\Wide310x150Logo.scale-200.png"
Save-Png (New-IconBitmap -Width 1240 -Height 600 -Plated $true -IconSize 600) "$assetsDir\SplashScreen.scale-200.png"

Write-Host "`nDone." -ForegroundColor Green
