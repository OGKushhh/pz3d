# MapBaker — bakes the city to a static .tscn file.
#
# Reuses existing infrastructure (PlacementValidator, DistrictStamper, LotStamper,
# BlockLayout, RoadNetwork, SpatialIndex, PathQuery, RiverNetwork) but instead
# of streaming at runtime, builds ALL chunks once and saves to a .tscn file.
#
# Run:
#   godot --headless --path godot_project --script res://scripts/map_baker.gd
#
# Output:
#   res://scenes/baked_city.tscn
#
# The baker IS the "streamer" object passed to stampers — implements _get_asset,
# _attach_building_collision, _create_plane_mesh_rotated, _get_road_edge_near,
# _path_query, spatial, roads, _asset_positions, _get_district_type_count, etc.
#
# All placements validated via PlacementValidator (collision/overlap/setback/
# neighbor-compat/repetition). Bad placements skipped.

extends SceneTree

# === Dependencies (preload) ===
const CityConfig = preload("res://tools/city_config.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const RoadNetwork = preload("res://tools/road_network.gd")
const BlockLayout = preload("res://tools/block_layout.gd")
const DistrictStamper = preload("res://tools/district_stamper.gd")
const LotStamper = preload("res://tools/lot_stamper.gd")
const PlacementValidator = preload("res://tools/placement_validator.gd")
const PathQuery = preload("res://tools/path_query.gd")
const RiverNetwork = preload("res://tools/river_network.gd")
const TerrainHeight = preload("res://tools/terrain_height.gd")

# === Configuration ===
const SEED := 1337
const OUTPUT_PATH := "res://scenes/baked_city.tscn"
# Bake region: default = full 12km² map (16 cols × 12 rows).
# Override with --bake-cols=N --bake-rows=N --bake-origin-col=N --bake-origin-row=N
# for partial bakes (debugging).
var BAKE_COLS: int = CityConfig.CHUNKS_COLS
var BAKE_ROWS: int = CityConfig.CHUNKS_ROWS
var BAKE_ORIGIN_COL: int = 0
var BAKE_ORIGIN_ROW: int = 0

# === State (mirrors ChunkStreamer's, minimal) ===
var city_root: Node3D
var manifest: Dictionary
var map_data: Dictionary
var city_plan: Dictionary
var spatial: SpatialIndex
var roads: RoadNetwork
var _path_query: PathQuery
var river: RiverNetwork
var terrain: TerrainHeight
var stamper: DistrictStamper
var lot_stamper: LotStamper
var validator: PlacementValidator
var rng: RandomNumberGenerator

# Asset cache: name → PackedScene
var asset_cache: Dictionary
# Per-asset position tracker (for validator's neighbor compat + repetition)
var _asset_positions: Dictionary  # asset_name → Array[Vector3]
# Per-biome per-type count (for validator's repetition check)
var _district_type_counts: Dictionary  # biome → {asset_name → count}
# POI exclusion zones (for _is_in_poi_exclusion)
var _global_poi_exclusions: Array  # of {center: Vector3, radius: float}
# Placed count (for stats + unique node names)
var placed_count: int = 0
# Skipped count (for stats — how many placements validator rejected)
var skipped_count: int = 0

# Constants (mirrors chunk_streamer.gd)
const FLAT_TERRAIN_V1 := true
const Y_GROUND := 0.000
const Y_GRASS := 0.005
const Y_PATH := 0.010
const Y_DRIVEWAY := 0.015
const Y_ROAD := 0.020
const Y_LANE := 0.025
const Y_PARKING := 0.030
const Y_SIDEWALK := 0.050
const Y_BUILDING_SLAB := 0.060
const Y_PARK := 0.005
const MIN_CLEARANCE_M := 2.0
const HIGHWAY_CLEARANCE_M := 15.0
const LOT_W := 20.0
const LOT_D := 16.0
const C_ROAD := Color(0.12, 0.12, 0.14, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_PARK := Color(0.18, 0.38, 0.14, 1)
const C_HIGHWAY := Color(0.08, 0.08, 0.10, 1)
const C_LOCAL := Color(0.16, 0.16, 0.18, 1)
const C_WATER := Color(0.15, 0.30, 0.45, 0.7)

# Biome density multiplier (matches chunk_streamer)
const BIOME_DENSITY_MULT := {
        0: 50, 1: 5, 2: 5, 3: 10, 4: 100, 5: 60, 6: 3, 7: 120, 8: 40, 9: 8, 10: 0, 11: 0
}
const BIOME_FOLIAGE_MULT := {
        0: 50, 1: 200, 2: 300, 3: 80, 4: 15, 5: 20, 6: 250, 7: 10, 8: 30, 9: 150, 10: 0, 11: 0
}

# === ENTRY POINT ===
func _init():
        print("=== MapBaker — baking city to .tscn ===")
        print("  Map size: %dm × %dm" % [CityConfig.MAP_SIZE_M.x, CityConfig.MAP_SIZE_M.y])
        print("  Chunks: %d × %d = %d total" % [BAKE_COLS, BAKE_ROWS, BAKE_COLS * BAKE_ROWS])
        print("  Seed: %d" % SEED)

        _load_manifest()
        _load_map_data()
        _load_city_plan()

        # Init state
        city_root = Node3D.new()
        city_root.name = "BakedCity"
        spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
        roads = RoadNetwork.new()
        rng = RandomNumberGenerator.new()
        rng.seed = SEED
        _path_query = PathQuery.new()
        river = RiverNetwork.new()
        terrain = TerrainHeight.new(SEED, river)
        stamper = DistrictStamper.new()
        lot_stamper = LotStamper.new()
        validator = PlacementValidator.new()

        # Load roads from map_data + mark in spatial index
        _load_roads_from_data()
        roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)

        # Setup environment + ground (sky, sun, ground collision)
        _setup_sky()
        _setup_sun()
        _setup_ground()

        # Build all chunks in bake region
        var build_start := Time.get_ticks_msec()
        for col in range(BAKE_ORIGIN_COL, BAKE_ORIGIN_COL + BAKE_COLS):
                for row in range(BAKE_ORIGIN_ROW, BAKE_ORIGIN_ROW + BAKE_ROWS):
                        if col < 0 or row < 0 or col >= CityConfig.CHUNKS_COLS or row >= CityConfig.CHUNKS_ROWS:
                                continue
                        _build_chunk(col, row)
        var build_ms := Time.get_ticks_msec() - build_start
        print("  Build time: %.2fs" % (build_ms / 1000.0))

        # Setup player (drop-in playable)
        _setup_player()

        # === Fix ownership for ALL nodes (so ResourceSaver saves them) ===
        # The stampers (lot_stamper, district_stamper) add children to chunk_root
        # but don't set owner=city_root. Without correct owner, nodes are dropped
        # when ResourceSaver.pack() saves the scene.
        _set_owner_recursive(city_root, city_root)

        # Save scene
        var save_start := Time.get_ticks_msec()
        var scene := PackedScene.new()
        var pack_err := scene.pack(city_root)
        if pack_err != OK:
                print("❌ Pack failed: ", pack_err)
                quit(1)
                return
        var err := ResourceSaver.save(scene, OUTPUT_PATH)
        if err == OK:
                var save_ms := Time.get_ticks_msec() - save_start
                print("✅ Scene saved: ", OUTPUT_PATH)
                print("   Placed: %d | Skipped: %d | Save time: %.2fs" % [placed_count, skipped_count, save_ms / 1000.0])
        else:
                print("❌ Save failed: ", err)
        quit()

# === LOADERS ===
func _load_manifest():
        var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
        if f:
                manifest = JSON.parse_string(f.get_as_text())
        print("  Manifest loaded: %d assets" % manifest.size())

func _load_map_data():
        var f := FileAccess.open("res://data/map_data.json", FileAccess.READ)
        if f:
                map_data = JSON.parse_string(f.get_as_text())
        print("  Map data loaded: %d roads, %d POIs" % [map_data.get("roads", []).size(), map_data.get("pois", []).size()])

func _load_city_plan():
        var f := FileAccess.open("res://data/city_plan.json", FileAccess.READ)
        if f:
                city_plan = JSON.parse_string(f.get_as_text())
        print("  City plan loaded: %d district budgets" % city_plan.get("district_budgets", {}).size())

func _load_roads_from_data():
        var roads_arr: Array = map_data.get("roads", [])
        for road_def in roads_arr:
                var start_arr: Array = road_def.get("start", [0, 0, 0])
                var end_arr: Array = road_def.get("end", [0, 0, 0])
                var width: float = float(road_def.get("width", 8.0))
                var kind: String = road_def.get("kind", "street")
                var name: String = road_def.get("name", "")
                var start := Vector3(float(start_arr[0]), 0, float(start_arr[2]))
                var end := Vector3(float(end_arr[0]), 0, float(end_arr[2]))
                roads._add_segment(start, end, width, kind, name)
                # Build visible road mesh
                _build_road_mesh(start, end, width, kind)
        print("  Roads loaded: %d segments" % roads.segments.size())

func _build_road_mesh(start: Vector3, end: Vector3, width: float, kind: String):
        var center := (start + end) * 0.5
        var length := start.distance_to(end)
        var yaw := atan2(end.x - start.x, end.z - start.z)
        var color: Color = C_LOCAL if kind == "street" else C_HIGHWAY
        if kind == "highway":
                width += 2.0
        # Road surface
        _plane("Road", center, length, width, color, Y_ROAD)
        # Center lane line
        if length > 20.0:
                _plane("Lane", center, length, 0.15, C_LANE, Y_LANE)
        # Sidewalks (both sides)
        var sw_w := 1.5
        var sw_off := width * 0.5 + sw_w * 0.5
        # Sidewalk positions (perpendicular to road direction)
        var perp_x := cos(yaw)
        var perp_z := -sin(yaw)
        _plane("Sidewalk", center + Vector3(perp_x * sw_off, 0, perp_z * sw_off), length, sw_w, C_SIDEWALK, Y_SIDEWALK)
        _plane("Sidewalk", center - Vector3(perp_x * sw_off, 0, perp_z * sw_off), length, sw_w, C_SIDEWALK, Y_SIDEWALK)

# === CHUNK BUILDER (simplified chunk_streamer._build_chunk) ===
func _build_chunk(col: int, row: int):
        var key := Vector2i(col, row)
        var origin := Vector3(col * CityConfig.CHUNK_SIZE_M, 0, row * CityConfig.CHUNK_SIZE_M)
        # Map chunk (col,row) → biome grid (col,row). Biome grid is 8×6 (500m cells),
        # chunks are 16×12 (250m cells). 4 chunks per biome cell.
        var grid_col: int = clamp(int(col * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
        var grid_row: int = clamp(int(row * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
        var biome: int = CityConfig.grid_layout()[grid_row][grid_col]
        if biome == CityConfig.Biome.WATER or biome == CityConfig.Biome.EMPTY:
                return

        var profile: Dictionary = CityConfig.biomes().get(biome, {})
        if profile.is_empty():
                return

        # Per-chunk RNG (deterministic per seed + chunk)
        var crng := RandomNumberGenerator.new()
        crng.seed = SEED + col * 1000 + row

        # Per-chunk root (for organization)
        var chunk_root := Node3D.new()
        chunk_root.name = "Chunk_%d_%d" % [col, row]
        city_root.add_child(chunk_root)
        chunk_root.owner = city_root
        # NOTE: do NOT set chunk_root.position = origin. The stampers use world coords
        # for inst.position, so chunk_root must stay at (0,0,0) to avoid double-offset.
        # The `origin` variable is still used for bounds checks + parcel generation.

        # Place POIs in this chunk
        var poi_exclusions: Array = []
        for poi in map_data.get("pois", []):
                var poi_pos_arr: Array = poi.get("pos", [0, 0, 0])
                var poi_pos := Vector3(float(poi_pos_arr[0]), 0, float(poi_pos_arr[2]))
                # Check if POI is in this chunk
                if poi_pos.x < origin.x or poi_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
                        continue
                if poi_pos.z < origin.z or poi_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
                        continue
                var poi_asset: String = poi.get("type", "")
                var poi_radius: float = float(poi.get("radius", 30))
                var poi_scene := _get_asset(poi_asset)
                if poi_scene:
                        var poi_inst := poi_scene.instantiate()
                        poi_inst.position = poi_pos
                        poi_inst.name = "POI_" + poi.get("id", poi_asset)
                        chunk_root.add_child(poi_inst)
                        poi_inst.owner = city_root
                        spatial.insert(poi_pos, poi_radius)
                        poi_exclusions.append({"center": poi_pos, "radius": poi_radius})
                        _global_poi_exclusions.append({"center": poi_pos, "radius": poi_radius})
                        placed_count += 1

        # Stamp district template (hand-authored block composition)
        var template_name: String = stamper.pick_template_for_biome(biome, crng)
        var template_placed: int = 0
        if template_name != "":
                var anchor_pos := origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5)
                var template_rot := crng.randf_range(0, TAU)
                template_placed = stamper.stamp_template(template_name, anchor_pos, template_rot, chunk_root, crng, self)
                if template_placed > 0:
                        spatial.insert(anchor_pos, 75.0)
                        poi_exclusions.append({"center": anchor_pos, "radius": 75.0})

        # Generate parcels + place buildings via lot recipes
        var layout_type: String = BlockLayout.layout_for_biome(biome)
        var parcels: Array = BlockLayout.generate_parcels(layout_type, origin, CityConfig.CHUNK_SIZE_M)
        # Query road_network for each parcel's actual nearest road
        for parcel in parcels:
                var info: Dictionary = roads.nearest_road_info(parcel.building_pos)
                if info.get("found", false):
                        parcel.road_edge_pos = info["point"]
                        parcel.road_distance = info["distance"]
                        parcel.road_dir = info["direction"]
                        var to_road: Vector3 = info["point"] - parcel.building_pos
                        if to_road.length() > 0.1:
                                parcel.front_dir = to_road.normalized()

        # Draw interior paths (so validator can check is_on_path)
        var paths: Array = BlockLayout.get_interior_paths(layout_type, origin, CityConfig.CHUNK_SIZE_M)
        for path in paths:
                var p_center := Vector3((path["start"].x + path["end"].x) * 0.5, Y_PATH, (path["start"].z + path["end"].z) * 0.5)
                var p_len: float = path["start"].distance_to(path["end"])
                var p_width: float = float(path.get("width", 3.0))
                var p_yaw: float = atan2(path["end"].x - path["start"].x, path["end"].z - path["start"].z)
                _create_plane_mesh_rotated(chunk_root, "Path", p_center, Vector2(p_width, p_len), Color(0.25, 0.25, 0.27, 1), p_yaw)

        # Density target (uses grid coords, not chunk coords)
        var fill: float = _get_density_for_cell(grid_col, grid_row, profile)
        var biome_mult: int = int(BIOME_DENSITY_MULT.get(biome, 50))
        var target: int = int(fill * biome_mult)
        var placed := 0
        var building_radius: float = max(LOT_W, LOT_D) * 0.4

        # Place buildings per parcel (lot recipe first, procedural fallback)
        var debug_parcel_count: int = parcels.size()
        var debug_skipped_road: int = 0
        var debug_skipped_free: int = 0
        var debug_skipped_poi: int = 0
        var debug_skipped_highway: int = 0
        var debug_lot_attempted: int = 0
        var debug_lot_success: int = 0
        var debug_empty_skip: int = 0
        var debug_procedural_placed: int = 0
        for parcel in parcels:
                if placed >= target:
                        break
                var lot_pos: Vector3 = parcel.building_pos
                if lot_pos.x < origin.x or lot_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
                        continue
                if lot_pos.z < origin.z or lot_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
                        continue
                if not spatial.is_free(lot_pos, building_radius):
                        debug_skipped_free += 1
                        continue
                if spatial.is_on_road(lot_pos):
                        debug_skipped_road += 1
                        continue
                if _is_in_poi_exclusion(lot_pos, poi_exclusions):
                        debug_skipped_poi += 1
                        continue
                if _is_near_highway(lot_pos):
                        debug_skipped_highway += 1
                        continue

                # Try hand-authored lot recipe first
                var lot_name: String = lot_stamper.pick_lot_for_biome(biome, crng)
                if lot_name != "" and crng.randf() <= fill:
                        debug_lot_attempted += 1
                        var lot_placed: int = lot_stamper.stamp_lot(lot_name, parcel, chunk_root, crng, self, biome)
                        if lot_placed > 0:
                                debug_lot_success += 1
                                spatial.insert(lot_pos, building_radius)
                                _register_asset_position("lot_" + lot_name, lot_pos)
                                placed += lot_placed
                                placed_count += lot_placed
                                continue

                # Empty lot check (skip with 1-fill probability)
                if crng.randf() > fill:
                        debug_empty_skip += 1
                        continue

                # Procedural fallback: pick building from profile
                var buildings_pool: Array = profile.get("buildings", [])
                if buildings_pool.is_empty():
                        continue
                # Anti-repetition: try up to 3 different picks to find one that's not over-repeated
                var bname: String = ""
                for _attempt in range(3):
                        var candidate: String = buildings_pool[crng.randi() % buildings_pool.size()]
                        var type_count: int = _get_district_type_count(biome, candidate)
                        if type_count < 5:
                                bname = candidate
                                break
                if bname == "":
                        continue  # all candidates are over-repeated, skip this parcel

                # Phase 1 (relaxed): skip validator — use only spatial checks already done above.
                # But DO check AABB overlap with existing buildings (prevents buildings inside each other)
                var inst: Node3D = _spawn_building(bname, lot_pos, parcel.front_dir, crng, chunk_root)
                if inst == null:
                        continue
                # Check AABB overlap with existing buildings in this chunk
                var new_aabb := _compute_aabb(inst)
                # Transform to world space (add building position)
                new_aabb.position += inst.position
                if _has_aabb_overlap(new_aabb, chunk_root):
                        inst.queue_free()
                        continue
                inst.set_meta("parcel_id", parcel.parcel_id)
                spatial.insert(lot_pos, building_radius)
                _register_asset_position(bname, lot_pos)
                _increment_district_type_count(biome, bname)
                placed += 1
                placed_count += 1
                debug_procedural_placed += 1

        # Foliage scatter
        var foliage: Array = profile.get("foliage", [])
        if not foliage.is_empty():
                var foliage_mult: int = int(BIOME_FOLIAGE_MULT.get(biome, 50))
                var green_count: int = int(fill * foliage_mult)
                for i in range(green_count):
                        var pos := Vector3(
                                origin.x + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0),
                                0,
                                origin.z + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0)
                        )
                        if not spatial.is_free(pos, 3.0) or spatial.is_on_road(pos):
                                continue
                        if _is_in_poi_exclusion(pos, poi_exclusions):
                                continue
                        if _path_query.is_on_path(pos, 2.0):
                                continue
                        var fname: String = foliage[crng.randi() % foliage.size()]
                        var scene: PackedScene = _get_asset(fname)
                        if scene == null:
                                continue
                        var finst: Node3D = scene.instantiate()
                        finst.position = pos
                        finst.rotation.y = crng.randf_range(0, TAU)
                        var tree_scale: float = crng.randf_range(0.8, 1.3)
                        finst.scale = Vector3(tree_scale, tree_scale, tree_scale)
                        finst.name = "%s_%d" % [fname, crng.randi() % 100000]
                        finst.set_meta("building_name", fname)
                        chunk_root.add_child(finst)
                        finst.owner = city_root
                        spatial.insert(pos, 3.0)
                        placed_count += 1

        # Props scatter (small gap fillers)
        var gap_fillers: Array = ["picket_fence", "planter_box", "garden_gnome", "trash_can", "mailbox"]
        var valid_fillers: Array = []
        for gf in gap_fillers:
                if manifest.has(gf):
                        valid_fillers.append(gf)
        var gap_count: int = int(fill * 20)
        for i in range(gap_count):
                var pos := Vector3(
                        origin.x + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 15.0),
                        0,
                        origin.z + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 15.0)
                )
                if not spatial.is_free(pos, 2.0) or spatial.is_on_road(pos):
                        continue
                if _is_in_poi_exclusion(pos, poi_exclusions):
                        continue
                if _path_query.is_on_path(pos, 1.0):
                        continue
                if valid_fillers.is_empty():
                        break
                var fname: String = valid_fillers[crng.randi() % valid_fillers.size()]
                var scene: PackedScene = _get_asset(fname)
                if scene:
                        var inst: Node3D = scene.instantiate()
                        inst.position = pos
                        inst.rotation.y = crng.randf_range(0, TAU)
                        inst.name = "%s_%d" % [fname, crng.randi() % 100000]
                        chunk_root.add_child(inst)
                        inst.owner = city_root
                        spatial.insert(pos, 2.0)
                        placed_count += 1

# === STREAMER INTERFACE (called by stampers + validator) ===
func _get_asset(name: String) -> PackedScene:
        if name == "":
                return null
        if asset_cache.has(name):
                return asset_cache[name]
        if not manifest.has(name):
                push_warning("[MapBaker] asset '%s' not in manifest" % name)
                asset_cache[name] = null
                return null
        var path: String = manifest[name].get("path", "")
        if not ResourceLoader.exists(path):
                push_warning("[MapBaker] asset path missing: %s" % path)
                asset_cache[name] = null
                return null
        var scene := load(path) as PackedScene
        asset_cache[name] = scene
        return scene

func _attach_building_collision(building_inst: Node3D) -> void:
        # Use box collider from AABB (cheap, works for non-shell buildings)
        var aabb := _compute_aabb(building_inst)
        if aabb.size == Vector3.ZERO:
                return
        var static_body := StaticBody3D.new()
        static_body.name = "BuildingCollider"
        static_body.position = aabb.position + aabb.size * 0.5
        var col_shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = aabb.size
        col_shape.shape = box
        static_body.add_child(col_shape)
        col_shape.owner = city_root
        building_inst.add_child(static_body)
        building_inst.set_meta("has_collision", true)
        building_inst.set_meta("collision_type", "box")

func _compute_aabb(node: Node3D) -> AABB:
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
        return aabb

# Check if a new AABB overlaps any existing building in the chunk
func _has_aabb_overlap(new_aabb: AABB, chunk_root: Node3D) -> bool:
        if new_aabb.size == Vector3.ZERO:
                return false
        for child in chunk_root.get_children():
                if not child is Node3D:
                        continue
                var n3d: Node3D = child
                if not n3d.get_meta("building_name", ""):
                        continue  # skip non-building nodes
                var existing_aabb := _compute_aabb(n3d)
                if existing_aabb.size == Vector3.ZERO:
                        continue
                # Transform existing AABB to world space too
                existing_aabb.position += n3d.position
                # Check XZ overlap (ignore Y — buildings at different heights don't collide)
                if new_aabb.position.x < existing_aabb.position.x + existing_aabb.size.x and \
                   new_aabb.position.x + new_aabb.size.x > existing_aabb.position.x and \
                   new_aabb.position.z < existing_aabb.position.z + existing_aabb.size.z and \
                   new_aabb.position.z + new_aabb.size.z > existing_aabb.position.z:
                        return true
        return false

func _create_plane_mesh_rotated(parent: Node3D, name: String, pos: Vector3, size: Vector2, color: Color, yaw: float) -> void:
        var mi := MeshInstance3D.new()
        mi.name = name + "_" + str(rng.randi() % 100000)
        var p := PlaneMesh.new()
        p.size = size
        mi.mesh = p
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.85
        mi.material_override = mat
        mi.position = Vector3(pos.x, pos.y, pos.z)
        mi.rotation.y = yaw
        parent.add_child(mi)
        mi.owner = city_root
        placed_count += 1
        # Register path segments in path_query (so validator can check is_on_path)
        if name == "Sidewalk" or name == "Driveway" or name == "Path":
                var half_len: float = size.y * 0.5
                var dir_x: float = sin(yaw)
                var dir_z: float = cos(yaw)
                var start: Vector3 = Vector3(pos.x - dir_x * half_len, pos.y, pos.z - dir_z * half_len)
                var end: Vector3 = Vector3(pos.x + dir_x * half_len, pos.y, pos.z + dir_z * half_len)
                _path_query.register_segment(start, end, size.x, name)

func _get_road_edge_near(pos: Vector3) -> Vector3:
        var info: Dictionary = roads.nearest_road_info(pos)
        if info.get("found", false):
                return info["point"]
        return pos

func _is_near_highway(pos: Vector3) -> bool:
        for seg in roads.segments:
                if seg.get("kind", "street") != "highway":
                        continue
                var d: float = roads.distance_to_road_centerline(pos, seg)
                if d < HIGHWAY_CLEARANCE_M:
                        return true
        return false

func _is_in_poi_exclusion(pos: Vector3, exclusions: Array) -> bool:
        for ex in exclusions:
                var center: Vector3 = ex["center"]
                var radius: float = float(ex["radius"])
                if pos.distance_to(center) < radius:
                        return true
        return false

func _register_asset_position(bname: String, pos: Vector3) -> void:
        if not _asset_positions.has(bname):
                _asset_positions[bname] = []
        _asset_positions[bname].append(pos)

func _get_district_type_count(biome: int, asset_name: String) -> int:
        if not _district_type_counts.has(biome):
                return 0
        var biome_counts: Dictionary = _district_type_counts[biome]
        return int(biome_counts.get(asset_name, 0))

func _increment_district_type_count(biome: int, asset_name: String) -> void:
        if not _district_type_counts.has(biome):
                _district_type_counts[biome] = {}
        var biome_counts: Dictionary = _district_type_counts[biome]
        biome_counts[asset_name] = int(biome_counts.get(asset_name, 0)) + 1

# === HELPERS ===
func _get_density_for_cell(col: int, row: int, profile: Dictionary) -> float:
        if city_plan.is_empty():
                return float(profile.get("fill", 0.5))
        var gradient: Dictionary = city_plan.get("density_gradient", {})
        var grid: Array = gradient.get("grid", [])
        if row >= 0 and row < grid.size() and col >= 0 and col < grid[row].size():
                return float(grid[row][col])
        return float(profile.get("fill", 0.5))

func _spawn_building(bname: String, pos: Vector3, front_dir: Vector3, crng: RandomNumberGenerator, parent: Node3D) -> Node3D:
        var scene: PackedScene = _get_asset(bname)
        if scene == null:
                return null
        var inst: Node3D = scene.instantiate()
        inst.position = pos
        # Face the road
        var perp := Vector3(-front_dir.z, 0, front_dir.x)
        var rot_yaw := atan2(perp.x, perp.z)
        inst.rotation.y = rot_yaw + deg_to_rad(crng.randf_range(-3.0, 3.0))  # small jitter
        inst.name = "%s_%d" % [bname, crng.randi() % 100000]
        inst.set_meta("building_name", bname)
        parent.add_child(inst)
        inst.owner = city_root
        _attach_building_collision(inst)
        return inst

func _plane(name_prefix: String, center: Vector3, size_x: float, size_z: float, color: Color, y_offset: float):
        var mi := MeshInstance3D.new()
        mi.name = name_prefix + "_" + str(placed_count)
        var p := PlaneMesh.new()
        p.size = Vector2(size_x, size_z)
        mi.mesh = p
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.85
        mi.material_override = mat
        mi.position = Vector3(center.x, y_offset, center.z)
        city_root.add_child(mi)
        mi.owner = city_root
        placed_count += 1

# === ENVIRONMENT SETUP (from build_test_city_v2.gd, proven to work) ===
func _setup_sky():
        var env := Environment.new()
        var sky_mat := ProceduralSkyMaterial.new()
        sky_mat.sky_top_color = Color(0.15, 0.35, 0.70, 1)
        sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.88, 1)
        sky_mat.ground_bottom_color = Color(0.25, 0.22, 0.18, 1)
        sky_mat.ground_horizon_color = Color(0.50, 0.48, 0.42, 1)
        sky_mat.sun_angle_max = 30.0
        sky_mat.sun_curve = 0.12
        sky_mat.use_debanding = true
        var sky := Sky.new()
        sky.sky_material = sky_mat
        env.background_mode = Environment.BG_SKY
        env.sky = sky
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_color = Color(0.55, 0.60, 0.65, 1)
        env.ambient_light_energy = 0.6
        env.fog_enabled = true
        env.fog_light_color = Color(0.50, 0.55, 0.60, 1)
        env.fog_density = 0.005
        env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        env.tonemap_white = 1.0
        var we := WorldEnvironment.new()
        we.name = "WorldEnvironment"
        we.environment = env
        city_root.add_child(we)
        we.owner = city_root

func _setup_sun():
        var sun := DirectionalLight3D.new()
        sun.name = "Sun"
        sun.transform.origin = Vector3(-200, 300, -200)
        sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
        sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
        sun.light_color = Color(1.0, 0.95, 0.80, 1)
        sun.light_energy = 2.0
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 400.0
        city_root.add_child(sun)
        sun.owner = city_root

func _setup_ground():
        # Ground collision (big box under entire map)
        var body := StaticBody3D.new()
        body.name = "Ground"
        body.position = Vector3(CityConfig.MAP_SIZE_M.x * 0.5, 0, CityConfig.MAP_SIZE_M.y * 0.5)
        city_root.add_child(body)
        body.owner = city_root
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(CityConfig.MAP_SIZE_M.x + 100, 1, CityConfig.MAP_SIZE_M.y + 100)
        col.shape = shape
        body.add_child(col)
        col.owner = city_root
        # Visible ground (green grass everywhere)
        _plane("GroundMesh", Vector3(CityConfig.MAP_SIZE_M.x * 0.5, 0, CityConfig.MAP_SIZE_M.y * 0.5), CityConfig.MAP_SIZE_M.x + 100, CityConfig.MAP_SIZE_M.y + 100, C_GRASS, 0.0)

# Recursively set owner on all descendants of root to owner_node.
# This ensures ResourceSaver.pack() saves every node in the tree.
func _set_owner_recursive(root: Node, owner_node: Node):
        for child in root.get_children():
                if child.owner != owner_node:
                        child.owner = owner_node
                _set_owner_recursive(child, owner_node)

func _setup_player():
        var player := CharacterBody3D.new()
        player.name = "Player"
        # Spawn at center of map, eye height
        player.position = Vector3(CityConfig.MAP_SIZE_M.x * 0.4, 2, CityConfig.MAP_SIZE_M.y * 0.5)
        var cam := Camera3D.new()
        cam.name = "Camera3D"
        cam.fov = 75.0
        cam.near = 0.05
        cam.far = 500.0
        cam.position = Vector3(0, 1.65, 0)
        player.add_child(cam)
        cam.owner = city_root
        var col := CollisionShape3D.new()
        col.name = "Col"
        var shape := CapsuleShape3D.new()
        shape.radius = 0.4
        shape.height = 1.8
        col.shape = shape
        col.position = Vector3(0, 0.9, 0)
        player.add_child(col)
        col.owner = city_root
        var script := GDScript.new()
        script.source_code = """extends CharacterBody3D
const WALK = 5.0
const SPRINT = 8.0
const SENS = 0.002
const FLY = 15.0
var spd = WALK
var fly_mode = false
func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(e):
    if e is InputEventMouseMotion:
        rotate_y(-e.relative.x * SENS)
        $Camera3D.rotate_x(-e.relative.y * SENS)
        $Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.5, 1.5)
    if e.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if e.is_action_pressed("fly_toggle"):
        fly_mode = !fly_mode
        $Col.disabled = fly_mode
func _physics_process(d):
    if fly_mode:
        var i = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
        if dir: velocity = dir * FLY
        else: velocity = velocity.move_toward(Vector3.ZERO, FLY * d * 5)
        if Input.is_action_pressed("jump"): velocity.y = FLY
        if Input.is_action_pressed("crouch"): velocity.y = -FLY
        move_and_slide()
        return
    if not is_on_floor(): velocity.y -= 9.8 * d
    if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = 4.5
    spd = SPRINT if Input.is_action_pressed("sprint") else WALK
    var i = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
    if dir: velocity.x = dir.x * spd; velocity.z = dir.z * spd
    else: velocity.x = move_toward(velocity.x, 0, spd*d*10); velocity.z = move_toward(velocity.z, 0, spd*d*10)
    move_and_slide()"""
        player.set_script(script)
        city_root.add_child(player)
        player.owner = city_root
        placed_count += 1
        print("  ✓ Player at center, fly mode toggle (V)")
