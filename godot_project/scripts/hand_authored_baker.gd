# HandAuthoredBaker — bakes a hand-authored test map from JSON data.
#
# SIDE TEST — does NOT replace city_gen_v2.gd (procedural gen stays as-is).
#
# Reads data/hand_authored_map.json + places:
#   1. Highways as polyline road meshes
#   2. Coastal road + military bridge
#   3. Each landmark at its exact [x, z] position (with the matching asset)
#   4. For each district: generates a recipe-based plan via BlockRecipes
#      (using district's center/radius/shape to spawn buildings)
#
# Output:
#   scenes/hand_authored.tscn  (the test map — open in Godot editor)
#
# Use:
#   godot --headless --path godot_project --script res://scripts/hand_authored_baker.gd
#
# Comparison vs city_gen_v2:
#   - city_gen_v2: procedural placement, anchor-based districts
#   - hand_authored: human-defined district centers, exact landmark positions
#   - Both use BlockRecipes for buildings within each district
#   - The hand-authored map should feel like the map you drew, not a random gen

extends SceneTree

# === Dependencies ===
const BlockRecipes = preload("res://tools/block_recipes.gd")
const RoadGraphV2 = preload("res://tools/road_graph_v2.gd")

# === Output paths ===
const MAP_DATA_PATH := "res://data/hand_authored_map.json"
const OUTPUT_SCENE := "res://scenes/hand_authored.tscn"

# === Y layering (matches city_v2_baker) ===
const Y_GROUND := 0.000
const Y_DISTRICT_GROUND := 0.010
const Y_ROAD := 0.030
const Y_LANE := 0.035
const Y_SIDEWALK := 0.050

# === Colors ===
const C_HIGHWAY := Color(0.08, 0.08, 0.10, 1)
const C_ARTERIAL := Color(0.12, 0.12, 0.14, 1)
const C_LOCAL := Color(0.16, 0.16, 0.18, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_SEA := Color(0.10, 0.30, 0.45, 1)
const C_BRIDGE := Color(0.35, 0.30, 0.25, 1)

# === District ground colors (debug distinct — same as city_v2_baker) ===
const DISTRICT_COLORS := {
	"forest": Color(0.20, 0.35, 0.15),
	"suburbia": Color(0.35, 0.52, 0.20),
	"parks": Color(0.40, 0.60, 0.25),
	"farmland": Color(0.55, 0.48, 0.22),
	"industrial": Color(0.35, 0.33, 0.30),
	"downtown": Color(0.40, 0.38, 0.35),
	"commercial": Color(0.45, 0.43, 0.40),
	"coastal": Color(0.85, 0.80, 0.55),  # sandy beach
	"military": Color(0.50, 0.45, 0.35),
}

# === Landmark -> asset_name mapping (uses city_manifest.json asset names) ===
# All landmarks now have assets (built in Blender, 2026-09-24)
const LANDMARK_ASSETS := {
	"Subway Entrance": "subway_entrance",
	"Suburbia Power Substation": "power_substation",
	"The Old Royal Palace": "old_royal_palace",
	"The Grain Silo": "grain_silo",
	"The Grand Bazaar": "grand_bazaar",
	"The Broadcast Tower": "broadcast_tower",
	"The Hospital": "hospital",
	"The Police HQ": "police_station",
	"The Government Palace": "government_palace",
	"The Stadium": "stadium",
	"The Fire Station": "fire_station",
	"The Water Tower": "water_tower_small",
	"The Railway Station": "railway_station",
	"Industrial Power Plant": "power_plant",
	"The Lighthouse": "lighthouse",
	"Fort Sarran": "fort_sarran",
}

# === State ===
var manifest: Dictionary
var asset_cache: Dictionary = {}
var placed_count: int = 0
var skipped_landmarks: int = 0

func _init():
	print("=== HandAuthoredBaker — building test map from JSON ===")
	_load_manifest()

	# Load the hand-authored map JSON
	var map_data: Dictionary = _load_map_data()
	if map_data.is_empty():
		printerr("  ERROR: can't load map data")
		quit(1)
		return

	var map_w: int = int(map_data.map_size[0])
	var map_d: int = int(map_data.map_size[1])
	print("  Map: %dm x %dm = %.1f km²" % [map_w, map_d, float(map_w * map_d) / 1_000_000.0])

	var t0 := Time.get_ticks_msec()

	# Build the scene
	var root := Node3D.new()
	root.name = "HandAuthoredMap"

	# 1. Sky + sun + ground (same setup as city_v2_baker)
	_setup_sky(root)
	_setup_sun(root)
	_setup_ground(root, map_w, map_d)
	_setup_sea(root, map_w, map_d)  # sea on south + east edges

	# 2. District grounds (colored circles/areas at each district center)
	_render_district_grounds(root, map_data.districts)

	# 3. Highways (polyline road meshes)
	_render_highways(root, map_data.highways)
	print("  Highways: %d placed" % map_data.highways.size())

	# 4. Coastal road
	if map_data.has("coastal_road"):
		_render_polyline_road(root, map_data.coastal_road.path, map_data.coastal_road.width, C_ARTERIAL)
		print("  Coastal road: 1 placed")

	# 4b. Arterials (mid-tier roads connecting districts)
	var arterial_count: int = 0
	for arterial in map_data.get("arterials", []):
		_render_polyline_road(root, arterial.path, arterial.width, C_ARTERIAL)
		arterial_count += 1
	print("  Arterials: %d placed" % arterial_count)

	# 4c. Local streets (small roads within districts)
	var local_count: int = 0
	for local in map_data.get("local_streets", []):
		_render_polyline_road(root, local.path, local.width, C_LOCAL)
		local_count += 1
	print("  Local streets: %d placed" % local_count)

	# 5. Military bridge
	if map_data.has("military_bridge"):
		var b: Dictionary = map_data.military_bridge
		_render_bridge(root, Vector3(b.from[0], 0, b.from[1]), Vector3(b.to[0], 0, b.to[1]), b.width)
		print("  Military bridge: 1 placed")

	# 6. Landmarks (exact positions from JSON)
	var skipped_landmark_names: Array = []
	_place_landmarks(root, map_data.landmarks, skipped_landmark_names)
	print("  Landmarks: %d placed, %d skipped (no asset)" % [placed_count, skipped_landmarks])
	if not skipped_landmark_names.is_empty():
		print("    Skipped landmark names:")
		for lm_name in skipped_landmark_names:
			print("      - %s" % lm_name)

	# 7. Buildings within each district (via BlockRecipes)
	var buildings_placed: int = 0
	for district in map_data.districts:
		buildings_placed += _fill_district_with_recipes(root, district, map_w, map_d)
	print("  Buildings (recipe-based): %d placed" % buildings_placed)

	# Save
	_set_owner_recursive(root, root)
	var scene := PackedScene.new()
	var pack_err := scene.pack(root)
	if pack_err != OK:
		printerr("  ERROR: pack failed: ", pack_err)
		quit(1)
		return
	ResourceSaver.save(scene, OUTPUT_SCENE)

	var t1 := Time.get_ticks_msec()
	print("  Total placements: %d" % placed_count)
	print("  Build time: %dms" % (t1 - t0))
	print("✅ Saved: %s" % OUTPUT_SCENE)
	quit()

# === LOADERS ===
func _load_manifest():
	var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
	if f:
		manifest = JSON.parse_string(f.get_as_text())
	print("  Manifest: %d assets" % manifest.size())

func _load_map_data() -> Dictionary:
	var f := FileAccess.open(MAP_DATA_PATH, FileAccess.READ)
	if f == null:
		printerr("  ERROR: can't open ", MAP_DATA_PATH)
		return {}
	var json_text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		printerr("  ERROR: JSON parse failed")
		return {}
	return parsed

func _get_asset(name: String) -> PackedScene:
	if name == "" or name == "skip":
		return null
	if asset_cache.has(name):
		return asset_cache[name]
	if not manifest.has(name):
		return null
	var path: String = manifest[name].get("path", "")
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	asset_cache[name] = scene
	return scene

# === SKY / SUN / GROUND / SEA ===

func _setup_sky(root: Node3D):
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.35, 0.70, 1)
	sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.88, 1)
	sky_mat.ground_bottom_color = Color(0.25, 0.22, 0.18, 1)
	sky_mat.ground_horizon_color = Color(0.50, 0.48, 0.42, 1)
	sky_mat.sun_curve = 0.12
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
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)
	we.owner = root

func _setup_sun(root: Node3D):
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform.origin = Vector3(-200, 300, -200)
	sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
	sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
	sun.light_color = Color(1.0, 0.95, 0.80, 1)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 400.0
	root.add_child(sun)
	sun.owner = root

func _setup_ground(root: Node3D, map_w: int, map_d: int):
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.position = Vector3(map_w / 2.0, 0, map_d / 2.0)
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(map_w + 100, 1, map_d + 100)
	col.shape = shape
	body.add_child(col)
	col.owner = root
	var mi := MeshInstance3D.new()
	mi.name = "GroundMesh"
	var p := PlaneMesh.new()
	p.size = Vector2(map_w + 100, map_d + 100)
	mi.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = C_GRASS
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)
	mi.owner = root

# Sea on south + east edges (water plane + ground dip)
# Simple approach: place a large blue plane below the map for south + east water
func _setup_sea(root: Node3D, map_w: int, map_d: int):
	# South sea (extends below z=map_d)
	var south_mi := MeshInstance3D.new()
	south_mi.name = "SeaSouth"
	var south_p := PlaneMesh.new()
	south_p.size = Vector2(map_w + 200, 400)
	south_mi.mesh = south_p
	var south_mat := StandardMaterial3D.new()
	south_mat.albedo_color = C_SEA
	south_mat.roughness = 0.3
	south_mat.metallic = 0.5
	south_mi.material_override = south_mat
	south_mi.position = Vector3(map_w / 2.0, -0.5, map_d + 200)
	root.add_child(south_mi)
	south_mi.owner = root

	# East sea (extends beyond x=map_w)
	var east_mi := MeshInstance3D.new()
	east_mi.name = "SeaEast"
	var east_p := PlaneMesh.new()
	east_p.size = Vector2(400, map_d + 200)
	east_mi.mesh = east_p
	var east_mat := StandardMaterial3D.new()
	east_mat.albedo_color = C_SEA
	east_mat.roughness = 0.3
	east_mat.metallic = 0.5
	east_mi.material_override = east_mat
	east_mi.position = Vector3(map_w + 200, -0.5, map_d / 2.0)
	root.add_child(east_mi)
	east_mi.owner = root

# === DISTRICT GROUNDS ===
# Place a colored circle/disc at each district center to visualize district boundaries
func _render_district_grounds(root: Node3D, districts: Array):
	for d in districts:
		var center: Vector3 = Vector3(d.center[0], 0, d.center[1])
		var radius: float = float(d.radius)
		var district_name: String = d.name
		var ground_color: Color = DISTRICT_COLORS.get(district_name, C_GRASS)
		# Place a flat disc mesh at the district center
		var mi := MeshInstance3D.new()
		mi.name = "DistrictGround_%s" % district_name
		var disc := PlaneMesh.new()
		disc.size = Vector2(radius * 2.0, radius * 2.0)
		mi.mesh = disc
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ground_color
		mat.roughness = 0.9
		mi.material_override = mat
		mi.position = Vector3(center.x, Y_DISTRICT_GROUND, center.z)
		root.add_child(mi)
		mi.owner = root
		placed_count += 1

# === HIGHWAYS (polyline roads) ===
func _render_highways(root: Node3D, highways: Array):
	for hw in highways:
		_render_polyline_road(root, hw.path, hw.width, C_HIGHWAY)

# Render a polyline as a series of road segment meshes
func _render_polyline_road(root: Node3D, path: Array, width: float, color: Color):
	if path.size() < 2:
		return
	for i in range(path.size() - 1):
		var p1: Vector3 = Vector3(path[i][0], 0, path[i][1])
		var p2: Vector3 = Vector3(path[i + 1][0], 0, path[i + 1][1])
		_render_road_segment(root, p1, p2, width, color)

# Render one road segment as a plane mesh
func _render_road_segment(root: Node3D, start: Vector3, end: Vector3, width: float, color: Color):
	var center := (start + end) * 0.5
	var length := start.distance_to(end)
	var yaw := atan2(end.x - start.x, end.z - start.z)
	_plane(root, "Road", center, length, width, color, Y_ROAD, yaw)

# Render a bridge (different color + raised slightly)
func _render_bridge(root: Node3D, start: Vector3, end: Vector3, width: float):
	var center := (start + end) * 0.5
	var length := start.distance_to(end)
	var yaw := atan2(end.x - start.x, end.z - start.z)
	_plane(root, "Bridge", center, length, width, C_BRIDGE, Y_ROAD + 0.5, yaw)  # raised 0.5m above road

# === LANDMARKS ===
func _place_landmarks(root: Node3D, landmarks: Array, skipped_names: Array):
	for lm in landmarks:
		var lm_name: String = lm.name
		var pos: Vector3 = Vector3(lm.pos[0], 0, lm.pos[1])
		var asset_name: String = LANDMARK_ASSETS.get(lm_name, "skip")
		if asset_name == "skip":
			skipped_landmarks += 1
			skipped_names.append(lm_name + " (mapped to skip)")
			continue
		var scene: PackedScene = _get_asset(asset_name)
		if scene == null:
			skipped_landmarks += 1
			skipped_names.append(lm_name + " (asset '" + asset_name + "' not found in manifest)")
			continue
		var inst: Node3D = scene.instantiate()
		inst.position = pos
		inst.rotation.y = deg_to_rad(0.0)
		inst.name = "%s_%d" % [asset_name, placed_count]
		inst.set_meta("landmark_name", lm_name)
		root.add_child(inst)
		inst.owner = root
		placed_count += 1

# === FILL DISTRICT WITH RECIPES ===
# For each district, generate a plan via BlockRecipes and place the buildings.
# We treat the district as a single "block" — using apply_recipe with a virtual block.
func _fill_district_with_recipes(root: Node3D, district: Dictionary, map_w: int, map_d: int) -> int:
	var district_name: String = district.name
	var center: Vector3 = Vector3(district.center[0], 0, district.center[1])
	var radius: float = float(district.radius)
	var seed_val: int = int(center.x) * 31 + int(center.z) * 17 + 1337

	# Build a virtual block representing the district bounds
	# (districts are circular but we approximate as square of side 2*radius)
	var w: float = radius * 2.0
	var d: float = radius * 2.0
	var min_x: float = center.x - radius
	var min_z: float = center.z - radius
	var max_x: float = center.x + radius
	var max_z: float = center.z + radius

	# Clamp to map bounds
	min_x = max(0.0, min_x)
	min_z = max(0.0, min_z)
	max_x = min(float(map_w), max_x)
	max_z = min(float(map_d), max_z)
	w = max_x - min_x
	d = max_z - min_z

	var virtual_block := {
		"id": "hand_authored_%s" % district_name,
		"min": Vector2(min_x, min_z),
		"max": Vector2(max_x, max_z),
		"center": center,
		"width": w,
		"depth": d,
		"district": district_name,
	}

	# Pick a recipe for this district
	var recipe_name: String = BlockRecipes.pick_recipe(district_name, seed_val)
	var result: Dictionary = BlockRecipes.apply_recipe(recipe_name, virtual_block, seed_val)

	# Place buildings, foliage, props
	var count: int = 0
	for b in result.get("buildings", []):
		var pos: Vector3 = b.pos
		var rot_y: float = float(b.rot_y)
		var asset_name: String = b.asset_name
		# Skip buildings outside map bounds
		if pos.x < 0 or pos.x > map_w or pos.z < 0 or pos.z > map_d:
			continue
		# Skip buildings too close to district boundary (avoid spilling into neighbor)
		if center.distance_to(Vector3(pos.x, 0, pos.z)) > radius:
			continue
		var scene: PackedScene = _get_asset(asset_name)
		if scene == null:
			continue
		var inst: Node3D = scene.instantiate()
		inst.position = pos
		inst.rotation.y = deg_to_rad(rot_y)
		inst.name = "%s_%d" % [asset_name, placed_count]
		root.add_child(inst)
		inst.owner = root
		placed_count += 1
		count += 1

	for f in result.get("foliage", []):
		var pos: Vector3 = f.pos
		if center.distance_to(Vector3(pos.x, 0, pos.z)) > radius:
			continue
		var scene: PackedScene = _get_asset(f.asset_name)
		if scene == null:
			continue
		var inst: Node3D = scene.instantiate()
		inst.position = pos
		inst.rotation.y = deg_to_rad(float(f.rot_y))
		if f.has("scale"):
			var s: float = float(f.scale)
			inst.scale = Vector3(s, s, s)
		inst.name = "%s_%d" % [f.asset_name, placed_count]
		root.add_child(inst)
		inst.owner = root
		placed_count += 1
		count += 1

	for p in result.get("props", []):
		var pos: Vector3 = p.pos
		if center.distance_to(Vector3(pos.x, 0, pos.z)) > radius:
			continue
		var scene: PackedScene = _get_asset(p.asset_name)
		if scene == null:
			continue
		var inst: Node3D = scene.instantiate()
		inst.position = pos
		inst.rotation.y = deg_to_rad(float(p.rot_y))
		inst.name = "%s_%d" % [p.asset_name, placed_count]
		root.add_child(inst)
		inst.owner = root
		placed_count += 1
		count += 1

	# Place internal roads
	for r in result.get("internal_roads", []):
		var r_start: Vector3 = r.start
		var r_end: Vector3 = r.end
		var r_width: float = float(r.get("width", 6.0))
		_render_road_segment(root, r_start, r_end, r_width, C_LOCAL)
		placed_count += 1
		count += 1

	return count

# === PLANE HELPER ===
func _plane(root: Node3D, name: String, center: Vector3, size_x: float, size_z: float, color: Color, y: float, yaw: float):
	var mi := MeshInstance3D.new()
	mi.name = name + "_" + str(placed_count)
	var p := PlaneMesh.new()
	p.size = Vector2(size_x, size_z)
	mi.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = Vector3(center.x, y, center.z)
	mi.rotation.y = yaw
	root.add_child(mi)
	mi.owner = root
	placed_count += 1

# === SET OWNER RECURSIVE ===
func _set_owner_recursive(node: Node, root: Node):
	for child in node.get_children():
		if child.owner == null:
			child.set_owner(root)
		_set_owner_recursive(child, root)
