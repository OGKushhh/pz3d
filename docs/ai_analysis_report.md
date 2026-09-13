# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **27**
> Total opportunities found: **56**
> Total actions generated: **2**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| asset_repetition | 14 | Same asset appearing >5 times in one chunk |
| min_spacing_violation | 12 |  |
| overlaps | 1 | Buildings with intersecting AABBs (3D overlap) |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_pair | 18 |  |
| missing_parking_lot | 12 | Commercial chunk with no parking lot |
| high_density_gap | 1 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 2 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 7,7 | PARKS | 1 | 87% | 0 | 4 | 0 |
| 8,11 | WETLANDS | 4 | 77% | 0 | 1 | 0 |
| 6,7 | PARKS | 1 | 70% | 0 | 1 | 0 |
| 6,10 | WETLANDS | 8 | 70% | 0 | 1 | 0 |
| 8,10 | WETLANDS | 5 | 70% | 0 | 1 | 0 |
| 6,11 | WETLANDS | 16 | 69% | 1 | 2 | 0 |
| 5,9 | PARKS | 8 | 65% | 1 | 1 | 0 |
| 7,11 | WETLANDS | 32 | 65% | 2 | 2 | 0 |
| 9,11 | WETLANDS | 3 | 64% | 0 | 1 | 0 |
| 7,10 | WETLANDS | 23 | 61% | 1 | 2 | 0 |
| 5,7 | PARKS | 18 | 60% | 1 | 2 | 0 |
| 9,10 | WETLANDS | 3 | 54% | 0 | 1 | 0 |
| 6,8 | COMMERCIAL | 4 | 47% | 0 | 3 | 0 |
| 5,11 | SUBURBIA | 18 | 44% | 0 | 2 | 0 |
| 6,9 | COMMERCIAL | 13 | 41% | 2 | 3 | 0 |
| 7,8 | COMMERCIAL | 21 | 40% | 2 | 3 | 0 |
| 7,9 | COMMERCIAL | 18 | 39% | 2 | 3 | 0 |
| 5,10 | SUBURBIA | 9 | 39% | 1 | 2 | 0 |
| 9,7 | COMMERCIAL | 19 | 37% | 2 | 3 | 0 |
| 5,8 | COMMERCIAL | 12 | 36% | 1 | 3 | 0 |
| 9,8 | COMMERCIAL | 11 | 34% | 2 | 3 | 0 |
| 8,9 | COMMERCIAL | 21 | 33% | 2 | 3 | 0 |
| 8,7 | COMMERCIAL | 23 | 30% | 2 | 3 | 0 |
| 8,8 | COMMERCIAL | 14 | 30% | 3 | 3 | 2 |
| 9,9 | COMMERCIAL | 20 | 27% | 2 | 3 | 0 |
