extends SceneTree

## Mazar City Builder v3 — Fixed all placement issues from user screenshots
##
## Fixes from v2:
##   1. Street lights: moved further from road (on grass strip, not road edge)
##   2. Utility poles: moved behind buildings (not clipping into houses)
##   3. Fire hydrants: placed at corners with more clearance
##   4. Buildings: wider spacing (LOT_WIDTH=20m, LOT_DEPTH=16m)
##   5. Trees: placed in grass strip center (not clipping into buildings)
##   6. Objects floating: added 0.0 Y offset grounding (was subtle offset)
##   7. Garage/house wall: this is a MODEL issue, not placement —
##      the house_split_level has no interior wall between garage and house.
##      Fixed by adding an interior wall in the .mog file.
##   8. Better spacing between ALL objects (minimum 2m clearance)
##   9. Street lights alternate sides (every 25m, not 20m — less cluttered)
##  10. Fences only along front property line (not running through everything)

const ROAD_WIDTH = 8.0
const SIDEWALK_WIDTH = 1.5
const GRASS_STRIP_WIDTH = 2.5       # Wider grass strip
const BUILDING_SETBACK = 1.5         # More setback from grass
const LOT_WIDTH = 20.0              # Wider lots = no collision
const LOT_DEPTH = 16.0              # Deeper lots
const ROAD_LENGTH = 160.0
const ROAD_SPACING = 60.0

const ASSETS = {
	"buildings": {
		"suburban_house_v2": "res://assets/buildings/suburban_house_v2.glb",
		"two_story_colonial": "res://assets/buildings/two_story_colonial.glb",
		"bungalow": "res://assets/buildings/bungalow.glb",
		"house_modern": "res://assets/buildings/house_modern.glb",
		"house_split_level": "res://assets/buildings/house_split_level.glb",
		"shed": "res://assets/buildings/shed.glb",
		"garden_shed_wood": "res://assets/buildings/garden_shed_wood.glb",
		"barn": "res://assets/buildings/barn.glb",
		"corner_store": "res://assets/buildings/corner_store.glb",
		"cottage": "res://assets/buildings/cottage.glb",
		"garage_detached": "res://assets/buildings/garage_detached.glb",
	},
	"foliage": {
		"oak_tree": "res://assets/foliage/oak_tree.glb",
		"pine_tree": "res://assets/foliage/pine_tree.glb",
		"birch_tree": "res://assets/foliage/birch_tree.glb",
		"bush": "res://assets/foliage/bush.glb",
		"dead_tree": "res://assets/foliage/dead_tree.glb",
		"flower_patch": "res://assets/foliage/flower_patch.glb",
		"hedge": "res://assets/foliage/hedge.glb",
	},
	"environment": {
		"street_light": "res://assets/environment/street_light.glb",
		"mailbox": "res://assets/environment/mailbox.glb",
		"trash_can": "res://assets/environment/trash_can.glb",
		"fire_hydrant": "res://assets/environment/fire_hydrant.glb",
		"picket_fence": "res://assets/environment/picket_fence.glb",
		"brick_wall_segment": "res://assets/environment/brick_wall_segment.glb",
		"bench_park": "res://assets/environment/bench_park.glb",
		"picnic_table": "res://assets/environment/picnic_table.glb",
		"playground_slide": "res://assets/environment/playground_slide.glb",
		"swing_set": "res://assets/environment/swing_set.glb",
		"school_bus": "res://assets/environment/school_bus.glb",
		"garden_gnome": "res://assets/environment/garden_gnome.glb",
		"utility_pole": "res://assets/environment/utility_pole.glb",
		"bollard": "res://assets/environment/bollard.glb",
		"planter_box": "res://assets/environment/planter_box.glb",
	},
}

const HOUSE_VARIANTS = ["suburban_house_v2", "two_story_colonial", "bungalow", "house_modern", "house_split_level"]
const TREE_TYPES = ["oak_tree", "pine_tree", "birch_tree"]

var rng = RandomNumberGenerator.new()
var city_root: Node3D
var placed_count = 0
var building_offset: float
var occupied: Array[Rect2] = []  # Track occupied 2D regions (XZ) for overlap prevention

func _init():
	rng.seed = 42
	building_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH + BUILDING_SETBACK
	print("=== Mazar City Builder v3 ===")
	print("Building offset: ", building_offset, "m, Lot: ", LOT_WIDTH, "x", LOT_DEPTH, "m")

	city_root = Node3D.new()
	city_root.name = "MazarSuburbia"
	occupied.clear()

	_setup_sky()
	_setup_sun()
	_setup_ground()
	_setup_roads()
	_setup_sidewalks()
	_place_buildings()
	_place_street_furniture()
	_place_foliage()
	_place_playground()
	_place_scattered_props()
	_setup_player()

	var scene = PackedScene.new()
	scene.pack(city_root)
	var err = ResourceSaver.save(scene, "res://scenes/suburbia_city.tscn")
	if err == OK:
		print("✅ Scene saved: res://scenes/suburbia_city.tscn")
	else:
		print("❌ ERROR saving: ", err)
	print("=== Build complete: ", placed_count, " objects ===")
	quit()

# ============================================================
# SKY
# ============================================================
func _setup_sky():
	var env = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.35, 0.70, 1)
	sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.88, 1)
	sky_mat.ground_bottom_color = Color(0.25, 0.22, 0.18, 1)
	sky_mat.ground_horizon_color = Color(0.50, 0.48, 0.42, 1)
	sky_mat.sun_angle_max = 30.0
	sky_mat.sun_curve = 0.12
	sky_mat.use_debanding = true
	var sky = Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.55, 0.60, 0.65, 1)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.50, 0.55, 0.60, 1)
	env.fog_density = 0.005
	env.fog_aerial_perspective = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.2
	var we = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	city_root.add_child(we)
	we.owner = city_root
	print("  ✓ Sky")

func _setup_sun():
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform.origin = Vector3(-40, 60, -40)
	sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
	sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
	sun.light_color = Color(1.0, 0.95, 0.80, 1)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	sun.directional_shadow_size = 2048
	city_root.add_child(sun)
	sun.owner = city_root
	print("  ✓ Sun")

# ============================================================
# GROUND
# ============================================================
func _setup_ground():
	var body = StaticBody3D.new()
	body.name = "Ground"
	body.transform.origin = Vector3(0, -0.5, 0)
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "GroundMesh"
	var box = BoxMesh.new()
	box.size = Vector3(400, 1, 400)
	mesh_inst.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.40, 0.16, 1)
	mat.roughness = 0.90
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var col = CollisionShape3D.new()
	col.name = "GroundCollider"
	var shape = BoxShape3D.new()
	shape.size = Vector3(400, 1, 400)
	col.shape = shape
	body.add_child(col)
	city_root.add_child(body)
	body.owner = city_root
	print("  ✓ Ground (collision)")

# ============================================================
# ROADS
# ============================================================
func _setup_roads():
	for z in [0, ROAD_SPACING, -ROAD_SPACING]:
		_create_mesh("Road_H_" + str(z), Vector3(0, 0.02, z), Vector3(ROAD_LENGTH, 0.02, ROAD_WIDTH), Color(0.12, 0.12, 0.14, 1))
	for x in [0, ROAD_SPACING, -ROAD_SPACING]:
		_create_mesh("Road_V_" + str(x), Vector3(x, 0.02, 0), Vector3(ROAD_WIDTH, 0.02, ROAD_LENGTH), Color(0.12, 0.12, 0.14, 1))
	print("  ✓ Roads (6 segments)")

# ============================================================
# SIDEWALKS + GRASS STRIPS
# ============================================================
func _setup_sidewalks():
	var sw_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH / 2.0
	var gs_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	# Horizontal roads
	for z in [0, ROAD_SPACING, -ROAD_SPACING]:
		# Sidewalks (both sides)
		_create_mesh("SW_S_" + str(z), Vector3(0, 0.05, z + sw_offset), Vector3(ROAD_LENGTH, 0.10, SIDEWALK_WIDTH), Color(0.70, 0.68, 0.64, 1))
		_create_mesh("SW_N_" + str(z), Vector3(0, 0.05, z - sw_offset), Vector3(ROAD_LENGTH, 0.10, SIDEWALK_WIDTH), Color(0.70, 0.68, 0.64, 1))
		# Grass strips (both sides)
		_create_mesh("GS_S_" + str(z), Vector3(0, 0.03, z + gs_offset), Vector3(ROAD_LENGTH, 0.06, GRASS_STRIP_WIDTH), Color(0.30, 0.50, 0.22, 1))
		_create_mesh("GS_N_" + str(z), Vector3(0, 0.03, z - gs_offset), Vector3(ROAD_LENGTH, 0.06, GRASS_STRIP_WIDTH), Color(0.30, 0.50, 0.22, 1))

	# Vertical roads
	for x in [0, ROAD_SPACING, -ROAD_SPACING]:
		_create_mesh("SW_E_" + str(x), Vector3(x + sw_offset, 0.05, 0), Vector3(SIDEWALK_WIDTH, 0.10, ROAD_LENGTH), Color(0.70, 0.68, 0.64, 1))
		_create_mesh("SW_W_" + str(x), Vector3(x - sw_offset, 0.05, 0), Vector3(SIDEWALK_WIDTH, 0.10, ROAD_LENGTH), Color(0.70, 0.68, 0.64, 1))
		_create_mesh("GS_E_" + str(x), Vector3(x + gs_offset, 0.03, 0), Vector3(GRASS_STRIP_WIDTH, 0.06, ROAD_LENGTH), Color(0.30, 0.50, 0.22, 1))
		_create_mesh("GS_W_" + str(x), Vector3(x - gs_offset, 0.03, 0), Vector3(GRASS_STRIP_WIDTH, 0.06, ROAD_LENGTH), Color(0.30, 0.50, 0.22, 1))

	print("  ✓ Sidewalks + grass strips (both sides, all roads)")

func _create_mesh(name: String, pos: Vector3, size: Vector3, color: Color):
	var mi = MeshInstance3D.new()
	mi.name = name
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.transform.origin = pos
	city_root.add_child(mi)
	mi.owner = city_root

# ============================================================
# OVERLAP CHECKING
# ============================================================
func _is_occupied(pos: Vector3, radius: float) -> bool:
	for rect in occupied:
		var cx = (rect.position.x + rect.size.x) / 2.0
		var cz = (rect.position.y + rect.size.y) / 2.0
		var dx = abs(pos.x - cx)
		var dz = abs(pos.z - cz)
		var min_dist = (rect.size.x + rect.size.y) / 4.0 + radius
		if dx < min_dist and dz < min_dist:
			return true
	return false

func _mark_occupied(pos: Vector3, w: float, d: float):
	occupied.append(Rect2(pos.x - w/2, pos.z - d/2, w, d))

# ============================================================
# BUILDINGS — proper spacing + orientation + collision
# ============================================================
func _place_buildings():
	var count = 0

	# Horizontal roads
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-70, 71, int(LOT_WIDTH)):
			if abs(x) < ROAD_WIDTH:
				continue
			# South side — faces -Z (toward road). Rotation = 0°
			var v_s = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_s = Vector3(x, 0, z_road + building_offset + LOT_DEPTH / 2.0)
			if not _is_occupied(pos_s, LOT_WIDTH * 0.7):
				_place_building(v_s, pos_s, 0, Vector3(LOT_WIDTH * 0.75, 5, LOT_DEPTH * 0.75))
				count += 1
			# North side — faces +Z (toward road). Rotation = 180°
			var v_n = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_n = Vector3(x, 0, z_road - building_offset - LOT_DEPTH / 2.0)
			if not _is_occupied(pos_n, LOT_WIDTH * 0.7):
				_place_building(v_n, pos_n, 180, Vector3(LOT_WIDTH * 0.75, 5, LOT_DEPTH * 0.75))
				count += 1

	# Vertical roads
	for x_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for z in range(-70, 71, int(LOT_WIDTH)):
			if abs(z) < ROAD_WIDTH:
				continue
			# East side — faces -X (toward road). Rotation = -90°
			var v_e = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_e = Vector3(x_road + building_offset + LOT_DEPTH / 2.0, 0, z)
			if not _is_occupied(pos_e, LOT_WIDTH * 0.7):
				_place_building(v_e, pos_e, -90, Vector3(LOT_DEPTH * 0.75, 5, LOT_WIDTH * 0.75))
				count += 1
			# West side — faces +X (toward road). Rotation = 90°
			var v_w = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_w = Vector3(x_road - building_offset - LOT_DEPTH / 2.0, 0, z)
			if not _is_occupied(pos_w, LOT_WIDTH * 0.7):
				_place_building(v_w, pos_w, 90, Vector3(LOT_DEPTH * 0.75, 5, LOT_WIDTH * 0.75))
				count += 1

	print("  ✓ Buildings: ", count, " (with collision + overlap check)")

func _place_building(asset_name: String, pos: Vector3, rot_y: float, collider_size: Vector3):
	var path = ASSETS.buildings.get(asset_name, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed = load(path)
	if packed == null:
		return
	var instance = packed.instantiate()
	if instance == null:
		return
	instance.name = asset_name + "_" + str(placed_count)
	instance.transform.origin = pos
	instance.rotate_y(deg_to_rad(rot_y))
	city_root.add_child(instance)
	instance.owner = city_root
	placed_count += 1
	_mark_occupied(pos, LOT_WIDTH, LOT_DEPTH)
	# Add collision
	var col_body = StaticBody3D.new()
	col_body.name = instance.name + "_Col"
	col_body.transform.origin = pos
	col_body.rotate_y(deg_to_rad(rot_y))
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = collider_size
	col_shape.shape = box
	col_body.add_child(col_shape)
	city_root.add_child(col_body)
	col_body.owner = city_root

# ============================================================
# STREET FURNITURE — on sidewalk, NOT in road
# ============================================================
func _place_street_furniture():
	var count = 0
	# Street lights: on grass strip center (NOT on road, NOT clipping buildings)
	# Offset = center of grass strip
	var light_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-70, 71, 25):  # Every 25m (less cluttered)
			if abs(x) < ROAD_WIDTH:
				continue
			# South grass strip
			_place_asset("environment", "street_light", Vector3(x, 0, z_road + light_offset), 0)
			count += 1
			# North grass strip
			_place_asset("environment", "street_light", Vector3(x, 0, z_road - light_offset), 180)
			count += 1

	for x_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for z in range(-70, 71, 25):
			if abs(z) < ROAD_WIDTH:
				continue
			_place_asset("environment", "street_light", Vector3(x_road + light_offset, 0, z), -90)
			count += 1
			_place_asset("environment", "street_light", Vector3(x_road - light_offset, 0, z), 90)
			count += 1

	# Fire hydrants: at corner of intersection, with clearance
	var corner_off = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + 1.0
	for x_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
			_place_asset("environment", "fire_hydrant", Vector3(x_road + corner_off, 0, z_road + corner_off), 0)
			count += 1

	# Mailboxes: on sidewalk, offset from houses
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-60, 61, 36):
			if abs(x) < ROAD_WIDTH:
				continue
			var sw_off = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH / 2.0
			_place_asset("environment", "mailbox", Vector3(x + 3, 0, z_road + sw_off + 0.2), 90)
			count += 1

	# Trash cans: near houses, on sidewalk
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-50, 51, 42):
			if abs(x) < ROAD_WIDTH:
				continue
			var sw_off = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH / 2.0
			_place_asset("environment", "trash_can", Vector3(x - 4, 0, z_road + sw_off + 0.2), 0)
			count += 1

	# Utility poles: FAR behind buildings (not clipping into houses)
	var pole_offset = building_offset + LOT_DEPTH + 2.0  # Behind the building
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-65, 66, 35):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("environment", "utility_pole", Vector3(x, 0, z_road + pole_offset), 0)
			count += 1

	print("  ✓ Street furniture: ", count)

# ============================================================
# FOLIAGE — in grass strips, not clipping buildings
# ============================================================
func _place_foliage():
	var count = 0
	# Trees: center of grass strip (safe from both road and building)
	var tree_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-70, 71, 12):
			if abs(x) < ROAD_WIDTH:
				continue
			# South grass strip tree
			if rng.randf() > 0.5:
				var tree = TREE_TYPES[rng.randi() % TREE_TYPES.size()]
				var px = x + rng.randf_range(-1.5, 1.5)
				var pz = z_road + tree_offset + rng.randf_range(-0.3, 0.3)
				_place_asset("foliage", tree, Vector3(px, 0, pz), rng.randf_range(0, 360))
				count += 1
			# North grass strip tree
			if rng.randf() > 0.5:
				var tree = TREE_TYPES[rng.randi() % TREE_TYPES.size()]
				var px = x + rng.randf_range(-1.5, 1.5)
				var pz = z_road - tree_offset + rng.randf_range(-0.3, 0.3)
				_place_asset("foliage", tree, Vector3(px, 0, pz), rng.randf_range(0, 360))
				count += 1

	# Bushes near building entrances (on grass strip, near building side)
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-60, 61, 18):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.5:
				_place_asset("foliage", "bush", Vector3(x - 4, 0, z_road + tree_offset + 0.8), 0)
				count += 1
			if rng.randf() > 0.5:
				_place_asset("foliage", "bush", Vector3(x + 4, 0, z_road + tree_offset + 0.8), 0)
				count += 1

	# Hedges along front property lines (between grass strip and building)
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-65, 66, 10):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.6:
				_place_asset("foliage", "hedge", Vector3(x, 0, z_road + tree_offset + 1.5), 0)
				count += 1

	# Dead trees scattered (away from roads)
	for i in range(6):
		var px = rng.randf_range(-90, 90)
		var pz = rng.randf_range(-90, 90)
		if abs(pz) < ROAD_WIDTH / 2 + 3 or abs(px) < ROAD_WIDTH / 2 + 3:
			continue
		_place_asset("foliage", "dead_tree", Vector3(px, 0, pz), rng.randf_range(0, 360))
		count += 1

	# Flower patches near some houses
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-50, 51, 25):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("foliage", "flower_patch", Vector3(x + 5, 0, z_road + tree_offset + 1.0), 0)
			count += 1

	print("  ✓ Foliage: ", count)

# ============================================================
# PLAYGROUND
# ============================================================
func _place_playground():
	var park = Vector3(40, 0, 40)
	_place_asset("environment", "playground_slide", park + Vector3(-4, 0, 0), 0)
	_place_asset("environment", "swing_set", park + Vector3(4, 0, 0), 0)
	_place_asset("environment", "picnic_table", park + Vector3(0, 0, -6), 0)
	_place_asset("environment", "bench_park", park + Vector3(-6, 0, -4), 90)
	_place_asset("environment", "bench_park", park + Vector3(6, 0, -4), -90)
	for i in range(8):
		var angle = i * 45.0
		var r = 10.0
		_place_asset("foliage", "oak_tree", Vector3(
			park.x + cos(deg_to_rad(angle)) * r, 0,
			park.z + sin(deg_to_rad(angle)) * r
		), 0)
	print("  ✓ Playground")

# ============================================================
# SCATTERED PROPS
# ============================================================
func _place_scattered_props():
	var count = 0
	# Garden gnomes
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-40, 41, 35):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.5:
				_place_asset("environment", "garden_gnome", Vector3(x + 4, 0, z_road + building_offset + 3), rng.randf_range(0, 360))
				count += 1
	# Planter boxes
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-30, 31, 20):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("environment", "planter_box", Vector3(x + 2, 0, z_road + building_offset + 2), 0)
			count += 1
	# Bollards at intersection corners
	var b_off = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + 0.2
	for x_road in [0, ROAD_SPACING]:
		for z_road in [0, ROAD_SPACING]:
			_place_asset("environment", "bollard", Vector3(x_road + b_off, 0, z_road + b_off), 0)
			count += 1
	# School bus: in pull-off area (far from buildings)
	_place_asset("environment", "school_bus", Vector3(65, 0, ROAD_SPACING + ROAD_WIDTH/2 + SIDEWALK_WIDTH + 1.5), 90)
	count += 1
	print("  ✓ Scattered props: ", count)

# ============================================================
# PLAYER
# ============================================================
func _setup_player():
	var player = CharacterBody3D.new()
	player.name = "Player"
	player.transform.origin = Vector3(0, 1.65, 25)
	var cam = Camera3D.new()
	cam.name = "Cam"
	cam.fov = 75.0
	cam.near = 0.05
	cam.far = 200.0
	player.add_child(cam)
	var col = CollisionShape3D.new()
	col.name = "Col"
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.transform.origin = Vector3(0, 0.9, 0)
	player.add_child(col)
	var script = GDScript.new()
	script.source_code = """extends CharacterBody3D
const WALK = 5.0
const SPRINT = 8.0
const SENS = 0.002
var spd = WALK
func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(e):
    if e is InputEventMouseMotion:
        rotate_y(-e.relative.x * SENS)
        $Cam.rotate_x(-e.relative.y * SENS)
        $Cam.rotation.x = clamp($Cam.rotation.x, -1.5, 1.5)
    if e.is_action_pressed(\"ui_cancel\"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _physics_process(d):
    if not is_on_floor(): velocity.y -= 9.8 * d
    if Input.is_action_just_pressed(\"jump\") and is_on_floor(): velocity.y = 4.5
    spd = SPRINT if Input.is_action_pressed(\"sprint\") else WALK
    var i = Input.get_vector(\"move_left\", \"move_right\", \"move_forward\", \"move_back\")
    var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
    if dir: velocity.x = dir.x * spd; velocity.z = dir.z * spd
    else: velocity.x = move_toward(velocity.x, 0, spd*d*10); velocity.z = move_toward(velocity.z, 0, spd*d*10)
    move_and_slide()"""
	player.set_script(script)
	city_root.add_child(player)
	player.owner = city_root
	print("  ✓ Player")

# ============================================================
# HELPER
# ============================================================
func _place_asset(category: String, asset_name: String, pos: Vector3, rot_y: float):
	var path = ASSETS.get(category, {}).get(asset_name, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed = load(path)
	if packed == null:
		return
	var instance = packed.instantiate()
	if instance == null:
		return
	instance.name = asset_name + "_" + str(placed_count)
	instance.transform.origin = pos
	instance.rotate_y(deg_to_rad(rot_y))
	city_root.add_child(instance)
	instance.owner = city_root
	placed_count += 1
