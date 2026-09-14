# MAZAR — Roadmap

> **Last updated:** 2026-09-14 (doc consolidation + roadmap cleanup)
> **Map:** LOCKED at 12 km² (4km × 3km). See GDD §4.1.
> **Authoring pivot:** runtime generator is a TESTING SCAFFOLD. Shipping map is hand-authored via Lot recipes + district templates. See GDD §4.7.

---

## AUTHORING PIVOT (2026-09-14) — context for any new chat session

The runtime procedural generator in `tools/chunk_streamer.gd` is **not the shipping map**. It exists to:
1. Validate the asset pipeline (does every GLB load + place + collide correctly?)
2. Validate biome profiles + district templates + parcel layout math
3. Give the player something to walk around in while interiors + gameplay are built

The shipping map is **fixed + hand-authored** per Pillar 1 of the GDD. The right scope for hand-authoring is **recipes** (district templates at block scale + Lot recipes at parcel scale), NOT one giant hand-authored scene. Hand-authoring the whole 12 km² as one `.tscn` was considered and rejected (see GDD §4.7.4).

---

## Completed Phases

### Phase A — City Gen + AI Middleware (2026-09-12 to 2026-09-13)

| Phase | What | Status |
|---|---|---|
| A.4 | River-as-feature (polyline, not biome) + Wetlands split | ✓ |
| A.5 | Wetlands at river mouth + district naming (lore placeholders) | ✓ |
| A.6 | Diagonal avenues + anchor points + road graph + highway logic | ✓ |
| A.7 | Hand-authored district templates (4: suburb/commercial/downtown/industrial) | ✓ |
| A.8 | FPS quick wins + block fill + zoning + setback variation | ✓ |
| A.9 | District halo + identity/weather palette (data locked) | ✓ |
| A.10 | Data-driven chunk state dumper | ✓ |
| A.11 | Bridge visuals (elevated + piers) | ✓ |
| A.12 | AI middleware: 10 detectors + validation + multi-pass loop + spatial query + versioned runs + portability tested | ✓ FROZEN |

### Phase B.5 — Parcel system (DONE 2026-09-14)
- Parcel-based block subdivision (`block_layout.gd`)
- Per-biome layout types
- Interior paths (visual only)

### Phase B.6 — Lot System (DONE 2026-09-14)
- `tools/lot.gd` — 11 lot recipes for 6 biomes
- `tools/lot_stamper.gd` — stamps Lot at parcel, draws sidewalk + driveway
- Patched `chunk_streamer.gd` to call LotStamper per parcel
- Removed garage_detached + shed from gap filler (was the "garage facing wrong way" bug)

### Phase B.7 — Generator Fixes + Constraint Validator (DONE 2026-09-14)
- B.7.1-B.7.4: road_network queries + Parcel road-aware fields + LotStamper uses actual road_edge_pos
- B.7.5-B.7.6: path_query.gd + gap filler path avoidance
- B.7.7-B.7.8: placement_validator.gd + lot_stamper integration
- B.7.9: parcel size fix (110m → 30m depth)
- B.7.10: per-biome density multiplier
- B.7.11: roadside content pass (cars, props, small buildings)
- B.7.12: per-biome foliage multiplier
- B.7.13: layer cake fix + foliage array in chunk_states
- B.7.14: props-on-paths fix (5 functions missing is_on_path)

### Phase B.8 — Persistent Map Baker (DEFERRED)
- `map_baker.gd` — bake validated layout to `.tscn` chunks
- `persistent_placements.json` — per-chunk placement index
- Bake version stamp (hash of generator files + manifest + seed)
- Runtime loads baked chunks, middleware moves to bake step
- **Status:** Deferred per user — focus on city gen quality first, baking later

### Phase C — Structural Believability (DONE 2026-09-14)
- C.1: Road hierarchy (highway/arterial/local, 235 segments)
- C.2: Zoned districts (core/ring/edge density overlay)
- C.3: Attached buildings (row houses, strip malls, downtown attached)
- C.4: Landmark footprints (parking lots, plazas, bollards)
- C.5: Decay layer (abandoned convoys, mass graves, quarantine, looted stores)
- C.6: OBB-style parcel variation (organic lot sizes + row-house splits)

### Gun System (DONE 2026-09-14)
- 6 components: hitscan, tracer, recoil, spread pattern, recovery, muzzle flash
- 4 weapons: pistol, rifle, shotgun, sniper_rifle
- Test shooting range (arcade-style, 8 color-coded targets)
- Timer-based fire rate (enables automated tests)
- Signal bus (headless test support)
- Dynamic crosshair (visualizes spread patterns)
- Collision layers (world/player/target/weapon)
- RenderValidator (catches rendering-only errors)

### v1 Flat Terrain (DONE 2026-09-14)
- FLAT_TERRAIN_V1 := true in chunk_streamer.gd
- terrain_height.gd preserved for future re-enable
- Subway system unaffected (underground, own Y coordinate)

---

## Next Priorities

### Phase D — Gameplay Systems (next major phase)

| # | Task | Effort | Impact |
|---|---|---|---|
| D.1 | Wire `interior_builder.gd` (exists but unused) — place furniture inside shell buildings | Large | High (gameplay-critical per GDD §4.4) |
| D.2 | Vehicle spawning — abandoned cars in driveways, streets, parking lots (M.A.V.S integration) | Medium | Medium (core PZ loop) |
| D.3 | NPC AI — zombies wander toward noise, attack on contact | Large | High (gameplay) |
| D.4 | Save/load — persist player modifications across runs | Large | Medium |
| D.5 | Inventory + item system (loot from containers, weapons, food) | Large | High (gameplay) |
| D.6 | Health + damage system (player takes damage, heals, dies) | Medium | High (gameplay) |

### Phase E — Polish (post-gameplay)

| # | Task | Effort | Impact |
|---|---|---|---|
| E.1 | Intersection variation (T-junctions, roundabouts, traffic islands) | Medium | Medium |
| E.2 | Setback variation per zoning type (folded into Lot recipes) | Low | Medium |
| E.3 | L-shaped / irregular footprints | Medium | Low |
| E.4 | Signage — street signs, business signs, billboards | Medium | Low |
| E.5 | Re-enable terrain elevation (post-v1, see GDD §12.0) | Medium | Medium |
| E.6 | Broken windows on buildings (requires window child meshes) | Medium | Medium (atmosphere) |
| E.7 | Overgrowth on buildings (day-1-to-10-years sim mechanic) | Large | Low (future) |

---

## Bug list (active)

| # | Bug | Status | Fix |
|---|---|---|---|
| 1 | Door origin — `door_front.mog` comment says origin at bottom, actual mesh centered | Pending | Add `pos=[0, 1.10, 0]` to frame box |
| 2 | Street lamp origin — likely same pattern | Pending | Inspect + fix .mog |
| 3 | Crossroads are overlapping rectangles | Pending | Phase E.1 |
| 4 | Bridge visually flat (was, now elevated +3m with piers) | Fixed (A.11) | Verify visually |

---

## Milestones (moved from GDD)

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

## Asset production status (moved from GDD)

Current: 234 active assets (226 buildings/props/foliage + 8 weapons)

| Category | Count | Notes |
|---|---:|---|
| Buildings | 88 | 13 with shells done, ~20 TODO |
| Props (dynamic) | 16 | chairs, tables, lamps, beds, fridges |
| Props (static fixtures) | 11 | kitchen modules, toilet, bathtub |
| Foliage | 19 | trees, bushes, hedges, flowers |
| Environment | 40+ | roads, lights, fences, signs |
| Characters | 5 | player + 4 zombies |
| Weapons | 8 | 4 ranged + 4 melee |
| Vehicles | 8 | M.A.V.S addon |

Known asset issues: see `docs/buildings.md` Part 1 (shells needed) + bug list above.

---

## Terrain phases (moved from GDD — for post-v1 re-enable)

Validation rule: FPS must not drop >20% from baseline (145 FPS headless, threshold 116 FPS).

| Phase | What | Status |
|---|---|---|
| A — Prep | River redesign, biome enum cleanup, subway-as-layer | ✓ DONE |
| B — Terrain core | terrain_height.gd, river_network.gd, debug viz | ✓ DONE |
| C — Terrain mesh | Terrain3D plugin, heightmap bake, splatmap | ⏳ deferred (v1 flat) |
| D — Water + bridge | Water surface, bridge POIs, water_depth query | ✓ Partial (bridges done, water surface done, depth query pending) |
| E — NavMesh | NavigationRegion3D per chunk, zombie pathfinding | ⏳ pending |
| F — POI system | pois.json, landmark placement, visibility check | ⏳ pending |
| G — Independent perf | Spatial grid roads, MultiMesh batching, AABB insert | ⏳ pending |

---

## Middleware (FROZEN — no commits except real bugs)

- 10 detectors (7 geometric + 3 semantic)
- 3 action types (fill / remove / reposition)
- Validate-before-commit (simulate → count local problems → keep if reduces)
- Multi-pass loop (dump → analyze → apply → re-dump → compare → keep/revert → stop after 2 streaks)
- 25% problem reduction verified
- Spatial query API (O(1) grid lookup, portable across maps)
- Versioned runs (runs/run_NNN/ with timestamp + git hash)
- Portability tested against hostile JSON (2 crashes, both fixed)
- Semantic tags (28 assets with conflicts_with / pairs_with / min_spacing)

```bash
# How to use the frozen middleware
# 1. Run godot (dumps chunk_states_auto.json after 2s)
timeout 30 /home/z/my-project/tools/godot --headless --path godot_project --quit-after 300
# 2. Run AI middleware (reads dump, generates fill_plan.json)
python3 scripts/ai_fill_planner.py
# 3. Run multi-pass loop
python3 scripts/ai_multi_pass.py 3
```
