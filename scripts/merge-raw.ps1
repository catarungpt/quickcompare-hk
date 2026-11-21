# Convert raw crawl chunks (data/raw/pns/*.json) into data/products/<store>.json.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\merge-raw.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$rawDir = Join-Path $root "data\raw\pns"
$outDir = Join-Path $root "data\products"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)
$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

function Read-Chunk($path) {
  $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  if (-not $text.Trim()) { return @() }
  return @($text | ConvertFrom-Json)
}

# ---------- PNS ----------
$pns = [ordered]@{}
Get-ChildItem $rawDir -Filter "chunk-pns2-*.json" | ForEach-Object {
  foreach ($p in (Read-Chunk $_.FullName)) {
    if (-not $p.code) { continue }
    if ($pns.Contains($p.code)) { continue }
    $pns[$p.code] = [ordered]@{
      store         = "pns"
      storeName     = "PNS"
      sku           = "$($p.code)"
      name          = "$($p.name)"
      brand         = if ($p.brand) { "$($p.brand)" } else { $null }
      barcode       = if ($p.ean) { "$($p.ean)" } else { $null }
      category      = @($p.cat)
      size          = if ($p.size) { "$($p.size)" } else { $null }
      price         = if ($null -ne $p.price) { [math]::Round([double]$p.price, 2) } else { $null }
      originalPrice = if ($null -ne $p.was) { [math]::Round([double]$p.was, 2) } else { $null }
      currency      = "HKD"
      unitPrice     = $null
      unit          = $null
      inStock       = ("$($p.stock)" -eq "inStock")
      promotion     = $null
      image         = if ($p.image) { "$($p.image)" } else { $null }
      url           = "https://www.pns.hk/en/p/$($p.code)"
      linkType      = "product"
      lastSeen      = $now
      lastChecked   = $now
    }
  }
}

# ---------- Wellcome ----------
$wc = [ordered]@{}
Get-ChildItem $rawDir -Filter "chunk-wellcome2-*.json" | ForEach-Object {
  foreach ($p in (Read-Chunk $_.FullName)) {
    if (-not $p.sku) { continue }
    if ($wc.Contains($p.sku)) { continue }
    $slug = [uri]::EscapeDataString("$($p.name)")
    $wc[$p.sku] = [ordered]@{
      store         = "wellcome"
      storeName     = "Wellcome"
      sku           = "$($p.sku)"
      name          = "$($p.name)"
      brand         = $null
      barcode       = $null
      category      = @($p.cat)
      size          = $null
      price         = if ($null -ne $p.price) { [math]::Round([double]$p.price, 2) } else { $null }
      originalPrice = if ($null -ne $p.was) { [math]::Round([double]$p.was, 2) } else { $null }
      currency      = "HKD"
      unitPrice     = $null
      unit          = $null
      inStock       = ([int]$p.stock -gt 0)
      promotion     = $null
      image         = if ($p.image) { "$($p.image)" } else { $null }
      url           = "https://www.wellcome.com.hk/en/p/$slug/i/$($p.sku).html"
      linkType      = "product"
      lastSeen      = $now
      lastChecked   = $now
    }
  }
}

# ---------- Market Place ----------
$mp = [ordered]@{}
Get-ChildItem $rawDir -Filter "chunk-marketplace2-*.json" | ForEach-Object {
  foreach ($p in (Read-Chunk $_.FullName)) {
    if (-not $p.sku) { continue }
    if ($mp.Contains($p.sku)) { continue }
    $slug = [uri]::EscapeDataString("$($p.name)")
    $mp[$p.sku] = [ordered]@{
      store         = "marketplace"
      storeName     = "Market Place"
      sku           = "$($p.sku)"
      name          = "$($p.name)"
      brand         = $null
      barcode       = $null
      category      = @($p.cat)
      size          = $null
      price         = if ($null -ne $p.price) { [math]::Round([double]$p.price, 2) } else { $null }
      originalPrice = if ($null -ne $p.was) { [math]::Round([double]$p.was, 2) } else { $null }
      currency      = "HKD"
      unitPrice     = $null
      unit          = $null
      inStock       = ([int]$p.stock -gt 0)
      promotion     = $null
      image         = if ($p.image) { "$($p.image)" } else { $null }
      url           = "https://www.marketplacehk.com/en/p/$slug/i/$($p.sku).html"
      linkType      = "product"
      lastSeen      = $now
      lastChecked   = $now
    }
  }
}

function Write-Store($id, $name, $map) {
  $doc = [ordered]@{
    store     = $id
    storeName = $name
    updatedAt = $now
    products  = @($map.Values)
  }
  $json = $doc | ConvertTo-Json -Depth 8 -Compress
  [System.IO.File]::WriteAllText((Join-Path $outDir "$id.json"), $json, $utf8)
  Write-Host ("{0,-12} {1,6} products" -f $name, $map.Count)
}

Write-Store "pns" "PNS" $pns
Write-Store "wellcome" "Wellcome" $wc
Write-Store "marketplace" "Market Place" $mp
