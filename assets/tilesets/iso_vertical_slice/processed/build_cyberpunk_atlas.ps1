# One-off atlas builder (PowerShell + System.Drawing).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Resize-ToCell {
    param(
        [System.Drawing.Bitmap]$Src,
        [System.Drawing.Rectangle]$Crop,
        [int]$Cell = 64
    )
    if ($Crop.X -lt 0) { $Crop.X = 0 }
    if ($Crop.Y -lt 0) { $Crop.Y = 0 }
    if ($Crop.Right -gt $Src.Width) { $Crop.Width = $Src.Width - $Crop.X }
    if ($Crop.Bottom -gt $Src.Height) { $Crop.Height = $Src.Height - $Crop.Y }
    if ($Crop.Width -le 0 -or $Crop.Height -le 0) { throw "Bad crop rectangle" }

    $bmp = New-Object System.Drawing.Bitmap($Cell, $Cell)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $dest = New-Object System.Drawing.Rectangle(0, 0, $Cell, $Cell)
    $g.DrawImage($Src, $dest, $Crop, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    return $bmp
}

$processed = $PSScriptRoot
$root = Split-Path -Parent $processed
$mono = Join-Path $root "source\monogon"

$sources = @{
    pavement   = Join-Path $mono "Isometric Cyberpunk Streets\Architecture\Cyberpunk Streets-140-Pavement-3.png"
    groundtile = Join-Path $mono "Isometric Cyberpunk Streets\Architecture\Cyberpunk Streets-6-GroundTile-2.png"
    road       = Join-Path $mono "Isometric Cyberpunk City\StreetModules\Road_Chunk6.png"
    wallA      = Join-Path $mono "Isometric Cyberpunk Streets\Architecture\Cyberpunk Streets-14-BuildingModule-17.png"
    wallB      = Join-Path $mono "Isometric Cyberpunk Buildings\Building\SciFi_Buildings-46-Base_A.png"
    door       = Join-Path $mono "Isomectric Cyberpunk Interior\Props&Characters\Megabuilding-94-Door-1.png"
    vent       = Join-Path $mono "Isometric Cyberpunk Streets\Props\Cyberpunk Streets-156-Vent-4.png"
    box        = Join-Path $mono "Isometric Cyberpunk Streets\Props\Cyberpunk Streets-15-Box_Pharmacy-1.png"
    metal      = Join-Path $mono "Isometric Cyberpunk Streets\Props\Cyberpunk Streets-146-MetalCorner.png"
    pills      = Join-Path $mono "Isometric Cyberpunk Streets\Props\Cyberpunk Streets-138-Pills-1.png"
    cable      = Join-Path $mono "Isometric Cyberpunk Streets\Props\Cyberpunk Streets-12-Cable-24.png"
}

foreach ($k in $sources.Keys) {
    if (-not (Test-Path $sources[$k])) { throw "Missing source $($k): $($sources[$k])" }
}

$cell = 64
$cols = 6
$rows = 2
$atlas = New-Object System.Drawing.Bitmap(($cols * $cell), ($rows * $cell))
$gAtlas = [System.Drawing.Graphics]::FromImage($atlas)
$gAtlas.Clear([System.Drawing.Color]::FromArgb(255, 16, 12, 28))

function Blit-Cell([System.Drawing.Graphics]$G, [int]$Col, [int]$Row, [System.Drawing.Bitmap]$Bmp, [int]$CellSz) {
    $G.DrawImage($Bmp, ($Col * $CellSz), ($Row * $CellSz))
    $Bmp.Dispose()
}

# Row 0
$pav = [System.Drawing.Bitmap]::FromFile($sources.pavement)
$ph = [Math]::Min(349, $pav.Height)
Blit-Cell $gAtlas 0 0 (Resize-ToCell $pav ([System.Drawing.Rectangle]::new(0, 0, 268, $ph)) $cell) $cell
$pav.Dispose()

$gt = [System.Drawing.Bitmap]::FromFile($sources.groundtile)
$gh = [Math]::Min(669, $gt.Height)
Blit-Cell $gAtlas 1 0 (Resize-ToCell $gt ([System.Drawing.Rectangle]::new(0, 0, 287, $gh)) $cell) $cell
$gt.Dispose()

$rd = [System.Drawing.Bitmap]::FromFile($sources.road)
$rw = $rd.Width
$rh = $rd.Height
$sliceW = [Math]::Min(220, $rw)
$cx = [Math]::Max(0, [int](($rw - $sliceW) / 2))
Blit-Cell $gAtlas 2 0 (Resize-ToCell $rd ([System.Drawing.Rectangle]::new($cx, 0, $sliceW, $rh)) $cell) $cell
$rd.Dispose()

$wa = [System.Drawing.Bitmap]::FromFile($sources.wallA)
$wax = 80
$way = [Math]::Min(200, $wa.Height - 120)
if ($way -lt 0) { $way = 0 }
$wah = [Math]::Min(340, $wa.Height - $way)
Blit-Cell $gAtlas 3 0 (Resize-ToCell $wa ([System.Drawing.Rectangle]::new($wax, $way, 420, $wah)) $cell) $cell
$wa.Dispose()

$wb = [System.Drawing.Bitmap]::FromFile($sources.wallB)
$wbx = 400
$wby = [Math]::Min(180, $wb.Height - 200)
if ($wby -lt 0) { $wby = 0 }
$wbw = [Math]::Min(520, $wb.Width - $wbx)
$wbh = [Math]::Min(380, $wb.Height - $wby)
Blit-Cell $gAtlas 4 0 (Resize-ToCell $wb ([System.Drawing.Rectangle]::new($wbx, $wby, $wbw, $wbh)) $cell) $cell
$wb.Dispose()

$dr = [System.Drawing.Bitmap]::FromFile($sources.door)
Blit-Cell $gAtlas 5 0 (Resize-ToCell $dr ([System.Drawing.Rectangle]::new(0, 0, $dr.Width, $dr.Height)) $cell) $cell
$dr.Dispose()

# Row 1 props
$vt = [System.Drawing.Bitmap]::FromFile($sources.vent)
Blit-Cell $gAtlas 0 1 (Resize-ToCell $vt ([System.Drawing.Rectangle]::new(0, 0, $vt.Width, $vt.Height)) $cell) $cell

$bx = [System.Drawing.Bitmap]::FromFile($sources.box)
Blit-Cell $gAtlas 1 1 (Resize-ToCell $bx ([System.Drawing.Rectangle]::new(0, 0, $bx.Width, $bx.Height)) $cell) $cell

$mt = [System.Drawing.Bitmap]::FromFile($sources.metal)
Blit-Cell $gAtlas 2 1 (Resize-ToCell $mt ([System.Drawing.Rectangle]::new(0, 0, $mt.Width, $mt.Height)) $cell) $cell

$pl = [System.Drawing.Bitmap]::FromFile($sources.pills)
Blit-Cell $gAtlas 3 1 (Resize-ToCell $pl ([System.Drawing.Rectangle]::new(0, 0, $pl.Width, $pl.Height)) $cell) $cell

$cb = [System.Drawing.Bitmap]::FromFile($sources.cable)
$cw = [Math]::Min(280, $cb.Width)
Blit-Cell $gAtlas 4 1 (Resize-ToCell $cb ([System.Drawing.Rectangle]::new(0, 0, $cw, $cb.Height)) $cell) $cell

$gAtlas.Dispose()
$outPath = Join-Path $processed "cyberpunk_iso_atlas.png"
$atlas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$atlas.Dispose()
Write-Host "Wrote $outPath"
