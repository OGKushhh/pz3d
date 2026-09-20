# RefLoop3V2 — Loop 3: reference-driven convergence.
#
# Phase F.3: minimize distance between generated plan and a reference profile.
#
# Pipeline:
#	1. Extract a PROFILE (numeric metrics) from each reference image (top-down map photo
#	   of a real city district). Stored in res://data/reference_profiles.json.
#	2. Compute PROFILE of each generated district (from our V2 plan).
#	3. Compute DISTANCE between generated profile and reference profile.
#	4. Report: per district, distance + which tuning would reduce it.
#
# Profiles are 6-dimensional vectors (each normalized to 0..1):
#	- density:        buildings per 1000m²
#	- height:         avg building footprint size (proxy for height_class)
#	- foliage:        foliage per 1000m²
#	- prop_density:   props per 1000m²
#	- road_coverage:  road surface ratio (proxy: road_count_per_block_area)
#	- diversity:      unique asset types / total buildings
#
# Distance = euclidean distance in 6D profile space (0 = perfect match, 1 = max).
#
# Reference images: stored in docs/style/map_references/
# We extract profiles via VLM (vision model) — see scripts/extract_reference_profiles.gd

class_name RefLoop3V2
extends RefCounted

const PlanMetricsV2 = preload("res://tools/plan_metrics_v2.gd")

# === PROFILE NORMALIZATION CONSTANTS ===
# Each metric is normalized to 0..1 so distances are comparable.
# These are the "max reasonable" values — anything above = clamped to 1.0.
const MAX_DENSITY := 5.0          # buildings per 1000m² (very dense downtown)
const MAX_FOLIAGE := 30.0          # foliage per 1000m² (dense forest)
const MAX_PROP_DENSITY := 20.0    # props per 1000m² (busy commercial)
const MAX_DIVERSITY := 1.0        # already 0..1
const MAX_HEIGHT_PROXY := 100.0   # footprint avg in m² (large warehouse)

# === COMPUTE PROFILE from generated plan (per district) ===
# Returns Dictionary with 6 normalized metrics + raw values for debugging.
static func profile_district(plans: Array, district: String) -> Dictionary:
	var district_plans: Array = plans.filter(func(p): return p.district == district)
	if district_plans.is_empty():
		return _empty_profile()

	var total_buildings: int = 0
	var total_foliage: int = 0
	var total_props: int = 0
	var total_area: float = 0.0
	var type_set: Dictionary = {}
	var footprint_sum: float = 0.0

	for plan in district_plans:
		var m: Dictionary = PlanMetricsV2.evaluate(plan)
		total_buildings += m.buildings
		total_foliage += m.foliage
		total_props += m.props
		total_area += m.block_area
		for asset_name in m.type_distribution:
			type_set[asset_name] = true
		# Estimate footprint from block area / buildings (very rough)
		if m.buildings > 0:
			footprint_sum += m.block_area / float(m.buildings)

	var area_k: float = total_area / 1000.0  # m² -> thousands of m²
	if area_k <= 0.0:
		return _empty_profile()

	# Raw values
	var raw_density: float = float(total_buildings) / area_k
	var raw_foliage: float = float(total_foliage) / area_k
	var raw_prop_density: float = float(total_props) / area_k
	var raw_diversity: float = float(type_set.size()) / float(max(total_buildings, 1))
	var raw_height_proxy: float = footprint_sum / float(max(district_plans.size(), 1))

	# Normalized (0..1)
	var n_density: float = clamp(raw_density / MAX_DENSITY, 0.0, 1.0)
	var n_foliage: float = clamp(raw_foliage / MAX_FOLIAGE, 0.0, 1.0)
	var n_prop: float = clamp(raw_prop_density / MAX_PROP_DENSITY, 0.0, 1.0)
	var n_diversity: float = clamp(raw_diversity / MAX_DIVERSITY, 0.0, 1.0)
	var n_height: float = clamp(raw_height_proxy / MAX_HEIGHT_PROXY, 0.0, 1.0)
	# road_coverage: skip for now, no road-per-block data per district
	var n_road: float = 0.5  # placeholder neutral value

	return {
		"district": district,
		"blocks": district_plans.size(),
		"buildings": total_buildings,
		"foliage": total_foliage,
		"props": total_props,
		"area_m2": total_area,
		"raw": {
			"density": raw_density,
			"foliage": raw_foliage,
			"prop_density": raw_prop_density,
			"diversity": raw_diversity,
			"height_proxy": raw_height_proxy,
		},
		"normalized": {
			"density": n_density,
			"foliage": n_foliage,
			"prop_density": n_prop,
			"diversity": n_diversity,
			"height_proxy": n_height,
			"road_coverage": n_road,
		},
	}

# === COMPUTE DISTANCE between two profiles (0 = perfect match, sqrt(6) ≈ 2.45 = max) ===
# Uses euclidean distance in 6D normalized profile space.
static func profile_distance(p1: Dictionary, p2: Dictionary) -> float:
	var n1: Dictionary = p1.get("normalized", {})
	var n2: Dictionary = p2.get("normalized", {})
	if n1.is_empty() or n2.is_empty():
		return 99.0  # very far if one is missing

	var keys: Array = ["density", "foliage", "prop_density", "diversity", "height_proxy", "road_coverage"]
	var sum_sq: float = 0.0
	for k in keys:
		var v1: float = float(n1.get(k, 0.0))
		var v2: float = float(n2.get(k, 0.0))
		var diff: float = v1 - v2
		sum_sq += diff * diff
	return sqrt(sum_sq)

# === LOAD reference profiles from JSON ===
# Stored at res://data/reference_profiles.json (built by scripts/extract_reference_profiles.gd)
static func load_reference_profiles() -> Dictionary:
	var path := "res://data/reference_profiles.json"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json_text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		return {}
	return parsed

# === REPORT: for each district, compute distance to reference profile ===
# Returns {district: {distance, generated, reference, recommendations}}
static func report(map_plan: Dictionary) -> Dictionary:
	var plans: Array = map_plan.get("plans", [])
	var ref_profiles: Dictionary = load_reference_profiles()

	var districts_seen: Dictionary = {}
	for plan in plans:
		districts_seen[plan.district] = true

	var reports: Array = []
	var total_distance: float = 0.0
	var n_compared: int = 0

	for district in districts_seen:
		var generated: Dictionary = profile_district(plans, district)
		var report_entry: Dictionary = {
			"district": district,
			"generated": generated,
			"reference": {},
			"distance": -1.0,
			"has_reference": false,
			"recommendations": [],
		}

		if ref_profiles.has(district):
			var ref: Dictionary = ref_profiles[district]
			report_entry.reference = ref
			report_entry.distance = profile_distance(generated, ref)
			report_entry.has_reference = true
			report_entry.recommendations = _recommendations(generated, ref)
			total_distance += report_entry.distance
			n_compared += 1

		reports.append(report_entry)

	return {
		"reports": reports,
		"avg_distance": total_distance / float(max(n_compared, 1)),
		"n_compared": n_compared,
		"n_total_districts": districts_seen.size(),
	}

# === RECOMMENDATIONS: which tuning would reduce distance to reference? ===
static func _recommendations(generated: Dictionary, reference: Dictionary) -> Array:
	var recs: Array = []
	var n_gen: Dictionary = generated.get("normalized", {})
	var n_ref: Dictionary = reference.get("normalized", {})

	var keys_with_direction: Dictionary = {
		"density":      {"low": "increase fill %", "high": "decrease fill %"},
		"foliage":       {"low": "add more foliage", "high": "remove foliage"},
		"prop_density": {"low": "add more props", "high": "remove props"},
		"diversity":     {"low": "increase recipe variety", "high": "limit asset pool"},
		"height_proxy": {"low": "use bigger buildings", "high": "use smaller buildings"},
	}

	for k in keys_with_direction:
		var v_gen: float = float(n_gen.get(k, 0.0))
		var v_ref: float = float(n_ref.get(k, 0.0))
		var diff: float = v_ref - v_gen
		if abs(diff) < 0.05:
			continue  # close enough, no recommendation
		var direction: String = "low" if diff > 0 else "high"
		var rec: String = "%s: gen=%.2f ref=%.2f -> %s" % [
			k, v_gen, v_ref, keys_with_direction[k][direction]
		]
		recs.append(rec)

	return recs

# === PRETTY-PRINT a Loop 3 report ===
static func print_summary(report: Dictionary) -> void:
	print("=== RefLoop3V2 — Reference-Driven Report ===")
	print("  Districts compared: %d/%d" % [report.n_compared, report.n_total_districts])
	print("  Average distance:  %.3f (0=perfect, 2.45=max)" % report.avg_distance)
	print("")
	print("  Per-district distance:")
	for entry in report.reports:
		var d: String = entry.district
		if entry.has_reference:
			print("    %s: distance=%.3f" % [d, entry.distance])
		else:
			print("    %s: no reference profile" % d)
	print("")

	# Recommendations for districts with biggest distance
	print("  Recommendations (top 5):")
	var sorted: Array = (report.reports as Array).duplicate()
	sorted.sort_custom(func(a, b):
		if not a.has_reference: return false
		if not b.has_reference: return true
		return a.distance > b.distance
	)
	var n: int = min(sorted.size(), 5)
	for i in range(n):
		var e: Dictionary = sorted[i]
		if not e.has_reference:
			continue
		print("    %s (dist=%.3f):" % [e.district, e.distance])
		for rec in e.recommendations:
			print("      - %s" % rec)
	print("=========================================")

# Empty profile (when district has no plans)
static func _empty_profile() -> Dictionary:
	return {
		"district": "",
		"blocks": 0,
		"buildings": 0,
		"foliage": 0,
		"props": 0,
		"area_m2": 0.0,
		"raw": {},
		"normalized": {},
	}
