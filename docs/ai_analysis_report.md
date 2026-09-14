# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **13**
> Total opportunities found: **41**
> Total actions generated: **5**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| min_spacing_violation | 8 |  |
| overlaps | 2 | Buildings with intersecting AABBs (3D overlap) |
| asset_repetition | 2 | Same asset appearing >5 times in one chunk |
| too_close | 1 | Buildings within 3m of each other (spacing violation) |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_pair | 13 |  |
| high_density_gap | 3 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 4 |
| reposition | 1 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 7,7 | PARKS | 0 | 96% | 0 | 2 | 0 |
| 8,11 | WETLANDS | 0 | 87% | 0 | 2 | 0 |
| 7,11 | WETLANDS | 0 | 82% | 0 | 2 | 0 |
| 6,7 | PARKS | 0 | 75% | 0 | 1 | 0 |
| 6,11 | WETLANDS | 0 | 75% | 0 | 1 | 0 |
| 8,10 | WETLANDS | 0 | 74% | 0 | 1 | 0 |
| 7,10 | WETLANDS | 0 | 69% | 0 | 1 | 0 |
| 5,7 | PARKS | 0 | 67% | 0 | 1 | 0 |
| 5,9 | PARKS | 0 | 67% | 0 | 1 | 0 |
| 6,10 | WETLANDS | 0 | 67% | 0 | 1 | 0 |
| 9,11 | WETLANDS | 0 | 65% | 0 | 1 | 0 |
| 9,10 | WETLANDS | 0 | 60% | 0 | 1 | 0 |
| 7,9 | COMMERCIAL | 8 | 55% | 1 | 2 | 0 |
| 7,8 | COMMERCIAL | 10 | 51% | 1 | 2 | 0 |
| 8,9 | COMMERCIAL | 5 | 49% | 0 | 2 | 0 |
| 6,8 | COMMERCIAL | 8 | 47% | 1 | 2 | 0 |
| 6,9 | COMMERCIAL | 3 | 47% | 0 | 2 | 0 |
| 9,7 | COMMERCIAL | 12 | 45% | 1 | 2 | 0 |
| 5,8 | COMMERCIAL | 7 | 45% | 1 | 2 | 0 |
| 9,8 | COMMERCIAL | 6 | 41% | 1 | 2 | 0 |
| 9,9 | COMMERCIAL | 4 | 39% | 0 | 2 | 0 |
| 8,8 | COMMERCIAL | 7 | 36% | 1 | 2 | 0 |
| 8,7 | COMMERCIAL | 14 | 35% | 1 | 2 | 0 |
| 5,11 | SUBURBIA | 59 | 33% | 3 | 2 | 3 |
| 5,10 | SUBURBIA | 57 | 32% | 2 | 2 | 2 |
