#!/usr/bin/env python3
"""
AI Middleware: reads chunk_states_auto.json (the MAP → DATA dump) and
generates fill_plan.json (the DATA → MAP instructions the runtime applies).

This is the feedback loop:
  1. Runtime places procedural content → dumps chunk_states_auto.json
  2. THIS SCRIPT reads the dump + analyzes gaps with suggested fills
  3. THIS SCRIPT writes fill_plan.json with concrete placement decisions
  4. Runtime reads fill_plan.json + places the fills (next time chunks load)

Run after the runtime has dumped chunk_states_auto.json (wait 2s after
scene load, or press F8 to dump manually, then run this script).

Usage: python3 /home/z/my-project/pz3d/scripts/ai_fill_planner.py
"""
import json
import sys
from pathlib import Path

DUMP_PATH = Path("/home/z/my-project/pz3d/godot_project/chunk_states_auto.json")
PLAN_PATH = Path("/home/z/my-project/pz3d/godot_project/fill_plan.json")

def main():
    if not DUMP_PATH.exists():
        print("ERROR: chunk_states_auto.json not found.")
        print("Run godot --headless --quit-after 300 first to generate it.")
        sys.exit(1)
    
    states = json.loads(DUMP_PATH.read_text())
    print(f"=== AI FILL PLANNER — analyzing {len(states)} chunk states ===\n")
    
    # Collect ALL gaps with their suggested fills
    all_fills = []
    fill_type_counts = {}
    
    for state in states:
        chunk_key = state["chunk_key"]
        gaps = state.get("gaps", [])
        biome = state.get("biome", 0)
        stats = state.get("stats", {})
        halo = state.get("halo", {})
        
        # AI DECISION LOGIC:
        # For each gap, decide whether to actually place a fill + which type.
        # Not every gap should be filled — leave some empty for variety.
        # Priority: parking_lot > backyard > alley > green_space > tree_cluster
        
        # Limit fills per chunk to avoid over-crowding (max 3 per chunk)
        fills_this_chunk = 0
        MAX_FILLS_PER_CHUNK = 3
        
        for gap in gaps:
            if fills_this_chunk >= MAX_FILLS_PER_CHUNK:
                break
            
            suggested = gap.get("suggested_fill", "empty")
            pos = gap.get("pos", [0, 0, 0])
            
            # AI DECISION: 60% chance to actually place a fill (40% stay empty for variety)
            import random
            random.seed(hash((chunk_key[0], chunk_key[1], gap.get("cell", [0, 0])[0], gap.get("cell", [0, 0])[1])))
            if random.random() > 0.6:
                continue
            
            # Pick the fill type — use the suggested one, with some AI adjustments
            fill_type = suggested
            
            # AI OVERRIDE: if this chunk is commercial + has no parking lot yet,
            # force at least one parking_lot fill
            if (biome == 4 and  # COMMERCIAL
                not stats.get("has_parking_lot", False) and
                fills_this_chunk == 0):
                fill_type = "parking_lot"
            
            # AI OVERRIDE: if a halo landmark is nearby + the halo suggests
            # parking (stadium, hospital, railway_station), force parking_lot
            if halo.get("active", False):
                boost_buildings = halo.get("boost_buildings", {})
                if "parking_garage" in boost_buildings or "parking_meter" in boost_buildings:
                    if not stats.get("has_parking_lot", False):
                        fill_type = "parking_lot"
            
            # AI OVERRIDE: in residential biomes, prefer backyard over other fills
            if biome == 0 and fill_type == "empty":  # SUBURBIA
                fill_type = "backyard"
            
            # AI OVERRIDE: in forest/parks, prefer tree_cluster
            if biome in (1, 2):  # PARKS, FOREST
                fill_type = "tree_cluster"
            
            # Skip "empty" — no fill to place
            if fill_type == "empty":
                continue
            
            all_fills.append({
                "chunk_key": chunk_key,
                "pos": pos,
                "fill_type": fill_type,
                "suggested": suggested,
                "biome": biome,
            })
            fill_type_counts[fill_type] = fill_type_counts.get(fill_type, 0) + 1
            fills_this_chunk += 1
    
    # Write the fill plan
    plan = {
        "version": 1,
        "total_fills": len(all_fills),
        "fill_type_counts": fill_type_counts,
        "fills": all_fills,
    }
    PLAN_PATH.write_text(json.dumps(plan, indent=2))
    
    print(f"=== FILL PLAN GENERATED ===")
    print(f"  Total fills: {len(all_fills)}")
    print(f"  Fill type distribution:")
    for ft, count in sorted(fill_type_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"    {ft}: {count}")
    print(f"\n  Written to: {PLAN_PATH}")
    print(f"\n  Next: run godot again — runtime will read fill_plan.json + place these fills")
    print(f"  on next chunk load. Press F5 in Godot to see the fills appear.")

if __name__ == "__main__":
    main()
