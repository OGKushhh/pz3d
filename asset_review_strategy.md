# Asset Review Strategy — How I Review Thousands of Assets

> **Problem:** alpha needs maybe 1000+ assets (buildings × variants, props × variants, foliage, vehicles, decals, etc.). User cannot review each one. Yet we need quality control.
>
> **Solution below.** Read it once, then we operate this way forever.

---

## The Problem, Quantified

A real Zomboid-equivalent alpha needs roughly:

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

If I asked you to review each at 1 minute each: ~16 hours of pure review. Too much.

---

## The Strategy — Tiered Review

### Tier 1 — Style Anchor (user reviews every one) ~10 assets

These define the visual identity for the entire category. User reviews every render, locks the style, and from then on I produce variants that match.

Examples:
- 1 house (the canonical suburban house — done, `suburban_house.png`)
- 1 chair, 1 table, 1 cup, 1 fence (style anchors for furniture)
- 1 tree, 1 bush, 1 patch of grass (style anchors for foliage)
- 1 car, 1 truck (style anchors for vehicles)
- 1 decal (blood splatter — style anchor for grime)
- 1 humanoid (style anchor for characters — done, `humanoid.png`)

**Review cadence:** each one as a single 1024px PNG, ~30 seconds to approve.

### Tier 2 — Variant Pack (user reviews thumbnails in batches) ~80 assets

After Tier 1 is locked, I generate variants of each anchor. User reviews in **batched contact sheets** — one PNG with 8-12 thumbnails, approve/reject the batch or specific items.

Examples:
- House variants: pristine, weathered, ruined, burned — one contact sheet, 4 thumbnails
- Tree variants: oak, pine, birch, dead — one contact sheet, 4 thumbnails
- Decal batches: 12 blood splatters in one sheet — approve/reject per item

**Review cadence:** 1 contact sheet per category per week, ~2-3 minutes each. ~20 minutes/week total.

### Tier 3 — Mass Production (no per-asset user review) ~900 assets

Once Tier 1 + Tier 2 are locked, I produce the long tail autonomously. These are:
- Procedural variants (slightly different colors, slightly different scales)
- Combinations of locked modules (a house = locked shell + locked furniture modules + procedural layout)
- Asset library fills (100 different kinds of books, 50 different cans of food)

**Quality control:**
- I run `mogen check` on every single one (zero diagnostics allowed)
- I run an automated VLM sanity check on every render ("is this recognisable as X?")
- I generate a thumbnail contact sheet per category per sprint (you spot-check)
- I commit to git in batches with a manifest file listing what was generated

**User review:** spot-check only. You see the alpha map at the end of each biome milestone.

### Tier 4 — Final Alpha Review (user reviews the assembled map)

At the end of each biome milestone (per the alpha build order), I:
1. Assemble all assets for that biome in a Godot scene
2. Render a flythrough / overview screenshot via Chrome + three.js
3. You review the **biome as a whole** — not individual assets

This is the "final alpha map" review you mentioned. You see the spirit, the mood, the density. If something is wrong, you tell me "the houses feel too repetitive" or "too many red cars" and I tune the procedural generation, not individual assets.

---

## The Batch Zip Idea (your suggestion, refined)

You mentioned zipping every bulk rendering for mass review. Here's how I'll do it:

### Per-batch output structure

```
/home/z/my-project/download/asset-batches/
├── 2026-09-15_suburbia_houses_batch-001/
│   ├── contact_sheet.png          # 1 image with all 8 houses as thumbnails
│   ├── manifest.md                 # what's in this batch, how to read it
│   ├── renders/                    # full-size PNGs, one per asset
│   │   ├── house_suburbia_001.png
│   │   ├── house_suburbia_002.png
│   │   └── ...
│   ├── sources/                    # .mog source files
│   │   ├── house_suburbia_001.mog
│   │   └── ...
│   └── glbs/                        # compiled .glb files
│       ├── house_suburbia_001.glb
│       └── ...
└── 2026-09-22_suburbia_props_batch-002/
    └── ...
```

### Contact sheet format

A single 2048×2048 PNG with 16 thumbnails in a 4×4 grid. Each thumbnail labeled with the asset ID. Caption underneath: "Suburbia Houses Batch 001 — 8 variants. Reply with: APPROVE ALL / REJECT <ids> / REGENERATE <ids> with note".

You reply with one line: "APPROVE ALL" or "REJECT 003, 007 — too tall" or "REGEN 005 with steeper roof".

### Zipped exports

At the end of each sprint (every 2 weeks), I bundle everything into:
```
/home/z/my-project/download/asset-batches/2026-09-sprint-01_suburbia.zip
```

The zip contains the .mog source + .glb + .png for every asset, ready to import into Godot.

---

## What I Auto-Validate (so you don't have to)

Every asset goes through these checks before it's even shown to you:

1. **`mogen check`** — zero diagnostics (mandatory). Won't show you broken files.
2. **`mogen build`** — must succeed in <100ms. Won't show you slow/broken GLBs.
3. **Automated VLM sanity check** — I send the render to GLM-5V and ask "is this recognisable as <category>?". If VLM says no, I regenerate before showing you.
4. **Scale check** — every asset has a known target dimension (door = 0.90m wide × 2.10m tall, etc.). I check the asset's bounding box against the target. Off-scale assets are auto-flagged.
5. **Palette check** — once we lock the palette, I check every asset's material colors against the swatch. Off-palette assets are auto-flagged.
6. **LOD sanity** — every asset must have a valid LOD chain (or be marked as "no LOD needed" with reason).

If any check fails, you never see the asset. It goes into a "regenerate" queue.

---

## What You Actually Review

| Tier | What you see | Cadence | Time per session |
|---|---|---|---|
| 1 — Style anchors | Individual 1024px PNG | Once per anchor (~10 total) | 1 min each |
| 2 — Variant packs | Contact sheets (4-16 thumbs) | Once per category (~5 total) | 3 min each |
| 3 — Mass production | Spot checks only | You ask, I show | 0 unless you ask |
| 4 — Biome milestone | Full biome overview render | Once per biome (10 total, per build order) | 10 min each |

**Total time investment:** ~3 hours of review across the entire alpha build. Not 16 hours.

---

## How to Communicate

When you review a batch, reply with one of:
- `APPROVE ALL` — ship it
- `APPROVE EXCEPT <ids>` — list the asset IDs to reject
- `REGEN <ids> WITH <note>` — list asset IDs and what to change
- `REJECT BATCH — <reason>` — nuke the whole batch and rethink

I'll keep a public log of every review decision in `/home/z/my-project/asset-pipeline/worklog/worklog.md` so we never lose track of why asset 042 is taller than asset 041.

---

## First Style Anchors Queue

To kick off Tier 1, here are the first 10 assets I'll produce. Each gets its own 1024px render for individual review:

1. ~~Canonical suburban house~~ ✅ done (`suburban_house.png`)
2. ~~DSL humanoid~~ ✅ done (`humanoid.png`) — but for alpha characters stay DSL
3. Office chair (interior prop anchor)
4. Dining table (interior prop anchor)
5. Oak tree (foliage anchor)
6. Bush (foliage anchor)
7. Sedan car (vehicle anchor)
8. Pickup truck (vehicle anchor)
9. Blood splatter decal (decal anchor)
10. Asphalt road segment (environment anchor)

Once these 10 are approved, I can produce the entire alpha map's variant packs autonomously, in batches.

**Ready to start Tier 1 production? Or want to lock the city lore + palette first?**
