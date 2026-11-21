# Refresh the Wellcome (HK) product catalogue.
#
# Uses the public storefront search API that www.wellcome.com.hk itself calls.
# Polite: one request at a time, short delay, honest User-Agent.
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\refresh-wellcome.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$ua = "HKPriceWatch/1.0 (+local price comparison; contact: local user)"
$api = "https://www.wellcome.com.hk/api/item/wareSearch"
$site = "https://www.wellcome.com.hk"

# Top-level categories exposed by the storefront navigation.
$categories = @(
  @{ id = 105591; name = "Case Deal" },
  @{ id = 100011; name = "Fruits & Vegetables" },
  @{ id = 100015; name = "Meat & Seafood" },
  @{ id = 100020; name = "Rice, Oil & Noodles" },
  @{ id = 100007; name = "Dairy, Chilled & Eggs" },
  @{ id = 100003; name = "Breakfast & Bakery" },
  @{ id = 100010; name = "Frozen Food" },
  @{ id = 100022; name = "Snacks & Confectionery" },
  @{ id = 100001; name = "Beer, Wines & Spirits" },
  @{ id = 100002; name = "Beverages" },
  @{ id = 100004; name = "Canned, Preserved & Soup" },
  @{ id = 100005; name = "Condiment & Sauce" },
  @{ id = 100013; name = "Household Supplies" },
  @{ id = 100014; name = "Kitchen & Dining" },
  @{ id = 100000; name = "Beauty & Personal Care" },
  @{ id = 100016; name = "Mother & Baby" },
  @{ id = 100012; name = "Health Care" },
  @{ id = 100017; name = "Outdoor & Sundries" },
  @{ id = 189651; name = "Cat" },
  @{ id = 189941; name = "Dog" },
  @{ id = 161256; name = "Fitness & Wellness" }
)

# Pages per category (20 products per page). Raise for a deeper crawl.
$maxPages = 10

$comm = @{
  dmTenantId = 15; venderId = 5; businessCode = 1; origin = 26
  "superweb-locale" = "en_US"; storeId = 43; pickUpStoreId = ""; shipmentType = 1
}

$products = @{}
$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
$failures = @()

foreach ($cat in $categories) {
  $page = 1
  $total = $null
  while ($page -le $maxPages) {
    $body = @{
      param = @{
        businessCode = 1; categoryType = 1; erpStoreId = 43; venderId = 5
        keyword = ""; pageNum = "$page"; pageSize = "20"; categoryId = $cat.id
        filterProperties = @(); sortKey = 0; sortRule = 0
      }
      comm = $comm
    } | ConvertTo-Json -Depth 10

    try {
      # Invoke-RestMethod mis-decodes this API's UTF-8 body on Windows PowerShell 5.1,
      # so read the raw bytes and decode them explicitly.
      $resp = Invoke-WebRequest -Uri $api -Method Post -ContentType "application/json" `
        -Body $body -Headers @{ "User-Agent" = $ua; "Accept" = "application/json" } `
        -TimeoutSec 30 -UseBasicParsing
      $text = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
      $r = $text | ConvertFrom-Json
    } catch {
      $failures += "$($cat.name) page $page : $($_.Exception.Message)"
      break
    }

    if (-not $r.data -or -not $r.data.wareList) { break }
    if ($null -eq $total) { $total = [int]$r.data.pageInfo.total }
    if ($r.data.wareList.Count -eq 0) { break }

    foreach ($w in $r.data.wareList) {
      $sku = "$($w.sku)"
      if (-not $sku -or $products.ContainsKey($sku)) { continue }

      $online = [double]$w.onlinePrice / 100
      $promo = [double]$w.onlinePromotionPrice / 100
      $price = if ($promo -gt 0) { $promo } else { $online }
      $original = if ($promo -gt 0 -and $online -gt $promo) { $online } else { $null }
      $slug = [uri]::EscapeDataString("$($w.wareName)")

      $products[$sku] = [ordered]@{
        store         = "wellcome"
        storeName     = "Wellcome"
        sku           = $sku
        name          = "$($w.wareName)"
        brand         = $null
        barcode       = $null
        category      = @($cat.name)
        size          = $null
        price         = [math]::Round($price, 2)
        originalPrice = if ($null -ne $original) { [math]::Round($original, 2) } else { $null }
        currency      = "HKD"
        unitPrice     = $null
        unit          = $null
        inStock       = ([int]$w.stock -gt 0)
        promotion     = $null
        image         = "$($w.wareImg)"
        url           = "$site/en/p/$slug/i/$sku.html"
        linkType      = "product"
        lastSeen      = $now
        lastChecked   = $now
      }
    }

    if ($total -and ($page * 20) -ge $total) { break }
    $page++
    Start-Sleep -Milliseconds 250
  }
  Write-Host ("{0,-28} {1,5} products" -f $cat.name, $products.Count)
}

$out = [ordered]@{
  store     = "wellcome"
  storeName = "Wellcome"
  updatedAt = $now
  products  = @($products.Values)
}

$dir = Join-Path $root "data\products"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$json = $out | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText((Join-Path $dir "wellcome.json"), $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Wellcome: $($products.Count) products written."
if ($failures.Count) {
  Write-Host "Failures:"
  $failures | ForEach-Object { Write-Host "  $_" }
}
