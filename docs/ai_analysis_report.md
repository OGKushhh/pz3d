# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **75**
> Total opportunities found: **62**
> Total actions generated: **48**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| too_close | 25 | Buildings within 3m of each other (spacing violation) |
| asset_repetition | 24 | Same asset appearing >5 times in one chunk |
| overlaps | 21 | Buildings with intersecting AABBs (3D overlap) |
| min_spacing_violation | 5 |  |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_halo_buildings | 14 | Landmark halo didn't attract its boost buildings |
| missing_pair | 13 |  |
| high_density_gap | 10 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 48 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 10,5 | COASTAL_BEACH | 268 | 97% | 3 | 3 | 2 |
| 11,6 | COASTAL_BEACH | 319 | 97% | 3 | 3 | 2 |
| 10,6 | COASTAL_BEACH | 383 | 96% | 3 | 3 | 2 |
| 7,7 | PARKS | 839 | 94% | 3 | 2 | 2 |
| 11,5 | COASTAL_BEACH | 516 | 93% | 3 | 4 | 2 |
| 11,7 | COASTAL_BEACH | 413 | 93% | 3 | 2 | 2 |
| 10,7 | COASTAL_BEACH | 239 | 86% | 2 | 2 | 2 |
| 7,4 | PARKS | 1293 | 85% | 3 | 3 | 2 |
| 7,5 | PARKS | 1832 | 82% | 3 | 4 | 2 |
| 10,8 | COASTAL_BEACH | 378 | 81% | 3 | 4 | 2 |
| 11,4 | COASTAL_BEACH | 872 | 77% | 3 | 2 | 2 |
| 8,4 | FARMLAND | 233 | 75% | 3 | 2 | 2 |
| 9,5 | FARMLAND | 379 | 75% | 3 | 2 | 2 |
| 10,4 | COASTAL_BEACH | 282 | 73% | 2 | 3 | 2 |
| 11,8 | COASTAL_BEACH | 322 | 73% | 3 | 2 | 2 |
| 7,6 | PARKS | 137 | 71% | 1 | 1 | 0 |
| 8,5 | FARMLAND | 137 | 70% | 2 | 2 | 2 |
| 9,4 | FARMLAND | 1465 | 53% | 3 | 2 | 2 |
| 7,8 | COMMERCIAL | 888 | 51% | 4 | 2 | 2 |
| 9,7 | COMMERCIAL | 1346 | 47% | 4 | 2 | 2 |
| 9,6 | COMMERCIAL | 1281 | 39% | 4 | 3 | 2 |
| 8,8 | COMMERCIAL | 816 | 37% | 3 | 2 | 2 |
| 9,8 | COMMERCIAL | 945 | 35% | 4 | 2 | 2 |
| 8,7 | COMMERCIAL | 1101 | 32% | 4 | 2 | 2 |
| 8,6 | COMMERCIAL | 572 | 29% | 3 | 3 | 2 |
