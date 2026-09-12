# Road Network — generated ONCE from map seed, BEFORE any chunk builds.
# Chunks query this for setback math and clipped road rendering.
# Ownership rule: a segment belongs to the chunk where its perpendicular
# axis falls in [chunk_min, chunk_max). Non-owner chunks still query for
# setback math but do not render or place lights on non-owned segments.
class_name RoadNetwork
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

var segments: Array = []

func generate(rng: RandomNumberGenerator) -> void:
    segments.clear()
    _build_grid_roads(rng)
    _build_bridges(rng)
    _build_highway(rng)

func _build_grid_roads(_rng: RandomNumberGenerator) -> void:
    for row in range(CFG.GRID_ROWS + 1):
        if (row % 2) != 0:
            continue
        var z := row * CFG.CELL_SIZE_M
        for col in range(CFG.GRID_COLS):
            segments.append({
                "start": Vector3(col * CFG.CELL_SIZE_M, 0, z),
                "end":   Vector3((col + 1) * CFG.CELL_SIZE_M, 0, z),
                "width": CFG.ROAD_WIDTH,
                "kind":  "street",
            })
    for col in range(CFG.GRID_COLS + 1):
        if (col % 2) != 0:
            continue
        var x := col * CFG.CELL_SIZE_M
        for row in range(CFG.GRID_ROWS):
            segments.append({
                "start": Vector3(x, 0, row * CFG.CELL_SIZE_M),
                "end":   Vector3(x, 0, (row + 1) * CFG.CELL_SIZE_M),
                "width": CFG.ROAD_WIDTH,
                "kind":  "street",
            })

func _build_bridges(_rng: RandomNumberGenerator) -> void:
    for b in CFG.bridges():
        var z := b["row"] * CFG.CELL_SIZE_M + CFG.CELL_SIZE_M * 0.5
        segments.append({
            "start": Vector3(b["from_col"] * CFG.CELL_SIZE_M, 0, z),
            "end":   Vector3(b["to_col"]   * CFG.CELL_SIZE_M, 0, z),
            "width": CFG.ROAD_WIDTH * 1.5,
            "kind":  "bridge",
            "name":  b["name"],
        })

func _build_highway(_rng: RandomNumberGenerator) -> void:
    # TODO GLM: add coastal highway + river-crossing avenue per GDD 4.2.
    pass

# ── QUERIES ───────────────────────────────────────────────

# Segments whose bbox overlaps the chunk AND which this chunk OWNS.
# Ownership: perpendicular axis falls in [chunk_min, chunk_max).
func owned_segments_in_chunk(chunk_origin: Vector3, chunk_size: float) -> Array:
    var min_x := chunk_origin.x
    var max_x := chunk_origin.x + chunk_size
    var min_z := chunk_origin.z
    var max_z := chunk_origin.z + chunk_size
    var out: Array = []
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        if a.z == b.z:
            # horizontal → owned by Z
            if a.z >= min_z and a.z < max_z:
                out.append(s)
        elif a.x == b.x:
            # vertical → owned by X
            if a.x >= min_x and a.x < max_x:
                out.append(s)
        else:
            # diagonal (future) → owned by centroid
            var mid := (a + b) * 0.5
            if mid.x >= min_x and mid.x < max_x and mid.z >= min_z and mid.z < max_z:
                out.append(s)
    return out

# All segments overlapping the chunk bbox, regardless of ownership.
# Use for setback math only — do NOT render or place lights from this list.
func overlapping_segments(chunk_origin: Vector3, chunk_size: float) -> Array:
    var min_x := chunk_origin.x
    var max_x := chunk_origin.x + chunk_size
    var min_z := chunk_origin.z
    var max_z := chunk_origin.z + chunk_size
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
    var best := INF
    for s in segments:
        var d := _point_segment_distance(pos, s["start"], s["end"])
        if d < best:
            best = d
    return best

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
    var ab := b - a
    if ab.length_squared() < 0.001:
        return p.distance_to(a)
    var t := clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(a + ab * t)
