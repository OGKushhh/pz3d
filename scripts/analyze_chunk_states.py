#!/usr/bin/env python3
"""Analyze the auto-dumped chunk_states_auto.json and report what the AI can 'see'."""
import json
import sys
from pathlib import Path

dump_path = Path("/home/z/my-project/pz3d/godot_project/chunk_states_auto.json")
if not dump_path.exists():
    print("ERROR: chunk_states_auto.json not found — run godot --headless first")
    sys.exit(1)

states = json.loads(dump_path.read_text())
print(f"=== CHUNK STATE ANALYSIS — {len(states)} chunks ===\n")

# === OVERVIEW ===
print("=== OVERVIEW ===")
biome_counts = {}
total_buildings = 0
total_props = 0
total_foliage = 0
total_zombies = 0
total_gaps = 0
total_water_cells = 0
chunks_with_river = 0
chunks_with_halo = 0
for s in states:
    b = s["biome"]
    biome_counts[b] = biome_counts.get(b, 0) + 1
    total_buildings += s["counts"]["buildings"]
    total_props += s["counts"]["props"]
    total_foliage += s["counts"]["foliage"]
    total_zombies += s["counts"]["zombies"]
    total_gaps += s.get("gap_count", 0)
    if s.get("river", {}).get("passes_through", False):
        chunks_with_river += 1
    if s.get("halo", {}).get("active", False):
        chunks_with_halo += 1
    terrain = s.get("terrain", {})
    if terrain.get("has_water", False):
        total_water_cells += 1

print(f"  Total buildings: {total_buildings}")
print(f"  Total props: {total_props}")
print(f"  Total foliage: {total_foliage}")
print(f"  Total zombies: {total_zombies}")
print(f"  Total gaps (empty cells): {total_gaps}")
print(f"  Chunks with river passing through: {chunks_with_river}")
print(f"  Chunks with active halo: {chunks_with_halo}")
print(f"  Chunks with water coverage: {total_water_cells}")
print(f"  Biome distribution: {biome_counts}")

# === TERRAIN HEIGHT ANALYSIS ===
print("\n=== TERRAIN HEIGHTS ===")
min_heights = []
max_heights = []
avg_heights = []
for s in states:
    t = s.get("terrain", {})
    if t:
        min_heights.append(t.get("min_height", 0))
        max_heights.append(t.get("max_height", 0))
        avg_heights.append(t.get("avg_height", 0))
if min_heights:
    print(f"  Lowest point across all chunks: {min(min_heights):.2f}m")
    print(f"  Highest point across all chunks: {max(max_heights):.2f}m")
    print(f"  Average height across chunks: {sum(avg_heights)/len(avg_heights):.2f}m")
    # Find chunks with most elevation change
    elevation_changes = [(i, max_h - min_h) for i, (min_h, max_h) in enumerate(zip(min_heights, max_heights))]
    elevation_changes.sort(key=lambda x: x[1], reverse=True)
    print(f"  Top 3 chunks by elevation change:")
    for i, change in elevation_changes[:3]:
        s = states[i]
        print(f"    chunk {s['chunk_key']}: {change:.2f}m change ({s['district_name']})")

# === RIVER ANALYSIS ===
print("\n=== RIVER ===")
for s in states:
    r = s.get("river", {})
    if r.get("passes_through", False):
        print(f"  chunk {s['chunk_key']} ({s['district_name']}): river passes through")
        print(f"    distance to centerline: {r.get('distance_to_centerline', 'N/A'):.1f}m")
        print(f"    water depth at center: {r.get('water_depth_at_center', 0):.2f}m")
        entry = r.get("entry_point", [])
        if entry:
            print(f"    river enters chunk at: ({entry[0]:.0f}, {entry[1]:.0f})")

# === HALO ANALYSIS ===
print("\n=== DISTRICT HALO ===")
for s in states:
    h = s.get("halo", {})
    if h.get("active", False):
        landmarks = h.get("landmarks_nearby", [])
        boosts = h.get("boost_buildings", {})
        print(f"  chunk {s['chunk_key']} ({s['district_name']}): halo active")
        print(f"    landmarks nearby: {landmarks}")
        print(f"    boost buildings: {list(boosts.keys())}")

# === ZONING ANALYSIS ===
print("\n=== ZONING BALANCE ===")
for s in states:
    stats = s.get("stats", {})
    if stats.get("commercial_pct", 0) > 0 or stats.get("residential_pct", 0) > 0:
        print(f"  chunk {s['chunk_key']} ({s['district_name']}): "
              f"commercial={stats.get('commercial_pct', 0):.0%} "
              f"residential={stats.get('residential_pct', 0):.0%} "
              f"landmarks={stats.get('landmark_count', 0)} "
              f"buildings={s['counts']['buildings']}")

# === GAP ANALYSIS ===
print("\n=== GAPS (empty positions needing fill) ===")
gap_fills = {}
for s in states:
    for gap in s.get("gaps", []):
        fill = gap.get("suggested_fill", "empty")
        gap_fills[fill] = gap_fills.get(fill, 0) + 1
print(f"  Suggested fill distribution:")
for fill, count in sorted(gap_fills.items(), key=lambda x: x[1], reverse=True):
    print(f"    {fill}: {count} positions")

# === DENSITY GRID SAMPLE (first chunk) ===
print("\n=== DENSITY GRID SAMPLE (first chunk) ===")
s = states[0]
print(f"  chunk {s['chunk_key']} ({s['district_name']}):")
grid = s.get("density_grid", [])
print(f"  Legend: B=building/blocked, R=road, W=water, E=empty gap, O=occupied")
for row in grid:
    print(f"    {''.join(row)}")

# === NEIGHBOR BIOMES ===
print("\n=== NEIGHBOR BIOMES (border chunks show biome transitions) ===")
biome_names = {0: "SUBURBIA", 1: "PARKS", 2: "FOREST", 3: "FARMLAND", 4: "COMMERCIAL",
               5: "INDUSTRIAL", 6: "WETLANDS", 7: "DOWNTOWN", 8: "MILITARY",
               9: "COASTAL_BEACH", 10: "WATER", 11: "EMPTY", 12: "WETLANDS"}
for s in states[:5]:
    n = s.get("neighbors", {})
    print(f"  chunk {s['chunk_key']} biome={biome_names.get(s['biome'], '?')}: "
          f"N={biome_names.get(n.get('north', -1), '?')} "
          f"S={biome_names.get(n.get('south', -1), '?')} "
          f"E={biome_names.get(n.get('east', -1), '?')} "
          f"W={biome_names.get(n.get('west', -1), '?')}")

# === ROAD ANALYSIS ===
print("\n=== ROADS PER CHUNK ===")
for s in states[:5]:
    roads = s.get("roads", [])
    print(f"  chunk {s['chunk_key']}: {len(roads)} roads")
    for r in roads[:3]:
        print(f"    {r.get('kind', 'street')} '{r.get('name', '')}' "
              f"width={r.get('width', 8)}m length={r.get('length', 0):.0f}m")

print("\n=== ANALYSIS COMPLETE ===")
