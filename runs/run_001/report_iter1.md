# AI Middleware Analysis Report
> Generated from 25 chunk states.
> Total problems detected: **6**
> Total opportunities found: **72**
> Total actions generated: **2**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| min_spacing_violation | 5 |  |
| overlaps | 1 | Buildings with intersecting AABBs (3D overlap) |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| biome_border | 25 | Chunk borders a different biome (transition zone) |
| missing_halo_buildings | 14 | Landmark halo didn't attract its boost buildings |
| missing_pair | 13 |  |
| high_density_gap | 10 | Chunk >80% empty gaps |
| missing_parking_lot | 10 | Commercial chunk with no parking lot |

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
| 10,5 | COASTAL_BEACH | 2 | 97% | 0 | 3 | 0 |
| 11,6 | COASTAL_BEACH | 1 | 97% | 0 | 4 | 0 |
| 10,6 | COASTAL_BEACH | 1 | 96% | 0 | 3 | 0 |
| 7,7 | PARKS | 0 | 94% | 0 | 2 | 0 |
| 11,5 | COASTAL_BEACH | 3 | 93% | 0 | 4 | 0 |
| 11,7 | COASTAL_BEACH | 3 | 93% | 0 | 2 | 0 |
| 10,7 | COASTAL_BEACH | 1 | 86% | 0 | 2 | 0 |
| 7,4 | PARKS | 1 | 85% | 0 | 4 | 0 |
| 7,5 | PARKS | 1 | 82% | 0 | 5 | 0 |
| 10,8 | COASTAL_BEACH | 2 | 81% | 0 | 4 | 0 |
| 11,4 | COASTAL_BEACH | 6 | 77% | 0 | 2 | 0 |
| 8,4 | FARMLAND | 1 | 75% | 0 | 2 | 0 |
| 9,5 | FARMLAND | 3 | 75% | 0 | 2 | 0 |
| 10,4 | COASTAL_BEACH | 3 | 73% | 0 | 3 | 0 |
| 11,8 | COASTAL_BEACH | 0 | 73% | 0 | 2 | 0 |
| 7,6 | PARKS | 1 | 71% | 0 | 1 | 0 |
| 8,5 | FARMLAND | 0 | 70% | 0 | 2 | 0 |
| 9,4 | FARMLAND | 2 | 53% | 0 | 2 | 0 |
| 7,8 | COMMERCIAL | 10 | 51% | 1 | 3 | 0 |
| 9,7 | COMMERCIAL | 18 | 47% | 1 | 3 | 0 |
| 9,6 | COMMERCIAL | 13 | 39% | 2 | 4 | 2 |
| 8,8 | COMMERCIAL | 4 | 37% | 0 | 3 | 0 |
| 9,8 | COMMERCIAL | 12 | 35% | 1 | 3 | 0 |
| 8,7 | COMMERCIAL | 10 | 32% | 1 | 3 | 0 |
| 8,6 | COMMERCIAL | 4 | 29% | 0 | 4 | 0 |
