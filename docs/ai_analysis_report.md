# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **24**
> Total opportunities found: **56**
> Total actions generated: **11**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| min_spacing_violation | 12 |  |
| overlaps | 7 | Buildings with intersecting AABBs (3D overlap) |
| asset_repetition | 5 | Same asset appearing >5 times in one chunk |

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
| remove | 11 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 7,7 | PARKS | 1 | 86% | 0 | 4 | 0 |
| 8,11 | WETLANDS | 3 | 78% | 0 | 1 | 0 |
| 8,10 | WETLANDS | 5 | 71% | 0 | 1 | 0 |
| 6,11 | WETLANDS | 14 | 71% | 1 | 2 | 0 |
| 6,7 | PARKS | 1 | 67% | 0 | 1 | 0 |
| 6,10 | WETLANDS | 6 | 67% | 0 | 1 | 0 |
| 5,9 | PARKS | 8 | 63% | 2 | 2 | 0 |
| 7,10 | WETLANDS | 24 | 63% | 1 | 2 | 0 |
| 7,11 | WETLANDS | 34 | 60% | 2 | 2 | 0 |
| 9,11 | WETLANDS | 4 | 60% | 0 | 1 | 0 |
| 5,7 | PARKS | 16 | 59% | 1 | 1 | 0 |
| 9,10 | WETLANDS | 2 | 55% | 0 | 1 | 0 |
| 6,8 | COMMERCIAL | 3 | 46% | 0 | 3 | 0 |
| 7,8 | COMMERCIAL | 16 | 46% | 2 | 3 | 1 |
| 6,9 | COMMERCIAL | 11 | 41% | 2 | 3 | 1 |
| 5,10 | SUBURBIA | 12 | 40% | 1 | 2 | 0 |
| 5,11 | SUBURBIA | 21 | 40% | 0 | 2 | 0 |
| 5,8 | COMMERCIAL | 12 | 39% | 2 | 3 | 2 |
| 7,9 | COMMERCIAL | 20 | 39% | 2 | 3 | 2 |
| 9,8 | COMMERCIAL | 8 | 36% | 1 | 3 | 0 |
| 8,9 | COMMERCIAL | 11 | 36% | 2 | 3 | 1 |
| 9,7 | COMMERCIAL | 18 | 34% | 2 | 3 | 2 |
| 8,8 | COMMERCIAL | 11 | 30% | 1 | 3 | 0 |
| 9,9 | COMMERCIAL | 9 | 30% | 0 | 3 | 0 |
| 8,7 | COMMERCIAL | 20 | 29% | 2 | 3 | 2 |
