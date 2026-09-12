# AnchorPoints — defines one anchor per grid cell (48 total for 8×6 grid).
#
# Phase A.6 (2026-09-13): Anchor points are the "nodes" of the city graph.
# Each anchor sits at a cell CENTER (not corner) and carries metadata about
# the district at that location. Used by:
#   - Phase A.7: hand-authored district templates stamp at anchor positions
#   - Phase A.8: zoning rules per anchor (residential / commercial / etc.)
#   - Phase A.9: district halo — landmarks influence neighbor anchor picks
#   - Phase A.10: intersection variation at major anchors
#   - Phase A.11: bridge visuals at anchors near the river
#
# Anchors are CONCEPTUAL — they're not rendered as visible nodes (yet).
# They're a metadata layer that future systems query for placement decisions.
#
# Anchor positions vs road positions: anchors sit at cell centers
# (col * 500 + 250, 0, row * 500 + 250). Roads sit at cell BORDERS
# (col * 500, 0, row * 500). This is intentional — roads separate cells,
# anchors sit inside cells. A road at z=500 separates row 0 (center z=250)
# from row 1 (center z=750).
class_name AnchorPoints
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

# Returns an Array of 48 anchor Dictionaries, one per grid cell.
# Each anchor: {
#   "cell": Vector2i(col, row),
#   "position": Vector3(x, 0, z),
#   "biome": int,
#   "district_name": String,
#   "is_major": bool,
#   "landmark": String (empty if no landmark at this cell)
# }
static func get_anchors() -> Array:
	var anchors: Array = []
	var grid: Array = CFG.grid_layout()
	var landmarks := _get_landmark_overrides()
	for row in range(CFG.GRID_ROWS):
		for col in range(CFG.GRID_COLS):
			var biome: int = grid[row][col]
			var pos := Vector3(
				float(col) * CFG.CELL_SIZE_M + CFG.CELL_SIZE_M * 0.5,
				0.0,
				float(row) * CFG.CELL_SIZE_M + CFG.CELL_SIZE_M * 0.5
			)
			var cell := Vector2i(col, row)
			var landmark: String = landmarks.get(cell, "")
			var is_major: bool = landmark != "" or _is_major_biome(biome)
			anchors.append({
				"cell": cell,
				"position": pos,
				"biome": biome,
				"district_name": CFG.district_name_for(biome),
				"is_major": is_major,
				"landmark": landmark
			})
	return anchors

# Returns anchors that are "major" — either contain a landmark POI or sit in
# a major biome (Downtown, Commercial, Industrial, Military). These get extra
# weight in district halo + template stamping.
static func get_major_anchors() -> Array:
	var major: Array = []
	for anchor in get_anchors():
		if anchor["is_major"]:
			major.append(anchor)
	return major

# Returns the anchor at a specific grid cell, or null if out of bounds.
static func get_anchor_at(cell: Vector2i) -> Variant:
	if cell.x < 0 or cell.y < 0 or cell.x >= CFG.GRID_COLS or cell.y >= CFG.GRID_ROWS:
		return null
	for anchor in get_anchors():
		if anchor["cell"] == cell:
			return anchor
	return null

# Returns the anchor nearest to a world position. Used by gameplay code to
# answer "which district am I in right now?". O(48) linear scan — cheap.
static func get_nearest_anchor(world_pos: Vector3) -> Variant:
	var best: Variant = null
	var best_dist: float = INF
	for anchor in get_anchors():
		var ap: Vector3 = anchor["position"]
		var d: float = world_pos.distance_to(Vector3(ap.x, world_pos.y, ap.z))
		if d < best_dist:
			best_dist = d
			best = anchor
	return best

# Reads POI positions from map_data.json and converts them to cell coordinates.
# Returns Dictionary[Vector2i cell → String landmark_type]. Used to mark
# anchor cells that contain a known landmark (stadium, fort_sarran, etc.).
static func _get_landmark_overrides() -> Dictionary:
	var f := FileAccess.open("res://data/map_data.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null or not (parsed is Dictionary):
		return {}
	var md: Dictionary = parsed
	var result: Dictionary = {}
	for poi in md.get("pois", []):
		var pos_arr: Array = poi.get("pos", [])
		if pos_arr.size() < 3:
			continue
		var col: int = int(float(pos_arr[0]) / CFG.CELL_SIZE_M)
		var row: int = int(float(pos_arr[2]) / CFG.CELL_SIZE_M)
		result[Vector2i(col, row)] = String(poi.get("type", ""))
	return result

# Major biomes: those with civic/commercial/strategic significance.
# Anchors in these biomes are marked is_major=true even without a landmark POI.
# Used to bias road generation (major-major connections become arterials) and
# district halo (major anchors influence neighbor chunk picks).
static func _is_major_biome(biome: int) -> bool:
	return biome == CFG.Biome.DOWNTOWN \
		or biome == CFG.Biome.COMMERCIAL \
		or biome == CFG.Biome.INDUSTRIAL \
		or biome == CFG.Biome.MILITARY
