# Game Design Document — Mazar Alpha

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v7 — pre-production → vertical slice. Lore semi-locked. Path B locked. **Tier 1 production: 15 approved + 4 retired. All batch 003 issues FIXED.**
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

**Tier 1 lookbook:** 15 approved assets. Contact sheet at `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-004_post_fixes_contact_sheet.png`

### Comic-book / outline post-processing 🔓

**Recommended:** inverted hull outline (~1 day, *Wind Waker* look). Implement when we lock the palette.

### Texture workflow 🔓 PAUSED

`mogen textures` requires paid Gemini API key (free tier = 0 image quota). **Paused for alpha** — flat-color materials are acceptable.

### Vehicles + blood decals + grass tufts = EXTERNAL ASSETS 🔒

Cars (sedan, pickup_truck), blood splatter decals, and grass tufts are **retired from MoGen production**. External assets are better quality for these. Retired files preserved in `assets/{vehicles,decals,foliage}/retired/`.

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
**Backups:** `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` (1.4MB) + `mazar_design_backup_2026-09-11.zip` (3.4MB)

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

**Static furniture** (kitchen counters, sinks, toilets, built-ins) = merged into room mesh. 0 extra draw calls. Can't move/destroy.

**Dynamic furniture** (chairs, tables, beds, fridges, lamps, bookshelves) = separate meshes + RigidBody3D. Can be moved, thrown, scrapped, used as barricade.

**Cap:** 10 dynamic props per room on Low preset. 15 on High. 25 on Ultra.

See `/home/z/my-project/download/furniture_merging_decision.md` for full details.

### 10.4 Tiered review strategy 🔒

Tier 1 (~10 anchors, individual), Tier 2 (~80 variant packs, contact sheets), Tier 3 (~900 mass production, auto-validated), Tier 4 (~10 biome milestones). Total user review: ~3 hours.

### 10.5 Communication protocol 🔒

`APPROVE ALL` / `APPROVE EXCEPT <ids>` / `REGEN <ids> WITH <note>` / `REJECT BATCH — <reason>`

### 10.6 Tier 1 production — 15 APPROVED + 4 RETIRED ✅

| # | Asset | Category | Tris | Type | Status |
|---|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | static shell | ✅ FIXED (side windows aligned) |
| 2 | office_chair | props | 6,500 | dynamic | ✅ approved |
| 3 | dining_table | props | 460 | dynamic | ✅ approved |
| 4 | oak_tree | foliage | 2,400 | hero tree | ✅ approved |
| 5 | bush | foliage | 360 | bush | ✅ approved |
| 6 | sedan | vehicles | — | — | ❌ RETIRED (external) |
| 7 | pickup_truck | vehicles | — | — | ❌ RETIRED (external) |
| 8 | blood_splatter_decal | decals | — | — | ❌ RETIRED (external) |
| 9 | asphalt_road_segment | environment | 96 | road | ✅ approved |
| 10 | two_story_colonial | buildings | 2,600 | static shell | ✅ FIXED (side windows aligned) |
| 11 | bungalow | buildings | 2,000 | static shell | ✅ FIXED (side windows aligned) |
| 12 | bookshelf | props | 264 | dynamic | ✅ FIXED (books face camera) |
| 13 | bed_single | props | 1,600 | dynamic | ✅ FIXED (sheets connected) |
| 14 | kitchen_counter | props | 580 | static fixture | ✅ FIXED (L-turn direction) |
| 15 | refrigerator | props | 412 | dynamic + loot | ✅ SIMPLIFIED (removed handles/divider) |
| 16 | pine_tree | foliage | 256 | standard tree | ✅ approved |
| 17 | grass_tuft | foliage | — | — | ❌ RETIRED (external) |
| 18 | picket_fence | environment | 168 | fence | ✅ approved |
| 19 | street_light | environment | 504 | light source | ✅ approved |
| — | fence.mog (upstream) | environment | 318 | fence | ✅ approved |

**Total: 15 active + 1 upstream = 16 approved. 4 retired.**

**Contact sheet:** `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-004_post_fixes_contact_sheet.png`

### 10.7 Known issues queue 🔒

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream) | Doors flush with wall | Author v2 with `wall` holes + recessed door | ✅ FIXED |
| 2 | humanoid.mog (DSL test) | Reads "Roblox/blocky" | Accept for alpha; hybrid for v1 | Accepted |
| 3 | oak_tree.mog (v1) | Bare twigs from `branch` primitive | Replace with `cylinder` trunk | ✅ FIXED |
| 4 | sedan + pickup_truck | Wrong dimensions, wrong wheel angle | Retire — use external assets | ✅ RETIRED |
| 5 | blood_splatter_decal | Just a red square | Retire — use external blood decal assets | ✅ RETIRED |
| 6 | texture workflow | Gemini free tier = 0 image quota | Need paid key OR ZAI_API_KEY OR manual workflow | 🔓 PAUSED |
| 7 | grass_tuft | Low quality, easy to get externally | Retire — use external grass assets | ✅ RETIRED |
| 8 | house side windows (all 3 houses) | Windows on rotated walls not aligned — window groups weren't rotated with the wall | Add `rot=[0, 90, 0]` to side window groups | ✅ FIXED |
| 9 | bookshelf showing back | Camera saw the back panel (books were on -Z, camera at +Z) | Flip bookshelf: back panel at -Z, books at +Z (facing default camera) | ✅ FIXED |
| 10 | bed sheets/blanket/pillow disconnected | Used `tags="floating"` which made them physically disconnected | Remove `tags="floating"`, make them overlap with mattress by 0.02-0.03m | ✅ FIXED |
| 11 | refrigerator "middle upside down" | User saw something wrong with the divider/handles area | Simplify: remove divider + handles + magnets + shelf lines. Keep just body + 2 door panels + base + vent | ✅ FIXED |
| 12 | kitchen counter "reversed" | L-turn going wrong direction, looked backwards from camera | Rebuild: L-turn extends toward -Z (back, toward wall), stove on LEFT, sink in MIDDLE, cabinet doors on +Z front face | ✅ FIXED |

---

## 11. Lore — SEMI-LOCKED for alpha 🔓

**Full lore:** `/home/z/my-project/download/lore_mazar_v1.2.md`

**Locked:** overall structure (city/river/biomes/Operation Living Troop/Immune player).
**Can change:** street names, faction names, character names, radio station names, lore fragment texts.

---

## 12. Open questions for v8 🔓

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
11. External vehicle + blood decal + grass asset sources (Mixamo? Quaternius? Kenney? Sketchfab?)
12. Tier 2 production start — variant packs

---

## 13. Milestones 🔒

| # | Milestone | Exit criteria | Status |
|---|---|---|---|
| 0 | Pre-production | All v8 open questions answered | ⏳ in progress |
| 1 | Vertical slice — Suburbia | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night | Next |
| 2 | Alpha — full map | All 10 biomes present, all systems functional | — |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated | — |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings | — |
| 5 | Co-op technical pass | Online architecture validated | — |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader | — |

---

## Appendix A — MoGen lessons learned (cumulative, 9 sessions)

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
- **`alpha_mode="blend"`** for transparency. `alpha_mode="mask"` + `alpha_cutoff=0.5` for 1-bit cutout (foliage).
- **Wrap complex bodies in `solid (cleanup="coplanar")`** to merge same-material parts.
- **`tags="floating"`** is the escape hatch for intentionally disconnected parts.
- **`light` node** embedded in .mog — exported as glTF KHR_lights_punctual, Godot reads as Light3D.
- **Vehicles + blood decals + grass are better as external assets.** DSL can't do correct proportions, wheel angles, or fine organic detail. Retire from MoGen.
- **Static vs dynamic furniture split** is the key architecture decision. See `furniture_merging_decision.md`.
- **CRITICAL: window groups on rotated walls must also be rotated.** A wall with `rot=[0, 90, 0]` (left/right side walls) needs window groups on that wall to also have `rot=[0, 90, 0]`, otherwise the windows face perpendicular to the wall (sideways). This was the root cause of "side windows not aligned with the wall" in batch 003. Fix applied to all 3 houses (suburban_house_v2, two_story_colonial, bungalow).
- **Bookshelf orientation:** if the open side (with books visible) faces -Z, the default camera (at +Z) sees the back panel. Flip the bookshelf so the open side faces +Z (back panel at -Z, books at +Z toward camera).
- **Bedding overlap:** sheets/blanket/pillow must actually overlap with the mattress by 0.02-0.03m in Y to be physically connected. Using `tags="floating"` makes them visually disconnected (they appear to float above the mattress).
- **Refrigerator simplification:** when in doubt, remove decorative details (handles, dividers, magnets, shelf lines). The user said "you can remove it for simplicity" — listen to that instinct. Less is more for stylized low-poly.
- **Kitchen counter L-direction:** the L-turn should extend toward the BACK of the counter (the wall side, -Z), not toward the front (camera side, +Z). Stove on LEFT, sink in MIDDLE, cabinet doors on FRONT face (+Z). This is the standard "galley kitchen" layout.
- **Cabinet doors are decorative panels** — they don't structurally connect to the carcass. Tag them as `floating` to avoid floating cluster errors.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v7.md` | **this document** |
| `/home/z/my-project/download/lore_mazar_v1.2.md` | **the semi-locked lore document** |
| `/home/z/my-project/download/poly_budget_v3_path_b.md` | **the locked Path B budget** |
| `/home/z/my-project/download/furniture_merging_decision.md` | **the locked furniture decision** |
| `/home/z/my-project/download/asset_review_strategy.md` | tiered asset review strategy |
| `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-004_post_fixes_contact_sheet.png` | **Tier 1 batch 004 — POST-FIXES contact sheet** |
| `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` | **alpha backup (1.4MB)** |
| `/home/z/my-project/download/mazar_design_backup_2026-09-11.zip` | **design backup (3.4MB)** |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference** |
