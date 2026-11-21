# Cross-store product matching.
#
# Combines four signals:
#   1. barcode (exact)
#   2. match key  = normalised brand + pack size
#   3. name similarity (token Jaccard, brand/size/parentheticals removed)
#   4. image similarity (8x8 average hash, Hamming distance)
#
# Writes `imageHash` and `matchGroup` back into data/products/*.json.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\match.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root "data\products"
$rawDir = Join-Path $root "data\raw\pns"
$utf8 = New-Object System.Text.UTF8Encoding($false)

$stop = @{
  "the"=1; "and"=1; "with"=1; "for"=1; "of"=1; "x"=1; "pack"=1; "new"=1; "old"=1;
  "random"=1; "packaging"=1; "chilled"=1; "hong"=1; "kong"=1; "consume"=1;
  "within"=1; "days"=1; "best"=1; "quality"=1; "ea"=1; "pc"=1; "pcs"=1;
  "ml"=1; "l"=1; "g"=1; "kg"=1; "lt"=1; "gm"=1; "each"=1; "unit"=1; "set"=1;
  "box"=1; "pk"=1; "bx"=1; "st"=1; "rl"=1; "flavour"=1; "flavor"=1
}

function Clean-Name($name) {
  if (-not $name) { return "" }
  $s = $name.ToLower()
  $s = $s -replace '\[[^\]]*\]', ' '
  $s = $s -replace '\([^\)]*\)', ' '
  $s = $s -replace '[^a-z0-9]+', ' '
  return $s.Trim()
}

function Get-Tokens($name, $brand, $size) {
  $s = Clean-Name $name
  $tokens = @($s -split ' ' | Where-Object { $_ -and -not $stop.ContainsKey($_) -and $_ -notmatch '^\d+(\.\d+)?$' })
  if ($brand) {
    $bt = @((Clean-Name $brand) -split ' ' | Where-Object { $_ })
    $tokens = @($tokens | Where-Object { $bt -notcontains $_ })
  }
  if ($size) {
    $st = @((Clean-Name $size) -split ' ' | Where-Object { $_ })
    $tokens = @($tokens | Where-Object { $st -notcontains $_ })
  }
  return @($tokens | Sort-Object -Unique)
}

function Jaccard($a, $b) {
  if ($a.Count -eq 0 -or $b.Count -eq 0) { return 0.0 }
  $setB = @{}
  foreach ($t in $b) { $setB[$t] = $true }
  $inter = 0
  foreach ($t in $a) { if ($setB.ContainsKey($t)) { $inter++ } }
  $union = $a.Count + $b.Count - $inter
  if ($union -eq 0) { return 0.0 }
  return [double]$inter / $union
}

function Hamming($h1, $h2) {
  if (-not $h1 -or -not $h2) { return 64 }
  try {
    $a = [Convert]::ToUInt64($h1, 16)
    $b = [Convert]::ToUInt64($h2, 16)
    $x = $a -bxor $b
    $count = 0
    while ($x -ne 0) { $count += ($x -band 1); $x = $x -shr 1 }
    return $count
  } catch { return 64 }
}

# ---------- load ----------
$docs = @{}
foreach ($id in @("pns", "wellcome", "marketplace")) {
  $docs[$id] = ([System.IO.File]::ReadAllText((Join-Path $dir "$id.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json).products
}

# ---------- image hashes ----------
$hashes = @{}
Get-ChildItem $rawDir -Filter "chunk-hashes-*.json" | ForEach-Object {
  $store = ($_.BaseName -split '-')[2]
  foreach ($h in ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)) {
    $hashes["$store|$($h.sku)"] = $h.hash
  }
}
Write-Host "Image hashes loaded: $($hashes.Count)"

# ---------- index products ----------
$items = New-Object System.Collections.ArrayList
$tokens = @{}
$byKey = @{}
$byBarcode = @{}

foreach ($id in $docs.Keys) {
  foreach ($p in $docs[$id]) {
    $key = "$id|$($p.sku)"
    $h = $hashes[$key]
    $p | Add-Member -NotePropertyName imageHash -NotePropertyValue $h -Force
    $p | Add-Member -NotePropertyName matchGroup -NotePropertyValue $null -Force
    $tokens[$key] = Get-Tokens $p.name $p.brand $p.size
    [void]$items.Add([pscustomobject]@{ key = $key; store = $id; p = $p })

    if ($p.barcode) {
      $bk = "b|$($p.barcode)"
      if (-not $byBarcode.ContainsKey($bk)) { $byBarcode[$bk] = New-Object System.Collections.ArrayList }
      [void]$byBarcode[$bk].Add($key)
    }
    if ($p.matchKey) {
      $mk = "m|$($p.matchKey)"
      if (-not $byKey.ContainsKey($mk)) { $byKey[$mk] = New-Object System.Collections.ArrayList }
      [void]$byKey[$mk].Add($key)
    }
  }
}
Write-Host "Products indexed: $($items.Count)"

$byId = @{}
foreach ($it in $items) { $byId[$it.key] = $it }

# ---------- union-find ----------
$parent = @{}
foreach ($it in $items) { $parent[$it.key] = $it.key }
function Find($x) {
  $r = $x
  while ($parent[$r] -ne $r) { $r = $parent[$r] }
  while ($parent[$x] -ne $r) { $n = $parent[$x]; $parent[$x] = $r; $x = $n }
  return $r
}
function Union($a, $b) {
  $ra = Find $a; $rb = Find $b
  if ($ra -ne $rb) { $parent[$ra] = $rb }
}

# ---------- score pairs inside each block ----------
$pairs = 0
$accepted = 0
$blocks = @{}
foreach ($k in $byBarcode.Keys) { $blocks[$k] = $byBarcode[$k] }
foreach ($k in $byKey.Keys) { $blocks[$k] = $byKey[$k] }

foreach ($k in $blocks.Keys) {
  $keys = $blocks[$k]
  if ($keys.Count -lt 2) { continue }
  for ($i = 0; $i -lt $keys.Count; $i++) {
    $ka = $keys[$i]
    $ia = $byId[$ka]
    for ($j = $i + 1; $j -lt $keys.Count; $j++) {
      $kb = $keys[$j]
      $ib = $byId[$kb]
      if ($ia.store -eq $ib.store) { continue }
      $pairs++

      $nameSim = Jaccard $tokens[$ka] $tokens[$kb]
      $ham = Hamming $ia.p.imageHash $ib.p.imageHash
      $imgSim = 1.0 - ($ham / 64.0)
      $score = if ($ia.p.imageHash -and $ib.p.imageHash) { 0.7 * $nameSim + 0.3 * $imgSim } else { $nameSim }

      # Precision over recall: a shared brand and pack size is not enough on its
      # own (Fresh Milk / Skimmed Milk / Soy Milk all collide), so require a
      # strong name match and let the image only confirm it.
      if (($nameSim -ge 0.85) -or ($score -ge 0.68 -and $nameSim -ge 0.5)) {
        Union $ka $kb
        $accepted++
      }
    }
  }
}
Write-Host "Candidate pairs: $pairs  accepted: $accepted"

# ---------- assign group ids ----------
$groups = @{}
foreach ($it in $items) {
  $r = Find $it.key
  if (-not $groups.ContainsKey($r)) { $groups[$r] = New-Object System.Collections.ArrayList }
  [void]$groups[$r].Add($it)
}

$gid = 0
$multi = 0
foreach ($r in $groups.Keys) {
  $members = $groups[$r]
  $stores = @{}
  foreach ($m in $members) { $stores[$m.store] = $true }
  if ($stores.Count -lt 2) { continue }
  $multi++
  $gid++
  $id = "g$gid"
  foreach ($m in $members) { $m.p.matchGroup = $id }
}
Write-Host "Cross-store groups: $multi"

# ---------- write ----------
foreach ($id in $docs.Keys) {
  $doc = [ordered]@{
    store     = $id
    storeName = $docs[$id][0].storeName
    updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    products  = $docs[$id]
  }
  $json = $doc | ConvertTo-Json -Depth 8 -Compress
  [System.IO.File]::WriteAllText((Join-Path $dir "$id.json"), $json, $utf8)
  Write-Host ("{0,-12} {1,6} products" -f $id, $docs[$id].Count)
}
