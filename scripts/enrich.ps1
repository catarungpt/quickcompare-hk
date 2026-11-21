# Enrich product records with brand, pack size and a cross-store match key.
#
# PNS publishes brand and size directly. Wellcome and Market Place do not, so
# infer the brand from the product name using the PNS brand list, and extract
# the pack size with a regex.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\enrich.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root "data\products"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Norm-Text($s) {
  if (-not $s) { return "" }
  return (($s.ToLower() -replace '[^a-z0-9]+', ' ').Trim())
}

function Norm-Size($s) {
  if (-not $s) { return $null }
  $v = ($s.ToUpper() -replace '\s+', '')
  if ($v -match '^(EACH|PACK|UNIT|SET|BOX)$') { return $null }
  $v = $v -replace 'KGS$', 'KG'
  $v = $v -replace '(LTR|LT)$', 'L'
  $v = $v -replace '(GM|GR)$', 'G'
  $v = $v -replace 'PCS$', 'PC'
  if ($v -notmatch '^\d') { return $null }
  return $v
}

function Get-Size($name) {
  if (-not $name) { return $null }
  $u = $name.ToUpper()
  $m = [regex]::Match($u, '(\d+)\s*X\s*(\d+(?:\.\d+)?)\s*(ML|LTR|LT|L|KGS|KG|GM|GR|G)\b')
  if ($m.Success) { return Norm-Size "$($m.Groups[1].Value)X$($m.Groups[2].Value)$($m.Groups[3].Value)" }
  $ms = [regex]::Matches($u, '(\d+(?:\.\d+)?)\s*(ML|LTR|LT|L|KGS|KG|GM|GR|G|PCS|PC|EA|PK|BX|ST|RL)\b')
  if ($ms.Count -eq 0) { return $null }
  $m = $ms[$ms.Count - 1]
  return Norm-Size "$($m.Groups[1].Value)$($m.Groups[2].Value)"
}

# ---------- load ----------
$docs = @{}
foreach ($id in @("pns", "wellcome", "marketplace")) {
  $path = Join-Path $dir "$id.json"
  if (Test-Path $path) {
    $docs[$id] = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
  }
}

# ---------- brand dictionary from PNS ----------
$brandMap = @{}
foreach ($p in $docs["pns"].products) {
  if (-not $p.brand) { continue }
  $n = Norm-Text $p.brand
  if ($n -and -not $brandMap.ContainsKey($n)) { $brandMap[$n] = $p.brand }
}
Write-Host "Brand dictionary: $($brandMap.Count) entries"

function Get-Brand($name) {
  $n = Norm-Text $name
  if (-not $n) { return $null }
  $words = $n -split ' '
  $max = [Math]::Min(4, $words.Count)
  for ($i = $max; $i -ge 1; $i--) {
    $prefix = ($words[0..($i - 1)] -join ' ')
    if ($brandMap.ContainsKey($prefix)) { return $brandMap[$prefix] }
  }
  return $null
}

# ---------- enrich ----------
$stats = @{}
foreach ($id in $docs.Keys) {
  $inferredBrand = 0
  $inferredSize = 0
  foreach ($p in $docs[$id].products) {
    if (-not $p.brand) {
      $b = Get-Brand $p.name
      if ($b) { $p.brand = $b; $inferredBrand++ }
    }
    if (-not $p.size) {
      $s = Get-Size $p.name
      if ($s) { $p.size = $s; $inferredSize++ }
    }
    $nb = Norm-Text $p.brand
    $ns = Norm-Size $p.size
    $mk = if ($nb -and $ns) { "$nb|$ns" } else { $null }
    $p | Add-Member -NotePropertyName matchKey -NotePropertyValue $mk -Force
  }
  $stats[$id] = @{ brand = $inferredBrand; size = $inferredSize }
}

# ---------- write ----------
foreach ($id in $docs.Keys) {
  $json = $docs[$id] | ConvertTo-Json -Depth 8 -Compress
  [System.IO.File]::WriteAllText((Join-Path $dir "$id.json"), $json, $utf8)
  $s = $stats[$id]
  Write-Host ("{0,-12} brand inferred {1,6}  size inferred {2,6}" -f $id, $s.brand, $s.size)
}

# ---------- match-key coverage ----------
$byKey = @{}
foreach ($id in $docs.Keys) {
  foreach ($p in $docs[$id].products) {
    if (-not $p.matchKey) { continue }
    if (-not $byKey.ContainsKey($p.matchKey)) { $byKey[$p.matchKey] = @{} }
    $byKey[$p.matchKey][$id] = $true
  }
}
$multi = @($byKey.Keys | Where-Object { $byKey[$_].Count -ge 2 })
Write-Host "Match keys spanning 2+ stores: $($multi.Count)"
