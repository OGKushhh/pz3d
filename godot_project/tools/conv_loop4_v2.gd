# ConvLoop4V2 — Convergence / Stopping Condition for V2 city gen.
#
# Phase F.4: Separates "hard problems" (must fix) from "preferences" (optional).
# Reports when all hard problems are resolved — that's when you stop iterating.
#
# Hard constraints (must pass, blocks plan from being baked):
#       - No block with buildings placed within MIN_SETBACK of road edge
#       - No empty urban/commercial/industrial/military blocks (wilderness districts exempt)
#       - No block with > 70% same asset type (anti-repetition)
#       - No block with > MAX_PER_TYPE buildings of same asset (anti-monotony)
#
# Soft preferences (optional, user decides):
#       - Density target per district (too sparse vs too dense)
#       - Diversity target per district (too uniform vs varied)
#       - Foliage coverage (too bare vs too lush)
#
# Usage:
#       var report = ConvLoop4V2.report(map_plan)
#       if report.hard_problems == 0:
#               print("OK to bake — all hard problems resolved.")
#               print("Remaining issues (%d) are preferences." % report.preferences)
#       else:
#               print("REFUSING to bake — %d hard problems remain:" % report.hard_problems)
#               for p in report.problems:
#                       if p.severity == "hard":
#                               print("  - %s" % p.description)

class_name ConvLoop4V2
extends RefCounted

const PlanMetricsV2 = preload("res://tools/plan_metrics_v2.gd")

# Hard constraint thresholds
const MAX_REPETITION := 0.7        # > 70% same asset = hard problem
const MAX_PER_TYPE := 5             # > 5 of same asset in one block = hard problem
const MIN_BUILDINGS_URBAN := 1      # urban blocks must have >= 1 building
const WILDERNESS_DISTRICTS := ["forest", "parks", "farmland"]

# Evaluate all blocks and classify problems as hard vs preference
static func report(map_plan: Dictionary) -> Dictionary:
	var plans: Array = map_plan.get("plans", [])
	var hard_problems: Array = []
	var preferences: Array = []
	var problems_log: Array = []

	for plan in plans:
		var m: Dictionary = PlanMetricsV2.evaluate(plan)
		var block_id: String = plan.get("id", "?")
		var district: String = m.district
		var is_wilderness: bool = district in WILDERNESS_DISTRICTS

		# === HARD CONSTRAINTS ===

		# 1. Road clearance: buildings must not be within MIN_SETBACK of road edge
		if m.road_clearance < 1.0:
			hard_problems.append({
				"block": block_id, "district": district,
				"type": "road_clearance", "value": m.road_clearance,
				"severity": "hard",
				"description": "%s block %s has a building within %.0fm of road" % [district, block_id, PlanMetricsV2.MIN_SETBACK]
			})
			problems_log.append({"severity": "hard", "description": "%s block %s has a building within %.0fm of road" % [district, block_id, PlanMetricsV2.MIN_SETBACK]})

		# 2. Empty urban block (wilderness districts exempt — they're meant to be sparse)
		if m.buildings == 0 and not is_wilderness:
			hard_problems.append({
				"block": block_id, "district": district,
				"type": "empty_block", "value": 0,
				"severity": "hard",
				"description": "%s block %s has 0 buildings (non-wilderness district)" % [district, block_id]
			})
			problems_log.append({"severity": "hard", "description": "%s block %s has 0 buildings (non-wilderness district)" % [district, block_id]})

		# 3. Repetition: > MAX_REPETITION same asset type in a block with > 3 buildings
		if m.repetition > MAX_REPETITION and m.buildings > 3:
			hard_problems.append({
				"block": block_id, "district": district,
				"type": "repetition", "value": m.repetition,
				"threshold": MAX_REPETITION, "severity": "hard",
				"description": "%s block %s has %.0f%% same asset type (%d/%d buildings)" % [district, block_id, m.repetition * 100.0, int(m.repetition * m.buildings), m.buildings]
			})
			problems_log.append({"severity": "hard", "description": "%s block %s has %.0f%% same asset type" % [district, block_id, m.repetition * 100.0]})

		# 4. Max per type: more than MAX_PER_TYPE of same asset in one block
		var type_dist: Dictionary = m.type_distribution
		for asset_name in type_dist:
			var count: int = int(type_dist[asset_name])
			if count > MAX_PER_TYPE:
				hard_problems.append({
					"block": block_id, "district": district,
					"type": "max_per_type", "value": count,
					"threshold": MAX_PER_TYPE, "asset": asset_name, "severity": "hard",
					"description": "%s block %s has %d of %s (max %d)" % [district, block_id, count, asset_name, MAX_PER_TYPE]
				})
				problems_log.append({"severity": "hard", "description": "%s block %s has %d of %s" % [district, block_id, count, asset_name]})

		# === SOFT PREFERENCES ===

		# Low density (non-wilderness)
		if not is_wilderness and m.density < 0.5 and m.buildings > 0:
			preferences.append({
				"block": block_id, "district": district,
				"type": "low_density", "value": m.density,
				"severity": "preference",
				"description": "%s block %s low density (%.1f/1000m²)" % [district, block_id, m.density]
			})

		# Low diversity (non-wilderness, must have > 3 buildings for diversity to matter)
		if not is_wilderness and m.diversity < 0.3 and m.buildings > 3:
			preferences.append({
				"block": block_id, "district": district,
				"type": "low_diversity", "value": m.diversity,
				"severity": "preference",
				"description": "%s block %s low diversity (%.2f)" % [district, block_id, m.diversity]
			})

	# Aggregate stats
	var map_metrics: Dictionary = PlanMetricsV2.evaluate_map(map_plan)

	return {
		"hard_problems": hard_problems.size(),
		"preferences": preferences.size(),
		"hard_problem_list": hard_problems,
		"preference_list": preferences,
		"problems_log": problems_log,
		"map_metrics": map_metrics,
		"blocks_evaluated": plans.size(),
		"ok_to_bake": hard_problems.size() == 0,
	}

# Pretty-print a report summary
static func print_summary(report: Dictionary) -> void:
	print("=== ConvLoop4V2 — Convergence Report ===")
	print("  Blocks evaluated: %d" % report.blocks_evaluated)
	print("  Hard problems:    %d" % report.hard_problems)
	print("  Preferences:      %d" % report.preferences)
	print("  OK to bake:       %s" % ("YES" if report.ok_to_bake else "NO"))

	if report.hard_problems > 0:
		print("")
		print("  HARD PROBLEMS (must fix before bake):")
		# Show first 20 hard problems to avoid spam
		var hard: Array = report.hard_problem_list
		var n: int = min(hard.size(), 20)
		for i in range(n):
			print("    - %s" % hard[i].description)
		if hard.size() > n:
			print("    ... and %d more" % (hard.size() - n))

	if report.preferences > 0:
		print("")
		print("  PREFERENCES (optional, user decides):")
		var prefs: Array = report.preference_list
		var n: int = min(prefs.size(), 10)
		for i in range(n):
			print("    - %s" % prefs[i].description)
		if prefs.size() > n:
			print("    ... and %d more" % (prefs.size() - n))

	# Per-district breakdown
	print("")
	print("  Per-district breakdown:")
	var reports: Array = report.map_metrics.get("district_reports", [])
	# Sort by district name
	reports.sort_custom(func(a, b): return a.district < b.district)
	for dr in reports:
		print("    %s: %d blocks, %d buildings, %d foliage, %d props, density=%.2f/1000m², rep=%.0f%%, empty=%d, road_clr_fail=%d" % [
			dr.district, dr.blocks, dr.buildings, dr.foliage, dr.props,
			dr.density, dr.avg_repetition * 100.0, dr.empty_blocks, dr.road_clearance_failures
		])

	print("=========================================")
