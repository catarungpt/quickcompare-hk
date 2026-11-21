# Price refresh — 2026-11-21 15:35 (HKT)

## Summary

| Store | Products | Change vs 07 Nov |
| --- | ---: | --- |
| PNS | 25,976 | ~same |
| Wellcome | 11,682 | -223 |
| Market Place | 10,404 | -223 |
| **Total** | **48,062** | -447 |

Every price, stock flag and promotion is from today's crawl. The previous index
was 14 days old.

## Pipeline

1. Crawled PNS (260 pages), Wellcome (21 categories) and Market Place (21
   categories) through the browser, posting each batch to the local ingest
   endpoint.
2. Merged raw chunks into `data/products/<store>.json`.
3. Re-inferred brand and pack size; 3,734 match keys span two or more stores.
4. Image hashes: 21,042 (only 2,190 new images needed hashing; the rest were
   reused from the previous run).
5. Combined matching: 64,630 candidate pairs, 11,336 accepted, **5,915
   cross-store groups**.
6. Rebuilt `data/index.json` and `site/data/index.json` (28 MB, 3.5 MB gzipped).

## Spot check

*Kowloon Dairy Fresh Milk 946ML* still compares correctly:

| Store | Price | Difference |
| --- | ---: | ---: |
| PNS | HK$28.00 | best price |
| Market Place | HK$32.00 | +HK$4.00 |
| Wellcome | HK$32.00 | +HK$4.00 |

## Notes

- `scripts/make-hash-candidates.ps1` now reuses existing image hashes and only
  sends new products to the browser hasher.
- Hash chunks written by a re-run must use unique tags, otherwise identical
  range names overwrite earlier chunks. Fixed by tagging batches (`r2a`, `w1`,
  `m1`, …).
