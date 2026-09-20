class_name PlanGrid
extends RefCounted

# Step 1: Global density field — 20m resolution grid over the whole map.
# Each cell holds a density value (0-1) modulated by biome fill, road distance, and Perlin noise.
# This produces spatially coherent density instead of dice-per-chunk random.

const CityConfig = preload("res://tools/city_config.gd")

var cols: int
var rows: int
var cell_size: float = 20.0
var density: PackedFloat32Array
var road_dist: PackedFloat32Array

func _init() -> void:
    cols = int(CityConfig.MAP_SIZE_M.x / cell_size)
    rows = int(CityConfig.MAP_SIZE_M.y / cell_size)
    density.resize(cols * rows)
    road_dist.resize(cols * rows)

func build(roads, map_seed: int) -> void:
    # 1. Fill density from biome fill values
    _fill_biome_density()
    # 2. Blur 3x3 twice for smooth transitions
    _blur3x3()
    _blur3x3()
    # 3. Compute road distances
    _compute_road_distances(roads)
    # 4. Modulate density by road distance
    _modulate_by_road_distance()
    # 5. Perlin noise modulation
    _modulate_by_noise(map_seed)
    # 6. Clamp to [0, 1]
    _clamp_density()
    print("[PlanGrid] built %dx%d cells (%.1f km²)" % [cols, rows, (cols * cell_size * rows * cell_size) / 1e6])

func _fill_biome_density() -> void:
    for r in range(rows):
        for c in range(cols):
            var world_x: float = c * cell_size
            var world_z: float = r * cell_size
            var biome: int = _biome_at(world_x, world_z)
            var profile: Dictionary = CityConfig.biomes().get(biome, {})
            density[r * cols + c] = profile.get("fill", 0.0)

func _biome_at(world_x: float, world_z: float) -> int:
    var col: int = clamp(int(world_x / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
    var row: int = clamp(int(world_z / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
    return CityConfig.grid_layout()[row][col]

func _blur3x3() -> void:
    var src := density.duplicate()
    for r in range(rows):
        for c in range(cols):
            var sum: float = 0.0
            var count: int = 0
            for dr in range(-1, 2):
                for dc in range(-1, 2):
                    var nr: int = r + dr
                    var nc: int = c + dc
                    if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
                        sum += src[nr * cols + nc]
                        count += 1
            density[r * cols + c] = sum / float(count)

func _compute_road_distances(roads) -> void:
    for r in range(rows):
        for c in range(cols):
            var pos := Vector3(c * cell_size, 0, r * cell_size)
            road_dist[r * cols + c] = roads.distance_to_nearest_road(pos)

func _modulate_by_road_distance() -> void:
    for i in range(density.size()):
        var rd: float = road_dist[i]
        var factor: float = clamp(1.5 - rd / 100.0, 0.2, 1.3)
        density[i] *= factor

func _modulate_by_noise(map_seed: int) -> void:
    var noise := FastNoiseLite.new()
    noise.seed = map_seed
    noise.frequency = 0.005
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    for r in range(rows):
        for c in range(cols):
            var world_x: float = c * cell_size
            var world_z: float = r * cell_size
            var n: float = noise.get_noise_2d(world_x, world_z)
            density[r * cols + c] *= 0.75 + n * 0.5

func _clamp_density() -> void:
    for i in range(density.size()):
        density[i] = clamp(density[i], 0.0, 1.0)

func sample_density(pos: Vector3) -> float:
    var c: int = clamp(int(pos.x / cell_size), 0, cols - 1)
    var r: int = clamp(int(pos.z / cell_size), 0, rows - 1)
    return density[r * cols + c]
