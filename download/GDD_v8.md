# Game Design Document — Mazar Alpha

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v8 — pre-production → vertical slice. Lore semi-locked. Path B locked. **Tier 1 production: 18 approved + 5 retired. Kitchen counter split into 4 modular pieces (PZ-style).**
> **Working title:** *Mazar*
> **Lore:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, **semi-locked for alpha**)
> **Poly budget:** `/home/z/my-project/download/poly_budget_v3_path_b.md` (v3, **locked — two-tier Low/High presets**)
> **Furniture decision:** `/home/z/my-project/download/furniture_merging_decision.md` (**locked — static vs dynamic + modular kitchen**)
> **Engine:** Godot 4.7.2 (glTF 2.0 native, **Compatibility renderer default for Low preset**)
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot)
> **MoGen reference:** `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB, compiled)

---

## 1. Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is the National City of Mazar — a fictional coastal city divided by the Sarran River, where a 300-year monarchy ended in a quiet coup 70 years ago, where a military junta sold the nation to a foreign Border Enemy, where Operation Living Troop created a supersoldier serum that killed its subjects and raised them as the undead.

The city is fixed, persistent, hand-crafted. Every building enterable. Every run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

No place is safe.

---

## 2. Pillars

1. **Authored skeleton, procedural flesh.** Landmarks, roads, and POIs are hand-placed. Buildings and props fill the authored skeleton procedurally. Procedural interiors provide replayability; the exterior shell is fixed. 🧪 *(under testing — see §6.6)*
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist.
4. **Biome identity.** Each of the 10 biomes has loot focus, difficulty, vibe, weather.
5. **Travel as exploration.** Sarran River blocks. Forest hides. Bridges force chokepoints.
6. **All three combat modes.** Stealth, guns, melee. Shooting is the addictive hook (Valorant-feel).
7. **Civic, not sacred.** No religious buildings. Faith lives in the people.
8. **Runs on millions of PCs.** Low preset baseline: 2GB VRAM / 4GB RAM / 1080p / 60 FPS.
9. **Furniture is interactive + modular.** Static fixtures merge for performance. Dynamic furniture is separate RigidBody3D. Kitchen counter is split into modular pieces (sink, stove, empty, wall cabinet) for flexible layout — PZ-style.

---

## 3. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Not pixel art. Not gritty realism.

**Tier 1 lookbook:** 18 approved assets. Contact sheet at `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-005_modular_kitchen_contact_sheet.png`

### Comic-book / outline post-processing 🔓

**Recommended:** inverted hull outline (~1 day, *Wind Waker* look). Implement when we lock the palette.

### Texture workflow 🔓 PAUSED

`mogen textures` requires paid Gemini API key (free tier = 0 image quota). **Paused for alpha** — flat-color materials are acceptable.

### Vehicles + blood decals + grass tufts = EXTERNAL ASSETS 🔒

Cars (sedan, pickup_truck), blood splatter decals, and grass tufts are **retired from MoGen production**. External assets are better quality for these.

---

## 4. Camera — FIRST-PERSON 🔒

- Player eye height: 1.65 m
- Standard door: 0.90 m wide × 2.10 m tall
- Standard ceiling: 2.40 m

---

## 5. Characters — DSL HUMANOID FOR ALPHA 🔒

DSL-authored humanoid via `humanoid.mog`. Blocky, Roblox-adjacent, accepted for alpha. Hybrid (external base + MoGen clothing) for v1.

**Lore justification:** player is one of "The Immune" — body rejected the Living Troop liquid.

---

## 6. World structure — FIXED MAP + PROCEDURAL INTERIORS 🔒

### 6.1 Map dimensions 🔒

**4.0 km × 3.0 km = 12 km²** (~40% of GTA San Andreas). Grid: 8 × 6 cells of 500m × 500m.

### 6.2 Map geography 🔒

Sarran River flows from northern Forest through Farmland into Sarran Bay (west). River splits city east/west.

**West Side:** Suburbia, Parks & Greenways, Commercial Strip, Farmland, Forest
**East Side:** Industrial Park, River & Wetlands, Downtown, Military Zone
**Underground:** Subway

### 6.3 The 10 Biomes 🔒

| # | Biome | Difficulty | Zombies | Base |
|---|---|---|---|---|
| 1 | Suburbia | Low | Low–Med | **High** |
| 2 | Parks & Greenways | Low | Low | Low–Med |
| 3 | Forest | Medium | Low | Med–High |
| 4 | Farmland | Low–Med | Low | **High** |
| 5 | Commercial Strip | Med–High | Med–High | Medium |
| 6 | Industrial Park | Medium | Medium | **High** |
| 7 | River & Wetlands | Medium | Low–Med | Low–Med |
| 8 | Subway | Med–High | Med–High | Low–Med |
| 9 | Downtown | High–V.High | Very High | **Low** |
| 10 | Military Zone | Extreme | Extreme | None |

### 6.4 Alpha build order 🔒

Suburbia → Parks → Farmland → Forest → Commercial → Industrial → River/Wetlands → Subway → Downtown → Military Zone.

### 6.5 Persistent map + per-run reset 🔒

- **Persistent:** map layout, story keys, lore fragments, base upgrades, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor.

### 6.6 Procedural interiors 🧪

> **Status: under testing.** The hybrid split below is the design intent. Current code (`chunk_builder.gd` + `chunk_streamer.gd`) places buildings PROCEDURALLY per-chunk at runtime — exterior shells are NOT yet hand-authored. POI/landmark system is not yet implemented. Interior lazy-spawn (`interior_builder.gd`) is stubbed but not gameplay-tested.

- **Fixed (when fully implemented):** building exterior shell, room layout, doors, windows, static furniture (kitchen counters, sinks, built-ins).
- **Procedural:** dynamic furniture placement, loot containers, prop scatter, zombie patrol routes.
- **Modular kitchen:** kitchen is assembled from 4 modular pieces (sink_unit, stove_unit, empty_counter, wall_cabinet) placed side-by-side. Layout is procedural — different kitchens have different arrangements.
- **Current implementation gap:** exterior shell placement is procedural, not hand-authored. This is acceptable for alpha (chunks look varied enough) but breaks Pillar 1's intent. Fix requires implementing POI/landmark overlay system (§6.8 below).

### 6.7 Civic landmarks 🔒

12 civic landmarks (no religious): Lighthouse, Water Tower, Grain Silo, Hospital, Police HQ, Government Palace, Stadium, Old Royal Palace, Naval Fort, Broadcast Tower, Railway Station, Grand Bazaar.

**Models built:** all 12 exist as MoGen assets. **Placement:** NOT yet wired — `city_config.gd` has a `landmarks` field per biome, but `chunk_streamer.gd` does not yet read it. Landmarks will not spawn in-game until streamer is patched (see §11 TODO list).

### 6.8 POI / landmark overlay system 🧪

> **Status: under design.** Recommended by architectural review (DeepSeek, 2026-09-12). Not yet implemented.

**Goal:** every biome has 1+ landmark visible from 500–800m (GTA SA memorability). POIs are hand-placed in a JSON file (`res://data/pois.json`),” and `chunk_builder` checks: "is there a POI in my bounds?" If yes, place it exactly and suppress procedural placement in its radius.

```json
// res://data/pois.json (example)
[
  {"id":"hospital_main", "type":"hospital", "pos":[1200,0,800], "radius":40, "biome":9},
  {"id":"fort_sarran",   "type":"fort_sarran", "pos":[3500,0,2500], "radius":60, "biome":10},
  {"id":"gov_palace",   "type":"government_palace", "pos":[3000,0,1500], "radius":50, "biome":9}
]
```

**Implementation status:** assets exist, JSON format proposed, builder integration NOT done. Tracked in §11 TODO list.

---

## 7. Gameplay systems

### 7.1 Survival needs 🔓

Likely subset of PZ's: hunger, thirst, fatigue, panic, sickness, infection.

### 7.2 Combat — STEALTH + GUNS + MELEE 🔒

**Shooting:** Valorant-feel — tight, low-TTK, learnable recoil, headshot-focused.
**Stealth:** crouch silent, backstab instakill, LOS breaks.
**Melee:** stab silent / blunt 5m / heavy 10m. Door-defense meta.

### 7.3 Hearing-based zombie AI 🔒

3D sound propagation. Zombies investigate gunshots (50m+), footsteps (5-20m), alarms, generators (30m), broken glass (15m).

### 7.4 Zombies 🔒

Walker (slow, sight + hearing), Crawlers (legs destroyed), Groups (noise pulls, no coordination), Memory ~10 sec.

### 7.5 Death penalty + meta-progression 🔒

**Story mode:** keep weapons, lose consumables. **Sandbox:** lose everything, find old body.

| Upgrade | Per-level | Max |
|---|---|---|
| Movement Speed | +5% | 5 |
| Max Health | +10 HP | 5 |
| Carrying Capacity | +2 slots | 5 |
| Flashlight Battery | +15% duration | 5 |
| Stamina / Noise Reduction | -10% noise | 5 |

### 7.6 Radio Rumor system 🔒

4 stations: Voice of Mazar, Radio Junta, Free Bay FM, The Border Signal.

### 7.7 Factions — SEMI-LOCKED 🔓

5 factions: Mazar Republic, Junta Remnants, Border Enemy, Survivors, The Immune.

### 7.8 Lore fragments 🔒

Reveal: Operation Living Troop, Border Enemy, junta cover-up, King Amir's fate, immune identity, Fort Sarran, secret Subway routes.

### 7.9 Base / safehouse hub 🔒

Apartment → Base. **No place is safe.**

### 7.10 Dynamic spawns + permanent kills 🔒

Killed zombies stay dead (alpha).

### 7.11 Co-op 🔓

Alpha: technical possibility only. Future: revive + hold-the-gate.

---

## 8. Loot tables 🔒

Per-district fixed table. Within: Common 60%, Uncommon 30%, Rare 10%. All 10 biome tables locked in v5.

---

## 9. 3D-specific systems 🔓

FOV (likely 90°), LOS checks, sound propagation grid, occlusion.

---

## 10. Asset production pipeline 🔒

**Contract:** `/home/z/my-project/asset-pipeline/README.md`
**Worklog:** `/home/z/my-project/asset-pipeline/worklog/worklog.md`
**Poly budget:** `/home/z/my-project/download/poly_budget_v3_path_b.md`
**Furniture decision:** `/home/z/my-project/download/furniture_merging_decision.md`
**Backups:** `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` (1.5MB) + `mazar_design_backup_2026-09-11.zip` (3.6MB)

### 10.1 Engine budgets — LOCKED (Path B) 🔒

| Metric | Low (alpha default) | High | Ultra (v1) |
|---|---|---|---|
| Resolution | 1080p (720p int. on iGPU) | 1080p | 1440p |
| Renderer | Compatibility (OpenGL 3.3) | Compat / Forward+ | Forward+ |
| Draw calls | 600 max | 1500 max | 2500 max |
| On-screen tris | 500k max | 1.5M max | 3M max |
| Texture memory | 800 MB | 2 GB | 4 GB |
| View distance | 100m | 200m | 300m+ |
| Shadows | sun only (1024² hard) | sun + 4 spot | sun + 8 |
| Zombies max | 30 | 60 | 100 |
| Chunks | 3×3 active + 5×5 warm | 5×5 + 7×7 | 7×7 + 9×9 |

### 10.2 Per-asset budgets (Low preset LOD0) 🔒

See `poly_budget_v3_path_b.md §3.2` for full table.

### 10.3 Furniture merging — LOCKED 🔒

**Static furniture** (kitchen counters, sinks, toilets, built-ins) = merged into room mesh OR modular separate pieces. 0-1 draw calls.

**Dynamic furniture** (chairs, tables, beds, fridges, lamps, bookshelves) = separate meshes + RigidBody3D.

**Cap:** 10 dynamic props per room on Low preset. 15 on High. 25 on Ultra.

**Modular kitchen:** 4 separate pieces (sink_unit, stove_unit, empty_counter, wall_cabinet). Each is its own static mesh. Placed side-by-side in Godot to form any kitchen layout. Procedural interior generator picks the arrangement.

See `/home/z/my-project/download/furniture_merging_decision.md` for full details.

### 10.4 Tiered review strategy 🔒

Tier 1 (~10 anchors, individual), Tier 2 (~80 variant packs, contact sheets), Tier 3 (~900 mass production, auto-validated), Tier 4 (~10 biome milestones). Total user review: ~3 hours.

### 10.5 Communication protocol 🔒

`APPROVE ALL` / `APPROVE EXCEPT <ids>` / `REGEN <ids> WITH <note>` / `REJECT BATCH — <reason>`

### 10.6 Tier 1 production — 18 APPROVED + 5 RETIRED ✅

| # | Asset | Category | Tris | Type | Status |
|---|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | static shell | ✅ approved |
| 2 | office_chair | props | 6,500 | dynamic | ✅ approved |
| 3 | dining_table | props | 460 | dynamic | ✅ approved |
| 4 | oak_tree | foliage | 2,400 | hero tree | ✅ approved |
| 5 | bush | foliage | 360 | bush | ✅ approved |
| 6 | sedan | vehicles | — | — | ❌ RETIRED (external) |
| 7 | pickup_truck | vehicles | — | — | ❌ RETIRED (external) |
| 8 | blood_splatter_decal | decals | — | — | ❌ RETIRED (external) |
| 9 | asphalt_road_segment | environment | 96 | road | ✅ approved |
| 10 | two_story_colonial | buildings | 2,600 | static shell | ✅ approved (3 windows top = 3 rooms) |
| 11 | bungalow | buildings | 2,000 | static shell | ✅ approved |
| 12 | bookshelf | props | 264 | dynamic | ✅ approved |
| 13 | bed_single | props | 1,600 | dynamic | ✅ approved (minor disconnect, accepted) |
| 14 | kitchen_counter | props | — | — | ❌ RETIRED (split into 4 modular pieces) |
| 15 | refrigerator | props | 412 | dynamic + loot | ✅ approved |
| 16 | pine_tree | foliage | 256 | standard tree | ✅ approved |
| 17 | grass_tuft | foliage | — | — | ❌ RETIRED (external) |
| 18 | picket_fence | environment | 168 | fence | ✅ approved |
| 19 | street_light | environment | 504 | light source | ✅ approved |
| 20 | kitchen_sink_unit | props | 172 | static modular | ✅ NEW (modular kitchen #1) |
| 21 | kitchen_stove_unit | props | 416 | static modular | ✅ NEW (modular kitchen #2) |
| 22 | kitchen_empty_counter | props | 120 | static modular | ✅ NEW (modular kitchen #3) |
| 23 | kitchen_wall_cabinet | props | 60 | static modular | ✅ NEW (modular kitchen #4) |
| — | fence.mog (upstream) | environment | 318 | fence | ✅ approved |

**Total: 18 active + 1 upstream = 19 approved. 5 retired.**

**Contact sheet:** `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-005_modular_kitchen_contact_sheet.png`

### 10.7 Two-story colonial window layout — LOCKED 🔒

3 windows on the upper front floor = 3 rooms upstairs. Classic colonial layout:
- Left window = master bedroom
- Center window = bathroom
- Right window = second bedroom

This matches real colonial house architecture and gives the house proper room count for gameplay (2 bedrooms + 1 bathroom upstairs, living room + kitchen + dining room downstairs).

### 10.8 Known issues queue 🔒

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream) | Doors flush with wall | Author v2 with `wall` holes | ✅ FIXED |
| 2 | humanoid.mog (DSL test) | Reads "Roblox/blocky" | Accept for alpha; hybrid for v1 | Accepted |
| 3 | oak_tree.mog (v1) | Bare twigs from `branch` primitive | Replace with `cylinder` trunk | ✅ FIXED |
| 4 | sedan + pickup_truck | Wrong dimensions, wrong wheel angle | Retire — external assets | ✅ RETIRED |
| 5 | blood_splatter_decal | Just a red square | Retire — external assets | ✅ RETIRED |
| 6 | texture workflow | Gemini free tier = 0 image quota | Need paid key | 🔓 PAUSED |
| 7 | grass_tuft | Low quality | Retire — external assets | ✅ RETIRED |
| 8 | house side windows | Windows on rotated walls not aligned | Add `rot=[0, 90, 0]` to side window groups | ✅ FIXED |
| 9 | bookshelf showing back | Back panel at +Z, camera at +Z | Flip: back at -Z, books at +Z | ✅ FIXED |
| 10 | bed sheets disconnected | `tags="floating"` made them physically disconnected | Remove `tags`, overlap with mattress | ✅ FIXED (user accepted minor residual) |
| 11 | refrigerator middle upside down | Divider/handles area looked wrong | Simplify: remove divider + handles + magnets | ✅ FIXED |
| 12 | kitchen counter reversed | L-turn going wrong direction | Split into 4 modular pieces (PZ-style) | ✅ FIXED (split into modules) |

---

## 11. Lore — SEMI-LOCKED for alpha 🔓

**Full lore:** `/home/z/my-project/download/lore_mazar_v1.2.md`

**Locked:** overall structure (city/river/biomes/Operation Living Troop/Immune player).
**Can change:** street names, faction names, character names, radio station names, lore fragment texts.

---

## 12. Open questions for v9 🔓

1. Survival needs list (subset of PZ's)
2. Combat focus balance (ratios of stealth/guns/melee encounters)
3. Loot richness multipliers per biome
4. Visual palette per biome (locked color swatches)
5. FOV angle (likely 90°, lock it)
6. Number of buildings / POIs per biome
7. Day-1 sim feasibility
8. Co-op technical architecture
9. Sandbox vs story mode launch order
10. Texture API key resolution
11. External vehicle + blood decal + grass asset sources
12. Tier 2 production start — variant packs

---

## 13. Milestones 🔒

| # | Milestone | Exit criteria | Status |
|---|---|---|---|
| 0 | Pre-production | All v9 open questions answered | ⏳ in progress |
| 1 | Vertical slice — Suburbia | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night | Next |
| 2 | Alpha — full map | All 10 biomes present, all systems functional | — |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated | — |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings | — |
| 5 | Co-op technical pass | Online architecture validated | — |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader | — |

---

## Appendix A — MoGen lessons learned (cumulative, 10 sessions)

- MoGen compiles fast. suburban_house_v2 (1.8k tris): 12 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` broken — replaced with Chrome + three.js + swiftshader.
- `mogen textures` requires **paid Gemini API key** (free tier = 0 image quota).
- DSL is structural, not artistic. Excellent at buildings/props. Bad at organic characters + vehicles + grass.
- **The DSL reference is compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).**
- **The `wall` primitive** with `holes=[cx, cy, w, h]` is the right tool for walls with door/window cutouts.
- **The `solid` group** with `cleanup="coplanar"` merges same-material primitives. Use for building/vehicle shells.
- **Floating cluster errors (`E1101`)** — fix by overlapping meshes in ALL 3 axes (X, Y, Z). OR use `tags="floating"` for intentionally disconnected decorative elements.
- **`slab` uses `anchor=bottom`** by default. When placing a foundation on a lawn, set pos y to overlap.
- **`icosphere` uses `subdivisions=`** not `detail=`. 1=low-poly, 2=default.
- **`branch` primitive** is hard to control. Use plain cylinders for stylized trees.
- **`plane` uses `size=[x, _, z]`** (XZ-aligned). `quad` uses `w=` and `h=` (XY-aligned).
- **`cone` primitive** with `sides=8` is good for stylized conifer foliage.
- **Camera yaw convention:** yaw=0 = +Z face (back). yaw=180 = -Z face (front with door).
- **`alpha_mode="blend"`** for transparency. `alpha_mode="mask"` + `alpha_cutoff=0.5` for 1-bit cutout.
- **Wrap complex bodies in `solid (cleanup="coplanar")`** to merge same-material parts.
- **`tags="floating"`** is the escape hatch for intentionally disconnected parts.
- **`light` node** embedded in .mog — exported as glTF KHR_lights_punctual, Godot reads as Light3D.
- **Vehicles + blood decals + grass are better as external assets.** DSL can't do correct proportions, wheel angles, or fine organic detail.
- **Static vs dynamic furniture split** is the key architecture decision. See `furniture_merging_decision.md`.
- **CRITICAL: window groups on rotated walls must also be rotated.** Wall `rot=[0, 90, 0]` → window group also `rot=[0, 90, 0]`.
- **Bookshelf orientation:** open side (with books) faces +Z (default camera direction). Back panel at -Z.
- **Bedding overlap:** sheets/blanket/pillow must overlap with mattress by 0.02-0.03m in Y. Don't use `tags="floating"` for bedding.
- **Refrigerator simplification:** when in doubt, remove decorative details. Less is more for stylized low-poly.
- **Modular kitchen pattern (PZ-style):** split complex multi-part furniture into separate modular pieces. Each piece is its own .mog file. Place side-by-side in Godot to form any layout. More flexible than fixed L-shape or unified asset. 4 pieces: sink_unit, stove_unit, empty_counter, wall_cabinet. Each ~60-400 tris. Total modular kitchen = ~770 tris (vs 580 for unified — slightly more, but 4× the layout flexibility).
- **Two-story colonial window count = 3 upstairs = 3 rooms.** Classic colonial layout: master bedroom (left), bathroom (center), second bedroom (right). Downstairs: living room + kitchen + dining room.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v8.md` | **this document** |
| `/home/z/my-project/download/lore_mazar_v1.2.md` | **the semi-locked lore document** |
| `/home/z/my-project/download/poly_budget_v3_path_b.md` | **the locked Path B budget** |
| `/home/z/my-project/download/furniture_merging_decision.md` | **the locked furniture decision** |
| `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-005_modular_kitchen_contact_sheet.png` | **Tier 1 batch 005 — modular kitchen contact sheet** |
| `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` | **alpha backup (1.5MB)** |
| `/home/z/my-project/download/mazar_design_backup_2026-09-11.zip` | **design backup (3.6MB)** |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog |

---

## §11 — Architecture TODO list 🧪

> Tracked issues from architectural review (DeepSeek, 2026-09-12). Each item has severity, status, and proposed fix. Work these in priority order before scaling content.

### 🔴 Critical (gameplay-affecting)

| # | Issue | Status | Fix | Est |
|---|---|---|---|---|
| 11.1 | **River = 25% of map** (12/48 grid cells). Player walks 3km² of water. Should be 5–10% + Coastal Beach biome. | 🧪 open | Reduce RI to 1 column (6 cells = 12.5%) + add COASTAL_BEACH biome enum value for the freed column. | 1h |
| 11.2 | **`chunk_streamer.gd` duplicates `chunk_builder.gd` placement logic.** Streamer rebuilds chunks at runtime instead of loading prebuilt `.tscn` files. ~730 stale `.tscn` chunks unused. | 🧪 open | Refactor streamer to be a thin loader (see DeepSeek's snippet). Move all placement into `chunk_builder.gd` as the single source of truth. Run `city_builder.gd` once to regenerate `.tscn` files. | 2–4h |
| 11.3 | **First-frame hitch.** `stream_radius=2` → 25 chunks generated synchronously on first frame. Multi-second stall. | 🧪 open | Add frame budget: max 1 chunk build per frame, queue the rest. Or pre-build on background thread. | 1–2h |
| 11.4 | **River guard missing in streamer.** If `Biome.RIVER` profile has any `fill > 0` or non-empty buildings list, it will spawn buildings in water. | 🔒 fixed | Verified `city_config.gd` River has `fill=0.15` and 4 water-appropriate buildings (fishing_hut, pier_dock, houseboat, marsh_pier). NOT a bug given current profile. Re-check after any River profile edit. | — |

### 🟠 Performance (blocks scaling)

| # | Issue | Status | Fix | Est |
|---|---|---|---|---|
| 11.5 | **`_face_nearest_road` is O(n²).** 200 segments × 100 buildings × 730 chunks = 14.6M ops per build. | 🧪 open | Add spatial grid to `RoadNetwork`: `Vector2i → Array[segment]`. `nearest_road_to(pos, radius)` becomes O(1). | 1h |
| 11.6 | **MultiMesh batching not implemented.** Each tree = 1 draw call. 200 trees × 49 loaded chunks = 9,800 draw calls for foliage alone. | 🧪 open | Group `MeshInstance3D` by mesh, replace with `MultiMeshInstance3D` per asset per chunk. 80–90% draw call reduction. (Snippet in DeepSeek review.) | 2h |
| 11.7 | **Navigation baking missing.** Zombies need NavMesh. Retrofit after 30km² is miserable. | 🧪 open | Add `NavigationRegion3D` per chunk in `chunk_builder.gd`. Bake trivial navmesh now; refine later. | 2–4h |
| 11.8 | **`SpatialIndex` uses circles not AABB.** Buildings are 8×12m rectangles but stored as center+radius. Causes overlap or wasted space. | 🧪 open | Add `insert_box(center, size, rot_y)` that converts oriented box to world AABB. | 1–2h |
| 11.9 | **`CityMeta._hash_builders()` re-reads files every build.** Minor — only matters if rebuilding in a loop. | 🧪 backlog | Cache hash in `user://city_meta_cache.json`, recompute only if `mtime` changed. | 30m |

### 🟡 Architectural (philosophical / design)

| # | Issue | Status | Fix | Est |
|---|---|---|---|---|
| 11.10 | **Pillar 1 contradiction.** GDD says "hand-authored world" but code is fully procedural. | 🧪 design | Pillar 1 wording updated (see §2). Real fix: implement §6.8 POI overlay system. | — |
| 11.11 | **POI / landmark system not implemented.** `city_config.gd` has `landmarks` field per biome but streamer doesn't read it. 8 hero landmarks (fort_sarran, government_palace, etc.) won't spawn. | 🧪 open | Add `pois.json`. Patch `chunk_builder.gd` to query POIs in chunk bounds, place 1 per POI exactly, suppress procedural in POI radius. | 4–6h |
| 11.12 | **Zone palette per biome missing.** No biome-specific ground/fog/sun tinting. All biomes look the same atmospherically. | 🧪 backlog | Add `palette` field per biome in `city_config.gd`. Apply in `environment_setup.gd`. | 2h |
| 11.13 | **Duplicate `city_builder.gd` removed.** Old 579-line v3 prototype was sitting in `godot_project/scripts/` alongside the proper `tools/city_builder.gd`. | 🔒 fixed | Deleted in this commit. | — |
| 11.14 | **`is_road_clear()` inverted naming.** Every caller wrote `not spatial.is_road_clear(pos)`. Confusing. | 🔒 fixed | Renamed to `is_on_road()`. All callers updated. Old name kept as deprecated alias. | — |
| 11.15 | **`bridges()` off-by-one.** `row=6` doesn't exist (`GRID_ROWS=6` means rows 0..5). Silent failure. | 🔒 fixed | Changed to `row=5`. | — |

### Status legend
- 🔒 = decided / fixed (don't touch unless requirements change)
- 🧪 = under testing / under design / open (work needed)
- 📋 = backlog (deferred until after alpha vertical slice)

---

## §12 — Terrain Architecture 🧪

> **Status: design locked, implementation in phases A–G (see §11.16–11.22 below).**
> Captured 2026-09-12 after DeepSeek review of original terrain plan.

### Core principle: Terrain3D owns terrain, ChunkStreamer owns everything else

Two layers, cleanly separated:

| Layer | Owner | What it does |
|---|---|---|
| **Terrain mesh + collision** | `Terrain3D` plugin | Renders the visible terrain with LOD. Handles heightmap collision via `HeightMapShape3D`. Texture splatting for grass/dirt/rock per biome. We do NOT write custom LOD — Terrain3D gives us 300m+ view distance without 3.75M tris. |
| **Deterministic height function** | `tools/terrain_height.gd` (custom) | Pure function `height_at(x, z) → float`. Used by gameplay code (building placement, AI path queries, POI placement, bridge pier depth). No dependency on Terrain3D at runtime — only the build step writes to Terrain3D's heightmap. |
| **Build step** | `tools/terrain_baker.gd` (one-shot) | Reads `terrain_height.gd`, writes to Terrain3D's heightmap asset. Run once at design time, re-run when height function changes (bump `TERRAIN_HEIGHT_VERSION`). |
| **Everything else** | `ChunkStreamer` + `chunk_builder.gd` | Buildings, props, foliage, streetlights, roads, water surface (separate from terrain), POIs. All sample `terrain_height.height_at()` for their Y position. |

### TERRAIN_HEIGHT_VERSION constant

```gdscript
# tools/terrain_height.gd
const TERRAIN_HEIGHT_VERSION := 1   # BUMP THIS when height function changes
```

When `TERRAIN_HEIGHT_VERSION` is bumped:
1. `tools/terrain_baker.gd` re-runs (writes new heightmap to Terrain3D asset)
2. `CityMeta` includes the version in its hash → `skip_if_valid` correctly invalidates cached chunks
3. All `.tscn` chunk files regenerate on next `city_builder.gd` run
4. Player spawn Y auto-recalculates from `terrain_height.height_at(spawn_x, spawn_z) + 2.0`

**Current version: 1** (initial — function not yet written, but the version tracking is in place)

### Subway-as-layer, not biome

**Decision (2026-09-12):** `Biome.SUBWAY` removed from the enum. Subway is a parallel underground layer, not a surface biome.

Rationale:
- A subway tunnel can run under any surface biome (Downtown station under Downtown, Industrial depot under Industrial, etc.). Treating subway as a surface biome forced every subway cell to also be surface-only.
- Surface cells where station entrances sit keep their surface biome (Downtown, Industrial, etc.). The entrance is a POI on the surface.
- Tunnels are a `SubwayNetwork` class (like `RoadNetwork` but for tunnels at Y ≈ -8m). Stations are nodes in this network; tunnels connect them.
- Player descends via station stairs → loads subway tunnel chunk. Same lazy-interior pattern as buildings — only loads when player enters.

Implementation status: `Biome.SUBWAY` value removed from `city_config.gd` enum. `tools/subway_network.gd` is a stub. Subway assets (subway_platform, subway_tunnel, subway_train_car, ticket_booth, turnstile, maintenance_tunnel_junction, emergency_exit_stairs, subway_pipe_cluster) are still in the manifest but won't be placed by surface chunk_builder — they'll be placed by `subway_builder.gd` when the player enters a station.

### Per-biome elevation signatures

| Biome | Base Y | Amplitude | Frequency | Result |
|---|---:|---:|---:|---|
| SUBURBIA | +0.5 | 1.0m | 0.008 | gentle rolling — suburban feel |
| PARKS | +1.0 | 2.0m | 0.012 | parkland hills |
| FOREST | +2.0 | 5.0m | 0.018 | rolling hills — fog collects in valleys |
| FARMLAND | +0.2 | 0.3m | 0.005 | flat — tractors need level ground |
| COMMERCIAL | +0.5 | 0.5m | 0.005 | nearly flat — urban grid |
| INDUSTRIAL | +0.5 | 0.5m | 0.005 | flat |
| RIVER | -4.0 | 0.0 | — | carved valley — water at Y=0, riverbed at -4m |
| DOWNTOWN | +0.5 | 0.5m | 0.005 | flat (urban) but raised above river for visibility |
| MILITARY | +3.0 | 0.0 | — | plateau — fort sits on a bluff |
| COASTAL_BEACH | -1.0 | 8.0m | 0.020 | rolling cliff coastline — lighthouse territory |
| WATER | -2.0 | 0.0 | — | ocean/lake (sea level) |

---

## §11.16–11.22 — Terrain phases (new) 🧪

Appended to §11 TODO list. Each phase has validation step (FPS must not drop >20% from baseline).

### Phase A — Prep (4–5h)
| # | Task | Status |
|---|---|---|
| A.1 | Refactor `chunk_streamer.gd` to thin loader (drop inline placement, use `ResourceLoader.load_threaded_request` on prebuilt `.tscn` chunks). Move all placement logic into `chunk_builder.gd` as single source of truth. | 📋 **deferred to Phase B** — see note below |
| A.2 | River=25% redesign: reduce RI from 2 columns to 1 column (6 cells = 12.5%). Add `COASTAL_BEACH` biome enum value for the freed column. | 🔒 done (2026-09-12) |
| A.3 | Remove `Biome.SUBWAY` from enum. Create `tools/subway_network.gd` stub. Move subway_* assets to a `subway/` subfolder in manifest. | 🔒 done (2026-09-12) — manifest subfolder move deferred (assets stay in current location, just not placed by surface builder) |
| A.4 | Re-run `city_builder.gd` to regenerate `.tscn` chunks with new biome layout. | 📋 **deferred to Phase B** — see note below |
| A.5 | Validation: re-run baseline capture. FPS must be ≥ 116 headless (80% of 145). If <116, stop and diagnose. | 🔒 done (2026-09-12) — **145 FPS, 0% drop, PASS** |

**Why A.1 + A.4 are deferred to Phase B:**
The current `chunk_streamer.gd` (v4) has dense inline placement logic (target=fill×30 to fill×60, props 25-50, foliage 15-50). The older `chunk_builder.gd` (used by `city_builder.gd` for prebuilt .tscn chunks) has simpler placement that would produce a sparser world. Porting v4 logic into `chunk_builder.gd` is 2-4h of work.

Phase B (terrain core) will require ALL placement code to sample `terrain_height.height_at(x, z)` for Y position. Doing the refactor twice (once now for A.1, again in B.1 for terrain) is wasteful. Better to do both in one pass during Phase B: refactor `chunk_streamer.gd` to thin loader + port v4 logic to `chunk_builder.gd` + add terrain_height sampling, all together.

Phase A validation passed: FPS unchanged at 145 (0% drop), no errors, Coastal Beach biome spawning correctly, River reduced from 15 chunks to 10 in spawn area.

### Phase B — Terrain core (4–5h)
| # | Task | Status |
|---|---|---|
| B.1 | `tools/terrain_height.gd` — `class_name TerrainHeight`. Pure function `height_at(x, z) → float`. Uses Godot's `FastNoiseLite` seeded by `map_seed`. Composes biome elevation + river carve + bridge flatten. Includes `TERRAIN_HEIGHT_VERSION = 1` constant. | 🧪 pending |
| B.2 | Debug visualization — heightmap-colored plane (`MeshInstance3D` with vertex-colored quad grid) so we can SEE the height function before Terrain3D lands. 30min. | 🧪 pending |
| B.3 | `tools/river_network.gd` — generates river centerline (spline through bridge endpoints from `city_config.gd::bridges()`). Exposes `nearest_point(x, z) → {distance, depth, on_line}` and `water_depth_at(x, z) → float`. | 🧪 pending |
| B.4 | Road flattening — `terrain_height.flatten_road_corridor(x, z) → y` so roads don't clip through hills or float over valleys. Cut-and-fill like real cities. | 🧪 pending |
| B.5 | Bridge ramp logic — bridge deck at surrounding terrain Y, piers extend down to riverbed Y, road ramps 30m on either end to bridge deck height. | 🧪 pending |
| B.6 | Validation: re-run baseline. FPS ≥ 116 headless. Buildings should sit at varied Y (no longer all at Y=0). | 🧪 pending |

### Phase C — Terrain mesh (4–6h)
| # | Task | Status |
|---|---|---|
| C.1 | Install Terrain3D plugin (https://github.com/outobugi/Terrain3D). Add to `project.godot` plugins list. | 🧪 pending |
| C.2 | `tools/terrain_baker.gd` — one-shot script that samples `terrain_height.height_at()` on a 4m grid and writes to Terrain3D's heightmap asset. | 🧪 pending |
| C.3 | Splatmap per biome — paint grass/dirt/rock/sand textures based on biome + slope. | 🧪 pending |
| C.4 | Delete flat `Ground` node from `main.tscn`. Replace with Terrain3D node. | 🧪 pending |
| C.5 | Player spawn Y auto-calc: `player.y = terrain_height.height_at(player.x, player.z) + 2.0`. | 🧪 pending |
| C.6 | Validation: re-run baseline. FPS ≥ 116 headless. Player should walk up/down hills. | 🧪 pending |

### Phase D — Water + bridge (2–3h)
| # | Task | Status |
|---|---|---|
| D.1 | Water surface — translucent plane at Y=0 over carved areas. Animated normal map. | 🧪 pending |
| D.2 | `water_depth_at(x, z) → float` query — returns 0 on land, >0 over river/ocean. Used for swim state, fish loot, boat traversal (deferred). | 🧪 pending |
| D.3 | Bridge POI placement — `bridge_section.glb` placed at bridge endpoints in `pois.json`. Pier depth from `terrain_height.height_at()` at pier base. | 🧪 pending |
| D.4 | Validation: re-run baseline. FPS ≥ 116 headless. Bridges should go over real water. | 🧪 pending |

### Phase E — NavMesh (2–4h)
| # | Task | Status |
|---|---|---|
| E.1 | Add `NavigationRegion3D` per chunk in `chunk_builder.gd`. Bake trivial navmesh against terrain + buildings. | 🧪 pending |
| E.2 | `NavigationServer3D` query for zombie AI. | 🧪 pending |
| E.3 | Validation: re-run baseline. FPS ≥ 116 headless. Zombies can path up hills, around valleys, across bridges. | 🧪 pending |

### Phase F — POI system (4–6h)
| # | Task | Status |
|---|---|---|
| F.1 | `res://data/pois.json` — hand-placed POIs (hospital, fort_sarran, government_palace, lighthouse, water_tower, stadium, old_royal_palace, bridges, gas_stations, schools, churches, water_towers, etc.). 60–80 POIs total. | 🧪 pending |
| F.2 | `chunk_builder.gd` queries POIs in chunk bounds. Places 1 per POI exactly. Suppresses procedural placement in POI radius. | 🧪 pending |
| F.3 | Landmark visibility check — raycast from 1km away, verify not occluded by terrain. Adjust POI Y if needed. | 🧪 pending |
| F.4 | Validation: re-run baseline. FPS ≥ 116 headless. Landmarks visible from 500m+. | 🧪 pending |

### Phase G — Independent perf (4–5h, parallel-safe)
| # | Task | Status |
|---|---|---|
| G.1 | `RoadNetwork` spatial grid — `Vector2i → Array[segment]`. `nearest_road_to(pos, radius)` becomes O(1). Removes 14.6M ops from `_face_nearest_road`. | 🧪 pending |
| G.2 | MultiMesh batching per chunk — group `MeshInstance3D` by mesh, replace with `MultiMeshInstance3D`. 80–90% draw call reduction for foliage. | 🧪 pending |
| G.3 | `SpatialIndex.insert_box(center, size, rot_y)` — AABB instead of circle. Buildings stop clipping into each other. | 🧪 pending |
| G.4 | Validation: re-run baseline. FPS ≥ 116 headless. Draw calls should drop 50%+ from G.2. | 🧪 pending |
