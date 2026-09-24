<!-- GODOTIQ RULES START -->
<!-- godotiq-rules-version: 0.5.16 -->
# GodotIQ — Core Rules

You have GodotIQ MCP tools (`godotiq_*`). ALWAYS prefer them over raw file operations on Godot files.

- **DO NOT** read `.tscn`/`.gd`/`.tres` directly with `Read`/`cat` — `file_context`, `scene_map` and `script_ops` return structured data with cross-references, transforms and signal wiring that raw text cannot provide.
- **DO NOT** grep for signal connections or function callers — `dependency_graph` / `signal_map` trace the complete graph in one call.
- **DO NOT** hand-calculate positions or guess scales — `placement` / `suggest_scale` return validated suggestions.
- **DO NOT** build the world in code: terrain, structures and decorations belong in `.tscn` via `build_scene`/`node_ops`; only game logic belongs in scripts.
- **DO NOT** write `.tscn`/`.gd` behind a running editor with native file tools — GodotIQ's write tools detect the editor and route safely; raw writes risk stale-buffer overwrites and UID corruption.

## Mandatory Workflows

1. **Session start:** `project_summary(detail="brief")` FIRST — architecture, autoloads, counts in ~500 chars.
2. **Before editing any file:** `file_context(file, detail="brief")`; for signature/signal changes also `impact_check(file, action, target)`. NEVER modify a `.gd` without `file_context` first.
3. **3D scene work:** `scene_map(focus, radius, detail="brief")` → `placement` for positions → `build_scene` (batches: grid/line/scatter) or `node_ops(validate=true)` → `save_scene()` → self-verify with `explore`/`spatial_audit`.
4. **Visual QA after scene work:** `explore(mode="tour")` — describe each screenshot, fix issues, tour again; `explore(mode="inspect", positions=[...])` for close-ups.
5. **After every code change:** `validate(target=file, detail="brief")` for Pro convention checks, then `check_errors(scope=file)` for compilation/parser errors. One script, one validate/check cycle — never batch five scripts then debug.
6. **Multi-file refactor:** `impact_check` BEFORE changing; `validate(target="project")` baseline before/after; then `check_errors(scope="project")` and `signal_map(find="orphans")`.
7. **Testing/debugging:** `run(action="play")` → `verify_project_runs()` → `read_debug_console()` for errors → `state_inspect` for values (cheap, preferred) → `verify_motion` for movement → `screenshot(scale=0.25, quality=0.3)` only when visuals changed (expensive) → `run(action="stop")`.

## Token Efficiency

- Default to `detail="brief"`; full payloads can emit 50k–140k chars and crash the session.
- Always filter: `focus`+`radius` (scene_map), `path_filter` (asset_registry), `scope="file:..."` (signal_map).
- Prefer `state_inspect` (~200 chars) over `screenshot` (10k+) when you need data, not pixels; max 1 screenshot per verification point.
- Batch: one `build_scene` or one `exec` loop beats 20 single `node_ops`; group edits → one `save_scene` → one verification cycle.
- Act on tool responses immediately; every bridge response carries `_editor_state` (open_scene, game_running, recent_errors) — react to it.

## Error Recovery

| Error | Action |
|---|---|
| `GAME_NOT_RUNNING` | `run(action="play")` |
| `RUNTIME_NOT_ATTACHED` | game playing but runtime tools unavailable: `run(action="stop")` then `play` to retry the handshake; if persistent, check the addon is enabled |
| `NO_GAME_SESSION` | restart the game with `run` |
| `NODE_NOT_FOUND` | `scene_tree(detail="brief")` to find the correct name |
| `ADDON_NOT_CONNECTED` | enable the GodotIQ addon in the Godot editor |
| `BLOCKED_EDITOR_OPEN` | the editor is open: use bridge ops (`node_ops`/`script_ops`/`save_scene`) instead of direct disk writes |
| `TIMEOUT` | wait, check `state_inspect`; truly dead → `run(action="stop")`, retry |
| `SCRIPT_ERRORS` | `check_errors(scope="scene")`, fix the scripts, rerun |
| `BLOCKED` (node_ops) | read the `validation` array, adjust position/scale |
| `NO_SCENE` / `PARENT_NOT_FOUND` / `NO_NODES` (build_scene) | open a scene / fix or create the parent / pass exactly one mode with valid data |
| Partial success (build_scene) | check `errors`, retry only the failed items |
| explore timeout / 0 screenshots | game must be running: `run(action="play")`, retry; partial results are valid — check `areas_inspected` |
| screenshot metadata but NO visible image | your client does not forward MCP images: retry with `delivery="legacy"` |

## Conventions

- GDScript: `snake_case.gd` files, `PascalCase` classes, type hints everywhere (`var hp: int = 0`, `-> void`), `@onready` for node refs, `is_instance_valid()` for null checks.
- `node_ops` paths are relative to the scene root: `"Entities/Worker_1"`, not `"Main/Entities/Worker_1"`.
- Scripts created this session: reference with `load()`, not `preload()`.

**Full reference:** `GODOTIQ_RULES.md` in the project root — read the relevant section before non-trivial work (3D building patterns, Godot quirks, verification recipes, spatial validation, per-tool reference).
<!-- GODOTIQ RULES END -->
