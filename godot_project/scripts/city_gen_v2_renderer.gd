# CityGenV2 Renderer — converts a CityGenV2 map plan into scene nodes + saves .tscn
#
# Usage:
#   var map = CityGenV2.generate_map(1337)
#   CityGenV2Renderer.render_and_save(map, manifest, "res://scenes/main.tscn")

extends SceneTree

const CityGenV2 = preload("res://tools/city_gen_v2.gd")
const CityConfig = preload("res://tools/city_config.gd")

var manifest: Dictionary
var asset_cache: Dictionary = {}
var placed_count: int = 0

# Y constants
const Y_GROUND := 0.000
const Y_ROAD := 0.060
const Y_LANE := 0.065
const Y_SIDEWALK := 0.040
const Y_PARK := 0.005

# Colors
const C_HIGHWAY := Color(0.08, 0.08, 0.10, 1)
const C_ARTERIAL := Color(0.12, 0.12, 0.14, 1)
const C_LOCAL := Color(0.16, 0.16, 0.18, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)

# District ground colors
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

func _init():
	print("=== CityGenV2 Renderer ===")
	_load_manifest()
	
	# Generate the map plan
	var t0 := Time.get_ticks_msec()
	var map := CityGenV2.generate_map(1337)
	var t1 := Time.get_ticks_msec()
	print("  Plan time: %dms" % (t1 - t0))
	
	# Render to scene
	var root := Node3D.new()
	root.name = "MazarCity"
	
	# Sky + sun + ground
	_setup_sky(root)
	_setup_sun(root)
	_setup_ground(root)
	
	# Render roads
	var t2 := Time.get_ticks_msec()
	_render_roads(root, map.roads)
	var t3 := Time.get_ticks_msec()
	print("  Roads rendered: %dms (%d segments)" % [t3 - t2, map.roads.size()])
	
	# Render blocks
	_render_blocks(root, map.plans)
	var t4 := Time.get_ticks_msec()
	print("  Blocks rendered: %dms (%d blocks, %d placements)" % [t4 - t3, map.plans.size(), placed_count])
	
	# Save scene
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, "res://scenes/main.tscn")
	if err == OK:
		print("✅ Saved: res://scenes/main.tscn (%d total placements, %dms total)" % [placed_count, t4 - t0])
	else:
		print("❌ Save failed: ", err)
	quit()

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

func _setup_ground(root: Node3D):
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.position = Vector3(2000, 0, 1500)
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4100, 1, 3100)
	col.shape = shape
	body.add_child(col)
	col.owner = root
	var mi := MeshInstance3D.new()
	mi.name = "GroundMesh"
	var p := PlaneMesh.new()
	p.size = Vector2(4100, 3100)
	mi.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = C_GRASS
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)
	mi.owner = root

func _render_roads(root: Node3D, roads: Array):
	for road in roads:
		var start: Vector3 = road.start
		var end: Vector3 = road.end
		var width: float = float(road.width)
		var kind: String = road.get("kind", "local")
		var center := (start + end) * 0.5
		var length := start.distance_to(end)
		var yaw := atan2(end.x - start.x, end.z - start.z)
		
		# Road surface
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

func _render_blocks(root: Node3D, plans: Array):
	for plan in plans:
		var center: Vector3 = plan.center
		var w: float = plan.width
		var d: float = plan.depth
		var district: String = plan.district
		
		# District ground color
		var ground_color: Color = DISTRICT_COLORS.get(district, C_GRASS)
		_plane(root, "DistrictGround", center, w, d, ground_color, 0.001, 0)
		
		# Buildings
		for b in plan.buildings:
			var pos: Vector3 = b.pos
			var rot_y: float = float(b.rot_y)
			var asset_name: String = b.asset_name
			var scene: PackedScene = _get_asset(asset_name)
			if scene == null:
				continue
			var inst: Node3D = scene.instantiate()
			inst.position = pos
			inst.rotation.y = deg_to_rad(rot_y)
			inst.name = "%s_%d" % [asset_name, placed_count]
			inst.set_meta("building_name", asset_name)
			root.add_child(inst)
			inst.owner = root
			# Add collision
			#_attach_collision(inst)
			placed_count += 1
		
		# Foliage
		for f in plan.foliage:
			var pos: Vector3 = f.pos
			var rot_y: float = float(f.rot_y)
			var asset_name: String = f.asset_name
			var scale: float = float(f.scale)
			var scene: PackedScene = _get_asset(asset_name)
			if scene == null:
				continue
			var inst: Node3D = scene.instantiate()
			inst.position = pos
			inst.rotation.y = deg_to_rad(rot_y)
			inst.scale = Vector3(scale, scale, scale)
			inst.name = "%s_%d" % [asset_name, placed_count]
			inst.set_meta("building_name", asset_name)
			root.add_child(inst)
			inst.owner = root
			placed_count += 1
		
		# Props
		for p in plan.props:
			var pos: Vector3 = p.pos
			var rot_y: float = float(p.rot_y)
			var asset_name: String = p.asset_name
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

func _attach_collision(node: Node3D):
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
		return
	var body := StaticBody3D.new()
	body.name = "Collider"
	body.position = aabb.position + aabb.size * 0.5
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	col.shape = box
	body.add_child(col)
	node.add_child(body)

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
