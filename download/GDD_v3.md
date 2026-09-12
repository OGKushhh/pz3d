# Game Design Document — Republic of Mazar (Alpha)

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v3 — pre-production. Lore locked. Most systems locked. Open items marked 🔓.
> **Working title:** *Mazar* (subject to refinement)
> **Lore document:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, LOCKED)
> **Inspiration:** Project Zomboid (gameplay loop, tone, permadeath, no-place-is-safe) — not its isometric pixel art. Real 3D.
> **Engine:** Godot 4.x (glTF 2.0 native).
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

**Lookbook:** 11 PNGs at `/home/z/my-project/download/mogen-lookbook/`.

**Known alpha-acceptable issues (fix in v1, not now):**
- Suburban house has a door bug — the door meshes are flush with the wall (z-fighting) and the porch obscures them from the front. Confirmed via VLM. **Fix in Tier 1 asset #1 (suburban house v2)** by recessing doors into the wall with a proper frame.
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

**For v1 (post-alpha):** hybrid approach — external base mesh (Mixamo / Quaternius / Ready Player Me — TBD) + MoGen for clothing and accessories via `bind="<bone_name>"` rigid pinning. Goal: Schedule 1-style modular character creator as a v2 stretch.

**Lore justification for the player character:** the player is one of "The Immune" — individuals whose bodies rejected or never encountered the Living Troop liquid. This is why you're alive. This is why you can survive.

---

## 6. World structure — FIXED MAP + PROCEDURAL INTERIORS 🔒

### 6.1 Map dimensions — LOCKED 🔒

**4.0 km × 3.0 km = 12 km² of playable area** (~40% of GTA San Andreas total map).

Derived from:
- GTA SA full map ≈ 5.5 km × 5.5 km ≈ 30 km²
- Los Santos + Red County + Flint County ≈ 42% of total ≈ 12.7 km²
- Rounded to 4 × 3 km

**Grid:** 8 × 6 cells of 500m × 500m. Each cell = 0.25 km². Total 48 cells.

**Player traversal times** (corner-to-corner, ~5 km diagonal):
- Walking (5 km/h): ~60 min (too long — hence vehicles)
- Sprinting (8 km/h): ~37 min
- Bicycle (20 km/h): ~15 min
- Car at 60 km/h: ~5 min
- Car at 120 km/h on highway: ~2.5 min

### 6.2 Map geography — LOCKED via lore 🔒

The Sarran River flows from the northern Forest through the Farmland and into Sarran Bay. The bay is west of the city. The river splits the city into east and west. Bridges are chokepoints. Water is a barrier.

**West Side (5 biomes):**
- Suburbia — middle-class homes from the Long Peace, now empty
- Parks & Greenways — old public gardens, walking trails, playgrounds
- Commercial Strip — once-bustling bazaars and shops, now looted
- Farmland — Mazar's food basket: olive groves, wheat, irrigation canals
- Forest — the border region, enemy infiltration routes, hidden bunkers

**East Side (4 biomes):**
- Industrial Park — manufacturing and rail, junta outposts here
- River & Wetlands / Coastal Beach — fishing villages, smuggling routes, the bay, the lighthouse
- Downtown — the capital district: hospital, police HQ, government palace
- Military Zone / Quarantine — ground zero, Operation Living Troop lab, Fort Sarran

**Underground (1 biome, spans both sides):**
- Subway — public transit + secret military transport tunnels

### 6.3 Map design principles (locked) 🔒

1. Draw distance fog — prevents seeing far things. Sells scale. Hides streaming. **Lore-justified:** the fog rolling in after the leak is permanent weather.
2. Non-trivial road network — highways connect regions but require merges, turns, detours. No trivial ring road.
3. GPS not always fastest — GPS picks a "safe" path; player knows faster dangerous routes.
4. Sarran River as obstacle — water creates real barriers. Bridges are chokepoints.
5. Landmarks far apart — placed in opposite corners to sell scale.
6. Every town has a reason to stop — no filler towns.
7. Unique color/weather/time per biome — each biome has its own identity.
8. Free-roam interiors — every building enterable.
9. Technical limits as creative constraints — fog, draw distance, streaming budget all become gameplay.
10. Travel = exploration, not optimization.

### 6.4 The 10 Biomes — LOCKED via lore 🔒

Full biome table in lore document Part Nine. Summary:

| # | Biome | Lore Role | Difficulty | Zombie Density | Base Potential |
|---|---|---|---|---|---|
| 1 | Suburbia | Middle-class homes from the Long Peace. Now empty. | Low | Low–Medium | **High** — starter base |
| 2 | Parks & Greenways | Old public gardens, walking trails, playgrounds. | Low | Low | **Low–Medium** |
| 3 | Forest | Border region. Enemy infiltration routes. Hidden bunkers. | Medium | Low | **Medium–High** — hidden base |
| 4 | Farmland | Mazar's food basket. Olive groves, wheat, irrigation canals. | Low–Medium | Low | **High** — remote farm base |
| 5 | Commercial Strip | Once-bustling bazaars and shops. Now looted. | Medium–High | Medium–High | **Medium** — staging point |
| 6 | Industrial Park | Manufacturing and rail. Junta outposts here. | Medium | Medium | **High** — strong base |
| 7 | River & Wetlands / Coastal Beach | Fishing villages, smuggling routes, the bay, the lighthouse. | Medium | Low–Medium | **Low–Medium** — boat access |
| 8 | Subway | Public transit + secret military transport tunnels. | Medium–High | Medium–High (clustered) | **Low–Medium** — hidden, defensible |
| 9 | Downtown | Capital district. Hospital, police HQ, government buildings. | High–Very High | Very High | **Low** — death trap, great for raids |
| 10 | Military Zone / Quarantine | Ground zero. Operation Living Troop lab. Fort Sarran. | Extreme | Extreme | **None** — endgame raid only |

**Military Zone placement:** eastern edge of the city (Fort Sarran is on the eastern edge per lore). Gated by keycard/quest/radio rumor. One road in, one road out. 1-2 city blocks or one fenced compound. High risk/reward side exploration.

### 6.5 Alpha build order 🔒

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

### 6.6 Persistent map + per-run reset 🔒

- **Persistent (carries across runs):** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

### 6.7 Procedural interiors 🔒

- **Fixed:** building exterior shell, room layout (walls), doors, windows, structural props (kitchen counters, bathroom fixtures, built-in shelving).
- **Procedural:** small furniture placement, loot container positions, prop scatter (books, debris, blood decals), zombie patrol routes.

### 6.8 Civic landmarks — LOCKED via lore 🔒

**No religious buildings.** Mazar's landmarks are civic:

1. The Lighthouse (River & Wetlands / Coastal Beach)
2. The Water Tower (Industrial Park)
3. The Grain Silo (Farmland)
4. The Hospital (Downtown)
5. The Police HQ (Downtown)
6. The Government Palace — now junta HQ (Downtown)
7. The Stadium (Downtown)
8. The Old Royal Palace — abandoned, sealed (Downtown or Suburbia edge)
9. The Naval Fort — Fort Sarran (Military Zone)
10. The Broadcast Tower (Downtown or Industrial)
11. The Railway Station (Industrial Park)
12. The Grand Bazaar / Souq (Commercial Strip)

Each landmark is a navigation aid visible from afar — sells scale, gives direction.

---

## 7. Gameplay systems

### 7.1 Survival needs 🔓

Zomboid uses: hunger, thirst, fatigue, panic, boredom, depression, sickness, infection. We will likely adopt a subset. To spec in v4.

### 7.2 Combat — STEALTH + GUNS + MELEE, ALL VIABLE 🔒

**Locked.** All three combat modes viable. Situational.

**Shooting = the addictive hook** — Valorant-feel:
- Tight, responsive, low-TTK
- Headshots matter (zombie headshot = instant kill)
- Recoil patterns (learnable, like Valorant spray patterns)
- Movement penalty while aiming
- Audio feedback (each gun has a distinct sound profile — also gameplay-relevant via hearing AI)

**Stealth — primary survival tool:**
- Crouch walk = silent
- Standing walk = audible at 5m
- Running = audible at 20m
- Distract with thrown objects (rocks, bottles)
- Backstab = instant kill on lone zombie
- Line-of-sight breaks = zombie loses you (after investigation)

**Melee — last resort / silent takedown / door defense:**
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

### 7.4 Zombies — LOCKED via lore 🔒

| Type | Behavior |
|---|---|
| **Walker** | Slow shamble. Sight cone, hearing radius, short memory. The default. |
| **Crawlers** | Legs destroyed. Slow, quiet, easy to miss. Bite from the ground. |
| **Groups** | Noise pulls nearby zombies. Hordes form slowly. No coordination. |
| **Memory** | ~10 seconds. Investigate, then forget. |

**Lore justification:** the Living Troop liquid overloaded nervous systems — hearts stopped, brains died, bodies rose. The undead consume energy at a fraction of human rate, can go weeks without feeding. They are not fast, not smart, not coordinated. They are relentless.

### 7.5 Death penalty + meta-progression 🔒

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

### 7.6 Radio Rumor system 🔒

One run modifier per run. Overrides a specific biome's rules.

**Locked radio stations** (via lore):

| Station | Faction | Broadcast Style |
|---|---|---|
| **Voice of Mazar** | Mazar Republic | Coded messages, election plans, anti-junta propaganda |
| **Radio Junta** | Junta Remnants | Curfews, false safety, martial law announcements |
| **Free Bay FM** | Survivors | Distress calls, supply tips, safe route warnings |
| **The Border Signal** | Border Enemy | Foreign language, jamming, encrypted transmissions |

### 7.7 Factions — LOCKED via lore 🔒

| Faction | Goal | Relationship |
|---|---|---|
| **Mazar Republic** | Hold real elections. Restore political peace. End military rule. | Enemy of Junta, enemy of Border Enemy |
| **Junta Remnants** | Hold power. Cover up Operation Living Troop. | Allied with Border Enemy, suspicious of Survivors |
| **Border Enemy** | Recover the liquid. Weaponize it. | Allied with Junta, enemy of Survivors and Mazar Republic |
| **Survivors** | Stay alive. Help each other. | Neutral |
| **The Immune** | Not a faction. Random individuals with natural or partial resistance. | Scattered, unorganized — **the player is one of these** |

### 7.8 Lore fragments + persistent keys 🔒

Scattered across biomes and the Subway. Persistent across runs. They reveal:
- The truth about Operation Living Troop
- The Border Enemy's involvement
- The junta's cover-up
- The fate of the last monarch (King Amir)
- The identity of the immune
- The location of the lab (Fort Sarran)
- The secret Subway transport routes

### 7.9 Base / safehouse hub 🔒

Apartment → Base progression. Storage, crafting, medical, radio, specialist ammo station.

**No place is safe.** Bases can be overrun. Player must defend or relocate.

### 7.10 Dynamic spawns + permanent kills 🔒

Killed zombies stay dead (alpha). Cleared areas become safer. (Evaluate zombie respawn in v1.)

### 7.11 Co-op (optional, future) 🔓

Alpha: just make it technically possible (no actual co-op gameplay).
Future: revive downed players, hold-the-gate / vehicle extraction mechanics.

---

## 8. Loot tables (locked pattern) 🔒

### 8.1 Pattern

Per-district fixed loot table. Within the table, rarity is random:
- Common — 60%
- Uncommon — 30%
- Rare — 10%

### 8.2 All 10 biome loot tables (locked)

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

Each biome also has a "loot richness" multiplier — Downtown has more rare items rolling than Suburbia. To spec concrete multipliers in v4.

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
- **Tier 3 — Mass Production (~900 assets):** no per-asset review. Auto-validated. User spot-checks only.
- **Tier 4 — Biome Milestone (~10 reviews):** user reviews assembled biome flythrough. ~10 min each.

**Total user review time:** ~3 hours across entire alpha.

### 10.2 Batch zip exports 🔒

Every sprint (2 weeks), bundle everything into:
```
/home/z/my-project/download/asset-batches/<date>_<sprint>_<biome>.zip
```

Each batch has: contact sheet + manifest + renders + sources + GLBs.

### 10.3 Auto-validation (locked) 🔒

Every asset goes through:
1. `mogen check` — zero diagnostics
2. `mogen build` — must succeed in <100ms
3. VLM sanity check — "is this recognisable as X?"
4. Scale check — bounding box vs target dimensions
5. Palette check — material colors vs locked swatch (once palette locked)
6. LOD sanity — valid LOD chain or explicit "no LOD needed"

### 10.4 Communication protocol 🔒

When reviewing a batch, reply with one of:
- `APPROVE ALL` — ship it
- `APPROVE EXCEPT <ids>` — list asset IDs to reject
- `REGEN <ids> WITH <note>` — list asset IDs and what to change
- `REJECT BATCH — <reason>` — nuke the whole batch and rethink

### 10.5 Known issues queue (to fix in Tier 1 production)

| # | Asset | Issue | Fix |
|---|---|---|---|
| 1 | suburban_house.mog (upstream example) | Doors are flush with wall (z-fighting), obscured by porch. VLM-confirmed: front view shows no door. | In our v2: recess door 5cm into wall, add door frame (trim), ensure porch doesn't occlude door from front view. |
| 2 | humanoid.mog (our DSL test) | Reads "Roblox/blocky" per user. | Accepted for alpha. Hybrid (external base + MoGen clothing) for v1. |

---

## 11. Lore — LOCKED 🔒

**Full lore document:** `/home/z/my-project/download/lore_mazar_v1.2.md` (v1.2, LOCKED)

### 11.1 Setting

The Republic of Mazar — a coastal nation on the edge of a forgotten sea. Capital: the National City of Mazar, on a wide bay where the Sarran River meets the ocean.

### 11.2 Timeline

- **300 years ago → 70 years ago:** The Long Peace. House of Mazar monarchy. Tolerant, stable, prosperous.
- **70 years ago:** The Quiet Coup. King Amir abdicated to avoid civil war. Military took power.
- **68-60 years ago:** General Karim's principled regime, then rot. He was placed under house arrest by his own officers.
- **13 years ago:** The Border Enemy (northern neighbor) bought the latest junta leader. Mazar became a staging ground.
- **10 years ago:** Operation Living Troop began. Secret military experiment to create supersoldiers. The liquid worked — but it killed subjects and raised them as undead.
- **2 weeks ago:** The lab at Fort Sarran exploded. Liquid leaked into drainage, sewer, drinking water, river. The fog rolled in. The rain fell. The water was poison.
- **Day 0 = now:** The city is silent. The dead walk. The immune (including the player) are alive for reasons no one understands.

### 11.3 Naming conventions — LOCKED 🔒

**Streets:**
- King's Way, Coup Avenue, Martyrs' Road, Unity Boulevard, Harbor Street, Olive Lane, Bunker Road, Sarran Street

**Districts:**
- Al-Salam (Peace), Al-Nour (Light), Al-Minar (Lighthouse), Old Town, New Town, New Mazar, Fort Quarter, Sarran District

**Radio:**
- Voice of Mazar, Radio Junta, Free Bay FM, The Border Signal

**Key figures:**
- King Amir of House Mazar (last monarch, exiled, fate unknown)
- General Karim (first junta leader, principled, died under house arrest)

**Key locations:**
- Fort Sarran (the lab, outbreak origin, Military Zone)
- Sarran Bay (west of city)
- Sarran River (divides city east/west)
- Sarran Bridge (main crossing)
- The Old Royal Palace (abandoned, sealed — lore fragment location)

---

## 12. Open questions for v4 🔓

1. Survival needs list (subset of PZ's)
2. Combat focus balance (ratios of stealth/guns/melee encounters)
3. Loot richness multipliers per biome
4. Visual palette per biome (locked color swatches)
5. FOV angle (likely 90°, lock it)
6. Number of buildings / POIs per biome (concrete counts)
7. Poly budget per biome (concrete numbers)
8. Day-1 sim feasibility (chaos effects scope — story mode feature, not alpha)
9. Co-op technical architecture
10. Sandbox vs story mode launch order

---

## 13. Milestones (high-level, alpha-focused) 🔒

| # | Milestone | Exit criteria |
|---|---|---|
| 0 | Pre-production (this GDD) | All v4 open questions answered |
| 1 | Vertical slice — 1 biome fully playable | Suburbia (first in build order), 5 buildings enterable, 1 weapon, 5 loot items, basic zombie AI (Walker), day/night cycle |
| 2 | Alpha — full map at reduced fidelity | All 10 biomes present, all systems functional, no story mode yet |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings |
| 5 | Co-op technical pass | Online architecture validated |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed |

---

## Appendix A — what I learned validating MoGen

- MoGen compiles fast. 440-node skyscraper: ~10 ms. 49-node suburban house: 6 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` is broken in this env (EGL surfaceless) — replaced with Chrome + three.js + swiftshader, gives better PBR output.
- `mogen textures` is Gemini-only by design. Need `mogen auth antigravity login` or `GEMINI_API_KEY`. Alternatively `--zai-api-key` for Z.ai's `glm-image`.
- MoGHub community library available — `mogen moghub discover --query chair`.
- DSL is structural, not artistic. Excellent at "house with windows and chimney". Bad at "rotting zombie with torn shirt". This is why characters stay simple for alpha.
- **The DSL reference is compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).** I read it from disk instead of web-fetching every time.
- **The upstream `suburban_house.mog` has a door visibility bug** — doors are flush with wall, obscured by porch. Confirmed via front-view render + VLM. Will fix in our Tier 1 v2.
- **The upstream `fence.mog` is good** — user confirmed. 44 nodes, 318 tris, 31 meshes, 3 materials. Will use as Tier 1 style anchor for environment props.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v3.md` | **this document** |
| `/home/z/my-project/download/GDD_v2_archive.md` | v2 archived |
| `/home/z/my-project/download/GDD_v1_archive.md` | v1 archived |
| `/home/z/my-project/download/GDD_v0_archive.md` | v0 archived |
| `/home/z/my-project/download/lore_mazar_v1.2.md` | **the locked lore document** |
| `/home/z/my-project/download/city_lore_options.md` | the 3 options I drafted (superseded by lore_mazar — kept for reference) |
| `/home/z/my-project/download/asset_review_strategy.md` | tiered asset review strategy |
| `/home/z/my-project/download/mogen-lookbook/` | 11 PNG renders of MoGen-native output |
| `/home/z/my-project/download/mogen-lookbook/suburban_house_front_door_check.png` | front-view render proving the door bug |
| `/home/z/my-project/asset-pipeline/README.md` | asset pipeline contract |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog of every decision |
| `/home/z/my-project/assets/{buildings,props,...}/` | the curated asset library |
| `/home/z/my-project/scripts/render_with_chrome.js` | PBR renderer (three.js + Chrome) |
| `/home/z/my-project/scripts/gl_renderer/render_glb.html` | the render page |
| `/home/z/my-project/mogen-examples/` | the upstream example `.mog` files |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference (1559 lines)** |
| `/home/z/my-project/upload/large-detailed-map-of-gta-san-andreas.jpg` | the GTA SA map reference |
