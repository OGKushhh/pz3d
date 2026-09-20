# PlanMetricsV2 — evaluates a V2 block plan against objective criteria.
#
# Phase F.4 (Loop 4) foundation. Given a plan Dictionary from CityGenV2.plan_block,
# computes metrics that can be:
#	- Checked against hard constraints (ConvLoop4V2)
#	- Compared to reference profiles (future Loop 3)
#
# Metrics computed per block:
#	buildings: count of buildings placed
#	foliage: count of foliage placed
#	props: count of props placed
#	density: buildings per 1000m² (buildings / block_area * 1000)
#	diversity: unique asset types / total buildings (0..1, higher = more varied)
#	repetition: max single asset type / total buildings (0..1, lower = better)
#	prop_density: props per 1000m²
#	foliage_coverage: foliage per 1000m²
#	type_distribution: {asset_name: count} for diversity analysis
#	road_clearance: 1.0 if no buildings within MIN_SETBACK of block edge, 0.0 if violated
#
# Usage:
#	var metrics = PlanMetricsV2.evaluate(plan)
#	print("density:", metrics.density, "diversity:", metrics.diversity)

class_name PlanMetricsV2
extends RefCounted

# Minimum setback from block edge (matches BlockRecipes.MIN_SETBACK)
const MIN_SETBACK := 7.0

static func evaluate(plan: Dictionary) -> Dictionary:
	var buildings: Array = plan.get("buildings", [])
	var foliage: Array = plan.get("foliage", [])
	var props: Array = plan.get("props", [])
	var w: float = float(plan.get("width", 0.0))
	var d: float = float(plan.get("depth", 0.0))
	var district: String = plan.get("district", "")
	var block_min: Vector2 = plan.get("min", Vector2.ZERO)
	var block_max: Vector2 = plan.get("max", Vector2.ZERO)

	var block_area: float = w * d  # m²
	if block_area <= 0.0:
		block_area = 1.0  # avoid div-by-zero

	var bldg_count: int = buildings.size()
	var foliage_count: int = foliage.size()
	var prop_count: int = props.size()

	# Density: buildings per 1000m²
	var density: float = float(bldg_count) / (block_area / 1000.0)

	# Diversity: unique asset types / total buildings
	var type_counts: Dictionary = {}
	for b in buildings:
		var name: String = b.get("asset_name", "")
		type_counts[name] = int(type_counts.get(name, 0)) + 1
	var diversity: float = float(type_counts.size()) / float(max(bldg_count, 1))

	# Repetition: max single asset type / total buildings (lower is better)
	var max_type_count: int = 0
	for name in type_counts:
		max_type_count = max(max_type_count, int(type_counts[name]))
	var repetition: float = float(max_type_count) / float(max(bldg_count, 1))

	# Foliage coverage: foliage per 1000m²
	var foliage_coverage: float = float(foliage_count) / (block_area / 1000.0)

	# Prop density: props per 1000m²
	var prop_density: float = float(prop_count) / (block_area / 1000.0)

	# Road clearance: 1.0 if no buildings within MIN_SETBACK of block edge, 0.0 if violated
	var road_clearance: float = 1.0
	for b in buildings:
		var pos: Vector3 = b.get("pos", Vector3.ZERO)
		var dist_n: float = abs(pos.z - block_min.y)
		var dist_s: float = abs(pos.z - block_max.y)
		var dist_e: float = abs(pos.x - block_max.x)
		var dist_w: float = abs(pos.x - block_min.x)
		var min_dist: float = min(min(dist_n, dist_s), min(dist_e, dist_w))
		if min_dist < MIN_SETBACK - 0.5:  # 0.5m tolerance
			road_clearance = 0.0
			break

	return {
		"buildings": bldg_count,
		"foliage": foliage_count,
		"props": prop_count,
		"density": density,
		"diversity": diversity,
		"repetition": repetition,
		"foliage_coverage": foliage_coverage,
		"prop_density": prop_density,
		"road_clearance": road_clearance,
		"type_distribution": type_counts,
		"block_area": block_area,
		"district": district,
	}

# Aggregate metrics across all blocks in a map plan
static func evaluate_map(map_plan: Dictionary) -> Dictionary:
	var plans: Array = map_plan.get("plans", [])
	if plans.is_empty():
		return {"hard_problems": 0, "blocks_evaluated": 0}

	var total_buildings: int = 0
	var total_foliage: int = 0
	var total_props: int = 0
	var total_area: float = 0.0
	var district_metrics: Dictionary = {}  # district -> aggregated metrics
	var hard_problems: int = 0
	var preferences: int = 0

	for plan in plans:
		var m: Dictionary = evaluate(plan)
		var district: String = m.district
		total_buildings += m.buildings
		total_foliage += m.foliage
		total_props += m.props
		total_area += m.block_area

		# Aggregate by district
		if not district_metrics.has(district):
			district_metrics[district] = {
				"blocks": 0, "buildings": 0, "foliage": 0, "props": 0,
				"area": 0.0, "diversity_sum": 0.0, "repetition_sum": 0.0,
				"road_clearance_failures": 0, "empty_blocks": 0,
			}
		var dm: Dictionary = district_metrics[district]
		dm.blocks += 1
		dm.buildings += m.buildings
		dm.foliage += m.foliage
		dm.props += m.props
		dm.area += m.block_area
		dm.diversity_sum += m.diversity
		dm.repetition_sum += m.repetition
		if m.road_clearance < 1.0:
			dm.road_clearance_failures += 1
		if m.buildings == 0:
			dm.empty_blocks += 1

	# Compute per-district averages + classify problems
	var district_reports: Array = []
	for district in district_metrics:
		var dm: Dictionary = district_metrics[district]
		var avg_diversity: float = dm.diversity_sum / float(max(dm.blocks, 1))
		var avg_repetition: float = dm.repetition_sum / float(max(dm.blocks, 1))
		var density: float = float(dm.buildings) / (dm.area / 1000.0)

		var report := {
			"district": district,
			"blocks": dm.blocks,
			"buildings": dm.buildings,
			"foliage": dm.foliage,
			"props": dm.props,
			"density": density,
			"avg_diversity": avg_diversity,
			"avg_repetition": avg_repetition,
			"road_clearance_failures": dm.road_clearance_failures,
			"empty_blocks": dm.empty_blocks,
		}
		district_reports.append(report)

		# Classify hard problems (per district)
		# 1. Empty blocks in non-wilderness districts (should have buildings)
		var wilderness := ["forest", "parks", "farmland"]
		if district not in wilderness and dm.empty_blocks > 0:
			hard_problems += dm.empty_blocks

		# 2. Road clearance failures (building on road)
		hard_problems += dm.road_clearance_failures

		# 3. Repetition > 0.7 in non-wilderness (too much same-asset)
		if district not in wilderness and avg_repetition > 0.7 and dm.buildings > 3:
			hard_problems += 1

		# Preferences (not hard)
		if district not in wilderness and density < 0.5:
			preferences += 1  # too sparse
		if district not in wilderness and avg_diversity < 0.3 and dm.buildings > 3:
			preferences += 1  # too uniform

	return {
		"district_reports": district_reports,
		"hard_problems": hard_problems,
		"preferences": preferences,
		"blocks_evaluated": plans.size(),
		"total_buildings": total_buildings,
		"total_foliage": total_foliage,
		"total_props": total_props,
		"total_area": total_area,
	}
