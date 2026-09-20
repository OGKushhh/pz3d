# BlockRecipes — recipe-driven block planning for CityGenV2.
#
# A recipe is a static function that takes block bounds + seed and returns
# exact placement specs: {buildings, foliage, props}.
#
# Each recipe defines EXACT placement (not RNG scatter):
# - Which slots have buildings (fixed positions, not random)
# - Front yard setbacks (no buildings within MIN_SETBACK of road)
# - Driveways/pathways (gaps between buildings for walking)
# - Foliage in yards (not on roads)
# - Props along sidewalks (not on roads)
#
# Variation comes from:
# - Picking which asset variant from a pool (seeded)
# - Small rotation jitter (±2°)
# - Choosing between N or N+1 buildings (within recipe constraints)
#
# All positions are in WORLD coordinates (block.min already applied).

class_name BlockRecipes
extends RefCounted

# === ROAD / SETBACK CONSTANTS ===
# Roads have width 6-12m. Half-width = 3-6m.
# Sidewalk = 1.5m on each side.
# Buffer = 2m (no building should touch the sidewalk edge).
# MIN_SETBACK = road_half + sidewalk + buffer = 3 + 1.5 + 2 = 6.5
const MIN_SETBACK := 7.0  # rounded up for safety

# === RECIPE REGISTRY ===
# Maps district -> array of recipe names.
const RECIPES := {
	"downtown": [
		"downtown_tower_block",
		"downtown_office_strip",
		"downtown_civic_plaza",
		"downtown_parking_block",
	],
	"commercial": [
		"commercial_strip",
		"commercial_corner_store",
		"commercial_mall_block",
		"commercial_gas_station",
	],
	"suburbia": [
		"suburb_house_grid",
		"suburb_house_corner",
		"suburb_row_houses",
		"suburb_cul_de_sac",
	],
	"industrial": [
		"industrial_warehouse_block",
		"industrial_factory_block",
		"industrial_yard",
	],
	"farmland": [
		"farm_house_lot",
		"farm_field_block",
		"farm_complex",
	],
	"forest": [
		"forest_dense_trees",
		"forest_cabin_clearing",
		"forest_trail_block",
	],
	"parks": [
		"park_central_green",
		"park_playground",
		"park_garden",
	],
	"military": [
		"military_checkpoint_block",
		"military_bunker_block",
		"military_fortress_block",
	],
}

# === BUILDING POOLS per district ===
const POOLS := {
	"downtown": {
		"towers": ["apartment_tower_high", "highrise_office", "broadcast_tower"],
		"mid": ["bank_branch", "police_station", "parking_garage"],
		"civic": ["hospital", "police_station", "bank_branch"],
	},
	"commercial": {
		"stores": ["corner_store", "diner", "store_pharmacy", "auto_repair_shop", "laundromat", "grocery_store", "barber_shop", "salon"],
		"large": ["store_supermarket", "strip_mall", "motel"],
	},
	"suburbia": {
		"houses": ["suburban_house_v2", "bungalow", "two_story_colonial", "house_modern", "house_ranch", "house_cape_cod", "house_victorian", "house_tudor"],
		"small": ["bungalow", "house_cape_cod", "house_ranch"],
		"large": ["two_story_colonial", "house_victorian", "house_modern"],
	},
	"industrial": {
		"warehouses": ["warehouse", "warehouse_large"],
		"factories": ["factory_small"],
		"support": ["utility_shed_metal", "storage_tank", "loading_dock"],
	},
	"farmland": {
		"houses": ["farmhouse", "cottage"],
		"utility": ["barn", "tractor_shed", "grain_storage_shed", "windmill"],
	},
	"forest": {
		"cabins": ["hunting_cabin", "ranger_station", "camping_tent", "deer_stand", "ranger_lean_to"],
	},
	"parks": {
		"structures": ["gazebo", "water_fountain"],
	},
	"military": {
		"main": ["military_checkpoint", "bunker_entrance", "watchtower", "helipad", "field_hospital_tent"],
		"landmark": ["fort_sarran"],
	},
}

# === FOLIAGE + PROP POOLS ===
const FOLIAGE_POOLS := {
	"suburbia": ["oak_tree", "maple_tree", "birch_tree", "bush", "hedge"],
	"farmland": [],
	"forest": ["pine_tree", "oak_tree", "birch_tree", "bush", "fern", "mushrooms", "fallen_log", "rocks_small"],
	"parks": ["oak_tree", "maple_tree", "willow_tree", "flower_patch", "bush", "hedge_tall"],
	"downtown": [],
	"commercial": [],
	"industrial": [],
	"military": [],
}

const PROP_POOLS := {
	"downtown": ["bollard", "planter_box", "trash_can", "street_light", "bench_park"],
	"commercial": ["parking_meter", "dumpster", "shopping_cart", "bollard", "traffic_cone"],
	"suburbia": ["mailbox", "picket_fence", "trash_can", "garden_gnome", "fire_hydrant", "street_light"],
	"industrial": ["shipping_container", "dumpster", "construction_barrier", "guard_rail", "chain_link_fence"],
	"farmland": ["hay_bale", "wood_fence_post", "irrigation_canal"],
	"military": ["barrier_concrete", "sandbag", "barbed_wire_fence", "bollard", "traffic_cone"],
	"forest": ["park_sign", "bench_park"],
	"parks": ["bench_park", "picnic_table", "playground_slide", "swing_set", "seesaw", "water_fountain", "park_sign", "trash_can"],
}

# === PICK RECIPE (adjacency-aware) ===
# Picks a recipe for the given district, preferring ones not already chosen by neighbors.
# This makes adjacent blocks get different recipe variants — visual variety.
#
# neighbor_recipes: list of recipe names already chosen by this block's neighbors.
# Strategy:
# 1. Get all recipes for this district
# 2. Filter out ones used by neighbors (if possible)
# 3. If all recipes are used by neighbors, fall back to least-used neighbor recipe
# 4. Pick randomly from remaining candidates (seeded by block coords)
static func pick_recipe(district: String, seed: int, neighbor_recipes: Array = []) -> String:
	var recipes: Array = RECIPES.get(district, [])
	if recipes.is_empty():
		return "empty_block"
	var crng := RandomNumberGenerator.new()
	crng.seed = seed

	# If no neighbor info, just pick randomly (backward-compat)
	if neighbor_recipes.is_empty():
		return recipes[crng.randi() % recipes.size()]

	# Count how many neighbors used each recipe
	var neighbor_counts: Dictionary = {}
	for r in neighbor_recipes:
		neighbor_counts[r] = int(neighbor_counts.get(r, 0)) + 1

	# Find recipes not used by any neighbor (preferred)
	var candidates: Array = []
	for r in recipes:
		if not neighbor_counts.has(r):
			candidates.append(r)

	# If all recipes are used by neighbors, use least-used ones
	if candidates.is_empty():
		var min_count: int = 999
		for r in recipes:
			var c: int = int(neighbor_counts.get(r, 0))
			if c < min_count:
				min_count = c
				candidates = [r]
			elif c == min_count:
				candidates.append(r)

	# Pick from candidates (seeded)
	return candidates[crng.randi() % candidates.size()]

# === APPLY RECIPE ===
static func apply_recipe(recipe_name: String, block: Dictionary, seed: int) -> Dictionary:
	var min_x: float = block.min.x
	var min_z: float = block.min.y
	var max_x: float = block.max.x
	var max_z: float = block.max.y
	var w: float = block.width
	var d: float = block.depth
	var center: Vector3 = block.center

	var crng := RandomNumberGenerator.new()
	crng.seed = seed + int(center.x) * 31 + int(center.z) * 17

	var result := {"buildings": [], "foliage": [], "props": []}

	match recipe_name:
		"downtown_tower_block":
			_downtown_tower_block(result, min_x, min_z, w, d, center, crng)
		"downtown_office_strip":
			_downtown_office_strip(result, min_x, min_z, w, d, center, crng)
		"downtown_civic_plaza":
			_downtown_civic_plaza(result, min_x, min_z, w, d, center, crng)
		"downtown_parking_block":
			_downtown_parking_block(result, min_x, min_z, w, d, center, crng)
		"commercial_strip":
			_commercial_strip(result, min_x, min_z, w, d, center, crng)
		"commercial_corner_store":
			_commercial_corner_store(result, min_x, min_z, w, d, center, crng)
		"commercial_mall_block":
			_commercial_mall_block(result, min_x, min_z, w, d, center, crng)
		"commercial_gas_station":
			_commercial_gas_station(result, min_x, min_z, w, d, center, crng)
		"suburb_house_grid":
			_suburb_house_grid(result, min_x, min_z, w, d, center, crng)
		"suburb_house_corner":
			_suburb_house_corner(result, min_x, min_z, w, d, center, crng)
		"suburb_row_houses":
			_suburb_row_houses(result, min_x, min_z, w, d, center, crng)
		"suburb_cul_de_sac":
			_suburb_cul_de_sac(result, min_x, min_z, w, d, center, crng)
		"industrial_warehouse_block":
			_industrial_warehouse_block(result, min_x, min_z, w, d, center, crng)
		"industrial_factory_block":
			_industrial_factory_block(result, min_x, min_z, w, d, center, crng)
		"industrial_yard":
			_industrial_yard(result, min_x, min_z, w, d, center, crng)
		"farm_house_lot":
			_farm_house_lot(result, min_x, min_z, w, d, center, crng)
		"farm_field_block":
			_farm_field_block(result, min_x, min_z, w, d, center, crng)
		"farm_complex":
			_farm_complex(result, min_x, min_z, w, d, center, crng)
		"forest_dense_trees":
			_forest_dense_trees(result, min_x, min_z, w, d, center, crng)
		"forest_cabin_clearing":
			_forest_cabin_clearing(result, min_x, min_z, w, d, center, crng)
		"forest_trail_block":
			_forest_trail_block(result, min_x, min_z, w, d, center, crng)
		"park_central_green":
			_park_central_green(result, min_x, min_z, w, d, center, crng)
		"park_playground":
			_park_playground(result, min_x, min_z, w, d, center, crng)
		"park_garden":
			_park_garden(result, min_x, min_z, w, d, center, crng)
		"military_checkpoint_block":
			_military_checkpoint_block(result, min_x, min_z, w, d, center, crng)
		"military_bunker_block":
			_military_bunker_block(result, min_x, min_z, w, d, center, crng)
		"military_fortress_block":
			_military_fortress_block(result, min_x, min_z, w, d, center, crng)
		_:
			_empty_block(result, min_x, min_z, w, d, center, crng)

	# FALLBACK: ensure non-wilderness blocks have at least 1 building.
	# Recipes may bail on small blocks (returning 0 buildings), which fails
	# Loop 4's hard constraint. Place a small fallback building at center.
	if result.buildings.is_empty():
		var district: String = block.get("district", "")
		if district not in WILDERNESS_DISTRICTS:
			_add_fallback_building(result, district, center, crng)

	return result

# WILDERNESS_DISTRICTS = exempt from "must have at least 1 building" rule
const WILDERNESS_DISTRICTS := ["forest", "parks", "farmland"]

# Fallback building per district (small, fits anywhere)
static func _add_fallback_building(result: Dictionary, district: String, center: Vector3, crng: RandomNumberGenerator):
	var fallback: Dictionary = {
		"downtown": "parking_garage",
		"commercial": "corner_store",
		"industrial": "utility_shed_metal",
		"military": "watchtower",
		"suburbia": "bungalow",
	}
	var bname: String = fallback.get(district, "utility_shed_metal")
	_add_building(result, Vector3(center.x, 0, center.z), crng.randf() * 360.0, bname)

# === HELPERS ===

static func _pick(pool: Array, crng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return ""
	return pool[crng.randi() % pool.size()]

static func _pick_unique(pool: Array, crng: RandomNumberGenerator, used: Dictionary, max_count: int) -> String:
	for _i in range(5):
		var candidate: String = pool[crng.randi() % pool.size()]
		if int(used.get(candidate, 0)) < max_count:
			return candidate
	return pool[crng.randi() % pool.size()]

static func _add_building(result: Dictionary, pos: Vector3, rot_y: float, name: String):
	result["buildings"].append({"pos": pos, "rot_y": rot_y, "asset_name": name})

static func _add_foliage(result: Dictionary, pos: Vector3, rot_y: float, name: String, scale: float = 1.0):
	result["foliage"].append({"pos": pos, "rot_y": rot_y, "asset_name": name, "scale": scale})

static func _add_prop(result: Dictionary, pos: Vector3, rot_y: float, name: String):
	result["props"].append({"pos": pos, "rot_y": rot_y, "asset_name": name})

static func _scatter_foliage(result: Dictionary, pool: Array, min_x: float, min_z: float, w: float, d: float, count: int, crng: RandomNumberGenerator, inset: float = MIN_SETBACK):
	if pool.is_empty() or count <= 0:
		return
	for _i in range(count):
		var fx: float = min_x + inset + crng.randf() * (w - inset * 2.0)
		var fz: float = min_z + inset + crng.randf() * (d - inset * 2.0)
		var fname: String = pool[crng.randi() % pool.size()]
		var scale: float = crng.randf_range(0.8, 1.3)
		_add_foliage(result, Vector3(fx, 0, fz), crng.randf() * 360.0, fname, scale)

static func _scatter_props(result: Dictionary, pool: Array, min_x: float, min_z: float, w: float, d: float, count: int, crng: RandomNumberGenerator, inset: float = MIN_SETBACK):
	if pool.is_empty() or count <= 0:
		return
	for _i in range(count):
		var px: float = min_x + inset + crng.randf() * (w - inset * 2.0)
		var pz: float = min_z + inset + crng.randf() * (d - inset * 2.0)
		var pname: String = pool[crng.randi() % pool.size()]
		_add_prop(result, Vector3(px, 0, pz), crng.randf() * 360.0, pname)

# === EMPTY BLOCK (fallback) ===
static func _empty_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	pass  # nothing placed

# === DOWNTOWN RECIPES (4) ===

# downtown_tower_block: 1-2 high-rise towers in center, plaza around them.
static func _downtown_tower_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var towers: Array = POOLS.downtown.towers
	var usable_w: float = w - MIN_SETBACK * 2.0
	var usable_d: float = d - MIN_SETBACK * 2.0
	if usable_w < 30 or usable_d < 30:
		return
	# 1 or 2 towers depending on block size
	var tower_count: int = 2 if usable_w > 80 and usable_d > 80 else 1
	var tower_type_counts: Dictionary = {}
	for i in range(tower_count):
		var offset_x: float = -usable_w * 0.25 if i == 0 else usable_w * 0.25
		var offset_z: float = 0.0
		var pos := Vector3(center.x + offset_x, 0, center.z + offset_z)
		var bname: String = _pick_unique(towers, crng, tower_type_counts, 1)
		_add_building(result, pos, crng.randf_range(-5, 5), bname)
		tower_type_counts[bname] = 1
	# Plaza props around tower base
	var plaza_props: Array = PROP_POOLS.downtown
	_scatter_props(result, plaza_props, min_x, min_z, w, d, int(usable_w * usable_d / 400.0), crng, MIN_SETBACK + 15.0)

# downtown_office_strip: row of mid-rise offices along south edge, facing south road.
static func _downtown_office_strip(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var mid: Array = POOLS.downtown.mid
	var usable_w: float = w - MIN_SETBACK * 2.0
	if usable_w < 30:
		return
	var building_w: float = 30.0
	var building_d: float = 20.0
	var cols: int = max(1, int(usable_w / building_w))
	var row_z: float = min_z + MIN_SETBACK + building_d * 0.5
	var type_counts: Dictionary = {}
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + col * building_w + building_w * 0.5
		var pos := Vector3(bx, 0, row_z)
		var bname: String = _pick_unique(mid, crng, type_counts, 2)
		_add_building(result, pos, 0.0, bname)
		type_counts[bname] = int(type_counts.get(bname, 0)) + 1
	# Sidewalk props
	_scatter_props(result, PROP_POOLS.downtown, min_x, min_z, w, d, int(w * d / 600.0), crng, MIN_SETBACK)

# downtown_civic_plaza: landmark building + open plaza with benches.
static func _downtown_civic_plaza(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var civic: Array = POOLS.downtown.civic
	if civic.is_empty():
		return
	# Landmark at center-back (north side)
	var landmark_z: float = min_z + MIN_SETBACK + 15.0
	var bname: String = civic[crng.randi() % civic.size()]
	_add_building(result, Vector3(center.x, 0, landmark_z), 180.0, bname)
	# Benches in plaza
	var plaza_props: Array = PROP_POOLS.downtown
	_scatter_props(result, plaza_props, min_x, min_z, w, d, 6, crng, MIN_SETBACK + 5.0)

# downtown_parking_block: parking garage + small shops.
static func _downtown_parking_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Parking garage at center
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, "parking_garage")
	# Bollards around
	_scatter_props(result, PROP_POOLS.downtown, min_x, min_z, w, d, 8, crng, MIN_SETBACK + 10.0)

# === COMMERCIAL RECIPES (4) ===

# commercial_strip: stores along south edge, parking in front.
static func _commercial_strip(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var stores: Array = POOLS.commercial.stores
	var usable_w: float = w - MIN_SETBACK * 2.0
	if usable_w < 25:
		return
	var building_w: float = 25.0
	var building_d: float = 18.0
	var cols: int = max(1, int(usable_w / building_w))
	var row_z: float = min_z + MIN_SETBACK + building_d * 0.5
	var type_counts: Dictionary = {}
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + col * building_w + building_w * 0.5
		var bname: String = _pick_unique(stores, crng, type_counts, 2)
		_add_building(result, Vector3(bx, 0, row_z), 0.0, bname)
		type_counts[bname] = int(type_counts.get(bname, 0)) + 1
	# Parking meters in front (south side)
	var front_z: float = min_z + MIN_SETBACK + building_d + 5.0
	for col in range(cols):
		var px: float = min_x + MIN_SETBACK + col * building_w + building_w * 0.5
		_add_prop(result, Vector3(px, 0, front_z), 0.0, "parking_meter")
	# Dumpsters at corners
	_add_prop(result, Vector3(min_x + MIN_SETBACK + 2, 0, min_z + MIN_SETBACK + 2), 0.0, "dumpster")

# commercial_corner_store: single store at SE corner.
static func _commercial_corner_store(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var stores: Array = POOLS.commercial.stores
	if stores.is_empty():
		return
	var bname: String = stores[crng.randi() % stores.size()]
	var pos := Vector3(min_x + MIN_SETBACK + 12, 0, min_z + MIN_SETBACK + 12)
	_add_building(result, pos, 0.0, bname)
	# Parking meters
	_scatter_props(result, PROP_POOLS.commercial, min_x, min_z, w, d, 4, crng, MIN_SETBACK + 5.0)

# commercial_mall_block: supermarket + parking lot.
static func _commercial_mall_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var large: Array = POOLS.commercial.large
	if large.is_empty():
		return
	var bname: String = large[crng.randi() % large.size()]
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, bname)
	# Parking lot props
	_scatter_props(result, PROP_POOLS.commercial, min_x, min_z, w, d, 8, crng, MIN_SETBACK + 10.0)

# commercial_gas_station: gas station + small shop at corner.
static func _commercial_gas_station(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, "gas_station")
	_scatter_props(result, PROP_POOLS.commercial, min_x, min_z, w, d, 4, crng, MIN_SETBACK + 5.0)

# === SUBURBIA RECIPES (4) ===

# suburb_house_grid: 2 rows of houses facing outward, front yards, backyards between.
# This is the KEY recipe that fixes "no side pathways between homes".
static func _suburb_house_grid(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var houses: Array = POOLS.suburbia.houses
	if houses.is_empty():
		return
	var usable_w: float = w - MIN_SETBACK * 2.0
	var usable_d: float = d - MIN_SETBACK * 2.0
	if usable_w < 25 or usable_d < 50:
		# Block too small for 2 rows — place 1 row
		_suburb_single_row(result, min_x, min_z, w, d, center, crng)
		return

	# Layout (cross-section, north to south):
	#   [N road] | setback | front_yard_n | house_n | backyard | house_s | front_yard_s | setback | [S road]
	#
	# front_yard = 8m (mailbox, tree, fence)
	# house = 12m deep
	# backyard = remaining space (at least 15m for pathway + greenery)
	var front_yard: float = 8.0
	var house_depth: float = 12.0
	var lot_w: float = 25.0
	var min_backyard: float = 15.0

	var backyard: float = usable_d - front_yard * 2.0 - house_depth * 2.0
	if backyard < min_backyard:
		# Not enough depth for 2 rows — use single row
		_suburb_single_row(result, min_x, min_z, w, d, center, crng)
		return

	var cols: int = max(1, int(usable_w / lot_w))
	# Center the row grid
	var row_w: float = cols * lot_w
	var row_offset_x: float = (usable_w - row_w) * 0.5

	# North row: houses face north (rot=180), placed at top of block
	var north_z: float = min_z + MIN_SETBACK + front_yard + house_depth * 0.5
	# South row: houses face south (rot=0), placed at bottom of block
	var south_z: float = max_z - MIN_SETBACK - front_yard - house_depth * 0.5

	var type_counts: Dictionary = {}
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + row_offset_x + col * lot_w + lot_w * 0.5
		var jitter: float = crng.randf_range(-1.0, 1.0)
		# North house
		var bname_n: String = _pick_unique(houses, crng, type_counts, 2)
		_add_building(result, Vector3(bx + jitter, 0, north_z), 180.0 + crng.randf_range(-2, 2), bname_n)
		type_counts[bname_n] = int(type_counts.get(bname_n, 0)) + 1
		# South house
		var bname_s: String = _pick_unique(houses, crng, type_counts, 2)
		_add_building(result, Vector3(bx - jitter, 0, south_z), 0.0 + crng.randf_range(-2, 2), bname_s)
		type_counts[bname_s] = int(type_counts.get(bname_s, 0)) + 1
		# Front yard: mailbox + small tree (north side)
		var fy_n_z: float = north_z - house_depth * 0.5 - 3.0
		_add_prop(result, Vector3(bx, 0, fy_n_z), 0.0, "mailbox")
		_add_foliage(result, Vector3(bx + lot_w * 0.3, 0, fy_n_z + 1), crng.randf() * 360.0, _pick(FOLIAGE_POOLS.suburbia, crng), crng.randf_range(0.9, 1.2))
		# Front yard: mailbox + small tree (south side)
		var fy_s_z: float = south_z + house_depth * 0.5 + 3.0
		_add_prop(result, Vector3(bx, 0, fy_s_z), 0.0, "mailbox")
		_add_foliage(result, Vector3(bx - lot_w * 0.3, 0, fy_s_z - 1), crng.randf() * 360.0, _pick(FOLIAGE_POOLS.suburbia, crng), crng.randf_range(0.9, 1.2))

	# Backyard: scatter bushes + trees (between the two rows, away from roads)
	var backyard_center_z: float = (north_z + south_z) * 0.5
	var backyard_w: float = row_w
	var backyard_d: float = abs(south_z - north_z) - house_depth
	_scatter_foliage_in_area(result, FOLIAGE_POOLS.suburbia, min_x + MIN_SETBACK + row_offset_x, backyard_center_z - backyard_d * 0.5, backyard_w, backyard_d, int(backyard_w * backyard_d / 300.0), crng)

	# Street lights at block corners
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, min_z + MIN_SETBACK), 0.0, "street_light")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, min_z + MIN_SETBACK), 0.0, "street_light")
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "street_light")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "street_light")
	# Fire hydrant at one corner
	_add_prop(result, Vector3(min_x + MIN_SETBACK + 3, 0, max_z - MIN_SETBACK - 3), 0.0, "fire_hydrant")

# Helper: single row of houses (for small blocks)
static func _suburb_single_row(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var houses: Array = POOLS.suburbia.houses
	var usable_w: float = w - MIN_SETBACK * 2.0
	if usable_w < 25:
		return
	var lot_w: float = 25.0
	var house_depth: float = 12.0
	var front_yard: float = 8.0
	var cols: int = max(1, int(usable_w / lot_w))
	var row_offset_x: float = (usable_w - cols * lot_w) * 0.5
	# Place houses along the south edge, facing south (toward road)
	var house_z: float = max_z - MIN_SETBACK - front_yard - house_depth * 0.5
	var type_counts: Dictionary = {}
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + row_offset_x + col * lot_w + lot_w * 0.5
		var bname: String = _pick_unique(houses, crng, type_counts, 2)
		_add_building(result, Vector3(bx, 0, house_z), 0.0, bname)
		type_counts[bname] = int(type_counts.get(bname, 0)) + 1
		# Front yard
		var fy_z: float = house_z + house_depth * 0.5 + 3.0
		_add_prop(result, Vector3(bx, 0, fy_z), 0.0, "mailbox")
		_add_foliage(result, Vector3(bx + 5, 0, fy_z), crng.randf() * 360.0, _pick(FOLIAGE_POOLS.suburbia, crng), 1.0)
	# Street lights
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "street_light")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "street_light")

# suburb_house_corner: bigger house on corner lot + smaller houses along edge.
static func _suburb_house_corner(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var large: Array = POOLS.suburbia.large
	var small: Array = POOLS.suburbia.small
	if large.is_empty() or small.is_empty():
		_suburb_house_grid(result, min_x, min_z, w, d, center, crng)
		return
	# Corner lot: NW corner, large house
	var corner_x: float = min_x + MIN_SETBACK + 15
	var corner_z: float = min_z + MIN_SETBACK + 12
	var corner_name: String = large[crng.randi() % large.size()]
	_add_building(result, Vector3(corner_x, 0, corner_z), 90.0, corner_name)
	# 2-3 smaller houses along south edge
	var usable_w: float = w - MIN_SETBACK * 2.0
	var lot_w: float = 25.0
	var house_depth: float = 10.0
	var front_yard: float = 8.0
	var cols: int = max(1, int(usable_w / lot_w) - 1)
	var house_z: float = max_z - MIN_SETBACK - front_yard - house_depth * 0.5
	var type_counts: Dictionary = {corner_name: 1}
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + col * lot_w + lot_w * 0.5
		var bname: String = _pick_unique(small, crng, type_counts, 2)
		_add_building(result, Vector3(bx, 0, house_z), 0.0, bname)
		type_counts[bname] = int(type_counts.get(bname, 0)) + 1
		_add_prop(result, Vector3(bx, 0, house_z + house_depth * 0.5 + 3), 0.0, "mailbox")
	# Front yard trees for corner house
	_add_foliage(result, Vector3(corner_x + 8, 0, corner_z + 5), crng.randf() * 360.0, _pick(FOLIAGE_POOLS.suburbia, crng), 1.1)
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "street_light")

# suburb_row_houses: 3-4 attached row houses (no side yards).
static func _suburb_row_houses(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var houses: Array = POOLS.suburbia.houses
	var usable_w: float = w - MIN_SETBACK * 2.0
	if usable_w < 60:
		_suburb_single_row(result, min_x, min_z, w, d, center, crng)
		return
	# Row houses: 4 attached, each 15m wide
	var unit_w: float = 15.0
	var cols: int = min(5, int(usable_w / unit_w))
	var row_w: float = cols * unit_w
	var row_offset_x: float = (usable_w - row_w) * 0.5
	var house_depth: float = 12.0
	var front_yard: float = 6.0
	var house_z: float = max_z - MIN_SETBACK - front_yard - house_depth * 0.5
	var type_counts: Dictionary = {}
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + row_offset_x + col * unit_w + unit_w * 0.5
		var bname: String = _pick_unique(houses, crng, type_counts, 2)
		_add_building(result, Vector3(bx, 0, house_z), 0.0, bname)
		type_counts[bname] = int(type_counts.get(bname, 0)) + 1
	# Front yard: hedge along the row
	var hedge_z: float = house_z + house_depth * 0.5 + 4.0
	for col in range(cols):
		var bx: float = min_x + MIN_SETBACK + row_offset_x + col * unit_w + unit_w * 0.5
		_add_foliage(result, Vector3(bx, 0, hedge_z), 0.0, "hedge", 1.0)
	# Backyard trees
	_scatter_foliage_in_area(result, FOLIAGE_POOLS.suburbia, min_x + MIN_SETBACK + row_offset_x, min_z + MIN_SETBACK, row_w, house_z - house_depth * 0.5 - (min_z + MIN_SETBACK), int(row_w * 10 / 300.0), crng)

# suburb_cul_de_sac: curved street feel — houses around central green.
static func _suburb_cul_de_sac(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var houses: Array = POOLS.suburbia.houses
	var radius: float = min(w, d) * 0.35
	if radius < 20:
		_suburb_single_row(result, min_x, min_z, w, d, center, crng)
		return
	# Houses in a circle around center green
	var count: int = min(6, max(3, int(radius / 12.0)))
	var type_counts: Dictionary = {}
	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU
		var bx: float = center.x + cos(angle) * radius
		var bz: float = center.z + sin(angle) * radius
		var bname: String = _pick_unique(houses, crng, type_counts, 2)
		var rot: float = rad_to_deg(atan2(bx - center.x, bz - center.z)) + 180.0
		_add_building(result, Vector3(bx, 0, bz), rot, bname)
		type_counts[bname] = int(type_counts.get(bname, 0)) + 1
	# Central green: trees + bench
	_add_foliage(result, Vector3(center.x, 0, center.z), 0.0, _pick(FOLIAGE_POOLS.suburbia, crng), 1.2)
	_add_prop(result, Vector3(center.x + 5, 0, center.z + 3), 0.0, "bench_park")
	_add_prop(result, Vector3(center.x - 4, 0, center.z - 2), crng.randf() * 360.0, "garden_gnome")

# === INDUSTRIAL RECIPES (3) ===

static func _industrial_warehouse_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var warehouses: Array = POOLS.industrial.warehouses
	var usable_w: float = w - MIN_SETBACK * 2.0
	var usable_d: float = d - MIN_SETBACK * 2.0
	if usable_w < 40 or usable_d < 40:
		# Block too small for warehouses — place a single utility shed as fallback
		_add_building(result, Vector3(center.x, 0, center.z), 0.0, "utility_shed_metal")
		_scatter_props(result, PROP_POOLS.industrial, min_x, min_z, w, d, 3, crng, MIN_SETBACK)
		return
	# 1-2 warehouses, placed at center with setback
	var wh_count: int = 2 if usable_w > 100 else 1
	var type_counts: Dictionary = {}
	for i in range(wh_count):
		var offset_x: float = -usable_w * 0.2 if i == 0 else usable_w * 0.2
		var pos := Vector3(center.x + offset_x, 0, center.z)
		var bname: String = _pick_unique(warehouses, crng, type_counts, 1)
		_add_building(result, pos, crng.randf_range(-5, 5), bname)
		type_counts[bname] = 1
	# Shipping containers + dumpsters scattered (inset from road)
	_scatter_props(result, PROP_POOLS.industrial, min_x, min_z, w, d, int(usable_w * usable_d / 500.0), crng, MIN_SETBACK + 10.0)

static func _industrial_factory_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var factories: Array = POOLS.industrial.factories
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, _pick(factories, crng))
	# Storage tanks + loading docks around
	var support: Array = POOLS.industrial.support
	if not support.is_empty():
		for i in range(3):
			var angle: float = (float(i) / 3.0) * TAU
			var r: float = min(w, d) * 0.3
			var px: float = center.x + cos(angle) * r
			var pz: float = center.z + sin(angle) * r
			_add_building(result, Vector3(px, 0, pz), crng.randf() * 360.0, _pick(support, crng))
	_scatter_props(result, PROP_POOLS.industrial, min_x, min_z, w, d, 6, crng, MIN_SETBACK + 5.0)

static func _industrial_yard(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Open storage yard — no main building, just containers + barriers
	_scatter_props(result, PROP_POOLS.industrial, min_x, min_z, w, d, int(w * d / 200.0), crng, MIN_SETBACK)
	# Chain link fence around perimeter (corners)
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, min_z + MIN_SETBACK), 0.0, "chain_link_fence")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, min_z + MIN_SETBACK), 90.0, "chain_link_fence")
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, max_z - MIN_SETBACK), 90.0, "chain_link_fence")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "chain_link_fence")

# === FARMLAND RECIPES (3) ===

static func _farm_house_lot(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var houses: Array = POOLS.farmland.houses
	var utility: Array = POOLS.farmland.utility
	if houses.is_empty():
		return
	# Farmhouse at one corner, barn at opposite
	var house_pos := Vector3(min_x + MIN_SETBACK + 15, 0, min_z + MIN_SETBACK + 12)
	_add_building(result, house_pos, 90.0, _pick(houses, crng))
	var barn_pos := Vector3(max_x - MIN_SETBACK - 20, 0, max_z - MIN_SETBACK - 15)
	_add_building(result, barn_pos, 270.0, _pick(utility, crng))
	# Hay bales scattered
	_scatter_props(result, PROP_POOLS.farmland, min_x, min_z, w, d, int(w * d / 800.0), crng, MIN_SETBACK)

static func _farm_field_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Empty field — just hay bales + fence posts
	_scatter_props(result, PROP_POOLS.farmland, min_x, min_z, w, d, int(w * d / 600.0), crng, MIN_SETBACK)

static func _farm_complex(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var houses: Array = POOLS.farmland.houses
	var utility: Array = POOLS.farmland.utility
	if houses.is_empty() or utility.is_empty():
		return
	# Farmhouse at center
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, _pick(houses, crng))
	# Utility buildings around
	var type_counts: Dictionary = {}
	for i in range(3):
		var angle: float = (float(i) / 3.0) * TAU + crng.randf()
		var r: float = min(w, d) * 0.3
		var px: float = center.x + cos(angle) * r
		var pz: float = center.z + sin(angle) * r
		var bname: String = _pick_unique(utility, crng, type_counts, 1)
		_add_building(result, Vector3(px, 0, pz), crng.randf() * 360.0, bname)
		type_counts[bname] = 1
	_scatter_props(result, PROP_POOLS.farmland, min_x, min_z, w, d, 4, crng, MIN_SETBACK)

# === FOREST RECIPES (3) ===

static func _forest_dense_trees(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var pool: Array = FOLIAGE_POOLS.forest
	var count: int = int(w * d / 150.0)  # dense
	_scatter_foliage(result, pool, min_x, min_z, w, d, count, crng, MIN_SETBACK)
	_scatter_props(result, PROP_POOLS.forest, min_x, min_z, w, d, int(w * d / 1000.0), crng, MIN_SETBACK)

static func _forest_cabin_clearing(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var cabins: Array = POOLS.forest.cabins
	if cabins.is_empty():
		_forest_dense_trees(result, min_x, min_z, w, d, center, crng)
		return
	# 1-2 cabins in a clearing at center
	_add_building(result, Vector3(center.x - 10, 0, center.z), 0.0, _pick(cabins, crng))
	if w > 100:
		_add_building(result, Vector3(center.x + 10, 0, center.z), 180.0, _pick(cabins, crng))
	# Dense trees around edges (not in clearing)
	var clearing_r: float = 25.0
	var pool: Array = FOLIAGE_POOLS.forest
	var count: int = int(w * d / 200.0)
	for _i in range(count):
		var fx: float = min_x + MIN_SETBACK + crng.randf() * (w - MIN_SETBACK * 2.0)
		var fz: float = min_z + MIN_SETBACK + crng.randf() * (d - MIN_SETBACK * 2.0)
		# Skip if in clearing
		if Vector2(fx - center.x, fz - center.z).length() < clearing_r:
			continue
		_add_foliage(result, Vector3(fx, 0, fz), crng.randf() * 360.0, _pick(pool, crng), crng.randf_range(0.8, 1.3))

static func _forest_trail_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Walking trail: benches + sign, sparse trees
	_add_prop(result, Vector3(center.x, 0, center.z), 0.0, "park_sign")
	_add_prop(result, Vector3(center.x + 10, 0, center.z + 5), 0.0, "bench_park")
	_add_prop(result, Vector3(center.x - 8, 0, center.z - 3), 90.0, "bench_park")
	var pool: Array = FOLIAGE_POOLS.forest
	var count: int = int(w * d / 400.0)  # sparse
	_scatter_foliage(result, pool, min_x, min_z, w, d, count, crng, MIN_SETBACK)

# === PARKS RECIPES (3) ===

static func _park_central_green(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var structures: Array = POOLS.parks.structures
	if not structures.is_empty():
		_add_building(result, Vector3(center.x, 0, center.z), 0.0, _pick(structures, crng))
	# Benches + trees around
	var pool: Array = FOLIAGE_POOLS.parks
	_scatter_foliage(result, pool, min_x, min_z, w, d, int(w * d / 300.0), crng, MIN_SETBACK)
	_scatter_props(result, PROP_POOLS.parks, min_x, min_z, w, d, int(w * d / 400.0), crng, MIN_SETBACK)

static func _park_playground(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Playground equipment at center
	_add_prop(result, Vector3(center.x - 8, 0, center.z), 0.0, "playground_slide")
	_add_prop(result, Vector3(center.x + 8, 0, center.z), 0.0, "swing_set")
	_add_prop(result, Vector3(center.x, 0, center.z - 8), 0.0, "seesaw")
	_add_prop(result, Vector3(center.x, 0, center.z + 8), 0.0, "picnic_table")
	_add_prop(result, Vector3(center.x + 15, 0, center.z + 10), 0.0, "bench_park")
	# Trees around edges
	_scatter_foliage(result, FOLIAGE_POOLS.parks, min_x, min_z, w, d, int(w * d / 400.0), crng, MIN_SETBACK + 10.0)

static func _park_garden(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Flower patches + hedges in rows
	var pool: Array = FOLIAGE_POOLS.parks
	var count: int = int(w * d / 200.0)
	_scatter_foliage(result, pool, min_x, min_z, w, d, count, crng, MIN_SETBACK)
	_add_prop(result, Vector3(center.x, 0, center.z), 0.0, "water_fountain")
	_add_prop(result, Vector3(center.x + 10, 0, center.z + 5), 0.0, "bench_park")
	_add_prop(result, Vector3(center.x - 10, 0, center.z - 5), 0.0, "bench_park")

# === MILITARY RECIPES (3) ===

static func _military_checkpoint_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	# Checkpoint at center
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, "military_checkpoint")
	# Barriers + sandbags around perimeter
	_scatter_props(result, PROP_POOLS.military, min_x, min_z, w, d, int(w * d / 300.0), crng, MIN_SETBACK + 5.0)
	# Concrete barriers at corners
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, min_z + MIN_SETBACK), 0.0, "barrier_concrete")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, min_z + MIN_SETBACK), 0.0, "barrier_concrete")
	_add_prop(result, Vector3(min_x + MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "barrier_concrete")
	_add_prop(result, Vector3(max_x - MIN_SETBACK, 0, max_z - MIN_SETBACK), 0.0, "barrier_concrete")

static func _military_bunker_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var main: Array = POOLS.military.main
	if main.is_empty():
		return
	# Bunker entrance at center
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, "bunker_entrance")
	# Watchtower at corner
	_add_building(result, Vector3(min_x + MIN_SETBACK + 10, 0, min_z + MIN_SETBACK + 10), 0.0, "watchtower")
	# Barbed wire + sandbags
	_scatter_props(result, PROP_POOLS.military, min_x, min_z, w, d, int(w * d / 400.0), crng, MIN_SETBACK + 5.0)

static func _military_fortress_block(result: Dictionary, min_x: float, min_z: float, w: float, d: float, center: Vector3, crng: RandomNumberGenerator):
	var max_x: float = min_x + w
	var max_z: float = min_z + d
	var landmark: Array = POOLS.military.landmark
	if landmark.is_empty():
		_military_bunker_block(result, min_x, min_z, w, d, center, crng)
		return
	# Fort Sarran at center (landmark — only 1 per map ideally)
	_add_building(result, Vector3(center.x, 0, center.z), 0.0, _pick(landmark, crng))
	# Helipad nearby
	_add_building(result, Vector3(center.x + 30, 0, center.z + 20), 0.0, "helipad")
	# Field hospital tent
	_add_building(result, Vector3(center.x - 25, 0, center.z + 15), 0.0, "field_hospital_tent")
	# Barriers around perimeter
	_scatter_props(result, PROP_POOLS.military, min_x, min_z, w, d, int(w * d / 300.0), crng, MIN_SETBACK + 5.0)

# === HELPER: scatter foliage in specific area ===
static func _scatter_foliage_in_area(result: Dictionary, pool: Array, area_x: float, area_z: float, area_w: float, area_d: float, count: int, crng: RandomNumberGenerator):
	if pool.is_empty() or count <= 0 or area_w <= 0 or area_d <= 0:
		return
	for _i in range(count):
		var fx: float = area_x + crng.randf() * area_w
		var fz: float = area_z + crng.randf() * area_d
		_add_foliage(result, Vector3(fx, 0, fz), crng.randf() * 360.0, _pick(pool, crng), crng.randf_range(0.8, 1.3))
