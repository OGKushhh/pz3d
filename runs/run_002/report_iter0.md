# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **13**
> Total opportunities found: **45**
> Total actions generated: **4**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| min_spacing_violation | 9 |  |
| overlaps | 2 | Buildings with intersecting AABBs (3D overlap) |
| asset_repetition | 2 | Same asset appearing >5 times in one chunk |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_pair | 13 |  |
| high_density_gap | 5 | Chunk >80% empty gaps |
| missing_parking_lot | 2 | Commercial chunk with no parking lot |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 4 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 7,7 | PARKS | 0 | 97% | 0 | 2 | 0 |
| 7,11 | WETLANDS | 0 | 95% | 0 | 2 | 0 |
| 8,11 | WETLANDS | 0 | 88% | 0 | 2 | 0 |
| 6,11 | WETLANDS | 0 | 84% | 0 | 2 | 0 |
| 7,10 | WETLANDS | 0 | 81% | 0 | 2 | 0 |
| 5,7 | PARKS | 0 | 78% | 0 | 1 | 0 |
| 5,9 | PARKS | 0 | 77% | 0 | 1 | 0 |
| 6,10 | WETLANDS | 0 | 77% | 0 | 1 | 0 |
| 8,10 | WETLANDS | 0 | 77% | 0 | 1 | 0 |
| 6,7 | PARKS | 0 | 75% | 0 | 1 | 0 |
| 9,11 | WETLANDS | 0 | 68% | 0 | 1 | 0 |
| 9,10 | WETLANDS | 0 | 59% | 0 | 1 | 0 |
| 7,9 | COMMERCIAL | 11 | 52% | 1 | 2 | 0 |
| 7,8 | COMMERCIAL | 13 | 51% | 1 | 2 | 0 |
| 5,8 | COMMERCIAL | 8 | 47% | 1 | 2 | 0 |
| 6,8 | COMMERCIAL | 8 | 46% | 1 | 2 | 0 |
| 6,9 | COMMERCIAL | 3 | 46% | 0 | 3 | 0 |
| 9,7 | COMMERCIAL | 10 | 45% | 1 | 2 | 0 |
| 8,9 | COMMERCIAL | 8 | 45% | 1 | 2 | 0 |
| 5,11 | SUBURBIA | 34 | 41% | 2 | 2 | 2 |
| 9,8 | COMMERCIAL | 8 | 39% | 1 | 2 | 0 |
| 9,9 | COMMERCIAL | 4 | 39% | 0 | 3 | 0 |
| 8,8 | COMMERCIAL | 12 | 34% | 1 | 2 | 0 |
| 8,7 | COMMERCIAL | 17 | 32% | 1 | 2 | 0 |
| 5,10 | SUBURBIA | 28 | 31% | 2 | 2 | 2 |
