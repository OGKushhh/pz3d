class_name RoadNetwork
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

var segments: Array = []

func generate(rng: RandomNumberGenerator) -> void:
    segments.clear()
    _build_grid_roads(rng)
    _build_bridges(rng)
    _build_highway(rng)

func _add_segment(start: Vector3, end: Vector3, width: float, kind: String, name: String = "") -> void:
    var s := {
        "id": segments.size(),
        "start": start,
        "end": end,
        "width": width,
        "kind": kind,
    }
    if name != "":
        s["name"] = name
    segments.append(s)

func _build_grid_roads(_rng: RandomNumberGenerator) -> void:
    for row in range(CityConfig.GRID_ROWS + 1):
        if false:
            continue
        var z: float = row * CityConfig.CELL_SIZE_M
        for col in range(CityConfig.GRID_COLS):
            _add_segment(
                Vector3(col * CityConfig.CELL_SIZE_M, 0, z),
                Vector3((col + 1) * CityConfig.CELL_SIZE_M, 0, z),
                CityConfig.ROAD_WIDTH, "street"
            )
    for col in range(CityConfig.GRID_COLS + 1):
        if false:
            continue
        var x: float = col * CityConfig.CELL_SIZE_M
        for row in range(CityConfig.GRID_ROWS):
            _add_segment(
                Vector3(x, 0, row * CityConfig.CELL_SIZE_M),
                Vector3(x, 0, (row + 1) * CityConfig.CELL_SIZE_M),
                CityConfig.ROAD_WIDTH, "street"
            )

func _build_bridges(_rng: RandomNumberGenerator) -> void:
    for b in CityConfig.bridges():
        if not (b is Dictionary and b.has("row") and b.has("from_col") and b.has("to_col")):
            push_error("[RoadNetwork] bridge entry missing expected keys: " + str(b))
            continue
        var z: float = b["row"] * CityConfig.CELL_SIZE_M + CityConfig.CELL_SIZE_M * 0.5
        _add_segment(
            Vector3(b["from_col"] * CityConfig.CELL_SIZE_M, 0, z),
            Vector3(b["to_col"] * CityConfig.CELL_SIZE_M, 0, z),
            CityConfig.ROAD_WIDTH * 1.5, "bridge", b["name"]
        )

func _build_highway(_rng: RandomNumberGenerator) -> void:
    pass

func owned_segments_for_chunk(chunk: Vector2i, chunk_size: float) -> Array:
    var out: Array = []
    var c_min_x: float = float(chunk.x) * chunk_size
    var c_max_x: float = c_min_x + chunk_size
    var c_min_z: float = float(chunk.y) * chunk_size
    var c_max_z: float = c_min_z + chunk_size
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        if abs(a.z - b.z) < 0.001:
            if a.z < c_min_z or a.z >= c_max_z:
                continue
            var lo: float = max(min(a.x, b.x), c_min_x)
            var hi: float = min(max(a.x, b.x), c_max_x)
            if lo < hi:
                out.append(_clipped(s, Vector3(lo, a.y, a.z), Vector3(hi, a.y, a.z)))
        elif abs(a.x - b.x) < 0.001:
            if a.x < c_min_x or a.x >= c_max_x:
                continue
            var lo: float = max(min(a.z, b.z), c_min_z)
            var hi: float = min(max(a.z, b.z), c_max_z)
            if lo < hi:
                out.append(_clipped(s, Vector3(a.x, a.y, lo), Vector3(a.x, a.y, hi)))
    return out

func _clipped(s: Dictionary, start: Vector3, end: Vector3) -> Dictionary:
    var c := s.duplicate()
    c["start"] = start
    c["end"] = end
    return c

func owned_segments_in_chunk(chunk_origin: Vector3, chunk_size: float) -> Array:
    var out: Array = []
    var min_x: float = chunk_origin.x
    var max_x: float = chunk_origin.x + chunk_size
    var min_z: float = chunk_origin.z
    var max_z: float = chunk_origin.z + chunk_size
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        if a.z == b.z:
            if a.z >= min_z and a.z < max_z:
                out.append(s)
        elif a.x == b.x:
            if a.x >= min_x and a.x < max_x:
                out.append(s)
    return out

func overlapping_segments(chunk_origin: Vector3, chunk_size: float) -> Array:
    var min_x: float = chunk_origin.x
    var max_x: float = chunk_origin.x + chunk_size
    var min_z: float = chunk_origin.z
    var max_z: float = chunk_origin.z + chunk_size
    var out: Array = []
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        if max(a.x, b.x) < min_x or min(a.x, b.x) > max_x:
            continue
        if max(a.z, b.z) < min_z or min(a.z, b.z) > max_z:
            continue
        out.append(s)
    return out

func distance_to_nearest_road(pos: Vector3) -> float:
    var best: float = INF
    for s in segments:
        var d: float = _point_segment_distance(pos, s["start"], s["end"])
        if d < best:
            best = d
    return best

func mark_roads_in_index(index, cell_size: float) -> void:
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        var half_w: float = float(s["width"]) * 0.5
        var length: float = a.distance_to(b)
        if length < 0.001:
            index.mark_road(a, half_w)
            continue
        var step: float = maxf(2.0, minf(half_w, cell_size))
        var n: int = int(ceil(length / step))
        for i in range(n + 1):
            index.mark_road(a.lerp(b, float(i) / float(n)), half_w)

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
    var ab: Vector3 = b - a
    if ab.length_squared() < 0.001:
        return p.distance_to(a)
    var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(a + ab * t)
