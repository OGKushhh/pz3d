extends Node3D

# Direct placement ChunkStreamer — no .tscn files needed
# Loads GLB assets directly and places them around the player

const CityConfig = preload("res://tools/city_config.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const RoadNetwork = preload("res://tools/road_network.gd")

var player: Node3D
var stream_radius: int = 2
var spatial: SpatialIndex
var roads: RoadNetwork
var manifest: Dictionary = {}
var asset_cache: Dictionary = {}
var rng: RandomNumberGenerator
var _loaded: Dictionary = {}  # Vector2i -> Node3D

func _ready() -> void:
    await get_tree().process_frame
    var root := get_tree().current_scene
    player = root.get_node_or_null("Player")
    if player == null:
        for child in root.get_children():
            if child is CharacterBody3D:
                player = child
                break
    if player == null:
        push_error("[ChunkStreamer] No player found!")
        return

    # Load manifest
    var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
    if f:
        manifest = JSON.parse_string(f.get_as_text())
    print("[ChunkStreamer] manifest: %d assets, player at %s" % [manifest.size(), player.global_position])

    # Init spatial index + roads
    spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
    roads = RoadNetwork.new()
    rng = RandomNumberGenerator.new()
    rng.seed = 1337
    roads.generate(rng)
    roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)

func _process(_delta: float) -> void:
    if player == null or manifest.is_empty():
        return
    var cx: int = int(floor(player.global_position.x / CityConfig.CHUNK_SIZE_M))
    var cy: int = int(floor(player.global_position.z / CityConfig.CHUNK_SIZE_M))
    _refresh(cx, cy)

func _refresh(cx: int, cy: int) -> void:
    var unload_r: int = stream_radius + CityConfig.STREAM_UNLOAD_BUFFER
    var wanted: Dictionary = {}

    for dy in range(-stream_radius, stream_radius + 1):
        for dx in range(-stream_radius, stream_radius + 1):
            var key := Vector2i(cx + dx, cy + dy)
            wanted[key] = true
            if not _loaded.has(key):
                _build_chunk(key)

    var to_remove: Array = []
    for key in _loaded:
        if abs(key.x - cx) > unload_r or abs(key.y - cy) > unload_r:
            to_remove.append(key)
    for key in to_remove:
        _unload_chunk(key)

func _build_chunk(key: Vector2i) -> void:
    if key.x < 0 or key.y < 0 or key.x >= CityConfig.CHUNKS_COLS or key.y >= CityConfig.CHUNKS_ROWS:
        return

    # Get biome for this chunk
    var col: int = clamp(int(key.x * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
    var row: int = clamp(int(key.y * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
    var biome: int = CityConfig.grid_layout()[row][col]

    var profile: Dictionary = CityConfig.biomes().get(biome, {})
    if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
        return

    var origin: Vector3 = Vector3(key.x * CityConfig.CHUNK_SIZE_M, 0, key.y * CityConfig.CHUNK_SIZE_M)
    var chunk_root := Node3D.new()
    chunk_root.name = "Chunk_%d_%d" % [key.x, key.y]

    # Per-chunk RNG
    var chunk_seed: int = hash(key) ^ 1337
    var chunk_rng := RandomNumberGenerator.new()
    chunk_rng.seed = chunk_seed

    # Place buildings (block-based)
    var buildings: Array = profile.get("buildings", [])
    if not buildings.is_empty():
        var block_count := 4
        var block_size: float = CityConfig.CHUNK_SIZE_M / float(block_count)
        var inset: float = CityConfig.BUILDING_SETBACK + CityConfig.SIDEWALK_WIDTH + CityConfig.ROAD_WIDTH * 0.5
        var fill: float = profile.get("fill", 0.5)

        for bx in range(block_count):
            for bz in range(block_count):
                if chunk_rng.randf() > fill:
                    continue
                var block_origin: Vector3 = origin + Vector3(bx * block_size, 0, bz * block_size)
                var count: int = chunk_rng.randi_range(2, 4)
                for i in range(count):
                    var bname: String = buildings[chunk_rng.randi() % buildings.size()]
                    var scene: PackedScene = _get_asset(bname)
                    if scene == null:
                        continue
                    var pos: Vector3 = block_origin + Vector3(
                        chunk_rng.randf_range(inset, block_size - inset),
                        0,
                        chunk_rng.randf_range(inset, block_size - inset)
                    )
                    if not spatial.is_free(pos, 12.0) or not spatial.is_road_clear(pos):
                        continue
                    var inst: Node3D = scene.instantiate()
                    inst.position = pos
                    inst.rotation.y = chunk_rng.randf_range(0, TAU)
                    inst.name = "%s_%d" % [bname, chunk_rng.randi() % 100000]
                    chunk_root.add_child(inst)
                    spatial.insert(pos, 12.0)

    # Place props
    var props: Array = profile.get("props", [])
    if not props.is_empty():
        var count: int = chunk_rng.randi_range(6, 16)
        for i in range(count):
            var pname: String = props[chunk_rng.randi() % props.size()]
            var scene: PackedScene = _get_asset(pname)
            if scene == null:
                continue
            var pos: Vector3 = origin + Vector3(
                chunk_rng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0),
                0,
                chunk_rng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0)
            )
            if not spatial.is_free(pos, 1.5) or not spatial.is_road_clear(pos):
                continue
            var inst: Node3D = scene.instantiate()
            inst.position = pos
            inst.rotation.y = chunk_rng.randf_range(0, TAU)
            inst.name = "%s_%d" % [pname, chunk_rng.randi() % 100000]
            chunk_root.add_child(inst)
            spatial.insert(pos, 1.5)

    # Place foliage
    var foliage: Array = profile.get("foliage", [])
    if not foliage.is_empty():
        var count: int = chunk_rng.randi_range(15, 50)
        for i in range(count):
            var fname: String = foliage[chunk_rng.randi() % foliage.size()]
            var scene: PackedScene = _get_asset(fname)
            if scene == null:
                continue
            var pos: Vector3 = origin + Vector3(
                chunk_rng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0),
                0,
                chunk_rng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0)
            )
            var radius: float = 3.0 if "tree" in fname else 1.0
            if not spatial.is_free(pos, radius) or not spatial.is_road_clear(pos):
                continue
            var inst: Node3D = scene.instantiate()
            inst.position = pos
            inst.rotation.y = chunk_rng.randf_range(0, TAU)
            inst.name = "%s_%d" % [fname, chunk_rng.randi() % 100000]
            chunk_root.add_child(inst)
            spatial.insert(pos, radius)

    # Place street lights
    if profile.get("lights", false):
        var scene: PackedScene = _get_asset("street_light")
        if scene != null:
            var owned: Array = roads.owned_segments_in_chunk(origin, CityConfig.CHUNK_SIZE_M)
            var edge_offset: float = CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH * 0.5
            for seg in owned:
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                var length: float = a.distance_to(b)
                var d: float = 0.0
                while d < length:
                    var t: float = d / length if length > 0.001 else 0.0
                    var base: Vector3 = a.lerp(b, t)
                    var dir: Vector3 = (b - a).normalized() if length > 0.001 else Vector3.FORWARD
                    var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
                    var pos: Vector3 = base + perp * edge_offset
                    if spatial.is_road_clear(pos) and spatial.is_free(pos, 0.5):
                        var inst: Node3D = scene.instantiate()
                        inst.position = pos
                        inst.name = "street_light_%d" % chunk_rng.randi()
                        chunk_root.add_child(inst)
                        spatial.insert(pos, 0.5)
                    d += CityConfig.STREETLIGHT_SPACING

    add_child(chunk_root)
    _loaded[key] = chunk_root
    print("[ChunkStreamer] built chunk (%d,%d) biome=%d children=%d" % [key.x, key.y, biome, chunk_root.get_child_count()])

func _unload_chunk(key: Vector2i) -> void:
    var inst: Node3D = _loaded[key]
    inst.queue_free()
    _loaded.erase(key)

func _get_asset(p_name: String) -> PackedScene:
    if asset_cache.has(p_name):
        return asset_cache[p_name]
    if not manifest.has(p_name):
        return null
    var s: PackedScene = load(manifest[p_name]["path"]) as PackedScene
    asset_cache[p_name] = s
    return s
