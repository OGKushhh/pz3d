# Loop 3 — Reference-Driven Generation
#
# Phase F.3: Given reference profile targets (from mood images or manual spec),
# sweep config parameters to find the closest match.
#
# Usage:
#   var result = RefLoop3.sweep(config, roads, spatial, path_query, city_plan, map_data, target_profile)
#   # result = {best_config, best_distance, all_results}
#
# The target_profile is a PackedFloat32Array from PlanMetrics.profile():
#   [density, diversity, foliage_coverage, prop_density, walkability, fill_ratio]
#
# You provide it by analyzing reference images or specifying desired values.

class_name RefLoop3
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")
const CityGenConfig = preload("res://tools/city_gen_config.gd")
const ChunkPlanner = preload("res://tools/chunk_planner.gd")
const PlanMetrics = preload("res://tools/plan_metrics.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const PathQuery = preload("res://tools/path_query.gd")

# Default reference profiles per biome (from style guide + mood references)
# These are the "target" profiles — what we want each biome to look like.
# Format: [density, diversity, foliage_coverage, prop_density, walkability, fill_ratio]
const REFERENCE_PROFILES := {
	CityConfig.Biome.SUBURBIA: [0.15, 0.6, 0.8, 0.4, 0.9, 0.5],
	CityConfig.Biome.PARKS: [0.02, 0.3, 3.0, 0.5, 0.5, 0.1],
	CityConfig.Biome.FOREST: [0.02, 0.3, 4.0, 0.1, 0.3, 0.1],
	CityConfig.Biome.FARMLAND: [0.05, 0.4, 1.0, 0.3, 0.6, 0.2],
	CityConfig.Biome.COMMERCIAL: [0.3, 0.5, 0.2, 0.8, 0.9, 0.7],
	CityConfig.Biome.INDUSTRIAL: [0.2, 0.4, 0.3, 0.5, 0.7, 0.5],
	CityConfig.Biome.WETLANDS: [0.01, 0.2, 3.5, 0.1, 0.2, 0.05],
	CityConfig.Biome.DOWNTOWN: [0.4, 0.5, 0.1, 0.6, 0.95, 0.8],
	CityConfig.Biome.MILITARY: [0.1, 0.4, 0.4, 0.4, 0.6, 0.3],
	CityConfig.Biome.COASTAL_BEACH: [0.05, 0.4, 2.0, 0.3, 0.5, 0.15],
}

# Run a parameter sweep for a single biome
# Tests different density_mult + foliage_mult values, finds closest to target
static func sweep_biome(
	biome: int,
	roads, city_plan: Dictionary, map_data: Dictionary,
	target_profile: PackedFloat32Array
) -> Dictionary:
	var results: Array = []
	var best_distance: float = 9999.0
	var best_config: Dictionary = {}
	
	# Sweep: density_mult from 0.5 to 2.0 in steps of 0.25 (7 values)
	#        foliage_mult from 0.5 to 2.0 in steps of 0.25 (7 values)
	# Total: 49 combinations per biome
	var density_mults: Array = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
	var foliage_mults: Array = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
	
	print("[RefLoop3] Sweeping biome %d: %d combinations" % [biome, density_mults.size() * foliage_mults.size()])
	
	for d_mult in density_mults:
		for f_mult in foliage_mults:
			# Create config with these multipliers
			var config = CityGenConfig.new()
			config.seed = 1337
			config.density_mult = d_mult
			config.foliage_mult = f_mult
			
			# Evaluate this biome with these settings
			var metrics = PlanMetrics.evaluate_biome(biome, config, roads, SpatialIndex.new(CityConfig.SPATIAL_CELL_M), PathQuery.new(), city_plan, map_data)
			
			# Compute profile distance
			var current_profile = PackedFloat32Array([
				float(metrics.get("avg_density", 0.0)),
				float(metrics.get("avg_diversity", 0.0)),
				float(metrics.get("avg_foliage_coverage", 0.0)) if metrics.has("avg_foliage_coverage") else float(metrics.get("total_foliage", 0)) / 1000.0,
				float(metrics.get("avg_prop_density", 0.0)) if metrics.has("avg_prop_density") else float(metrics.get("total_props", 0)) / 1000.0,
				float(metrics.get("avg_walkability", 0.0)),
				float(metrics.get("avg_fill_ratio", 0.0)) if metrics.has("avg_fill_ratio") else float(metrics.get("total_buildings", 0)) / float(max(metrics.get("total_lots", 1), 1)),
			])
			
			var dist = PlanMetrics.profile_distance(current_profile, target_profile)
			
			results.append({
				"density_mult": d_mult,
				"foliage_mult": f_mult,
				"distance": dist,
				"buildings": metrics.get("total_buildings", 0),
				"rejections": metrics.get("total_rejections", 0),
			})
			
			if dist < best_distance:
				best_distance = dist
				best_config = {"density_mult": d_mult, "foliage_mult": f_mult}
	
	# Sort by distance
	results.sort_custom(func(a, b): return a.distance < b.distance)
	
	return {
		"biome": biome,
		"best_config": best_config,
		"best_distance": best_distance,
		"top_5": results.slice(0, 5),
		"all_results": results,
	}

# Run sweep for all biomes
static func sweep_all(roads, city_plan: Dictionary, map_data: Dictionary) -> Dictionary:
	var all_results: Dictionary = {}
	var biomes: Array = [
		CityConfig.Biome.SUBURBIA, CityConfig.Biome.PARKS, CityConfig.Biome.FOREST,
		CityConfig.Biome.FARMLAND, CityConfig.Biome.COMMERCIAL, CityConfig.Biome.INDUSTRIAL,
		CityConfig.Biome.WETLANDS, CityConfig.Biome.DOWNTOWN, CityConfig.Biome.MILITARY,
		CityConfig.Biome.COASTAL_BEACH,
	]
	
	for biome in biomes:
		var target = PackedFloat32Array(REFERENCE_PROFILES.get(biome, [0.1, 0.5, 1.0, 0.3, 0.7, 0.3]))
		var result = sweep_biome(biome, roads, city_plan, map_data, target)
		all_results[biome] = result
		print("[RefLoop3] Biome %d: best dist=%.3f config=%s" % [biome, result.best_distance, result.best_config])
	
	return all_results
