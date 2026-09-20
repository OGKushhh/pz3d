# Loop 4 — Convergence / Stopping Condition
#
# Phase F.4: Separates "hard problems" (must fix) from "preferences" (optional).
# Reports when all hard problems are resolved — that's when you stop iterating.
#
# Hard constraints (must pass):
#   - walkability > 0.5 (at least half of lots have road access)
#   - rejection_rate < 0.5 (less than half of placement attempts rejected)
#   - No chunk with 0 buildings in non-wilderness biomes (Suburbia, Commercial, Downtown, Industrial)
#   - No chunk with >50% same asset type (anti-repetition enforced)
#
# Soft preferences (optional, user decides):
#   - density target (too sparse vs too dense)
#   - diversity target (too uniform vs varied)
#   - foliage coverage (too bare vs too lush)
#   - fill ratio (empty lots ratio)
#
# Usage:
#   var report = ConvLoop4.report(config, roads, city_plan, map_data)
#   print(report.summary)
#   if report.hard_problems == 0:
#       print("All hard problems resolved. Remaining issues are preferences.")
#       print("Consider stopping iteration.")

class_name ConvLoop4
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")
const CityGenConfig = preload("res://tools/city_gen_config.gd")
const PlanMetrics = preload("res://tools/plan_metrics.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const PathQuery = preload("res://tools/path_query.gd")
const ChunkPlanner = preload("res://tools/chunk_planner.gd")

# Evaluate all chunks and classify problems as hard vs preference
static func report(
        config: CityGenConfig,
        roads, city_plan: Dictionary, map_data: Dictionary
) -> Dictionary:
        var hard_problems: Array = []
        var preferences: Array = []
        var hard_resolved: int = 0
        var total_chunks: int = 0
        var biome_names = {
                CityConfig.Biome.SUBURBIA: "Suburbia", CityConfig.Biome.PARKS: "Parks",
                CityConfig.Biome.FOREST: "Forest", CityConfig.Biome.FARMLAND: "Farmland",
                CityConfig.Biome.COMMERCIAL: "Commercial", CityConfig.Biome.INDUSTRIAL: "Industrial",
                CityConfig.Biome.WETLANDS: "Wetlands", CityConfig.Biome.DOWNTOWN: "Downtown",
                CityConfig.Biome.MILITARY: "Military", CityConfig.Biome.COASTAL_BEACH: "Coastal",
        }
        var wilderness_biomes = [CityConfig.Biome.PARKS, CityConfig.Biome.FOREST, CityConfig.Biome.WETLANDS, CityConfig.Biome.COASTAL_BEACH]
        
        # Evaluate each chunk
        for col in range(CityConfig.CHUNKS_COLS):
                for row in range(CityConfig.CHUNKS_ROWS):
                        var grid_col: int = clamp(int(col * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
                        var grid_row: int = clamp(int(row * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
                        var biome: int = CityConfig.grid_layout()[grid_row][grid_col]
                        if biome == CityConfig.Biome.WATER or biome == CityConfig.Biome.EMPTY:
                                continue
                        
                        total_chunks += 1
                        var chunk_spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
                        var chunk_path_query = PathQuery.new()
                        roads.mark_roads_in_index(chunk_spatial, CityConfig.SPATIAL_CELL_M)
                        
                        var plan = ChunkPlanner.plan_chunk(col, row, config, roads, chunk_spatial, chunk_path_query, city_plan, map_data)
                        var m = PlanMetrics.evaluate(plan)
                        var bname: String = biome_names.get(biome, str(biome))
                        var chunk_id: String = "%d_%d" % [col, row]
                        
                        # === HARD CONSTRAINTS ===
                        
                        # 1. Walkability: > 0.5 (at least half of lots have road access)
                        if m.walkability < 0.5 and not biome in wilderness_biomes:
                                hard_problems.append({
                                        "chunk": chunk_id, "biome": bname,
                                        "type": "walkability", "value": m.walkability,
                                        "threshold": 0.5, "reason": "less than half of lots have road access"
                                })
                        else:
                                hard_resolved += 1
                        
                        # 2. Rejection rate: < 0.5 (less than half of attempts rejected)
                        if m.rejection_rate > 0.5:
                                hard_problems.append({
                                        "chunk": chunk_id, "biome": bname,
                                        "type": "rejection_rate", "value": m.rejection_rate,
                                        "threshold": 0.5, "reason": "more than half of placement attempts rejected",
                                        "reasons": m.get("rejection_reasons", {})
                                })
                        else:
                                hard_resolved += 1
                        
                        # 3. No chunk with 0 buildings in non-wilderness biomes
                        if m.buildings == 0 and not biome in wilderness_biomes:
                                hard_problems.append({
                                        "chunk": chunk_id, "biome": bname,
                                        "type": "empty_chunk", "value": 0,
                                        "threshold": 1, "reason": "non-wilderness chunk has 0 buildings"
                                })
                        else:
                                hard_resolved += 1
                        
                        # 4. No chunk with >50% same asset type (only check chunks with 4+ buildings)
                        var max_type_count: int = 0
                        var max_type_name: String = ""
                        for type_name in m.get("type_distribution", {}):
                                var count: int = int(m.type_distribution[type_name])
                                if count > max_type_count:
                                        max_type_count = count
                                        max_type_name = type_name
                        if m.buildings > 3 and float(max_type_count) / float(m.buildings) > 0.5:
                                hard_problems.append({
                                        "chunk": chunk_id, "biome": bname,
                                        "type": "repetition", "value": float(max_type_count) / float(m.buildings),
                                        "threshold": 0.5, "reason": "more than 50%% of buildings are %s (%d/%d)" % [max_type_name, max_type_count, m.buildings]
                                })
                        else:
                                hard_resolved += 1
                        
                        # === SOFT PREFERENCES ===
                        
                        # Density: too sparse (below 0.05 for urban, below 0.01 for wilderness)
                        if m.density < 0.05 and not biome in wilderness_biomes:
                                preferences.append({"chunk": chunk_id, "biome": bname, "type": "low_density", "value": m.density})
                        if m.density > 0.5:
                                preferences.append({"chunk": chunk_id, "biome": bname, "type": "high_density", "value": m.density})
                        
                        # Diversity: too uniform
                        if m.diversity < 0.2 and m.buildings > 3:
                                preferences.append({"chunk": chunk_id, "biome": bname, "type": "low_diversity", "value": m.diversity})
                        
                        # Foliage: too bare for nature biomes
                        if biome in [CityConfig.Biome.FOREST, CityConfig.Biome.PARKS, CityConfig.Biome.WETLANDS] and m.foliage < 10:
                                preferences.append({"chunk": chunk_id, "biome": bname, "type": "low_foliage", "value": m.foliage})
        
        var hard_count: int = hard_problems.size()
        var pref_count: int = preferences.size()
        var all_hard_resolved: bool = hard_count == 0
        
        var summary: String
        if all_hard_resolved:
                summary = "✅ All hard problems resolved (%d/%d checks passed). %d preferences remain.\nConsider stopping iteration — remaining issues are aesthetic." % [hard_resolved, hard_resolved + hard_count, pref_count]
        else:
                summary = "⚠️ %d hard problems found (%d/%d checks passed). %d preferences remain.\nFix hard problems first." % [hard_count, hard_resolved, hard_resolved + hard_count, pref_count]
        
        return {
                "hard_problems": hard_problems,
                "preferences": preferences,
                "hard_count": hard_count,
                "preference_count": pref_count,
                "hard_resolved": hard_resolved,
                "total_checks": hard_resolved + hard_count,
                "all_hard_resolved": all_hard_resolved,
                "summary": summary,
                "total_chunks": total_chunks,
        }
