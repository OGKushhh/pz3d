# extends Node3D
#
# ChunkStreamer v7 — data-driven city generation with visible roads,
# gap filler, interior greenery, commercial on corners, parks every N blocks.
#
# Loads map data from map_data.json (biome grid, roads, POIs, services).
# Builds visible road meshes, places buildings along road segments,
# fills gaps, adds trees inside blocks, places parks, varies scale/rotation.
#
# All placement at Y=0 (flat ground). Terrain3D is disabled for now.

extends Node3D

const CityConfig = preload("res://tools/city_config.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const RoadNetwork = preload("res://tools/road_network.gd")
const PlanGrid = preload("res://tools/plan_grid.gd")
const TerrainHeight = preload("res://tools/terrain_height.gd")
const RiverNetwork = preload("res://tools/river_network.gd")

var player: Node3D
var stream_radius: int = 2
var spatial: SpatialIndex
var roads: RoadNetwork
var manifest: Dictionary = {}
var asset_cache: Dictionary = {}
var rng: RandomNumberGenerator
var plan_grid: PlanGrid
var terrain: TerrainHeight
var river: RiverNetwork
var _loaded: Dictionary = {}
var _build_queue: Array = []
var _builds_this_frame: int = 0
var _map_data: Dictionary = {}
var _pois_cache: Array = []

# Colors for road/sidewalk/grass meshes
const C_ROAD := Color(0.12, 0.12, 0.14, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_PARK := Color(0.18, 0.38, 0.14, 1)
const C_WATER := Color(0.15, 0.30, 0.45, 0.7)

# Placement constants
const LOT_W := 20.0
const LOT_D := 16.0
const BUILDING_OFFSET := 9.5  # road/2 + sidewalk + grass + setback

func _ready() -> void:
	await get_tree().process_frame
	var root := get_tree().current_scene
	player = root.get_node_or_null("Player")
	if player == null:
		for child in root.get_children():
			if child is CharacterBody3D:
				player = child
				break
	if player == null:
		push_error("[ChunkStreamer] No player found!")
		return

	# Load manifest
	var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
	if f:
		manifest = JSON.parse_string(f.get_as_text())
	print("[ChunkStreamer] manifest: %d assets" % manifest.size())

	# Load map data
	_load_map_data()

	spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
	roads = RoadNetwork.new()
	rng = RandomNumberGenerator.new()
	rng.seed = 1337

	# Load roads from map_data
	_load_roads_from_data()
	roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)

	plan_grid = PlanGrid.new()
	plan_grid.build(roads, 1337)

	river = RiverNetwork.new()
	terrain = TerrainHeight.new(1337, river)

	print("[ChunkStreamer] ready, player at %s" % player.global_position)

func _load_map_data():
	var f := FileAccess.open("res://data/map_data.json", FileAccess.READ)
	if f:
		_map_data = JSON.parse_string(f.get_as_text())
		print("[ChunkStreamer] map_data loaded: %d roads, %d POIs" % [
			_map_data.get("roads", []).size(),
			_map_data.get("pois", []).size()
		])
		_pois_cache = _map_data.get("pois", [])

func _load_roads_from_data():
	roads.segments.clear()
	for road in _map_data.get("roads", []):
		var start_arr: Array = road["start"]
		var end_arr: Array = road["end"]
		roads._add_segment(
			Vector3(start_arr[0], 0, start_arr[2]),
			Vector3(end_arr[0], 0, end_arr[2]),
			float(road.get("width", 8.0)),
			road.get("kind", "street"),
			road.get("name", "")
		)
	print("[ChunkStreamer] roads loaded: %d segments" % roads.segments.size())

func _process(_delta: float) -> void:
	if player == null or manifest.is_empty():
		return
	var cx: int = int(floor(player.global_position.x / CityConfig.CHUNK_SIZE_M))
	var cy: int = int(floor(player.global_position.z / CityConfig.CHUNK_SIZE_M))
	_builds_this_frame = 0
	_refresh(cx, cy)
	if not _build_queue.is_empty() and _builds_this_frame == 0:
		var next_key: Vector2i = _build_queue.pop_front()
		_build_chunk(next_key)
		_builds_this_frame += 1

func _refresh(cx: int, cy: int) -> void:
	var unload_r: int = stream_radius + CityConfig.STREAM_UNLOAD_BUFFER
	var wanted: Dictionary = {}
	for dy in range(-stream_radius, stream_radius + 1):
		for dx in range(-stream_radius, stream_radius + 1):
			var key := Vector2i(cx + dx, cy + dy)
			wanted[key] = true
			if not _loaded.has(key) and not _build_queue.has(key):
				_build_queue.append(key)
	var to_remove: Array = []
	for key in _loaded:
		if abs(key.x - cx) > unload_r or abs(key.y - cy) > unload_r:
			to_remove.append(key)
	for key in to_remove:
		_unload_chunk(key)

func _build_chunk(key: Vector2i) -> void:
	if key.x < 0 or key.y < 0 or key.x >= CityConfig.CHUNKS_COLS or key.y >= CityConfig.CHUNKS_ROWS:
		return
	var col: int = clamp(int(key.x * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
	var row: int = clamp(int(key.y * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
	var biome: int = CityConfig.grid_layout()[row][col]
	var profile: Dictionary = CityConfig.biomes().get(biome, {})
	if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
		return

	var origin: Vector3 = Vector3(key.x * CityConfig.CHUNK_SIZE_M, 0, key.y * CityConfig.CHUNK_SIZE_M)
	var chunk_root := Node3D.new()
	chunk_root.name = "Chunk_%d_%d" % [key.x, key.y]
	var crng := RandomNumberGenerator.new()
	crng.seed = hash(key) ^ 1337

	var b_count := 0
	var p_count := 0
	var f_count := 0
	var s_count := 0
	var l_count := 0

	# === VISIBLE ROADS ===
	_build_visible_roads(chunk_root, origin, CityConfig.CHUNK_SIZE_M)

	# === POI PLACEMENT ===
	var poi_exclusions: Array = []
	var pois := _get_pois_for_chunk(origin, CityConfig.CHUNK_SIZE_M)
	for poi in pois:
		var poi_asset: String = poi.get("type", "")
		var poi_scene: PackedScene = _get_asset(poi_asset)
		if poi_scene == null:
			continue
		var poi_pos := Vector3(float(poi.pos[0]), 0, float(poi.pos[2]))
		var poi_inst: Node3D = poi_scene.instantiate()
		poi_inst.position = poi_pos
		poi_inst.name = "POI_%s" % poi.get("id", poi_asset)
		chunk_root.add_child(poi_inst)
		spatial.insert(poi_pos, float(poi.get("radius", 30)))
		poi_exclusions.append({"center": poi_pos, "radius": float(poi.get("radius", 30))})
		l_count += 1

	# === BUILDINGS ALONG ROAD SEGMENTS ===
	var buildings: Array = profile.get("buildings", [])
	var commercial_buildings: Array = profile.get("commercial_buildings", ["corner_store", "diner", "gas_station", "corner_store"])
	var fill: float = profile.get("fill", 0.5)
	var building_radius: float = max(LOT_W, LOT_D) * 0.4

	# Get road segments that pass through this chunk
	var chunk_roads: Array = _get_roads_in_chunk(origin, CityConfig.CHUNK_SIZE_M)
	var placed := 0
	var target: int = int(fill * 40)

	for seg in chunk_roads:
		if placed >= target:
			break
		var a: Vector3 = seg["start"]
		var b: Vector3 = seg["end"]
		var length: float = a.distance_to(b)
		if length < 1.0:
			continue
		var dir: Vector3 = (b - a).normalized()
		var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
		var road_half_w: float = float(seg.get("width", 8.0)) * 0.5

		# Walk along segment at LOT_W intervals
		var d: float = LOT_W * 0.5
		while d < length and placed < target:
			var t: float = d / length
			var base_pos: Vector3 = a.lerp(b, t)

			# Check if near intersection (within 15m of a crossing road)
			var near_intersection := _is_near_intersection(base_pos, 15.0)

			for side in [-1, 1]:
				if placed >= target:
					break
				var lot_pos: Vector3 = base_pos + perp * float(side) * BUILDING_OFFSET
				# Check bounds
				if lot_pos.x < origin.x or lot_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
					continue
				if lot_pos.z < origin.z or lot_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
					continue
				if not spatial.is_free(lot_pos, building_radius) or spatial.is_on_road(lot_pos):
					continue
				if _is_in_poi_exclusion(lot_pos, poi_exclusions):
					continue
				if crng.randf() > fill:
					continue  # Empty lot (will be filled by gap filler)

				# Pick building: commercial at intersections, residential otherwise
				var bname: String
				if near_intersection and crng.randf() < 0.5 and not commercial_buildings.is_empty():
					bname = commercial_buildings[crng.randi() % commercial_buildings.size()]
				else:
					bname = buildings[crng.randi() % buildings.size()]

				var scene: PackedScene = _get_asset(bname)
				if scene == null:
					continue

				var inst: Node3D = scene.instantiate()
				inst.position = lot_pos
				# Face the road + slight rotation variation
				var face_angle: float = atan2(perp.x, perp.z) * float(side)
				inst.rotation.y = face_angle + crng.randf_range(-0.1, 0.1)
				# Scale variation (0.9-1.1)
				var scale_var: float = crng.randf_range(0.9, 1.1)
				inst.scale = Vector3(scale_var, crng.randf_range(0.95, 1.05), scale_var)
				inst.name = "%s_%d" % [bname, crng.randi() % 100000]
				chunk_root.add_child(inst)
				spatial.insert(lot_pos, building_radius)
				placed += 1
				b_count += 1

			d += LOT_W

	# === GAP FILLER — fill empty spaces with small props ===
	var props: Array = profile.get("props", [])
	var gap_fillers: Array = ["shed", "garage_detached", "picket_fence", "planter_box", "garden_gnome", "trash_can", "mailbox"]
	# Filter to assets that exist in manifest
	var valid_fillers: Array = []
	for gf in gap_fillers:
		if manifest.has(gf):
			valid_fillers.append(gf)

	var gap_count := int(fill * 15)
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
		# Place a gap filler
		if not valid_fillers.is_empty():
			var fname: String = valid_fillers[crng.randi() % valid_fillers.size()]
			var scene: PackedScene = _get_asset(fname)
			if scene:
				var inst: Node3D = scene.instantiate()
				inst.position = pos
				inst.rotation.y = crng.randf_range(0, TAU)
				inst.name = "%s_%d" % [fname, crng.randi() % 100000]
				chunk_root.add_child(inst)
				spatial.insert(pos, 2.0)
				p_count += 1

	# === INTERIOR GREENERY — trees/bushes inside blocks ===
	var foliage: Array = profile.get("foliage", [])
	if not foliage.is_empty():
		var green_count := int(fill * 25)
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
			var fname: String = foliage[crng.randi() % foliage.size()]
			var scene: PackedScene = _get_asset(fname)
			if scene == null:
				continue
			var inst: Node3D = scene.instantiate()
			inst.position = pos
			inst.rotation.y = crng.randf_range(0, TAU)
			# Scale variation for trees
			var tree_scale: float = crng.randf_range(0.8, 1.3)
			inst.scale = Vector3(tree_scale, tree_scale, tree_scale)
			inst.name = "%s_%d" % [fname, crng.randi() % 100000]
			chunk_root.add_child(inst)
			spatial.insert(pos, 3.0)
			f_count += 1

	# === PARKS — every 4th chunk, convert center to a park ===
	if (key.x + key.y) % 4 == 0 and biome != CityConfig.Biome.RIVER and biome != CityConfig.Biome.WATER:
		var park_center := origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5)
		_place_park(chunk_root, park_center, crng)

	# === STREET LIGHTS ===
	if profile.get("lights", false):
		_place_street_lights(chunk_root, chunk_roads, crng)

	add_child(chunk_root)
	_loaded[key] = chunk_root

	var bname: String = profile.get("name", "Unknown")
	print("chunk %d_%d: biome=%s buildings=%d props=%d foliage=%d lights=%d landmarks=%d children=%d" % [
		key.x, key.y, bname, b_count, p_count, f_count, s_count, l_count, chunk_root.get_child_count()
	])

func _build_visible_roads(chunk_root: Node3D, origin: Vector3, chunk_size: float) -> void:
	var chunk_roads: Array = _get_roads_in_chunk(origin, chunk_size)
	for seg in chunk_roads:
		var a: Vector3 = seg["start"]
		var b: Vector3 = seg["end"]
		var width: float = float(seg.get("width", 8.0))
		var length: float = a.distance_to(b)
		if length < 1.0:
			continue
		var mid: Vector3 = (a + b) * 0.5
		var dir: Vector3 = (b - a).normalized()

		# Road surface
		var is_horizontal: bool = abs(dir.z) > abs(dir.x)
		var road_size: Vector3 = Vector3(length, 0.02, width) if is_horizontal else Vector3(width, 0.02, length)
		_create_plane_mesh(chunk_root, "Road", mid, road_size, C_ROAD)

		# Center lane line (dashed — just a thin strip for now)
		var lane_size: Vector3 = Vector3(length, 0.03, 0.15) if is_horizontal else Vector3(0.15, 0.03, length)
		_create_plane_mesh(chunk_root, "Lane", mid, lane_size, C_LANE)

		# Sidewalks (both sides)
		var sw_off: float = width * 0.5 + CityConfig.SIDEWALK_WIDTH * 0.5
		var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
		var sw_size: Vector3 = Vector3(length, 0.05, CityConfig.SIDEWALK_WIDTH) if is_horizontal else Vector3(CityConfig.SIDEWALK_WIDTH, 0.05, length)
		_create_plane_mesh(chunk_root, "SW1", mid + perp * sw_off, sw_size, C_SIDEWALK)
		_create_plane_mesh(chunk_root, "SW2", mid - perp * sw_off, sw_size, C_SIDEWALK)

		# Grass strips
		var gs_off: float = width * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH * 0.5
		var gs_size: Vector3 = Vector3(length, 0.03, CityConfig.GRASS_STRIP_WIDTH) if is_horizontal else Vector3(CityConfig.GRASS_STRIP_WIDTH, 0.03, length)
		_create_plane_mesh(chunk_root, "GS1", mid + perp * gs_off, gs_size, C_GRASS)
		_create_plane_mesh(chunk_root, "GS2", mid - perp * gs_off, gs_size, C_GRASS)

func _create_plane_mesh(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name + "_" + str(randi() % 10000)
	var p := PlaneMesh.new()
	p.size = Vector2(size.x, size.z)
	mi.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = Vector3(pos.x, pos.y, pos.z)
	parent.add_child(mi)

func _place_park(chunk_root: Node3D, center: Vector3, crng: RandomNumberGenerator) -> void:
	# Park ground (darker green)
	_create_plane_mesh(chunk_root, "ParkGround", center, Vector3(60, 0.04, 60), C_PARK)

	# Park furniture
	var park_assets := ["bench_park", "picnic_table", "playground_slide", "swing_set", "water_fountain", "garden_gnome", "planter_box"]
	for asset_name in park_assets:
		if not manifest.has(asset_name):
			continue
		var scene: PackedScene = _get_asset(asset_name)
		if scene == null:
			continue
		var offset := Vector3(crng.randf_range(-20, 20), 0, crng.randf_range(-20, 20))
		var inst: Node3D = scene.instantiate()
		inst.position = center + offset
		inst.rotation.y = crng.randf_range(0, TAU)
		inst.name = "%s_park_%d" % [asset_name, crng.randi() % 100000]
		chunk_root.add_child(inst)

	# Trees in circle
	var tree_types := ["oak_tree", "pine_tree", "birch_tree"]
	for i in range(8):
		var angle := float(i) * 45.0
		var r := 20.0
		var tx := center.x + cos(deg_to_rad(angle)) * r
		var tz := center.z + sin(deg_to_rad(angle)) * r
		var tree_name: String = tree_types[i % tree_types.size()]
		var scene: PackedScene = _get_asset(tree_name)
		if scene:
			var inst: Node3D = scene.instantiate()
			inst.position = Vector3(tx, 0, tz)
			inst.rotation.y = float(i * 53)
			inst.name = "%s_park_%d" % [tree_name, crng.randi() % 100000]
			chunk_root.add_child(inst)

func _place_street_lights(chunk_root: Node3D, chunk_roads: Array, crng: RandomNumberGenerator) -> void:
	var scene: PackedScene = _get_asset("street_light")
	if scene == null:
		return
	var edge_offset: float = CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH * 0.5
	for seg in chunk_roads:
		var a: Vector3 = seg["start"]
		var b: Vector3 = seg["end"]
		var length: float = a.distance_to(b)
		if length < 25.0:
			continue
		var dir: Vector3 = (b - a).normalized()
		var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
		var d: float = 12.0
		while d < length - 12.0:
			var t: float = d / length
			var base: Vector3 = a.lerp(b, t)
			for side in [-1, 1]:
				var pos: Vector3 = base + perp * edge_offset * float(side)
				if spatial.is_free(pos, 0.5) and not spatial.is_on_road(pos):
					var inst: Node3D = scene.instantiate()
					inst.position = pos
					inst.rotation.y = 0.0 if side < 0 else PI
					inst.name = "street_light_%d" % crng.randi()
					chunk_root.add_child(inst)
					spatial.insert(pos, 0.5)
			d += 25.0

func _get_roads_in_chunk(origin: Vector3, chunk_size: float) -> Array:
	var result: Array = []
	var min_x: float = origin.x
	var max_x: float = origin.x + chunk_size
	var min_z: float = origin.z
	var max_z: float = origin.z + chunk_size
	for seg in roads.segments:
		var a: Vector3 = seg["start"]
		var b: Vector3 = seg["end"]
		# Check if segment passes through chunk bounds
		if max(a.x, b.x) < min_x or min(a.x, b.x) > max_x:
			continue
		if max(a.z, b.z) < min_z or min(a.z, b.z) > max_z:
			continue
		result.append(seg)
	return result

func _is_near_intersection(pos: Vector3, threshold: float) -> bool:
	for seg in roads.segments:
		var a: Vector3 = seg["start"]
		var b: Vector3 = seg["end"]
		# Check if pos is near a road that's perpendicular to another road at this point
		var dist := _point_segment_distance(pos, a, b)
		if dist < threshold:
			# Check if there's another road crossing near here
			for seg2 in roads.segments:
				if seg == seg2:
					continue
				var a2: Vector3 = seg2["start"]
				var b2: Vector3 = seg2["end"]
				# Check if the two segments cross near pos
				var d1 := _point_segment_distance(pos, a2, b2)
				if d1 < threshold:
					return true
	return false

func _unload_chunk(key: Vector2i) -> void:
	var inst: Node3D = _loaded[key]
	inst.queue_free()
	_loaded.erase(key)

func _get_pois_for_chunk(origin: Vector3, chunk_size: float) -> Array:
	var result: Array = []
	for poi in _pois_cache:
		var px: float = float(poi.pos[0])
		var pz: float = float(poi.pos[2])
		if px >= origin.x and px < origin.x + chunk_size and pz >= origin.z and pz < origin.z + chunk_size:
			result.append(poi)
	return result

static func _is_in_poi_exclusion(pos: Vector3, exclusions: Array) -> bool:
	for exc in exclusions:
		var center: Vector3 = exc["center"]
		var radius: float = exc["radius"]
		if pos.distance_to(center) < radius:
			return true
	return false

func _get_asset(p_name: String) -> PackedScene:
	if asset_cache.has(p_name):
		return asset_cache[p_name]
	if not manifest.has(p_name):
		return null
	var s: PackedScene = load(manifest[p_name]["path"]) as PackedScene
	asset_cache[p_name] = s
	return s

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	if ab.length_squared() < 0.001:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
