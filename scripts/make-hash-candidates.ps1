# Build per-store image-hash candidate lists: products whose match key appears
# in two or more stores. Only these need an image hash for cross-store matching.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\make-hash-candidates.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root "data\products"
$outDir = Join-Path $root "data\raw\pns"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)

$docs = @{}
foreach ($id in @("pns", "wellcome", "marketplace")) {
  $docs[$id] = ([System.IO.File]::ReadAllText((Join-Path $dir "$id.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json).products
}

$keyStores = @{}
foreach ($id in $docs.Keys) {
  foreach ($p in $docs[$id]) {
    if (-not $p.matchKey) { continue }
    if (-not $keyStores.ContainsKey($p.matchKey)) { $keyStores[$p.matchKey] = @{} }
    $keyStores[$p.matchKey][$id] = $true
  }
}
$multi = @{}
foreach ($k in $keyStores.Keys) {
  if ($keyStores[$k].Count -ge 2) { $multi[$k] = $true }
}
Write-Host "Multi-store match keys: $($multi.Count)"

# Reuse hashes from previous runs so only new products need to be hashed.
$haveHash = @{}
Get-ChildItem $outDir -Filter "chunk-hashes-*.json" | ForEach-Object {
  $store = ($_.BaseName -split '-')[2]
  foreach ($h in ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)) {
    $haveHash["$store|$($h.sku)"] = $true
  }
}
Write-Host "Existing hashes: $($haveHash.Count)"

foreach ($id in $docs.Keys) {
  $list = @()
  $skipped = 0
  foreach ($p in $docs[$id]) {
    if (-not $p.image) { continue }
    if (-not $p.matchKey -or -not $multi.ContainsKey($p.matchKey)) { continue }
    if ($haveHash.ContainsKey("$id|$($p.sku)")) { $skipped++; continue }
    $list += [ordered]@{ sku = "$($p.sku)"; image = "$($p.image)" }
  }
  $json = $list | ConvertTo-Json -Depth 4 -Compress
  [System.IO.File]::WriteAllText((Join-Path $outDir "candidates-$id.json"), $json, $utf8)
  Write-Host ("{0,-12} {1,6} to hash  {2,6} already hashed" -f $id, $list.Count, $skipped)
}
