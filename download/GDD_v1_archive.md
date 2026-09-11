# Game Design Document — Working Title TBD

> **Format:** Markdown. First-person (the designer = me, speaking to the team).
> **Status:** v1 — pre-production. Most foundational decisions locked. Open items marked 🔓.
> **Inspiration:** Project Zomboid (gameplay loop, tone, permadeath stakes, no-place-is-safe) — but **not** its isometric pixel art. We are doing real 3D.
> **Engine:** Godot 4.x (glTF 2.0 native).
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot).

---

## 1. Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is a hand-authored fictional city and its surrounding countryside — fixed, persistent, hand-crafted, every building enterable. Each run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

Travel is not a loading screen. Travel is exploration. The map uses draw-distance fog, non-trivial road networks, terrain and water as obstacles, landmarks placed far apart, and every town has a reason to stop. The fastest path on the GPS is rarely the safest path.

No place is safe.

---

## 2. Pillars

1. **Hand-authored world.** Every building has a reason. Procedural interiors (furniture, room layout, prop placement) provide replayability; the exterior shell is fixed.
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters. Generators hum. Footsteps echo.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist. Find your old body, loot your old loot.
4. **Biome identity.** Each of the 9 biomes has a loot focus, difficulty, vibe, weather, and time-cycle identity. You go to the hospital for meds, not for fun.
5. **Travel as exploration.** Not optimization. Roads merge, turn, detour. Water blocks. Forests hide. Mountains force chokepoints.

---

## 3. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Albedo LLM-drawn via Gemini 2.5 Flash Image; normal/roughness/AO locally-derived (Sobel-from-luminance, variance, cavity). Not pixel art. Not gritty realism. Same neighbourhood as *Night of the Dead* or the cleaner scenes from *The Long Dark*.

**Lookbook:** 11 PNGs at `/home/z/my-project/download/mogen-lookbook/`. Key reference renders:
- `suburban_house.png` — proof of concept for environment art
- `humanoid.png` — proof of DSL character (acceptable for alpha, will revisit)

**Known alpha-acceptable issues (fix in v1, not now):**
- Suburban house has a small gap between roof and main body. Geometry clean-up needed.
- DSL humanoid reads "Roblox/blocky". Accepted for alpha; will move to hybrid external-base + MoGen-clothing for v1.

### Comic-book / outline post-processing 🔓

Godot-side decision, not MoGen. Three options considered:

1. **Inverted hull outline** — duplicate mesh, scale 1.03×, render back-faces solid black. ~1 day. Looks like *Zelda Wind Waker*. **Recommended.**
2. **Screen-space Sobel** — post-process shader on `WorldEnvironment`, edge-detect depth + normal. ~3 days. Looks like *Borderlands*.
3. **Full cel-shading** — banded lighting + hard shadows. ~1 week. Throws away half our PBR textures.

**Plan:** implement option 1 when we lock the palette. Upgrade to option 2 only if option 1 looks weak with our actual textured assets.

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

**Why DSL is fine for alpha:** the map, environment, and props are the priority. Characters are visible but not the focus. Once the world is built, we revisit characters.

---

## 6. World structure — FIXED MAP + PROCEDURAL INTERIORS 🔒

**Locked.** Hand-authored exterior. Procedural interior furniture, rooms, and props.

### 6.1 Map reference — GTA San Andreas (Los Santos + Red County + Flint County target)

User uploaded `large-detailed-map-of-gta-san-andreas.jpg` as the structural reference. VLM-extracted principles:

- **Tri-city model:** GTA SA places 3 cities at different corners to maximize travel time. **Our alpha: 1 city only** (Los Santos equivalent) + 2 rural counties (Red County + Flint County equivalents). Expansion to tri-city is post-alpha.
- **Biome transitions:** space between POIs is for environmental storytelling.
- **Natural barriers:** mountains and water force chokepoints (bridges, tunnels) for gameplay flow.
- **Grid vs organic:** strict grids in dense urban, winding roads in coastal/rural.
- **Rural > urban by area:** rural areas significantly larger than urban to sell scale + wilderness.
- **Hierarchy of roads:** highways connecting regions (loop system), surface streets local, bridges as critical infrastructure.

### 6.2 Map design principles (locked) 🔒

1. **Draw distance fog** — prevents seeing far things. Sells scale. Hides streaming.
2. **Non-trivial road network** — highways connect regions but require merges, turns, detours, route choices. No trivial ring road.
3. **GPS not always fastest** — GPS picks a "safe" path, but the player knows a faster route that's more dangerous.
4. **Terrain as obstacle** — rivers, lakes, canyons, cliffs, forests block sightlines and direct routes. Water creates real obstacles.
5. **Landmarks far apart** — placed in opposite corners to sell scale.
6. **Every town has a reason to stop** — no filler towns. Loot, story, NPC, or tactical reason.
7. **Unique color/weather/time per region** — each biome has its own identity.
8. **Free-roam interiors** — every building enterable.
9. **Technical limits as creative constraints** — fog, draw distance, streaming budget all become gameplay.
10. **Travel = exploration, not optimization.**

### 6.3 Map size

**Target:** medium. Approximately Los Santos + Red County + Flint County from GTA SA (≈ 1/3 of full GTA SA map).

**Exact dimensions:** 🔓 to spec — I'll measure the GTA SA reference and propose concrete km × km numbers in v2.

### 6.4 Biomes (locked — 9 total) 🔒

| # | Biome | One-line identity |
|---|---|---|
| 1 | Industrial Park | Warehouses, factories, fuel depots, container yards |
| 2 | River & Wetlands / coastal beach | Water-locked, swampy, fog-prone, isolated shacks |
| 3 | Downtown | High-rises, dense zombies, verticality, hospital/police/skyscrapers |
| 4 | Subway | Underground tunnels, dark, no weather, electrical hazards |
| 5 | Suburbia | Houses with yards, fences, low zombie density but high interiors |
| 6 | Parks & Greenways | Open green space, low cover, snipers' paradise, wildlife |
| 7 | Forest | Dense trees, no roads, navigation by landmarks, cabins |
| 8 | Farmland | Open fields, silos, barns, low density but high visibility |
| 9 | Commercial Strip | Shops, malls, diners, gas stations — high loot density |

### 6.5 Per-biome spec template (to fill per biome)

Each biome needs:
- **Loot focus** — what players come here to find
- **Difficulty** (1-5) — combat / navigation / resource pressure
- **Vibe** — 1-2 sentence mood
- **Zombie density** — low / medium / high / swarm
- **Weather/time-cycle identity** — e.g. "always overcast", "foggy mornings"
- **Key POIs** — 3-5 named landmarks
- **Base potential** — yes/no + why

🔓 All 9 biome specs to be filled in v2 of this GDD.

### 6.6 Persistent map + per-run reset 🔒

- **Persistent (carries across runs):** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

### 6.7 Procedural interiors 🔒

- **Fixed:** building exterior shell, room layout (walls), doors, windows, structural props (kitchen counters, bathroom fixtures, built-in shelving).
- **Procedural:** small furniture placement (chairs, tables, lamps, decoration props), loot container positions, prop scatter (books, debris, blood decals), zombie patrol routes.

This gives replayability without losing hand-authored identity. Players learn the hospital's layout; they don't know which room has the stimulant this run.

---

## 7. Gameplay systems

### 7.1 Survival needs (PZ-like, locked conceptually) 🔓

Freedom to design the exact list. Zomboid uses: hunger, thirst, fatigue, panic, boredom, depression, sickness, infection. We will likely adopt a subset.

### 7.2 Combat 🔓

Open question: stealth-first (PZ), gun-heavy (7DtD), or melee-first (State of Decay). User still deciding.

### 7.3 Hearing-based zombie AI 🔒

**Locked conceptually.** 3D sound propagation, occlusion, noise events. Zombies investigate:
- Gunshots (loud, far carry)
- Footsteps (medium, surface-dependent)
- Alarms (loud, sustained)
- Generators (sustained hum)
- Broken glass (sharp, short)
- Door barricades being broken (medium, sustained)

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

One run modifier per run. Overrides a specific biome's rules. Sources:
- Emergency broadcasts (radio)
- Survivor radio (NPC)
- Faction rumors (NPC)

Example: "Quarantine lifted in Industrial Park — zombie density doubled, rare loot doubled." One per run. Huge replay value, low dev cost.

### 7.6 Lore fragments + persistent keys 🔒

Story items persistent across runs. Unlock new areas, endings, base rooms. Long-term goals.

### 7.7 Base / safehouse hub 🔒

Apartment → Base progression. Storage, crafting, medical, radio, specialist ammo station.

**No place is safe.** Bases can be overrun. Player must defend or relocate.

### 7.8 Dynamic spawns + permanent kills 🔒

Killed zombies stay dead (alpha). Cleared areas become safer. (We'll evaluate zombie respawn in v1; for alpha, kills are permanent.)

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

### 8.2 Example tables (user-provided)

| District | Common (60%) | Uncommon (30%) | Rare (10%) |
|---|---|---|---|
| Hospital | Bandage, Bottled Water | Medkit, Syringe | Stimulant (temp speed boost) |
| Police HQ | Pistol Ammo | Shotgun Ammo | Tier 2 Armor |
| Industrial | Scrap Metal, Canned Food | Noise Grenade Parts | Rare Crafting Component |
| Subway | Flashlight Battery, Clean Water | Electronics | Lore Fragment (story item) |

🔓 Remaining 5 biome tables to spec in v2.

---

## 9. 3D-specific systems 🔓

To design (locked list, details TBD):
- FOV angle (likely 75-90°)
- Line-of-sight checks (raycasts + visibility volumes for AI)
- Sound propagation (occlusion + reverb + noise events)
- Occlusion (rendering culling + gameplay visibility)

---

## 10. Asset production pipeline 🔒

**Contract:** `/home/z/my-project/asset-pipeline/README.md`
**Worklog:** `/home/z/my-project/asset-pipeline/worklog/worklog.md` (append-only, every decision logged)
**Directory:** `/home/z/my-project/assets/{buildings,props,foliage,characters,environment,vehicles,decals}/{src,out,textures,refs}/`

**Roles:**
- **User:** describes intent, approves / rejects renders, locks style decisions.
- **Me (AI):** writes `.mog` DSL, validates, builds GLB, renders preview PNG via Chrome + three.js + swiftshader, iterates by editing `.mog` in place, generates PBR textures after geometry approval.

**Loop:** describe → draft `.mog` → `mogen check` → `mogen build` → render PNG → review → iterate or texture → publish.

**MoGHub community library** available for browse/fork/publish. We don't publish without explicit approval.

---

## 11. Lore 🔓

City name: undecided. Fictional. Not real-world.
Time horizon: day-1 sim undecided (chaos effects complexity concern). Sandbox first. Story mode later, spanning day-1 to 10 years.

---

## 12. Open questions for v2 🔓

1. City name (lore)
2. Exact map dimensions (km × km) — derive from GTA SA reference
3. Number of buildings / POIs per biome
4. Poly budget per biome
5. Visual palette per biome (locked color swatches)
6. Combat focus: stealth / guns / melee
7. Survival needs list (subset of PZ's)
8. All 9 biome specs (loot focus, difficulty, vibe, zombie density, weather, POIs, base potential)
9. Remaining 5 loot tables (Subway done, Hospital done, Police done, Industrial done — 5 left: River/Wetlands, Downtown, Suburbia, Parks, Forest, Farmland, Commercial Strip)
10. Day-1 sim feasibility (chaos effects scope)
11. Co-op technical architecture (just enough to not paint ourselves into a corner)

---

## 13. Milestones (high-level, alpha-focused)

| # | Milestone | Exit criteria |
|---|---|---|
| 0 | Pre-production (this GDD) | All v2 open questions answered |
| 1 | Vertical slice — 1 biome fully playable | 1 biome, 5 buildings enterable, 1 weapon, 5 loot items, basic zombie AI, day/night cycle |
| 2 | Alpha — full map at reduced fidelity | All 9 biomes present, all systems functional, no story mode yet |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings |
| 5 | Co-op technical pass | Online architecture validated |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed |

---

## Appendix A — what I learned validating MoGen

- MoGen compiles fast. 440-node skyscraper: ~10 ms. 49-node suburban house: 6 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` is broken in this env (EGL surfaceless can't init without a real DRI device) — we replaced it with Chrome + three.js + swiftshader, which gives better PBR output anyway.
- `mogen textures` is Gemini-only by design. When we're ready to texture, we need `mogen auth antigravity login` or `GEMINI_API_KEY`. Alternatively, `--zai-api-key` for Z.ai's `glm-image`.
- MoGHub community library is available — `mogen moghub discover --query chair`.
- DSL is structural, not artistic. Excellent at "house with windows and chimney". Bad at "rotting zombie with torn shirt". This is why characters stay simple for alpha.
- The DSL reference is 2059 lines. User will compile it into a single file in my env at `/home/z/my-project/mogen-docs/compiled.md` so I stop web-fetching.

## Appendix B — file map

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v1.md` | this document |
| `/home/z/my-project/download/GDD_v0_archive.md` | the v0 draft (decision log only) |
| `/home/z/my-project/download/mogen-lookbook/` | 11 PNG renders of MoGen-native output |
| `/home/z/my-project/asset-pipeline/README.md` | asset pipeline contract |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog of every decision |
| `/home/z/my-project/assets/{buildings,props,...}/` | the curated asset library |
| `/home/z/my-project/scripts/render_with_chrome.js` | PBR renderer (three.js + Chrome) |
| `/home/z/my-project/scripts/gl_renderer/render_glb.html` | the render page |
| `/home/z/my-project/mogen-examples/` | the upstream example `.mog` files |
| `/home/z/my-project/upload/large-detailed-map-of-gta-san-andreas.jpg` | the GTA SA map reference |
| `/home/z/my-project/mogen-docs/compiled.md` | 🔓 user will drop the compiled MoGen docs here |
