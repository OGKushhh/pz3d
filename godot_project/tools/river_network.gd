# RiverNetwork — generates river centerline + provides distance/depth queries.
#
# The river runs vertically through grid column 4 (the single RIVER column
# after Phase A.2 redesign). Bridges cross it at the rows defined in
# CityConfig.bridges().
#
# The centerline is a vertical line at X = river_center_x.
# distance_to(x, z) returns the horizontal distance to this line.
# water_depth_at(x, z) returns water depth (0 on land, >0 over river).
#
# See GDD §12.4 (River = -4m carved valley, water at Y=0).
class_name RiverNetwork
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

var _center_x: float
var _bridges: Array = []

func _init() -> void:
	# River is in grid column 4 (0-indexed).
	# Each cell is CELL_SIZE_M = 500m wide.
	# River center = col 4 center = (4 * 500) + 250 = 2250m
	_center_x = 4.0 * 500.0 + 500.0 / 2.0
	_bridges = CFG.bridges()

# Horizontal distance from (x, z) to the river centerline.
# Since the river is a vertical line, distance = |x - center_x|.
func distance_to(x: float, z: float) -> float:
	return abs(x - _center_x)

# Water depth at (x, z). Returns 0 on land, positive over river.
# Uses the same quadratic falloff as TerrainHeight's carve.
func water_depth_at(x: float, z: float) -> float:
	var d := distance_to(x, z)
	if d > 30.0:  # RIVER_HALF_WIDTH
		return 0.0
	var t := d / 30.0
	return 4.0 * (1.0 - t * t)  # 4m deep at center, 0 at edge

# Returns true if (x, z) is over the river (within RIVER_HALF_WIDTH).
func is_over_river(x: float, z: float) -> bool:
	return distance_to(x, z) < 30.0

# Returns bridge data if (x, z) is near a bridge, else null.
# A bridge spans from_col to to_col at a given row.
func bridge_at(x: float, z: float) -> Variant:
	for bridge in _bridges:
		var row: int = bridge["row"]
		var from_col: int = bridge["from_col"]
		var to_col: int = bridge["to_col"]
		# Bridge Z = row * CELL_SIZE_M + CELL_SIZE_M/2
		var bridge_z: float = float(row) * 500.0 + 250.0
		# Bridge spans from_col to to_col in X
		var bridge_x_min: float = float(from_col) * 500.0
		var bridge_x_max: float = float(to_col + 1) * 500.0
		# Check if within 50m of bridge centerline (in Z)
		if abs(z - bridge_z) < 50.0 and x >= bridge_x_min and x <= bridge_x_max:
			return bridge
	return null

func get_center_x() -> float:
	return _center_x

func get_bridges() -> Array:
	return _bridges
