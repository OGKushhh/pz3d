# MAZAR — Roadmap

> **Last updated:** 2026-09-13
> **Middleware status:** FROZEN (no commits except real bugs)

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

### Phase B.5 — Polish (deferred)

| # | Task | Effort | Impact |
|---|---|---|---|
| 15 | Intersection variation (T-junctions, roundabouts, traffic islands) | Medium | Medium |
| 16 | Clustered lots + shared driveways | Medium | Low |
| 17 | L-shaped / irregular footprints | Medium | Low |
| 18 | Setback variation per zoning type (0m commercial, 4m residential) | Low | Medium |
| 19 | Signage — street signs, business signs | Medium | Low |
| 20 | Billboards — American-style landmark signage | Medium | Low |

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
| 4 | Crossroads are overlapping rectangles | Pending | Phase B.5 #15 |
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
