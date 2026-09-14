# Dumps baked_city.tscn to chunk_states_baked.json (same format as chunk_states_auto.json)
# so the AI middleware (ai_fill_planner.py) can analyze it.
#
# Run: godot --headless --path godot_project --script res://scripts/dump_baked_city.gd

extends SceneTree

const CityConfig = preload("res://tools/city_config.gd")
const OUTPUT_PATH := "res://chunk_states_baked.json"

var manifest: Dictionary

func _init():
        print("=== DumpBakedCity ===")
        # Load manifest (for category lookup)
        var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
        if f:
                manifest = JSON.parse_string(f.get_as_text())
        
        # Load baked city
        var scene := load("res://scenes/baked_city.tscn")
        if scene == null:
                print("FAIL: baked_city.tscn not found")
                quit(1)
        var inst: Node3D = scene.instantiate()
        # Add to tree so global_position works correctly
        root.add_child(inst)
        
        # Walk all nodes, group by chunk
        var chunks: Dictionary = {}  # Vector2i → {buildings, foliage, props, ...}
        var stack := [inst]
        while stack.size() > 0:
                var node: Node = stack.pop_back()
                if node is Node3D:
                        var n3d: Node3D = node
                        # Use transform.origin (local position from .tscn) instead of global_position
                        # (which requires transform propagation that doesn't happen until next frame)
                        # Since chunk_root nodes are at (0,0,0), local position = world position for buildings
                        var pos := n3d.transform.origin
                        # Determine chunk key
                        var col: int = int(pos.x / CityConfig.CHUNK_SIZE_M)
                        var row: int = int(pos.z / CityConfig.CHUNK_SIZE_M)
                        # Clamp to map bounds
                        if col < 0 or row < 0 or col >= CityConfig.CHUNKS_COLS or row >= CityConfig.CHUNKS_ROWS:
                                for c in node.get_children():
                                        stack.append(c)
                                continue
                        var key := Vector2i(col, row)
                        if not chunks.has(key):
                                chunks[key] = {
                                        "buildings": [],
                                        "foliage": [],
                                        "props": [],
                                        "chunk_key": [col, row],
                                }
                        # Classify node by name + manifest category
                        var node_name: String = n3d.name
                        var asset_name: String = String(n3d.get_meta("building_name", "")).strip_edges()
                        if asset_name == "":
                                # Try to infer from node name (e.g. "House1_suburban_house_v2_0" → "suburban_house_v2")
                                asset_name = _infer_asset_name(node_name)
                        if asset_name == "":
                                # Skip non-asset nodes (Sun, Ground, WorldEnvironment, Player, Camera3D, Col, etc.)
                                for c in node.get_children():
                                        stack.append(c)
                                continue
                        
                        var category: String = _get_category(asset_name)
                        var entry := {
                                "name": asset_name,
                                "node_name": node_name,
                                "pos": [pos.x, pos.y, pos.z],
                                "rot": [n3d.rotation.x, n3d.rotation.y, n3d.rotation.z],
                                "scale": [n3d.scale.x, n3d.scale.y, n3d.scale.z],
                                "aabb": _compute_aabb(n3d),
                        }
                        match category:
                                "buildings":
                                        chunks[key]["buildings"].append(entry)
                                "foliage":
                                        chunks[key]["foliage"].append(entry)
                                _:
                                        chunks[key]["props"].append(entry)
                for c in node.get_children():
                        stack.append(c)
        
        # Build the chunk_states array (matching chunk_states_auto.json format)
        var states: Array = []
        for key in chunks:
                var chunk_data: Dictionary = chunks[key]
                var col: int = key.x
                var row: int = key.y
                var origin := Vector3(col * CityConfig.CHUNK_SIZE_M, 0, row * CityConfig.CHUNK_SIZE_M)
                # Determine biome
                var grid_col: int = clamp(int(col * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
                var grid_row: int = clamp(int(row * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
                var biome: int = CityConfig.grid_layout()[grid_row][grid_col]
                # Build density grid (10×10 over the chunk, 25m cells)
                var density_grid: Array = _build_density_grid(chunk_data, origin)
                var gap_count: int = _count_gaps(density_grid)
                # Stats
                var bldgs: Array = chunk_data["buildings"]
                var fol: Array = chunk_data["foliage"]
                var props: Array = chunk_data["props"]
                var state := {
                        "chunk_key": [col, row],
                        "biome": biome,
                        "buildings": bldgs,
                        "foliage": fol,
                        "props": props,
                        "zombies": [],
                        "counts": {
                                "buildings": bldgs.size(),
                                "foliage": fol.size(),
                                "props": props.size(),
                                "zombies": 0,
                        },
                        "density_grid": density_grid,
                        "gap_count": gap_count,
                        "gaps": [],
                        "world_bounds": {
                                "min": [origin.x, 0, origin.z],
                                "max": [origin.x + CityConfig.CHUNK_SIZE_M, 0, origin.z + CityConfig.CHUNK_SIZE_M],
                        },
                        "anchor": {},
                        "halo": {},
                        "neighbors": [],
                        "river": null,
                        "roads": [],
                        "stats": {},
                        "terrain": {},
                        "district_name": "",
                }
                states.append(state)
        
        # Sort by chunk_key for stable output
        states.sort_custom(func(a, b): return a["chunk_key"][0] == b["chunk_key"][0] and a["chunk_key"][1] < b["chunk_key"][1] or a["chunk_key"][0] < b["chunk_key"][0])
        
        # Save
        var out_file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
        if out_file:
                out_file.store_string(JSON.stringify(states, "\t"))
                out_file.close()
                print("✅ Dumped %d chunks to %s" % [states.size(), OUTPUT_PATH])
                var total_b: int = 0
                var total_f: int = 0
                var total_p: int = 0
                for s in states:
                        total_b += s["counts"]["buildings"]
                        total_f += s["counts"]["foliage"]
                        total_p += s["counts"]["props"]
                print("   Total: %d buildings, %d foliage, %d props" % [total_b, total_f, total_p])
        else:
                print("FAIL: couldn't write %s" % OUTPUT_PATH)
        quit()

func _infer_asset_name(node_name: String) -> String:
        # Node names are like "House1_suburban_house_v2_0" or "street_light_215" or "windmill_92771"
        # Try to match against manifest keys
        if manifest.is_empty():
                return ""
        # Strip leading prefix like "House1_" or "Oak1_" etc.
        var cleaned := node_name
        # Find longest manifest key that's a substring of node_name
        var best_match: String = ""
        for key in manifest:
                if node_name.find(key) >= 0 and key.length() > best_match.length():
                        best_match = key
        return best_match

func _get_category(asset_name: String) -> String:
        if manifest.has(asset_name):
                var info: Dictionary = manifest[asset_name]
                var cat: String = info.get("category", "")
                # Handle inconsistent manifest naming (building vs buildings, prop vs props)
                if cat == "buildings" or cat == "building":
                        return "buildings"
                elif cat == "foliage":
                        return "foliage"
        # Heuristic: trees/bushes are foliage, road/sign/fence/light are props, else buildings
        if asset_name.find("tree") >= 0 or asset_name.find("bush") >= 0 or asset_name.find("hedge") >= 0 or asset_name.find("flower") >= 0 or asset_name.find("fern") >= 0 or asset_name.find("grass") >= 0 or asset_name.find("mushrooms") >= 0 or asset_name.find("cattail") >= 0 or asset_name.find("palm") >= 0 or asset_name.find("willow") >= 0 or asset_name.find("oak") >= 0 or asset_name.find("pine") >= 0 or asset_name.find("birch") >= 0 or asset_name.find("maple") >= 0 or asset_name.find("rocks") >= 0 or asset_name.find("log") >= 0 or asset_name.find("marsh") >= 0 or asset_name.find("crop") >= 0 or asset_name.find("hay") >= 0 or asset_name.find("ivy") >= 0 or asset_name.find("dead_tree") >= 0:
                return "foliage"
        # Roads/sidewalks/paths are special — skip them
        if asset_name.find("Road") >= 0 or asset_name.find("Sidewalk") >= 0 or asset_name.find("Lane") >= 0 or asset_name.find("Path") >= 0 or asset_name.find("Ground") >= 0 or asset_name.find("Parking") >= 0 or asset_name.find("Sand") >= 0 or asset_name.find("Water") >= 0 or asset_name.find("ParkGround") >= 0 or asset_name.find("Marsh") >= 0:
                return ""  # skip infrastructure planes
        # Chunk sub-nodes
        if asset_name.find("Chunk_") >= 0 or asset_name == "BakedCity" or asset_name == "Player" or asset_name == "Camera3D" or asset_name == "Col" or asset_name == "Sun" or asset_name == "WorldEnvironment" or asset_name == "Ground":
                return ""
        # Everything else is a prop
        return "props"

func _compute_aabb(node: Node3D) -> Dictionary:
        var aabb := AABB()
        var first := true
        for child in node.find_children("*", "MeshInstance3D", true, false):
                var mi: MeshInstance3D = child
                var mesh_aabb := mi.get_aabb()
                if mesh_aabb.size == Vector3.ZERO:
                        continue
                mesh_aabb.position += mi.position
                if first:
                        aabb = mesh_aabb
                        first = false
                else:
                        aabb = aabb.merge(mesh_aabb)
        if first:
                return {"min": [0,0,0], "max": [0,0,0], "size": [0,0,0]}
        # Transform to world space (apply node's position + scale)
        var world_min := aabb.position + node.position
        var world_max := aabb.position + aabb.size + node.position
        return {
                "min": [world_min.x, world_min.y, world_min.z],
                "max": [world_max.x, world_max.y, world_max.z],
                "size": [aabb.size.x, aabb.size.y, aabb.size.z],
        }

func _build_density_grid(chunk_data: Dictionary, origin: Vector3) -> Array:
        # 10×10 grid of 25m cells. R=road, B=building, F=foliage, P=prop, E=empty, O=occupied
        var grid: Array = []
        for r in range(10):
                var row_arr: Array = []
                for c in range(10):
                        row_arr.append("E")
                grid.append(row_arr)
        # Mark buildings
        for b in chunk_data["buildings"]:
                var pos: Array = b["pos"]
                var cx: int = clamp(int((pos[0] - origin.x) / 25.0), 0, 9)
                var cz: int = clamp(int((pos[2] - origin.z) / 25.0), 0, 9)
                grid[cz][cx] = "B"
        # Mark foliage
        for f in chunk_data["foliage"]:
                var pos: Array = f["pos"]
                var cx: int = clamp(int((pos[0] - origin.x) / 25.0), 0, 9)
                var cz: int = clamp(int((pos[2] - origin.z) / 25.0), 0, 9)
                if grid[cz][cx] == "E":
                        grid[cz][cx] = "F"
        # Mark props
        for p in chunk_data["props"]:
                var pos: Array = p["pos"]
                var cx: int = clamp(int((pos[0] - origin.x) / 25.0), 0, 9)
                var cz: int = clamp(int((pos[2] - origin.z) / 25.0), 0, 9)
                if grid[cz][cx] == "E":
                        grid[cz][cx] = "P"
        return grid

func _count_gaps(grid: Array) -> int:
        var count: int = 0
        for row in grid:
                for cell in row:
                        if cell == "E":
                                count += 1
        return count
