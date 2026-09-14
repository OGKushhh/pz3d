# PathQuery — spatial index for path segments (sidewalks + driveways + interior paths).
#
# Phase B.7.5 (2026-09-14): Collects all drawn path segments during chunk build
# and provides fast is_on_path(pos, margin) queries. Used by the gap filler
# and foliage loops in chunk_streamer.gd to skip placements that would land
# on a path (the "props standing in middle of paths" bug from the 2026-09-14
# screenshot review).
#
# Architecture:
#   - register_segment(start, end, width) — called by LotStamper + chunk_streamer
#     every time a sidewalk/driveway/interior-path strip is drawn
#   - is_on_path(pos, margin) — returns true if pos is within margin meters
#     of any registered path segment
#   - clear() — called at the start of each chunk build (paths are per-chunk)
#
# The query uses point-to-segment distance (same formula as road_network.gd:149).
# For performance, segments are bucketed by a coarse spatial grid (cell size = 50m)
# so only nearby segments are checked. With ~20 lots per chunk × 2 strips each
# = ~40 segments per chunk, the grid is barely needed — but it future-proofs
# against larger chunk sizes or denser lots.
class_name PathQuery
extends RefCounted

# Grid cell size for spatial bucketing. 50m means a query checks at most the
# 9 cells (3x3 neighborhood) around the query point. Each cell has ~1-2 segments.
const CELL_SIZE := 50.0

# All registered path segments: Array of {start: Vector3, end: Vector3, width: float, type: String}
var _segments: Array = []

# Spatial grid: maps cell key (String "cx_cz") to Array of segment indices
var _grid: Dictionary = {}

# Register a path segment. Call this every time a sidewalk/driveway/interior-path
# is drawn (in LotStamper._draw_strip_world + chunk_streamer's interior path loop).
func register_segment(start: Vector3, end: Vector3, width: float, type: String = "path") -> void:
	var idx: int = _segments.size()
	_segments.append({"start": start, "end": end, "width": width, "type": type})
	# Insert into all grid cells the segment touches (AABB of the segment)
	var min_x: float = minf(start.x, end.x) - width * 0.5
	var max_x: float = maxf(start.x, end.x) + width * 0.5
	var min_z: float = minf(start.z, end.z) - width * 0.5
	var max_z: float = maxf(start.z, end.z) + width * 0.5
	var cx_min: int = int(min_x / CELL_SIZE)
	var cx_max: int = int(max_x / CELL_SIZE)
	var cz_min: int = int(min_z / CELL_SIZE)
	var cz_max: int = int(max_z / CELL_SIZE)
	for cx in range(cx_min, cx_max + 1):
		for cz in range(cz_min, cz_max + 1):
			var key: String = "%d_%d" % [cx, cz]
			if not _grid.has(key):
				_grid[key] = []
			_grid[key].append(idx)

# Returns true if pos is within `margin` meters of any registered path segment.
# Checks only the 3x3 grid neighborhood around pos for performance.
func is_on_path(pos: Vector3, margin: float = 2.0) -> bool:
	var cx: int = int(pos.x / CELL_SIZE)
	var cz: int = int(pos.z / CELL_SIZE)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var key: String = "%d_%d" % [cx + dx, cz + dz]
			if not _grid.has(key):
				continue
			for idx in _grid[key]:
				if idx >= _segments.size():
					continue
				var seg: Dictionary = _segments[idx]
				var d: float = _point_segment_distance(pos, seg["start"], seg["end"])
				# If within the path's half-width + margin, it's on the path
				if d < seg["width"] * 0.5 + margin:
					return true
	return false

# Returns the nearest path segment info to pos, or empty dict if none within radius.
func nearest_path(pos: Vector3, max_radius: float = 50.0) -> Dictionary:
	var best_d: float = max_radius
	var best_seg: Dictionary = {}
	var cx: int = int(pos.x / CELL_SIZE)
	var cz: int = int(pos.z / CELL_SIZE)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var key: String = "%d_%d" % [cx + dx, cz + dz]
			if not _grid.has(key):
				continue
			for idx in _grid[key]:
				if idx >= _segments.size():
					continue
				var seg: Dictionary = _segments[idx]
				var d: float = _point_segment_distance(pos, seg["start"], seg["end"])
				if d < best_d:
					best_d = d
					best_seg = seg
	return best_seg

# Clear all registered segments. Call at the start of each chunk build.
func clear() -> void:
	_segments.clear()
	_grid.clear()

# Returns the total number of registered segments (for debugging).
func segment_count() -> int:
	return _segments.size()

# Point-to-segment distance (same formula as road_network.gd:149 + spatial_index.gd).
static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	if ab.length_squared() < 0.001:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
