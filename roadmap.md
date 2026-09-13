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

## Next: Phase B.6 — Lot System (HIGHEST PRIORITY)

Three-step plan. Each step is one file. Total ~1 day of work.

| # | Task | File | Effort |
|---|---|---|---|
| B.6.1 | Define `Lot` data structure + 20-30 hand-authored Lot recipes for 6+ biomes | `tools/lot.gd` (NEW, ~250 lines) | Medium |
| B.6.2 | Implement `LotStamper` mirroring `district_stamper.gd` pattern. Stamps primary + companions with relative offsets, draws sidewalk + driveway polylines from road edge to building doors | `tools/lot_stamper.gd` (NEW, ~150 lines) | Medium |
| B.6.3 | Patch `chunk_streamer.gd:617-690` to call `LotStamper` per parcel instead of parcel-by-parcel loop. Replace gap-filler's garage/shed scatter (line 711+) with lot-companion placement. Patch `block_layout.gd:get_interior_paths` to also emit per-lot sidewalk + driveway segments connecting road-edge → building-door | `tools/chunk_streamer.gd` + `tools/block_layout.gd` (EDITS) | Medium |

Visual contract after Phase B.6:
- House + garage always sit on the same lot, garage door aligned with house front
- Grey sidewalk (1.5m wide) from each house's front door to the nearest road
- Darker driveway (3m wide) from each garage to the nearest road
- No more random garages in the middle of fields

---

## Phase B.7-alt — Visual contract scene (optional, parallel to B.6)

Hand-author ONE hero block (e.g. suburb_block from `district_templates.gd`) in a separate `scenes/authored_reference.tscn` scene as a **visual benchmark** for what the runtime generator should produce. ~1 day. Useful as a "this is what good looks like" target — NOT a substitute for Phase B.6.

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
