# Merge every data/products/<store>.json into data/index.json and docs/data/index.json.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-index.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$productsDir = Join-Path $root "data\products"
$storesFile = Join-Path $root "data\stores.json"

$stores = ([System.IO.File]::ReadAllText($storesFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).stores
$storeMeta = @{}
foreach ($s in $stores) { $storeMeta[$s.id] = $s }

$all = New-Object System.Collections.Generic.List[object]
$counts = [ordered]@{}
$updated = $null

# The UI only needs these fields. Dropping matchKey and imageHash keeps the
# index small; they are used at build time only.
$keep = @(
  "store", "storeName", "sku", "name", "brand", "barcode", "category", "size",
  "price", "originalPrice", "currency", "unitPrice", "unit", "inStock",
  "promotion", "image", "url", "linkType", "lastSeen", "lastChecked", "matchGroup"
)

Get-ChildItem $productsDir -Filter *.json | Where-Object { $_.Name -notlike "*.prev.json" } | ForEach-Object {
  $doc = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
  $id = $doc.store
  $items = @($doc.products)
  $counts[$id] = $items.Count
  if ($doc.updatedAt) { $updated = $doc.updatedAt }
  foreach ($p in $items) {
    $slim = [ordered]@{}
    foreach ($field in $keep) {
      $slim[$field] = $p.$field
    }
    $all.Add([pscustomobject]$slim)
  }
}

$index = [ordered]@{
  generatedAt = if ($updated) { $updated } else { (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz") }
  currency    = "HKD"
  sample      = $false
  stores      = @($stores | ForEach-Object { [ordered]@{ id = $_.id; name = $_.name; url = $_.url } })
  products    = $all
}

$json = $index | ConvertTo-Json -Depth 8 -Compress
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $root "data\index.json"), $json, $utf8)

$siteData = Join-Path $root "docs\data"
New-Item -ItemType Directory -Force -Path $siteData | Out-Null
[System.IO.File]::WriteAllText((Join-Path $siteData "index.json"), $json, $utf8)

Write-Host "Index built: $($all.Count) products"
foreach ($k in $counts.Keys) {
  $name = if ($storeMeta[$k]) { $storeMeta[$k].name } else { $k }
  Write-Host ("  {0,-16} {1,6}" -f $name, $counts[$k])
}
