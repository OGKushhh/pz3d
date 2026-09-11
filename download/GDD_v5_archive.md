# Game Design Document — Mazar Alpha

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v5 — pre-production → vertical slice. Lore semi-locked. Poly budget v3 Path B locked. **Tier 1 production COMPLETE — all 9 style anchors built + VLM-verified.**
> **Working title:** *Mazar*
> **Lore:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, **semi-locked for alpha**)
> **Poly budget:** `/home/z/my-project/download/poly_budget_v3_path_b.md` (v3, **locked — two-tier Low/High presets**)
> **Engine:** Godot 4.7.2 (glTF 2.0 native, **Compatibility renderer default for Low preset**)
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot)
> **MoGen reference:** `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB, compiled)

---

## 1. Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is the National City of Mazar — a fictional coastal city divided by the Sarran River, where a 300-year monarchy ended in a quiet coup 70 years ago, where a military junta sold the nation to a foreign Border Enemy, where Operation Living Troop created a supersoldier serum that killed its subjects and raised them as the undead.

The city is fixed, persistent, hand-crafted. Every building enterable. Every run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

Travel is exploration, not optimization. The map uses draw-distance fog, non-trivial road networks, the Sarran River as a real obstacle, bridges as chokepoints, landmarks far apart.

No place is safe.

---

## 2. Pillars

1. **Hand-authored world.** Every building has a reason. Procedural interiors (furniture, room layout, prop placement) provide replayability; the exterior shell is fixed.
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters. Generators hum. Footsteps echo.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist. Find your old body, loot your old loot.
4. **Biome identity.** Each of the 10 biomes has a loot focus, difficulty, vibe, weather, and time-cycle identity.
5. **Travel as exploration.** Not optimization. The Sarran River blocks. The Forest hides. Bridges force chokepoints.
6. **All three combat modes.** Stealth, guns, melee — all viable, all situational. Shooting is the addictive hook (Valorant-feel).
7. **Civic, not sacred.** Mazar's landmarks are civic. No religious buildings. Faith lives in the people, not the skyline.
8. **Runs on millions of PCs.** Low preset baseline: 2GB VRAM / 4GB RAM / 1080p / 60 FPS. High preset scales up.

---

## 3. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Not pixel art. Not gritty realism. Same neighbourhood as *Night of the Dead* or the cleaner scenes from *The Long Dark*.

**Tier 1 lookbook:** 9 PNG renders + contact sheet at `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-002_all_9_contact_sheet.png`

### Comic-book / outline post-processing 🔓

Three options considered. **Recommended:** inverted hull outline (~1 day, *Wind Waker* look). Implement when we lock the palette.

### Texture workflow 🔓 PAUSED

`mogen textures` requires paid Gemini API key (free tier = 0 image quota). Alternative: separate ZAI_API_KEY via `--zai-api-key` flag, OR manual workflow via image-generation skill. **Paused for alpha** — flat-color materials are acceptable. Textures become a v1 polish step.

---

## 4. Camera — FIRST-PERSON 🔒

**Locked.** First-person.

- Player eye height: 1.65 m
- Standard door: 0.90 m wide × 2.10 m tall
- Standard ceiling: 2.40 m
- Assets must hold up at 0.5 m viewing distance
- LODs matter — kitchens with 30k+ tris of props in view (on High preset)

---

## 5. Characters — DSL HUMANOID FOR ALPHA 🔒

**Locked for alpha.** DSL-authored humanoid via `humanoid.mog`. Blocky, Roblox-adjacent, accepted.

**For v1 (post-alpha):** hybrid approach — external base mesh + MoGen for clothing/accessories.

**Lore justification:** player is one of "The Immune" — body rejected the Living Troop liquid. This is why you're alive.

---

## 6. World structure — FIXED MAP + PROCEDURAL INTERIORS 🔒

### 6.1 Map dimensions — LOCKED 🔒

**4.0 km × 3.0 km = 12 km² of playable area** (~40% of GTA San Andreas total map).

- Grid: 8 × 6 cells of 500m × 500m. Each cell = 0.25 km². Total 48 cells.
- Traversal: walk 60 min, sprint 37 min, bicycle 15 min, car 5 min.

### 6.2 Map geography — LOCKED via lore 🔒

The Sarran River flows from the northern Forest through the Farmland and into Sarran Bay. The bay is west of the city. The river splits the city into east and west.

**West Side:** Suburbia, Parks & Greenways, Commercial Strip, Farmland, Forest
**East Side:** Industrial Park, River & Wetlands, Downtown, Military Zone
**Underground:** Subway (public + secret military tunnels)

### 6.3 The 10 Biomes — LOCKED 🔒

| # | Biome | Difficulty | Zombie Density | Base Potential |
|---|---|---|---|---|
| 1 | Suburbia | Low | Low–Medium | **High** |
| 2 | Parks & Greenways | Low | Low | Low–Medium |
| 3 | Forest | Medium | Low | Medium–High |
| 4 | Farmland | Low–Medium | Low | **High** |
| 5 | Commercial Strip | Medium–High | Medium–High | Medium |
| 6 | Industrial Park | Medium | Medium | **High** |
| 7 | River & Wetlands / Coastal Beach | Medium | Low–Medium | Low–Medium |
| 8 | Subway | Medium–High | Medium–High (clustered) | Low–Medium |
| 9 | Downtown | High–Very High | Very High | **Low** |
| 10 | Military Zone / Quarantine | Extreme | Extreme | None — endgame raid only |

### 6.4 Alpha build order 🔒

Suburbia → Parks → Farmland → Forest → Commercial → Industrial → River/Wetlands → Subway → Downtown → Military Zone.

### 6.5 Persistent map + per-run reset 🔒

- **Persistent:** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

### 6.6 Procedural interiors 🔒

- **Fixed:** building exterior shell, room layout, doors, windows, structural props.
- **Procedural:** small furniture placement, loot containers, prop scatter, zombie patrol routes.

### 6.7 Civic landmarks 🔒

12 civic landmarks (no religious): Lighthouse, Water Tower, Grain Silo, Hospital, Police HQ, Government Palace, Stadium, Old Royal Palace, Naval Fort, Broadcast Tower, Railway Station, Grand Bazaar.

---

## 7. Gameplay systems

### 7.1 Survival needs 🔓

Likely adopt subset of PZ's: hunger, thirst, fatigue, panic, sickness, infection.

### 7.2 Combat — STEALTH + GUNS + MELEE 🔒

**Shooting = Valorant-feel:** tight, responsive, low-TTK, learnable recoil patterns, headshot-focused.

**Stealth:** crouch silent, backstab instakill, LOS breaks lose zombies.

**Melee:** stab silent / blunt 5m / heavy 10m. Door-defense meta.

### 7.3 Hearing-based zombie AI 🔒

3D sound propagation, occlusion, noise events. Zombies investigate gunshots (50m+), footsteps (5-20m), alarms, generators (30m), broken glass (15m), door barricades, vehicle engines.

### 7.4 Zombies 🔒

Walker (slow, sight cone + hearing), Crawlers (legs destroyed), Groups (noise pulls, no coordination), Memory ~10 sec.

### 7.5 Death penalty + meta-progression 🔒

**Story mode:** keep equipped weapons, lose consumables/materials.
**Sandbox:** lose everything, new character can find old body.

| Upgrade | Per-level | Max |
|---|---|---|
| Movement Speed | +5% | 5 |
| Max Health | +10 HP | 5 |
| Carrying Capacity | +2 slots | 5 |
| Flashlight Battery | +15% duration | 5 |
| Stamina / Noise Reduction | -10% noise | 5 |

Resources: scrap, blood, electronics.

### 7.6 Radio Rumor system 🔒

One run modifier per run. 4 stations: Voice of Mazar (Republic), Radio Junta (Junta), Free Bay FM (Survivors), The Border Signal (Border Enemy).

### 7.7 Factions — SEMI-LOCKED 🔓

5 factions: Mazar Republic, Junta Remnants, Border Enemy, Survivors, The Immune. Names + relationships may shift during alpha.

### 7.8 Lore fragments + persistent keys 🔒

Reveal: Operation Living Troop truth, Border Enemy involvement, junta cover-up, King Amir's fate, immune identity, lab location (Fort Sarran), secret Subway routes.

### 7.9 Base / safehouse hub 🔒

Apartment → Base. Storage, crafting, medical, radio, ammo station. **No place is safe.**

### 7.10 Dynamic spawns + permanent kills 🔒

Killed zombies stay dead (alpha). Cleared areas become safer.

### 7.11 Co-op (optional, future) 🔓

Alpha: technical possibility only. Future: revive + hold-the-gate.

---

## 8. Loot tables 🔒

### 8.1 Pattern

Per-district fixed table. Within: Common 60%, Uncommon 30%, Rare 10%.

### 8.2 All 10 biome tables 🔒

| District | Common (60%) | Uncommon (30%) | Rare (10%) |
|---|---|---|---|
| Hospital (Downtown) | Bandage, Bottled Water | Medkit, Syringe | Stimulant |
| Police HQ (Downtown) | Pistol Ammo | Shotgun Ammo | Tier 2 Armor |
| Industrial Park | Scrap Metal, Canned Food | Noise Grenade Parts | Rare Crafting Component |
| Subway | Flashlight Battery, Clean Water | Electronics | Lore Fragment |
| River & Wetlands | Fish, Driftwood | Boat Fuel | Hermetic Container |
| Suburbia | Canned Food, Batteries | Household Tools | Car Keys |
| Parks & Greenways | Snacks, Water | Seeds | Fishing Rod |
| Forest | Wood, Herbs | Hunting Gear | Animal Trap |
| Farmland | Crops, Eggs | Fuel Canister | Tractor Parts |
| Commercial Strip | Cash, Snacks | Electronics | Weapon Magazine |
| Military Zone | MRE, Battery | Hazmat Suit | Military Keycard |

---

## 9. 3D-specific systems 🔓

- FOV (likely 90°)
- LOS checks for AI
- Sound propagation grid
- Occlusion (rendering + gameplay)

---

## 10. Asset production pipeline 🔒

**Contract:** `/home/z/my-project/asset-pipeline/README.md`
**Worklog:** `/home/z/my-project/asset-pipeline/worklog/worklog.md`
**Poly budget:** `/home/z/my-project/download/poly_budget_v3_path_b.md` (locked v3, two-tier)
**Backups:** `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` + `mazar_design_backup_2026-09-11.zip`
**Directory:** `/home/z/my-project/assets/{buildings,props,foliage,characters,environment,vehicles,decals}/{src,out,renders,textures,refs}/`

### 10.1 Engine budgets — LOCKED (Path B, two-tier) 🔒

| Metric | Low preset (alpha default) | High preset | Ultra (v1) |
|---|---|---|---|
| Resolution | 1080p (720p internal on Intel iGPU) | 1080p native | 1440p |
| Renderer | Compatibility (OpenGL 3.3) | Compatibility (alpha) / Forward+ (v1) | Forward+ |
| Frame time | 16.67 ms (60 FPS) | 16.67 ms | 11.1 ms |
| Draw calls | 600 max | 1500 max | 2500 max |
| On-screen triangles | 500k max | 1.5M max | 3M max |
| Texture memory (active) | 800 MB | 2 GB | 4 GB |
| View distance | 100m | 200m | 300m+ |
| Fog start | 60m | 150m | 250m |
| Foliage billboard swap | 60m | 100m | 150m |
| Real-time shadow lights | sun only (1024² hard) | sun + 4 spot (2048² PCF) | sun + 8 (4096² PCF) |
| Decals on screen | 30 | 80 | 200 |
| Time-of-day | ambient color shift only | mixed bake + 1 dynamic sun | fully dynamic |
| Active chunks in memory | 3×3 active + 5×5 warm | 5×5 active + 7×7 warm | 7×7 active + 9×9 warm |

### 10.2 Per-asset triangle budgets (Low preset LOD0) 🔒

| Asset type | Low LOD0 | Low LOD1 | Low LOD2 | Low LOD3 |
|---|---|---|---|---|
| Hero building (landmark) | 8 000 | 3 000 | 1 000 | 300 |
| Standard enterable building | 2 500 | 800 | 250 | 80 |
| Background building | 500 | 200 | 80 | 30 |
| Interior shell (per room) | 1 500 | — | — | — |
| Interior prop (per item) | 200 | 80 | — | — |
| Held weapon (FPS view) | 3 000 | — | — | — |
| Hero prop | 800 | 250 | 80 | — |
| Standard prop | 250 | 80 | 30 | — |
| Background prop | 80 | 30 | — | — |
| Player character | 4 000 | 1 200 | 400 | 120 |
| Walker zombie | 3 000 | 800 | 250 | 80 |
| Crawler zombie | 2 000 | 600 | 200 | 60 |
| Hero tree | 1 200 | 400 | 120 | 30 (billboard) |
| Standard tree | 500 | 200 | 60 | 20 (billboard) |
| Bush | 200 | 80 | — | — |
| Driveable sedan | 4 000 | 1 200 | 400 | — |
| Driveable pickup | 5 000 | 1 500 | 500 | — |
| Decal | 6 verts | — | — | — |
| Road segment (per 10m) | 80 tris | — | — | — |

### 10.3 Zombie dynamic count system 🔒

**Key improvement on Gemini's profile:** zombies scale based on hardware + FPS.

| Preset | Max on-screen | Max active AI | Tick rate (close/mid/far) |
|---|---|---|---|
| Low | 30 | 30 | 60 Hz / 12 Hz / last-known-position steering |
| High | 60 | 60 | 60 Hz / 20 Hz / 4 Hz pathfinding |
| Ultra | 100 | 100 | 60 Hz / 30 Hz / 8 Hz pathfinding |

**Adaptive:** if FPS drops below 50 for 2 sec, reduce max zombies by 5 (floor 10). If FPS above 65 for 5 sec, increase by 5 (up to preset ceiling).

### 10.4 Tiered review strategy 🔒

- Tier 1 (~10 style anchors): individual review, ~1 min each.
- Tier 2 (~80 variant packs): contact sheets, ~3 min each.
- Tier 3 (~900 mass production): auto-validated only.
- Tier 4 (~10 biome milestones): full biome flythrough, ~10 min each.
- Total user review time: ~3 hours across entire alpha.

### 10.5 Communication protocol 🔒

`APPROVE ALL` / `APPROVE EXCEPT <ids>` / `REGEN <ids> WITH <note>` / `REJECT BATCH — <reason>`

### 10.6 Tier 1 production — COMPLETE ✅

All 9 style anchors built + rendered + VLM-verified. Contact sheet at `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-002_all_9_contact_sheet.png`.

| # | Asset | Status | Tris | High LOD0 budget | Low LOD0 budget | Notes |
|---|---|---|---|---|---|---|
| 1 | suburban_house_v2 | ✅ built | 1,800 | 8k | 2.5k | Door bug fixed — red door + garage door visible. Under both budgets. |
| 2 | office_chair | ✅ built | 6,500 | 600 | 250 | Over both Low + High budgets (chairs are complex). Will use Godot auto-LOD for Low preset. |
| 3 | dining_table | ✅ built | 460 | 800 | 250 | Under High, over Low. Auto-LOD will handle Low preset. |
| 4 | oak_tree (fixed) | ✅ built | 2,400 | 2.5k | 1.2k | Under High, over Low. Auto-LOD will handle Low preset. |
| 5 | bush | ✅ built | 360 | 400 | 200 | Under High, over Low. Auto-LOD will handle Low preset. |
| 6 | sedan | ✅ built | 2,000 | 12k | 4k | Way under both budgets. |
| 7 | pickup_truck | ✅ built | 1,700 | 15k | 5k | Way under both budgets. |
| 8 | blood_splatter_decal | ✅ built | 2 | 6 verts | 6 verts | Perfect — decal is flat plane. |
| 9 | asphalt_road_segment | ✅ built | 96 | 200 | 80 | Under High, just over Low. Auto-LOD will handle Low. |
| 10 | fence.mog (upstream) | ✅ approved | 318 | — | 200 | Under budget. |

### 10.7 Known issues queue 🔒

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream) | Doors flush with wall (z-fighting), obscured by porch | Author suburban_house_v2 with `wall` primitive holes + recessed door panel + frame | ✅ FIXED |
| 2 | humanoid.mog (DSL test) | Reads "Roblox/blocky" | Accept for alpha; hybrid for v1 | Accepted |
| 3 | oak_tree.mog (v1) | Bare twigs poking through canopy (branch primitive internal sub-segments leaking) | Replace `branch` with `cylinder` trunk + 7-sphere canopy | ✅ FIXED |
| 4 | office_chair.mog | 6.5k tris, over both Low + High budgets | Will use Godot auto-LOD generation at import time to generate LOD1-3 chains for Low preset | Deferred to Godot import |
| 5 | texture workflow | Gemini free tier = 0 image quota | Need paid Gemini key OR separate ZAI_API_KEY OR manual workflow via image-generation skill | 🔓 PAUSED for alpha |

---

## 11. Lore — SEMI-LOCKED for alpha 🔓

**Full lore document:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, **semi-locked during alpha**)

**What's locked:** overall structure (coastal city, river dividing east/west, monarchy → coup → junta → outbreak), 10 biomes' lore roles, 5 factions' high-level goals, 12 civic landmarks, Operation Living Troop as zombie origin, player is one of The Immune.

**What can change during alpha:** street names, faction names, character names, radio station names, lore fragment texts.

### 11.1 Timeline (semi-locked)

- 300 yr ago → 70 yr ago: Long Peace (House of Mazar monarchy)
- 70 yr ago: Quiet Coup (King Amir abdicated)
- 68-60 yr ago: General Karim's regime → rot → house arrest
- 13 yr ago: Border Enemy takes over junta
- 10 yr ago: Operation Living Troop begins
- 2 weeks ago: Fort Sarran lab explosion → leak → contamination
- Day 0 = now: outbreak, city silent, immune alive

---

## 12. Open questions for v6 🔓

1. Survival needs list (subset of PZ's)
2. Combat focus balance (ratios of stealth/guns/melee encounters)
3. Loot richness multipliers per biome
4. Visual palette per biome (locked color swatches)
5. FOV angle (likely 90°, lock it)
6. Number of buildings / POIs per biome (concrete counts)
7. Day-1 sim feasibility (chaos effects scope — story mode feature, not alpha)
8. Co-op technical architecture
9. Sandbox vs story mode launch order
10. Texture API key resolution (paid Gemini / separate ZAI / manual workflow)
11. Tier 2 production start — variant packs (first: Suburbia house variants pristine/weathered/ruined/burned)

---

## 13. Milestones 🔒

| # | Milestone | Exit criteria | Status |
|---|---|---|---|
| 0 | Pre-production (this GDD) | All v6 open questions answered | ⏳ in progress |
| 1 | Vertical slice — Suburbia fully playable | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night | Next |
| 2 | Alpha — full map at reduced fidelity | All 10 biomes present, all systems functional | — |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced | — |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings | — |
| 5 | Co-op technical pass | Online architecture validated | — |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed | — |

---

## Appendix A — MoGen lessons learned (cumulative, 6 sessions)

- MoGen compiles fast. 440-node skyscraper: ~10 ms. 1.8k-tri suburban house v2: 12 ms. 1.7k-tri pickup truck: 19ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` is broken in this env — replaced with Chrome + three.js + swiftshader.
- `mogen textures` requires **paid Gemini API key** (free tier = 0 image quota).
- MoGHub community library available — `mogen moghub discover --query chair`.
- DSL is structural, not artistic. Excellent at "house with windows and chimney". Bad at "rotting zombie with torn shirt".
- **The DSL reference is compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).** Read from disk, not web-fetching.
- **The `wall` primitive** is the right tool for walls with door/window cutouts — `holes=[cx, cy, w, h]` cuts all the way through Z thickness.
- **The `solid` group** with `cleanup="coplanar"` merges same-material primitives and removes interior faces at export time. Use this for building/vehicle shells.
- **Floating cluster errors (`E1101`)** are caused by disconnected geometry. Fix by overlapping meshes by ~0.01-0.05m so the `solid` group can merge them. CRITICAL: meshes must overlap in ALL 3 axes (X, Y, Z), not just one.
- **`detail=` is not an `icosphere` attribute.** Use `subdivisions=` instead (1 = low-poly 20 faces, 2 = default 80 faces, 3 = high-poly 320 faces).
- **The `branch` primitive** is hard to control. Internal sub-segments (seg_d0..d3) can poke through canopy spheres in unpredictable ways. For stylized trees where you want clean silhouette control, plain cylinders are better. Reserve `branch` for hero assets where the trunk itself is the visual focus.
- **Camera yaw convention in our render_glb.html:** yaw=0 looks at +Z face (back). yaw=180 looks at -Z face (front with door). For front views, use yaw=180-225.
- **`plane` primitive** uses `size=[x, _, z]` (Y ignored, plane is XZ-aligned). NOT `size=[x, y]`.
- **`alpha_mode="blend"`** on materials for transparency. `alpha_mode="mask"` for 1-bit cutout (foliage).
- **Wrap vehicle/complex bodies in `solid (cleanup="coplanar")`** to merge all same-material primitives into one watertight mesh. Eliminates "floating cluster" errors caused by separate body parts.
- **Gemini's "Low Graphics" profile assessment:** mostly correct. Agreed on: 600 draw calls, 500k triangles, MultiMeshInstance3D for foliage, staggered AI tick rates, 256² texture max, baked lighting, ambient color shift for time-of-day, blob contact shadows. Refined: view distance 100m (Gemini said 150m — too far for 2GB VRAM), chunk streaming 3×3 active + 5×5 warm (Gemini said instant unload — too aggressive), sun shadows at 1024² hard (Gemini said disable entirely — looks flat), zombie count 30 (Gemini's number — better than my earlier 15).

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v5.md` | **this document** |
| `/home/z/my-project/download/GDD_v4_archive.md` | v4 archived |
| `/home/z/my-project/download/lore_mazar_v1.2.md` | **the semi-locked lore document** |
| `/home/z/my-project/download/poly_budget_v1.md` | v1 budget (mid-range, archived) |
| `/home/z/my-project/download/poly_budget_v2_low_end.md` | v2 budget (low-end only, archived) |
| `/home/z/my-project/download/poly_budget_v3_path_b.md` | **the locked v3 budget (two-tier Low/High)** |
| `/home/z/my-project/download/asset_review_strategy.md` | tiered asset review strategy |
| `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-002_all_9_contact_sheet.png` | **Tier 1 batch 002 — ALL 9 contact sheet for user review** |
| `/home/z/my-project/download/mogen-lookbook/` | 11 PNG renders of MoGen-native output (initial) |
| `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` | **alpha backup zip — assets + scripts + mogen-examples** |
| `/home/z/my-project/download/mazar_design_backup_2026-09-11.zip` | **design backup zip — GDDs + lore + poly budgets + worklogs + compiled MoGen docs + GTA SA map ref** |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference** |
| `/home/z/my-project/upload/large-detailed-map-of-gta-san-andreas.jpg` | the GTA SA map reference |
