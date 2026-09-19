# PlanMetrics — evaluates a chunk plan against objective criteria.
#
# Phase F.3: Foundation for Loop 3 (reference-driven) + Loop 4 (convergence).
# Given a plan Dictionary from ChunkPlanner, computes metrics that can be:
#   - Compared to reference profiles (Loop 3)
#   - Checked against hard constraints (Loop 4)
#
# Metrics computed:
#   density: buildings per 1000m² (buildings / chunk_area * 1000)
#   diversity: unique asset types / total buildings (0..1, higher = more varied)
#   foliage_coverage: foliage count / chunk_area * 1000
#   prop_density: props per 1000m²
#   walkability: lots with road access / total lots (0..1)
#   rejection_rate: rejections / (buildings + rejections) (0..1, lower = better)
#   fill_ratio: buildings / target (how close to density target)
#   type_distribution: {asset_name: count} for diversity analysis
#
# Usage:
#   var metrics = PlanMetrics.evaluate(plan)
#   print("density:", metrics.density, "diversity:", metrics.diversity)

class_name PlanMetrics
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

static func evaluate(plan: Dictionary) -> Dictionary:
	var buildings: Array = plan.get("buildings", [])
	var foliage: Array = plan.get("foliage", [])
	var props: Array = plan.get("props", [])
	var lots: Array = plan.get("lots", [])
	var rejections: Array = plan.get("rejections", [])
	var stats: Dictionary = plan.get("stats", {})
	var biome: int = plan.get("biome", 0)
	
	var chunk_area: float = CityConfig.CHUNK_SIZE_M * CityConfig.CHUNK_SIZE_M  # 62500 m²
	
	# Building count
	var bldg_count: int = buildings.size()
	
	# Density: buildings per 1000m²
	var density: float = float(bldg_count) / (chunk_area / 1000.0)
	
	# Diversity: unique asset types / total buildings
	var type_set: Dictionary = {}
	for b in buildings:
		var name: String = b.get("asset_name", "")
		type_set[name] = true
	var diversity: float = float(type_set.size()) / float(max(bldg_count, 1))
	
	# Foliage coverage
	var foliage_count: int = foliage.size()
	var foliage_coverage: float = float(foliage_count) / (chunk_area / 1000.0)
	
	# Prop density
	var prop_count: int = props.size()
	var prop_density: float = float(prop_count) / (chunk_area / 1000.0)
	
	# Walkability: lots with road access (road_distance > 0) / total lots
	var lots_with_road: int = 0
	for lot in lots:
		if float(lot.get("road_distance", 0.0)) > 0.1:
			lots_with_road += 1
	var walkability: float = float(lots_with_road) / float(max(lots.size(), 1))
	
	# Rejection rate
	var total_attempts: int = bldg_count + rejections.size()
	var rejection_rate: float = float(rejections.size()) / float(max(total_attempts, 1))
	
	# Fill ratio: actual buildings / target (from stats)
	# We don't have the target in the plan directly, but we can estimate:
	# target = fill * biome_mult. We can compute fill_ratio = buildings / lots.size()
	var fill_ratio: float = float(bldg_count) / float(max(lots.size(), 1))
	
	# Type distribution
	var type_dist: Dictionary = {}
	for b in buildings:
		var name: String = b.get("asset_name", "")
		type_dist[name] = int(type_dist.get(name, 0)) + 1
	
	# Rejection reasons breakdown
	var rejection_reasons: Dictionary = {}
	for r in rejections:
		var reason: String = r.get("reason", "unknown")
		rejection_reasons[reason] = int(rejection_reasons.get(reason, 0)) + 1
	
	return {
		"biome": biome,
		"buildings": bldg_count,
		"foliage": foliage_count,
		"props": prop_count,
		"lots": lots.size(),
		"density": density,
		"diversity": diversity,
		"foliage_coverage": foliage_coverage,
		"prop_density": prop_density,
		"walkability": walkability,
		"rejection_rate": rejection_rate,
		"fill_ratio": fill_ratio,
		"type_distribution": type_dist,
		"rejection_reasons": rejection_reasons,
		"unique_types": type_set.size(),
	}

# Compute a numeric profile vector from metrics — used for distance comparison
# in Loop 3 (reference-driven generation).
# Returns a PackedFloat32Array so it can be compared via Euclidean distance.
static func profile(metrics: Dictionary) -> PackedFloat32Array:
	return PackedFloat32Array([
		float(metrics.get("density", 0.0)),
		float(metrics.get("diversity", 0.0)),
		float(metrics.get("foliage_coverage", 0.0)),
		float(metrics.get("prop_density", 0.0)),
		float(metrics.get("walkability", 0.0)),
		float(metrics.get("fill_ratio", 0.0)),
	])

# Euclidean distance between two profile vectors (lower = more similar)
static func profile_distance(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var sum: float = 0.0
	var n: int = min(a.size(), b.size())
	for i in n:
		var diff: float = a[i] - b[i]
		sum += diff * diff
	return sqrt(sum)

# Evaluate all chunks for a given biome and return aggregate metrics
# This is used by Loop 3/4 to evaluate a complete configuration
static func evaluate_biome(
	biome: int,
	config,
	roads, spatial, path_query,
	city_plan: Dictionary, map_data: Dictionary
) -> Dictionary:
	# Find all chunks for this biome
	var chunk_keys: Array = []
	for col in range(CityConfig.CHUNKS_COLS):
		for row in range(CityConfig.GRID_ROWS):
			var grid_col: int = clamp(int(col * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
			var grid_row: int = clamp(int(row * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
			var b: int = CityConfig.grid_layout()[grid_row][grid_col]
			if b == biome:
				chunk_keys.append([col, row])
	
	if chunk_keys.is_empty():
		return {"chunks": 0}
	
	# Plan + evaluate each chunk
	var all_metrics: Array = []
	var total_buildings: int = 0
	var total_foliage: int = 0
	var total_props: int = 0
	var total_rejections: int = 0
	var total_lots: int = 0
	var all_rejection_reasons: Dictionary = {}
	
	# Need fresh spatial index per chunk (planner mutates it)
	for key in chunk_keys:
		var col: int = key[0]
		var row: int = key[1]
		# Fresh spatial per chunk
		var chunk_spatial = preload("res://tools/spatial_index.gd").new(CityConfig.SPATIAL_CELL_M)
		var chunk_path_query = preload("res://tools/path_query.gd").new()
		# Re-add roads to spatial
		roads.mark_roads_in_index(chunk_spatial, CityConfig.SPATIAL_CELL_M)
		
		var plan = preload("res://tools/chunk_planner.gd").plan_chunk(
			col, row, config, roads, chunk_spatial, chunk_path_query, city_plan, map_data
		)
		var m = evaluate(plan)
		all_metrics.append(m)
		total_buildings += m.buildings
		total_foliage += m.foliage
		total_props += m.props
		total_rejections += plan.get("rejections", []).size()
		total_lots += m.lots
		for reason in m.get("rejection_reasons", {}):
			all_rejection_reasons[reason] = int(all_rejection_reasons.get(reason, 0)) + int(m.rejection_reasons[reason])
	
	# Aggregate
	var avg_density: float = 0.0
	var avg_diversity: float = 0.0
	var avg_walkability: float = 0.0
	var avg_rejection_rate: float = 0.0
	for m in all_metrics:
		avg_density += m.density
		avg_diversity += m.diversity
		avg_walkability += m.walkability
		avg_rejection_rate += m.rejection_rate
	
	var count: int = all_metrics.size()
	avg_density /= max(count, 1)
	avg_diversity /= max(count, 1)
	avg_walkability /= max(count, 1)
	avg_rejection_rate /= max(count, 1)
	
	return {
		"biome": biome,
		"chunks": count,
		"total_buildings": total_buildings,
		"total_foliage": total_foliage,
		"total_props": total_props,
		"total_rejections": total_rejections,
		"total_lots": total_lots,
		"avg_density": avg_density,
		"avg_diversity": avg_diversity,
		"avg_walkability": avg_walkability,
		"avg_rejection_rate": avg_rejection_rate,
		"rejection_reasons": all_rejection_reasons,
		"per_chunk_metrics": all_metrics,
	}
