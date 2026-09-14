# AI Middleware Analysis Report
> Generated from 18 chunk states.
> Total problems detected: **11**
> Total opportunities found: **30**
> Total actions generated: **7**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| overlaps | 5 | Buildings with intersecting AABBs (3D overlap) |
| min_spacing_violation | 5 |  |
| asset_repetition | 1 | Same asset appearing >5 times in one chunk |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 18 | Chunk borders a different biome (transition zone) |
| missing_pair | 12 |  |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 7 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 7,7 | PARKS | 0 | 75% | 0 | 1 | 0 |
| 6,7 | PARKS | 0 | 60% | 0 | 1 | 0 |
| 7,10 | WETLANDS | 0 | 55% | 0 | 1 | 0 |
| 5,9 | PARKS | 0 | 53% | 0 | 1 | 0 |
| 6,10 | WETLANDS | 0 | 53% | 0 | 1 | 0 |
| 5,7 | PARKS | 0 | 52% | 0 | 1 | 0 |
| 7,9 | COMMERCIAL | 9 | 49% | 2 | 2 | 1 |
| 7,8 | COMMERCIAL | 10 | 47% | 2 | 2 | 1 |
| 6,9 | COMMERCIAL | 3 | 43% | 0 | 2 | 0 |
| 9,7 | COMMERCIAL | 10 | 42% | 2 | 2 | 1 |
| 6,8 | COMMERCIAL | 4 | 42% | 0 | 2 | 0 |
| 8,9 | COMMERCIAL | 4 | 41% | 0 | 2 | 0 |
| 5,8 | COMMERCIAL | 4 | 37% | 0 | 2 | 0 |
| 9,8 | COMMERCIAL | 3 | 36% | 0 | 2 | 0 |
| 9,9 | COMMERCIAL | 4 | 34% | 0 | 2 | 0 |
| 8,8 | COMMERCIAL | 4 | 32% | 0 | 2 | 0 |
| 8,7 | COMMERCIAL | 11 | 31% | 2 | 2 | 2 |
| 5,10 | SUBURBIA | 59 | 25% | 3 | 2 | 2 |
