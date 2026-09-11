extends Node3D

# ChunkStreamer v4 — direct placement, denser, roads every cell
# Fixes:
#   - Roads every grid cell (was every 2nd) — denser street grid
#   - 3x more buildings per chunk (fill*30 to fill*60, was 10-30)
#   - Tighter building radius (8m, was 12m) — closer buildings
#   - 4x more props (25-50, was 6-16)
#   - Ground at Y=0 (top at Y=0.5), player at Y=2
#   - Logging per-chunk stats

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
var _loaded: Dictionary = {}
var _stats: Dictionary = {}

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

    var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
    if f:
        manifest = JSON.parse_string(f.get_as_text())
    print("[ChunkStreamer] manifest: %d assets, player at %s" % [manifest.size(), player.global_position])

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

    var col: int = clamp(int(key.x * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
    var row: int = clamp(int(key.y * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
    var biome: int = CityConfig.grid_layout()[row][col]

    var profile: Dictionary = CityConfig.biomes().get(biome, {})
    if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
        return

    var origin: Vector3 = Vector3(key.x * CityConfig.CHUNK_SIZE_M, 0, key.y * CityConfig.CHUNK_SIZE_M)
    var chunk_root := Node3D.new()
    chunk_root.name = "Chunk_%d_%d" % [key.x, key.y]

    var chunk_seed: int = hash(key) ^ 1337
    var crng := RandomNumberGenerator.new()
    crng.seed = chunk_seed

    var b_count := 0
    var p_count := 0
    var f_count := 0
    var s_count := 0

    # === BUILDINGS (block-based, denser) ===
    var buildings: Array = profile.get("buildings", [])
    if not buildings.is_empty():
        var block_count := 4
        var block_size: float = CityConfig.CHUNK_SIZE_M / float(block_count)
        var inset: float = CityConfig.BUILDING_SETBACK + CityConfig.SIDEWALK_WIDTH + CityConfig.ROAD_WIDTH * 0.5
        var fill: float = profile.get("fill", 0.5)
        var building_radius: float = 8.0  # was 12.0 — tighter

        for bx in range(block_count):
            for bz in range(block_count):
                if crng.randf() > fill:
                    continue
                var block_origin: Vector3 = origin + Vector3(bx * block_size, 0, bz * block_size)
                var target: int = crng.randi_range(int(fill * 30), int(fill * 60))  # was 10-30
                target = min(target, 6)  # cap per block to avoid overcrowding
                for i in range(target):
                    var bname: String = buildings[crng.randi() % buildings.size()]
                    var scene: PackedScene = _get_asset(bname)
                    if scene == null:
                        continue
                    var pos: Vector3 = block_origin + Vector3(
                        crng.randf_range(inset, block_size - inset),
                        0,
                        crng.randf_range(inset, block_size - inset)
                    )
                    if not spatial.is_free(pos, building_radius) or not spatial.is_road_clear(pos):
                        continue
                    var inst: Node3D = scene.instantiate()
                    inst.position = pos
                    inst.rotation.y = _face_nearest_road(pos, crng)
                    inst.name = "%s_%d" % [bname, crng.randi() % 100000]
                    chunk_root.add_child(inst)
                    spatial.insert(pos, building_radius)
                    b_count += 1

    # === PROPS (denser: 25-50, was 6-16) ===
    var props: Array = profile.get("props", [])
    if not props.is_empty():
        var count: int = crng.randi_range(25, 50)
        for i in range(count):
            var pname: String = props[crng.randi() % props.size()]
            var scene: PackedScene = _get_asset(pname)
            if scene == null:
                continue
            var pos: Vector3 = origin + Vector3(
                crng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0),
                0,
                crng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0)
            )
            if not spatial.is_free(pos, 1.5) or not spatial.is_road_clear(pos):
                continue
            var inst: Node3D = scene.instantiate()
            inst.position = pos
            inst.rotation.y = crng.randf_range(0, TAU)
            inst.name = "%s_%d" % [pname, crng.randi() % 100000]
            chunk_root.add_child(inst)
            spatial.insert(pos, 1.5)
            p_count += 1

    # === FOLIAGE (keep dense) ===
    var foliage: Array = profile.get("foliage", [])
    if not foliage.is_empty():
        var count: int = crng.randi_range(15, 50)
        for i in range(count):
            var fname: String = foliage[crng.randi() % foliage.size()]
            var scene: PackedScene = _get_asset(fname)
            if scene == null:
                continue
            var pos: Vector3 = origin + Vector3(
                crng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0),
                0,
                crng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0)
            )
            var radius: float = 3.0 if "tree" in fname else 1.0
            if not spatial.is_free(pos, radius) or not spatial.is_road_clear(pos):
                continue
            var inst: Node3D = scene.instantiate()
            inst.position = pos
            inst.rotation.y = crng.randf_range(0, TAU)
            inst.name = "%s_%d" % [fname, crng.randi() % 100000]
            chunk_root.add_child(inst)
            spatial.insert(pos, radius)
            f_count += 1

    # === STREET LIGHTS ===
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
                        inst.name = "street_light_%d" % crng.randi()
                        chunk_root.add_child(inst)
                        spatial.insert(pos, 0.5)
                        s_count += 1
                    d += CityConfig.STREETLIGHT_SPACING

    add_child(chunk_root)
    _loaded[key] = chunk_root

    var bname: String = profile.get("name", "Unknown")
    print("chunk %d_%d: biome=%s buildings=%d props=%d foliage=%d lights=%d children=%d" % [
        key.x, key.y, bname, b_count, p_count, f_count, s_count, chunk_root.get_child_count()
    ])

    # Track stats
    if not _stats.has(bname):
        _stats[bname] = {"buildings": 0, "props": 0, "foliage": 0, "lights": 0, "chunks": 0}
    _stats[bname]["buildings"] += b_count
    _stats[bname]["props"] += p_count
    _stats[bname]["foliage"] += f_count
    _stats[bname]["lights"] += s_count
    _stats[bname]["chunks"] += 1

func _unload_chunk(key: Vector2i) -> void:
    var inst: Node3D = _loaded[key]
    inst.queue_free()
    _loaded.erase(key)

func _face_nearest_road(pos: Vector3, crng: RandomNumberGenerator) -> float:
    var best_dist: float = INF
    var best_dir: Vector3 = Vector3.FORWARD
    for seg in roads.segments:
        var a: Vector3 = seg["start"]
        var b: Vector3 = seg["end"]
        var dist: float = _point_segment_distance(pos, a, b)
        if dist < best_dist:
            best_dist = dist
            var nearest: Vector3 = _nearest_point_on_segment(pos, a, b)
            best_dir = (nearest - pos).normalized()
    return atan2(best_dir.x, best_dir.z)

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
    var ab: Vector3 = b - a
    if ab.length_squared() < 0.001:
        return p.distance_to(a)
    var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(a + ab * t)

static func _nearest_point_on_segment(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
    var ab: Vector3 = b - a
    if ab.length_squared() < 0.001:
        return a
    var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return a + ab * t

func _get_asset(p_name: String) -> PackedScene:
    if asset_cache.has(p_name):
        return asset_cache[p_name]
    if not manifest.has(p_name):
        return null
    var s: PackedScene = load(manifest[p_name]["path"]) as PackedScene
    asset_cache[p_name] = s
    return s
