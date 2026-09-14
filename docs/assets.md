# Assets — Count, Strategy, and Pipeline

> **Canonical asset document.** Merges: asset_count.md + asset_review_strategy.md.
> Last updated: 2026-09-14.

---

# Part 1: Asset Count — What We Have vs What We Need

## Current status: 234 active assets (226 buildings/props/foliage + 8 weapons)

| Category | Have | Need for Vertical Slice (Suburbia) | Need for Full Alpha | Gap (Full Alpha) |
|---|---:|---:|---:|---:|
| **Buildings** | 88 | 5-8 | 25-35 | ✓ met |
| **Props (dynamic)** | 16 | 15-20 | 60-80 | ~45-65 |
| **Props (static fixtures)** | 11 | 8-10 | 20-25 | ~10-15 |
| **Foliage** | 19 | 8-10 | 20-25 | ~5-10 |
| **Environment** | 40+ | 10-15 | 35-45 | ✓ met |
| **Characters** | 5 | 2-3 (player + walker) | 5-8 | ✓ met |
| **Vehicles** | 8 (M.A.V.S) | 0 | 5-10 | ~0-5 |
| **Weapons** | 8 | 4 | 8-12 | ✓ met |
| **Decals** | 0 | 0 | 0 | 0 |

---

# Part 2: Asset Review Strategy — How I Review Thousands of Assets

> **Problem:** alpha needs maybe 1000+ assets (buildings × variants, props × variants, foliage, vehicles, decals, etc.). User cannot review each one. Yet we need quality control.

## The Problem, Quantified

| Category | Distinct assets | Variants per asset | Total instances |
|---|---:|---:|---:|
| Buildings (exteriors) | ~40 | 3 (pristine, weathered, ruined) | 120 |
| Buildings (interiors, per room type) | ~25 | 4 (furniture layouts) | 100 |
| Props (furniture, loot, decoration) | ~150 | 2-5 (color variants, conditions) | ~500 |
| Foliage (trees, bushes, grass, crops) | ~30 | 3 (seasons/conditions) | 90 |
| Vehicles | ~15 | 4 (colors, damage states) | 60 |
| Decals (blood, grime, posters) | ~25 | — | 25 |
| Environment (terrain patches, roads, fences, lights) | ~40 | — | 40 |
| **Total** | | | **~935** |

## The Strategy — Tiered Review

### Tier 1 — Style Anchor (~10 assets, user reviews every one)
The visual anchors that define the project's style. If these are wrong, everything is wrong. User reviews every variant.

### Tier 2 — Variant Burst (~50 assets, user reviews contact sheets)
Assets that branch from Tier 1 anchors. Reviewed via contact sheets (batch renders grouped into a single image), not individually.

### Tier 3 — Filler (~100+ assets, AI reviews, user spot-checks)
Background variety. AI checks polygon count, texture resolution, manifest tags. User spot-checks 10%.

## Review Workflow

1. **Build batch** — MoGen generates 10-20 assets per batch
2. **Contact sheet** — `scripts/build_tier1_contact_sheet.py` renders all into one PNG
3. **User reviews** — approves/rejects/requests changes per asset
4. **AI fixes** — rejected assets get regenerated with adjusted MoGen DSL
5. **Register** — approved assets added to `city_manifest.json`

## Asset Categories (from city_manifest.json)

| Category | Count | Examples |
|---|---:|---|
| buildings | 88 | suburban_house_v2, grocery_store, stadium |
| environment | 40+ | road_straight, street_light, mailbox |
| foliage | 19 | oak_tree, pine_tree, bush |
| characters | 5 | walker_zombie, npc_survivor |
| weapons | 8 | pistol, rifle, shotgun, axe |
| vehicles | 8 | (M.A.V.S addon) |
| props | 16 | trash_can, planter_box, parking_meter |
