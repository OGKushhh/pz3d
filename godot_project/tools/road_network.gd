class_name RoadNetwork
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

var segments: Array = []

func generate(rng: RandomNumberGenerator) -> void:
    segments.clear()
    _build_grid_roads(rng)
    _build_local_streets(rng)
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

# Phase C.1.1: 3-tier road hierarchy.
# Highways: every 4th grid road (every 2000m), 12m wide, "highway" kind.
# Arterials: remaining grid roads (every 500m), 8m wide, "arterial" kind (was "street").
# Local streets: inside cells at 125m spacing, 5m wide, "local" kind (C.1.2).
#
# Highway rows: 0 and 4 (z=0, z=2000) — 2 east-west highways
# Highway cols: 0 and 4 (x=0, x=2000) — 2 north-south highways
# This creates a highway ring around the city center + cross-highways through it.
const HIGHWAY_WIDTH := 12.0
const ARTERIAL_WIDTH := 8.0  # was CityConfig.ROAD_WIDTH (8.0)
const LOCAL_WIDTH := 5.0
const HIGHWAY_INTERVAL := 4  # every 4th grid line is a highway

func _build_grid_roads(_rng: RandomNumberGenerator) -> void:
    # Horizontal roads (east-west) at each row boundary
    for row in range(CityConfig.GRID_ROWS + 1):
        var z: float = row * CityConfig.CELL_SIZE_M
        var is_hwy: bool = (row % HIGHWAY_INTERVAL == 0)
        var kind: String = "highway" if is_hwy else "arterial"
        var width: float = HIGHWAY_WIDTH if is_hwy else ARTERIAL_WIDTH
        for col in range(CityConfig.GRID_COLS):
            _add_segment(
                Vector3(col * CityConfig.CELL_SIZE_M, 0, z),
                Vector3((col + 1) * CityConfig.CELL_SIZE_M, 0, z),
                width, kind
            )
    # Vertical roads (north-south) at each column boundary
    for col in range(CityConfig.GRID_COLS + 1):
        var x: float = col * CityConfig.CELL_SIZE_M
        var is_hwy: bool = (col % HIGHWAY_INTERVAL == 0)
        var kind: String = "highway" if is_hwy else "arterial"
        var width: float = HIGHWAY_WIDTH if is_hwy else ARTERIAL_WIDTH
        for row in range(CityConfig.GRID_ROWS):
            _add_segment(
                Vector3(x, 0, row * CityConfig.CELL_SIZE_M),
                Vector3(x, 0, (row + 1) * CityConfig.CELL_SIZE_M),
                width, kind
            )

# Phase C.1.2: Local streets inside each cell.
# Each 500m cell gets local streets at 125m spacing, dividing it into 4 strips.
# Local streets run parallel to the arterials and connect to them at cell borders.
# Width: 5m, kind: "local". These are the narrow residential streets where houses face.
const LOCAL_STREET_SPACING := 125.0  # meters between local streets
func _build_local_streets(_rng: RandomNumberGenerator) -> void:
    # For each cell, add local streets inside it (not on borders — arterials handle those)
    for row in range(CityConfig.GRID_ROWS):
        for col in range(CityConfig.GRID_COLS):
            var cell_x: float = col * CityConfig.CELL_SIZE_M
            var cell_z: float = row * CityConfig.CELL_SIZE_M
            # Horizontal local streets (east-west) inside the cell
            # Skip the cell border (z=0 offset) — that's an arterial. Add 3 local streets at 125, 250, 375m
            for i in range(1, int(CityConfig.CELL_SIZE_M / LOCAL_STREET_SPACING)):
                var z: float = cell_z + i * LOCAL_STREET_SPACING
                _add_segment(
                    Vector3(cell_x, 0, z),
                    Vector3(cell_x + CityConfig.CELL_SIZE_M, 0, z),
                    LOCAL_WIDTH, "local"
                )
            # Vertical local streets (north-south) inside the cell
            for i in range(1, int(CityConfig.CELL_SIZE_M / LOCAL_STREET_SPACING)):
                var x: float = cell_x + i * LOCAL_STREET_SPACING
                _add_segment(
                    Vector3(x, 0, cell_z),
                    Vector3(x, 0, cell_z + CityConfig.CELL_SIZE_M),
                    LOCAL_WIDTH, "local"
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

# Phase B.7.1: Returns full info about the nearest road segment to pos.
# Unlike distance_to_nearest_road (which returns only the distance), this
# returns the nearest point ON the road centerline, the road segment's
# direction, and the segment itself. Used by Parcel to derive road_edge_pos
# + front_dir from actual road geometry (not chunk-grid assumptions).
#
# Returns Dictionary:
#   { distance: float,      # distance from pos to nearest point on road
#     point: Vector3,       # nearest point on road centerline (world space)
#     direction: Vector3,   # normalized direction of the road segment
#     segment: Dictionary,  # the road segment dict {start, end, width, kind, ...}
#     found: bool }         # false if no roads (empty network)
func nearest_road_info(pos: Vector3) -> Dictionary:
    var best_d: float = INF
    var best_point: Vector3 = pos
    var best_dir: Vector3 = Vector3(0, 0, 1)
    var best_seg: Dictionary = {}
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        var ab: Vector3 = b - a
        var t: float = 0.0
        if ab.length_squared() < 0.001:
            var d: float = pos.distance_to(a)
            if d < best_d:
                best_d = d
                best_point = a
                best_dir = Vector3(0, 0, 1)
                best_seg = s
        else:
            t = clamp((pos - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
            var proj: Vector3 = a + ab * t
            var d2: float = pos.distance_to(proj)
            if d2 < best_d:
                best_d = d2
                best_point = proj
                best_dir = ab.normalized()
                best_seg = s
    return {
        "distance": best_d,
        "point": best_point,
        "direction": best_dir,
        "segment": best_seg,
        "found": best_d < INF,
    }

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

# ── ROAD GRAPH HELPERS (Phase A.6) ────────────────────────
# The road network is a graph: nodes are implicit at every road segment
# endpoint + every cell corner intersection. Edges are the segments
# themselves. These helpers expose the graph relationship for queries
# like "which roads pass through district cell X?" and "which anchors
# does road Y connect?".
#
# Cell coords here use the (col, row) convention where (0,0) is NW corner
# and (GRID_COLS-1, GRID_ROWS-1) is SE corner. Cell (col, row) spans
# x ∈ [col*500, (col+1)*500), z ∈ [row*500, (row+1)*500).
# Anchors (per AnchorPoints.gd) sit at cell CENTERS: (col*500+250, row*500+250).
# Roads sit at cell BORDERS: (col*500, row*500).

# Returns all road segments that pass through the given grid cell.
# Uses Liang-Barsky segment-rectangle intersection (same algorithm as
# chunk_streamer._get_roads_in_chunk but for grid cells not chunks).
const ANCHOR_CFG := preload("res://tools/city_config.gd")
func get_roads_through_cell(cell: Vector2i) -> Array:
    var result: Array = []
    var min_x: float = float(cell.x) * ANCHOR_CFG.CELL_SIZE_M
    var max_x: float = min_x + ANCHOR_CFG.CELL_SIZE_M
    var min_z: float = float(cell.y) * ANCHOR_CFG.CELL_SIZE_M
    var max_z: float = min_z + ANCHOR_CFG.CELL_SIZE_M
    for seg in segments:
        var a: Vector3 = seg["start"]
        var b: Vector3 = seg["end"]
        if _segment_intersects_rect(a, b, min_x, max_x, min_z, max_z):
            result.append(seg)
    return result

# Returns all grid cells that a road segment passes through. Inverse of
# get_roads_through_cell. Walks the segment at 50m steps and records
# each unique cell entered. Used by future systems to answer "which
# districts does this road traverse?" (e.g., for zoning decisions).
func get_cells_for_road(seg: Dictionary) -> Array:
    var a: Vector3 = seg["start"]
    var b: Vector3 = seg["end"]
    var length: float = a.distance_to(b)
    if length < 1.0:
        return []
    var dir: Vector3 = (b - a).normalized()
    var cells: Array = []
    var seen: Dictionary = {}
    var step: float = 50.0
    var d: float = 0.0
    while d <= length:
        var p: Vector3 = a + dir * d
        var col: int = clamp(int(p.x / ANCHOR_CFG.CELL_SIZE_M), 0, ANCHOR_CFG.GRID_COLS - 1)
        var row: int = clamp(int(p.z / ANCHOR_CFG.CELL_SIZE_M), 0, ANCHOR_CFG.GRID_ROWS - 1)
        var key := Vector2i(col, row)
        if not seen.has(key):
            seen[key] = true
            cells.append(key)
        d += step
    var col_end: int = clamp(int(b.x / ANCHOR_CFG.CELL_SIZE_M), 0, ANCHOR_CFG.GRID_COLS - 1)
    var row_end: int = clamp(int(b.z / ANCHOR_CFG.CELL_SIZE_M), 0, ANCHOR_CFG.GRID_ROWS - 1)
    var end_key := Vector2i(col_end, row_end)
    if not seen.has(end_key):
        cells.append(end_key)
    return cells

# Returns all road segments of a specific kind ("street" / "highway" /
# "bridge" / "diagonal"). Used by highway clearance checks + future zoning.
func get_roads_of_kind(kind: String) -> Array:
    var result: Array = []
    for seg in segments:
        if seg.get("kind", "street") == kind:
            result.append(seg)
    return result

# Returns the perpendicular distance from a world point to a road segment's
# centerline (clamped to the segment's extent — so cross-streets near an
# endpoint don't count). Used by highway clearance checks.
func distance_to_road_centerline(pos: Vector3, seg: Dictionary) -> float:
    var a: Vector3 = seg["start"]
    var b: Vector3 = seg["end"]
    var ab: Vector3 = b - a
    var len_sq: float = ab.length_squared()
    if len_sq < 0.0001:
        return pos.distance_to(a)
    var t: float = clamp((pos - a).dot(ab) / len_sq, 0.0, 1.0)
    var closest: Vector3 = a + ab * t
    return pos.distance_to(closest)

# Liang-Barsky segment-rectangle intersection test.
# Used by get_roads_through_cell. Returns true if segment [a,b] passes
# through rectangle [min_x,max_x] × [min_z,max_z].
static func _segment_intersects_rect(
    a: Vector3, b: Vector3,
    min_x: float, max_x: float,
    min_z: float, max_z: float
) -> bool:
    var dx: float = b.x - a.x
    var dz: float = b.z - a.z
    var t_min: float = 0.0
    var t_max: float = 1.0
    if abs(dx) < 0.0001:
        if a.x < min_x or a.x > max_x:
            return false
    else:
        var t1: float = (min_x - a.x) / dx
        var t2: float = (max_x - a.x) / dx
        if t1 > t2:
            var tmp: float = t1; t1 = t2; t2 = tmp
        t_min = max(t_min, t1)
        t_max = min(t_max, t2)
        if t_min > t_max:
            return false
    if abs(dz) < 0.0001:
        if a.z < min_z or a.z > max_z:
            return false
    else:
        var t1: float = (min_z - a.z) / dz
        var t2: float = (max_z - a.z) / dz
        if t1 > t2:
            var tmp: float = t1; t1 = t2; t2 = tmp
        t_min = max(t_min, t1)
        t_max = min(t_max, t2)
        if t_min > t_max:
            return false
    return true
