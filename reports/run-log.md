# Run log

| Timestamp | Stores OK | Stores failed | Products | Notes |
| --- | --- | --- | --- | --- |
| 2026-11-07 16:02 HKT | 1 (Wellcome) | 14 | 3,533 | First real crawl. ParknShop 403, U Select TLS, others no public catalogue. |
| 2026-11-07 17:10 HKT | 2 (PNS, Wellcome) | 1 (Market Place) | 29,632 | Scope narrowed to 3 stores. PNS full catalogue 25,978; Wellcome 3,654 in English. Market Place unreachable (TCP 443). |
| 2026-11-07 16:38 HKT | 3 (PNS, Wellcome, Market Place) | 0 | 33,126 | Market Place crawled via marketplacehk.com (storeId 188). 3,494 products. 1,965 cross-store comparisons. |
| 2026-11-07 16:55 HKT | 3 | 0 | 48,509 | Fixed missing products: PNS re-crawled with fields=FULL to capture brand; Wellcome and Market Place crawled to the end of every category. |
| 2026-11-21 HKT | 3 | 0 | 48,509 | Added brand/size inference, image hashing (19,199) and combined matching. 5,597 cross-store groups, 950 with all three stores. |
| 2026-11-21 15:35 HKT | 3 | 0 | 48,062 | Full refresh. PNS 25,976, Wellcome 11,682, Market Place 10,404. 21,042 image hashes, 5,915 cross-store groups. |
| 2026-11-27 22:42 HKT | 3 | 0 | 47,701 | Full refresh. PNS 26,000, Wellcome 11,538, Market Place 10,163. 21,317 hashes, 5,472 groups. DFI API returned Chinese names; English restored by SKU. |
