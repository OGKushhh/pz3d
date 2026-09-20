# STATUS — what's current vs deprecated

> **Last updated:** 2026-09-20 (session 14 — Cogito separation + V2 city prebuild)

## Canonical docs (current truth)

| What | Where | Notes |
|---|---|---|
| GDD | `docs/GDD.md` | Master design doc |
| Lore | `docs/lore.md` | World lore |
| Poly budget | `docs/poly_budget.md` | Polygon budgets per asset type |
| Assets | `docs/assets.md` | Asset count + review strategy |
| Buildings | `docs/buildings.md` | Shells needed + furniture + district templates |
| Style guide | `docs/style/STYLE_GUIDE.md` | 12-section visual style (palette, lighting, HUD, atmosphere) |
| Mood references | `docs/style/mood_*.jpg/png` | 3 reference images for visual direction |
| Retired v3 extraction | `docs/retired_city_builder_v3_extraction.md` | Historical reference |
| Roadmap | `roadmap.md` | Phase tracker + priorities + design decisions |
| Worklog | `worklog.md` | Append-only multi-session log |
| STATUS | `STATUS.md` | This file — what's current vs archived |
| README | `README.md` | Project overview |

## Code locations

| What | Where |
|---|---|
| Godot project | `godot_project/` |
| Source assets | `assets/{category}/` |
| MoGen assets | `assets/{category}/{src,out,renders}/` |
| Weapon assets (PPS) | `assets/weapons/pps/` |
| Build scripts (baker, dumper, cleanup) | `godot_project/scripts/` |
| Weapon scripts | `godot_project/weapons/` |
| City gen tools | `godot_project/tools/` |
| MoGen DSL reference | `mogen-docs/compiled.md` |
| MoGen upstream examples | `mogen-examples/` |
| Asset pipeline docs | `asset-pipeline/` |
| Cogito addon | `godot_project/addons/cogito/` (DO NOT MODIFY — extend from outside) |
| Godot State Charts | `godot_project/addons/godot_state_charts/` (Cogito dependency) |
| Input Helper | `godot_project/addons/input_helper/` (Cogito dependency) |
| Quick Audio | `godot_project/addons/quick_audio/` (Cogito dependency) |
| Quality FPS Controller | `godot_project/addons/fpc/` (available, not primary) |
| Terrain 3D | `godot_project/addons/terrain_3d/` (deferred to post-v1) |
| M.A.V.S (vehicles) | `godot_project/addons/M.A.V.S/` |
| Style mood references | `docs/style/` |

## Baked city files (V2 — current)

| What | Where |
|---|---|
| World scene (sky + sun + ground + Roads + 300 Block instances + Player) | `godot_project/scenes/main.tscn` |
| Roads scene (37 road meshes + sidewalks + lane lines) | `godot_project/scenes/baked_v2/roads.tscn` |
| Block scenes (300 × .tscn — each = ground + buildings + foliage + props) | `godot_project/scenes/baked_v2/block_<i>.tscn` |
| V2 plan generator | `godot_project/tools/city_gen_v2.gd` |
| V2 baker script | `godot_project/scripts/city_v2_baker.gd` |
| Saved V2 plan (JSON, for inspection) | `godot_project/data/city_plan_v2.json` |

## Baked city files (V1 — archived, not used)

| What | Where |
|---|---|
| Old world scene (monolithic 82k lines, INLINED — freezes Godot editor) | `godot_project/scenes/baked_chunks/` (kept for reference, do NOT load) |
| Old chunk files (192 × .tscn) | `godot_project/scenes/baked_chunks/chunk_X_Y.tscn` |
| Old baker (V1, per-chunk, inlined main.tscn) | `godot_project/scripts/map_baker.gd` |
| Old dumper script | `godot_project/scripts/dump_baked_city.gd` |
| Old cleanup script | `godot_project/scripts/post_bake_cleanup.gd` |

## Weapon system architecture

| What | Where | Status |
|---|---|---|
| WieldableHitscan (extends CogitoWieldable) | `godot_project/weapons/wieldable_hitscan.gd` | ✅ Current |
| WieldableShotgun (extends WieldableHitscan) | `godot_project/weapons/wieldable_shotgun.gd` | ✅ Current |
| Tracer | `godot_project/weapons/tracer.gd` | ✅ Current |
| MuzzleFlash | `godot_project/weapons/muzzle_flash.gd` | ✅ Current |
| RecoilController | `godot_project/weapons/recoil_controller.gd` | ✅ Current |
| WeaponSpreads (data) | `godot_project/data/weapon_spreads.gd` | ✅ Current |
| WeaponSystem (old standalone) | `godot_project/weapons/weapon_system.gd` | ⚠️ Legacy (will be deleted in Step 3) |
| WeaponViewModel (old standalone) | `godot_project/weapons/weapon_viewmodel.gd` | ⚠️ Legacy (replaced by CogitoWieldable.wieldable_mesh) |

## Archived (historical, do not edit)

| What | Where |
|---|---|
| Old GDD versions (v0-v8, 17 files) | `archive/gdd_history/` |
| Old poly budgets (v1, v2, low_end) | `archive/poly_budgets/` |
| Old city lore options | `archive/city_lore_options.md` |
| Frozen reference architecture | `archive/reference_architecture/mazar_city_builder/` |
| Original Python generator | `archive/mazar_city_builder.py` |
| Early-batch lookbook | `archive/lookbook/mogen-lookbook/` |
| Old contact sheets | `archive/contact_sheets/` |
| Old screenshots | `archive/screenshots/` |

## Gitignored (not in repo)

| What | Why |
|---|---|
| `.env` | Secrets |
| `upload/` | User-uploaded reference images |
| `tool-results/` | AI tool call artifacts |
| `skills/`, `.claude/` | Skill system internals |
| `*.deb` | System packages |
| `godot_engine/` | Local Godot binary |
| `godot.zip` | Local Godot archive |
| `backup/` | Local backups |
| `*.pyc`, `__pycache__/` | Python cache |
| `.godot/` | Godot editor cache |
| `*.tmp` | Temp files |

## Naming convention
- Canonical docs in `docs/` have **no version suffix** — there's only one `GDD.md`, period.
- Versions are tracked in git history.
- Cogito addon files are **never modified** — we extend from outside (`weapons/`, `scripts/`).

## How to know if a file is current
1. Check `docs/` — if it's there, it's current.
2. Check `archive/` — if it's there, it's historical.
3. Check `STATUS.md` code locations table — if listed, it's current.
4. If it's at root or `download/` and not in STATUS, it's likely orphaned.
