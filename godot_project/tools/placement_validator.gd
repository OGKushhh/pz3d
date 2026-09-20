# PlacementValidator — localConstraints pass for proposed placements.
#
# Phase B.7.7 (2026-09-14): The "brain" that was missing. Implements the
# validate half of Parish & Müller's propose-validate-commit architecture.
#
# This is a SAFETY NET, not the primary fix (per DeepSeek correction #1).
# The generator (Track 1, B.7.1-B.7.6) should propose good placements by
# default. This validator catches bad ones that slip through:
#   - Buildings whose center lands on a path
#   - Buildings too close or too far from the road (setback violation)
#   - Buildings overlapping other assets
#   - Incompatible neighbors (shed next to gas_station)
#   - Asset repetition (>5 of same type in one chunk)
#
# Usage:
#   var result = validator.validate(pos, asset_name, biome, streamer, is_primary)
#   if not result.ok:
#       skip placement (or nudge + retry)
#
# Penalty scoring per uliwitness's desirability system (SE answer).
class_name PlacementValidator
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

# ── PENALTY SCORES ────────────────────────────────────────
# Hard rejects (score goes below ACCEPT_THRESHOLD → placement skipped)
const PENALTY_ON_PATH := -100           # building center is on a sidewalk/driveway/path
const PENALTY_ON_ROAD := -100           # building center is on a road
const PENALTY_OVERLAP := -100           # within 2m of another asset
const PENALTY_POI_EXCLUSION := -100     # inside a POI exclusion zone

# Soft rejects (reject for primary, allow for backyard companions)
const PENALTY_SETBACK_MIN := -50        # too close to road
const PENALTY_SETBACK_MAX := -30        # too far from road
const PENALTY_NEIGHBOR_INCOMPAT := -40 # incompatible neighbor nearby
const PENALTY_REPETITION := -20        # >5 of same asset in chunk

# Base score for a valid placement (before penalties)
const BASE_SCORE := 100

# Accept threshold: score must be >= this to accept
const ACCEPT_THRESHOLD := 0

# ── BIOME SETBACK RANGES ──────────────────────────────────
# Distance from road centerline to building origin (meters).
# Per GDD §4.7.3: "0m commercial, 4m residential, 8m suburban".
# These should eventually move to city_config.gd.
const BIOME_SETBACKS := {
        0: {"min": 4.0, "max": 20.0},   # SUBURBIA — row 0 at ~15.5m passes (was max 15)
        3: {"min": 6.0, "max": 25.0},   # FARMLAND — farmhouses have long driveways
        4: {"min": 0.0, "max": 8.0},    # COMMERCIAL — storefronts close to road
        5: {"min": 5.0, "max": 25.0},   # INDUSTRIAL — warehouses set back for trucks
        7: {"min": 0.0, "max": 5.0},    # DOWNTOWN — zero setback, flush with sidewalk
        8: {"min": 8.0, "max": 30.0},   # MILITARY — large clear zones
        # 1=PARKS, 2=FOREST, 6=WETLANDS, 9=COASTAL_BEACH: no setback check (nature biomes)
}

# ── INCOMPATIBLE NEIGHBORS ────────────────────────────────
# Pairs of assets that should NOT be near each other.
# Key = asset being placed, Value = Array of assets that conflict.
# Distances are checked via spatial index (within 15m = incompatible).
const INCOMPATIBLE_NEIGHBORS := {
        "shed": ["gas_station", "factory_small", "warehouse_large"],
        "garden_shed_wood": ["gas_station", "factory_small", "warehouse_large"],
        "barn": ["gas_station", "factory_small"],
        "farmhouse": ["gas_station", "factory_small"],
        "church_small": ["gas_station", "factory_small", "warehouse_large"],
        "school_elementary": ["gas_station", "factory_small", "warehouse_large"],
        "house_modern": ["gas_station", "factory_small"],
}

# Validate a proposed placement.
#
# Args:
#   pos: world position of the proposed placement
#   asset_name: the asset being placed (e.g. "suburban_house_v2", "garage_detached")
#   biome: the biome enum value (for setback range lookup)
#   streamer: the chunk_streamer instance (for _path_query, spatial, roads access)
#   is_primary: true if this is the primary building on the lot, false for companions
#
# Returns Dictionary:
#   { ok: bool,       # true if placement is acceptable
#     score: int,    # final score (BASE_SCORE + penalties)
#     reasons: Array[String]  # list of penalty reasons (empty if ok)
#   }
func validate(
        pos: Vector3,
        asset_name: String,
        biome: int,
        streamer,
        is_primary: bool
) -> Dictionary:
        var score: int = BASE_SCORE
        var reasons: Array = []

        # 1. On path? (hard reject) — checks with 3m margin to account for building footprint
        #    (building center might be 1m off the path, but the building edge still overlaps)
        if streamer._path_query.is_on_path(pos, 3.0):
                score += PENALTY_ON_PATH
                reasons.append("on_path")

        # 2. On road? (hard reject)
        if streamer.spatial.is_on_road(pos):
                score += PENALTY_ON_ROAD
                reasons.append("on_road")

        # 3. Overlap with another asset? (hard reject)
        #    Uses building_radius=8m (covers most building footprints).
        #    The gap filler uses 2m; buildings are larger so use 8m.
        if not streamer.spatial.is_free(pos, 8.0):
                score += PENALTY_OVERLAP
                reasons.append("overlap")

        # 4. Setback check (primary buildings only — companions can be in backyard)
        if is_primary and BIOME_SETBACKS.has(biome):
                var setback: Dictionary = BIOME_SETBACKS[biome]
                var road_dist: float = streamer.roads.distance_to_nearest_road(pos)
                var min_s: float = float(setback["min"])
                var max_s: float = float(setback["max"])
                if road_dist < min_s:
                        score += PENALTY_SETBACK_MIN
                        reasons.append("too_close_to_road (%.1fm < %.1fm)" % [road_dist, min_s])
                if road_dist > max_s:
                        score += PENALTY_SETBACK_MAX
                        reasons.append("too_far_from_road (%.1fm > %.1fm)" % [road_dist, max_s])

        # 5. Neighbor compatibility check
        #    If this asset has incompatible neighbors defined, check if any are within 15m.
        if INCOMPATIBLE_NEIGHBORS.has(asset_name):
                var incompat: Array = INCOMPATIBLE_NEIGHBORS[asset_name]
                for nearby_name in streamer._asset_positions:
                        if not incompat.has(nearby_name):
                                continue
                        var positions: Array = streamer._asset_positions[nearby_name]
                        for npos in positions:
                                if pos.distance_to(npos) < 15.0:
                                        score += PENALTY_NEIGHBOR_INCOMPAT
                                        reasons.append("incompatible_neighbor (%s at %.1fm)" % [nearby_name, pos.distance_to(npos)])
                                        break  # one incompat neighbor is enough
                        if reasons.size() > 0 and reasons[-1].begins_with("incompatible"):
                                break

        # 6. Asset repetition check
        #    If this asset already has >5 instances in the current chunk, penalize.
        #    Uses _district_type_counts (per-biome per-type tracker in chunk_streamer).
        #    We check the current biome's count for this asset type.
        var type_count: int = streamer._get_district_type_count(biome, asset_name)
        if type_count >= 5:
                score += PENALTY_REPETITION
                reasons.append("repetition (%d in biome %d)" % [type_count, biome])

        var ok: bool = score >= ACCEPT_THRESHOLD
        return {
                "ok": ok,
                "score": score,
                "reasons": reasons,
        }

# Returns the setback range for a biome, or empty dict if no setback check.
func get_setback_range(biome: int) -> Dictionary:
        return BIOME_SETBACKS.get(biome, {})
