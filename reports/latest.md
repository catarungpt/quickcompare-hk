# Price refresh — 2026-11-27 22:42 (HKT)

## Summary

| Store | Products | vs 21 Nov |
| --- | ---: | --- |
| PNS | 26,000 | +24 |
| Wellcome | 11,538 | -144 |
| Market Place | 10,163 | -241 |
| **Total** | **47,701** | -361 |

- Cross-store match groups: **5,472**
- Products listed by 2+ stores: **13,618**
- Price comparisons shown: **8,350**
- Image hashes: **21,317** (275 new this run)
- Products on offer: **11,128**

## Pipeline

1. Crawled PNS (260 pages), Wellcome (21 categories) and Market Place
   (21 categories) through the browser.
2. Merged, enriched brand and pack size, hashed only the new images, matched,
   rebuilt the index.
3. Rebuilt the deck and its screenshots from the new index.

## Issue found: the DFI API dropped English names

Both Wellcome (`/api/item/wareSearch`) and Market Place now return Chinese
product names even with `superweb-locale: en_US`. On 21 Nov the same requests
returned English.

Fix: `scripts/restore-names.ps1` reuses the English names captured on the
previous crawl for the same SKU and rebuilds the product URLs.

- Wellcome: 10,825 names restored, 519 still Chinese (mostly new SKUs)
- Market Place: 9,613 were already English, 550 remain Chinese

## Known limitation

The ~1,000 products that remain Chinese cannot match English-named products by
name. They still match by brand and pack size where the brand is present in the
name (many DFI names start with an English brand).

## Next steps

- Ask DFI whether the English catalogue is still available under another locale.
- Extend `restore-names.ps1` to translate new Chinese names, not just reuse old
  ones.