# AI Middleware Analysis Report
> Generated from 6 chunk states.
> Total problems detected: **8**
> Total opportunities found: **8**
> Total actions generated: **6**

## Problem Types Detected

| Problem Type | Count | Description |
|---|---|---|
| overlaps | 3 | Buildings with intersecting AABBs (3D overlap) |
| semantic_conflict | 2 |  |
| too_close | 2 | Buildings within 3m of each other (spacing violation) |
| min_spacing_violation | 1 |  |

## Opportunities Found

| Opportunity Type | Count | Description |
|---|---|---|
| missing_pair | 3 |  |
| missing_halo_buildings | 2 | Landmark halo didn't attract its boost buildings |
| biome_border | 2 | Chunk borders a different biome (transition zone) |
| high_density_gap | 1 | Chunk >80% empty gaps |

## Generated Actions

| Action Type | Count |
|---|---|
| remove | 4 |
| reposition | 2 |

### Fill Type Distribution

| Fill Type | Count |
|---|---|

## Per-Chunk Analysis (sorted by gap_pct descending)

| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |
|---|---|---|---|---|---|---|
| 0,0 | ? | 0 | 100% | 0 | 1 | 0 |
| 3,7 | DOWNTOWN | 2 | 80% | 2 | 3 | 1 |
| 50,50 | COMMERCIAL | 3 | 50% | 4 | 2 | 3 |
| 99,99 | ? | 3 | 0% | 2 | 1 | 2 |
| -5,-5 | COMMERCIAL | 1 | 0% | 0 | 1 | 0 |
| 255,255 | ? | 0 | 0% | 0 | 0 | 0 |
