# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **78**
> Total opportunities found: **60**
> Total actions generated: **135**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| asset_repetition | 25 | Same asset appearing >5 times in one chunk |
| too_close | 25 | Buildings within 3m of each other (spacing violation) |
| overlaps | 23 | Buildings with intersecting AABBs (3D overlap) |
| min_spacing_violation | 5 |  |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_halo_buildings | 14 | Landmark halo didn't attract its boost buildings |
| missing_pair | 13 |  |
| high_density_gap | 8 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 50 |
| fill | 47 |
| reposition | 38 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|
| green_space | 24 |
| backyard | 14 |
| tree_cluster | 9 |

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 11,6 | COASTAL_BEACH | 373 | 95% | 3 | 3 | 6 |
| 10,5 | COASTAL_BEACH | 346 | 94% | 3 | 3 | 7 |
| 10,6 | COASTAL_BEACH | 461 | 93% | 3 | 3 | 7 |
| 7,7 | PARKS | 911 | 92% | 3 | 2 | 6 |
| 11,7 | COASTAL_BEACH | 462 | 91% | 3 | 2 | 6 |
| 11,5 | COASTAL_BEACH | 611 | 90% | 3 | 4 | 7 |
| 10,7 | COASTAL_BEACH | 296 | 84% | 2 | 2 | 6 |
| 7,4 | PARKS | 1364 | 83% | 3 | 3 | 6 |
| 7,5 | PARKS | 1921 | 80% | 3 | 3 | 4 |
| 10,8 | COASTAL_BEACH | 462 | 78% | 3 | 3 | 6 |
| 11,4 | COASTAL_BEACH | 937 | 75% | 3 | 2 | 6 |
| 8,4 | FARMLAND | 290 | 73% | 3 | 2 | 6 |
| 10,4 | COASTAL_BEACH | 312 | 73% | 3 | 3 | 6 |
| 9,5 | FARMLAND | 559 | 72% | 3 | 2 | 4 |
| 11,8 | COASTAL_BEACH | 380 | 72% | 3 | 2 | 6 |
| 7,6 | PARKS | 156 | 70% | 2 | 1 | 3 |
| 8,5 | FARMLAND | 194 | 68% | 3 | 2 | 4 |
| 9,4 | FARMLAND | 1571 | 50% | 3 | 2 | 6 |
| 7,8 | COMMERCIAL | 924 | 50% | 4 | 2 | 5 |
| 9,7 | COMMERCIAL | 1355 | 46% | 4 | 2 | 5 |
| 9,6 | COMMERCIAL | 1351 | 38% | 4 | 3 | 4 |
| 8,8 | COMMERCIAL | 856 | 35% | 3 | 2 | 5 |
| 9,8 | COMMERCIAL | 976 | 34% | 4 | 2 | 5 |
| 8,7 | COMMERCIAL | 1141 | 31% | 4 | 2 | 5 |
| 8,6 | COMMERCIAL | 667 | 27% | 3 | 3 | 4 |
