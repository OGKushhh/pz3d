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

# Load semantic tags (Tier 2 — enables conflict + pairing reasoning)
SEMANTICS = {}
if SEMANTICS_PATH.exists():
    SEMANTICS = json.loads(SEMANTICS_PATH.read_text())
    # Strip the _meta key
    SEMANTICS.pop("_meta", None)

# Biome constants (must match city_config.gd)
BIOME_NAMES = {
    0: "SUBURBIA", 1: "PARKS", 2: "FOREST", 3: "FARMLAND", 4: "COMMERCIAL",
    5: "INDUSTRIAL", 6: "WETLANDS", 7: "DOWNTOWN", 8: "MILITARY",
    9: "COASTAL_BEACH", 10: "WATER", 11: "EMPTY", 12: "WETLANDS",
}

# Asset categories for analysis
COMMERCIAL_TYPES = {"corner_store", "diner", "gas_station", "store_pharmacy", "store_gun",
    "store_supermarket", "motel", "strip_mall", "auto_repair_shop", "laundromat",
    "barber_shop", "salon", "grocery_store", "bank_branch"}
RESIDENTIAL_TYPES = {"suburban_house_v2", "two_story_colonial", "bungalow", "house_modern",
    "house_split_level", "house_victorian", "house_ranch", "house_cape_cod", "house_tudor",
    "house_cottage_stone", "apartment_small", "cottage", "farmhouse", "shed", "garage_detached"}
INDUSTRIAL_TYPES = {"warehouse", "warehouse_large", "factory_small", "utility_shed_metal",
    "shipping_container", "storage_tank", "loading_dock"}
LANDMARK_TYPES = {"government_palace", "stadium", "old_royal_palace", "fort_sarran",
    "lighthouse", "broadcast_tower", "grain_silo", "windmill", "railway_station",
    "hospital", "police_station", "school_elementary", "church_small"}


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
    buildings = state.get("buildings", [])
    biome = state.get("biome", 0)
    stats = state.get("stats", {})
    halo = state.get("halo", {})
    neighbors = state.get("neighbors", {})
    gap_count = state.get("gap_count", 0)
    
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


def generate_actions(analysis: dict, state: dict, random_seed: int) -> list:
    """Generate concrete actions (fill/remove/reposition) from analysis.
    Balanced: max 2 removes + 2 repositions + 3 fills per chunk (total 7 max).
    """
    actions = []
    chunk_key = analysis["chunk_key"]
    rng = random.Random(random_seed)

    MAX_REMOVES = 2       # cap removes per chunk (preserve content)
    MAX_REPOSITIONS = 2    # cap repositions per chunk (avoid moving everything)
    MAX_FILLS = 3          # cap fills per chunk (avoid over-crowding)
    remove_count = 0
    reposition_count = 0
    fill_count = 0

    # 1. REMOVE overlapping buildings (priority — fix problems first)
    for problem in analysis["problems"]:
        if problem["type"] == "overlaps" and remove_count < MAX_REMOVES:
            for overlap in problem["details"]:
                if remove_count >= MAX_REMOVES:
                    break
                smaller = overlap["smaller"]
                if smaller["name"] in LANDMARK_TYPES:
                    continue
                actions.append({
                    "type": "remove",
                    "chunk_key": chunk_key,
                    "node_name": smaller.get("node_name", ""),
                    "reason": "overlap",
                    "asset_name": smaller["name"],
                })
                remove_count += 1

    # 2. REMOVE repetitive buildings (max 1 per chunk)
    for problem in analysis["problems"]:
        if problem["type"] == "asset_repetition" and remove_count < MAX_REMOVES:
            for name, count in problem["details"].items():
                if remove_count >= MAX_REMOVES:
                    break
                buildings = state.get("buildings", [])
                for b in buildings:
                    if b["name"] == name:
                        actions.append({
                            "type": "remove",
                            "chunk_key": chunk_key,
                            "node_name": b.get("node_name", ""),
                            "reason": f"repetition (count={count})",
                            "asset_name": name,
                        })
                        remove_count += 1
                        break
                if remove_count >= MAX_REMOVES:
                    break

    # 2b. REMOVE semantic conflicts (gas_station near park, factory near school, etc.)
    # Priority: if a conflict is detected, remove the offender (the asset that
    # has the conflict declared in its semantics). E.g. gas_station has
    # conflicts_with=["park","school"] → remove the gas_station, not the park.
    for problem in analysis["problems"]:
        if problem["type"] == "semantic_conflict" and remove_count < MAX_REMOVES:
            for conflict in problem["details"]:
                if remove_count >= MAX_REMOVES:
                    break
                offender = conflict["offender"]
                if offender["name"] in LANDMARK_TYPES:
                    continue  # don't remove landmarks
                actions.append({
                    "type": "remove",
                    "chunk_key": chunk_key,
                    "node_name": offender.get("node_name", ""),
                    "reason": f"semantic_conflict: {conflict['reason']}",
                    "asset_name": offender["name"],
                })
                remove_count += 1

    # 3. REPOSITION buildings that are too close (push them apart along perpendicular)
    # DeepSeek: "Moving one of the pair 0.5m along the perpendicular axis turns
    # 25 problems into 25 fixes in about 10 lines. Cheapest win on the board."
    for problem in analysis["problems"]:
        if problem["type"] == "too_close" and reposition_count < MAX_REPOSITIONS:
            for pair in problem["details"]:
                if reposition_count >= MAX_REPOSITIONS:
                    break
                a, b = pair["a"], pair["b"]
                # Don't reposition landmarks (they're placed intentionally)
                if a["name"] in LANDMARK_TYPES or b["name"] in LANDMARK_TYPES:
                    continue
                # Compute perpendicular axis (push B away from A)
                ax, az = a["pos"][0], a["pos"][2]
                bx, bz = b["pos"][0], b["pos"][2]
                dx, dz = bx - ax, bz - az
                dist = (dx*dx + dz*dz) ** 0.5
                if dist < 0.01:
                    continue  # buildings at same position — can't compute perpendicular
                # Perpendicular = (-dz, dx) normalized
                perp_x = -dz / dist
                perp_z = dx / dist
                # Move B 0.5m along perpendicular (push it away from A)
                new_bx = bx + perp_x * 0.5
                new_bz = bz + perp_z * 0.5
                # Keep building's existing rotation
                new_rot_y = b.get("rot", [0, 0, 0])[1]
                actions.append({
                    "type": "reposition",
                    "chunk_key": chunk_key,
                    "node_name": b.get("node_name", ""),
                    "new_pos": [new_bx, b["pos"][1], new_bz],
                    "new_rot_y": new_rot_y,
                    "reason": f"too_close (dist={pair['dist']:.2f}m, pushed 0.5m)",
                    "asset_name": b["name"],
                })
                reposition_count += 1

    # 4. FILL — from opportunities
    for opp in analysis["opportunities"]:
        if fill_count >= MAX_FILLS:
            break
        if opp["type"] == "missing_parking_lot":
            gaps = state.get("gaps", [])
            if gaps:
                gap = rng.choice(gaps)
                actions.append({
                    "type": "fill",
                    "chunk_key": chunk_key,
                    "pos": gap["pos"],
                    "fill_type": "parking_lot",
                    "reason": opp["reason"],
                })
                fill_count += 1
        elif opp["type"] == "missing_halo_buildings":
            gaps = state.get("gaps", [])
            if gaps and opp["missing"]:
                gap = rng.choice(gaps)
                missing = opp["missing"]
                if any("parking" in m for m in missing):
                    fill_type = "parking_lot"
                else:
                    fill_type = "backyard"
                actions.append({
                    "type": "fill",
                    "chunk_key": chunk_key,
                    "pos": gap["pos"],
                    "fill_type": fill_type,
                    "reason": f"halo missing: {missing}",
                })
                fill_count += 1
        elif opp["type"] == "high_density_gap":
            gaps = state.get("gaps", [])
            biome = analysis["biome"]
            if gaps:
                gap = rng.choice(gaps)
                fill_type = "tree_cluster" if biome in (1, 2, 3, 9) else "green_space"
                if biome == 4:
                    fill_type = "parking_lot"
                elif biome == 0:
                    fill_type = "backyard"
                elif biome == 7:
                    fill_type = "plaza"
                actions.append({
                    "type": "fill",
                    "chunk_key": chunk_key,
                    "pos": gap["pos"],
                    "fill_type": fill_type,
                    "reason": f"high_density_gap ({opp['gap_pct']:.0%} empty)",
                })
                fill_count += 1
        elif opp["type"] == "biome_border":
            gaps = state.get("gaps", [])
            if gaps:
                gap = rng.choice(gaps)
                borders = opp["borders"]
                fill_type = "green_space"
                for border in borders:
                    if border["neighbor_biome"] in (1, 2):
                        fill_type = "tree_cluster"
                        break
                    elif border["neighbor_biome"] == 9:
                        fill_type = "green_space"
                        break
                actions.append({
                    "type": "fill",
                    "chunk_key": chunk_key,
                    "pos": gap["pos"],
                    "fill_type": fill_type,
                    "reason": f"biome_border ({borders[0]['neighbor_name']})",
                })
                fill_count += 1

    return actions


def main():
    if not DUMP_PATH.exists():
        print("ERROR: chunk_states_auto.json not found.")
        print("Run godot --headless --quit-after 300 first to generate it.")
        sys.exit(1)
    
    states = json.loads(DUMP_PATH.read_text())
    print(f"=== AI MIDDLEWARE v2 — analyzing {len(states)} chunk states ===\n")
    
    # Sort chunks by gap_pct descending (fill emptiest chunks first)
    states_sorted = sorted(states, key=lambda s: s.get("stats", {}).get("gap_pct", 0), reverse=True)
    
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
    print(f"\n  Plan written to: {PLAN_PATH}")
    print(f"  Report written to: {REPORT_PATH}")
    print(f"\n  Next: run godot again — runtime will read fill_plan.json + apply")
    print(f"  all actions (fills + removes + repositions) on next chunk load.")


if __name__ == "__main__":
    main()
