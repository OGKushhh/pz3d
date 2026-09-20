# ChunkPlanner — pure function that decides WHAT goes WHERE in a chunk.
#
# Phase F.0 Refactor 2: Separates planning from rendering.
# This function produces a Dictionary (the "plan") that describes every
# placement in a chunk. It does NOT create any nodes, scenes, or meshes.
#
# The plan can be:
#	- Evaluated by PlanMetrics (for optimization loops)
#	- Rendered by ChunkRenderer (creates actual nodes)
#	- Cached, compared, serialized
#
# Plan schema:
# {
#	cx, cz, biome, style_hash,
#	origin: Vector3,
#	roads: [{start, end, width, kind}],
#	sidewalks: [{start, end, width}],
#	paths: [{center, width, length, yaw}],
#	poi_exclusions: [{center, radius}],
#	lots: [{center, front_dir, parcel_id, road_edge_pos, road_distance}],
#	buildings: [{pos, rot_y, asset_name, parcel_id, is_landmark, is_lot}],
#	foliage: [{pos, rot_y, asset_name, scale}],
#	props: [{pos, rot_y, asset_name}],
#	landmarks: [{pos, asset_name}],
#	pois: [{pos, asset_name, radius}],
#	rejections: [{what, reason, pos}],
#	stats: {buildings, foliage, props, landmarks, rejections}
# }

class_name ChunkPlanner
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")
const CityGenConfig = preload("res://tools/city_gen_config.gd")
const BlockLayout = preload("res://tools/block_layout.gd")
const PlacementValidator = preload("res://tools/placement_validator.gd")

# Plan a chunk. Pure function — no nodes, no scenes, no add_child.
# Args:
#	col, row: chunk coordinates
#	config: CityGenConfig instance (seed, multipliers, etc.)
#	roads: RoadNetwork (already loaded)
#	spatial: SpatialIndex (for overlap checks)
#	path_query: PathQuery (for path collision checks)
#	city_plan: Dictionary (density gradient from city_plan.json)
#	map_data: Dictionary (POIs, river, etc.)
#	manifest: Dictionary (asset manifest)
# Returns: Dictionary (the plan)
static func plan_chunk(
		col: int, row: int,
		config: CityGenConfig,
		roads, spatial, path_query,
		city_plan: Dictionary, map_data: Dictionary
) -> Dictionary:
		var origin := Vector3(col * CityConfig.CHUNK_SIZE_M, 0, row * CityConfig.CHUNK_SIZE_M)
		var grid_col: int = clamp(int(col * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
		var grid_row: int = clamp(int(row * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
		var biome: int = CityConfig.grid_layout()[grid_row][grid_col]

		var plan: Dictionary = {
				"cx": col, "cz": row, "biome": biome,
				"origin": origin,
				"roads": [], "sidewalks": [], "paths": [],
				"poi_exclusions": [],
				"lots": [], "buildings": [], "foliage": [], "props": [],
				"landmarks": [], "pois": [],
				"rejections": [],
				"stats": {"buildings": 0, "foliage": 0, "props": 0, "landmarks": 0, "rejections": 0},
		}

		if biome == CityConfig.Biome.WATER or biome == CityConfig.Biome.EMPTY:
				return plan

		var profile: Dictionary = CityConfig.biomes().get(biome, {})
		if profile.is_empty():
				return plan

		# Per-chunk RNG
		var crng := RandomNumberGenerator.new()
		crng.seed = config.seed + col * 1000 + row

		# === POIs ===
		var poi_exclusions: Array = []
		for poi in map_data.get("pois", []):
				var poi_pos_arr: Array = poi.get("pos", [0, 0, 0])
				var poi_pos := Vector3(float(poi_pos_arr[0]), 0, float(poi_pos_arr[2]))
				if poi_pos.x < origin.x or poi_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
						continue
				if poi_pos.z < origin.z or poi_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
						continue
				var poi_asset: String = poi.get("type", "")
				var poi_radius: float = float(poi.get("radius", 30))
				# Nudge POI off road
				poi_pos = _nudge_off_road(poi_pos, poi_radius, roads)
				plan["pois"].append({"pos": poi_pos, "asset_name": poi_asset, "radius": poi_radius})
				spatial.insert(poi_pos, poi_radius)
				poi_exclusions.append({"center": poi_pos, "radius": poi_radius})

		# === District template ===
		var template_name: String = ""
		var anchor_pos := origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5)
		# Template selection is handled by the renderer (it needs streamer for _get_asset)
		# Planner just records the anchor + template name for the renderer
		# (We can't call stamper.pick_template_for_biome here because it needs the stamper instance)
		# For now, leave template selection to the renderer.
		plan["template_anchor"] = anchor_pos
		plan["template_rot"] = crng.randf_range(0, TAU)

		# === Parcels ===
		var layout_type: String = BlockLayout.layout_for_biome(biome)
		var parcels: Array = BlockLayout.generate_parcels(layout_type, origin, CityConfig.CHUNK_SIZE_M)
		for parcel in parcels:
				var info: Dictionary = roads.nearest_road_info(parcel.building_pos)
				if info.get("found", false):
						parcel.road_edge_pos = info["point"]
						parcel.road_distance = info["distance"]
						parcel.road_dir = info["direction"]
						var to_road: Vector3 = info["point"] - parcel.building_pos
						if to_road.length() > 0.1:
								parcel.front_dir = to_road.normalized()
				plan["lots"].append({
						"center": parcel.building_pos,
						"front_dir": parcel.front_dir,
						"parcel_id": parcel.parcel_id,
						"road_edge_pos": parcel.road_edge_pos if info.get("found", false) else Vector3.ZERO,
						"road_distance": parcel.road_distance if info.get("found", false) else 0.0,
				})

		# === Interior paths ===
		var paths: Array = BlockLayout.get_interior_paths(layout_type, origin, CityConfig.CHUNK_SIZE_M)
		for path in paths:
				var p_center := Vector3((path["start"].x + path["end"].x) * 0.5, CityGenConfig.Y_PATH, (path["start"].z + path["end"].z) * 0.5)
				var p_len: float = path["start"].distance_to(path["end"])
				var p_width: float = float(path.get("width", 3.0))
				var p_yaw: float = atan2(path["end"].x - path["start"].x, path["end"].z - path["start"].z)
				plan["paths"].append({"center": p_center, "width": p_width, "length": p_len, "yaw": p_yaw})
				# Register in path_query for collision checks
				path_query.register_segment(path["start"], path["end"], p_width, "Path")

		# === Buildings (plan only — no instantiation) ===
		var fill: float = _get_density_for_cell(grid_col, grid_row, profile, city_plan)
		var biome_mult: int = config.get_density_mult(biome)
		var target: int = int(fill * biome_mult)
		var building_radius: float = config.get_building_radius()
		var placed := 0

		# Track per-type counts for anti-repetition (applies to BOTH lot recipes + procedural)
		var type_counts: Dictionary = {}

		# Load lot recipes for this biome
		var LotRecipes := preload("res://tools/lot.gd")
		var lot_names: Array = LotRecipes.BIOME_LOTS.get(biome, [])
		var buildings_pool: Array = profile.get("buildings", [])

		for parcel in parcels:
				if placed >= target:
						break
				var lot_pos: Vector3 = parcel.building_pos
				if lot_pos.x < origin.x or lot_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
						continue
				if lot_pos.z < origin.z or lot_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
						continue
				if not spatial.is_free(lot_pos, building_radius):
						plan["rejections"].append({"what": "building", "reason": "not_free", "pos": lot_pos})
						continue
				if spatial.is_on_road(lot_pos):
						plan["rejections"].append({"what": "building", "reason": "on_road", "pos": lot_pos})
						continue
				if _is_in_poi_exclusion(lot_pos, poi_exclusions):
						plan["rejections"].append({"what": "building", "reason": "poi_exclusion", "pos": lot_pos})
						continue
				if _is_near_highway(lot_pos, roads):
						plan["rejections"].append({"what": "building", "reason": "near_highway", "pos": lot_pos})
						continue

				# Try lot recipe first (if biome has recipes)
				if not lot_names.is_empty() and crng.randf() <= fill:
						# Anti-repetition: pick a lot recipe that hasn't been overused
						var lot_name: String = ""
						for _attempt in range(3):
								var candidate_lot: String = lot_names[crng.randi() % lot_names.size()]
								var lot_count: int = int(type_counts.get(candidate_lot, 0))
								if lot_count < 3:  # max 3 of same lot recipe per chunk
										lot_name = candidate_lot
										break
						if lot_name == "":
								# All lot recipes overused — fall through to procedural
								pass
						else:
								plan["buildings"].append({
										"pos": lot_pos,
										"rot_y": 0.0,
										"asset_name": lot_name,
										"parcel_id": parcel.parcel_id,
										"is_landmark": false,
										"is_lot": true,
								})
								spatial.insert(lot_pos, building_radius)
								type_counts[lot_name] = int(type_counts.get(lot_name, 0)) + 1
								placed += 1
								plan["stats"]["buildings"] += 1
								continue

				# Empty lot check
				if crng.randf() > fill:
						continue

				# Procedural fallback: pick building from profile with anti-repetition
				if buildings_pool.is_empty():
						continue

				# Anti-repetition: try 3 picks, max 3 of same type per chunk
				var bname: String = ""
				for _attempt in range(3):
						var candidate: String = buildings_pool[crng.randi() % buildings_pool.size()]
						var type_count: int = int(type_counts.get(candidate, 0))
						if type_count < 3:	# max 3 of same building type per chunk (was 5)
								bname = candidate
								break
				if bname == "":
						plan["rejections"].append({"what": "building", "reason": "repetition_limit", "pos": lot_pos})
						continue

				plan["buildings"].append({
						"pos": lot_pos,
						"rot_y": 0.0,
						"asset_name": bname,
						"parcel_id": parcel.parcel_id,
						"is_landmark": false,
						"is_lot": false,
				})
				spatial.insert(lot_pos, building_radius)
				type_counts[bname] = int(type_counts.get(bname, 0)) + 1
				placed += 1
				plan["stats"]["buildings"] += 1

		# === Foliage (plan only) ===
		var foliage: Array = profile.get("foliage", [])
		if not foliage.is_empty():
				var foliage_mult: int = config.get_foliage_mult(biome)
				var green_count: int = int(fill * foliage_mult)
				for i in range(green_count):
						var pos := Vector3(
								origin.x + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0),
								0,
								origin.z + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0)
						)
						if not spatial.is_free(pos, 3.0) or spatial.is_on_road(pos):
								continue
						if _is_in_poi_exclusion(pos, poi_exclusions):
								continue
						if path_query.is_on_path(pos, 2.0):
								continue
						var fname: String = foliage[crng.randi() % foliage.size()]
						var tree_scale: float = crng.randf_range(0.8, 1.3)
						plan["foliage"].append({"pos": pos, "rot_y": crng.randf_range(0, TAU), "asset_name": fname, "scale": tree_scale})
						spatial.insert(pos, 3.0)
						plan["stats"]["foliage"] += 1

		# === Props / gap fillers (plan only) ===
		var gap_fillers: Array = config.get_gap_fillers(biome)
		if not gap_fillers.is_empty():
				var gap_count: int = int(fill * 40)
				for i in range(gap_count):
						var pos := Vector3(
								origin.x + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 15.0),
								0,
								origin.z + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 5.0)
						)
						if not spatial.is_free(pos, 2.0) or spatial.is_on_road(pos):
								continue
						if _is_in_poi_exclusion(pos, poi_exclusions):
								continue
						if path_query.is_on_path(pos, 1.0):
								continue
						var fname: String = gap_fillers[crng.randi() % gap_fillers.size()]
						plan["props"].append({"pos": pos, "rot_y": crng.randf_range(0, TAU), "asset_name": fname})
						spatial.insert(pos, 2.0)
						plan["stats"]["props"] += 1

		plan["poi_exclusions"] = poi_exclusions
		plan["stats"]["rejections"] = plan["rejections"].size()
		return plan

# === Helpers ===

static func _get_density_for_cell(col: int, row: int, profile: Dictionary, city_plan: Dictionary) -> float:
		if city_plan.is_empty():
				return float(profile.get("fill", 0.5))
		var gradient: Dictionary = city_plan.get("density_gradient", {})
		var grid: Array = gradient.get("grid", [])
		if row >= 0 and row < grid.size() and col >= 0 and col < grid[row].size():
				return float(grid[row][col])
		return float(profile.get("fill", 0.5))

static func _is_in_poi_exclusion(pos: Vector3, exclusions: Array) -> bool:
		for ex in exclusions:
				var center: Vector3 = ex["center"]
				var radius: float = float(ex["radius"])
				if pos.distance_to(center) < radius:
						return true
		return false

static func _is_near_highway(pos: Vector3, roads) -> bool:
		for seg in roads.segments:
				if seg.get("kind", "street") != "highway":
						continue
				var d: float = roads.distance_to_road_centerline(pos, seg)
				if d < CityGenConfig.HIGHWAY_CLEARANCE_M:
						return true
		return false

static func _nudge_off_road(pos: Vector3, poi_radius: float, roads) -> Vector3:
		var info: Dictionary = roads.nearest_road_info(pos)
		if not info.get("found", false):
				return pos
		var road_dist: float = float(info.get("distance", 0.0))
		var road_point: Vector3 = info.get("point", pos)
		var road_dir: Vector3 = info.get("direction", Vector3.FORWARD)
		var road_half_w: float = 6.0
		var safe_dist: float = road_half_w + poi_radius + 5.0
		if road_dist >= safe_dist:
				return pos
		var nudge_amount: float = safe_dist - road_dist
		var away_dir: Vector3 = (pos - road_point).normalized()
		if away_dir.length() < 0.01:
				away_dir = Vector3(-road_dir.z, 0, road_dir.x).normalized()
		return pos + away_dir * nudge_amount
