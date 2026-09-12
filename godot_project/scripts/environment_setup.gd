extends Node3D

# Environment Setup — applies v3-tuned sky, sun, fog, SSAO settings.
#
# In main.tscn, these values are set directly as scene properties on the
# WorldEnvironment + Sun nodes. This script exists as a programmatic fallback
# for scenes that need to set up environment at runtime (e.g. procedural scenes).
#
# Values extracted from retired city_builder.gd v3 prototype.
# See docs/retired_city_builder_v3_extraction.md §2 for provenance.
# All constants are in city_config.gd under LIGHTING + FOG section.

const CFG := preload("res://tools/city_config.gd")

func setup_environment(root: Node3D) -> void:
	_setup_sky(root)
	_setup_sun(root)

func _setup_sky(root: Node3D) -> void:
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = CFG.SKY_TOP_COLOR
	sky_mat.sky_horizon_color = CFG.SKY_HORIZON_COLOR
	sky_mat.ground_bottom_color = CFG.GROUND_BOTTOM_COLOR
	sky_mat.ground_horizon_color = CFG.GROUND_HORIZON_COLOR
	sky_mat.sun_angle_max = CFG.SUN_ANGLE_MAX
	sky_mat.sun_curve = CFG.SUN_CURVE
	sky_mat.use_debanding = true
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = CFG.AMBIENT_LIGHT_COLOR
	env.ambient_light_energy = CFG.AMBIENT_LIGHT_ENERGY
	env.fog_enabled = true
	env.fog_light_color = CFG.FOG_COLOR
	env.fog_density = CFG.FOG_DENSITY
	env.fog_aerial_perspective = CFG.FOG_AERIAL_PERSPECTIVE
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = CFG.TONEMAP_WHITE
	env.ssao_enabled = true
	env.ssao_radius = CFG.SSAO_RADIUS
	env.ssao_intensity = CFG.SSAO_INTENSITY
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)
	we.owner = root

func _setup_sun(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform.origin = Vector3(-40, 60, -40)
	sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
	sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
	sun.light_color = CFG.SUN_COLOR
	sun.light_energy = CFG.SUN_ENERGY
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = CFG.SUN_SHADOW_MAX_DIST
	sun.directional_shadow_size = CFG.SUN_SHADOW_SIZE
	root.add_child(sun)
	sun.owner = root
