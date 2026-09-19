# Rebuilds baked_world.tscn with Cogito's player (MazarPlayer) instead of our old player.
# Run: godot --headless --path godot_project --script res://scripts/rebuild_baked_world.gd

extends SceneTree

const CityConfig = preload("res://tools/city_config.gd")
const MazarPlayerScript = preload("res://scripts/mazar_player.gd")

func _init():
	print("=== Rebuild baked_world.tscn ===")
	var root := Node3D.new()
	root.name = "BakedCity"

	# Sky
	_setup_sky(root)
	# Sun
	_setup_sun(root)
	# Ground
	_setup_ground(root)
	# Player — instance Cogito's player scene, swap script to MazarPlayer
	_setup_player(root)

	# Save
	var scene := PackedScene.new()
	scene.pack(root)
	var err := ResourceSaver.save(scene, "res://scenes/baked_world.tscn")
	if err == OK:
		print("✅ Saved: res://scenes/baked_world.tscn")
	else:
		print("❌ Save failed: ", err)
	quit()

func _setup_sky(root: Node3D) -> void:
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.35, 0.70, 1)
	sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.88, 1)
	sky_mat.ground_bottom_color = Color(0.25, 0.22, 0.18, 1)
	sky_mat.ground_horizon_color = Color(0.50, 0.48, 0.42, 1)
	sky_mat.sun_angle_max = 30.0
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

func _setup_sun(root: Node3D) -> void:
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

func _setup_ground(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.position = Vector3(CityConfig.MAP_SIZE_M.x * 0.5, 0, CityConfig.MAP_SIZE_M.y * 0.5)
	root.add_child(body)
	body.owner = root
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(CityConfig.MAP_SIZE_M.x + 100, 1, CityConfig.MAP_SIZE_M.y + 100)
	col.shape = shape
	body.add_child(col)
	col.owner = root
	var mi := MeshInstance3D.new()
	mi.name = "GroundMesh"
	var p := PlaneMesh.new()
	p.size = Vector2(CityConfig.MAP_SIZE_M.x + 100, CityConfig.MAP_SIZE_M.y + 100)
	mi.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.40, 0.16, 1)
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)
	mi.owner = root

func _setup_player(root: Node3D) -> void:
	# Load Cogito's player scene
	var player_scene := load("res://addons/cogito/PackedScenes/cogito_player_advanced.tscn") as PackedScene
	if player_scene == null:
		print("❌ Failed to load cogito_player_advanced.tscn")
		return
	var player := player_scene.instantiate()
	player.name = "Player"
	# Swap script to MazarPlayer
	player.set_script(MazarPlayerScript)
	# Position at center of map
	player.position = Vector3(CityConfig.MAP_SIZE_M.x * 0.4, 2, CityConfig.MAP_SIZE_M.y * 0.5)
	root.add_child(player)
	player.owner = root
	print("  ✓ Player (MazarPlayer) at center")
