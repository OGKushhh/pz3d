class_name SpatialIndex
# O(1) spatial occupancy grid. Supports both circle (radius) and AABB (box) queries.
# Circle queries used for props/foliage. AABB queries used for buildings (Phase G.3).
extends RefCounted

var _occupied: Dictionary = {}  # Vector2i → Array[Dictionary{pos, radius, half_extents}]
var _road: Dictionary = {}
var cell_size: float

func _init(cell_m: float = 8.0) -> void:
	cell_size = cell_m

func _key(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / cell_size)), int(floor(pos.z / cell_size)))

# Circle-based overlap check (for props, foliage, small objects)
func is_free(pos: Vector3, radius: float) -> bool:
	var r := int(ceil(radius / cell_size))
	var c := _key(pos)
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var k := c + Vector2i(dx, dz)
			if not _occupied.has(k):
				continue
			for o in _occupied[k]:
				if o.has("half_extents"):
					# AABB check
					if _aabb_overlaps(pos, radius, o):
						return false
				else:
					# Circle check
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

# Phase G.3: Insert a box (AABB) for buildings.
# Converts oriented bounding box to world-space AABB.
# center = building center, size = (width, depth) in meters, rot_y = yaw in radians.
func insert_box(center: Vector3, size: Vector2, rot_y: float) -> void:
	# For axis-aligned buildings (rot_y = 0, 90, 180, 270), the AABB = the box itself.
	# For arbitrary rotations, compute the extent of the rotated box.
	var abs_cos: float = abs(cos(rot_y))
	var abs_sin: float = abs(sin(rot_y))
	var half_w: float = size.x * 0.5
	var half_d: float = size.y * 0.5
	# AABB half-extents of the rotated box
	var aabb_half_w: float = half_w * abs_cos + half_d * abs_sin
	var aabb_half_d: float = half_w * abs_sin + half_d * abs_cos
	# Use the larger of the two as the radius for the cell grid
	var radius: float = max(aabb_half_w, aabb_half_d)
	var r := int(ceil(radius / cell_size))
	var c := _key(center)
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var k := c + Vector2i(dx, dz)
			if not _occupied.has(k):
				_occupied[k] = []
			_occupied[k].append({
				"pos": center,
				"radius": radius,
				"half_extents": Vector2(aabb_half_w, aabb_half_d)
			})

# AABB overlap test
func _aabb_overlaps(pos: Vector3, radius: float, other: Dictionary) -> bool:
	var other_pos: Vector3 = other["pos"]
	var other_half: Vector2 = other["half_extents"]
	# Expand other's AABB by radius
	var dx: float = abs(pos.x - other_pos.x)
	var dz: float = abs(pos.z - other_pos.z)
	return dx < (other_half.x + radius) and dz < (other_half.y + radius)

func mark_road(pos: Vector3, half_width: float) -> void:
	var r := int(ceil(half_width / cell_size))
	var c := _key(pos)
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			_road[c + Vector2i(dx, dz)] = true

func is_on_road(pos: Vector3) -> bool:
	return _road.has(_key(pos))

func is_road_clear(pos: Vector3) -> bool:
	push_warning("SpatialIndex.is_road_clear() is deprecated — use is_on_road() instead.")
	return not _road.has(_key(pos))

func clear() -> void:
	_occupied.clear()
	_road.clear()
