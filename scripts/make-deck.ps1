# Build the 10-slide QuickCompare HK deck with PowerPoint COM.
# Narrative: origin story -> what is built -> how it is built.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\make-deck.ps1
# Output: deck\QuickCompare-HK.pptx and deck\QuickCompare-HK.pdf

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "deck"
$shots = Join-Path $outDir "shots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$pptx = Join-Path $outDir "QuickCompare-HK.pptx"
$pdf = Join-Path $outDir "QuickCompare-HK.pdf"

function RGB($r, $g, $b) { return ([int]$r) + ([int]$g * 256) + ([int]$b * 65536) }

$BG     = RGB 14 17 22
$CARD   = RGB 22 26 33
$CARD2  = RGB 30 36 45
$TEXT   = RGB 233 236 241
$MUTED  = RGB 154 163 178
$ACCENT = RGB 47 211 181
$AMBER  = RGB 255 176 32
$WHITE  = RGB 255 255 255
$HK     = [char]36

$app = New-Object -ComObject PowerPoint.Application
$app.Visible = -1

$pres = $app.Presentations.Add()
$pres.PageSetup.SlideWidth = 960
$pres.PageSetup.SlideHeight = 540

function New-Slide {
  $slide = $pres.Slides.Add($pres.Slides.Count + 1, 12)
  $slide.FollowMasterBackground = 0
  $slide.Background.Fill.Solid()
  $slide.Background.Fill.ForeColor.RGB = $BG
  return $slide
}

function Add-Text($slide, $text, $l, $t, $w, $h, $size, $bold, $color, $align) {
  $shape = $slide.Shapes.AddTextbox(1, $l, $t, $w, $h)
  $tf = $shape.TextFrame
  $tf.WordWrap = -1
  $tf.MarginLeft = 0
  $tf.MarginRight = 0
  $tf.MarginTop = 0
  $tf.MarginBottom = 0
  $tr = $tf.TextRange
  $tr.Text = $text
  $tr.Font.Name = "Segoe UI"
  $tr.Font.Size = $size
  $tr.Font.Bold = if ($bold) { -1 } else { 0 }
  $tr.Font.Color.RGB = $color
  $tr.ParagraphFormat.Alignment = $align
  return $shape
}

function Add-Box($slide, $l, $t, $w, $h, $fill, $round) {
  $type = if ($round) { 5 } else { 1 }
  $s = $slide.Shapes.AddShape($type, $l, $t, $w, $h)
  $s.Fill.ForeColor.RGB = $fill
  $s.Line.Visible = 0
  return $s
}

function Add-Accent($slide, $l, $t, $w) {
  $s = $slide.Shapes.AddShape(1, $l, $t, $w, 4)
  $s.Fill.ForeColor.RGB = $ACCENT
  $s.Line.Visible = 0
}

function Add-Chrome($slide, $number, $section) {
  Add-Text $slide "QuickCompare HK" 64 505 300 20 9 $false $MUTED 1 | Out-Null
  Add-Text $slide $section 364 505 400 20 9 $false $MUTED 2 | Out-Null
  Add-Text $slide ("{0:D2}" -f $number) 876 500 20 22 12 $true $ACCENT 3 | Out-Null
}

function Add-Title($slide, $title, $kicker) {
  Add-Text $slide $kicker 64 44 832 20 11 $true $ACCENT 1 | Out-Null
  Add-Text $slide $title 64 70 832 52 32 $true $TEXT 1 | Out-Null
  Add-Accent $slide 64 126 64
}

function Add-Bullets($slide, $lines, $l, $t, $w, $h, $size) {
  $shape = $slide.Shapes.AddTextbox(1, $l, $t, $w, $h)
  $tf = $shape.TextFrame
  $tf.WordWrap = -1
  $tf.MarginLeft = 0
  $tf.MarginRight = 0
  $tf.MarginTop = 0
  $tf.MarginBottom = 0
  $tr = $tf.TextRange
  $tr.Text = (($lines | ForEach-Object { "$([char]0x2022)  " + $_ }) -join "`r")
  $tr.Font.Name = "Segoe UI"
  $tr.Font.Size = $size
  $tr.Font.Color.RGB = $TEXT
  $tr.ParagraphFormat.Alignment = 1
  $tr.ParagraphFormat.SpaceAfter = 12
  return $shape
}

function Add-Shot($slide, $file, $l, $t, $w, $caption) {
  if (-not (Test-Path $file)) { return $null }
  $h = [math]::Round($w * 810 / 1440, 0)
  $pic = $slide.Shapes.AddPicture($file, 0, -1, $l, $t, $w, $h)
  $pic.Line.Visible = -1
  $pic.Line.ForeColor.RGB = RGB 64 74 88
  $pic.Line.Weight = 1
  if ($caption) {
    Add-Text $slide $caption $l ($t + $h + 8) $w 18 9 $false $MUTED 1 | Out-Null
  }
  return $pic
}

# ---------------------------------------------------------------- slide 1
$s = New-Slide
Add-Text $s "SUPERMARKET PRICES, COMPARED" 64 86 400 20 12 $true $ACCENT 1 | Out-Null
Add-Text $s "QuickCompare" 64 118 420 56 44 $true $WHITE 1 | Out-Null
Add-Text $s "HK" 64 176 120 40 28 $true $ACCENT 1 | Out-Null
Add-Text $s "One place to see what a product costs at Wellcome, PNS and Market Place - and which shop is cheapest today." 64 232 400 110 16 $false $MUTED 1 | Out-Null
Add-Accent $s 64 352 86

Add-Text $s "48,062" 64 386 140 34 24 $true $ACCENT 1 | Out-Null
Add-Text $s "products" 64 418 140 18 10 $false $MUTED 1 | Out-Null
Add-Text $s "3" 216 386 100 34 24 $true $WHITE 1 | Out-Null
Add-Text $s "stores" 216 418 100 18 10 $false $MUTED 1 | Out-Null
Add-Text $s "8,685" 300 386 140 34 24 $true $AMBER 1 | Out-Null
Add-Text $s "comparisons" 300 418 140 18 10 $false $MUTED 1 | Out-Null

Add-Text $s "Live at catarungpt.github.io/quickcompare-hk" 64 462 500 20 10 $false $MUTED 1 | Out-Null
Add-Shot $s (Join-Path $shots "home.png") 500 110 400 "The live site, 21 November 2026" | Out-Null

# ---------------------------------------------------------------- slide 2
$s = New-Slide
Add-Title $s "It started with a trolley" "ORIGIN STORY"

Add-Text $s "Standing in a supermarket, holding a carton of milk, wondering whether the shop next door was cheaper." 64 176 560 80 20 $false $TEXT 1 | Out-Null
Add-Text $s "Checking meant three websites, three different product names and a note on my phone. Ten minutes of clicking to answer one simple question." 64 268 560 80 16 $false $MUTED 1 | Out-Null

Add-Box $s 660 168 236 220 $CARD $true | Out-Null
Add-Text $s "The question" 680 186 196 20 10 $true $ACCENT 1 | Out-Null
Add-Text $s "Is this actually cheaper somewhere else?" 680 212 196 90 18 $true $TEXT 1 | Out-Null
Add-Text $s "That was the whole brief." 680 330 196 40 10 $false $MUTED 1 | Out-Null
Add-Chrome $s 2 "Origin"

# ---------------------------------------------------------------- slide 3
$s = New-Slide
Add-Title $s "Why it is hard to answer" "THE PROBLEM"

$cols = @(
  @{ x = 64;  n = "3";      h = "Separate shops"; b = "Wellcome, PNS and Market Place each run their own website and their own catalogue." },
  @{ x = 356; n = "3";      h = "Different names"; b = "The same product is described differently in each shop, so names do not line up." },
  @{ x = 648; n = "Daily";  h = "Moving prices"; b = "Promotions, case deals and stock change all the time, so yesterday's note is already wrong." }
)
foreach ($c in $cols) {
  Add-Box $s $c.x 168 248 220 $CARD $true | Out-Null
  Add-Text $s $c.n $($c.x + 20) 186 200 44 28 $true $ACCENT 1 | Out-Null
  Add-Text $s $c.h $($c.x + 20) 238 208 24 14 $true $TEXT 1 | Out-Null
  Add-Text $s $c.b $($c.x + 20) 270 208 100 11 $false $MUTED 1 | Out-Null
}
Add-Text $s "Three tabs and a notebook is not a system." 64 420 832 30 16 $true $TEXT 1 | Out-Null
Add-Chrome $s 3 "Problem"

# ---------------------------------------------------------------- slide 4
$s = New-Slide
Add-Title $s "So this is what I built" "WHAT IT IS"

Add-Text $s "One search across all three supermarkets. Every price in one place, and a direct link to the shop that sells it." 64 146 520 50 14 $false $MUTED 1 | Out-Null
Add-Shot $s (Join-Path $shots "home.png") 64 204 480 "The home page" | Out-Null

Add-Box $s 620 160 276 96 $CARD $true | Out-Null
Add-Text $s "48,062" 636 172 240 30 20 $true $ACCENT 1 | Out-Null
Add-Text $s "products from three stores" 636 204 240 18 10 $false $MUTED 1 | Out-Null

Add-Box $s 620 268 276 96 $CARD $true | Out-Null
Add-Text $s "8,685" 636 280 240 30 20 $true $AMBER 1 | Out-Null
Add-Text $s "products compared across shops" 636 312 240 18 10 $false $MUTED 1 | Out-Null

Add-Box $s 620 376 276 96 $CARD $true | Out-Null
Add-Text $s "10,514" 636 388 240 30 20 $true $WHITE 1 | Out-Null
Add-Text $s "products on offer right now" 636 420 240 18 10 $false $MUTED 1 | Out-Null

Add-Chrome $s 4 "What it is"

# ---------------------------------------------------------------- slide 5
$s = New-Slide
Add-Title $s "Find anything in seconds" "WHAT YOU CAN DO"

Add-Shot $s (Join-Path $shots "browse.png") 64 150 560 "Browse products" | Out-Null

Add-Bullets $s @(
  "Search by name, brand, barcode or pack size",
  "Filter by store or category",
  "See the price, the stock and any promotion",
  "Open the exact product page on the store's own site"
) 664 170 232 260 12 | Out-Null
Add-Chrome $s 5 "Search"

# ---------------------------------------------------------------- slide 6
$s = New-Slide
Add-Title $s "The same product, side by side" "THE ANSWER"

Add-Shot $s (Join-Path $shots "compare.png") 64 150 560 "Compare stores" | Out-Null

Add-Text $s "The cheapest price is green. Every other store shows exactly how much more it charges." 664 172 232 80 13 $false $TEXT 1 | Out-Null

Add-Box $s 664 270 232 64 $CARD $true | Out-Null
Add-Text $s "PNS" 678 280 120 18 10 $true $TEXT 1 | Out-Null
Add-Text $s "HK${HK}257.90" 678 300 120 20 12 $true $ACCENT 1 | Out-Null

Add-Box $s 664 344 232 64 $CARD $true | Out-Null
Add-Text $s "Wellcome" 678 354 120 18 10 $true $TEXT 1 | Out-Null
Add-Text $s "+HK${HK}172.00" 678 374 120 20 12 $true $MUTED 1 | Out-Null

Add-Text $s "One tap opens the product page on that store's website." 664 424 232 50 10 $false $MUTED 1 | Out-Null
Add-Chrome $s 6 "Compare"

# ---------------------------------------------------------------- slide 7
$s = New-Slide
Add-Title $s "Spot the real discounts" "SAVINGS"

Add-Shot $s (Join-Path $shots "deals.png") 64 150 560 "Current price drops" | Out-Null

Add-Text $s "Every offer keeps its original price, so a discount is a real discount - not just a sticker." 664 172 232 80 13 $false $TEXT 1 | Out-Null

Add-Text $s "10,514" 664 270 232 34 24 $true $ACCENT 1 | Out-Null
Add-Text $s "products currently on offer" 664 304 232 20 10 $false $MUTED 1 | Out-Null
Add-Text $s "89%" 664 344 232 34 24 $true $AMBER 1 | Out-Null
Add-Text $s "biggest discount today" 664 378 232 20 10 $false $MUTED 1 | Out-Null
Add-Text $s "Sorted by the biggest saving, so the best deals are at the top." 664 420 232 50 10 $false $MUTED 1 | Out-Null
Add-Chrome $s 7 "Deals"

# ---------------------------------------------------------------- slide 8
$s = New-Slide
Add-Title $s "How it is built" "BEHIND THE SCENES"

$steps = @(
  @{ x = 64;  n = "01"; h = "Collect"; b = "Read each store's public catalogue, the same pages a shopper sees." },
  @{ x = 278; n = "02"; h = "Clean";   b = "Learn each product's brand and pack size, so names can be compared." },
  @{ x = 492; n = "03"; h = "Match";   b = "Pair the same product across shops using brand, size, name and photo." },
  @{ x = 706; n = "04"; h = "Show";    b = "Rebuild the index and the page, then links go straight to the store." }
)
foreach ($st in $steps) {
  Add-Box $s $st.x 164 190 150 $CARD $true | Out-Null
  Add-Text $s $st.n $($st.x + 14) 178 162 20 10 $true $ACCENT 1 | Out-Null
  Add-Text $s $st.h $($st.x + 14) 202 162 26 15 $true $TEXT 1 | Out-Null
  Add-Text $s $st.b $($st.x + 14) 238 162 60 10 $false $MUTED 1 | Out-Null
}
Add-Box $s 64 340 832 96 $CARD2 $true | Out-Null
Add-Text $s "48,062 products - 5,915 matched groups - 21,042 photos compared" 84 358 792 24 13 $true $TEXT 1 | Out-Null
Add-Text $s "A full refresh takes about twenty minutes and runs on a normal laptop. No accounts, no tracking, no middleman." 84 388 792 34 11 $false $MUTED 1 | Out-Null
Add-Chrome $s 8 "How"

# ---------------------------------------------------------------- slide 9
$s = New-Slide
Add-Title $s "The AI was the builder, not the product" "THE AI PARTNER"

Add-Bullets $s @(
  "I described the goal; the AI chose the tools and the order of work.",
  "It opened the real store websites and read their public data, rather than guessing.",
  "It wrote the collector, the matching and the page - then tested each step against the live site.",
  "OpenRouter routed each request to the right model, so the project was never tied to one provider.",
  "Every price in the index was seen by a browser before it was accepted."
) 64 164 560 300 13 | Out-Null

Add-Box $s 664 168 232 220 $CARD $true | Out-Null
Add-Text $s "The rule" 682 186 196 20 10 $true $ACCENT 1 | Out-Null
Add-Text $s "Never claim a price the browser has not seen." 682 212 196 100 16 $true $TEXT 1 | Out-Null
Add-Text $s "That one rule kept the work honest." 682 320 196 50 10 $false $MUTED 1 | Out-Null
Add-Chrome $s 9 "AI"

# ---------------------------------------------------------------- slide 10
$s = New-Slide
Add-Title $s "What comes next" "NEXT"

Add-Bullets $s @(
  "Refresh automatically every six hours",
  "Add more Hong Kong stores",
  "Improve matching for the last few product gaps",
  "Keep the code and the data free on GitHub"
) 64 168 520 260 14 | Out-Null

Add-Box $s 620 168 276 200 $CARD $true | Out-Null
Add-Text $s "Try it" 636 186 244 20 10 $true $ACCENT 1 | Out-Null
Add-Text $s "catarungpt.github.io/quickcompare-hk" 636 214 244 60 13 $true $TEXT 1 | Out-Null
Add-Text $s "github.com/catarungpt/quickcompare-hk" 636 286 244 60 11 $false $MUTED 1 | Out-Null

Add-Text $s "Built in Hong Kong, for the weekly shop." 64 430 520 24 12 $false $MUTED 1 | Out-Null
Add-Chrome $s 10 "Next"

# ---------------------------------------------------------------- save
if (Test-Path $pptx) { Remove-Item $pptx -Force }
if (Test-Path $pdf) { Remove-Item $pdf -Force }

$pres.SaveAs($pptx, 24)
try { $pres.SaveAs($pdf, 32) } catch { Write-Host "PDF export skipped: $($_.Exception.Message)" }
$pres.Close()
$app.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($app) | Out-Null
[GC]::Collect()

Write-Host "PPTX: $pptx"
if (Test-Path $pdf) { Write-Host "PDF:  $pdf" }
