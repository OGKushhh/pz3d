extends SceneTree

## Mazar City Builder v2 — Improved placement, collisions, sidewalks, orientation
## Fixes from v1:
##   - Buildings properly spaced (no collisions between houses)
##   - Building fronts face the road (correct rotation per side)
##   - Ground has collision (StaticBody3D + BoxShape3D)
##   - Buildings have collision (AABB approximations)
##   - Sidewalks + grass strips between road and buildings
##   - Street lights on sidewalk edges (NOT in road)
##   - Fire hydrants on corners (NOT in road)
##   - Trees in grass strips (between sidewalk and building)
##   - Better sky (ProceduralSkyMaterial with sun)

const ROAD_WIDTH = 8.0
const SIDEWALK_WIDTH = 1.5
const GRASS_STRIP_WIDTH = 2.0
const BUILDING_SETBACK = 1.0
const LOT_WIDTH = 18.0      # Wider lots = no collision between houses
const LOT_DEPTH = 14.0      # Deeper lots = room for backyard
const ROAD_LENGTH = 160.0
const ROAD_SPACING = 60.0   # Distance between parallel roads

# Asset registry — res:// paths
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
		"traffic_cone": "res://assets/environment/traffic_cone.glb",
		"road_sign": "res://assets/environment/road_sign.glb",
		"bench_park": "res://assets/environment/bench_park.glb",
		"picnic_table": "res://assets/environment/picnic_table.glb",
		"playground_slide": "res://assets/environment/playground_slide.glb",
		"swing_set": "res://assets/environment/swing_set.glb",
		"school_bus": "res://assets/environment/school_bus.glb",
		"garden_gnome": "res://assets/environment/garden_gnome.glb",
		"utility_pole": "res://assets/environment/utility_pole.glb",
		"bollard": "res://assets/environment/bollard.glb",
		"planter_box": "res://assets/environment/planter_box.glb",
		"asphalt_road_segment": "res://assets/environment/asphalt_road_segment.glb",
		"dirt_road_segment": "res://assets/environment/dirt_road_segment.glb",
	},
}

const HOUSE_VARIANTS = ["suburban_house_v2", "two_story_colonial", "bungalow", "house_modern", "house_split_level"]
const TREE_TYPES = ["oak_tree", "pine_tree", "birch_tree"]

var rng = RandomNumberGenerator.new()
var city_root: Node3D
var placed_count = 0

# Full offset from road centerline to building face:
# ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH + BUILDING_SETBACK
var building_offset: float

func _init():
	rng.seed = 42
	building_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH + BUILDING_SETBACK
	print("=== Mazar City Builder v2 ===")
	print("Building offset from road center: ", building_offset, "m")

	city_root = Node3D.new()
	city_root.name = "MazarSuburbia"

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
		print("❌ ERROR saving scene: ", err)

	print("=== Build complete: ", placed_count, " objects ===")
	quit()

# ============================================================
# SKY + ENVIRONMENT
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
	env.fog_density = 0.006
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
	print("  ✓ Sky (procedural, fog, SSAO)")

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
	print("  ✓ Sun (shadows, 2k map)")

# ============================================================
# GROUND + COLLISION
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
	print("  ✓ Ground (400x400, WITH collision)")

# ============================================================
# ROADS — grid pattern
# ============================================================
func _setup_roads():
	# Main roads: 3 horizontal + 3 vertical, 60m apart
	var road_positions = [
		Vector3(0, 0, 0),      # Center intersection
		Vector3(0, 0, ROAD_SPACING),
		Vector3(0, 0, -ROAD_SPACING),
		Vector3(ROAD_SPACING, 0, 0),
		Vector3(-ROAD_SPACING, 0, 0),
	]

	# Horizontal roads (run along X)
	for z in [0, ROAD_SPACING, -ROAD_SPACING]:
		_create_road_segment("Road_H_" + str(z), Vector3(0, 0.02, z), Vector3(ROAD_LENGTH, 0.02, ROAD_WIDTH))

	# Vertical roads (run along Z)
	for x in [0, ROAD_SPACING, -ROAD_SPACING]:
		_create_road_segment("Road_V_" + str(x), Vector3(x, 0.02, 0), Vector3(ROAD_WIDTH, 0.02, ROAD_LENGTH))

	print("  ✓ Roads (6 segments, grid pattern)")

func _create_road_segment(name: String, pos: Vector3, size: Vector3):
	var road = MeshInstance3D.new()
	road.name = name
	var box = BoxMesh.new()
	box.size = size
	road.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.14, 1)
	mat.roughness = 0.95
	road.material_override = mat
	road.transform.origin = pos
	city_root.add_child(road)
	road.owner = city_root

# ============================================================
# SIDEWALKS + GRASS STRIPS
# ============================================================
func _setup_sidewalks():
	# For each road, create sidewalks on both sides
	# Sidewalk: 1.5m wide concrete strip, raised 0.05m
	# Grass strip: 2.0m wide green strip between sidewalk and building

	var sidewalk_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH / 2.0
	var grass_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	# Horizontal roads (sidewalks run along X on both sides)
	for z in [0, ROAD_SPACING, -ROAD_SPACING]:
		# South sidewalk (z > 0)
		_create_sidewalk("SW_S_" + str(z), Vector3(0, 0.05, z + sidewalk_offset), Vector3(ROAD_LENGTH, 0.10, SIDEWALK_WIDTH))
		# North sidewalk (z < 0)
		_create_sidewalk("SW_N_" + str(z), Vector3(0, 0.05, z - sidewalk_offset), Vector3(ROAD_LENGTH, 0.10, SIDEWALK_WIDTH))
		# South grass strip
		_create_grass_strip("GS_S_" + str(z), Vector3(0, 0.03, z + grass_offset), Vector3(ROAD_LENGTH, 0.06, GRASS_STRIP_WIDTH))
		# North grass strip
		_create_grass_strip("GS_N_" + str(z), Vector3(0, 0.03, z - grass_offset), Vector3(ROAD_LENGTH, 0.06, GRASS_STRIP_WIDTH))

	# Vertical roads (sidewalks run along Z on both sides)
	for x in [0, ROAD_SPACING, -ROAD_SPACING]:
		# East sidewalk (x > 0)
		_create_sidewalk("SW_E_" + str(x), Vector3(x + sidewalk_offset, 0.05, 0), Vector3(SIDEWALK_WIDTH, 0.10, ROAD_LENGTH))
		# West sidewalk (x < 0)
		_create_sidewalk("SW_W_" + str(x), Vector3(x - sidewalk_offset, 0.05, 0), Vector3(SIDEWALK_WIDTH, 0.10, ROAD_LENGTH))
		# East grass strip
		_create_grass_strip("GS_E_" + str(x), Vector3(x + grass_offset, 0.03, 0), Vector3(GRASS_STRIP_WIDTH, 0.06, ROAD_LENGTH))
		# West grass strip
		_create_grass_strip("GS_W_" + str(x), Vector3(x - grass_offset, 0.03, 0), Vector3(GRASS_STRIP_WIDTH, 0.06, ROAD_LENGTH))

	print("  ✓ Sidewalks + grass strips (both sides of all roads)")

func _create_sidewalk(name: String, pos: Vector3, size: Vector3):
	var sw = MeshInstance3D.new()
	sw.name = name
	var box = BoxMesh.new()
	box.size = size
	sw.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.70, 0.68, 0.64, 1)
	mat.roughness = 0.85
	sw.material_override = mat
	sw.transform.origin = pos
	city_root.add_child(sw)
	sw.owner = city_root

func _create_grass_strip(name: String, pos: Vector3, size: Vector3):
	var gs = MeshInstance3D.new()
	gs.name = name
	var box = BoxMesh.new()
	box.size = size
	gs.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.50, 0.22, 1)
	mat.roughness = 0.85
	gs.material_override = mat
	gs.transform.origin = pos
	city_root.add_child(gs)
	gs.owner = city_root

# ============================================================
# BUILDINGS — proper spacing + orientation + collision
# ============================================================
func _place_buildings():
	var count = 0

	# Place buildings along all 6 roads
	# For each road, buildings go on both sides

	# === Horizontal roads (buildings face road: door at -Z or +Z) ===
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-70, 71, int(LOT_WIDTH)):
			if abs(x) < ROAD_WIDTH:  # Skip intersection
				continue

			# South side (z > road) — building faces -Z (toward road). Rotation = 0°
			var variant_s = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_s = Vector3(x, 0, z_road + building_offset + LOT_DEPTH / 2.0)
			_place_building_with_collision(variant_s, pos_s, 0, Vector3(LOT_WIDTH * 0.8, 5, LOT_DEPTH * 0.8))
			count += 1

			# North side (z < road) — building faces +Z (toward road). Rotation = 180°
			var variant_n = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_n = Vector3(x, 0, z_road - building_offset - LOT_DEPTH / 2.0)
			_place_building_with_collision(variant_n, pos_n, 180, Vector3(LOT_WIDTH * 0.8, 5, LOT_DEPTH * 0.8))
			count += 1

	# === Vertical roads (buildings face road: door at -X or +X) ===
	for x_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for z in range(-70, 71, int(LOT_WIDTH)):
			if abs(z) < ROAD_WIDTH:
				continue

			# East side (x > road) — building faces -X (toward road). Rotation = -90°
			var variant_e = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_e = Vector3(x_road + building_offset + LOT_DEPTH / 2.0, 0, z)
			_place_building_with_collision(variant_e, pos_e, -90, Vector3(LOT_DEPTH * 0.8, 5, LOT_WIDTH * 0.8))
			count += 1

			# West side (x < road) — building faces +X (toward road). Rotation = 90°
			var variant_w = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
			var pos_w = Vector3(x_road - building_offset - LOT_DEPTH / 2.0, 0, z)
			_place_building_with_collision(variant_w, pos_w, 90, Vector3(LOT_DEPTH * 0.8, 5, LOT_WIDTH * 0.8))
			count += 1

	print("  ✓ Buildings placed: ", count, " (with collision + proper orientation)")

func _place_building_with_collision(asset_name: String, pos: Vector3, rot_y: float, collider_size: Vector3):
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

	# Add collision (AABB approximation)
	var col_body = StaticBody3D.new()
	col_body.name = instance.name + "_Collider"
	col_body.transform.origin = pos
	col_body.rotate_y(deg_to_rad(rot_y))

	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = collider_size
	col_shape.shape = box_shape
	col_body.add_child(col_shape)

	city_root.add_child(col_body)
	col_body.owner = city_root

# ============================================================
# STREET FURNITURE — on sidewalks, NOT in road
# ============================================================
func _place_street_furniture():
	var count = 0
	# Offset: on sidewalk centerline
	var sw_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH / 2.0
	var grass_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	# Street lights: every 20m along road, on sidewalk
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-70, 71, 20):
			if abs(x) < ROAD_WIDTH:
				continue
			# South sidewalk
			_place_asset("environment", "street_light", Vector3(x, 0, z_road + sw_offset), 0)
			count += 1
			# North sidewalk
			_place_asset("environment", "street_light", Vector3(x, 0, z_road - sw_offset), 180)
			count += 1

	for x_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for z in range(-70, 71, 20):
			if abs(z) < ROAD_WIDTH:
				continue
			_place_asset("environment", "street_light", Vector3(x_road + sw_offset, 0, z), -90)
			count += 1
			_place_asset("environment", "street_light", Vector3(x_road - sw_offset, 0, z), 90)
			count += 1

	# Fire hydrants: on corner of each intersection
	var corner_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + 0.5
	for x_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
			_place_asset("environment", "fire_hydrant", Vector3(x_road + corner_offset, 0, z_road + corner_offset), 0)
			count += 1

	# Mailboxes: on sidewalk near some houses
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-60, 61, 36):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("environment", "mailbox", Vector3(x + 2, 0, z_road + sw_offset + 0.3), 90)
			count += 1

	# Trash cans: near some houses on sidewalk
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-50, 51, 42):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("environment", "trash_can", Vector3(x - 3, 0, z_road + sw_offset + 0.3), 0)
			count += 1

	# Utility poles: behind sidewalk, in grass strip
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-65, 66, 30):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("environment", "utility_pole", Vector3(x, 0, z_road + grass_offset + 0.5), 0)
			count += 1

	print("  ✓ Street furniture: ", count, " (lights, hydrants, mailboxes, trash, poles)")

# ============================================================
# FOLIAGE — in grass strips + yards
# ============================================================
func _place_foliage():
	var count = 0
	var grass_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	# Trees in grass strips (between sidewalk and building)
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-70, 71, 10):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.4:  # 60% chance of tree
				var tree = TREE_TYPES[rng.randi() % TREE_TYPES.size()]
				var px = x + rng.randf_range(-2, 2)
				var pz = z_road + grass_offset + rng.randf_range(-0.5, 0.5)
				_place_asset("foliage", tree, Vector3(px, 0, pz), rng.randf_range(0, 360))
				count += 1
			# North side
			if rng.randf() > 0.4:
				var tree = TREE_TYPES[rng.randi() % TREE_TYPES.size()]
				var px = x + rng.randf_range(-2, 2)
				var pz = z_road - grass_offset + rng.randf_range(-0.5, 0.5)
				_place_asset("foliage", tree, Vector3(px, 0, pz), rng.randf_range(0, 360))
				count += 1

	# Bushes near building entrances
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-60, 61, 18):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.5:
				_place_asset("foliage", "bush", Vector3(x - 4, 0, z_road + building_offset - 1), 0)
				count += 1
			if rng.randf() > 0.5:
				_place_asset("foliage", "bush", Vector3(x + 4, 0, z_road + building_offset - 1), 0)
				count += 1

	# Hedges along property lines
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-65, 66, 8):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.6:
				_place_asset("foliage", "hedge", Vector3(x, 0, z_road + building_offset - 2), 0)
				count += 1

	# Dead trees scattered
	for i in range(8):
		var px = rng.randf_range(-90, 90)
		var pz = rng.randf_range(-90, 90)
		if abs(pz) < ROAD_WIDTH / 2 + 2 or abs(px) < ROAD_WIDTH / 2 + 2:
			continue
		_place_asset("foliage", "dead_tree", Vector3(px, 0, pz), rng.randf_range(0, 360))
		count += 1

	# Flower patches near some houses
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-50, 51, 25):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("foliage", "flower_patch", Vector3(x + 5, 0, z_road + building_offset + 0.5), 0)
			count += 1

	print("  ✓ Foliage: ", count)

# ============================================================
# PLAYGROUND AREA
# ============================================================
func _place_playground():
	var park = Vector3(40, 0, 40)
	# Make sure park is not on a road
	if abs(park.x) < ROAD_WIDTH or abs(park.z) < ROAD_WIDTH:
		park = Vector3(40, 0, 40)

	_place_asset("environment", "playground_slide", park + Vector3(-4, 0, 0), 0)
	_place_asset("environment", "swing_set", park + Vector3(4, 0, 0), 0)
	_place_asset("environment", "picnic_table", park + Vector3(0, 0, -6), 0)
	_place_asset("environment", "bench_park", park + Vector3(-6, 0, -4), 90)
	_place_asset("environment", "bench_park", park + Vector3(6, 0, -4), -90)

	# Trees around park
	for i in range(8):
		var angle = i * 45.0
		var r = 10.0
		_place_asset("foliage", "oak_tree", Vector3(
			park.x + cos(deg_to_rad(angle)) * r,
			0,
			park.z + sin(deg_to_rad(angle)) * r
		), 0)

	print("  ✓ Playground + park area")

# ============================================================
# SCATTERED PROPS
# ============================================================
func _place_scattered_props():
	var count = 0
	var grass_offset = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH / 2.0

	# Garden gnomes in yards
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-40, 41, 35):
			if abs(x) < ROAD_WIDTH:
				continue
			if rng.randf() > 0.5:
				_place_asset("environment", "garden_gnome", Vector3(x + 4, 0, z_road + building_offset + 2), rng.randf_range(0, 360))
				count += 1

	# Planter boxes near houses
	for z_road in [0, ROAD_SPACING, -ROAD_SPACING]:
		for x in range(-30, 31, 20):
			if abs(x) < ROAD_WIDTH:
				continue
			_place_asset("environment", "planter_box", Vector3(x + 2, 0, z_road + building_offset + 1), 0)
			count += 1

	# Bollards at intersection corners
	var b_off = ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + 0.2
	for x_road in [0, ROAD_SPACING]:
		for z_road in [0, ROAD_SPACING]:
			_place_asset("environment", "bollard", Vector3(x_road + b_off, 0, z_road + b_off), 0)
			count += 1

	# School bus parked on roadside (pull-off area)
	_place_asset("environment", "school_bus", Vector3(65, 0, ROAD_SPACING + sw_safe()), 90)
	count += 1

	print("  ✓ Scattered props: ", count)

func sw_safe() -> float:
	return ROAD_WIDTH / 2.0 + SIDEWALK_WIDTH + 1.0

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
	cam.transform.origin = Vector3(0, 0, 0)
	player.add_child(cam)

	var col = CollisionShape3D.new()
	col.name = "Col"
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.transform.origin = Vector3(0, 0.9, 0)
	player.add_child(col)

	# Inline player script
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
	print("  ✓ Player (first-person, inline script)")

# ============================================================
# ASSET PLACEMENT HELPER
# ============================================================
func _place_asset(category: String, asset_name: String, pos: Vector3, rot_y: float):
	var path = ASSETS.get(category, {}).get(asset_name, "")
	if path == "":
		return
	if not ResourceLoader.exists(path):
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
