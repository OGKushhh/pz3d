# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **71**
> Total opportunities found: **48**
> Total actions generated: **98**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| asset_repetition | 25 | Same asset appearing >5 times in one chunk |
| too_close | 25 | Buildings within 3m of each other (spacing violation) |
| overlaps | 21 | Buildings with intersecting AABBs (3D overlap) |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_halo_buildings | 14 | Landmark halo didn't attract its boost buildings |
| high_density_gap | 9 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 50 |
| fill | 48 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|
| green_space | 24 |
| backyard | 14 |
| tree_cluster | 10 |

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 10,5 | COASTAL_BEACH | 270 | 97% | 3 | 3 | 5 |
| 11,6 | COASTAL_BEACH | 331 | 97% | 3 | 2 | 4 |
| 10,6 | COASTAL_BEACH | 391 | 96% | 3 | 3 | 5 |
| 11,5 | COASTAL_BEACH | 528 | 93% | 3 | 3 | 5 |
| 11,7 | COASTAL_BEACH | 419 | 93% | 3 | 2 | 4 |
| 7,7 | PARKS | 915 | 91% | 3 | 2 | 4 |
| 10,7 | COASTAL_BEACH | 241 | 86% | 2 | 2 | 4 |
| 7,4 | PARKS | 1377 | 82% | 3 | 2 | 4 |
| 10,8 | COASTAL_BEACH | 388 | 81% | 3 | 3 | 5 |
| 7,5 | PARKS | 1925 | 79% | 3 | 2 | 4 |
| 11,4 | COASTAL_BEACH | 879 | 77% | 3 | 2 | 4 |
| 8,4 | FARMLAND | 229 | 75% | 3 | 2 | 4 |
| 9,5 | FARMLAND | 501 | 75% | 3 | 2 | 4 |
| 10,4 | COASTAL_BEACH | 284 | 73% | 2 | 2 | 4 |
| 11,8 | COASTAL_BEACH | 332 | 73% | 3 | 2 | 4 |
| 8,5 | FARMLAND | 139 | 70% | 2 | 2 | 4 |
| 7,6 | PARKS | 182 | 68% | 2 | 1 | 3 |
| 9,4 | FARMLAND | 1519 | 53% | 3 | 2 | 4 |
| 7,8 | COMMERCIAL | 981 | 47% | 3 | 1 | 3 |
| 9,7 | COMMERCIAL | 1473 | 44% | 3 | 1 | 3 |
| 9,6 | COMMERCIAL | 1376 | 37% | 3 | 2 | 4 |
| 8,8 | COMMERCIAL | 912 | 33% | 3 | 1 | 3 |
| 9,8 | COMMERCIAL | 1035 | 32% | 3 | 1 | 3 |
| 8,7 | COMMERCIAL | 1200 | 29% | 3 | 1 | 3 |
| 8,6 | COMMERCIAL | 695 | 26% | 3 | 2 | 4 |
