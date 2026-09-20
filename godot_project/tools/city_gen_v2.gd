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

# === BLOCK PLANNING ===
# Plan a single block: parcels, buildings, foliage, props.
static func plan_block(block: Dictionary, seed: int) -> Dictionary:
	var district: String = block.district
	var props: Dictionary = DISTRICT_PROPS.get(district, DISTRICT_PROPS["suburbia"])
	var center: Vector3 = block.center
	var w: float = block.width
	var d: float = block.depth
	var lot_w: float = props.lot_w
	var lot_d: float = props.lot_d
	var setback: float = props.setback
	var fill: float = props.fill
	
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
		"rejections": [],
	}
	
	# === Place buildings in a grid pattern within the block ===
	# Leave setback from road edges
	var usable_x: float = w - setback * 2.0
	var usable_z: float = d - setback * 2.0
	if usable_x < lot_w or usable_z < lot_d:
		# Block too small for buildings — just add foliage/props
		plan_foliage_and_props(plan, props, center, w, d, crng)
		return plan
	
	var cols: int = int(usable_x / lot_w)
	var rows: int = int(usable_z / lot_d)
	var buildings_placed: int = 0
	var type_counts: Dictionary = {}
	var building_pool: Array = props.get("buildings", [])
	
	if building_pool.is_empty():
		plan_foliage_and_props(plan, props, center, w, d, crng)
		return plan
	
	for row in range(rows):
		for col in range(cols):
			if crng.randf() > fill:
				continue  # empty lot
			
			# Calculate building position (relative to block min corner + setback)
			var bx: float = block.min.x + setback + col * lot_w + lot_w * 0.5
			var bz: float = block.min.y + setback + row * lot_d + lot_d * 0.5
			var pos := Vector3(bx, 0, bz)
			
			# Anti-repetition: max 3 of same type per block
			var bname: String = ""
			for _attempt in range(3):
				var candidate: String = building_pool[crng.randi() % building_pool.size()]
				if int(type_counts.get(candidate, 0)) < 3:
					bname = candidate
					break
			if bname == "":
				continue
			
			# Face nearest road edge
			var rot_y: float = 0.0
			# Check which edge is nearest (N/S/E/W)
			var dist_n: float = abs(bz - block.min.y)
			var dist_s: float = abs(bz - block.max.y)
			var dist_e: float = abs(bx - block.max.x)
			var dist_w: float = abs(bx - block.min.x)
			var min_dist: float = min(min(dist_n, dist_s), min(dist_e, dist_w))
			if min_dist == dist_n:
				rot_y = 180.0  # face north (-Z)
			elif min_dist == dist_s:
				rot_y = 0.0  # face south (+Z)
			elif min_dist == dist_e:
				rot_y = 270.0  # face east (+X)
			else:
				rot_y = 90.0  # face west (-X)
			
			plan["buildings"].append({
				"pos": pos,
				"rot_y": rot_y,
				"asset_name": bname,
			})
			type_counts[bname] = int(type_counts.get(bname, 0)) + 1
			buildings_placed += 1
	
	# Add foliage + props
	plan_foliage_and_props(plan, props, center, w, d, crng)
	
	return plan

# Fill block with foliage + props based on district
static func plan_foliage_and_props(plan: Dictionary, props: Dictionary, center: Vector3, w: float, d: float, crng: RandomNumberGenerator) -> void:
	var foliage_pool: Array = props.get("foliage", [])
	var prop_pool: Array = props.get("props", [])
	
	# Foliage: forest/parks get lots, urban gets little
	var foliage_count: int = 0
	match plan.district:
		"forest": foliage_count = int(w * d / 800.0)  # dense
		"parks": foliage_count = int(w * d / 1200.0)
		"farmland": foliage_count = int(w * d / 4000.0)
		"suburbia": foliage_count = int(w * d / 2000.0)
		_: foliage_count = int(w * d / 8000.0)
	
	if not foliage_pool.is_empty():
		for i in range(foliage_count):
			var fx: float = center.x - w * 0.5 + crng.randf() * w
			var fz: float = center.z - d * 0.5 + crng.randf() * d
			var fname: String = foliage_pool[crng.randi() % foliage_pool.size()]
			var scale: float = crng.randf_range(0.8, 1.3)
			plan["foliage"].append({"pos": Vector3(fx, 0, fz), "rot_y": crng.randf() * 360.0, "asset_name": fname, "scale": scale})
	
	# Props
	var prop_count: int = int(w * d / 800.0)
	if not prop_pool.is_empty():
		for i in range(prop_count):
			var px: float = center.x - w * 0.5 + crng.randf() * w
			var pz: float = center.z - d * 0.5 + crng.randf() * d
			var pname: String = prop_pool[crng.randi() % prop_pool.size()]
			plan["props"].append({"pos": Vector3(px, 0, pz), "rot_y": crng.randf() * 360.0, "asset_name": pname})

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
	
	# 5. Plan each block
	var plans: Array = []
	for block in blocks:
		var plan := plan_block(block, seed)
		plans.append(plan)
	
	var t1 := Time.get_ticks_msec()
	
	# 6. Aggregate stats
	var total_buildings: int = 0
	var total_foliage: int = 0
	var total_props: int = 0
	for plan in plans:
		total_buildings += plan.buildings.size()
		total_foliage += plan.foliage.size()
		total_props += plan.props.size()
	
	print("[CityGenV2] Plan complete: %dms" % (t1 - t0))
	print("[CityGenV2]   Buildings: %d, Foliage: %d, Props: %d" % [total_buildings, total_foliage, total_props])
	
	return {
		"roads": roads,
		"blocks": blocks,
		"plans": plans,
		"stats": {
			"roads": roads.size(),
			"blocks": blocks.size(),
			"buildings": total_buildings,
			"foliage": total_foliage,
			"props": total_props,
			"plan_time_ms": t1 - t0,
		},
	}
