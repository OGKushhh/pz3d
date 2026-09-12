# Game Design Document — Mazar Alpha

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v6 — pre-production → vertical slice. Lore semi-locked. Path B locked. **Tier 1 production EXPANDED — 16 approved style anchors. Cars + blood splatter retired (external assets).**
> **Working title:** *Mazar*
> **Lore:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, **semi-locked for alpha**)
> **Poly budget:** `/home/z/my-project/download/poly_budget_v3_path_b.md` (v3, **locked — two-tier Low/High presets**)
> **Furniture decision:** `/home/z/my-project/download/furniture_merging_decision.md` (**locked — static vs dynamic split**)
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

1. **Hand-authored world.** Every building has a reason. Procedural interiors provide replayability; the exterior shell is fixed.
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist.
4. **Biome identity.** Each of the 10 biomes has loot focus, difficulty, vibe, weather.
5. **Travel as exploration.** Sarran River blocks. Forest hides. Bridges force chokepoints.
6. **All three combat modes.** Stealth, guns, melee. Shooting is the addictive hook (Valorant-feel).
7. **Civic, not sacred.** No religious buildings. Faith lives in the people.
8. **Runs on millions of PCs.** Low preset baseline: 2GB VRAM / 4GB RAM / 1080p / 60 FPS.
9. **Furniture is interactive.** Static fixtures merge for performance. Dynamic furniture is separate RigidBody3D — can be pushed, thrown, scrapped, used as barricade.

---

## 3. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Not pixel art. Not gritty realism.

**Tier 1 lookbook:** 16 approved assets. Contact sheet at `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-003_all_16_contact_sheet.png`

### Comic-book / outline post-processing 🔓

**Recommended:** inverted hull outline (~1 day, *Wind Waker* look). Implement when we lock the palette.

### Texture workflow 🔓 PAUSED

`mogen textures` requires paid Gemini API key (free tier = 0 image quota). **Paused for alpha** — flat-color materials are acceptable. Textures become v1 polish step.

### Vehicles + blood decals = EXTERNAL ASSETS 🔒

Cars (sedan, pickup_truck) and blood splatter decals are **retired from MoGen production**. User decided to rely on external assets for vehicles and blood decals — better quality, correct dimensions, proper wheel angles. Retired files preserved in `assets/{vehicles,decals}/retired/` for history.

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

### 6.6 Procedural interiors 🔒

- **Fixed:** building exterior shell, room layout, doors, windows, static furniture (kitchen counters, sinks, built-ins).
- **Procedural:** dynamic furniture placement, loot containers, prop scatter, zombie patrol routes.

### 6.7 Civic landmarks 🔒

12 civic landmarks (no religious): Lighthouse, Water Tower, Grain Silo, Hospital, Police HQ, Government Palace, Stadium, Old Royal Palace, Naval Fort, Broadcast Tower, Railway Station, Grand Bazaar.

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
**Backups:** `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` (1.3MB) + `mazar_design_backup_2026-09-11.zip` (3MB)

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

See `poly_budget_v3_path_b.md §3.2` for full table. Key numbers:

| Asset type | Low LOD0 |
|---|---|
| Standard enterable building | 2,500 |
| Standard prop | 250 |
| Hero tree | 1,200 |
| Walker zombie | 3,000 |
| Held weapon | 3,000 |

### 10.3 Furniture merging — LOCKED 🔒

**Static furniture** (kitchen counters, sinks, toilets, built-ins) = merged into room mesh. 0 extra draw calls. Can't move/destroy.

**Dynamic furniture** (chairs, tables, beds, fridges, lamps, bookshelves) = separate meshes + RigidBody3D. Can be moved, thrown, scrapped, used as barricade.

**Cap:** 10 dynamic props per room on Low preset. 15 on High. 25 on Ultra.

**Loot containers** can exist on both static and dynamic furniture — they're interaction hotspots, not separate meshes.

See `/home/z/my-project/download/furniture_merging_decision.md` for full details.

### 10.4 Tiered review strategy 🔒

Tier 1 (~10 anchors, individual), Tier 2 (~80 variant packs, contact sheets), Tier 3 (~900 mass production, auto-validated), Tier 4 (~10 biome milestones). Total user review: ~3 hours.

### 10.5 Communication protocol 🔒

`APPROVE ALL` / `APPROVE EXCEPT <ids>` / `REGEN <ids> WITH <note>` / `REJECT BATCH — <reason>`

### 10.6 Tier 1 production — 16 APPROVED + 3 RETIRED ✅

| # | Asset | Category | Tris | Type | Status |
|---|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | static shell | ✅ approved |
| 2 | office_chair | props | 6,500 | dynamic | ✅ approved |
| 3 | dining_table | props | 460 | dynamic | ✅ approved |
| 4 | oak_tree | foliage | 2,400 | hero tree | ✅ approved |
| 5 | bush | foliage | 360 | bush | ✅ approved |
| 6 | sedan | vehicles | 2,000 | — | ❌ RETIRED (external) |
| 7 | pickup_truck | vehicles | 1,700 | — | ❌ RETIRED (external) |
| 8 | blood_splatter_decal | decals | 2 | — | ❌ RETIRED (external) |
| 9 | asphalt_road_segment | environment | 96 | road | ✅ approved |
| 10 | two_story_colonial | buildings | 2,600 | static shell | ✅ built (batch 003) |
| 11 | bungalow | buildings | 2,000 | static shell | ✅ built (batch 003) |
| 12 | bookshelf | props | 264 | dynamic | ✅ built (batch 003) |
| 13 | bed_single | props | 1,600 | dynamic | ✅ built (batch 003) |
| 14 | kitchen_counter | props | 580 | static fixture | ✅ built (batch 003) |
| 15 | refrigerator | props | 496 | dynamic + loot | ✅ built (batch 003) |
| 16 | pine_tree | foliage | 256 | standard tree | ✅ built (batch 003) |
| 17 | grass_tuft | foliage | 44 | multimesh scatter | ✅ built (batch 003) |
| 18 | picket_fence | environment | 168 | fence | ✅ built (batch 003) |
| 19 | street_light | environment | 504 | light source | ✅ built (batch 003) |
| — | fence.mog (upstream) | environment | 318 | fence | ✅ approved earlier |

**Total approved: 16 active + 1 upstream = 17 assets. 3 retired.**

**Contact sheet:** `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-003_all_16_contact_sheet.png`

### 10.7 Known issues queue 🔒

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream) | Doors flush with wall | Author v2 with `wall` holes + recessed door | ✅ FIXED |
| 2 | humanoid.mog (DSL test) | Reads "Roblox/blocky" | Accept for alpha; hybrid for v1 | Accepted |
| 3 | oak_tree.mog (v1) | Bare twigs from `branch` primitive | Replace with `cylinder` trunk + 7-sphere canopy | ✅ FIXED |
| 4 | sedan + pickup_truck | Wrong dimensions, wrong wheel angle | Retire — use external assets | ✅ RETIRED |
| 5 | blood_splatter_decal | Just a red square, not recognisable as blood | Retire — use external blood decal assets | ✅ RETIRED |
| 6 | texture workflow | Gemini free tier = 0 image quota | Need paid key OR ZAI_API_KEY OR manual workflow | 🔓 PAUSED |

---

## 11. Lore — SEMI-LOCKED for alpha 🔓

**Full lore:** `/home/z/my-project/download/lore_mazar_v1.2.md`

**Locked:** overall structure (city/river/biomes/Operation Living Troop/Immune player).
**Can change:** street names, faction names, character names, radio station names, lore fragment texts.

---

## 12. Open questions for v7 🔓

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
11. Tier 2 production start — variant packs
12. External vehicle + blood decal asset sources (Mixamo? Quaternius? Kenney? Sketchfab?)

---

## 13. Milestones 🔒

| # | Milestone | Exit criteria | Status |
|---|---|---|---|
| 0 | Pre-production | All v7 open questions answered | ⏳ in progress |
| 1 | Vertical slice — Suburbia | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night | Next |
| 2 | Alpha — full map | All 10 biomes present, all systems functional | — |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated | — |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings | — |
| 5 | Co-op technical pass | Online architecture validated | — |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader | — |

---

## Appendix A — MoGen lessons learned (cumulative, 8 sessions)

- MoGen compiles fast. 440-node skyscraper: ~10 ms. suburban_house_v2 (1.8k tris): 12 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` broken — replaced with Chrome + three.js + swiftshader.
- `mogen textures` requires **paid Gemini API key** (free tier = 0 image quota).
- DSL is structural, not artistic. Excellent at buildings/props. Bad at organic characters.
- **The DSL reference is compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).**
- **The `wall` primitive** with `holes=[cx, cy, w, h]` is the right tool for walls with door/window cutouts.
- **The `solid` group** with `cleanup="coplanar"` merges same-material primitives. Use for building/vehicle shells.
- **Floating cluster errors (`E1101`)** — fix by overlapping meshes in ALL 3 axes (X, Y, Z). OR use `tags="floating"` for intentionally disconnected decorative elements (shutters, grass blades, bed sheets, etc.).
- **`slab` uses `anchor=bottom`** by default. `box` uses `anchor=center`. When placing a foundation on a lawn, either use `box` (center anchor) or adjust `slab` pos y to overlap.
- **`icosphere` uses `subdivisions=`** not `detail=`. 1=low-poly (20 faces), 2=default (80 faces).
- **`branch` primitive** is hard to control — internal sub-segments can poke through canopies. Use plain cylinders for stylized trees.
- **`plane` uses `size=[x, _, z]`** (Y ignored, XZ-aligned). `quad` uses `w=` and `h=` attributes (XY-aligned).
- **`cone` primitive** with `sides=8` is good for stylized conifer foliage. Stack 3 cones of decreasing radius for pine tree silhouette.
- **Camera yaw convention:** yaw=0 = +Z face (back). yaw=180 = -Z face (front with door).
- **`alpha_mode="blend"`** for transparency. `alpha_mode="mask"` + `alpha_cutoff=0.5` for 1-bit cutout (foliage).
- **Wrap complex bodies in `solid (cleanup="coplanar")`** to merge same-material parts. Glass parts stay OUTSIDE the solid group (separate material).
- **Floating cluster fix requires overlap in ALL 3 axes.** The pickup truck had 7 clusters because front bumper overlapped with hood in X but not Y. Fixed by extending hood Y size.
- **`tags="floating"`** is the validator's escape hatch for intentionally disconnected parts. Use for: shutters, grass blades, bed sheets/pillows/blankets, door steps, loose props. The error message literally says: "tag them with `tags='floating'` if the gap is intentional."
- **`light` node** (kind=point/spot/directional) adds a Godot light to the scene. Per Low preset, only sun shadows are cast — point lights are "no shadow" and toggle on/off based on time-of-day.
- **Vehicles are better as external assets.** DSL cars have wrong proportions and wheel angles. Retire from MoGen production. Use external sources (Mixamo, Quaternius, Kenney, Sketchfab) for vehicles + blood decals.
- **Static vs dynamic furniture split** is the key architecture decision for performance + interactivity. Static = merged into room mesh (0 draw calls). Dynamic = separate RigidBody3D (1 draw call each, cap 10 per room). See `furniture_merging_decision.md`.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v6.md` | **this document** |
| `/home/z/my-project/download/lore_mazar_v1.2.md` | **the semi-locked lore document** |
| `/home/z/my-project/download/poly_budget_v3_path_b.md` | **the locked Path B budget** |
| `/home/z/my-project/download/furniture_merging_decision.md` | **the locked static vs dynamic furniture decision** |
| `/home/z/my-project/download/asset_review_strategy.md` | tiered asset review strategy |
| `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-003_all_16_contact_sheet.png` | **Tier 1 batch 003 — ALL 16 contact sheet** |
| `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` | **alpha backup (1.3MB)** |
| `/home/z/my-project/download/mazar_design_backup_2026-09-11.zip` | **design backup (3MB)** |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference** |
