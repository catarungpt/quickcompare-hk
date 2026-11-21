# QuickCompare HK

Compare supermarket prices across Hong Kong in one search.

**Live site:** https://catarungpt.github.io/quickcompare-hk/

48,000+ products from three stores, refreshed from each store's own public
catalogue. Every result links straight to the product page on the store's
website — no middleman, no markup.

## What it does

- Search by product name, brand, barcode, pack size or category.
- See the current price, original price, stock status and promotion.
- Compare the same product across stores, cheapest first, with the difference
  shown for every store.
- Browse today's price drops and the biggest savings.
- Save local price alerts (stored in your browser, no account).

## Stores

| Store | Site | Catalogue API |
| --- | --- | --- |
| Wellcome | https://www.wellcome.com.hk/en/ | `POST /api/item/wareSearch` |
| PNS (ParknShop) | https://www.pns.hk/en/ | `GET https://api.pns.hk/api/v2/pnshk/products/search` |
| Market Place | https://www.marketplacehk.com/ | `POST /api/item/wareSearch` |

## How matching works

A product is linked across stores using six signals:

1. **Barcode** (exact) — PNS publishes EANs.
2. **Brand** — published by PNS, inferred from the product name for the other
   two stores against a 3,000+ brand dictionary.
3. **Pack size** — extracted from names and unit-normalised.
4. **Category** — category path.
5. **Name similarity** — token Jaccard after removing brand, size, brackets and
   parentheticals.
6. **Image similarity** — an 8×8 average hash of each product image, compared by
   Hamming distance.

Matching runs offline in `scripts/match.ps1` and stores a `matchGroup` on every
product. The page only groups by that id, so the browser stays fast.

## Layout

```
docs/                 static site (no build step, no dependencies)
  index.html
  app.js
  styles.css
  fonts/
  data/index.json     generated price index (~28 MB, 3.5 MB gzipped)
scripts/
  merge-raw.ps1       raw crawl chunks -> data/products/<store>.json
  enrich.ps1          brand + pack size inference, match key
  make-hash-candidates.ps1
  match.ps1           cross-store matching -> matchGroup
  build-index.ps1     merge stores -> docs/data/index.json
  serve-site.ps1      local static server with gzip
  ingest-server.ps1   browser crawlers post batches here
  refresh-wellcome.ps1
reports/              latest refresh report and run log
.opencode/agents/     the agent definition that runs the refresh
```

## Run locally

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\serve-site.ps1
# open http://127.0.0.1:8765/
```

Use `127.0.0.1`, not `localhost`, if your machine routes loopback oddly.

## Refresh the data

```powershell
# 1. crawl (browser-based; see reports/latest.md for the current procedure)
# 2. merge and rebuild
powershell -File scripts\merge-raw.ps1
powershell -File scripts\enrich.ps1
powershell -File scripts\make-hash-candidates.ps1
powershell -File scripts\match.ps1
powershell -File scripts\build-index.ps1
```

## Disclaimer

QuickCompare HK is an independent price-comparison project. It is not
affiliated with Wellcome, PNS, Market Place or their parent companies. Prices
are collected from public store catalogues and change often — always confirm on
the store's page before buying. Product names and images belong to their
respective owners.

## License

Code in this repository is provided as-is for personal, non-commercial use.
