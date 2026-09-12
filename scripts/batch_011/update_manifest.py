#!/usr/bin/env python3
"""Update city_manifest.json to include all 40 new batch 011 assets + verify totals."""
import json
from pathlib import Path

BASE = Path("/home/z/my-project")
MANIFEST = BASE / "mazar_city_builder" / "data" / "city_manifest.json"

# Load existing
with open(MANIFEST) as f:
    manifest = json.load(f)
before = len(manifest)
print(f"Before: {before} assets in manifest")

# New assets (40) — match the GLB output paths
NEW = [
    # Downtown (6)
    ("hospital",              "buildings", ["building","civic","downtown","landmark"]),
    ("police_station",        "buildings", ["building","civic","downtown","landmark"]),
    ("highrise_office",       "buildings", ["building","downtown","highrise","landmark"]),
    ("parking_garage",        "buildings", ["building","downtown","parking"]),
    ("broadcast_tower",       "buildings", ["building","downtown","landmark","tower"]),
    ("railway_station",       "buildings", ["building","downtown","landmark","transit"]),
    # Farmland (4)
    ("grain_silo",            "buildings", ["building","farmland","landmark","industrial"]),
    ("windmill",              "buildings", ["building","farmland","landmark","windmill"]),
    ("tractor_shed",          "buildings", ["building","farmland","shed"]),
    ("farmhouse",             "buildings", ["building","farmland","house"]),
    # Forest (4)
    ("hunting_cabin",         "buildings", ["building","forest","cabin"]),
    ("ranger_station",        "buildings", ["building","forest","ranger"]),
    ("camping_tent",          "buildings", ["building","forest","camping","prop"]),
    ("deer_stand",            "buildings", ["building","forest","hunting"]),
    # River/Coastal (5)
    ("lighthouse",            "buildings", ["building","coastal","landmark","lighthouse"]),
    ("fishing_hut",           "buildings", ["building","coastal","fishing"]),
    ("pier_dock",             "buildings", ["building","coastal","pier"]),
    ("houseboat",             "buildings", ["building","coastal","houseboat"]),
    ("bridge_section",        "buildings", ["building","coastal","bridge","landmark"]),
    # Military (5)
    ("military_checkpoint",   "buildings", ["building","military","checkpoint"]),
    ("watchtower",            "buildings", ["building","military","watchtower"]),
    ("bunker_entrance",       "buildings", ["building","military","bunker"]),
    ("helipad",               "buildings", ["building","military","helipad"]),
    ("field_hospital_tent",   "buildings", ["building","military","medical","tent"]),
    # Subway (4)
    ("subway_platform",       "buildings", ["building","subway","platform"]),
    ("subway_tunnel",         "buildings", ["building","subway","tunnel"]),
    ("subway_train_car",      "buildings", ["building","subway","train","vehicle"]),
    ("ticket_booth",          "buildings", ["building","subway","ticket"]),
    # Commercial (4)
    ("strip_mall",            "buildings", ["building","commercial","downtown"]),
    ("auto_repair_shop",      "buildings", ["building","commercial","industrial"]),
    ("laundromat",            "buildings", ["building","commercial","downtown"]),
    ("barber_shop",           "buildings", ["building","commercial","downtown"]),
    # Backyard (1)
    ("treehouse",            "buildings", ["building","suburban","treehouse"]),
    # Environment (5)
    ("campfire_ring",         "environment", ["environment","park","camping","fire"]),
    ("barbed_wire_fence",     "environment", ["environment","military","fence"]),
    ("turnstile",             "environment", ["environment","subway","transit"]),
    ("crop_field_corn",       "environment", ["environment","farmland","crop"]),
    ("seesaw",                "environment", ["environment","park","playground"]),
    # Props (2)
    ("basketball_hoop",       "props", ["prop","sports","suburban"]),
    ("traffic_camera",        "props", ["prop","infrastructure","suburban"]),
]

added = 0
skipped = 0
for name, cat, tags in NEW:
    if name in manifest:
        print(f"  skip (exists): {name}")
        skipped += 1
        continue
    rel_path = f"res://assets/{cat}/{name}.glb"
    manifest[name] = {
        "path": rel_path,
        "tags": tags,
        "category": cat,
        "tier": 1,
        "batch": "011",
    }
    added += 1

# Sort by key for stable output
manifest_sorted = dict(sorted(manifest.items()))

# Write back
with open(MANIFEST, 'w') as f:
    json.dump(manifest_sorted, f, indent=2)

print(f"\nAfter: {len(manifest_sorted)} assets in manifest")
print(f"Added: {added}, Skipped (existed): {skipped}")
print(f"Total assets: {len(manifest_sorted)}")
