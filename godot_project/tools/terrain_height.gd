# TerrainHeight — deterministic height function for the entire map.
#
# Pure function: height_at(x, z) → float. No dependency on Terrain3D at runtime.
# Used by gameplay code (building placement, AI, spawns, bridge pier depth).
# Terrain3D's heightmap is baked from this function once at design time.
#
# See GDD §12 (Terrain Architecture) for full design.
#
# BUMP TERRAIN_HEIGHT_VERSION when the height function changes. This
# invalidates CityMeta hash → triggers chunk rebuild on next city_builder run.
class_name TerrainHeight
extends RefCounted

const TERRAIN_HEIGHT_VERSION := 1

# Per-biome elevation signatures (GDD §12.4)
# base:    baseline Y offset
# amp:     noise amplitude (height variation)
# freq:    noise frequency (lower = wider hills)
const ELEVATIONS := {
	0: {"base": 0.5, "amp": 1.0, "freq": 0.008},    # SUBURBIA
	1: {"base": 1.0, "amp": 2.0, "freq": 0.012},    # PARKS
	2: {"base": 2.0, "amp": 5.0, "freq": 0.018},    # FOREST
	3: {"base": 0.2, "amp": 0.3, "freq": 0.005},   # FARMLAND
	4: {"base": 0.5, "amp": 0.5, "freq": 0.005},   # COMMERCIAL
	5: {"base": 0.5, "amp": 0.5, "freq": 0.005},   # INDUSTRIAL
	6: {"base": -4.0, "amp": 0.0, "freq": 0.0},    # RIVER (carved valley)
	7: {"base": 0.5, "amp": 0.5, "freq": 0.005},   # DOWNTOWN
	8: {"base": 3.0, "amp": 0.0, "freq": 0.0},     # MILITARY (plateau)
	9: {"base": -1.0, "amp": 8.0, "freq": 0.020},  # COASTAL_BEACH
	10: {"base": -2.0, "amp": 0.0, "freq": 0.0},   # WATER (sea level)
	11: {"base": 0.0, "amp": 0.0, "freq": 0.0},    # EMPTY
}

# River carve parameters
const RIVER_HALF_WIDTH := 30.0    # m — river valley is 60m wide
const RIVER_DEPTH := 4.0          # m — riverbed at base-4, water surface at Y=0
const WATER_LEVEL := 0.0          # Y — water surface

var _noise: FastNoiseLite
var _river: Variant  # RiverNetwork instance (or null if not set)

func _init(seed: int = 1337, river: Variant = null) -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = seed
	_noise.frequency = 0.01
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_river = river

# Pure function: returns terrain Y at world (x, z).
# Composes: biome elevation (base + noise) + river carve + road flatten.
func height_at(x: float, z: float) -> float:
	var biome := _biome_at(x, z)
	var elev: Dictionary = ELEVATIONS[biome]
	var base: float = elev["base"]
	var amp: float = elev["amp"]
	var freq: float = elev["freq"]

	# Rolling hills from noise
	var y: float = base
	if amp > 0.0 and freq > 0.0:
		y += _noise.get_noise_2d(x * freq, z * freq) * amp

	# River carve — smooth quadratic falloff over RIVER_HALF_WIDTH
	if _river != null:
		var river_dist: float = _river.distance_to(x, z)
		if river_dist < RIVER_HALF_WIDTH:
			var t: float = river_dist / RIVER_HALF_WIDTH
			# Quadratic falloff: full depth at center, 0 at edge
			var carve: float = -RIVER_DEPTH * (1.0 - t * t)
			y += carve

	# Clamp to reasonable range
	return y

# Returns water depth at (x, z). 0 on land, >0 over water.
# Water surface is at Y=WATER_LEVEL (0.0). Depth = WATER_LEVEL - terrain_y.
func water_depth_at(x: float, z: float) -> float:
	var terrain_y: float = height_at(x, z)
	if terrain_y >= WATER_LEVEL:
		return 0.0
	return WATER_LEVEL - terrain_y

# Returns true if (x, z) is underwater (terrain below water level).
func is_underwater(x: float, z: float) -> bool:
	return height_at(x, z) < WATER_LEVEL

# Returns the biome enum value at world (x, z).
# Uses CityConfig.grid_layout() — same logic as CityBuilder._biome_at_chunk.
func _biome_at(x: float, z: float) -> int:
	var col: int = clamp(int(x / 500.0), 0, 7)  # CELL_SIZE_M = 500
	var row: int = clamp(int(z / 500.0), 0, 5)  # GRID_ROWS = 6
	return CityConfig.grid_layout()[row][col]

# Road flattening — returns a flattened Y for positions near roads.
# TODO B.4: implement. Currently returns height_at() unchanged.
func height_at_flat_for_road(x: float, z: float, road_half_width: float) -> float:
	return height_at(x, z)
