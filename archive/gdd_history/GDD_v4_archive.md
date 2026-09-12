# Game Design Document — Mazar Alpha

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v4 — pre-production → vertical slice. Lore semi-locked (we can change names/factions during alpha). Poly budget locked. Tier 1 production started.
> **Working title:** *Mazar*
> **Lore document:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, **semi-locked for alpha**)
> **Poly budget:** `/home/z/my-project/download/poly_budget_v1.md` (v1, locked)
> **Inspiration:** Project Zomboid (gameplay loop, tone, permadeath, no-place-is-safe) — not its isometric pixel art. Real 3D.
> **Engine:** Godot 4.7.2 (glTF 2.0 native, Forward+ renderer).
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot).
> **MoGen reference:** `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB, compiled).

---

## 1. Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is the National City of Mazar — a fictional coastal city divided by the Sarran River, where a 300-year monarchy ended in a quiet coup 70 years ago, where a military junta sold the nation to a foreign Border Enemy, where Operation Living Troop created a supersoldier serum that killed its subjects and raised them as the undead.

The city is fixed, persistent, hand-crafted. Every building enterable. Every run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

Travel is exploration, not optimization. The map uses draw-distance fog, non-trivial road networks, the Sarran River as a real obstacle, bridges as chokepoints, landmarks far apart. The fastest path on the GPS is rarely the safest path.

No place is safe.

---

## 2. Pillars

1. **Hand-authored world.** Every building has a reason. Procedural interiors (furniture, room layout, prop placement) provide replayability; the exterior shell is fixed.
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters. Generators hum. Footsteps echo.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist. Find your old body, loot your old loot.
4. **Biome identity.** Each of the 10 biomes has a loot focus, difficulty, vibe, weather, and time-cycle identity.
5. **Travel as exploration.** Not optimization. The Sarran River blocks. The Forest hides. Bridges force chokepoints.
6. **All three combat modes.** Stealth, guns, melee — all viable, all situational. Shooting is the addictive hook (Valorant-feel), but you don't have to shoot.
7. **Civic, not sacred.** Mazar's landmarks are civic (lighthouse, water tower, grain silo, hospital, government palace). No religious buildings. Faith lives in the people, not the skyline.

---

## 3. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Albedo LLM-drawn via Gemini 2.5 Flash Image; normal/roughness/AO locally-derived. Not pixel art. Not gritty realism. Same neighbourhood as *Night of the Dead* or the cleaner scenes from *The Long Dark*.

**Lookbook:** 11 PNGs at `/home/z/my-project/download/mogen-lookbook/`. **Tier 1 anchors (5 of 10 done):** see §10.

**Known alpha-acceptable issues:**
- ~~Suburban house has a door bug~~ ✅ FIXED in v2 (`suburban_house_v2.mog`).
- DSL humanoid reads "Roblox/blocky". Accepted for alpha; hybrid for v1.

### Comic-book / outline post-processing 🔓

Godot-side. Three options:
1. **Inverted hull outline** — ~1 day, *Wind Waker* look. **Recommended.**
2. **Screen-space Sobel** — ~3 days, *Borderlands* look.
3. **Full cel-shading** — ~1 week, throws away PBR textures.

**Plan:** implement option 1 when we lock the palette.

---

## 4. Camera — FIRST-PERSON 🔒

**Locked.** First-person.

- Player eye height: 1.65 m
- Standard door: 0.90 m wide × 2.10 m tall
- Standard ceiling: 2.40 m
- Assets must hold up at 0.5 m viewing distance
- Vertically interesting level design (look up at skyscrapers, down into basements)
- LODs matter — kitchens with 30k+ tris of props in view

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

The Sarran River flows from the northern Forest through the Farmland and into Sarran Bay. The bay is west of the city. The river splits the city into east and west. Bridges are chokepoints.

**West Side:** Suburbia, Parks & Greenways, Commercial Strip, Farmland, Forest
**East Side:** Industrial Park, River & Wetlands, Downtown, Military Zone
**Underground:** Subway (public + secret military tunnels)

### 6.3 Map design principles (locked) 🔒

1. Draw distance fog — lore-justified (fog rolled in after the leak)
2. Non-trivial road network
3. GPS not always fastest
4. Sarran River as obstacle
5. Landmarks far apart
6. Every town has a reason to stop
7. Unique color/weather/time per biome
8. Free-roam interiors
9. Technical limits as creative constraints
10. Travel = exploration

### 6.4 The 10 Biomes — LOCKED 🔒

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

### 6.5 Alpha build order 🔒

1. Suburbia → 2. Parks & Greenways → 3. Farmland → 4. Forest → 5. Commercial Strip → 6. Industrial Park → 7. River & Wetlands → 8. Subway → 9. Downtown → 10. Military Zone.

### 6.6 Persistent map + per-run reset 🔒

- **Persistent:** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

### 6.7 Procedural interiors 🔒

- **Fixed:** building exterior shell, room layout, doors, windows, structural props.
- **Procedural:** small furniture placement, loot containers, prop scatter, zombie patrol routes.

### 6.8 Civic landmarks 🔒

12 civic landmarks (no religious): Lighthouse, Water Tower, Grain Silo, Hospital, Police HQ, Government Palace, Stadium, Old Royal Palace, Naval Fort, Broadcast Tower, Railway Station, Grand Bazaar.

---

## 7. Gameplay systems

### 7.1 Survival needs 🔓

Zomboid uses: hunger, thirst, fatigue, panic, boredom, depression, sickness, infection. We will likely adopt a subset.

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

One run modifier per run. 4 stations locked: Voice of Mazar (Republic), Radio Junta (Junta), Free Bay FM (Survivors), The Border Signal (Border Enemy).

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
**Poly budget:** `/home/z/my-project/download/poly_budget_v1.md` (locked v1)
**Directory:** `/home/z/my-project/assets/{buildings,props,foliage,characters,environment,vehicles,decals}/{src,out,renders,textures,refs}/`

### 10.1 Engine budgets — LOCKED 🔒

| Metric | Target | Ceiling |
|---|---|---|
| Frame time | 16.67 ms (60 FPS) | 33 ms |
| Draw calls | ~1500 | 2000 |
| Triangles on-screen | ~2 M | 3 M |
| Texture memory | ~3 GB | 4 GB |
| Real-time lights | 8 (incl. sun) | 16 |
| Decals | ~50 | 100 |

### 10.2 Per-asset budgets — LOCKED 🔒

| Asset type | LOD0 | LOD1 | LOD2 | LOD3 |
|---|---|---|---|---|
| Hero building | 30k | 12k | 4k | 800 |
| Standard enterable building | 8k | 3k | 1k | 300 |
| Background building | 1.5k | 600 | 200 | 50 |
| Held weapon | 8k | — | — | — |
| Hero prop | 2k | 600 | 150 | — |
| Standard prop | 600 | 200 | 60 | — |
| Background prop | 150 | 50 | — | — |
| Player character | 10k | 4k | 1.5k | 400 |
| Walker zombie | 8k | 3k | 1k | 300 |
| Hero tree | 2.5k | 800 | 250 | 50 (billboard) |
| Standard tree | 1.2k | 400 | 120 | 30 |
| Bush | 400 | 150 | 50 | — |
| Driveable sedan | 12k | 4k | 1.2k | — |
| Driveable pickup | 15k | 5k | 1.5k | — |
| Decal | 6 verts | — | — | — |
| Road segment (per 10m) | 200 tris | — | — | — |

### 10.3 Per-biome scene budgets 🔒

Forest is heaviest at ~1M tris on-screen (foliage density). All others ~140-350k. Well under 3M ceiling.

### 10.4 Tiered review strategy 🔒

- Tier 1 (~10 style anchors): individual review, ~1 min each.
- Tier 2 (~80 variant packs): contact sheets, ~3 min each.
- Tier 3 (~900 mass production): auto-validated only.
- Tier 4 (~10 biome milestones): full biome flythrough, ~10 min each.
- Total user review time: ~3 hours across entire alpha.

### 10.5 Communication protocol 🔒

`APPROVE ALL` / `APPROVE EXCEPT <ids>` / `REGEN <ids> WITH <note>` / `REJECT BATCH — <reason>`

### 10.6 Tier 1 production — IN PROGRESS 🔓

| # | Asset | Status | Tris | Notes |
|---|---|---|---|---|
| 1 | suburban_house_v2 | ✅ built + rendered | 1800 | Door bug fixed (red door + garage door visible). 4 angles rendered. |
| 2 | office_chair | ✅ built + rendered | 6500 | 5-star base, gas cylinder, armrests. VLM-verified. |
| 3 | dining_table | ✅ built + rendered | 460 | Rectangular top + 4 legs + apron. VLM-verified. |
| 4 | oak_tree | ✅ built + rendered | 2700 | `branch` primitive trunk + 4-sphere canopy. VLM-verified. |
| 5 | bush | ✅ built + rendered | 360 | 3 leaf clusters + 2 twigs. VLM-verified. |
| 6 | sedan | ⏳ pending | target 12k | Vehicle anchor |
| 7 | pickup_truck | ⏳ pending | target 15k | Vehicle anchor |
| 8 | blood_splatter_decal | ⏳ pending | target 6 verts | Decal anchor |
| 9 | asphalt_road_segment | ⏳ pending | target 200 | Environment anchor |
| 10 | (~fence.mog~ already approved as anchor) | ✅ | 318 | Upstream example — user-approved |

**Contact sheet:** `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-001_contact_sheet.png`

### 10.7 Known issues queue 🔒

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream) | Doors flush with wall (z-fighting), obscured by porch | Author suburban_house_v2 with `wall` primitive holes + recessed door panel + frame | ✅ FIXED in v2 |
| 2 | humanoid.mog (our DSL test) | Reads "Roblox/blocky" per user | Accept for alpha; hybrid for v1 | Accepted |

---

## 11. Lore — SEMI-LOCKED for alpha 🔓

**Full lore document:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, **semi-locked during alpha**)

**What's locked:**
- Overall structure (coastal city, river dividing east/west, monarchy → coup → junta → outbreak)
- The 10 biomes' lore roles
- The 5 factions' high-level goals
- The 12 civic landmarks
- Operation Living Troop as the zombie origin
- Player is one of The Immune

**What can change during alpha:**
- Specific street/district names
- Faction names (Mazar Republic, Junta Remnants, Border Enemy — all adjustable)
- Specific character names (King Amir, General Karim)
- Radio station names
- Specific dialogue and lore fragment texts

**Rationale:** alpha is for testing mechanics, not narrative polish. Names can shift as we discover what feels right through playtesting.

### 11.1 Timeline (semi-locked)

- 300 yr ago → 70 yr ago: Long Peace (House of Mazar monarchy)
- 70 yr ago: Quiet Coup (King Amir abdicated)
- 68-60 yr ago: General Karim's principled regime → rot → house arrest
- 13 yr ago: Border Enemy takes over junta
- 10 yr ago: Operation Living Troop begins
- 2 weeks ago: Fort Sarran lab explosion → leak → contamination
- Day 0 = now: outbreak, city silent, immune alive

---

## 12. Open questions for v5 🔓

1. Survival needs list (subset of PZ's)
2. Combat focus balance (ratios of stealth/guns/melee encounters)
3. Loot richness multipliers per biome
4. Visual palette per biome (locked color swatches)
5. FOV angle (likely 90°, lock it)
6. Number of buildings / POIs per biome (concrete counts)
7. Day-1 sim feasibility (chaos effects scope — story mode feature, not alpha)
8. Co-op technical architecture
9. Sandbox vs story mode launch order

---

## 13. Milestones 🔒

| # | Milestone | Exit criteria |
|---|---|---|
| 0 | Pre-production (this GDD) | All v5 open questions answered |
| 1 | Vertical slice — Suburbia fully playable | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night |
| 2 | Alpha — full map at reduced fidelity | All 10 biomes present, all systems functional |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings |
| 5 | Co-op technical pass | Online architecture validated |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed |

---

## Appendix A — MoGen lessons learned (cumulative)

- MoGen compiles fast. 440-node skyscraper: ~10 ms. 49-node suburban house: 6 ms. 1.8k-tri suburban house v2: 12 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` is broken in this env — replaced with Chrome + three.js + swiftshader.
- `mogen textures` is Gemini-only by design. Need `mogen auth antigravity login` or `GEMINI_API_KEY`. Alternatively `--zai-api-key` for Z.ai's `glm-image`.
- MoGHub community library available — `mogen moghub discover --query chair`.
- DSL is structural, not artistic. Excellent at "house with windows and chimney". Bad at "rotting zombie with torn shirt".
- **The DSL reference is compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).** I read it from disk instead of web-fetching.
- **The `wall` primitive** is the right tool for walls with door/window cutouts — no CSG difference needed. `holes=[cx, cy, w, h]` cuts all the way through Z thickness.
- **The `solid` group** with `cleanup="coplanar"` merges same-material primitives and removes interior faces at export time. Use this for building shells.
- **Floating cluster errors (`E1101`)** are caused by disconnected geometry. Fix by overlapping meshes by ~0.01-0.05m so the `solid` group can merge them at export.
- **`detail=` is not an `icosphere` attribute.** Use `subdivisions=` instead. (1 = low-poly, 2 = default, 3 = high-poly.)
- **The `branch` primitive** is excellent for procedural trees — `form="decurrent"` (broadleaf), `length`, `radius`, `depth`, `splits`, `seed` for variation. Disable `leaves=0` if you want to add your own canopy.
- **Camera yaw convention in our render_glb.html:** yaw=0 looks at the +Z face of the model (back of house). yaw=180 looks at the -Z face (front of house with door). For front views, use yaw=180-225.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v4.md` | **this document** |
| `/home/z/my-project/download/GDD_v3_archive.md` | v3 archived |
| `/home/z/my-project/download/lore_mazar_v1.2.md` | **the semi-locked lore document** |
| `/home/z/my-project/download/poly_budget_v1.md` | **the locked poly budget** |
| `/home/z/my-project/download/asset_review_strategy.md` | tiered asset review strategy |
| `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-001_contact_sheet.png` | **Tier 1 batch 001 contact sheet — for user review** |
| `/home/z/my-project/download/mogen-lookbook/` | 11 PNG renders of MoGen-native output (initial) |
| `/home/z/my-project/assets/buildings/src/suburban_house_v2.mog` | Tier 1 #1 source |
| `/home/z/my-project/assets/buildings/out/suburban_house_v2.glb` | Tier 1 #1 compiled |
| `/home/z/my-project/assets/buildings/renders/suburban_house_v2_*.png` | Tier 1 #1 renders (4 angles) |
| `/home/z/my-project/assets/props/{src,out,renders}/office_chair.*` | Tier 1 #2 |
| `/home/z/my-project/assets/props/{src,out,renders}/dining_table.*` | Tier 1 #3 |
| `/home/z/my-project/assets/foliage/{src,out,renders}/oak_tree.*` | Tier 1 #4 |
| `/home/z/my-project/assets/foliage/{src,out,renders}/bush.*` | Tier 1 #5 |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog |
| `/home/z/my-project/scripts/render_tier1_batch1.js` | batch renderer for Tier 1 |
| `/home/z/my-project/scripts/build_tier1_contact_sheet.py` | contact sheet builder |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference** |
| `/home/z/my-project/upload/large-detailed-map-of-gta-san-andreas.jpg` | the GTA SA map reference |
