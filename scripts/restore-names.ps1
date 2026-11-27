# The DFI storefront API now returns Chinese product names even when the locale
# is set to English. Reuse the English names captured on the previous crawl for
# the same SKU, and rebuild the product URLs to match.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\restore-names.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root "data\products"
$utf8 = New-Object System.Text.UTF8Encoding($false)

$index = [System.IO.File]::ReadAllText((Join-Path $root "docs\data\index.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$names = @{ wellcome = @{}; marketplace = @{} }
foreach ($p in $index.products) {
  if (-not $names.ContainsKey($p.store)) { continue }
  if ($p.name -match '[\u4e00-\u9fff]') { continue }
  $names[$p.store]["$($p.sku)"] = "$($p.name)"
}
Write-Host "English names available: wellcome=$($names['wellcome'].Count) marketplace=$($names['marketplace'].Count)"

$bases = @{
  wellcome = "https://www.wellcome.com.hk/en/p/"
  marketplace = "https://www.marketplacehk.com/en/p/"
}

foreach ($store in @("wellcome", "marketplace")) {
  $path = Join-Path $dir "$store.json"
  $doc = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
  $replaced = 0
  foreach ($p in $doc.products) {
    if ($p.name -notmatch '[\u4e00-\u9fff]') { continue }
    $english = $names[$store]["$($p.sku)"]
    if (-not $english) { continue }
    $p.name = $english
    $slug = [uri]::EscapeDataString($english)
    $p.url = "$($bases[$store])$slug/i/$($p.sku).html"
    $replaced++
  }
  $doc.updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
  [System.IO.File]::WriteAllText($path, ($doc | ConvertTo-Json -Depth 8 -Compress), $utf8)
  $left = @($doc.products | Where-Object { $_.name -match '[\u4e00-\u9fff]' }).Count
  Write-Host ("{0,-12} replaced {1,5}  still Chinese {2,5}" -f $store, $replaced, $left)
}