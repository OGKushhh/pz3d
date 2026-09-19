# MAZAR — Roadmap

> **Last updated:** 2026-09-19 (session 13 — Cogito integration + style guide + weapon refactor)
> **Map:** LOCKED at 12 km² (4km × 3km). See GDD §4.1.
> **Architecture:** Baked .tscn chunks + Cogito immersive sim framework (extends, not forks).

---

## CURRENT STATE (2026-09-19)

### What's done this session
- ✅ City gen: map_baker.gd produces 192 chunk .tscn files + baked_world.tscn
- ✅ Post-bake cleanup: 99.9% overlaps removed
- ✅ Per-biome debug ground colors (XIII-style palette)
- ✅ POI nudging off roads
- ✅ Per-biome gap filler variety (10 biome-specific prop pools)
- ✅ PPS Shooter Essentials integrated (ZC57 pistol + MGP7 rifle + attachments)
- ✅ Quality FPS Controller addon installed (addons/fpc/)
- ✅ Camera feel: head bob, crouch, sprint FOV, land dip (procedural)
- ✅ Cogito integrated (4 addons, 214 scripts, MIT license)
- ✅ Cogito autoloads working (triple import fix for Godot 4.7)
- ✅ WieldableHitscan (extends CogitoWieldable) — our hitscan on Cogito's base
- ✅ Visual style guide (3 mood references → 12-section STYLE_GUIDE.md)
- ✅ XIII-style per-biome palettes (palette_primary + palette_accent per biome)
- ✅ Weapon system design decision: hitscan default, projectiles for special weapons only
- ✅ Coexistence principle: extend Cogito, don't fork it

### What's in progress
- 🔄 Step 2: mazar_player.gd (extends CogitoPlayerAdvanced) with chunk_loader + fly mode
- 🔄 Step 3: Update baked_world.tscn to use mazar_player

### What's NOT done yet
- ❌ Toon shader (cel-shading + inverted-hull outlines) — style guide priority #1
- ❌ HUD implementation (status-left, combat-right, nav-bottom layout)
- ❌ NPC AI (Cogito has it, not wired to our zombies yet)
- ❌ Save/load (Cogito has it, not wired to our baked city yet)
- ❌ Interior builder (furniture inside shell buildings)
- ❌ Weight-based inventory (Cogito has grid inventory, user wants weight system)

---

## Completed Phases

### Phase A — City Gen + AI Middleware (2026-09-12 to 2026-09-13)

| Phase | What | Status |
|---|---|---|
| A.4-A.12 | River, wetlands, diagonal avenues, district templates, FPS wins, district halo, data dumper, bridges, AI middleware | ✓ FROZEN |

### Phase B — Parcel + Lot System (2026-09-14)
- B.5-B.6: Parcel-based block subdivision + Lot recipes (11 recipes for 6 biomes)
- B.7: Generator fixes + constraint validator (PlacementValidator)
- B.8: Persistent Map Baker — **DONE** (map_baker.gd + chunk .tscn files)
- B.8.1: Post-bake cleanup (overlap removal) — **DONE**
- B.8.2: Per-biome gap filler variety — **DONE**
- B.8.3: POI nudging off roads — **DONE**
- B.8.4: Per-biome debug ground colors — **DONE**

### Phase C — Structural Believability (2026-09-14)
- C.1-C.6: Road hierarchy, zoned districts, attached buildings, landmarks, decay, OBB variation — ✓

### Phase Gun — Weapon System (2026-09-14 to 2026-09-19)
- 6 components: hitscan, tracer, recoil, spread pattern, recovery, muzzle flash — ✓
- 4 weapons: pistol, rifle, shotgun, sniper_rifle — ✓
- PPS Shooter Essentials integrated (ZC57 + MGP7 rigged models + attachments) — ✓
- Camera feel: head bob, crouch, sprint FOV, land dip — ✓
- WieldableHitscan (extends CogitoWieldable) — ✓
- WieldableShotgun (extends WieldableHitscan) — ✓

### Phase Cogito — Immersive Sim Integration (2026-09-19)
- Cogito addon installed (4 addons, 214 scripts) — ✓
- Autoload resolution fixed (triple import for Godot 4.7) — ✓
- Input actions merged (forward/back/left/right + Cogito actions) — ✓
- Step 1: WieldableHitscan created (extends CogitoWieldable) — ✓
- Step 2: mazar_player.gd (extends CogitoPlayerAdvanced) — 🔄 pending
- Step 3: baked_world.tscn updated to use mazar_player — 🔄 pending

### Phase Style — Visual Identity (2026-09-19)
- 3 mood reference images analyzed via VLM — ✓
- 12-section STYLE_GUIDE.md written — ✓
- XIII-style per-biome palettes (10 biomes, palette_primary + palette_accent) — ✓
- Toon shader (cel-shading + inverted-hull outlines) — ❌ NOT STARTED (priority #1)
- HUD layout implementation — ❌ NOT STARTED
- Paper grain overlay — ❌ NOT STARTED
- BANG/CRACK pop-up text effects — ❌ NOT STARTED

### v1 Flat Terrain (2026-09-14)
- FLAT_TERRAIN_V1 := true in chunk_streamer.gd — ✓
- terrain_height.gd preserved for future re-enable — ✓

---

## Next Priorities

### Phase D — Cogito Migration (CURRENT — in progress)

| # | Task | Status |
|---|---|---|
| D.1 | Step 2: mazar_player.gd (extends CogitoPlayerAdvanced) | 🔄 pending |
| D.2 | Step 3: Update baked_world.tscn to use mazar_player | 🔄 pending |
| D.3 | Delete old parallel systems (weapon_system.gd, player_main.gd, etc.) | pending |
| D.4 | Wire Cogito interaction components to baked buildings (doors, containers) | pending |
| D.5 | Wire Cogito inventory to our weapon loot (ammo boxes, medkits) | pending |
| D.6 | Wire Cogito NPC AI to our zombie assets | pending |
| D.7 | Wire Cogito save/load to baked city | pending |

### Phase S — Visual Style Implementation

| # | Task | Effort | Priority |
|---|---|---|---|
| S.1 | Toon shader (cel-shading + inverted-hull outlines) | Large | #1 (defines 70% of identity) |
| S.2 | Fog color matching per biome (XIII palette) | Medium | #2 |
| S.3 | HUD layout (status-left, combat-right, nav-bottom) | Large | #3 |
| S.4 | Color restriction (posterization, ~16-24 values per channel) | Medium | #4 |
| S.5 | Paper grain overlay (comic book printing feel) | Small | #5 |
| S.6 | Pop-up text effects (BANG/CRACK, 0.3s screen-space) | Small | #6 |
| S.7 | Weapon holster system (hide gun when not shooting) | Small | #7 |

### Phase E — Polish (post-style + post-gameplay)

| # | Task | Effort | Impact |
|---|---|---|---|
| E.1 | Intersection variation (T-junctions, roundabouts, traffic islands) | Medium | Medium |
| E.2 | Setback variation per zoning type | Low | Medium |
| E.3 | L-shaped / irregular footprints | Medium | Low |
| E.4 | Signage — street signs, business signs, billboards | Medium | Low |
| E.5 | Re-enable terrain elevation (post-v1) | Medium | Medium |
| E.6 | Broken windows on buildings | Medium | Medium (atmosphere) |
| E.7 | Overgrowth on buildings (day-1-to-10-years sim) | Large | Low (future) |

### Phase F — City Gen Optimization (POST-v1, saved from DeepSeek proposal)

| # | Task | Effort | Description |
|---|---|---|---|
| F.0 | 3 Refactors | 3 commits | Extract shared constants → ChunkPlanner (pure function) → ChunkRenderer. Unlocks all loops below. |
| F.3 | Loop 3 — Reference-Driven | ~250 lines + API | Provide top-down reference images per biome → AI extracts numeric profile → minimize distance between generated plan and reference profile. Matches how we already work with mood references. Needs F.0 + PlanMetrics. |
| F.4 | Loop 4 — Convergence | ~200 lines + design | Stopping condition: separates "hard problems" (walkability failures, rejection rate) from "preferences" (aesthetics). When round reports "zero hard problems, only preferences remain" → stop iterating. Orthogonal to F.3 — can run on top of any search method. |

**Phase F timing:** Only AFTER the city gen produces results the user is happy with. These are optimization loops, not generation improvements.

---

## Bug list (active)

| # | Bug | Status | Fix |
|---|---|---|---|
| 1 | Door origin — `door_front.mog` comment says origin at bottom, actual mesh centered | Pending | Add `pos=[0, 1.10, 0]` to frame box |
| 2 | Street lamp origin — likely same pattern | Pending | Inspect + fix .mog |
| 3 | Crossroads are overlapping rectangles | Pending | Phase E.1 |
| 4 | Bridge visually flat (was, now elevated +3m with piers) | Fixed (A.11) | Verify visually |
| 5 | Y-layering: roads were below sidewalks | Fixed | Roads now Y=0.060, sidewalks Y=0.040 |
| 6 | POIs on roads (5 of 8 POIs at grid intersections) | Fixed | _nudge_off_road() in map_baker.gd |
| 7 | Godot 4.7 autoload resolution | Fixed | Triple import sequence resolves class cache |

---

## Milestones

| # | Milestone | Exit criteria | Status |
|---|---|---|---|
| 0 | Pre-production | All open questions answered | ⏳ in progress |
| 1 | Vertical slice — Suburbia | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night | Next |
| 2 | Alpha — full map | All 10 biomes present, all systems functional | — |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced | — |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings | — |
| 5 | Co-op technical pass | Online architecture validated | — |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed | — |

---

## Asset production status

Current: 234 active assets (226 buildings/props/foliage + 8 weapons) + PPS Shooter Essentials (25+ models)

| Category | Count | Notes |
|---|---:|---|
| Buildings | 88 | 13 with shells done, ~20 TODO |
| Props (dynamic) | 16 | chairs, tables, lamps, beds, fridges |
| Props (static fixtures) | 11 | kitchen modules, toilet, bathtub |
| Foliage | 19 | trees, bushes, hedges, flowers |
| Environment | 40+ | roads, lights, fences, signs |
| Characters | 5 | player + 4 zombies |
| Weapons | 8 | 4 ranged + 4 melee |
| PPS Weapons | 25+ | ZC57 pistol, MGP7 rifle, attachments, grenades, props |
| Vehicles | 8 | M.A.V.S addon |
| Cogito Assets | 214 scripts | Inventory, NPC AI, save/load, quests, menus, interaction |

---

## Terrain phases (for post-v1 re-enable)

| Phase | What | Status |
|---|---|---|
| A — Prep | River redesign, biome enum cleanup, subway-as-layer | ✓ DONE |
| B — Terrain core | terrain_height.gd, river_network.gd, debug viz | ✓ DONE |
| C — Terrain mesh | Terrain3D plugin, heightmap bake, splatmap | ⏳ deferred (v1 flat) |
| D — Water + bridge | Water surface, bridge POIs, water_depth query | ✓ Partial |
| E — NavMesh | NavigationRegion3D per chunk, zombie pathfinding | ⏳ pending |
| F — POI system | pois.json, landmark placement, visibility check | ⏳ pending |
| G — Independent perf | Spatial grid roads, MultiMesh batching, AABB insert | ⏳ pending |

---

## Middleware (FROZEN — no commits except real bugs)

- 10 detectors (7 geometric + 3 semantic)
- 3 action types (fill / remove / reposition)
- Validate-before-commit
- Multi-pass loop
- 25% problem reduction verified
- Spatial query API (O(1) grid lookup)
- Versioned runs (runs/run_NNN/)

---

## Design decisions (locked)

### Weapon system (2026-09-19)
- **Hitscan** for all standard weapons (pistol, rifle, sniper, shotgun)
- **Projectiles** reserved for special weapons only (grenade launcher, rocket launcher, throwables)
- **Shotgun** = 8 hitscan raycasts with spread (NOT a projectile)
- **Coexistence**: extend Cogito, don't fork it. Our code in weapons/ + scripts/, Cogito's untouched in addons/cogito/

### Visual style (2026-09-19)
- **Cel-shaded comic book** (toon shader + inverted-hull outlines = 70% of identity)
- **Palette**: muted browns/grays/olive + saturated crimson blood pops
- **Per-biome XIII-style palettes** (10 biomes, each with distinct palette_primary + palette_accent)
- **Lighting**: overcast late afternoon, fog 150-200m
- **HUD**: status-left, combat-right, nav-bottom. Opaque panels, thick black borders
- **Weapons**: holster when not shooting, viewmodel on aim/fire/reload only
- **Pop-ups**: BANG/CRACK = 0.3s screen-space textures (not permanent)

### City gen architecture (2026-09-15)
- **Baked .tscn chunks** (192 files, streamed via chunk_loader.gd)
- **map_baker.gd** runs headless, produces .tscn files
- **post_bake_cleanup.gd** removes overlapping buildings
- **Runtime** loads pre-baked chunks (no procedural generation at runtime)
- **Future**: Phase F refactors (shared constants → planner → renderer) when city gen output is satisfactory
