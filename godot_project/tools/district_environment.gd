extends Node3D

# DistrictEnvironment — applies per-biome color grade + fog + ambient to
# WorldEnvironment at runtime. Lerps smoothly between biomes as the player
# walks.
#
# Phase B.1 (2026-09-13): The district identity DATA was locked in Phase A.9
# (city_config.gd DISTRICT_IDENTITY). This script is the runtime applier —
# it reads the player's current biome + lerps the WorldEnvironment's sky,
# fog, ambient, and sun energy toward the biome's target values.
#
# Attach as a child of the main scene (main.tscn). Needs a WorldEnvironment
# node in the scene.
#
# The lerp speed (LERP_SPEED) controls how fast the environment transitions
# between biomes. 0.5 = takes ~2 seconds to fully transition.

const CityConfig = preload("res://tools/city_config.gd")
const AnchorPoints = preload("res://tools/anchor_points.gd")

# How fast to lerp between biome environments (0-1 per second)
const LERP_SPEED := 0.5

# Base values (from main.tscn's Environment resource — these are the "no biome"
# defaults that the tints multiply with)
const BASE_SKY_HORIZON := Color(0.70, 0.78, 0.88, 1)
const BASE_FOG_COLOR := Color(0.50, 0.55, 0.60, 1)
const BASE_AMBIENT := Color(0.55, 0.60, 0.65, 1)
const BASE_SUN_ENERGY := 2.0
const BASE_FOG_DENSITY := 0.005

var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _sun: DirectionalLight3D
var _current_biome: int = -1
var _target_identity: Dictionary = {}
var _lerp_t: float = 1.0  # 1.0 = fully at target

func _ready() -> void:
	# Find WorldEnvironment in the scene
	var root := get_tree().current_scene
	var we := root.get_node_or_null("WorldEnvironment")
	if we == null or not (we is WorldEnvironment):
		push_error("[DistrictEnvironment] No WorldEnvironment found in scene")
		return
	_env = we.environment
	if _env == null:
		push_error("[DistrictEnvironment] WorldEnvironment has no Environment resource")
		return
	# Get the sky material
	if _env.sky != null and _env.sky.sky_material != null:
		_sky_mat = _env.sky.sky_material as ProceduralSkyMaterial
	# Find the sun
	_sun = root.get_node_or_null("Sun") as DirectionalLight3D
	print("[DistrictEnvironment] ready — will lerp environment per biome")

func _process(delta: float) -> void:
	if _env == null:
		return
	# Check player's current biome
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return
	var nearest: Variant = AnchorPoints.get_nearest_anchor(player.global_position)
	if nearest == null:
		return
	var biome: int = nearest["biome"]
	# If biome changed, update target
	if biome != _current_biome:
		_current_biome = biome
		_target_identity = CityConfig.district_identity_for(biome)
		_lerp_t = 0.0
		var dname: String = CityConfig.district_name_for(biome)
		print("[DistrictEnvironment] entering biome %d (%s) — lerping environment" % [biome, dname])
	# Lerp toward target
	if _lerp_t < 1.0:
		_lerp_t = min(1.0, _lerp_t + delta * LERP_SPEED)
		_apply_identity(_target_identity, _lerp_t)

func _apply_identity(identity: Dictionary, t: float) -> void:
	if identity.is_empty():
		# No identity for this biome — lerp back to base
		if _sky_mat != null:
			_sky_mat.sky_horizon_color = BASE_SKY_HORIZON.lerp(_sky_mat.sky_horizon_color, 1.0 - t)
		_env.fog_light_color = BASE_FOG_COLOR.lerp(_env.fog_light_color, 1.0 - t)
		_env.ambient_light_color = BASE_AMBIENT.lerp(_env.ambient_light_color, 1.0 - t)
		if _sun != null:
			_sun.light_energy = lerp(BASE_SUN_ENERGY, _sun.light_energy, 1.0 - t)
		_env.fog_density = lerp(BASE_FOG_DENSITY, _env.fog_density, 1.0 - t)
		return
	# Apply tinted values
	var sky_tint: Color = identity.get("sky_tint", Color(1, 1, 1))
	var fog_tint: Color = identity.get("fog_tint", BASE_FOG_COLOR)
	var ambient_tint: Color = identity.get("ambient_tint", BASE_AMBIENT)
	var sun_mult: float = float(identity.get("sun_energy_mult", 1.0))
	var fog_mult: float = float(identity.get("fog_density_mult", 1.0))
	# Compute target colors (base × tint)
	var target_sky := BASE_SKY_HORIZON * sky_tint
	var target_fog := BASE_FOG_COLOR * fog_tint
	var target_ambient := BASE_AMBIENT * ambient_tint
	var target_sun := BASE_SUN_ENERGY * sun_mult
	var target_fog_density := BASE_FOG_DENSITY * fog_mult
	# Lerp from current toward target
	if _sky_mat != null:
		_sky_mat.sky_horizon_color = _sky_mat.sky_horizon_color.lerp(target_sky, t)
	_env.fog_light_color = _env.fog_light_color.lerp(target_fog, t)
	_env.ambient_light_color = _env.ambient_light_color.lerp(target_ambient, t)
	if _sun != null:
		_sun.light_energy = lerp(_sun.light_energy, target_sun, t)
	_env.fog_density = lerp(_env.fog_density, target_fog_density, t)
