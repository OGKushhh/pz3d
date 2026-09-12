# godot_project/ directory layout

## scripts/ — per-node scripts attached in scene files
- `player_main.gd` / `player_controller.gd` — player movement, camera, input
- `environment_setup.gd` — sky/sun/fog setup (programmatic fallback)
- `auto_screenshot.gd` / `screenshot.gd` — utility

## tools/ — architecture classes (loaded via preload, not attached to nodes)
- **City architecture:** city_config.gd, chunk_streamer.gd, spatial_index.gd, road_network.gd, plan_grid.gd, city_meta.gd, interior_builder.gd
- **Terrain system:** terrain_height.gd, terrain_baker.gd, terrain_debug_viz.gd, river_network.gd
- **Underground:** subway_network.gd
- **Debug:** debug_hud.gd

## Rule
- If a script is attached to a node in a .tscn scene → `scripts/`
- If a script is a class loaded via `preload()` or `const` → `tools/`
- If a script is an autoload → `tools/` (autoloads are architecture, not per-node)
