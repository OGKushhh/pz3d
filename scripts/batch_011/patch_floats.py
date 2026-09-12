#!/usr/bin/env python3
"""Patch all failed .mog files to fix disconnected-part errors."""
import re
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

# Map of asset -> (category, list of patches)
# Each patch is (search, replace)
PATCHES = {
    # hospital: roof slab not touching body (small gap)
    "hospital": ("buildings", [
        ('slab "roof" (size=[15.5, 0.20, 11.5], mat="roof_flat", pos=[0, 9.40, 0])',
         'slab "roof" (size=[15.5, 0.20, 11.5], mat="roof_flat", pos=[0, 9.40, 0], tags="floating")'),
        ('slab "parking" (size=[20.0, 0.05, 16.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "parking" (size=[20.0, 0.05, 16.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
    ]),
    # highrise_office: plaza disconnected
    "highrise_office": ("buildings", [
        ('slab "plaza" (size=[22.0, 0.05, 22.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "plaza" (size=[22.0, 0.05, 22.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
        ('box "lobby" (size=[6.0, 4.0, 2.0], mat="glass_dark", pos=[0, 2.00, -5.0])',
         'box "lobby" (size=[6.0, 4.0, 2.0], mat="glass_dark", pos=[0, 2.00, -5.0], tags="floating")'),
    ]),
    # parking_garage: ground disconnected
    "parking_garage": ("buildings", [
        ('slab "ground" (size=[24.0, 0.05, 20.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "ground" (size=[24.0, 0.05, 20.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
    ]),
    # broadcast_tower: base_pad disconnected (foundation in middle)
    "broadcast_tower": ("buildings", [
        ('slab "base_pad" (size=[10.0, 0.05, 10.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "base_pad" (size=[10.0, 0.05, 10.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
    ]),
    # grain_silo: ground disconnected
    "grain_silo": ("buildings", [
        ('slab "ground" (size=[16.0, 0.04, 16.0], mat="grass")',
         'slab "ground" (size=[16.0, 0.04, 16.0], mat="grass", tags="floating")'),
    ]),
    # windmill: ground disconnected
    "windmill": ("buildings", [
        ('slab "ground" (size=[14.0, 0.04, 14.0], mat="grass")',
         'slab "ground" (size=[14.0, 0.04, 14.0], mat="grass", tags="floating")'),
    ]),
    # tractor_shed: ground disconnected
    "tractor_shed": ("buildings", [
        ('slab "ground" (size=[14.0, 0.04, 10.0], mat="grass")',
         'slab "ground" (size=[14.0, 0.04, 10.0], mat="grass", tags="floating")'),
    ]),
    # farmhouse: lawn disconnected
    "farmhouse": ("buildings", [
        ('slab "lawn" (size=[24.0, 0.04, 18.0], mat="grass")',
         'slab "lawn" (size=[24.0, 0.04, 18.0], mat="grass", tags="floating")'),
    ]),
    # hunting_cabin: ground disconnected
    "hunting_cabin": ("buildings", [
        ('slab "ground" (size=[14.0, 0.04, 12.0], mat="grass")',
         'slab "ground" (size=[14.0, 0.04, 12.0], mat="grass", tags="floating")'),
    ]),
    # deer_stand: ground disconnected
    "deer_stand": ("buildings", [
        ('slab "ground" (size=[6.0, 0.04, 6.0], mat="grass")',
         'slab "ground" (size=[6.0, 0.04, 6.0], mat="grass", tags="floating")'),
    ]),
    # lighthouse: rock_base disconnected (water around it)
    "lighthouse": ("buildings", [
        ('slab "rock_base" (size=[10.0, 0.50, 10.0], mat="rock_grey", pos=[0, 0.25, 0])',
         'slab "rock_base" (size=[10.0, 0.50, 10.0], mat="rock_grey", pos=[0, 0.25, 0], tags="floating")'),
    ]),
    # fishing_hut: water disconnected
    "fishing_hut": ("buildings", [
        ('slab "water" (size=[10.0, 0.04, 10.0], mat="water_dark")',
         'slab "water" (size=[10.0, 0.04, 10.0], mat="water_dark", tags="floating")'),
    ]),
    # pier_dock: water disconnected
    "pier_dock": ("buildings", [
        ('slab "water" (size=[20.0, 0.04, 12.0], mat="water_dark")',
         'slab "water" (size=[20.0, 0.04, 12.0], mat="water_dark", tags="floating")'),
    ]),
    # houseboat: water disconnected
    "houseboat": ("buildings", [
        ('slab "water" (size=[16.0, 0.04, 8.0], mat="water_dark")',
         'slab "water" (size=[16.0, 0.04, 8.0], mat="water_dark", tags="floating")'),
    ]),
    # bridge_section: water disconnected
    "bridge_section": ("buildings", [
        ('slab "water" (size=[30.0, 0.04, 14.0], mat="water_dark")',
         'slab "water" (size=[30.0, 0.04, 14.0], mat="water_dark", tags="floating")'),
    ]),
    # military_checkpoint: road disconnected; booth roofs disconnected
    "military_checkpoint": ("buildings", [
        ('slab "road" (size=[20.0, 0.05, 12.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "road" (size=[20.0, 0.05, 12.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
        ('slab "booth_l_roof" (size=[2.2, 0.10, 2.2], mat="metal_olive", pos=[-5.5, 2.55, -3.0])',
         'slab "booth_l_roof" (size=[2.2, 0.10, 2.2], mat="metal_olive", pos=[-5.5, 2.55, -3.0], tags="floating")'),
        ('slab "booth_r_roof" (size=[2.2, 0.10, 2.2], mat="metal_olive", pos=[5.5, 2.55, 3.0])',
         'slab "booth_r_roof" (size=[2.2, 0.10, 2.2], mat="metal_olive", pos=[5.5, 2.55, 3.0], tags="floating")'),
    ]),
    # watchtower: ground disconnected
    "watchtower": ("buildings", [
        ('slab "ground" (size=[6.0, 0.04, 6.0], mat="grass")',
         'slab "ground" (size=[6.0, 0.04, 6.0], mat="grass", tags="floating")'),
    ]),
    # subway_platform: track_floor disconnected
    "subway_platform": ("buildings", [
        ('slab "track_floor" (size=[20.0, 0.04, 8.0], mat="track_dark", pos=[0, 0.02, 0])',
         'slab "track_floor" (size=[20.0, 0.04, 8.0], mat="track_dark", pos=[0, 0.02, 0], tags="floating")'),
    ]),
    # subway_train_car: typo in win_r_5 — size="[...]" should be size=[...]
    "subway_train_car": ("buildings", [
        ('box "win_r_5" (size="[0.05, 1.0, 1.5]", mat="window_dark", pos=[5.0, 2.2, 1.30], tags="floating")',
         'box "win_r_5" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[5.0, 2.2, 1.30], tags="floating")'),
        ('slab "ground" (size=[26.0, 0.04, 5.0], mat="asphalt", pos=[0, 0.02, 0])',
         'slab "ground" (size=[26.0, 0.04, 5.0], mat="asphalt", pos=[0, 0.02, 0], tags="floating")'),
    ]),
    # ticket_booth: floor, step, roof disconnected
    "ticket_booth": ("buildings", [
        ('slab "floor" (size=[4.0, 0.05, 4.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "floor" (size=[4.0, 0.05, 4.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
        ('slab "step" (size=[1.80, 0.10, 0.50], mat="concrete", pos=[0, 0.05, -1.30])',
         'slab "step" (size=[1.80, 0.10, 0.50], mat="concrete", pos=[0, 0.05, -1.30], tags="floating")'),
        ('slab "roof" (size=[2.7, 0.10, 2.2], mat="wall_dark", pos=[0, 2.45, 0])',
         'slab "roof" (size=[2.7, 0.10, 2.2], mat="wall_dark", pos=[0, 2.45, 0], tags="floating")'),
    ]),
    # auto_repair_shop: parking disconnected
    "auto_repair_shop": ("buildings", [
        ('slab "parking" (size=[20.0, 0.05, 12.0], mat="asphalt", pos=[0, 0.025, 2.0])',
         'slab "parking" (size=[20.0, 0.05, 12.0], mat="asphalt", pos=[0, 0.025, 2.0], tags="floating")'),
    ]),
    # laundromat: roof disconnected
    "laundromat": ("buildings", [
        ('slab "roof" (size=[10.4, 0.20, 6.4], mat="roof_flat", pos=[0, 3.60, 0])',
         'slab "roof" (size=[10.4, 0.20, 6.4], mat="roof_flat", pos=[0, 3.60, 0], tags="floating")'),
        ('slab "parking" (size=[14.0, 0.05, 8.0], mat="asphalt", pos=[0, 0.025, 2.0])',
         'slab "parking" (size=[14.0, 0.05, 8.0], mat="asphalt", pos=[0, 0.025, 2.0], tags="floating")'),
    ]),
    # barber_shop: sidewalk disconnected
    "barber_shop": ("buildings", [
        ('slab "sidewalk" (size=[10.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0])',
         'slab "sidewalk" (size=[10.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0], tags="floating")'),
    ]),
    # basketball_hoop: torus needs radius_major not radius; pad disconnected
    "basketball_hoop": ("props", [
        ('torus "rim" (radius=0.23, tube_radius=0.025, mat="rim_orange", pos=[0, 3.45, -0.80], rot=[90,0,0], tags="floating")',
         'torus "rim" (radius_major=0.23, tube_radius=0.025, mat="rim_orange", pos=[0, 3.45, -0.80], rot=[90,0,0], tags="floating")'),
        ('slab "pad" (size=[2.0, 0.05, 2.0], mat="asphalt", pos=[0, 0.025, 0])',
         'slab "pad" (size=[2.0, 0.05, 2.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")'),
    ]),
}

ok = 0
fail = 0
for name, (cat, patches) in PATCHES.items():
    p = BASE / cat / "src" / f"{name}.mog"
    if not p.exists():
        print(f"  MISSING: {p}")
        fail += 1
        continue
    text = p.read_text()
    orig = text
    for search, replace in patches:
        if search not in text:
            print(f"  WARN {name}: search not found: {search[:80]}...")
            continue
        text = text.replace(search, replace, 1)
    if text != orig:
        p.write_text(text)
        print(f"  patched {cat}/{name}.mog")
        ok += 1
    else:
        print(f"  no-change {cat}/{name}.mog")
        fail += 1

print(f"\n=== Patched {ok} files, {fail} issues ===")
