# RiverNetwork — spline-based river feature (Phase A.4 — "River-as-feature").
#
# REFACTOR (2026-09-13): River is no longer a Biome (Biome.RIVER removed
# from enum, same precedent as Biome.SUBWAY removal in Phase A.3). It is
# now a polyline feature stored in map_data.json:
#   "river": {
#     "control_points": [[x, z], ...],
#     "half_width": 30.0,
#     "depth": 4.0,
#     "water_level": 0.0
#   }
#
# The river can curve through any surface biome (FOREST in the north,
# FARMLAND in the middle, COMMERCIAL/SUBURBIA in the south). The biome
# underneath any given river point is whatever the district grid says at
# that location.
#
# Bridges are still declared in row/col format in CityConfig.bridges() and
# rendered as horizontal road segments. They cross the river wherever the
# polyline happens to be at that row's Z. The polyline is designed so its
# X at the bridge Z values falls within the bridge's X extent.
#
# TerrainHeight queries this class for the river carve (the -4m valley
# that holds the water). The biome elevation table no longer has a RIVER
# entry — the carve is layered on top of whatever biome elevation exists
# at (x, z), which is exactly what we want: a river in the FOREST will
# have forest banks at +2m, and the riverbed drops to -2m at center
# (forest base 2m + carve -4m = -2m). A river in FARMLAND has banks at
# +0.2m and riverbed at -3.8m. Each biome's river looks slightly different.
class_name RiverNetwork
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

# River geometry — populated from map_data.json at runtime.
var _control_points: Array = []  # Array[Vector2] in XZ plane (world space)
var _half_width: float = 30.0
var _depth: float = 4.0
var _water_level: float = 0.0
var _bridges: Array = []

# Backwards-compat: get_center_x() now returns the average X of all
# control points (used by tests). New code should sample specific Z values
# via get_river_x_at(z) instead.
func _init() -> void:
        _load_from_map_data()
        _bridges = CFG.bridges()

# Load river geometry from map_data.json. Falls back to a default vertical
# line at X=2250 if map_data.json is missing or malformed (so tests don't
# require the data file).
func _load_from_map_data() -> void:
        var f := FileAccess.open("res://data/map_data.json", FileAccess.READ)
        if f == null:
                _control_points = [Vector2(2250, 0), Vector2(2250, 3000)]
                return
        var parsed: Dictionary = JSON.parse_string(f.get_as_text()) as Dictionary
        if parsed.is_empty():
                _control_points = [Vector2(2250, 0), Vector2(2250, 3000)]
                return
        var river: Dictionary = parsed.get("river", {})
        _half_width = float(river.get("half_width", 30.0))
        _depth = float(river.get("depth", 4.0))
        _water_level = float(river.get("water_level", 0.0))
        var cps: Array = river.get("control_points", [])
        _control_points.clear()
        for cp in cps:
                var arr: Array = cp
                _control_points.append(Vector2(float(arr[0]), float(arr[1])))
        if _control_points.size() < 2:
                _control_points = [Vector2(2250, 0), Vector2(2250, 3000)]

# Returns the minimum horizontal distance from (x, z) to any segment of
# the river polyline. Used by TerrainHeight for the river carve falloff.
func distance_to(x: float, z: float) -> float:
        if _control_points.size() < 2:
                return INF
        var p := Vector2(x, z)
        var best: float = INF
        for i in range(_control_points.size() - 1):
                var a: Vector2 = _control_points[i]
                var b: Vector2 = _control_points[i + 1]
                var d: float = _point_segment_distance(p, a, b)
                if d < best:
                        best = d
        return best

# Returns the river's X coordinate at a given Z. Linear interpolation
# between the two nearest control points. Used by tests + by bridge
# placement verification.
func get_river_x_at(z: float) -> float:
        if _control_points.size() < 2:
                return 2250.0
        # Find the segment containing z (or the nearest endpoint).
        for i in range(_control_points.size() - 1):
                var a: Vector2 = _control_points[i]
                var b: Vector2 = _control_points[i + 1]
                # Skip segments where z is outside [a.y, b.y] range (either direction).
                var z_min: float = min(a.y, b.y)
                var z_max: float = max(a.y, b.y)
                if z < z_min or z > z_max:
                        continue
                # Linear interp: t = (z - a.y) / (b.y - a.y)
                var dy: float = b.y - a.y
                if abs(dy) < 0.001:
                        return a.x
                var t: float = (z - a.y) / dy
                return lerpf(a.x, b.x, t)
        # z outside the polyline's range — clamp to nearest endpoint.
        if z <= _control_points[0].y:
                return _control_points[0].x
        return _control_points[_control_points.size() - 1].x

# Water depth at (x, z). 0 on land, >0 over river.
# Quadratic falloff: depth at centerline = _depth, 0 at _half_width edge.
func water_depth_at(x: float, z: float) -> float:
        var d: float = distance_to(x, z)
        if d > _half_width:
                return 0.0
        var t: float = d / _half_width
        return _depth * (1.0 - t * t)

# Returns true if (x, z) is over the river (within _half_width).
func is_over_river(x: float, z: float) -> bool:
        return distance_to(x, z) < _half_width

# Returns bridge data if (x, z) is near a bridge, else null.
# A bridge spans from_col*500 to (to_col+1)*500 in X, at Z = row*500 + 250.
# The bridge's centerline is at that Z, with ±50m tolerance.
func bridge_at(x: float, z: float) -> Variant:
        for bridge in _bridges:
                var row: int = bridge["row"]
                var from_col: int = bridge["from_col"]
                var to_col: int = bridge["to_col"]
                var bridge_z: float = float(row) * 500.0 + 250.0
                var bridge_x_min: float = float(from_col) * 500.0
                var bridge_x_max: float = float(to_col + 1) * 500.0
                if abs(z - bridge_z) < 50.0 and x >= bridge_x_min and x <= bridge_x_max:
                        return bridge
        return null

# ── ACCESSORS ───────────────────────────────────────────────
func get_control_points() -> Array:
        return _control_points

func get_half_width() -> float:
        return _half_width

func get_depth() -> float:
        return _depth

func get_water_level() -> float:
        return _water_level

func get_bridges() -> Array:
        return _bridges

# Backwards-compat: returns the average X of all control points.
# Deprecated — prefer get_river_x_at(z) for position-specific queries.
func get_center_x() -> float:
        if _control_points.is_empty():
                return 2250.0
        var sum: float = 0.0
        for cp in _control_points:
                sum += cp.x
        return sum / float(_control_points.size())

# ── HELPERS ─────────────────────────────────────────────────
# Shortest distance from point p to segment [a, b]. Standard formula:
# t = clamp((p-a)·(b-a)/|b-a|², 0, 1); return |p - (a + t(b-a))|.
static func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
        var ab: Vector2 = b - a
        var len_sq: float = ab.length_squared()
        if len_sq < 0.0001:
                return p.distance_to(a)
        var t: float = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
        var closest: Vector2 = a + ab * t
        return p.distance_to(closest)
