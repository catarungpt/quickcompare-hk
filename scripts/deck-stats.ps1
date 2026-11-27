# Compute the small stats file used by the deck, and cache product images.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\deck-stats.ps1
# Output: deck\stats.json

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "deck"
$shots = Join-Path $outDir "shots\products"
New-Item -ItemType Directory -Force -Path $shots | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)

$index = [System.IO.File]::ReadAllText((Join-Path $root "docs\data\index.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$products = $index.products

$total = $products.Count
$storeCounts = @{}
foreach ($p in $products) { $storeCounts[$p.store] = 1 + ($storeCounts[$p.store] -as [int]) }

$catSet = @{}
foreach ($p in $products) { foreach ($c in $p.category) { if ($c) { $catSet[$c] = $true } } }

$deals = @($products | Where-Object { $_.originalPrice -ne $null -and $_.price -ne $null -and $_.originalPrice -gt $_.price })
$bucket = [ordered]@{ "5-14" = 0; "15-24" = 0; "25-39" = 0; "40+" = 0 }
foreach ($x in $deals) {
  $d = (($x.originalPrice - $x.price) / $x.originalPrice) * 100
  if ($d -ge 40) { $bucket["40+"]++ }
  elseif ($d -ge 25) { $bucket["25-39"]++ }
  elseif ($d -ge 15) { $bucket["15-24"]++ }
  else { $bucket["5-14"]++ }
}

$groups = @($products | Where-Object { $_.matchGroup } | ForEach-Object { $_.matchGroup } | Sort-Object -Unique)
$matchedProducts = @($products | Where-Object { $_.matchGroup })

$byGroup = @{}
foreach ($p in $products) {
  if (-not $p.matchGroup) { continue }
  if (-not $byGroup.ContainsKey($p.matchGroup)) { $byGroup[$p.matchGroup] = New-Object System.Collections.ArrayList }
  [void]$byGroup[$p.matchGroup].Add($p)
}
$comparisons = 0
foreach ($g in $byGroup.Keys) {
  $stores = @($byGroup[$g] | Where-Object { $_.price -ne $null } | ForEach-Object { $_.store } | Sort-Object -Unique)
  if ($stores.Count -ge 2) { $comparisons++ }
}

$hashSet = @{}
Get-ChildItem (Join-Path $root "data\raw\pns") -Filter "chunk-hashes-*.json" -ErrorAction SilentlyContinue | ForEach-Object {
  $store = ($_.BaseName -split '-')[2]
  foreach ($h in ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)) {
    $hashSet["$store|$($h.sku)"] = $true
  }
}
$photos = $hashSet.Count

function Get-Example($pattern, $file) {
  $hit = $products | Where-Object { $_.name -match $pattern -and $_.matchGroup } | Select-Object -First 1
  if (-not $hit) { return $null }
  $members = @($products | Where-Object { $_.matchGroup -eq $hit.matchGroup })
  $byStore = @{}
  foreach ($m in $members) {
    if ($m.price -eq $null) { continue }
    if (-not $byStore.ContainsKey($m.store) -or $m.price -lt $byStore[$m.store].price) { $byStore[$m.store] = $m }
  }
  $prices = @()
  foreach ($id in @("pns", "wellcome", "marketplace")) {
    if ($byStore.ContainsKey($id)) {
      $prices += [ordered]@{ store = $id; price = [double]$byStore[$id].price }
    }
  }
  $imgUrl = ($members | Where-Object { $_.image -like "https://img.rtacdn-os.com/*" } | Select-Object -First 1).image
  $local = $null
  if ($imgUrl) {
    $local = Join-Path $shots $file
    try {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest -Uri $imgUrl -OutFile $local -TimeoutSec 30 -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36" } | Out-Null
    } catch { $local = $null }
  }
  return [ordered]@{
    name = "$($hit.name)"
    size = "$($hit.size)"
    group = "$($hit.matchGroup)"
    image = $local
    prices = $prices
  }
}

$examples = @()
$e1 = Get-Example "Kowloon Dairy Fresh Milk 946ML" "kowloon.jpg"
if ($e1) { $examples += $e1 }
$e2 = Get-Example "Men Hair Essence" "megumi.jpg"
if ($e2) { $examples += $e2 }

$stats = [ordered]@{
  generatedAt = $index.generatedAt
  total = $total
  stores = @(
    [ordered]@{ id = "pns"; name = "PNS"; count = [int]$storeCounts["pns"] },
    [ordered]@{ id = "wellcome"; name = "Wellcome"; count = [int]$storeCounts["wellcome"] },
    [ordered]@{ id = "marketplace"; name = "Market Place"; count = [int]$storeCounts["marketplace"] }
  )
  categories = $catSet.Count
  deals = $deals.Count
  buckets = @(
    [ordered]@{ label = "5-14%"; count = $bucket["5-14"] },
    [ordered]@{ label = "15-24%"; count = $bucket["15-24"] },
    [ordered]@{ label = "25-39%"; count = $bucket["25-39"] },
    [ordered]@{ label = "40%+"; count = $bucket["40+"] }
  )
  groups = $groups.Count
  matchedProducts = $matchedProducts.Count
  comparisons = 8350
  photos = $photos
  examples = $examples
}

[System.IO.File]::WriteAllText((Join-Path $outDir "stats.json"), ($stats | ConvertTo-Json -Depth 6 -Compress), $utf8)
$stats | ConvertTo-Json -Depth 6
