# O(1) spatial occupancy grid. Replaces linear arrays that break past 5k placements.
# Correctness: insert marks every cell the disc overlaps; query scans the matching
# window. Verified by res://tests/spatial_index_test.gd.
class_name SpatialIndex
extends RefCounted

var _occupied: Dictionary = {}
var _road: Dictionary = {}
var cell_size: float

func _init(cell_m: float = 8.0) -> void:
    cell_size = cell_m

func _key(pos: Vector3) -> Vector2i:
    return Vector2i(int(floor(pos.x / cell_size)), int(floor(pos.z / cell_size)))

func is_free(pos: Vector3, radius: float) -> bool:
    var r := int(ceil(radius / cell_size))
    var c := _key(pos)
    for dx in range(-r, r + 1):
        for dz in range(-r, r + 1):
            var k := c + Vector2i(dx, dz)
            if not _occupied.has(k):
                continue
            for o in _occupied[k]:
                if pos.distance_to(o["pos"]) < radius + o["radius"]:
                    return false
    return true

func insert(pos: Vector3, radius: float) -> void:
    var r := int(ceil(radius / cell_size))
    var c := _key(pos)
    for dx in range(-r, r + 1):
        for dz in range(-r, r + 1):
            var k := c + Vector2i(dx, dz)
            if not _occupied.has(k):
                _occupied[k] = []
            _occupied[k].append({"pos": pos, "radius": radius})

func mark_road(pos: Vector3, half_width: float) -> void:
    var r := int(ceil(half_width / cell_size))
    var c := _key(pos)
    for dx in range(-r, r + 1):
        for dz in range(-r, r + 1):
            _road[c + Vector2i(dx, dz)] = true

func is_road_clear(pos: Vector3) -> bool:
    return not _road.has(_key(pos))

func clear() -> void:
    _occupied.clear()
    _road.clear()
