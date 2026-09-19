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
const CityGenConfig = preload("res://tools/city_gen_config.gd")
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
const OUTPUT_DIR := "res://scenes/baked_chunks/"
var gen_config: CityGenConfig
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

# Biome density multiplier (matches chunk_streamer)

# === ENTRY POINT ===
func _init():
        gen_config = CityGenConfig.new()
        gen_config.seed = SEED
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

        # Make output directory
        DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

        # Global environment setup (sky + sun + ground — these go in a separate "world" scene)
        _setup_sky()
        _setup_sun()
        _setup_ground()

        # Bake each chunk as a separate .res file
        var build_start := Time.get_ticks_msec()
        for col in range(BAKE_ORIGIN_COL, BAKE_ORIGIN_COL + BAKE_COLS):
                for row in range(BAKE_ORIGIN_ROW, BAKE_ORIGIN_ROW + BAKE_ROWS):
                        if col < 0 or row < 0 or col >= CityConfig.CHUNKS_COLS or row >= CityConfig.CHUNKS_ROWS:
                                continue
                        _bake_chunk_to_file(col, row)
        var build_ms := Time.get_ticks_msec() - build_start
        print("  Build time: %.2fs" % (build_ms / 1000.0))

        # Save the world scene (sky + sun + ground + player + ChunkStreamer loader)
        # Player + ChunkLoader are added via text edit after bake (avoids
        # autoload resolution issues when running as SceneTree script)
        # _setup_player() and _setup_chunk_loader() are skipped — see _write_player_to_tscn()
        _write_player_to_tscn()

        # Set owner recursively for the world scene
        _set_owner_recursive(city_root, city_root)

        var save_start := Time.get_ticks_msec()
        var scene := PackedScene.new()
        var pack_err := scene.pack(city_root)
        if pack_err != OK:
                print("❌ Pack failed: ", pack_err)
                quit(1)
                return
        var save_flags := ResourceSaver.FLAG_COMPRESS
        var err := ResourceSaver.save(scene, "res://scenes/baked_world.tscn")
        if err == OK:
                var save_ms := Time.get_ticks_msec() - save_start
                print("✅ World scene saved: res://scenes/baked_world.tscn")
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
        var color: Color = CityGenConfig.C_LOCAL if kind == "street" else CityGenConfig.C_HIGHWAY
        if kind == "highway":
                width += 2.0
        # Road surface
        _plane("Road", center, length, width, color, CityGenConfig.Y_ROAD)
        # Center lane line
        if length > 20.0:
                _plane("Lane", center, length, 0.15, CityGenConfig.C_LANE, CityGenConfig.Y_LANE)
        # Sidewalks (both sides)
        var sw_w := 1.5
        var sw_off := width * 0.5 + sw_w * 0.5
        # Sidewalk positions (perpendicular to road direction)
        var perp_x := cos(yaw)
        var perp_z := -sin(yaw)
        _plane("Sidewalk", center + Vector3(perp_x * sw_off, 0, perp_z * sw_off), length, sw_w, CityGenConfig.C_SIDEWALK, CityGenConfig.Y_SIDEWALK)
        _plane("Sidewalk", center - Vector3(perp_x * sw_off, 0, perp_z * sw_off), length, sw_w, CityGenConfig.C_SIDEWALK, CityGenConfig.Y_SIDEWALK)

# === CHUNK BAKER (saves each chunk to its own .res file) ===
func _bake_chunk_to_file(col: int, row: int):
        var origin := Vector3(col * CityConfig.CHUNK_SIZE_M, 0, row * CityConfig.CHUNK_SIZE_M)
        var grid_col: int = clamp(int(col * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
        var grid_row: int = clamp(int(row * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
        var biome: int = CityConfig.grid_layout()[grid_row][grid_col]
        if biome == CityConfig.Biome.WATER or biome == CityConfig.Biome.EMPTY:
                return  # skip water/empty chunks entirely

        var profile: Dictionary = CityConfig.biomes().get(biome, {})
        if profile.is_empty():
                return

        # Per-chunk RNG
        var crng := RandomNumberGenerator.new()
        crng.seed = SEED + col * 1000 + row

        # Per-chunk root node (will be saved as its own .res)
        var chunk_root := Node3D.new()
        chunk_root.name = "Chunk_%d_%d" % [col, row]

        # Debug: per-biome colored ground plane (helps distinguish biomes while testing)
        # Sits at Y=0.001 (just above ground) so roads/sidewalks render on top
        var biome_color: Color = CityConfig.ground_color_for(biome)
        _plane_in_parent(chunk_root, "BiomeGround", origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5), CityConfig.CHUNK_SIZE_M, CityConfig.CHUNK_SIZE_M, biome_color, 0.001)

        # Place POIs in this chunk
        # FIX: POIs declared on road centerlines (e.g. at exact 500m grid intersections)
        # are nudged OFF the road before placement. User: "a tower and a stadium on roads".
        var poi_exclusions: Array = []
        for poi in map_data.get("pois", []):
                var poi_pos_arr: Array = poi.get("pos", [0, 0, 0])
                var poi_pos := Vector3(float(poi_pos_arr[0]), 0, float(poi_pos_arr[2]))
                if poi_pos.x < origin.x or poi_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
                        continue
                if poi_pos.z < origin.z or poi_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
                        continue
                var poi_asset: String = poi.get("type", "")
                var poi_radius: float = float(poi.get("radius", 30))
                # Nudge POI off road if too close (< 15m = on or near road)
                poi_pos = _nudge_off_road(poi_pos, poi_radius)
                var poi_scene := _get_asset(poi_asset)
                if poi_scene:
                        var poi_inst := poi_scene.instantiate()
                        poi_inst.position = poi_pos
                        poi_inst.name = "POI_" + poi.get("id", poi_asset)
                        chunk_root.add_child(poi_inst)
                        spatial.insert(poi_pos, poi_radius)
                        poi_exclusions.append({"center": poi_pos, "radius": poi_radius})
                        _global_poi_exclusions.append({"center": poi_pos, "radius": poi_radius})
                        placed_count += 1

        # Stamp district template
        var template_name: String = stamper.pick_template_for_biome(biome, crng)
        if template_name != "":
                var anchor_pos := origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5)
                var template_rot := crng.randf_range(0, TAU)
                var template_placed: int = stamper.stamp_template(template_name, anchor_pos, template_rot, chunk_root, crng, self)
                if template_placed > 0:
                        spatial.insert(anchor_pos, 75.0)
                        poi_exclusions.append({"center": anchor_pos, "radius": 75.0})

        # Generate parcels
        var layout_type: String = BlockLayout.layout_for_biome(biome)
        var parcels: Array = BlockLayout.generate_parcels(layout_type, origin, CityConfig.CHUNK_SIZE_M)
        for parcel in parcels:
                var info: Dictionary = roads.nearest_road_info(parcel.building_pos)
                if info.get("found", false):
                        parcel.road_edge_pos = info["point"]
                        parcel.road_distance = info["distance"]
                        parcel.road_dir = info["direction"]
                        var to_road: Vector3 = info["point"] - parcel.building_pos
                        if to_road.length() > 0.1:
                                parcel.front_dir = to_road.normalized()

        # Draw interior paths
        var paths: Array = BlockLayout.get_interior_paths(layout_type, origin, CityConfig.CHUNK_SIZE_M)
        for path in paths:
                var p_center := Vector3((path["start"].x + path["end"].x) * 0.5, CityGenConfig.Y_PATH, (path["start"].z + path["end"].z) * 0.5)
                var p_len: float = path["start"].distance_to(path["end"])
                var p_width: float = float(path.get("width", 3.0))
                var p_yaw: float = atan2(path["end"].x - path["start"].x, path["end"].z - path["start"].z)
                _create_plane_mesh_rotated(chunk_root, "Path", p_center, Vector2(p_width, p_len), Color(0.25, 0.25, 0.27, 1), p_yaw)

        # Density target
        var fill: float = _get_density_for_cell(grid_col, grid_row, profile)
        var biome_mult: int = gen_config.get_density_mult(biome)
        var target: int = int(fill * biome_mult)
        var placed := 0
        var building_radius: float = max(gen_config.LOT_W, gen_config.LOT_D) * 0.4

        # Place buildings per parcel
        for parcel in parcels:
                if placed >= target:
                        break
                var lot_pos: Vector3 = parcel.building_pos
                if lot_pos.x < origin.x or lot_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
                        continue
                if lot_pos.z < origin.z or lot_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
                        continue
                if not spatial.is_free(lot_pos, building_radius):
                        continue
                if spatial.is_on_road(lot_pos):
                        continue
                if _is_in_poi_exclusion(lot_pos, poi_exclusions):
                        continue
                if _is_near_highway(lot_pos):
                        continue

                var lot_name: String = lot_stamper.pick_lot_for_biome(biome, crng)
                if lot_name != "" and crng.randf() <= fill:
                        var lot_placed: int = lot_stamper.stamp_lot(lot_name, parcel, chunk_root, crng, self, biome)
                        if lot_placed > 0:
                                spatial.insert(lot_pos, building_radius)
                                _register_asset_position("lot_" + lot_name, lot_pos)
                                placed += lot_placed
                                placed_count += lot_placed
                                continue

                if crng.randf() > fill:
                        continue

                var buildings_pool: Array = profile.get("buildings", [])
                if buildings_pool.is_empty():
                        continue
                var bname: String = ""
                for _attempt in range(3):
                        var candidate: String = buildings_pool[crng.randi() % buildings_pool.size()]
                        var type_count: int = _get_district_type_count(biome, candidate)
                        if type_count < 5:
                                bname = candidate
                                break
                if bname == "":
                        continue

                var inst: Node3D = _spawn_building(bname, lot_pos, parcel.front_dir, crng, chunk_root)
                if inst == null:
                        continue
                var new_aabb := _compute_aabb(inst)
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

        # Foliage scatter
        var foliage: Array = profile.get("foliage", [])
        if not foliage.is_empty():
                var foliage_mult: int = gen_config.get_foliage_mult(biome)
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
                        spatial.insert(pos, 3.0)
                        placed_count += 1

        # Props scatter — increased density + per-biome variety (fills empty spaces)
        # User: "places between dense places are hella empty, we might need to put things between
        # instead of all foliage for performance, woods stay woods of course"
        var gap_fillers: Array = []
        # Per-biome gap filler pool — each biome gets appropriate props for its identity
        match biome:
                CityConfig.Biome.SUBURBIA:
                        # Residential: yard props + light street furniture
                        gap_fillers = [
                                "picket_fence", "mailbox", "trash_can", "garden_gnome",
                                "planter_box", "fire_hydrant", "street_light", "bollard",
                                "bench_park", "picnic_table", "water_fountain",
                                "playground_slide", "swing_set", "seesaw",
                                "shopping_cart", "traffic_cone"
                        ]
                CityConfig.Biome.COMMERCIAL:
                        # Storefronts: parking + commercial clutter
                        gap_fillers = [
                                "parking_meter", "shopping_cart", "dumpster", "trash_can",
                                "bollard", "planter_box", "street_light", "traffic_cone",
                                "construction_barrier", "bench_park", "picnic_table",
                                "fire_hydrant", "mailbox", "traffic_light"
                        ]
                CityConfig.Biome.INDUSTRIAL:
                        # Heavy industrial: containers + barriers + machinery
                        gap_fillers = [
                                "shipping_container", "storage_tank", "loading_dock",
                                "dumpster", "construction_barrier", "barrier_concrete",
                                "guard_rail", "chain_link_fence", "barbed_wire_fence",
                                "sandbag", "traffic_cone", "bollard", "street_light",
                                "utility_pole", "power_pole"
                        ]
                CityConfig.Biome.DOWNTOWN:
                        # Urban core: bollards + planters + street furniture
                        gap_fillers = [
                                "bollard", "planter_box", "trash_can", "street_light",
                                "bench_park", "water_fountain", "parking_meter",
                                "traffic_light", "fire_hydrant", "construction_barrier",
                                "turnstile", "manhole_cover", "sewer_grate"
                        ]
                CityConfig.Biome.MILITARY:
                        # Military: barriers + sandbags + checkpoints
                        gap_fillers = [
                                "barrier_concrete", "sandbag", "barbed_wire_fence",
                                "chain_link_fence", "guard_rail", "bollard",
                                "traffic_cone", "construction_barrier", "street_light",
                                "shipping_container", "storage_tank"
                        ]
                CityConfig.Biome.FARMLAND:
                        # Rural: fences + hay + irrigation
                        gap_fillers = [
                                "hay_bale", "wood_fence_post", "picket_fence",
                                "irrigation_canal", "planter_box", "trash_can",
                                "bench_park", "picnic_table", "fire_hydrant",
                                "street_light", "mailbox", "garden_gnome"
                        ]
                CityConfig.Biome.COASTAL_BEACH:
                        # Beach: boardwalk + benches + palms (already in foliage)
                        gap_fillers = [
                                "bench_park", "picnic_table", "trash_can", "planter_box",
                                "street_light", "water_fountain", "gazebo", "park_sign",
                                "mailbox", "traffic_cone"
                        ]
                CityConfig.Biome.WETLANDS:
                        # Marsh: minimal urban props, keep natural
                        gap_fillers = [
                                "fallen_log", "rocks_small", "boardwalk_section",
                                "trash_can", "park_sign"
                        ]
                CityConfig.Biome.PARKS:
                        # Park: benches + playground + picnic
                        gap_fillers = [
                                "bench_park", "picnic_table", "playground_slide",
                                "swing_set", "seesaw", "water_fountain", "park_sign",
                                "planter_box", "trash_can", "garden_gnome",
                                "fire_hydrant", "street_light"
                        ]
                CityConfig.Biome.FOREST:
                        # Woods stay woods — only natural props
                        gap_fillers = ["fallen_log", "rocks_small", "bush"]
                _:
                        # Default fallback
                        gap_fillers = [
                                "picket_fence", "planter_box", "trash_can", "mailbox",
                                "fire_hydrant", "street_light", "bollard", "bench_park"
                        ]
        var valid_fillers: Array = []
        for gf in gap_fillers:
                if manifest.has(gf):
                        valid_fillers.append(gf)
        # Increased from fill*20 to fill*40 (2x more gap fillers)
        var gap_count: int = int(fill * 40)
        for i in range(gap_count):
                var pos := Vector3(
                        origin.x + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 15.0),
                        0,
                        origin.z + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 5.0)
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
                        spatial.insert(pos, 2.0)
                        placed_count += 1

        # Set owner recursively for this chunk
        _set_owner_recursive(chunk_root, chunk_root)

        # Save this chunk as its own .res file
        var chunk_scene := PackedScene.new()
        var pack_err := chunk_scene.pack(chunk_root)
        if pack_err == OK:
                var chunk_path := "%schunk_%d_%d.tscn" % [OUTPUT_DIR, col, row]
                var save_err := ResourceSaver.save(chunk_scene, chunk_path)
                if save_err != OK:
                        push_warning("[MapBaker] Failed to save chunk %d_%d: %s" % [col, row, save_err])
        # Free the chunk node (it's saved to disk, no longer needed in memory)
        chunk_root.queue_free()

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
        # Set owner to parent (chunk_root or city_root depending on context)
        mi.owner = parent
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
                if d < gen_config.HIGHWAY_CLEARANCE_M:
                        return true
        return false

# FIX: Nudge a POI position OFF the road if it's too close to a road centerline.
# User reported: "a tower and a stadium on roads". POIs declared at exact grid
# intersections (e.g. 1500,500) land exactly on road centerlines.
#
# Strategy: query nearest road. If distance < (road_half_width + poi_radius + 5m buffer),
# move the POI away from the road by the shortfall + extra buffer.
# Picks the side (X or Z) that has more space (avoids nudging into a wall/edge).
func _nudge_off_road(pos: Vector3, poi_radius: float) -> Vector3:
        var info: Dictionary = roads.nearest_road_info(pos)
        if not info.get("found", false):
                return pos  # no road nearby, leave as-is
        var road_dist: float = float(info.get("distance", 0.0))
        var road_point: Vector3 = info.get("point", pos)
        var road_dir: Vector3 = info.get("direction", Vector3.FORWARD)
        # Estimate road half-width from the road's kind (streets=4m, highways=6m, bridges=6m)
        # We don't have the actual road width here without the segment, so use a safe default
        var road_half_w: float = 6.0  # generous: covers highways + sidewalks
        var safe_dist: float = road_half_w + poi_radius + 5.0  # 5m extra buffer
        if road_dist >= safe_dist:
                return pos  # already far enough, no nudge needed
        # Need to move POI (safe_dist - road_dist) meters away from road centerline
        var nudge_amount: float = safe_dist - road_dist
        # Direction from road point to POI (perpendicular to road, pointing AWAY from road)
        var away_dir: Vector3 = (pos - road_point).normalized()
        if away_dir.length() < 0.01:
                # POI is exactly ON road centerline — pick perpendicular to road direction
                away_dir = Vector3(-road_dir.z, 0, road_dir.x).normalized()
        var nudged_pos: Vector3 = pos + away_dir * nudge_amount
        return nudged_pos

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

# Like _plane but adds to a specific parent (for chunk-local ground planes)
func _plane_in_parent(parent: Node3D, name_prefix: String, center: Vector3, size_x: float, size_z: float, color: Color, y_offset: float):
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
        parent.add_child(mi)
        mi.owner = parent
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
        _plane("GroundMesh", Vector3(CityConfig.MAP_SIZE_M.x * 0.5, 0, CityConfig.MAP_SIZE_M.y * 0.5), CityConfig.MAP_SIZE_M.x + 100, CityConfig.MAP_SIZE_M.y + 100, CityGenConfig.C_GRASS, 0.0)

# Recursively set owner on all descendants of root to owner_node.
# This ensures ResourceSaver.pack() saves every node in the tree.
func _set_owner_recursive(root: Node, owner_node: Node):
        for child in root.get_children():
                if child.owner != owner_node:
                        child.owner = owner_node
                _set_owner_recursive(child, owner_node)


# === CHUNK LOADER ===
# No longer needed — MazarPlayer handles chunk loading internally via _refresh_chunks().
func _setup_chunk_loader():
    pass  # MazarPlayer has built-in chunk streaming

# Write Player node to baked_world.tscn as text (avoids autoload issues with SceneTree script)
func _write_player_to_tscn() -> void:
        # After the scene is saved, append a Player node as an instance reference
        # This avoids needing Cogito autoloads during bake (SceneTree doesn't have them)
        var path := "res://scenes/baked_world.tscn"
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
                push_error("[MapBaker] Can't open baked_world.tscn for player append")
                return
        var content := f.get_as_text()
        f.close()
        # Add ext_resource for Cogito player + MazarPlayer script if not already present
        if not "cogito_player_advanced.tscn" in content:
                content = content.replace(
                        '[node name="BakedCity"',
                        '[ext_resource type="PackedScene" path="res://addons/cogito/PackedScenes/cogito_player_advanced.tscn" id="cogito_player"]\n[ext_resource type="Script" path="res://scripts/mazar_player.gd" id="mazar_player_script"]\n\n[node name="BakedCity"'
                )
        # Add Player node at the end (if not already present)
        if not '[node name="Player"' in content:
                content += '\n[node name="Player" parent="." instance=ExtResource("cogito_player")]\n'
                content += 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 375, 2, 375)\n'
                content += 'script = ExtResource("mazar_player_script")\n'
        f = FileAccess.open(path, FileAccess.WRITE)
        if f:
                f.store_string(content)
                f.close()
                print("  ✓ Player node (MazarPlayer) written to baked_world.tscn")
        else:
                push_error("[MapBaker] Can't write player to baked_world.tscn")
