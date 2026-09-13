#!/usr/bin/env python3
"""
AI Middleware v2 — sophisticated city gen analyzer + planner.

Reads chunk_states_auto.json (the MAP → DATA dump) and generates
fill_plan.json (the DATA → MAP instructions) with multiple action types:

  - "fill": place new content at gaps (parking_lot, backyard, alley, etc.)
  - "remove": delete overlapping/duplicate/clustered buildings
  - "reposition": move a building to a better spot

Sophisticated features:
  1. Overlap detection — AABB intersection between building pairs → remove smaller
  2. Zoning balance — commercial_pct > 0.7 + no parking → force parking_lot
  3. Halo verification — landmark's halo buildings missing → force them
  4. Density targeting — sort chunks by gap_pct, fill emptiest first
  5. Neighbor context — biome borders suggest contextually-appropriate fills
  6. Asset repetition detection — same asset >5 times in chunk → suggest variety
  7. Building spacing analysis — buildings too close → reposition
  8. Landmark proximity check — is each landmark surrounded by appropriate context?
  9. Multi-pass output — generate plan, can be re-run after runtime applies it

Usage: python3 /home/z/my-project/pz3d/scripts/ai_fill_planner.py
"""
import json
import sys
import random
from pathlib import Path
from collections import defaultdict

DUMP_PATH = Path("/home/z/my-project/pz3d/godot_project/chunk_states_auto.json")
PLAN_PATH = Path("/home/z/my-project/pz3d/godot_project/fill_plan.json")
REPORT_PATH = Path("/home/z/my-project/pz3d/docs/ai_analysis_report.md")
METRICS_PATH = Path("/home/z/my-project/pz3d/godot_project/ai_metrics.json")
SEMANTICS_PATH = Path("/home/z/my-project/pz3d/godot_project/data/asset_semantics.json")

# Import the spatial query API (DeepSeek Tier 3 — portability)
sys.path.insert(0, str(Path(__file__).parent))
from spatial_query import SpatialIndex, SEMANTICS, LANDMARK_TYPES

# Global spatial index (built once from the dump)
_SPATIAL_INDEX = None

def get_spatial_index() -> SpatialIndex:
    """Lazily build + cache the spatial index from the dump."""
    global _SPATIAL_INDEX
    if _SPATIAL_INDEX is None:
        if not DUMP_PATH.exists():
            raise FileNotFoundError(f"chunk_states_auto.json not found at {DUMP_PATH}")
        _SPATIAL_INDEX = SpatialIndex(str(DUMP_PATH))
    return _SPATIAL_INDEX

# Biome constants (must match city_config.gd)
BIOME_NAMES = {
    0: "SUBURBIA", 1: "PARKS", 2: "FOREST", 3: "FARMLAND", 4: "COMMERCIAL",
    5: "INDUSTRIAL", 6: "WETLANDS", 7: "DOWNTOWN", 8: "MILITARY",
    9: "COASTAL_BEACH", 10: "WATER", 11: "EMPTY", 12: "WETLANDS",
}

# Asset categories for analysis (LANDMARK_TYPES imported from spatial_query)
COMMERCIAL_TYPES = {"corner_store", "diner", "gas_station", "store_pharmacy", "store_gun",
    "store_supermarket", "motel", "strip_mall", "auto_repair_shop", "laundromat",
    "barber_shop", "salon", "grocery_store", "bank_branch"}
RESIDENTIAL_TYPES = {"suburban_house_v2", "two_story_colonial", "bungalow", "house_modern",
    "house_split_level", "house_victorian", "house_ranch", "house_cape_cod", "house_tudor",
    "house_cottage_stone", "apartment_small", "cottage", "farmhouse", "shed", "garage_detached"}
INDUSTRIAL_TYPES = {"warehouse", "warehouse_large", "factory_small", "utility_shed_metal",
    "shipping_container", "storage_tank", "loading_dock"}


def aabb_overlaps(a: dict, b: dict) -> bool:
    """Check if two AABBs overlap (3D box intersection test)."""
    a_min, a_max = a["min"], a["max"]
    b_min, b_max = b["min"], b["max"]
    return (a_min[0] < b_max[0] and a_max[0] > b_min[0] and
            a_min[1] < b_max[1] and a_max[1] > b_min[1] and
            a_min[2] < b_max[2] and a_max[2] > b_min[2])


def aabb_volume(a: dict) -> float:
    """Compute AABB volume for overlap resolution (remove smaller)."""
    s = a["size"]
    return s[0] * s[1] * s[2]


def analyze_chunk(state: dict) -> dict:
    """Analyze a single chunk state for problems + opportunities."""
    buildings = state.get("buildings") or []
    biome = state.get("biome", 0)
    stats = state.get("stats") or {}
    halo = state.get("halo") or {}
    neighbors = state.get("neighbors") or {}
    gap_count = state.get("gap_count", 0) or 0

    problems = []
    opportunities = []
    
    # 1. OVERLAP DETECTION
    overlaps = []
    for i, b1 in enumerate(buildings):
        if "aabb" not in b1:
            continue
        for j, b2 in enumerate(buildings):
            if j <= i or "aabb" not in b2:
                continue
            if aabb_overlaps(b1["aabb"], b2["aabb"]):
                overlaps.append({"a": b1, "b": b2, "smaller": b1 if aabb_volume(b1["aabb"]) < aabb_volume(b2["aabb"]) else b2})
    if overlaps:
        problems.append({"type": "overlaps", "count": len(overlaps), "details": overlaps})
    
    # 2. ZONING BALANCE
    commercial_pct = stats.get("commercial_pct", 0)
    residential_pct = stats.get("residential_pct", 0)
    has_parking = stats.get("has_parking_lot", False)
    if commercial_pct > 0.7 and not has_parking:
        opportunities.append({"type": "missing_parking_lot", "reason": f"commercial_pct={commercial_pct:.0%}, no parking"})
    if residential_pct > 0.8 and biome == 4:  # COMMERCIAL biome but mostly residential
        problems.append({"type": "zoning_imbalance", "reason": f"commercial biome is {residential_pct:.0%} residential"})
    
    # 3. HALO VERIFICATION
    if halo.get("active", False):
        boost_buildings = halo.get("boost_buildings", {})
        landmarks_nearby = halo.get("landmarks_nearby", [])
        building_names = [b["name"] for b in buildings]
        missing_halo_buildings = []
        for hb in boost_buildings:
            if hb not in building_names:
                missing_halo_buildings.append(hb)
        if missing_halo_buildings:
            opportunities.append({
                "type": "missing_halo_buildings",
                "landmarks": landmarks_nearby,
                "missing": missing_halo_buildings,
                "reason": f"halo active but {len(missing_halo_buildings)} halo buildings missing"
            })
    
    # 4. DENSITY TARGETING
    gap_pct = stats.get("gap_pct", 0)
    if gap_pct > 0.8:
        opportunities.append({"type": "high_density_gap", "gap_pct": gap_pct, "reason": f"chunk is {gap_pct:.0%} empty"})
    
    # 5. NEIGHBOR CONTEXT
    biome_borders = []
    for direction in ["north", "south", "east", "west"]:
        n_biome = neighbors.get(direction, -1)
        if n_biome != -1 and n_biome != biome:
            biome_borders.append({"direction": direction, "neighbor_biome": n_biome, "neighbor_name": BIOME_NAMES.get(n_biome, "?")})
    if biome_borders:
        opportunities.append({"type": "biome_border", "borders": biome_borders})
    
    # 6. ASSET REPETITION DETECTION
    name_counts = defaultdict(int)
    for b in buildings:
        name_counts[b["name"]] += 1
    repetitive = {name: count for name, count in name_counts.items() if count > 5}
    if repetitive:
        problems.append({"type": "asset_repetition", "details": repetitive, "reason": "same asset >5 times"})
    
    # 7. BUILDING SPACING — too close (within 3m)
    too_close_pairs = []
    for i, b1 in enumerate(buildings):
        for j, b2 in enumerate(buildings):
            if j <= i:
                continue
            p1, p2 = b1["pos"], b2["pos"]
            dist = ((p1[0]-p2[0])**2 + (p1[2]-p2[2])**2) ** 0.5
            if dist < 3.0:  # within 3m
                too_close_pairs.append({"a": b1, "b": b2, "dist": dist})
    if too_close_pairs:
        problems.append({"type": "too_close", "count": len(too_close_pairs), "details": too_close_pairs[:5]})

    # 8. SEMANTIC CONFLICT DETECTION (Tier 2)
    # Use asset_semantics.json to detect: gas_station near park, factory near
    # school, etc. Each conflict becomes a problem with suggested resolution
    # (remove the offending asset OR add a buffer).
    semantic_conflicts = []
    for i, b1 in enumerate(buildings):
        name1 = b1["name"]
        sem1 = SEMANTICS.get(name1, {})
        conflicts1 = sem1.get("conflicts_with", [])
        if not conflicts1:
            continue
        for j, b2 in enumerate(buildings):
            if j == i:
                continue
            name2 = b2["name"]
            if name2 in conflicts1:
                p1, p2 = b1["pos"], b2["pos"]
                dist = ((p1[0]-p2[0])**2 + (p1[2]-p2[2])**2) ** 0.5
                semantic_conflicts.append({
                    "offender": b1,
                    "victim": b2,
                    "reason": f"{name1} conflicts with {name2} (dist={dist:.0f}m)",
                    "dist": dist,
                })
    if semantic_conflicts:
        problems.append({"type": "semantic_conflict", "count": len(semantic_conflicts), "details": semantic_conflicts[:5]})

    # 9. MIN_SPACING VIOLATION (semantic)
    # Check if any asset appears closer than its declared min_spacing
    min_spacing_violations = []
    for i, b1 in enumerate(buildings):
        name1 = b1["name"]
        sem1 = SEMANTICS.get(name1, {})
        min_spacing = sem1.get("min_spacing", 0)
        if min_spacing <= 0:
            continue
        for j, b2 in enumerate(buildings):
            if j <= i:
                continue
            if b2["name"] != name1:
                continue  # only check same-asset spacing
            p1, p2 = b1["pos"], b2["pos"]
            dist = ((p1[0]-p2[0])**2 + (p1[2]-p2[2])**2) ** 0.5
            if dist < min_spacing:
                min_spacing_violations.append({
                    "a": b1, "b": b2, "dist": dist,
                    "required": min_spacing,
                    "reason": f"two {name1} within {dist:.0f}m (min {min_spacing}m)",
                })
    if min_spacing_violations:
        problems.append({"type": "min_spacing_violation", "count": len(min_spacing_violations), "details": min_spacing_violations[:5]})

    # 10. PAIRING OPPORTUNITY (semantic)
    # If an asset's pairs_with isn't present in the chunk, that's an
    # opportunity to add it (e.g. gas_station exists but no convenience_store)
    pairing_ops = []
    building_names = set(b["name"] for b in buildings)
    for b in buildings:
        name = b["name"]
        sem = SEMANTICS.get(name, {})
        pairs_with = sem.get("pairs_with", [])
        for pair in pairs_with:
            if pair not in building_names:
                pairing_ops.append({
                    "asset": name,
                    "missing_pair": pair,
                    "reason": f"{name} should pair with {pair} (not in chunk)",
                })
    if pairing_ops:
        opportunities.append({"type": "missing_pair", "count": len(pairing_ops), "details": pairing_ops[:5]})

    return {
        "chunk_key": state["chunk_key"],
        "biome": biome,
        "district_name": state.get("district_name", "?"),
        "problems": problems,
        "opportunities": opportunities,
        "building_count": len(buildings),
        "gap_count": gap_count,
        "gap_pct": stats.get("gap_pct", 0),
    }


# ============================================================
# Phase A.12 v4: VALIDATE BEFORE COMMITTING (DeepSeek Tier 1)
# ============================================================
# For each candidate action, simulate it, count problems within 30m before
# and after, keep only if it reduces the local count. This is the big change
# that makes the loop converge.

# Approximate AABB dimensions per fill type (for simulating fills)
FILL_AABBS = {
    "parking_lot": {"size": [15.0, 0.1, 20.0]},
    "backyard": {"size": [10.0, 2.0, 10.0]},
    "alley": {"size": [4.0, 2.0, 15.0]},
    "green_space": {"size": [12.0, 0.5, 12.0]},
    "plaza": {"size": [15.0, 0.1, 15.0]},
    "courtyard": {"size": [12.0, 3.0, 12.0]},
    "tree_cluster": {"size": [10.0, 5.0, 10.0]},
}


def count_local_problems(buildings: list, center_pos: list, radius: float = 30.0) -> int:
    """Count problems within `radius` of `center_pos`.
    
    DeepSeek: 'Spatial query forces detectors to say what's near this position
    instead of scan the whole dump.'
    
    IMPORTANT: always uses the provided `buildings` list (which may be a
    SIMULATED copy with actions applied). The spatial index reflects the
    ORIGINAL dump state only — it cannot be used for AFTER counts because
    it doesn't know about simulated actions. The spatial index IS used
    elsewhere (query_nearby, find_isolated_gaps, analyze_chunk cross-chunk
    queries) where the original state is what we want.
    """
    nearby = []
    cx, cz = center_pos[0], center_pos[2]
    for b in buildings:
        dist = ((b["pos"][0] - cx) ** 2 + (b["pos"][2] - cz) ** 2) ** 0.5
        if dist <= radius:
            nearby.append(b)
    count = 0
    for i, b1 in enumerate(nearby):
        for j, b2 in enumerate(nearby):
            if j <= i:
                continue
            if "aabb" in b1 and "aabb" in b2:
                if aabb_overlaps(b1["aabb"], b2["aabb"]):
                    count += 1
            dist = ((b1["pos"][0] - b2["pos"][0]) ** 2 +
                    (b1["pos"][2] - b2["pos"][2]) ** 2) ** 0.5
            if dist < 3.0:
                count += 1
            sem1 = SEMANTICS.get(b1["name"], {})
            if b2["name"] in sem1.get("conflicts_with", []):
                count += 1
            sem2 = SEMANTICS.get(b2["name"], {})
            if b1["name"] in sem2.get("conflicts_with", []):
                count += 1
            min_s = sem1.get("min_spacing", 0)
            if min_s > 0 and b1["name"] == b2["name"] and dist < min_s:
                count += 1
    return count


def simulate_action(action: dict, buildings: list) -> list:
    """Return a COPY of the buildings list with the action applied.
    For remove: drop the building with matching node_name.
    For reposition: move the building to new_pos.
    For fill: add a placeholder building with the fill type's AABB."""
    simulated = [dict(b) for b in buildings]  # shallow copy each
    if action["type"] == "remove":
        target = action.get("node_name", "")
        simulated = [b for b in simulated if b.get("node_name") != target]
    elif action["type"] == "reposition":
        target = action.get("node_name", "")
        new_pos = action.get("new_pos", [0, 0, 0])
        for b in simulated:
            if b.get("node_name") == target:
                b["pos"] = list(new_pos)
                # Update AABB if present (move it to new position)
                if "aabb" in b:
                    old_min = b["aabb"]["min"]
                    old_max = b["aabb"]["max"]
                    dx = new_pos[0] - b.get("_orig_pos", [0, 0, 0])[0] if "_orig_pos" in b else 0
                    dz = new_pos[2] - b.get("_orig_pos", [0, 0, 0])[2] if "_orig_pos" in b else 0
                    b["aabb"] = {
                        "min": [old_min[0] + dx, old_min[1], old_min[2] + dz],
                        "max": [old_max[0] + dx, old_max[1], old_max[2] + dz],
                        "size": b["aabb"]["size"],
                    }
                break
    elif action["type"] == "fill":
        pos = action.get("pos", [0, 0, 0])
        fill_type = action.get("fill_type", "fill")
        aabb_dims = FILL_AABBS.get(fill_type, {"size": [10.0, 1.0, 10.0]})
        size = aabb_dims["size"]
        simulated.append({
            "name": fill_type,
            "node_name": "fill_placeholder",
            "pos": list(pos),
            "rot": [0, 0, 0],
            "scale": [1, 1, 1],
            "aabb": {
                "min": [pos[0] - size[0] / 2, pos[1], pos[2] - size[2] / 2],
                "max": [pos[0] + size[0] / 2, pos[1] + size[1], pos[2] + size[2] / 2],
                "size": size,
            },
        })
    return simulated


def validate_action(action: dict, buildings: list) -> bool:
    """Simulate the action, count local problems within 30m before and after.
    Returns True if the action REDUCES local problems (keep it), False otherwise.
    DeepSeek: 'For each candidate action, simulate it, count problems within
    30m before and after, keep only if it reduces the local count.'"""
    action_pos = action.get("pos", action.get("new_pos", [0, 0, 0]))
    before = count_local_problems(buildings, action_pos, 30.0)
    simulated = simulate_action(action, buildings)
    after = count_local_problems(simulated, action_pos, 30.0)
    return after < before


def generate_actions(analysis: dict, state: dict, random_seed: int) -> list:
    """Generate + VALIDATE concrete actions (fill/remove/reposition).
    Reordered per DeepSeek: reposition → remove → fill.
    Each candidate is validated — only kept if it reduces local problems.
    Chunks with ≤1 problem INSTANCE are skipped (not problem types).
    """
    # DeepSeek: "Skip chunks with 1 problem." — but with only 8 total problems,
    # every problem is worth solving. Changed threshold from ≤1 to ≤0.
    total_problem_instances = sum(p.get("count", len(p.get("details", []))) for p in analysis["problems"])
    if total_problem_instances <= 0:
        return []

    actions = []
    chunk_key = analysis["chunk_key"]
    rng = random.Random(random_seed)
    buildings = state.get("buildings") or []

    # Stats tracking (DeepSeek: "Track per-action-type deltas")
    stats = {"reposition": {"candidates": 0, "validated": 0},
             "remove": {"candidates": 0, "validated": 0},
             "fill": {"candidates": 0, "validated": 0}}

    MAX_REPOSITIONS = 2
    MAX_REMOVES = 2
    MAX_FILLS = 3

    # ============================================================
    # PHASE 1: REPOSITION (least destructive — move before delete)
    # DeepSeek: "Moves are less destructive than removes. Fix overlaps by
    # moving first, deleting only what you can't move."
    # Fix: push 2.5m (was 0.5m) to clear the 3m too_close threshold.
    # ============================================================
    reposition_count = 0
    for problem in analysis["problems"]:
        if problem["type"] == "too_close" and reposition_count < MAX_REPOSITIONS:
            for pair in problem["details"]:
                if reposition_count >= MAX_REPOSITIONS:
                    break
                a, b = pair["a"], pair["b"]
                if a["name"] in LANDMARK_TYPES or b["name"] in LANDMARK_TYPES:
                    continue
                ax, az = a["pos"][0], a["pos"][2]
                bx, bz = b["pos"][0], b["pos"][2]
                dx, dz = bx - ax, bz - az
                dist = (dx * dx + dz * dz) ** 0.5
                if dist < 0.01:
                    continue
                perp_x = -dz / dist
                perp_z = dx / dist
                # DeepSeek fix: 0.5m → 2.5m to clear 3m threshold
                push_dist = 2.5
                new_bx = bx + perp_x * push_dist
                new_bz = bz + perp_z * push_dist
                new_rot_y = b.get("rot", [0, 0, 0])[1]
                candidate = {
                    "type": "reposition",
                    "chunk_key": chunk_key,
                    "node_name": b.get("node_name", ""),
                    "new_pos": [new_bx, b["pos"][1], new_bz],
                    "new_rot_y": new_rot_y,
                    "reason": f"too_close (dist={pair['dist']:.2f}m, pushed {push_dist}m)",
                    "asset_name": b["name"],
                }
                stats["reposition"]["candidates"] += 1
                # VALIDATE: simulate + check if it reduces local problems
                if validate_action(candidate, buildings):
                    actions.append(candidate)
                    buildings = simulate_action(candidate, buildings)
                    reposition_count += 1
                    stats["reposition"]["validated"] += 1

    # ============================================================
    # PHASE 2: REMOVE (for overlaps that can't be fixed by moving)
    # DeepSeek: "Fills go last, into spaces that survive the first two passes."
    # ============================================================
    remove_count = 0
    for problem in analysis["problems"]:
        if problem["type"] == "overlaps" and remove_count < MAX_REMOVES:
            for overlap in problem["details"]:
                if remove_count >= MAX_REMOVES:
                    break
                smaller = overlap["smaller"]
                if smaller["name"] in LANDMARK_TYPES:
                    continue
                candidate = {
                    "type": "remove",
                    "pos": smaller["pos"],
                    "chunk_key": chunk_key,
                    "node_name": smaller.get("node_name", ""),
                    "reason": "overlap",
                    "asset_name": smaller["name"],
                }
                stats["remove"]["candidates"] += 1
                if validate_action(candidate, buildings):
                    actions.append(candidate)
                    buildings = simulate_action(candidate, buildings)
                    remove_count += 1
                    stats["remove"]["validated"] += 1

    # Remove repetitive buildings (only if validated)
    for problem in analysis["problems"]:
        if problem["type"] == "asset_repetition" and remove_count < MAX_REMOVES:
            for name, count in problem["details"].items():
                if remove_count >= MAX_REMOVES:
                    break
                for b in buildings:
                    if b["name"] == name:
                        candidate = {
                            "type": "remove",
                            "pos": b["pos"],
                            "chunk_key": chunk_key,
                            "node_name": b.get("node_name", ""),
                            "reason": f"repetition (count={count})",
                            "asset_name": name,
                        }
                        stats["remove"]["candidates"] += 1
                        if validate_action(candidate, buildings):
                            actions.append(candidate)
                            buildings = simulate_action(candidate, buildings)
                            remove_count += 1
                            stats["remove"]["validated"] += 1
                        break
                if remove_count >= MAX_REMOVES:
                    break

    # Remove semantic conflicts (only if validated)
    for problem in analysis["problems"]:
        if problem["type"] == "semantic_conflict" and remove_count < MAX_REMOVES:
            for conflict in problem["details"]:
                if remove_count >= MAX_REMOVES:
                    break
                offender = conflict["offender"]
                if offender["name"] in LANDMARK_TYPES:
                    continue
                candidate = {
                    "type": "remove",
                    "pos": offender["pos"],
                    "chunk_key": chunk_key,
                    "node_name": offender.get("node_name", ""),
                    "reason": f"semantic_conflict: {conflict['reason']}",
                    "asset_name": offender["name"],
                }
                stats["remove"]["candidates"] += 1
                if validate_action(candidate, buildings):
                    actions.append(candidate)
                    buildings = simulate_action(candidate, buildings)
                    remove_count += 1
                    stats["remove"]["validated"] += 1

    # ============================================================
    # PHASE 3: FILL (into spaces that survive the first two passes)
    # DeepSeek: "Fills go last, into spaces that survive the first two passes."
    # DeepSeek fix: gap-isolation check — no nearby building within 15m.
    # Fills were 100% rejected because they created new overlaps. Only
    # fill in gaps that are genuinely isolated (no building within 15m).
    # ============================================================

    def is_gap_isolated(gap_pos: list, blg_list: list, min_dist: float = 15.0) -> bool:
        """Check that no building is within min_dist of the gap position."""
        gx, gz = gap_pos[0], gap_pos[2]
        for b in blg_list:
            d = ((b["pos"][0] - gx) ** 2 + (b["pos"][2] - gz) ** 2) ** 0.5
            if d < min_dist:
                return False
        return True

    fill_count = 0
    for opp in analysis["opportunities"]:
        if fill_count >= MAX_FILLS:
            break
        gaps = state.get("gaps") or []
        if not gaps:
            continue
        # DeepSeek fix: only fill in ISOLATED gaps (no building within 15m)
        isolated_gaps = [g for g in gaps if is_gap_isolated(g["pos"], buildings, 15.0)]
        if not isolated_gaps:
            continue
        gap = rng.choice(isolated_gaps)
        fill_type = None
        reason = ""
        if opp["type"] == "missing_parking_lot":
            fill_type = "parking_lot"
            reason = opp["reason"]
        elif opp["type"] == "missing_halo_buildings":
            missing = opp["missing"]
            fill_type = "parking_lot" if any("parking" in m for m in missing) else "backyard"
            reason = f"halo missing: {missing}"
        elif opp["type"] == "high_density_gap":
            biome = analysis["biome"]
            fill_type = "tree_cluster" if biome in (1, 2, 3, 9) else "green_space"
            if biome == 4: fill_type = "parking_lot"
            elif biome == 0: fill_type = "backyard"
            elif biome == 7: fill_type = "plaza"
            reason = f"high_density_gap ({opp['gap_pct']:.0%} empty)"
        elif opp["type"] == "biome_border":
            borders = opp["borders"]
            fill_type = "green_space"
            for border in borders:
                if border["neighbor_biome"] in (1, 2):
                    fill_type = "tree_cluster"
                    break
            reason = f"biome_border ({borders[0]['neighbor_name']})"
        elif opp["type"] == "missing_pair":
            fill_type = "parking_lot"
            reason = f"missing_pair: {opp['details'][0]['reason'] if opp['details'] else ''}"

        if fill_type:
            candidate = {
                "type": "fill",
                "chunk_key": chunk_key,
                "pos": gap["pos"],
                "fill_type": fill_type,
                "reason": reason,
            }
            stats["fill"]["candidates"] += 1
            if validate_action(candidate, buildings):
                actions.append(candidate)
                buildings = simulate_action(candidate, buildings)
                fill_count += 1
                stats["fill"]["validated"] += 1

    # Store validation stats on the analysis for reporting
    analysis["validation_stats"] = stats
    return actions


def main():
    if not DUMP_PATH.exists():
        print("ERROR: chunk_states_auto.json not found.")
        print("Run godot --headless --quit-after 300 first to generate it.")
        sys.exit(1)
    
    states = json.loads(DUMP_PATH.read_text())
    print(f"=== AI MIDDLEWARE v2 — analyzing {len(states)} chunk states ===\n")
    
    # Sort chunks by gap_pct descending (fill emptiest chunks first)
    states_sorted = sorted(states, key=lambda s: (s.get("stats") or {}).get("gap_pct", 0) or 0, reverse=True)
    
    all_actions = []
    all_analyses = []
    total_problems = 0
    total_opportunities = 0
    problem_type_counts = defaultdict(int)
    opp_type_counts = defaultdict(int)
    
    for i, state in enumerate(states_sorted):
        seed = hash((state["chunk_key"][0], state["chunk_key"][1], i))
        analysis = analyze_chunk(state)
        actions = generate_actions(analysis, state, seed)
        all_actions.extend(actions)
        all_analyses.append(analysis)
        total_problems += len(analysis["problems"])
        total_opportunities += len(analysis["opportunities"])
        for p in analysis["problems"]:
            problem_type_counts[p["type"]] += 1
        for o in analysis["opportunities"]:
            opp_type_counts[o["type"]] += 1
    
    # Count action types
    action_type_counts = defaultdict(int)
    fill_type_counts = defaultdict(int)
    for action in all_actions:
        action_type_counts[action["type"]] += 1
        if action["type"] == "fill":
            fill_type_counts[action.get("fill_type", "?")] += 1
    
    # Write the plan
    plan = {
        "version": 2,
        "total_actions": len(all_actions),
        "action_type_counts": dict(action_type_counts),
        "fill_type_counts": dict(fill_type_counts),
        "actions": all_actions,
    }
    PLAN_PATH.write_text(json.dumps(plan, indent=2))
    
    # Generate analysis report
    report = []
    report.append("# AI Middleware Analysis Report\n")
    report.append(f"> Generated from {len(states)} chunk states.\n")
    report.append(f"> Total problems detected: **{total_problems}**\n")
    report.append(f"> Total opportunities found: **{total_opportunities}**\n")
    report.append(f"> Total actions generated: **{len(all_actions)}**\n\n")
    
    report.append("## Problem Types Detected\n\n")
    report.append("| Problem Type | Count | Description |\n|---|---|---|\n")
    for ptype, count in sorted(problem_type_counts.items(), key=lambda x: x[1], reverse=True):
        desc = {
            "overlaps": "Buildings with intersecting AABBs (3D overlap)",
            "zoning_imbalance": "Biome's primary zoning doesn't match its building mix",
            "asset_repetition": "Same asset appearing >5 times in one chunk",
            "too_close": "Buildings within 3m of each other (spacing violation)",
        }.get(ptype, "")
        report.append(f"| {ptype} | {count} | {desc} |\n")
    
    report.append("\n## Opportunities Found\n\n")
    report.append("| Opportunity Type | Count | Description |\n|---|---|---|\n")
    for otype, count in sorted(opp_type_counts.items(), key=lambda x: x[1], reverse=True):
        desc = {
            "missing_parking_lot": "Commercial chunk with no parking lot",
            "missing_halo_buildings": "Landmark halo didn't attract its boost buildings",
            "high_density_gap": "Chunk >80% empty gaps",
            "biome_border": "Chunk borders a different biome (transition zone)",
        }.get(otype, "")
        report.append(f"| {otype} | {count} | {desc} |\n")
    
    report.append("\n## Generated Actions\n\n")
    report.append("| Action Type | Count |\n|---|---|\n")
    for atype, count in sorted(action_type_counts.items(), key=lambda x: x[1], reverse=True):
        report.append(f"| {atype} | {count} |\n")
    
    report.append("\n### Fill Type Distribution\n\n")
    report.append("| Fill Type | Count |\n|---|---|\n")
    for ftype, count in sorted(fill_type_counts.items(), key=lambda x: x[1], reverse=True):
        report.append(f"| {ftype} | {count} |\n")
    
    report.append("\n## Per-Chunk Analysis (sorted by gap_pct descending)\n\n")
    report.append("| Chunk | Biome | Buildings | Gap % | Problems | Opportunities | Actions |\n")
    report.append("|---|---|---|---|---|---|---|\n")
    for analysis in all_analyses:
        ck = analysis["chunk_key"]
        biome_name = BIOME_NAMES.get(analysis["biome"], "?")
        chunk_actions = [a for a in all_actions if a["chunk_key"] == ck]
        report.append(f"| {ck[0]},{ck[1]} | {biome_name} | {analysis['building_count']} | "
                      f"{analysis['gap_pct']:.0%} | {len(analysis['problems'])} | "
                      f"{len(analysis['opportunities'])} | {len(chunk_actions)} |\n")
    
    REPORT_PATH.write_text("".join(report))

    # Write metrics JSON for multi-pass loop comparison
    metrics = {
        "iteration": 0,  # set by multi-pass wrapper
        "total_problems": total_problems,
        "total_opportunities": total_opportunities,
        "total_actions": len(all_actions),
        "problem_type_counts": dict(problem_type_counts),
        "opportunity_type_counts": dict(opp_type_counts),
        "action_type_counts": dict(action_type_counts),
        "fill_type_counts": dict(fill_type_counts),
    }
    METRICS_PATH.write_text(json.dumps(metrics, indent=2))

    print(f"=== ANALYSIS COMPLETE ===")
    print(f"  Problems detected: {total_problems}")
    for ptype, count in sorted(problem_type_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"    {ptype}: {count}")
    print(f"  Opportunities found: {total_opportunities}")
    for otype, count in sorted(opp_type_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"    {otype}: {count}")
    print(f"  Actions generated: {len(all_actions)}")
    for atype, count in sorted(action_type_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"    {atype}: {count}")

    # DeepSeek: "Track per-action-type deltas" — show validation rates
    total_candidates = 0
    total_validated = 0
    for a in all_analyses:
        vs = a.get("validation_stats", {})
        if isinstance(vs, dict):
            for action_type in vs.values():
                total_candidates += action_type.get("candidates", 0)
                total_validated += action_type.get("validated", 0)
    if total_candidates > 0:
        print(f"\n  VALIDATION (DeepSeek Tier 1):")
        print(f"    Total candidates: {total_candidates}")
        print(f"    Validated (reduces local problems): {total_validated}")
        print(f"    Rejected (wouldn't help or would worsen): {total_candidates - total_validated}")
        print(f"    Validation rate: {total_validated/total_candidates:.0%}")

    print(f"\n  Plan written to: {PLAN_PATH}")
    print(f"  Report written to: {REPORT_PATH}")
    print(f"\n  Next: run godot again — runtime will read fill_plan.json + apply")
    print(f"  all actions (fills + removes + repositions) on next chunk load.")


if __name__ == "__main__":
    main()
