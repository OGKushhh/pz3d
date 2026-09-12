# Run: godot --headless --script res://tests/test_anchor_points.gd
# Exit 0 = pass, 1 = fail.
# Tests Phase A.6 anchor points system + road graph helpers.
extends SceneTree

const AnchorPoints := preload("res://tools/anchor_points.gd")
const CityConfig := preload("res://tools/city_config.gd")
const RoadNetwork := preload("res://tools/road_network.gd")

var failures: int = 0

func _init():
	# === Anchor points tests ===
	# Test 1: get_anchors() returns 48 anchors (8 cols × 6 rows)
	var anchors: Array = AnchorPoints.get_anchors()
	_check(anchors.size() == 48, "get_anchors returns 48 (got %d)" % anchors.size())

	# Test 2: each anchor has required fields
	for a in anchors:
		_check(a.has("cell"), "anchor has cell field")
		_check(a.has("position"), "anchor has position field")
		_check(a.has("biome"), "anchor has biome field")
		_check(a.has("district_name"), "anchor has district_name field")
		_check(a.has("is_major"), "anchor has is_major field")
		_check(a.has("landmark"), "anchor has landmark field")
		if failures > 0:
			break

	# Test 3: anchor at cell (0,0) is at world position (250, 0, 250)
	var a00: Variant = AnchorPoints.get_anchor_at(Vector2i(0, 0))
	_check(a00 != null, "anchor at (0,0) is not null")
	if a00 != null:
		var pos: Vector3 = a00["position"]
		_check(abs(pos.x - 250.0) < 0.1, "anchor (0,0) x ≈ 250 (got %.1f)" % pos.x)
		_check(abs(pos.z - 250.0) < 0.1, "anchor (0,0) z ≈ 250 (got %.1f)" % pos.z)

	# Test 4: anchor at cell (7,5) (SE corner) is at world (3750, 0, 2750)
	var a75: Variant = AnchorPoints.get_anchor_at(Vector2i(7, 5))
	_check(a75 != null, "anchor at (7,5) is not null")
	if a75 != null:
		var pos: Vector3 = a75["position"]
		_check(abs(pos.x - 3750.0) < 0.1, "anchor (7,5) x ≈ 3750 (got %.1f)" % pos.x)
		_check(abs(pos.z - 2750.0) < 0.1, "anchor (7,5) z ≈ 2750 (got %.1f)" % pos.z)

	# Test 5: get_anchor_at out of bounds returns null
	_check(AnchorPoints.get_anchor_at(Vector2i(-1, 0)) == null, "anchor at (-1,0) returns null")
	_check(AnchorPoints.get_anchor_at(Vector2i(8, 0)) == null, "anchor at (8,0) returns null (col out of bounds)")
	_check(AnchorPoints.get_anchor_at(Vector2i(0, 6)) == null, "anchor at (0,6) returns null (row out of bounds)")

	# Test 6: at least one anchor is marked is_major (Downtown, Commercial, Industrial, Military biomes)
	var major_count := 0
	for a in anchors:
		if a["is_major"]:
			major_count += 1
	_check(major_count > 0, "at least 1 major anchor (got %d)" % major_count)

	# Test 7: anchors with landmark POIs are marked is_major
	# Per map_data.json POIs: fort_sarran at (3500, 0, 2500) → cell (7, 5)
	#                        government_palace at (3000, 0, 1500) → cell (6, 3)
	#                        stadium at (3000, 0, 500) → cell (6, 1)
	#                        etc.
	var a_fort: Variant = AnchorPoints.get_anchor_at(Vector2i(7, 5))
	if a_fort != null:
		_check(a_fort["is_major"], "anchor at fort_sarran cell (7,5) is_major = true")
		_check(a_fort["landmark"] == "fort_sarran", "anchor at (7,5) landmark = 'fort_sarran' (got '%s')" % a_fort["landmark"])

	# Test 8: get_major_anchors returns subset of get_anchors
	var major_anchors: Array = AnchorPoints.get_major_anchors()
	_check(major_anchors.size() <= anchors.size(), "major_anchors ≤ total anchors")
	_check(major_anchors.size() == major_count, "major_anchors count matches (%d)" % major_anchors.size())

	# Test 9: get_nearest_anchor returns nearest anchor to a known position
	# Player at (2250, 5, 1500) is in cell (4, 3) (center at 2250, 1750)? Wait —
	# cell (4, 3) center is (4*500+250, 0, 3*500+250) = (2250, 0, 1750). But
	# player is at z=1500 which is on the border. Cell (4, 2) center is (2250, 0, 1250),
	# cell (4, 3) center is (2250, 0, 1750). z=1500 is between them.
	# distance to (4,2) = 250, to (4,3) = 250. Tie — pick either. So we just
	# check the result is one of these two cells.
	var nearest: Variant = AnchorPoints.get_nearest_anchor(Vector3(2250, 5, 1500))
	_check(nearest != null, "nearest anchor to (2250, 5, 1500) is not null")
	if nearest != null:
		var cell: Vector2i = nearest["cell"]
		_check(cell.x == 4, "nearest anchor col = 4 (got %d)" % cell.x)
		_check(cell.y == 2 or cell.y == 3, "nearest anchor row = 2 or 3 (got %d)" % cell.y)

	# === Road graph helpers tests ===
	var roads := RoadNetwork.new()
	# Load roads from map_data.json (same as chunk_streamer does)
	var f := FileAccess.open("res://data/map_data.json", FileAccess.READ)
	if f:
		var md: Dictionary = JSON.parse_string(f.get_as_text())
		for road in md.get("roads", []):
			var start_arr: Array = road["start"]
			var end_arr: Array = road["end"]
			roads._add_segment(
				Vector3(start_arr[0], 0, start_arr[2]),
				Vector3(end_arr[0], 0, end_arr[2]),
				float(road.get("width", 8.0)),
				road.get("kind", "street"),
				road.get("name", "")
			)

	# Test 10: get_roads_through_cell for cell (4, 3) returns at least 1 road
	# Cell (4, 3) spans x=[2000, 2500], z=[1500, 2000]. The horizontal highway at
	# z=1500 passes through this cell (it's on the cell's north border).
	var roads_through_43: Array = roads.get_roads_through_cell(Vector2i(4, 3))
	_check(roads_through_43.size() > 0, "cell (4,3) has roads passing through (got %d)" % roads_through_43.size())

	# Test 11: get_cells_for_road for the z=1500 highway returns cells along z=1500
	# The highway goes from (0,0,1500) to (4000,0,1500), passing through all 8 cells
	# at row 3 (cells (0,3), (1,3), ..., (7,3)).
	var highway_seg: Dictionary = {}
	for seg in roads.segments:
		if seg.get("kind", "") == "highway":
			var a: Vector3 = seg["start"]
			if abs(a.z - 1500.0) < 1.0:  # the z=1500 highway
				highway_seg = seg
				break
	_check(not highway_seg.is_empty(), "found z=1500 highway segment")
	if not highway_seg.is_empty():
		var cells: Array = roads.get_cells_for_road(highway_seg)
		_check(cells.size() >= 8, "z=1500 highway passes through ≥8 cells (got %d)" % cells.size())

	# Test 12: get_roads_of_kind("highway") returns 2 (z=1500 and x=1500)
	var highways: Array = roads.get_roads_of_kind("highway")
	_check(highways.size() == 2, "exactly 2 highways (got %d)" % highways.size())

	# Test 13: get_roads_of_kind("diagonal") returns 2 (Sarran Ave + Bayview Ave)
	var diagonals: Array = roads.get_roads_of_kind("diagonal")
	_check(diagonals.size() == 2, "exactly 2 diagonals (got %d)" % diagonals.size())

	# Test 14: get_roads_of_kind("bridge") returns 2 (Sarran Bridge + Old Town Bridge)
	var bridges: Array = roads.get_roads_of_kind("bridge")
	_check(bridges.size() == 2, "exactly 2 bridges (got %d)" % bridges.size())

	# Test 15: distance_to_road_centerline for a point ON a road = 0
	# Point (2000, 0, 1500) is on the z=1500 highway.
	if not highway_seg.is_empty():
		var d: float = roads.distance_to_road_centerline(Vector3(2000, 0, 1500), highway_seg)
		_check(d < 0.5, "distance to z=1500 highway at (2000, 0, 1500) ≈ 0 (got %.2f)" % d)

	# Test 16: distance_to_road_centerline for a point OFF the road > 0
	if not highway_seg.is_empty():
		var d: float = roads.distance_to_road_centerline(Vector3(2000, 0, 1600), highway_seg)
		_check(d > 50.0, "distance to z=1500 highway at (2000, 0, 1600) > 50m (got %.2f)" % d)

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("anchor_points: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("anchor_points: PASS")
		quit(0)
