# MAZAR — Roadmap

> **Last updated:** 2026-09-14
> **Middleware status:** FROZEN (no commits except real bugs)
> **Authoring pivot:** runtime generator is a TESTING SCAFFOLD. Shipping map is hand-authored via Lot recipes + district templates. See GDD §4.7.

---

## AUTHORING PIVOT (2026-09-14) — context for any new chat session

The runtime procedural generator in `tools/chunk_streamer.gd` is **not the shipping map**. It exists to:

1. Validate the asset pipeline (does every GLB load + place + collide correctly?)
2. Validate biome profiles + district templates + parcel math
3. Give the player a walkable world while interiors + gameplay are built

The shipping map is **fixed + hand-authored** per Pillar 1 of the GDD. The right scope for hand-authoring is **recipes** (district templates at block scale + Lot recipes at parcel scale), NOT one giant hand-authored scene. Hand-authoring the whole 12 km² as one `.tscn` was considered and rejected (see GDD §4.7.4).

**Single most important next step: implement the Lot System (Phase B.6 below).**

This is the architectural fix for the user-reported pain points from the 2026-09-14 screenshot review:
- Garages placed by gap-filler loop at random positions with random rotation → "garage facing a different side completely"
- Interior paths are 2 cross-stripes through chunk centers → "paths don't connect to roads"
- No clustering, no companionship rule → "in between you find random something"

Root cause: the system has `Parcel` (1 primary building + yard position) but no `Lot` concept that owns companion structures + sidewalk + driveway as a unit.

---

## Next: Phase B.7 — Generator Fixes + Constraint Validator (HIGHEST PRIORITY)

> **Updated 2026-09-14 per DeepSeek review.** Two tracks: generator fixes (primary) + validator (safety net). Path connectivity + setbacks are GENERATOR fixes — the validator can't fix what isn't a rule violation. Middleware revert logic stays (two jobs: per-action filter + global accept/reject).

### Track 1 — Generator fixes (primary, do first)

| # | Task | File | Effort |
|---|---|---|---|
| B.7.1 | Add `nearest_road_info(pos) -> {distance, point, direction, segment}` to road_network | `tools/road_network.gd` (EDIT) | 1h |
| B.7.2 | Add `road_edge_pos` + `road_distance` + `road_dir` fields to Parcel class | `tools/block_layout.gd` (EDIT) | 1h |
| B.7.3 | After `generate_parcels()`, query road_network per parcel; set `road_edge_pos` + re-derive `front_dir` from actual road direction | `tools/chunk_streamer.gd` (EDIT) | 2h |
| B.7.4 | LotStamper: use `parcel.road_edge_pos` for sidewalk + driveway start points (not hardcoded recipe offsets). Compute driveway road-edge from garage position, not house position. | `tools/lot_stamper.gd` (EDIT) | 2h |
| B.7.5 | `path_query.gd` — collects all drawn path segments; `is_on_path(pos, margin)`, `nearest_path(pos)` | `tools/path_query.gd` (NEW, ~80 lines) | 2h |
| B.7.6 | Gap filler + foliage loops: add `path_query.is_on_path()` check before placing | `tools/chunk_streamer.gd` (EDIT) | 1h |

### Track 2 — Validator (safety net, do after Track 1)

| # | Task | File | Effort |
|---|---|---|---|
| B.7.7 | `placement_validator.gd` — `validate(pos, asset_name, biome) -> Dictionary` with penalty scoring (on_path=-100, on_road=-100, setback_violation=-50, neighbor_incompatible=-40, repeat>5=-20, overlap=-100) | `tools/placement_validator.gd` (NEW, ~150 lines) | 4h |
| B.7.8 | Patch `lot_stamper.gd` — call validator before stamping primary + each companion; nudge + retry on soft reject (max 3); skip lot on hard reject | `tools/lot_stamper.gd` (EDIT) | 2h |

Total: ~2-3 days.

### Removed (per DeepSeek correction #2)

- ~~B.7.6 (old): Fix ai_multi_pass.py revert logic~~ — middleware revert-on-regression is the accept/reject signal. Per-action validation is the filter. Two jobs, both needed. Keep the revert.

---

## Next: Phase B.8 — Persistent Map Baker (after B.7)

> **Updated 2026-09-14 per DeepSeek corrections #3 + #4.**

| # | Task | File | Effort |
|---|---|---|---|
| B.8.1 | `map_baker.gd` — runs full pipeline offline (gen → validate → middleware multi-pass → save). Middleware runs HERE, not at runtime. | `tools/map_baker.gd` (NEW, ~200 lines) | 4h |
| B.8.2 | `persistent_placements.json` — per-chunk index of placed lot recipes + world positions (for save/load + future editor) | `data/persistent_placements.json` (NEW) | 1h |
| B.8.3 | Bake version stamp — hash of generator files + manifest + seed. Stored in `baked_chunks/meta.json`. On load, compare; if mismatch, warn + force re-bake. | `tools/bake_version.gd` (NEW) + patch `chunk_streamer.gd` | 2h |
| B.8.4 | Patch `scenes/main.tscn` + `chunk_streamer.gd` — load baked chunks at runtime; `bake_mode: bool` flag; remove middleware from runtime path | `scenes/main.tscn` + `tools/chunk_streamer.gd` (EDIT) | 3h |

Total: ~1-2 days. After this, the player never runs the procedural gen — they load the baked persistent map. Middleware retires from runtime, moves to bake step.

---

## Phase B.6 — Lot System (DONE 2026-09-14)

Three-step plan, all committed:

| # | Task | File | Status |
|---|---|---|---|
| B.6.1 | `Lot` data structure + 8 hand-authored recipes for 6 biomes (SUBURBIA×3, COMMERCIAL, INDUSTRIAL, DOWNTOWN, FARMLAND, MILITARY) | `tools/lot.gd` (NEW, 302 lines) | ✓ commit `1dcd13e` |
| B.6.2 | `LotStamper` mirroring `district_stamper.gd` pattern — stamps primary + companions, draws sidewalk + driveway | `tools/lot_stamper.gd` (NEW, 188 lines) | ✓ commit `44aad51` |
| B.6.3 | Patch `chunk_streamer.gd:617-690` to call LotStamper per parcel; removed `garage_detached` + `shed` from gap filler (literal source of "garage facing a different side" bug) | `tools/chunk_streamer.gd` (EDIT) | ✓ commit `ae94f27` |

Verified via headless run + chunk_states analysis: 99 buildings placed by LotStamper (73 primary + 13 garage + 13 shed), 48 by DistrictStamper, 13 procedural fallback. Middleware detected 4 garage-overlap issues, generated 4 remove actions in `fill_plan.json`.

User feedback after walking the scene: "more organized now but not production level" — props on paths, inconsistent setbacks, paths still don't connect to roads. This is the motivation for Phase B.7 (Constraint Validator).

---

## Phase B.7-alt — Visual contract scene (optional, parallel to B.7)

Hand-author ONE hero block (e.g. suburb_block from `district_templates.gd`) in a separate `scenes/authored_reference.tscn` scene as a **visual benchmark** for what the runtime generator should produce. ~1 day. Useful as a "this is what good looks like" target — NOT a substitute for Phase B.7.

| # | Task | File | Effort |
|---|---|---|---|
| B.7-alt.1 | Hand-author suburb block scene with lot compositions (house + garage + shed + sidewalk + driveway) | `scenes/authored_reference.tscn` + `scripts/authored_reference.gd` | Medium |

---

## Completed

### Phase A — City Gen + AI Middleware (2026-09-12 to 2026-09-13)

| Phase | What | Status |
|---|---|---|
| A.4 | River-as-feature (polyline, not biome) + Wetlands split | ✓ |
| A.5 | Wetlands at river mouth + district naming (lore placeholders) | ✓ |
| A.6 | Diagonal avenues + anchor points + road graph + highway logic | ✓ |
| A.7 | Hand-authored district templates (3: suburb/commercial/downtown) | ✓ |
| A.8 | FPS quick wins + block fill + zoning + setback variation | ✓ |
| A.9 | District halo + identity/weather palette (data locked) | ✓ |
| A.10 | Data-driven chunk state dumper | ✓ |
| A.11 | Bridge visuals (elevated + piers) | ✓ |
| A.12 | AI middleware: 10 detectors + validation + multi-pass loop + spatial query + versioned runs + portability tested | ✓ FROZEN |

### Middleware (FROZEN — no commits except real bugs)

- 10 detectors (7 geometric + 3 semantic)
- 3 action types (fill / remove / reposition)
- Validate-before-commit (simulate → count local problems → keep if reduces)
- Multi-pass loop (dump → analyze → apply → re-dump → compare → keep/revert → stop after 2 streaks)
- 25% problem reduction verified
- Spatial query API (O(1) grid lookup, portable across maps)
- Versioned runs (runs/run_NNN/ with timestamp + git hash)
- Portability tested against hostile JSON (2 crashes, both fixed)
- Semantic tags (28 assets with conflicts_with / pairs_with / min_spacing)

---

## Next: Phase B — Visual Quality + Generator Features

### Phase B.1 — Visual quality pass (highest impact per effort)

| # | Task | Effort | Impact |
|---|---|---|---|
| 1 | Fix door origin bug — `door_front.mog` has origin at center, not bottom. Add `pos=[0, 1.10, 0]` to frame box. Same for window_unit + door_garage. | Low (edit .mog + recompile) | High — every shell building has broken doors |
| 2 | Fix street lamp origin — inspect + fix `street_light.mog` (same pattern) | Low | High — lamps sink into ground |
| 3 | Apply district identity at runtime — new `tools/district_environment.gd` that lerps WorldEnvironment sky/fog/ambient per biome. Data is locked in `city_config.gd DISTRICT_IDENTITY`. | Medium | High — transforms visual mood per district |
| 4 | Enable terrain height — replace FlatGround in main.tscn with heightmap mesh from `TerrainHeight.height_at()`. Roads follow terrain. | Medium | Medium — shows hidden -3.66m to +1.93m elevation |

### Phase B.2 — Density pass

| # | Task | Effort | Impact |
|---|---|---|---|
| 5 | Wire `suburb_block` template (defined but not in BIOME_TEMPLATES map) | Low | Medium |
| 6 | Add `industrial_block` + `military_block` templates | Medium | Medium |
| 7 | Increase fill density (target 60→80, vacant lot 50%→30%) | Low | High |
| 8 | MultiMesh batching for trees + zombies (1000+ draws → ~50) | Medium | High (FPS) |

### Phase B.3 — Gameplay depth (deferred)

| # | Task | Effort | Impact |
|---|---|---|---|
| 9 | Wire `interior_builder.gd` (exists but unused) — place furniture inside shell buildings | Large | High (gameplay-critical per GDD §4.4) |
| 10 | Vehicle spawning — cars in driveways, streets, parking lots | Medium | Medium (core PZ loop) |
| 11 | NPC AI — zombies wander toward noise, attack on contact | Large | High (gameplay) |
| 12 | Save/load — persist player modifications across runs | Large | Medium |

### Phase B.4 — Map expansion (deferred)

| # | Task | Effort | Impact |
|---|---|---|---|
| 13 | Expand 12km² → 30km² (update MAP_SIZE_M + GRID_COLS/ROWS + grid_layout) | Low (mechanical) | Medium |
| 14 | Expand 30km² → 100km² (GDD §4.1 v1 target) | Medium | Low (alpha) |

### Phase B.5 — Parcel system (DONE 2026-09-14)

| # | Task | Status |
|---|---|---|
| 1 | Parcel-based block subdivision (`block_layout.gd`) | ✓ |
| 2 | Per-biome layout types (residential_grid, commercial_perimeter, industrial_yard, courtyard_block, farmstead, forest_scatter, park_layout, marsh_scatter, checkpoint_grid, beach_strip) | ✓ |
| 3 | Interior paths (visual only, cross-stripes through chunk center) | ✓ — but identified as broken: doesn't connect to road sidewalks. Fix in B.6.3. |

> Phase B.5 closed. Its limitations (paths don't connect to road, no companion grouping) are the explicit motivation for Phase B.6 — Lot System.

### Phase B.6 — Lot System (HIGHEST PRIORITY — see top of file)

### Phase B.7 — Polish (deferred, post-Lot-System)

| # | Task | Effort | Impact |
|---|---|---|---|
| 15 | Intersection variation (T-junctions, roundabouts, traffic islands) | Medium | Medium |
| 16 | Setback variation per zoning type (0m commercial, 4m residential, 8m suburban) | Low | Medium — folded into Lot recipes in B.6 |
| 17 | L-shaped / irregular footprints | Medium | Low |
| 18 | Signage — street signs, business signs | Medium | Low |
| 19 | Billboards — American-style landmark signage | Medium | Low |

---

## Middleware roadmap (FROZEN — for reference only)

These features are NOT to be implemented unless a real bug requires them:

- City-wide allocation pass (multi-scale optimization)
- Versioned plans with diff visualization
- Spatial query API (DONE — frozen)
- VLM screenshot analysis integration
- Per-asset tri count balancing via middleware
- Road coverage analysis
- Landmark proximity scoring

---

## Bug list (active)

| # | Bug | Status | Fix |
|---|---|---|---|
| 1 | Door origin — `door_front.mog` comment says origin at bottom, actual mesh centered | Pending | Add `pos=[0, 1.10, 0]` to frame box |
| 2 | Street lamp origin — likely same pattern | Pending | Inspect + fix .mog |
| 3 | Red debug line in sky (screenshots) | Pending | Check TerrainDebugViz autoload |
| 4 | Crossroads are overlapping rectangles | Pending | Phase B.7 #15 |
| 5 | Bridge visually flat (was, now elevated +3m with piers) | Fixed (A.11) | Verify visually |

---

## How to use the frozen middleware

```bash
# 1. Run godot (dumps chunk_states_auto.json after 2s)
timeout 30 /home/z/my-project/tools/Godot_v4.7.2-stable_linux.x86_64 \
  --headless --path godot_project --quit-after 300

# 2. Run AI middleware (reads dump, generates fill_plan.json)
python3 scripts/ai_fill_planner.py

# 3. Run multi-pass loop (dump → analyze → apply → re-dump → compare)
python3 scripts/ai_multi_pass.py 3

# 4. List versioned runs
python3 scripts/versioned_runs.py list

# 5. Compare two runs
python3 scripts/versioned_runs.py compare 0 1

# 6. Press F8 during gameplay to manually dump chunk states
```
