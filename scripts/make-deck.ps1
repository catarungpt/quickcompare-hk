# Build the 10-slide QuickCompare HK deck with PowerPoint COM.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\make-deck.ps1
# Output: deck\QuickCompare-HK.pptx and deck\QuickCompare-HK.pdf

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "deck"
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
  if ($kicker) { Add-Text $slide $kicker 64 44 832 20 11 $true $ACCENT 1 | Out-Null }
  $top = if ($kicker) { 70 } else { 56 }
  Add-Text $slide $title 64 $top 832 52 32 $true $TEXT 1 | Out-Null
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

# ---------------------------------------------------------------- slide 1
$s = New-Slide
Add-Box $s 0 0 960 540 $BG $false | Out-Null
Add-Box $s 640 0 320 540 $CARD $false | Out-Null

Add-Text $s "SUPERMARKET PRICES, COMPARED" 64 92 520 20 12 $true $ACCENT 1 | Out-Null
Add-Text $s "QuickCompare HK" 64 128 540 84 46 $true $WHITE 1 | Out-Null
Add-Text $s "How an OpenRouter-routed AI agent built a live price index for 48,000+ Hong Kong supermarket products." 64 222 520 110 17 $false $MUTED 1 | Out-Null
Add-Accent $s 64 356 86
Add-Text $s "Wellcome   |   PNS   |   Market Place" 64 382 520 24 13 $false $TEXT 1 | Out-Null
Add-Text $s "Live at catarungpt.github.io/quickcompare-hk" 64 410 520 24 12 $false $ACCENT 1 | Out-Null

Add-Text $s "48,062" 700 190 220 46 36 $true $ACCENT 2 | Out-Null
Add-Text $s "products indexed" 700 238 220 20 11 $false $MUTED 2 | Out-Null
Add-Text $s "3" 700 282 220 40 32 $true $WHITE 2 | Out-Null
Add-Text $s "stores" 700 324 220 20 11 $false $MUTED 2 | Out-Null
Add-Text $s "8,685" 700 368 220 40 28 $true $AMBER 2 | Out-Null
Add-Text $s "comparisons" 700 408 220 20 11 $false $MUTED 2 | Out-Null

# ---------------------------------------------------------------- slide 2
$s = New-Slide
Add-Title $s "The problem: three tabs and a notebook" "WHY THIS EXISTS"

$cols = @(
  @{ x = 64;  n = "3+";  h = "Chains, no shared view"; b = "Wellcome, PNS and Market Place each publish their own catalogue in their own format." },
  @{ x = 356; n = "Daily"; h = "Prices move"; b = "Promotions, case deals and stock change constantly, so yesterday's note is already wrong." },
  @{ x = 648; n = "Manual"; h = "Comparison is guesswork"; b = "Names differ between stores, so matching the same product by hand is slow and error-prone." }
)
foreach ($c in $cols) {
  Add-Box $s $c.x 170 248 230 $CARD $true | Out-Null
  Add-Text $s $c.n $($c.x + 20) 190 200 44 30 $true $ACCENT 1 | Out-Null
  Add-Text $s $c.h $($c.x + 20) 244 208 24 14 $true $TEXT 1 | Out-Null
  Add-Text $s $c.b $($c.x + 20) 276 208 100 11 $false $MUTED 1 | Out-Null
}
Add-Text $s "The goal: one search, every price, a direct link to the store's own product page." 64 424 832 30 15 $true $TEXT 1 | Out-Null
Add-Chrome $s 2 "Problem"

# ---------------------------------------------------------------- slide 3
$s = New-Slide
Add-Title $s "What we shipped" "THE PRODUCT"

$stats = @(
  @{ x = 64;  n = "48,062"; l = "products" },
  @{ x = 278; n = "3";      l = "stores" },
  @{ x = 492; n = "10,514"; l = "price drops" },
  @{ x = 706; n = "8,685";  l = "comparisons" }
)
foreach ($st in $stats) {
  Add-Box $s $st.x 168 190 96 $CARD $true | Out-Null
  Add-Text $s $st.n $($st.x + 14) 186 162 38 22 $true $ACCENT 1 | Out-Null
  Add-Text $s $st.l $($st.x + 14) 228 162 20 10 $false $MUTED 1 | Out-Null
}

Add-Bullets $s @(
  "Search by product, brand, barcode, pack size or category",
  "Compare the same product across stores, cheapest first",
  "See the exact price difference for every store",
  "Save local price alerts, no account required",
  "Every row links straight to the store's product page"
) 64 304 832 170 15 | Out-Null
Add-Chrome $s 3 "Product"

# ---------------------------------------------------------------- slide 4
$s = New-Slide
Add-Title $s "The AI stack: one gateway, many tools" "OPENROUTER"

Add-Box $s 64 176 176 88 $CARD $true | Out-Null
Add-Text $s "Goal" 80 190 144 20 11 $true $MUTED 1 | Out-Null
Add-Text $s "Compare HK grocery prices" 80 212 144 44 11 $false $TEXT 1 | Out-Null

Add-Text $s "->" 250 206 30 30 20 $true $ACCENT 2 | Out-Null

Add-Box $s 292 176 176 88 $CARD2 $true | Out-Null
Add-Text $s "OpenRouter" 308 190 144 20 11 $true $ACCENT 1 | Out-Null
Add-Text $s "Routes each request to the model" 308 212 144 44 11 $false $TEXT 1 | Out-Null

Add-Text $s "->" 478 206 30 30 20 $true $ACCENT 2 | Out-Null

Add-Box $s 520 176 176 88 $CARD $true | Out-Null
Add-Text $s "Agent model" 536 190 144 20 11 $true $MUTED 1 | Out-Null
Add-Text $s "Plans, writes code, reads results" 536 212 144 44 11 $false $TEXT 1 | Out-Null

Add-Text $s "->" 706 206 30 30 20 $true $ACCENT 2 | Out-Null

Add-Box $s 748 176 148 88 $CARD2 $true | Out-Null
Add-Text $s "Tools" 764 190 116 20 11 $true $ACCENT 1 | Out-Null
Add-Text $s "Browser  |  Shell  |  Files" 764 212 116 44 11 $false $TEXT 1 | Out-Null

Add-Box $s 64 312 832 116 $CARD $true | Out-Null
Add-Text $s "The loop that did the work" 80 328 500 22 13 $true $TEXT 1 | Out-Null
Add-Text $s "Observe  ->  hypothesise  ->  call a tool  ->  read the real result  ->  fix  ->  repeat" 80 356 800 24 13 $false $ACCENT 1 | Out-Null
Add-Text $s "No step was taken on faith: every endpoint, price and match was verified against the live site before it was accepted." 80 386 800 32 11 $false $MUTED 1 | Out-Null
Add-Chrome $s 4 "AI stack"

# ---------------------------------------------------------------- slide 5
$s = New-Slide
Add-Title $s "Discovery: the AI found APIs nobody documented" "RESEARCH"

Add-Bullets $s @(
  "Read robots.txt before touching any store",
  "Opened each site in a real browser and inspected network traffic",
  "Found the hidden JSON APIs behind the storefronts",
  "Learned the PNS brand field only appears with fields=FULL",
  "Switched Market Place to EN: otherwise names come back in Chinese"
) 64 164 470 300 14 | Out-Null

Add-Box $s 556 164 340 92 $CARD $true | Out-Null
Add-Text $s "PNS  |  SAP Commerce" 572 176 308 18 10 $true $ACCENT 1 | Out-Null
Add-Text $s "/api/v2/pnshk/products/search" 572 200 308 18 10 $false $TEXT 1 | Out-Null
Add-Text $s "?query=&pageSize=100&fields=FULL" 572 220 308 18 10 $false $MUTED 1 | Out-Null

Add-Box $s 556 272 340 92 $CARD $true | Out-Null
Add-Text $s "Wellcome / Market Place  |  RTA" 572 284 308 18 10 $true $ACCENT 1 | Out-Null
Add-Text $s "POST /api/item/wareSearch" 572 308 308 18 10 $false $TEXT 1 | Out-Null
Add-Text $s "storeId 43 / 188   |   locale en_US" 572 328 308 18 10 $false $MUTED 1 | Out-Null

Add-Box $s 556 380 340 84 $CARD $true | Out-Null
Add-Text $s "Blocked, and left alone" 572 392 308 18 10 $true $AMBER 1 | Out-Null
Add-Text $s "ParknShop returned 403. U Select failed TLS. No bypass attempted." 572 414 308 40 10 $false $MUTED 1 | Out-Null
Add-Chrome $s 5 "Discovery"

# ---------------------------------------------------------------- slide 6
$s = New-Slide
Add-Title $s "Crawling at scale, politely" "DATA COLLECTION"

Add-Box $s 64 164 396 132 $CARD $true | Out-Null
Add-Text $s "PNS" 80 178 200 18 11 $true $ACCENT 1 | Out-Null
Add-Text $s "260 pages x 100" 80 202 360 26 20 $true $TEXT 1 | Out-Null
Add-Text $s "25,976 products  |  full catalogue" 80 236 360 18 10 $false $MUTED 1 | Out-Null

Add-Box $s 484 164 412 132 $CARD $true | Out-Null
Add-Text $s "Wellcome + Market Place" 500 178 380 18 11 $true $ACCENT 1 | Out-Null
Add-Text $s "21 categories each" 500 202 380 26 20 $true $TEXT 1 | Out-Null
Add-Text $s "11,682 + 10,404 products" 500 236 380 18 10 $false $MUTED 1 | Out-Null

Add-Box $s 64 316 832 132 $CARD $true | Out-Null
Add-Text $s "Why a browser, not a plain HTTP client" 80 332 500 22 13 $true $TEXT 1 | Out-Null
Add-Text $s "Bot protection, cookies and locale all matter. Running the fetch inside the real storefront returned English names, correct currency and live stock. Batches were posted to a local ingest endpoint and merged into JSON." 80 362 800 70 12 $false $MUTED 1 | Out-Null
Add-Chrome $s 6 "Crawling"

# ---------------------------------------------------------------- slide 7
$s = New-Slide
Add-Title $s "Turning messy catalogues into matches" "DATA ENGINEERING"

$signals = @(
  @{ x = 64;  y = 168; t = "Barcode";  s = "PNS EAN, exact" },
  @{ x = 278; y = 168; t = "Brand";    s = "3,132-name dictionary" },
  @{ x = 492; y = 168; t = "Pack size";s = "extracted + normalised" },
  @{ x = 706; y = 168; t = "Category"; s = "path" }
)
foreach ($g in $signals) {
  Add-Box $s $g.x $g.y 190 78 $CARD $true | Out-Null
  Add-Text $s $g.t $($g.x + 14) $($g.y + 12) 162 20 11 $true $ACCENT 1 | Out-Null
  Add-Text $s $g.s $($g.x + 14) $($g.y + 36) 162 28 9 $false $MUTED 1 | Out-Null
}
$signals2 = @(
  @{ x = 64;  t = "Name tokens"; s = "Jaccard, brand/size removed" },
  @{ x = 492; t = "Image hash";  s = "8x8 average hash, Hamming" }
)
for ($i = 0; $i -lt $signals2.Count; $i++) {
  $g = $signals2[$i]
  Add-Box $s $g.x 262 404 78 $CARD2 $true | Out-Null
  Add-Text $s $g.t $($g.x + 14) 274 376 20 11 $true $ACCENT 1 | Out-Null
  Add-Text $s $g.s $($g.x + 14) 298 376 28 9 $false $MUTED 1 | Out-Null
}

Add-Box $s 64 366 832 100 $CARD $true | Out-Null
Add-Text $s "->" 430 392 100 40 24 $true $ACCENT 2 | Out-Null
Add-Text $s "One matchGroup per product" 64 386 360 26 16 $true $TEXT 2 | Out-Null
Add-Text $s "5,915 groups  |  21,042 image hashes" 64 416 360 20 10 $false $MUTED 2 | Out-Null
Add-Text $s "Precision over recall: a shared brand and size is not enough. Fresh Milk, Skimmed Milk and Soy Milk must stay apart." 560 384 320 68 10 $false $MUTED 1 | Out-Null
Add-Chrome $s 7 "Matching"

# ---------------------------------------------------------------- slide 8
$s = New-Slide
Add-Title $s "The experience" "INTERFACE"

Add-Box $s 64 164 500 300 $CARD $true | Out-Null
Add-Text $s "Compare stores" 80 180 460 18 10 $true $ACCENT 1 | Out-Null
Add-Text $s "Kowloon Dairy Fresh Milk 946ML" 80 204 460 22 12 $true $TEXT 1 | Out-Null

$rows = @(
  @{ y = 240; store = "PNS";          price = "HK${HK}28.00"; note = "best price"; color = $ACCENT },
  @{ y = 282; store = "Market Place"; price = "HK${HK}32.00"; note = "+HK${HK}4.00";    color = $MUTED },
  @{ y = 324; store = "Wellcome";     price = "HK${HK}32.00"; note = "+HK${HK}4.00";    color = $MUTED }
)
foreach ($r in $rows) {
  Add-Box $s 80 $r.y 336 36 $CARD2 $true | Out-Null
  Add-Text $s $r.store 92 ($r.y + 8) 150 18 10 $true $TEXT 1 | Out-Null
  Add-Text $s $r.price 240 ($r.y + 7) 100 20 11 $true $(if ($r.note -eq "best price") { $ACCENT } else { $TEXT }) 1 | Out-Null
  Add-Text $s $r.note 344 ($r.y + 9) 70 16 8 $true $r.color 1 | Out-Null
}
Add-Text $s "Save HK${HK}4.00 vs the highest price" 80 380 460 20 11 $true $ACCENT 1 | Out-Null
Add-Text $s "Cheapest price is green, in a green row, with a Best badge." 80 408 460 30 10 $false $MUTED 1 | Out-Null

Add-Bullets $s @(
  "Search across 48k products instantly",
  "Today's price drops, sorted by discount",
  "Price alerts stored in the browser",
  "Light and dark themes, mobile layout",
  "Live on GitHub Pages"
) 600 176 296 280 13 | Out-Null
Add-Chrome $s 8 "Interface"

# ---------------------------------------------------------------- slide 9
$s = New-Slide
Add-Title $s "Results" "OUTCOME"

$big = @(
  @{ x = 64;  n = "8,685"; l = "cross-store comparisons" },
  @{ x = 356; n = "5,915"; l = "matched product groups" },
  @{ x = 648; n = "20 min"; l = "full refresh" }
)
foreach ($b in $big) {
  Add-Box $s $b.x 164 248 112 $CARD $true | Out-Null
  Add-Text $s $b.n $($b.x + 16) 182 216 44 26 $true $ACCENT 1 | Out-Null
  Add-Text $s $b.l $($b.x + 16) 228 216 20 10 $false $MUTED 1 | Out-Null
}

Add-Box $s 64 300 832 150 $CARD2 $true | Out-Null
Add-Text $s "What the user gets" 80 314 500 20 11 $true $ACCENT 1 | Out-Null
Add-Bullets $s @(
  "Every price on one screen, with the cheapest highlighted",
  "An exact HK${HK} difference for every store",
  "A direct link to the product page on that store's own site",
  "A refreshed index, not a stale snapshot"
) 80 340 760 100 12 | Out-Null

Add-Text $s "The old way: five minutes and three tabs. Now: one search." 64 468 832 24 13 $true $TEXT 1 | Out-Null
Add-Chrome $s 9 "Results"

# ---------------------------------------------------------------- slide 10
$s = New-Slide
Add-Title $s "Why the AI approach worked" "TAKEAWAYS"

$lessons = @(
  @{ x = 64;  y = 168; n = "01"; h = "Tools over guessing"; b = "Every endpoint and price was checked against the live site. The browser was the source of truth." },
  @{ x = 484; y = 168; n = "02"; h = "Failures became fixes"; b = "403s, TLS errors and encoding bugs shaped the pipeline instead of stopping it." },
  @{ x = 64;  y = 306; n = "03"; h = "Precision beats volume"; b = "5,915 trustworthy matches are worth more than 20,000 false ones." },
  @{ x = 484; y = 306; n = "04"; h = "One loop, end to end"; b = "Research, code, crawl, match, UI and deploy all ran in a single agent session." }
)
foreach ($l in $lessons) {
  Add-Box $s $l.x $l.y 412 122 $CARD $true | Out-Null
  Add-Text $s $l.n $($l.x + 16) ($l.y + 14) 40 18 10 $true $ACCENT 1 | Out-Null
  Add-Text $s $l.h $($l.x + 16) ($l.y + 36) 380 22 13 $true $TEXT 1 | Out-Null
  Add-Text $s $l.b $($l.x + 16) ($l.y + 62) 380 50 10 $false $MUTED 1 | Out-Null
}

Add-Text $s "Next: a 6-hour scheduled refresh, more stores, and fuzzy matching for the remaining gaps." 64 446 832 24 11 $false $MUTED 1 | Out-Null
Add-Text $s "catarungpt.github.io/quickcompare-hk" 64 474 500 22 11 $true $ACCENT 1 | Out-Null
Add-Chrome $s 10 "Takeaways"

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
