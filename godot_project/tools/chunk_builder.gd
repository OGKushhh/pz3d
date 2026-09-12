# ============================================================
# PLACEMENT RULES — extracted from retired city_builder.gd v3
# See docs/retired_city_builder_v3_extraction.md §3 for provenance.
#
# 1. STREET LIGHTS: place on grass strip center, NOT on road edge.
#    Offset = ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH/2.
#    Alternate sides every 25m. Was 20m in v2 — 25m is less cluttered.
#
# 2. UTILITY POLES: place FAR BEHIND buildings, not clipping into houses.
#    Offset = building_offset + LOT_DEPTH + UTILITY_POLE_OFFSET.
#
# 3. FIRE HYDRANTS: place at intersection corners with extra clearance.
#    corner_off = ROAD_WIDTH/2 + SIDEWALK_WIDTH + 1.0.
#
# 4. BUILDINGS: use LOT_WIDTH=20m × LOT_DEPTH=16m lots.
#    Collider size = LOT_WIDTH * 0.75 × LOT_DEPTH * 0.75.
#    Orientation: South=0°, North=180°, East=-90°, West=90°.
#
# 5. TREES: place in grass strip CENTER (not on building side, not on road).
#    tree_offset = ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH/2.
#    Add jitter: px ± 1.5m, pz ± 0.3m.
#
# 6. FLOATING OBJECTS: ground all Y positions explicitly.
#    Y=0.00 ground, Y=0.02 road, Y=0.03 grass strip, Y=0.05 sidewalk.
#
# 7. SPACING: minimum 2m clearance between ALL objects.
#
# 8. FENCES ONLY ALONG FRONT PROPERTY LINE — don't run through lots.
#
# 9. HEDGES along front property lines (between grass strip and building).
#
# Y-offset layer cake:
#   Y = 0.00  — ground plane / buildings / props / foliage
#   Y = 0.02  — road surface (2cm above ground)
#   Y = 0.03  — grass strip (3cm above ground)
#   Y = 0.05  — sidewalk (5cm above ground)
# ============================================================

class_name ChunkBuilder
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

var spatial
var roads
var manifest: Dictionary
var asset_cache: Dictionary
var rng: RandomNumberGenerator
var chunk_coord: Vector2i

func _init(idx, net, man: Dictionary, cache: Dictionary, p_seed: int, p_chunk: Vector2i) -> void:
    spatial = idx
    roads = net
    manifest = man
    asset_cache = cache
    rng = RandomNumberGenerator.new()
    rng.seed = p_seed
    chunk_coord = p_chunk

func build(biome: int, chunk_origin: Vector3) -> Node3D:
    var profile: Dictionary = CityConfig.biomes().get(biome, {})
    var root: Node3D = Node3D.new()
    root.name = "Chunk_%d_%d" % [chunk_coord.x, chunk_coord.y]
    root.set_meta("biome", biome)
    root.set_meta("origin", chunk_origin)

    if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
        return root

    _place_buildings(root, profile, chunk_origin)
    _place_props(root, profile, chunk_origin)
    _place_foliage(root, profile, chunk_origin)
    if profile.get("lights", false):
        _place_streetlights(root, chunk_origin)

    print("  chunk %d_%d: biome=%d children=%d" % [chunk_coord.x, chunk_coord.y, biome, root.get_child_count()])
    return root

func _place_buildings(root: Node3D, profile: Dictionary, origin: Vector3) -> void:
    var buildings: Array = profile.get("buildings", [])
    if buildings.is_empty():
        return

    # Block-based placement — buildings line up in rows like GTA SA
    var block_count := 4
    var block_size: float = CityConfig.CHUNK_SIZE_M / float(block_count)
    var inset: float = CityConfig.BUILDING_SETBACK + CityConfig.SIDEWALK_WIDTH + CityConfig.ROAD_WIDTH * 0.5
    var fill: float = profile.get("fill", 0.5)

    for bx in range(block_count):
        for bz in range(block_count):
            if rng.randf() > fill:
                continue  # vacant lot
            var block_origin: Vector3 = origin + Vector3(bx * block_size, 0, bz * block_size)
            _fill_block(root, buildings, block_origin, block_size, inset)

func _fill_block(root: Node3D, buildings: Array, block_origin: Vector3, block_size: float, inset: float) -> void:
    var count: int = rng.randi_range(2, 4)
    for i in range(count):
        var bname: String = buildings[rng.randi() % buildings.size()]
        var scene: PackedScene = _get_asset(bname)
        if scene == null:
            continue
        var pos: Vector3 = block_origin + Vector3(
            rng.randf_range(inset, block_size - inset),
            0,
            rng.randf_range(inset, block_size - inset)
        )
        if not spatial.is_free(pos, 12.0) or spatial.is_on_road(pos):
            continue
        var rot_y: float = _face_nearest_road(pos)
        _spawn(scene, root, pos, bname, rot_y)
        spatial.insert(pos, 12.0)

func _place_props(root: Node3D, profile: Dictionary, origin: Vector3) -> void:
    var props: Array = profile.get("props", [])
    if props.is_empty():
        return

    var count: int = rng.randi_range(6, 16)
    for i in range(count):
        var pname: String = props[rng.randi() % props.size()]
        var scene: PackedScene = _get_asset(pname)
        if scene == null:
            continue

        var pos: Vector3 = origin + Vector3(
            rng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0),
            0,
            rng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0)
        )

        if not spatial.is_free(pos, 1.5):
            continue
        if spatial.is_on_road(pos):
            continue

        _spawn(scene, root, pos, pname, rng.randf_range(0, TAU))
        spatial.insert(pos, 1.5)

func _place_foliage(root: Node3D, profile: Dictionary, origin: Vector3) -> void:
    var foliage: Array = profile.get("foliage", [])
    if foliage.is_empty():
        return

    var count: int = rng.randi_range(15, 50)
    for i in range(count):
        var fname: String = foliage[rng.randi() % foliage.size()]
        var scene: PackedScene = _get_asset(fname)
        if scene == null:
            continue

        var pos: Vector3 = origin + Vector3(
            rng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0),
            0,
            rng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0)
        )

        var radius: float = 3.0 if "tree" in fname else 1.0
        if not spatial.is_free(pos, radius):
            continue
        if spatial.is_on_road(pos):
            continue

        _spawn(scene, root, pos, fname, rng.randf_range(0, TAU))
        spatial.insert(pos, radius)

func _place_streetlights(root: Node3D, origin: Vector3) -> void:
    var scene: PackedScene = _get_asset("street_light")
    if scene == null:
        return

    var owned: Array = roads.owned_segments_for_chunk(chunk_coord, CityConfig.CHUNK_SIZE_M)
    var edge_offset: float = CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH * 0.5

    for seg in owned:
        var a: Vector3 = seg["start"]
        var b: Vector3 = seg["end"]
        var length: float = a.distance_to(b)
        var d: float = 0.0
        while d < length:
            var t: float = d / length if length > 0.001 else 0.0
            var base: Vector3 = a.lerp(b, t)
            var dir: Vector3 = (b - a).normalized()
            var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
            var pos: Vector3 = base + perp * edge_offset

            if not spatial.is_on_road(pos) and spatial.is_free(pos, 0.5):
                _spawn(scene, root, pos, "street_light", 0.0)
                spatial.insert(pos, 0.5)

            d += CityConfig.STREETLIGHT_SPACING

func _face_nearest_road(pos: Vector3) -> float:
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

func _spawn(scene: PackedScene, parent: Node3D, pos: Vector3, hint: String, rot_y: float) -> Node3D:
    var inst: Node3D = scene.instantiate()
    inst.position = pos
    inst.rotation.y = rot_y
    inst.name = "%s_%d" % [hint, rng.randi() % 100000]
    parent.add_child(inst)
    return inst

func _get_asset(p_name: String) -> PackedScene:
    if asset_cache.has(p_name):
        return asset_cache[p_name]
    if not manifest.has(p_name):
        return null
    var s: PackedScene = load(manifest[p_name]["path"]) as PackedScene
    asset_cache[p_name] = s
    return s
