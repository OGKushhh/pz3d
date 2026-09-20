# CityV2Baker — prebuilds the CityGenV2 plan to static .tscn files.
#
# Replaces the old per-chunk V1 baker with a cleaner block-based V2 baker.
# NO runtime generation, NO runtime streaming. The city is baked once and
# main.tscn simply instances each block as a PackedScene.
#
# Run:
#       godot --headless --path godot_project --script res://scripts/city_v2_baker.gd
#
# Output:
#       res://scenes/baked_v2/block_<i>.tscn  (one per block, ~300 files)
#       res://scenes/baked_v2/roads.tscn     (roads + sidewalks + lane lines)
#       res://scenes/main.tscn                (world scene with all instances + Player)
#
# The baker IS the renderer — it converts plan data directly to nodes.
# Block files contain: district ground + buildings + foliage + props.
# Road file contains: road meshes + lane lines + sidewalks.
# main.tscn contains: sky + sun + ground + roads.tscn instance + block instances + Player.
#
# Why per-block files:
#       - main.tscn stays small (~600 lines) -> Godot editor opens fast, no freeze
#       - Each block is independently editable for hand-tweaking
#       - Re-baking one block doesn't touch the others
#       - Loading is instant (no streaming, just one big instance tree)

extends SceneTree

# === Dependencies ===
const CityGenV2 = preload("res://tools/city_gen_v2.gd")
const CityConfig = preload("res://tools/city_config.gd")
const ConvLoop4V2 = preload("res://tools/conv_loop4_v2.gd")
const RefLoop3V2 = preload("res://tools/ref_loop3_v2.gd")
const RoadGraphV2 = preload("res://tools/road_graph_v2.gd")

# === Output paths ===
const OUTPUT_DIR := "res://scenes/baked_v2/"
const MAIN_SCENE := "res://scenes/main.tscn"
const ROADS_SCENE := "res://scenes/baked_v2/roads.tscn"
const BLOCK_INDEX_PATH := "res://data/block_index.json"

# === Y layering (roads above pavement/ground, sidewalks above roads like curbs) ===
const Y_GROUND := 0.000
const Y_DISTRICT_GROUND := 0.010
const Y_ROAD := 0.030       # roads above district ground (visible)
const Y_LANE := 0.035       # lane lines above road
const Y_SIDEWALK := 0.050   # sidewalks above road (curb height)

# === Colors ===
const C_HIGHWAY := Color(0.08, 0.08, 0.10, 1)
const C_ARTERIAL := Color(0.12, 0.12, 0.14, 1)
const C_LOCAL := Color(0.16, 0.16, 0.18, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)

# District ground colors (XIII-style per-biome palette — used for debug distinction)
const DISTRICT_COLORS := {
	"downtown": Color(0.40, 0.38, 0.35),
	"commercial": Color(0.45, 0.43, 0.40),
	"industrial": Color(0.35, 0.33, 0.30),
	"suburbia": Color(0.35, 0.52, 0.20),
	"farmland": Color(0.55, 0.48, 0.22),
	"military": Color(0.50, 0.45, 0.35),
	"forest": Color(0.20, 0.35, 0.15),
	"parks": Color(0.40, 0.60, 0.25),
}

# === State ===
var manifest: Dictionary
var asset_cache: Dictionary = {}  # asset_name -> PackedScene
var placed_count: int = 0
var baked_blocks: int = 0
var skipped_blocks: int = 0

# === ENTRY POINT ===
func _init():
	print("=== CityV2Baker — prebuilding city to .tscn ===")
	_load_manifest()

	# Step 1: Generate the entire map plan in-memory (36ms — fast)
	var t0 := Time.get_ticks_msec()
	var map := CityGenV2.generate_map(1337)
	var t1 := Time.get_ticks_msec()
	print("  Plan generated: %dms" % (t1 - t0))
	print("    Roads: %d | Blocks: %d | Buildings: %d | Foliage: %d | Props: %d" % [
		map.stats.roads, map.stats.blocks, map.stats.buildings,
		map.stats.foliage, map.stats.props
	])

	# Step 1b: Loop 4 validation — evaluate plan before baking.
	# Hard problems block the bake (must fix recipes first).
	# Preferences are reported but don't block.
	var report: Dictionary = ConvLoop4V2.report(map)
	ConvLoop4V2.print_summary(report)

	if not report.ok_to_bake:
		printerr("  REFUSING TO BAKE — %d hard problems remain. Fix recipes in tools/block_recipes.gd and re-run." % report.hard_problems)
		quit(1)
		return
	print("  ✓ All hard constraints passed — proceeding to bake")

	# Step 1c: Loop 3 — reference-driven distance report.
	# Compares generated district profiles to reference profiles extracted
	# from GTA SA map (data/reference_profiles.json).
	# Soft check — doesn't block bake, just reports distance + recommendations.
	var loop3_report: Dictionary = RefLoop3V2.report(map)
	RefLoop3V2.print_summary(loop3_report)

	# Step 2: Make output directory
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	# Step 3: Bake roads to a single .tscn file (shared, only ~37 segments)
	var t2 := Time.get_ticks_msec()
	_bake_roads(map.roads)
	var t3 := Time.get_ticks_msec()
	print("  Roads baked: %dms -> %s" % [t3 - t2, ROADS_SCENE])

	# Step 3b: Build road graph + place intersection props
	# This converts the flat road array into a graph (nodes + edges) and
	# places traffic lights at major intersections + traffic cones at minor ones.
	var t_graph_start := Time.get_ticks_msec()
	var road_graph: Dictionary = RoadGraphV2.build(map.roads)
	RoadGraphV2.print_stats(road_graph)
	var intersection_props: Array = RoadGraphV2.place_intersection_props(road_graph)
	# Save intersection props as part of roads.tscn (append to it)
	_add_intersection_props_to_roads(intersection_props)
	var t_graph_end := Time.get_ticks_msec()
	print("  Road graph + %d intersection props placed: %dms" % [intersection_props.size(), t_graph_end - t_graph_start])

	# Step 4: Bake each block to its own .tscn file
	# Also collect block index entries (index, center, width, depth) for streaming
	var block_index: Array = []
	for i in range(map.plans.size()):
		var plan: Dictionary = map.plans[i]
		_bake_block(plan, i)
		block_index.append({
			"index": i,
			"center": _vec3_to_str(plan.center),
			"width": plan.width,
			"depth": plan.depth,
			"district": plan.district,
		})
	print("  Blocks baked: %d ok, %d skipped" % [baked_blocks, skipped_blocks])

	# Step 4b: Write block_index.json (for BlockLoader streaming)
	var idx_f := FileAccess.open(BLOCK_INDEX_PATH, FileAccess.WRITE)
	if idx_f:
		idx_f.store_string(JSON.stringify(block_index, "\t"))
		idx_f.close()
		print("  Block index: %d entries -> %s" % [block_index.size(), BLOCK_INDEX_PATH])

	# Step 5: Generate main.tscn that instances roads + all blocks + Player
	var t4 := Time.get_ticks_msec()
	_write_main_tscn(map.plans.size())
	var t5 := Time.get_ticks_msec()
	print("  main.tscn written: %dms -> %s" % [t5 - t4, MAIN_SCENE])

	print("=== DONE ===")
	print("  Total placements: %d" % placed_count)
	print("  Total bake time: %dms" % (t5 - t0))
	quit()

# === MANIFEST ===
func _load_manifest():
	var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
	if f:
		manifest = JSON.parse_string(f.get_as_text())
	print("  Manifest: %d assets" % manifest.size())

func _get_asset(name: String) -> PackedScene:
	if name == "":
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

# === BAKE ROADS ===
func _bake_roads(roads: Array):
	var root := Node3D.new()
	root.name = "Roads"

	for road in roads:
		var start: Vector3 = road.start
		var end: Vector3 = road.end
		var width: float = float(road.width)
		var kind: String = road.get("kind", "local")
		var center := (start + end) * 0.5
		var length := start.distance_to(end)
		var yaw := atan2(end.x - start.x, end.z - start.z)

		# Road surface (color by kind)
		var color: Color = C_LOCAL
		match kind:
			"highway": color = C_HIGHWAY
			"arterial": color = C_ARTERIAL
		_plane(root, "Road", center, length, width, color, Y_ROAD, yaw)

		# Center lane line (for highways + arterials)
		if kind in ["highway", "arterial"] and length > 20:
			_plane(root, "Lane", center, length, 0.15, C_LANE, Y_LANE, yaw)

		# Sidewalks (both sides, for arterials + locals)
		if kind in ["arterial", "local"]:
			var sw_off := width * 0.5 + 0.75
			var perp_x := cos(yaw)
			var perp_z := -sin(yaw)
			_plane(root, "Sidewalk", center + Vector3(perp_x * sw_off, 0, perp_z * sw_off), length, 1.5, C_SIDEWALK, Y_SIDEWALK, yaw)
			_plane(root, "Sidewalk", center - Vector3(perp_x * sw_off, 0, perp_z * sw_off), length, 1.5, C_SIDEWALK, Y_SIDEWALK, yaw)

	# Save
	_set_owner_recursive(root, root)
	var scene := PackedScene.new()
	var pack_err := scene.pack(root)
	if pack_err != OK:
		print("  ERROR: roads pack failed: ", pack_err)
		return
	ResourceSaver.save(scene, ROADS_SCENE)

# === ADD INTERSECTION PROPS TO ROADS ===
# Loads roads.tscn, adds intersection props as children, saves again.
# This is a separate step because intersection detection needs the full road
# graph (which is built after _bake_roads runs).
func _add_intersection_props_to_roads(intersection_props: Array):
	# Load the existing roads.tscn
	var roads_scene := load(ROADS_SCENE) as PackedScene
	if roads_scene == null:
		printerr("  ERROR: can't load roads.tscn for intersection props")
		return
	var root: Node3D = roads_scene.instantiate()

	# Add intersection props (traffic lights, bollards, traffic cones)
	for prop_data in intersection_props:
		var pos: Vector3 = prop_data.pos
		var rot_y: float = float(prop_data.rot_y)
		var asset_name: String = prop_data.asset_name
		var scene: PackedScene = _get_asset(asset_name)
		if scene == null:
			continue  # asset not in manifest (e.g. traffic_light might not exist)
		var inst: Node3D = scene.instantiate()
		inst.position = pos
		inst.rotation.y = deg_to_rad(rot_y)
		inst.name = "%s_intersection_%d" % [asset_name, placed_count]
		root.add_child(inst)
		inst.owner = root
		placed_count += 1

	# Save (overwrites roads.tscn with intersection props added)
	var new_scene := PackedScene.new()
	var pack_err := new_scene.pack(root)
	if pack_err == OK:
		ResourceSaver.save(new_scene, ROADS_SCENE)
	root.queue_free()

# === BAKE ONE BLOCK ===
func _bake_block(plan: Dictionary, idx: int):
	var root := Node3D.new()
	root.name = "Block_%d" % idx

	var center: Vector3 = plan.center
	var w: float = plan.width
	var d: float = plan.depth
	var district: String = plan.district

	# District ground color (debug distinct)
	var ground_color: Color = DISTRICT_COLORS.get(district, C_GRASS)
	_plane(root, "DistrictGround", center, w, d, ground_color, Y_DISTRICT_GROUND, 0)

	# Buildings
	for b in plan.buildings:
		_place_asset(root, b.asset_name, b.pos, b.rot_y, 1.0)

	# Foliage
	for f in plan.foliage:
		_place_asset(root, f.asset_name, f.pos, f.rot_y, f.scale)

	# Props
	for p in plan.props:
		_place_asset(root, p.asset_name, p.pos, p.rot_y, 1.0)

	# Save block to its own file
	_set_owner_recursive(root, root)
	var scene := PackedScene.new()
	var pack_err := scene.pack(root)
	if pack_err != OK:
		print("  ERROR: block %d pack failed: %s" % [idx, pack_err])
		skipped_blocks += 1
		return
	var path := "%sblock_%d.tscn" % [OUTPUT_DIR, idx]
	ResourceSaver.save(scene, path)
	baked_blocks += 1

# === PLACE ASSET ===
func _place_asset(root: Node3D, asset_name: String, pos: Vector3, rot_y: float, scale: float):
	if asset_name == "":
		return
	var scene: PackedScene = _get_asset(asset_name)
	if scene == null:
		return  # asset missing from manifest, skip silently
	var inst: Node3D = scene.instantiate()
	inst.position = pos
	inst.rotation.y = deg_to_rad(float(rot_y))
	if scale != 1.0:
		inst.scale = Vector3(scale, scale, scale)
	inst.name = "%s_%d" % [asset_name, placed_count]
	inst.set_meta("building_name", asset_name)
	root.add_child(inst)
	inst.owner = root
	placed_count += 1

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

# === WRITE main.tscn ===
# Generates the main scene file as TEXT (not via PackedScene.pack()) to:
#       - Allow script override on Player (CogitoPlayerAdvanced -> MazarPlayer)
#       - Keep main.tscn TINY: NO block instances here (BlockLoader streams them at runtime)
func _write_main_tscn(block_count: int):
	var f := FileAccess.open(MAIN_SCENE, FileAccess.WRITE)
	if not f:
		print("  ERROR: can't write main.tscn")
		return

	# === HEADER ===
	# Sub_resources: SkyMat + SkyRes + EnvRes + GroundShape + GroundMat + GroundMesh = 6
	# Ext_resources: roads + player + mazar script + block_loader script = 4
	var load_steps := 6 + 4 + 1
	f.store_line("[gd_scene load_steps=%d format=3]" % load_steps)
	f.store_line("")

	# === EXT RESOURCES ===
	f.store_line('[ext_resource type="PackedScene" path="res://scenes/baked_v2/roads.tscn" id="1_roads"]')
	f.store_line('[ext_resource type="PackedScene" path="res://addons/cogito/PackedScenes/cogito_player_advanced.tscn" id="2_player"]')
	f.store_line('[ext_resource type="Script" path="res://scripts/mazar_player.gd" id="3_mazar"]')
	f.store_line('[ext_resource type="Script" path="res://scripts/block_loader.gd" id="4_block_loader"]')
	f.store_line("")

	# === SUB RESOURCES (sky + environment + ground material/mesh/shape) ===
	_write_sub_resources(f)
	f.store_line("")

	# === NODES ===
	# Root node
	f.store_line("[node name=\"MazarCity\" type=\"Node3D\"]")
	f.store_line("")

	# WorldEnvironment (sky + ambient + fog)
	_write_world_environment_node(f)
	f.store_line("")

	# Sun (DirectionalLight3D)
	_write_sun_node(f)
	f.store_line("")

	# Ground (StaticBody3D + collision + mesh)
	_write_ground_nodes(f)
	f.store_line("")

	# Roads instance (always loaded — small file, ~37 segments)
	f.store_line("[node name=\"Roads\" parent=\".\" instance=ExtResource(\"1_roads\")]")
	f.store_line("")

	# Blocks container (empty — BlockLoader adds block children at runtime)
	f.store_line("[node name=\"Blocks\" type=\"Node3D\" parent=\".\"]")
	f.store_line("")

	# BlockLoader (Node with script) — streams blocks in/out based on player position
	f.store_line("[node name=\"BlockLoader\" type=\"Node\" parent=\".\"]")
	f.store_line("script = ExtResource(\"4_block_loader\")")
	f.store_line("")

	# Player (instance of cogito_player_advanced.tscn, script overridden to mazar_player.gd)
	f.store_line("[node name=\"Player\" parent=\".\" instance=ExtResource(\"2_player\")]")
	f.store_line("script = ExtResource(\"3_mazar\")")
	f.store_line("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1125, 2, 1125)")
	f.store_line("")

	f.close()
	print("  main.tscn: %d ext_resources, %d sub_resources, NO block instances (streamed at runtime)" % [4, 6])

# === HELPER: Vector3 to String for JSON serialization ===
func _vec3_to_str(v: Vector3) -> String:
	return "(%s, %s, %s)" % [str(v.x), str(v.y), str(v.z)]

# === SUB RESOURCES (sky + environment + ground material/mesh/shape) ===
# These are referenced by nodes below. Must come before nodes in tscn format.
func _write_sub_resources(f: FileAccess):
	# Sky material
	f.store_line("[sub_resource type=\"ProceduralSkyMaterial\" id=\"SkyMat\"]")
	f.store_line("sky_top_color = Color(0.15, 0.35, 0.7, 1)")
	f.store_line("sky_horizon_color = Color(0.7, 0.78, 0.88, 1)")
	f.store_line("ground_bottom_color = Color(0.25, 0.22, 0.18, 1)")
	f.store_line("ground_horizon_color = Color(0.50, 0.48, 0.42, 1)")
	f.store_line("sun_curve = 0.12")
	f.store_line("")
	# Sky
	f.store_line("[sub_resource type=\"Sky\" id=\"SkyRes\"]")
	f.store_line("sky_material = SubResource(\"SkyMat\")")
	f.store_line("")
	# Environment
	f.store_line("[sub_resource type=\"Environment\" id=\"EnvRes\"]")
	f.store_line("background_mode = 1")
	f.store_line("sky = SubResource(\"SkyRes\")")
	f.store_line("ambient_light_source = 2")
	f.store_line("ambient_light_color = Color(0.55, 0.60, 0.65, 1)")
	f.store_line("ambient_light_energy = 0.6")
	f.store_line("fog_enabled = true")
	f.store_line("fog_light_color = Color(0.50, 0.55, 0.60, 1)")
	f.store_line("fog_density = 0.005")
	f.store_line("tonemap_mode = 2")
	f.store_line("")
	# Ground shape
	f.store_line("[sub_resource type=\"BoxShape3D\" id=\"GroundShape\"]")
	f.store_line("size = Vector3(4100, 1, 3100)")
	f.store_line("")
	# Ground material
	f.store_line("[sub_resource type=\"StandardMaterial3D\" id=\"GroundMat\"]")
	f.store_line("albedo_color = Color(0.22, 0.40, 0.16, 1)")
	f.store_line("roughness = 0.85")
	f.store_line("")
	# Ground mesh
	f.store_line("[sub_resource type=\"PlaneMesh\" id=\"GroundMesh\"]")
	f.store_line("size = Vector2(4100, 3100)")
	f.store_line("material = SubResource(\"GroundMat\")")

# === WORLD ENVIRONMENT NODE ===
func _write_world_environment_node(f: FileAccess):
	f.store_line("[node name=\"WorldEnvironment\" type=\"WorldEnvironment\" parent=\".\"]")
	f.store_line("environment = SubResource(\"EnvRes\")")

# === SUN NODE ===
func _write_sun_node(f: FileAccess):
	f.store_line("[node name=\"Sun\" type=\"DirectionalLight3D\" parent=\".\"]")
	f.store_line("transform = Transform3D(0.7071, 0.3535, -0.6123, 0, 0.866, 0.5, 0.7071, -0.3535, 0.6123, -200, 300, -200)")
	f.store_line("light_color = Color(1.0, 0.95, 0.80, 1)")
	f.store_line("light_energy = 2.0")
	f.store_line("shadow_enabled = true")
	f.store_line("directional_shadow_max_distance = 400.0")

# === GROUND NODES ===
func _write_ground_nodes(f: FileAccess):
	f.store_line("[node name=\"Ground\" type=\"StaticBody3D\" parent=\".\"]")
	f.store_line("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2000, 0, 1500)")
	f.store_line("")
	f.store_line("[node name=\"GroundMesh\" type=\"MeshInstance3D\" parent=\"Ground\"]")
	f.store_line("mesh = SubResource(\"GroundMesh\")")
	f.store_line("")
	f.store_line("[node name=\"GroundCollider\" type=\"CollisionShape3D\" parent=\"Ground\"]")
	f.store_line("shape = SubResource(\"GroundShape\")")
