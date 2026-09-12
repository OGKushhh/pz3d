# Game Design Document — Halberd Bay (Working Title)

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v2 — pre-production. All foundational systems locked. Lore pending user pick from 3 options. Open items marked 🔓.
> **Inspiration:** Project Zomboid (gameplay loop, tone, permadeath stakes, no-place-is-safe) — but **not** its isometric pixel art. We are doing real 3D.
> **Engine:** Godot 4.x (glTF 2.0 native).
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot).
> **MoGen reference:** `/home/z/my-project/mogen-docs/compiled.md` (single-file compiled docs — no more web fetching).

---

## 1. Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is a hand-authored fictional city and its surrounding countryside — fixed, persistent, hand-crafted, every building enterable. Each run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

Travel is not a loading screen. Travel is exploration. The map uses draw-distance fog, non-trivial road networks, terrain and water as obstacles, landmarks placed far apart, and every town has a reason to stop. The fastest path on the GPS is rarely the safest path.

No place is safe.

**Working title:** *Halberd Bay* (subject to lore confirmation — see §11)

---

## 2. Pillars

1. **Hand-authored world.** Every building has a reason. Procedural interiors (furniture, room layout, prop placement) provide replayability; the exterior shell is fixed.
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters. Generators hum. Footsteps echo.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist. Find your old body, loot your old loot.
4. **Biome identity.** Each of the 10 biomes has a loot focus, difficulty, vibe, weather, and time-cycle identity. You go to the hospital for meds, not for fun.
5. **Travel as exploration.** Not optimization. Roads merge, turn, detour. Water blocks. Forests hide. Mountains force chokepoints.
6. **All three combat modes.** Stealth, guns, melee — all viable, all situational. Shooting is the addictive hook (Valorant-feel), but you don't have to shoot.

---

## 3. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Albedo LLM-drawn via Gemini 2.5 Flash Image; normal/roughness/AO locally-derived (Sobel-from-luminance, variance, cavity). Not pixel art. Not gritty realism. Same neighbourhood as *Night of the Dead* or the cleaner scenes from *The Long Dark*.

**Lookbook:** 11 PNGs at `/home/z/my-project/download/mogen-lookbook/`.

**Known alpha-acceptable issues (fix in v1, not now):**
- Suburban house has a small gap between roof and main body. Geometry clean-up needed.
- DSL humanoid reads "Roblox/blocky". Accepted for alpha; will move to hybrid external-base + MoGen-clothing for v1.

### Comic-book / outline post-processing 🔓

Godot-side decision. Three options:
1. **Inverted hull outline** — duplicate mesh, scale 1.03×, render back-faces solid black. ~1 day. Looks like *Zelda Wind Waker*. **Recommended.**
2. **Screen-space Sobel** — post-process shader on `WorldEnvironment`, edge-detect depth + normal. ~3 days. Looks like *Borderlands*.
3. **Full cel-shading** — banded lighting + hard shadows. ~1 week. Throws away half our PBR textures.

**Plan:** implement option 1 when we lock the palette.

---

## 4. Camera — FIRST-PERSON 🔒

**Locked.** First-person.

Implications:
- Player eye height: 1.65 m
- Standard door: 0.90 m wide × 2.10 m tall
- Standard ceiling: 2.40 m
- Assets must hold up at 0.5 m viewing distance
- Vertically interesting level design (look up at skyscrapers, down into basements)
- LODs matter — kitchens with 30k+ tris of props in view

---

## 5. Characters — DSL HUMANOID FOR ALPHA 🔒

**Locked for alpha.** DSL-authored humanoid via `humanoid.mog`. Blocky, Roblox-adjacent, accepted.

**For v1 (post-alpha):** hybrid approach — external base mesh (Mixamo / Quaternius / Ready Player Me — TBD) + MoGen for clothing and accessories via `bind="<bone_name>"` rigid pinning. Goal: Schedule 1-style modular character creator as a v2 stretch.

---

## 6. World structure — FIXED MAP + PROCEDURAL INTERIORS 🔒

**Locked.** Hand-authored exterior. Procedural interior furniture, rooms, and props.

### 6.1 Map dimensions — LOCKED 🔒

**4.0 km × 3.0 km = 12 km² of playable area** (~40% of GTA San Andreas total map).

Derived from:
- GTA SA full map ≈ 5.5 km × 5.5 km ≈ 30 km² (canonical)
- Los Santos + Red County + Flint County ≈ 42% of total ≈ 12.7 km²
- Rounded to 4 × 3 km for clean grid math

**Player traversal times** (corner-to-corner, ~5 km diagonal):
- Walking (5 km/h): ~60 min (full traversal — too long, hence vehicles)
- Sprinting (8 km/h): ~37 min
- Bicycle (20 km/h): ~15 min
- Car at 60 km/h: ~5 min
- Car at 120 km/h on highway: ~2.5 min

**Grid:** 8 × 6 cells of 500m × 500m. Each cell = 0.25 km². Total 48 cells.

### 6.2 Map design principles (locked) 🔒

1. Draw distance fog — prevents seeing far things. Sells scale. Hides streaming.
2. Non-trivial road network — highways connect regions but require merges, turns, detours, route choices. No trivial ring road.
3. GPS not always fastest — GPS picks a "safe" path; player knows faster dangerous routes.
4. Terrain as obstacle — rivers, lakes, canyons, cliffs, forests block sightlines and direct routes. Water creates real obstacles.
5. Landmarks far apart — placed in opposite corners to sell scale.
6. Every town has a reason to stop — no filler towns.
7. Unique color/weather/time per region — each biome has its own identity.
8. Free-roam interiors — every building enterable.
9. Technical limits as creative constraints — fog, draw distance, streaming budget all become gameplay.
10. Travel = exploration, not optimization.

### 6.3 Biomes (locked — 10 total) 🔒

| # | Biome | Loot Focus | Difficulty | Vibe | Zombie Density | Weather | Base Potential |
|---|---|---|---|---|---|---|---|
| 1 | Industrial Park | Metal, tools, generators, fuel, chemicals, crafting parts, machinery, scrap, industrial batteries | Medium | Grey, rainy, smokestacks, rail yard, warehouses, fences, loading docks | Medium | Industrial smog, acid rain, cold drizzle, low visibility | **High** — strong walls, storage, power, but loud and high traffic |
| 2 | River & Wetlands / Coastal Beach | Fish, clean water, boat fuel, herbs, fishing gear, medical supplies, beach items, canned food, driftwood | Medium | Misty water, bridges, flooded roads, houseboats, quiet danger; beach: abandoned boardwalk, piers, washed-up debris | Low–Medium | Mist, heavy rain, flooding, humid nights, fog, coastal storms | **Low–Medium** — boat access, but wet, disease risk, limited space |
| 3 | Downtown | Best meds, guns, ammo, armor, electronics, rare loot, intel | High–Very High | Dense urban core, neon night, high-rises, sirens, claustrophobia | Very High | Neon night, rain, smog, blackouts, emergency lighting | **Low** — death trap, but great for raids |
| 4 | Subway | Electronics, non-perishable food, flashlight batteries, clean water, tools, rare lore | Medium–High | Narrow tunnels, pitch-black sections, echoes, abandoned stations, claustrophobic | Medium–High, clustered | Underground: damp, dripping, stale air. Entrances match Downtown. | **Low–Medium** — hidden, defensible chokepoints, but dark, damp, limited escape |
| 5 | Suburbia | Food, clothes, tools, batteries, basic meds, family cars, toys, household items | Low | Quiet residential, autumn leaves, broken picket fences, empty driveways | Low–Medium | Mild autumn, overcast, light rain, leaf storms | **High** — starter base, garages, fenced yards, close loot |
| 6 | Parks & Greenways | Water, snacks, gardening tools, seeds, meds, dog food, picnic supplies, fishing gear | Low | Open lawns, walking trails, ponds, playgrounds, peaceful but exposed | Low | Sunny, breezy, morning mist, occasional rain | **Low–Medium** — open sightlines, little cover, but good loot stop |
| 7 | Forest | Wood, herbs, hunting gear, camp supplies, wild food, animal traps, mushrooms | Medium | Dense trees, fog, winding dirt roads, isolation, hidden cabins | Low | Fog, cold rain, early dusk, damp air | **Medium–High** — hidden, resource-rich, hard to reach |
| 8 | Farmland | Crops, seeds, canned goods, fuel, animals, tractor parts, well water, eggs, milk | Low–Medium | Golden fields, barns, silos, lonely roads, wide-open sky | Low | Heat waves, dust, thunderstorms, clear nights | **High** — remote, farmable, defensible with work |
| 9 | Commercial Strip | Meds, food, fuel, weapons, cigarettes, electronics, clothing, cash, tools | Medium–High | Dead shops, neon signs, parking lots, broken glass, loot traps | Medium–High | Overcast, rain, neon reflections, blackouts | **Medium** — good staging point, but noisy and exposed |
| 10 | Military Zone / Quarantine | Military gear, MREs, hazmat suits, radios, advanced meds, weapons, ammo, fuel, generators, intel, keycards | Extreme | Checkpoints, tents, crashed convoy, barbed wire, ash, floodlights, silent dread, abandoned evacuation | Extreme — clustered around checkpoints, elite/military infected, armored zombies | Toxic fog, ashfall, cold wind, unnatural silence, occasional alarm sirens | **Medium but very excluded** — can be cleared, but not sustainable |

**Military Zone placement:** map edge, gated by keycard/quest/radio rumor. One road in, one road out. 1-2 city blocks or one fenced compound. High risk/reward side exploration.

### 6.4 Alpha build order 🔒

1. Suburbia
2. Parks & Greenways
3. Farmland
4. Forest
5. Commercial Strip
6. Industrial Park
7. River & Wetlands / Coastal Beach
8. Subway
9. Downtown
10. Military Zone / Quarantine (last — gated content)

**Logic:** safe rural → risky commercial → industrial → underground → urban endgame → military endgame.

### 6.5 Persistent map + per-run reset 🔒

- **Persistent (carries across runs):** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

### 6.6 Procedural interiors 🔒

- **Fixed:** building exterior shell, room layout (walls), doors, windows, structural props (kitchen counters, bathroom fixtures, built-in shelving).
- **Procedural:** small furniture placement, loot container positions, prop scatter (books, debris, blood decals), zombie patrol routes.

---

## 7. Gameplay systems

### 7.1 Survival needs 🔓

Freedom to design the exact list. Zomboid uses: hunger, thirst, fatigue, panic, boredom, depression, sickness, infection. We will likely adopt a subset.

### 7.2 Combat — STEALTH + GUNS + MELEE, ALL VIABLE 🔒

**Locked.** All three combat modes viable. Situational.

**Shooting = the addictive hook** — Valorant-feel:
- Tight, responsive, low-TTK
- Headshots matter (zombie headshot = instant kill)
- Recoil patterns (learnable, like Valorant spray patterns)
- Movement penalty while aiming
- Audio feedback (each gun has a distinct sound profile — also gameplay-relevant via hearing AI)

**Stealth** — primary survival tool:
- Crouch walk = silent
- Standing walk = audible at 5m
- Running = audible at 20m
- Distract with thrown objects (rocks, bottles)
- Backstab = instant kill on lone zombie
- Line-of-sight breaks = zombie loses you (after investigation)

**Melee** — last resort / silent takedown:
- Stab weapons (knife, screwdriver) = silent, low durability, low range
- Blunt weapons (bat, pipe, hammer) = audible at 5m, medium durability
- Heavy weapons (axe, sledgehammer) = audible at 10m, high durability, slow
- Door barricade breaking = melee combat meta (defend the door)

### 7.3 Hearing-based zombie AI 🔒

**Locked conceptually.** 3D sound propagation, occlusion, noise events. Zombies investigate:
- Gunshots (loud, far carry — 50m+)
- Footsteps (medium, surface-dependent — 5-20m)
- Alarms (loud, sustained)
- Generators (sustained hum — 30m)
- Broken glass (sharp, short — 15m)
- Door barricades being broken (medium, sustained)
- Vehicle engines (loud, mobile source)

Implementation: Godot audio bus + custom sound propagation grid. Each sound event has a position, intensity, and falloff curve. Zombies within hearing range make a navigation decision: ignore / investigate / chase.

### 7.4 Death penalty + meta-progression 🔒

**Roguelite.** Story mode: keep equipped weapons. Lose consumables and materials. Spend resources on permanent upgrades.

**Sandbox mode:** lose everything. Spawn as a new character. Can find your old body with old loot. (Zomboid-true-permadeath spirit.)

**Meta-progression upgrades** (locked concrete numbers):

| Upgrade | Per-level bonus | Max levels |
|---|---|---|
| Movement Speed | +5% | 5 |
| Max Health | +10 HP | 5 |
| Carrying Capacity | +2 slots | 5 |
| Flashlight Battery | +15% duration | 5 |
| Stamina / Noise Reduction | -10% footstep noise | 5 |

Resources to spend: scrap, blood, electronics.

### 7.5 Radio Rumor system 🔒

One run modifier per run. Overrides a specific biome's rules. Sources: emergency broadcasts, survivor radio, faction rumors.

Example: "Quarantine lifted in Industrial Park — zombie density doubled, rare loot doubled." One per run. Huge replay value, low dev cost.

### 7.6 Lore fragments + persistent keys 🔒

Story items persistent across runs. Unlock new areas, endings, base rooms. Long-term goals.

### 7.7 Base / safehouse hub 🔒

Apartment → Base progression. Storage, crafting, medical, radio, specialist ammo station.

**No place is safe.** Bases can be overrun. Player must defend or relocate.

### 7.8 Dynamic spawns + permanent kills 🔒

Killed zombies stay dead (alpha). Cleared areas become safer. (Evaluate zombie respawn in v1.)

### 7.9 Co-op (optional, future) 🔓

Alpha: just make it technically possible (no actual co-op gameplay).
Future: revive downed players, hold-the-gate / vehicle extraction mechanics.

---

## 8. Loot tables (locked pattern) 🔒

### 8.1 Pattern

Per-district fixed loot table. Within the table, rarity is random:
- Common — 60%
- Uncommon — 30%
- Rare — 10%

### 8.2 All 9+ biome tables (locked)

| District | Common (60%) | Uncommon (30%) | Rare (10%) |
|---|---|---|---|
| Hospital (Downtown) | Bandage, Bottled Water | Medkit, Syringe | Stimulant (temp speed boost) |
| Police HQ (Downtown) | Pistol Ammo | Shotgun Ammo | Tier 2 Armor |
| Industrial Park | Scrap Metal, Canned Food | Noise Grenade Parts | Rare Crafting Component |
| Subway | Flashlight Battery, Clean Water | Electronics | Lore Fragment (story item) |
| River & Wetlands | Fish, Driftwood | Boat Fuel | Hermetic Container (rare storage) |
| Suburbia | Canned Food, Batteries | Household Tools | Car Keys (random vehicle) |
| Parks & Greenways | Snacks, Water | Seeds | Fishing Rod |
| Forest | Wood, Herbs | Hunting Gear | Animal Trap |
| Farmland | Crops, Eggs | Fuel Canister | Tractor Parts |
| Commercial Strip | Cash, Snacks | Electronics | Weapon Magazine |
| Military Zone | MRE, Battery | Hazmat Suit | Military Keycard |

### 8.3 Rarity per biome 🔓

Each biome also has a "loot richness" multiplier — Downtown has more rare items rolling than Suburbia. To spec concrete multipliers in v3.

---

## 9. 3D-specific systems 🔓

To design (locked list, details TBD):
- FOV angle (likely 90° for FP combat)
- Line-of-sight checks (raycasts + visibility volumes for AI)
- Sound propagation (occlusion + reverb + noise events)
- Occlusion (rendering culling + gameplay visibility)

---

## 10. Asset production pipeline 🔒

**Contract:** `/home/z/my-project/asset-pipeline/README.md`
**Worklog:** `/home/z/my-project/asset-pipeline/worklog/worklog.md` (append-only, every decision logged)
**Directory:** `/home/z/my-project/assets/{buildings,props,foliage,characters,environment,vehicles,decals}/{src,out,textures,refs}/`

### 10.1 Tiered review strategy 🔒

Full strategy doc at `/home/z/my-project/download/asset_review_strategy.md`. Summary:

- **Tier 1 — Style Anchors (~10 assets):** user reviews every one individually. ~1 min each.
- **Tier 2 — Variant Packs (~80 assets):** user reviews contact sheets of 4-16 thumbnails. ~3 min each.
- **Tier 3 — Mass Production (~900 assets):** no per-asset review. Auto-validated by `mogen check` + VLM sanity check + scale check + palette check. User spot-checks only.
- **Tier 4 — Biome Milestone (~10 reviews):** user reviews assembled biome flythrough. ~10 min each.

**Total user review time:** ~3 hours across the entire alpha build. Not 16 hours.

### 10.2 Batch zip exports 🔒

Every sprint (2 weeks), bundle everything into:
```
/home/z/my-project/download/asset-batches/<date>_<sprint>_<biome>.zip
```

Each batch has:
- `contact_sheet.png` — 16 thumbnails in 4×4 grid
- `manifest.md` — what's in the batch
- `renders/` — full-size PNGs
- `sources/` — .mog source files
- `glbs/` — compiled .glb files

### 10.3 Auto-validation (locked)

Every asset goes through these checks before being shown:
1. `mogen check` — zero diagnostics (mandatory)
2. `mogen build` — must succeed in <100ms
3. Automated VLM sanity check — "is this recognisable as X?"
4. Scale check — bounding box against target dimensions
5. Palette check — material colors against locked swatch (once palette locked)
6. LOD sanity — valid LOD chain or explicit "no LOD needed"

Failed checks → regenerate queue. You never see broken assets.

### 10.4 Communication protocol 🔒

When reviewing a batch, reply with one of:
- `APPROVE ALL` — ship it
- `APPROVE EXCEPT <ids>` — list asset IDs to reject
- `REGEN <ids> WITH <note>` — list asset IDs and what to change
- `REJECT BATCH — <reason>` — nuke the whole batch and rethink

---

## 11. Lore 🔓 — 3 city options drafted

Full lore doc at `/home/z/my-project/download/city_lore_options.md`.

| Option | Setting | Vibe | Fog identity | Water feature | Subway lore | Military Zone lore |
|---|---|---|---|---|---|---|
| **A: Halberd Bay** | Pacific NW coastal naval town | Grey, rainy, naval, fog | ✅✅✅ permanent bay fog | ✅✅✅ central bay | Cold War bunker | Closed naval base (outbreak origin) |
| **B: Carthage** | Gulf Coast port city | Hot, humid, Southern gothic | ✅ | ✅✅✅ Gulf + bayou | 1970s unfinished subway | Old Air Force base |
| **C: Vance Valley** | Appalachian mountain town | Cold, isolated, mining | ✅✅ | ✅ river (linear) | Old coal mines (unique!) | Mining tunnel gates |

**My recommendation: A — Halberd Bay.**

Reasons:
1. Fog identity gets a lore reason (the bay has a permanent fog bank). Every screenshot justifies the locked fog design principle.
2. Bay as central water feature — players always know which way is west.
3. Naval shipyard = organic excuse for Industrial POIs (warehouses, cranes, loading docks, rail yards, containers).
4. Cold War bunker = unique Subway identity (not just generic tunnels).
5. Closed naval base = Military Zone with outbreak-origin story built in.
6. Visual coherence with MoGen native look — stylized low-poly loves overcast, foggy, low-saturation environments.

**Pick one and I'll lock lore + naming conventions in v3.**

---

## 12. Open questions for v3 🔓

1. Lore choice (Halberd Bay / Carthage / Vance Valley / remix)
2. Survival needs list (subset of PZ's)
3. Combat focus balance (stealth vs guns vs melee — locked "all three", but ratios?)
4. Loot richness multipliers per biome
5. Visual palette per biome (locked color swatches)
6. FOV angle (likely 90°, lock it)
7. Number of buildings / POIs per biome (concrete counts)
8. Poly budget per biome (concrete numbers)
9. Day-1 sim feasibility (chaos effects scope)
10. Co-op technical architecture (just enough to not paint ourselves into a corner)

---

## 13. Milestones (high-level, alpha-focused) 🔒

| # | Milestone | Exit criteria |
|---|---|---|
| 0 | Pre-production (this GDD) | All v3 open questions answered |
| 1 | Vertical slice — 1 biome fully playable | Suburbia (first in build order), 5 buildings enterable, 1 weapon, 5 loot items, basic zombie AI, day/night cycle |
| 2 | Alpha — full map at reduced fidelity | All 10 biomes present, all systems functional, no story mode yet |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings |
| 5 | Co-op technical pass | Online architecture validated |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed |

---

## Appendix A — what I learned validating MoGen

- MoGen compiles fast. 440-node skyscraper: ~10 ms. 49-node suburban house: 6 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` is broken in this env (EGL surfaceless can't init without a real DRI device) — replaced with Chrome + three.js + swiftshader, gives better PBR output.
- `mogen textures` is Gemini-only by design. Need `mogen auth antigravity login` or `GEMINI_API_KEY`. Alternatively `--zai-api-key` for Z.ai's `glm-image`.
- MoGHub community library available — `mogen moghub discover --query chair`.
- DSL is structural, not artistic. Excellent at "house with windows and chimney". Bad at "rotting zombie with torn shirt". This is why characters stay simple for alpha.
- **The DSL reference is now compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).** I read it from disk instead of web-fetching every time.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v2.md` | this document |
| `/home/z/my-project/download/GDD_v1_archive.md` | the v1 draft (archived) |
| `/home/z/my-project/download/GDD_v0_archive.md` | the v0 draft (archived) |
| `/home/z/my-project/download/city_lore_options.md` | 3 city lore concepts with comparison |
| `/home/z/my-project/download/asset_review_strategy.md` | tiered asset review strategy |
| `/home/z/my-project/download/mogen-lookbook/` | 11 PNG renders of MoGen-native output |
| `/home/z/my-project/asset-pipeline/README.md` | asset pipeline contract |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog of every decision |
| `/home/z/my-project/assets/{buildings,props,...}/` | the curated asset library |
| `/home/z/my-project/scripts/render_with_chrome.js` | PBR renderer (three.js + Chrome) |
| `/home/z/my-project/scripts/gl_renderer/render_glb.html` | the render page |
| `/home/z/my-project/mogen-examples/` | the upstream example `.mog` files |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference (1559 lines)** |
| `/home/z/my-project/upload/large-detailed-map-of-gta-san-andreas.jpg` | the GTA SA map reference |
