# CityGenV2 — from-scratch city generation.
#
# Replaces the old per-chunk approach with a top-down, road-first, block-based system.
#
# Architecture:
#   1. Generate road network for the ENTIRE map (graph of nodes + edges)
#   2. Find blocks (areas enclosed by roads)
#   3. Assign districts to blocks (proximity to anchors)
#   4. Plan each block (recipe-based, not random scatter)
#   5. Render blocks to .tscn
#
# No river, no wetlands, no per-chunk independence.
# Roads define structure. Blocks are the unit of planning.

class_name CityGenV2
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")
const BlockRecipes = preload("res://tools/block_recipes.gd")

# === MAP CONFIG ===
const MAP_W: float = 4000.0  # 4km × 3km = 12km²
const MAP_D: float = 3000.0
const HIGHWAY_WIDTH: float = 12.0
const ARTERIAL_WIDTH: float = 8.0
const LOCAL_WIDTH: float = 6.0
const ARTERIAL_SPACING: float = 400.0   # arterials every 400m
const LOCAL_SPACING: float = 150.0      # local streets every 150m within blocks

# === DISTRICT ANCHORS ===
# Each anchor seeds a district. Blocks near an anchor get that district.
const ANCHORS: Array = [
	{"pos": Vector3(800, 0, 600), "type": "downtown", "radius": 700},
	{"pos": Vector3(2800, 0, 800), "type": "commercial", "radius": 600},
	{"pos": Vector3(2000, 0, 2200), "type": "suburbia", "radius": 800},
	{"pos": Vector3(600, 0, 2200), "type": "farmland", "radius": 700},
	{"pos": Vector3(3500, 0, 2500), "type": "industrial", "radius": 500},
	{"pos": Vector3(1800, 0, 400), "type": "military", "radius": 350},
	{"pos": Vector3(3500, 0, 500), "type": "forest", "radius": 500},
	{"pos": Vector3(500, 0, 1000), "type": "parks", "radius": 400},
]

# District properties
const DISTRICT_PROPS: Dictionary = {
	"downtown": {
		"buildings": ["apartment_tower_high", "highrise_office", "hospital", "police_station", "parking_garage", "bank_branch", "broadcast_tower"],
		"fill": 0.95, "lot_w": 25.0, "lot_d": 25.0, "setback": 0.0,
		"foliage": [], "props": ["bollard", "planter_box", "trash_can", "street_light", "bench_park"],
	},
	"commercial": {
		"buildings": ["corner_store", "diner", "gas_station", "store_pharmacy", "store_supermarket", "motel", "strip_mall", "auto_repair_shop", "laundromat", "grocery_store"],
		"fill": 0.85, "lot_w": 30.0, "lot_d": 25.0, "setback": 2.0,
		"foliage": [], "props": ["parking_meter", "dumpster", "shopping_cart", "bollard", "traffic_cone"],
	},
	"suburbia": {
		"buildings": ["suburban_house_v2", "bungalow", "two_story_colonial", "house_modern", "house_ranch", "house_cape_cod", "house_victorian", "house_tudor"],
		"fill": 0.70, "lot_w": 20.0, "lot_d": 30.0, "setback": 4.0,
		"foliage": ["oak_tree", "maple_tree", "birch_tree", "bush", "hedge"],
		"props": ["mailbox", "picket_fence", "trash_can", "garden_gnome", "fire_hydrant", "street_light"],
	},
	"farmland": {
		"buildings": ["farmhouse", "barn", "cottage", "tractor_shed", "grain_storage_shed", "windmill"],
		"fill": 0.25, "lot_w": 40.0, "lot_d": 50.0, "setback": 8.0,
		"foliage": [], "props": ["hay_bale", "wood_fence_post", "irrigation_canal"],
	},
	"industrial": {
		"buildings": ["warehouse", "warehouse_large", "factory_small", "utility_shed_metal", "storage_tank", "loading_dock"],
		"fill": 0.60, "lot_w": 50.0, "lot_d": 40.0, "setback": 5.0,
		"foliage": [], "props": ["shipping_container", "dumpster", "construction_barrier", "guard_rail", "chain_link_fence"],
	},
	"military": {
		"buildings": ["fort_sarran", "military_checkpoint", "bunker_entrance", "watchtower", "helipad", "field_hospital_tent"],
		"fill": 0.40, "lot_w": 40.0, "lot_d": 40.0, "setback": 10.0,
		"foliage": [], "props": ["barrier_concrete", "sandbag", "barbed_wire_fence", "bollard", "traffic_cone"],
	},
	"forest": {
		"buildings": ["hunting_cabin", "ranger_station", "camping_tent", "deer_stand", "cave_entrance", "ranger_lean_to"],
		"fill": 0.05, "lot_w": 30.0, "lot_d": 30.0, "setback": 5.0,
		"foliage": ["pine_tree", "oak_tree", "birch_tree", "bush", "fern", "mushrooms", "fallen_log", "rocks_small"],
		"props": ["park_sign", "bench_park"],
	},
	"parks": {
		"buildings": ["gazebo", "water_fountain"],
		"fill": 0.05, "lot_w": 40.0, "lot_d": 40.0, "setback": 10.0,
		"foliage": ["oak_tree", "maple_tree", "willow_tree", "flower_patch", "bush", "hedge_tall"],
		"props": ["bench_park", "picnic_table", "playground_slide", "swing_set", "seesaw", "water_fountain", "park_sign", "trash_can"],
	},
}

# === ROAD NETWORK ===
# Each road segment: {start: Vector3, end: Vector3, width: float, kind: String}
static func generate_roads() -> Array:
	var roads: Array = []
	
	# 1. Highways: 2 crossing the map (N-S and E-W)
	roads.append({"start": Vector3(0, 0, 1500), "end": Vector3(MAP_W, 0, 1500), "width": HIGHWAY_WIDTH, "kind": "highway", "name": "Sarran Highway"})
	roads.append({"start": Vector3(2000, 0, 0), "end": Vector3(2000, 0, MAP_D), "width": HIGHWAY_WIDTH, "kind": "highway", "name": "Mazar Highway"})
	
	# 2. Arterials: grid every ARTERIAL_SPACING, skip where highway already exists
	for x in range(0, int(MAP_W) + 1, int(ARTERIAL_SPACING)):
		if abs(x - 2000) < 50:  # skip highway position
			continue
		roads.append({"start": Vector3(x, 0, 0), "end": Vector3(x, 0, MAP_D), "width": ARTERIAL_WIDTH, "kind": "arterial"})
	for z in range(0, int(MAP_D) + 1, int(ARTERIAL_SPACING)):
		if abs(z - 1500) < 50:  # skip highway position
			continue
		roads.append({"start": Vector3(0, 0, z), "end": Vector3(MAP_W, 0, z), "width": ARTERIAL_WIDTH, "kind": "arterial"})
	
	# 3. Local streets: subdivide each arterial block with local streets
	# Only in urban districts (downtown, commercial, suburbia, industrial)
	# Rural districts (farmland, forest, parks, military) have sparse roads
	for x in range(int(LOCAL_SPACING), int(MAP_W), int(LOCAL_SPACING)):
		if x % int(ARTERIAL_SPACING) < int(LOCAL_SPACING) or x % int(ARTERIAL_SPACING) > int(ARTERIAL_SPACING) - int(LOCAL_SPACING):
			continue  # skip near arterials
		# Check if this area is urban (near downtown/commercial/suburbia/industrial anchors)
		var is_urban := false
		for anchor in ANCHORS:
			if anchor.type in ["downtown", "commercial", "suburbia", "industrial"]:
				if abs(x - anchor.pos.x) < anchor.radius:
					is_urban = true
					break
		if is_urban:
			roads.append({"start": Vector3(x, 0, 0), "end": Vector3(x, 0, MAP_D), "width": LOCAL_WIDTH, "kind": "local"})
	
	for z in range(int(LOCAL_SPACING), int(MAP_D), int(LOCAL_SPACING)):
		if z % int(ARTERIAL_SPACING) < int(LOCAL_SPACING) or z % int(ARTERIAL_SPACING) > int(ARTERIAL_SPACING) - int(LOCAL_SPACING):
			continue
		var is_urban := false
		for anchor in ANCHORS:
			if anchor.type in ["downtown", "commercial", "suburbia", "industrial"]:
				if abs(z - anchor.pos.z) < anchor.radius:
					is_urban = true
					break
		if is_urban:
			roads.append({"start": Vector3(0, 0, z), "end": Vector3(MAP_W, 0, z), "width": LOCAL_WIDTH, "kind": "local"})
	
	return roads

# === BLOCK GENERATION ===
# A block = rectangular area enclosed by 4 roads.
# We generate blocks by iterating the road grid.
static func generate_blocks(roads: Array) -> Array:
	# Find all X and Z positions where roads exist
	var x_positions: Array = []
	var z_positions: Array = []
	for road in roads:
		var s: Vector3 = road.start
		var e: Vector3 = road.end
		if abs(s.x - e.x) < 1.0:  # vertical road (N-S)
			if not x_positions.has(s.x):
				x_positions.append(s.x)
		else:  # horizontal road (E-W)
			if not z_positions.has(s.z):
				z_positions.append(s.z)
	
	x_positions.sort()
	z_positions.sort()
	
	# Generate blocks between consecutive road positions
	var blocks: Array = []
	for i in range(x_positions.size() - 1):
		for j in range(z_positions.size() - 1):
			var x1: float = x_positions[i]
			var x2: float = x_positions[i + 1]
			var z1: float = z_positions[j]
			var z2: float = z_positions[j + 1]
			var w: float = x2 - x1
			var d: float = z2 - z1
			# Skip blocks that are too small (overlapping roads) or too large (gap)
			if w < 30.0 or d < 30.0:
				continue
			if w > 600.0 or d > 600.0:
				continue
			var center := Vector3((x1 + x2) * 0.5, 0, (z1 + z2) * 0.5)
			blocks.append({
				"id": "block_%d_%d" % [i, j],
				"min": Vector2(x1, z1),
				"max": Vector2(x2, z2),
				"center": center,
				"width": w,
				"depth": d,
				"district": "",  # assigned next
			})
	
	return blocks

# === DISTRICT ASSIGNMENT ===
# Each block gets a district based on nearest anchor.
static func assign_districts(blocks: Array) -> void:
	for block in blocks:
		var center: Vector3 = block.center
		var best_dist: float = 99999.0
		var best_type: String = "suburbia"  # default
		for anchor in ANCHORS:
			var d: float = center.distance_to(anchor.pos)
			if d < anchor.radius and d < best_dist:
				best_dist = d
				best_type = anchor.type
		block.district = best_type

# === BLOCK PLANNING (recipe-driven, adjacency-aware) ===
# Plan a single block using BlockRecipes — exact placement, not RNG scatter.
# neighbor_recipes: list of recipe names chosen by already-planned neighbors.
# Used to avoid placing the same recipe in adjacent blocks (visual variety).
static func plan_block(block: Dictionary, seed: int, neighbor_recipes: Array = []) -> Dictionary:
	var district: String = block.district
	var center: Vector3 = block.center
	var w: float = block.width
	var d: float = block.depth

	var crng := RandomNumberGenerator.new()
	crng.seed = seed + int(center.x) * 31 + int(center.z) * 17

	var plan: Dictionary = {
		"id": block.id,
		"district": district,
		"center": center,
		"width": w,
		"depth": d,
		"buildings": [],
		"foliage": [],
		"props": [],
		"recipe": "",
	}

	# Pick a recipe for this block — adjacency-aware (avoids neighbor duplicates)
	var recipe_name: String = BlockRecipes.pick_recipe(district, seed + int(center.x) * 31 + int(center.z) * 17, neighbor_recipes)
	plan["recipe"] = recipe_name

	# Apply the recipe — returns {buildings, foliage, props} with exact placements
	var result: Dictionary = BlockRecipes.apply_recipe(recipe_name, block, seed)

	plan["buildings"] = result.get("buildings", [])
	plan["foliage"] = result.get("foliage", [])
	plan["props"] = result.get("props", [])

	return plan

# === GENERATE ENTIRE MAP PLAN ===
static func generate_map(seed: int = 1337) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	
	# 1. Generate roads
	var roads := generate_roads()
	print("[CityGenV2] Roads: %d segments" % roads.size())
	
	# 2. Generate blocks
	var blocks := generate_blocks(roads)
	print("[CityGenV2] Blocks: %d" % blocks.size())
	
	# 3. Assign districts
	assign_districts(blocks)
	
	# 4. Count districts
	var district_counts: Dictionary = {}
	for block in blocks:
		district_counts[block.district] = int(district_counts.get(block.district, 0)) + 1
	for d in district_counts:
		print("[CityGenV2]   %s: %d blocks" % [d, district_counts[d]])
	
	# 5. Compute adjacency (each block knows its neighbors by index)
	# Two blocks are adjacent if their bounds touch (share an edge along a road).
	var adjacency: Dictionary = _compute_adjacency(blocks)
	print("[CityGenV2] Adjacency computed: avg %.1f neighbors/block" % _avg_neighbors(adjacency))

	# 6. Plan each block — pass adjacency so recipe picker can avoid duplicates
	# We plan in order; later blocks know what their already-planned neighbors chose.
	var plans: Array = []
	var chosen_recipes: Dictionary = {}  # block_index -> recipe_name (built up as we plan)
	for i in range(blocks.size()):
		var block: Dictionary = blocks[i]
		var neighbor_recipes: Array = _get_neighbor_recipes(i, adjacency, chosen_recipes)
		var plan := plan_block(block, seed, neighbor_recipes)
		plans.append(plan)
		chosen_recipes[i] = plan.recipe

	var t1 := Time.get_ticks_msec()

	# 7. Aggregate stats
	var total_buildings: int = 0
	var total_foliage: int = 0
	var total_props: int = 0
	for plan in plans:
		total_buildings += plan.buildings.size()
		total_foliage += plan.foliage.size()
		total_props += plan.props.size()

	print("[CityGenV2] Plan complete: %dms" % (t1 - t0))
	print("[CityGenV2]   Buildings: %d, Foliage: %d, Props: %d" % [total_buildings, total_foliage, total_props])

	# 8. Recipe distribution
	var recipe_counts: Dictionary = {}
	for plan in plans:
		recipe_counts[plan.recipe] = int(recipe_counts.get(plan.recipe, 0)) + 1
	print("[CityGenV2] Recipe distribution:")
	for r in recipe_counts:
		print("[CityGenV2]   %s: %d" % [r, recipe_counts[r]])

	return {
		"roads": roads,
		"blocks": blocks,
		"plans": plans,
		"adjacency": adjacency,
		"stats": {
			"roads": roads.size(),
			"blocks": blocks.size(),
			"buildings": total_buildings,
			"foliage": total_foliage,
			"props": total_props,
			"plan_time_ms": t1 - t0,
		},
	}

# Compute adjacency: for each block index, list of neighbor block indices
# Two blocks are adjacent if their bounds touch (share an edge along a road).
# We detect this by checking if their rectangles share an edge (within tolerance).
static func _compute_adjacency(blocks: Array) -> Dictionary:
	var adjacency: Dictionary = {}
	var tol: float = 2.0  # 2m tolerance for edge touching (roads take space)

	for i in range(blocks.size()):
		adjacency[i] = []
		var b1: Dictionary = blocks[i]
		var b1_min_x: float = b1.min.x
		var b1_max_x: float = b1.max.x
		var b1_min_z: float = b1.min.y
		var b1_max_z: float = b1.max.y

		for j in range(blocks.size()):
			if i == j:
				continue
			var b2: Dictionary = blocks[j]
			var b2_min_x: float = b2.min.x
			var b2_max_x: float = b2.max.x
			var b2_min_z: float = b2.min.y
			var b2_max_z: float = b2.max.y

			# Check if blocks share an edge (one is left/right/top/bottom of the other)
			# Edge cases: share a vertical edge (b2 is left of b1) or horizontal edge (b2 above b1)

			# Vertical edge shared: b2 is to the left of b1 (b2_max_x ≈ b1_min_x)
			# AND z ranges overlap
			var x_touch_left: bool = abs(b2_max_x - b1_min_x) < tol
			var x_touch_right: bool = abs(b2_min_x - b1_max_x) < tol
			var z_overlap: bool = (b2_min_z < b1_max_z - tol) and (b2_max_z > b1_min_z + tol)

			# Horizontal edge shared: b2 is above/below b1
			var z_touch_top: bool = abs(b2_max_z - b1_min_z) < tol
			var z_touch_bottom: bool = abs(b2_min_z - b1_max_z) < tol
			var x_overlap: bool = (b2_min_x < b1_max_x - tol) and (b2_max_x > b1_min_x + tol)

			if (x_touch_left or x_touch_right) and z_overlap:
				adjacency[i].append(j)
			elif (z_touch_top or z_touch_bottom) and x_overlap:
				adjacency[i].append(j)

	return adjacency

# Get recipe names of already-planned neighbors
static func _get_neighbor_recipes(block_index: int, adjacency: Dictionary, chosen_recipes: Dictionary) -> Array:
	var result: Array = []
	var neighbors: Array = adjacency.get(block_index, [])
	for n in neighbors:
		if chosen_recipes.has(n):
			result.append(chosen_recipes[n])
	return result

static func _avg_neighbors(adjacency: Dictionary) -> float:
	if adjacency.is_empty():
		return 0.0
	var total: int = 0
	for i in adjacency:
		total += adjacency[i].size()
	return float(total) / float(adjacency.size())
