# HANDOFF — for the next chat session

> **Created:** 2026-09-14
> **Purpose:** Bootstrap a fresh chat with the current state of the Mazar project.

## Read these first (in order)

1. `docs/GDD.md` — start with §1.1 vision + §4.1-4.7 (map + authoring approach)
2. `roadmap.md` — current status + next priorities
3. `worklog.md` — bottom entry is the latest: `phase-b6-lot-system-diagnosis-and-fixed-map-pivot`
4. `STATUS.md` — what's current vs archived

## The single most important fact

**The map is FIXED and HAND-AUTHORED. The runtime procedural generation in `chunk_streamer.gd` is a TESTING SCAFFOLD for validating the asset pipeline — it is NOT the final product.**

Pillar 1 of the GDD: *"Authored skeleton, procedural flesh."* The skeleton (roads, landmarks, building exteriors, lot compositions) is fixed. The flesh (interior furniture placement, loot, zombie spawns) is procedural.

This was mis-stated in the previous chat's first response — the AI recommended "don't hand-author, fix the generator" because it assumed streaming/infinite was the goal. The user corrected this. The GDD §1.1 + §4.3 + new §4.7 now state the fixed-map intent unambiguously.

## Where we are right now (2026-09-14)

**Done:**
- Asset pipeline: 226 GLBs registered in `city_manifest.json`
- 10 biomes defined in `city_config.gd`
- 3 hand-authored district templates (`data/district_templates.gd`): suburb_block, commercial_strip, downtown_block
- `DistrictStamper` stamps these at chunk anchors with per-run variation
- Parcel system (`tools/block_layout.gd`) subdivides chunks into parcels with front_dir + building_pos + yard_pos
- Runtime chunk gen produces a testable city — 25 visible chunks, ~30-40 buildings per major-biome chunk
- Phase A.1-A.12 + Phase B.1-B.5 work documented in `roadmap.md`

**Pain point (this session's diagnosis):**

VLM analysis of 5 screenshots (`pz3d/screenshots/image.png` through `image5.png`) confirmed:
- Houses face random directions relative to roads (mostly random rotation per building)
- Garages are placed by the **gap filler loop** at random positions with random rotation — no "this garage belongs to this house" link
- Interior paths are 2 cross-stripes through chunk centers, NOT connecting house front doors to road sidewalks
- No clustering — auxiliary structures (sheds, garages, garden gnomes) are scattered uniformly

**Root cause:** The system has `Parcel` (1 primary building + yard position) but no `Lot` concept that owns:
- 1 primary building
- N companion structures with RELATIVE offsets to the primary
- A sidewalk polyline from road edge → building front door
- A driveway polyline from road edge → garage door
- A setback distance from the road

The gap filler loop at `chunk_streamer.gd:711` picks `garage_detached` etc. at random chunk positions with `crng.randf_range(0, TAU)` rotation. That is the literal source of the "garage faces a different side" observation.

## What's next — Lot System (Phase B.6)

The plan, agreed in this session, is to add the missing Lot data structure. NOT hand-author the entire map as one scene (rationale: GDD §4.7 — fixed map is the goal, but full-map hand-authoring kills replayability of the procedural-flesh layer; the right scope is hand-authored Lot RECIPES that stamp at parcel positions, like the existing district templates do for hero blocks).

**Three-step plan** (full detail in `worklog.md` bottom entry):

1. `tools/lot.gd` (~80 lines) — Lot data structure + recipes for 6 biomes
2. `tools/lot_stamper.gd` (~150 lines) — stamper mirroring `district_stamper.gd`
3. Patch `chunk_streamer.gd:617-690` — call LotStamper per parcel instead of the parcel-by-parcel loop, and replace the gap filler's garage/shed scatter with lot-companion placement

After this, the visual contract is:
- House + garage always sit on the same lot, garage door aligned with house front
- A grey sidewalk strip goes from each house's front door to the nearest road
- A wider grey driveway strip goes from each garage to the nearest road
- Gap filler becomes lot-level — no more random garages in fields

## Alternative the user offered

The user floated: "want try your luck doing hand authored full map in another scene?"

The cheaper version of that idea is also on the table: hand-author ONE hero block in a separate `authored_reference.tscn` scene as a **visual contract** / target for what the generator should produce. ~1 day of work. Useful as a benchmark, not a substitute for fixing the Lot system.

User will decide in next chat which path to take.

## Quick file map

| Path | What |
|---|---|
| `docs/GDD.md` | Canonical game design doc (1221 lines, v2.0) |
| `roadmap.md` | Phase tracker + bug list + middleware usage |
| `worklog.md` | Append-only multi-session work log |
| `STATUS.md` | Current vs archived docs |
| `godot_project/tools/chunk_streamer.gd` | The runtime gen (TESTING ONLY) |
| `godot_project/tools/block_layout.gd` | Parcel system (needs Lot upgrade) |
| `godot_project/tools/district_stamper.gd` | Hero template stamper (model for LotStamper) |
| `godot_project/data/district_templates.gd` | 3 hand-authored hero templates (model for lot recipes) |
| `godot_project/data/city_manifest.json` | 226 GLBs registered |
| `screenshots/` | 5 latest screenshots from this session |
