# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **21**
> Total opportunities found: **55**
> Total actions generated: **10**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| min_spacing_violation | 12 |  |
| overlaps | 6 | Buildings with intersecting AABBs (3D overlap) |
| asset_repetition | 3 | Same asset appearing >5 times in one chunk |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_pair | 15 |  |
| missing_parking_lot | 12 | Commercial chunk with no parking lot |
| high_density_gap | 3 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 10 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 7,11 | WETLANDS | 3 | 91% | 0 | 3 | 0 |
| 7,7 | PARKS | 1 | 86% | 0 | 4 | 0 |
| 6,11 | WETLANDS | 0 | 83% | 0 | 2 | 0 |
| 8,11 | WETLANDS | 3 | 78% | 0 | 1 | 0 |
| 5,9 | PARKS | 0 | 76% | 0 | 1 | 0 |
| 6,10 | WETLANDS | 0 | 76% | 0 | 1 | 0 |
| 5,7 | PARKS | 0 | 75% | 0 | 1 | 0 |
| 7,10 | WETLANDS | 6 | 75% | 0 | 1 | 0 |
| 8,10 | WETLANDS | 5 | 71% | 0 | 1 | 0 |
| 6,7 | PARKS | 1 | 70% | 0 | 1 | 0 |
| 9,11 | WETLANDS | 4 | 60% | 0 | 1 | 0 |
| 9,10 | WETLANDS | 2 | 55% | 0 | 1 | 0 |
| 6,8 | COMMERCIAL | 3 | 45% | 0 | 3 | 0 |
| 7,8 | COMMERCIAL | 21 | 41% | 2 | 3 | 2 |
| 6,9 | COMMERCIAL | 11 | 40% | 2 | 3 | 1 |
| 5,10 | SUBURBIA | 12 | 40% | 1 | 2 | 0 |
| 5,11 | SUBURBIA | 24 | 39% | 1 | 2 | 0 |
| 7,9 | COMMERCIAL | 24 | 37% | 2 | 3 | 1 |
| 5,8 | COMMERCIAL | 12 | 36% | 2 | 3 | 2 |
| 9,7 | COMMERCIAL | 20 | 35% | 3 | 3 | 2 |
| 9,8 | COMMERCIAL | 8 | 35% | 1 | 3 | 0 |
| 8,9 | COMMERCIAL | 23 | 32% | 2 | 3 | 0 |
| 9,9 | COMMERCIAL | 17 | 31% | 2 | 3 | 0 |
| 8,8 | COMMERCIAL | 11 | 30% | 1 | 3 | 0 |
| 8,7 | COMMERCIAL | 23 | 27% | 2 | 3 | 2 |
