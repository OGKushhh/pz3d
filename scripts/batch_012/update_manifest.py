#!/usr/bin/env python3
"""Update city_manifest.json with all batch 012 assets."""
import json
from pathlib import Path

MANIFEST = Path("/home/z/my-project/mazar_city_builder/data/city_manifest.json")

with open(MANIFEST) as f:
    manifest = json.load(f)
before = len(manifest)
print(f"Before: {before} assets in manifest")

NEW = [
    # Characters (5) — new category
    ("walker_zombie_male",       "characters", ["character","zombie","walker","male","enemy"]),
    ("walker_zombie_female",    "characters", ["character","zombie","walker","female","enemy"]),
    ("crawler_zombie",           "characters", ["character","zombie","crawler","enemy"]),
    ("npc_survivor",             "characters", ["character","npc","survivor","neutral"]),
    ("npc_soldier",              "characters", ["character","npc","soldier","military","neutral"]),
    # Decals (4) — new category
    ("blood_splatter",           "decals", ["decal","blood","horror"]),
    ("poster_torn",              "decals", ["decal","poster","urban","horror"]),
    ("grime_dirt",               "decals", ["decal","grime","urban"]),
    ("crack_road",               "decals", ["decal","crack","road","urban"]),
    # Buildings — heroes (4)
    ("government_palace",        "buildings", ["building","downtown","landmark","hero","civic"]),
    ("stadium",                  "buildings", ["building","downtown","landmark","hero","sports"]),
    ("old_royal_palace",         "buildings", ["building","downtown","landmark","hero","historic"]),
    ("fort_sarran",              "buildings", ["building","military","landmark","hero","outbreak"]),
    # Buildings — misc (15)
    ("cave_entrance",            "buildings", ["building","forest","cave","natural"]),
    ("logging_camp_shed",        "buildings", ["building","forest","logging","industrial"]),
    ("ranger_lean_to",           "buildings", ["building","forest","shelter","simple"]),
    ("grain_storage_shed",       "buildings", ["building","farmland","industrial","storage"]),
    ("marsh_pier",               "buildings", ["building","coastal","marsh","pier"]),
    ("maintenance_tunnel_junction", "buildings", ["building","subway","tunnel","maintenance"]),
    ("emergency_exit_stairs",    "buildings", ["building","subway","emergency","stairs"]),
    ("subway_pipe_cluster",      "buildings", ["building","subway","infrastructure","pipes"]),
    ("helipad_control_room",     "buildings", ["building","military","control","tower"]),
    ("salon",                    "buildings", ["building","commercial","salon","downtown"]),
    ("grocery_store",            "buildings", ["building","commercial","downtown"]),
    ("bank_branch",              "buildings", ["building","commercial","bank","downtown"]),
    ("apartment_tower_high",     "buildings", ["building","downtown","residential","highrise"]),
    ("train_boxcar_derelict",    "buildings", ["building","industrial","train","derelict"]),
    # Environment (5)
    ("irrigation_canal",         "environment", ["environment","farmland","water","canal"]),
    ("hay_bale",                 "environment", ["environment","farmland","hay","prop"]),
    ("boardwalk_section",        "environment", ["environment","coastal","boardwalk","pier"]),
    ("mass_grave",               "environment", ["environment","military","grave","horror","dark"]),
    # Foliage (1)
    ("marsh_grass",              "foliage", ["foliage","coastal","marsh","grass","wetland"]),
    # Props (2)
    ("bird_house",               "props", ["prop","suburban","garden","decorative"]),
    ("garden_pergola",           "props", ["prop","suburban","garden","pergola"]),
]

added = 0
skipped = 0
for name, cat, tags in NEW:
    if name in manifest:
        skipped += 1
        continue
    rel_path = f"res://assets/{cat}/{name}.glb"
    manifest[name] = {
        "path": rel_path,
        "tags": tags,
        "category": cat,
        "tier": 1,
        "batch": "012",
    }
    added += 1

manifest_sorted = dict(sorted(manifest.items()))
with open(MANIFEST, 'w') as f:
    json.dump(manifest_sorted, f, indent=2)

print(f"After: {len(manifest_sorted)} assets in manifest")
print(f"Added: {added}, Skipped: {skipped}")
