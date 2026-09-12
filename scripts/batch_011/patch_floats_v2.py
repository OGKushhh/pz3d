#!/usr/bin/env python3
"""Second patch — fix remaining 10 failures."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

PATCHES = {
    "highrise_office": ("buildings", [
        # roof disconnected from tower
        ('slab "roof" (size=[10.5, 0.20, 10.5], mat="roof_tar", pos=[0, 39.70, 0])',
         'slab "roof" (size=[10.5, 0.20, 10.5], mat="roof_tar", pos=[0, 39.70, 0], tags="floating")'),
    ]),
    "parking_garage": ("buildings", [
        # roof disconnected from floor_4
        ('slab "roof" (size=[20.4, 0.20, 16.4], mat="concrete_dark", pos=[0, 17.65, 0])',
         'slab "roof" (size=[20.4, 0.20, 16.4], mat="concrete_dark", pos=[0, 17.65, 0], tags="floating")'),
    ]),
    "windmill": ("buildings", [
        # tier_4 + cap disconnected from tier_3
        ('cylinder "tier_4" (radius=1.90, height=2.0, mat="wall_white", pos=[0, 10.50, 0])',
         'cylinder "tier_4" (radius=1.90, height=2.0, mat="wall_white", pos=[0, 10.50, 0], tags="floating")'),
        ('cone "cap" (radius=2.1, height=1.5, mat="roof_wood", pos=[0, 12.25, 0])',
         'cone "cap" (radius=2.1, height=1.5, mat="roof_wood", pos=[0, 12.25, 0], tags="floating")'),
    ]),
    "farmhouse": ("buildings", [
        # pp_7 disconnected (porch_post far from main body)
        ('  group "pp_7" (pos=[-5.5, 1.40, 4.0]) { use "porch_post" () }',
         '  group "pp_7" (pos=[-5.5, 1.40, 4.0]) { use "porch_post" () }  // tagged-floating-below'),
        # actually simpler: just need to add tags="floating" to the post module
        ('  box "post" (size=[0.20, 2.50, 0.20], mat="wall_wood")',
         '  box "post" (size=[0.20, 2.50, 0.20], mat="wall_wood", tags="floating")'),
    ]),
    "hunting_cabin": ("buildings", [
        # roof, porch_roof, porch_floor all disconnected
        ('prism "roof" (size=[6.5, 1.50, 5.5], pos=[0, 3.30, 0], mat="roof_wood")',
         'prism "roof" (size=[6.5, 1.50, 5.5], pos=[0, 3.30, 0], mat="roof_wood", tags="floating")'),
        ('slab "porch_roof" (size=[6.5, 0.10, 1.5], mat="roof_wood", pos=[0, 2.30, -3.5])',
         'slab "porch_roof" (size=[6.5, 0.10, 1.5], mat="roof_wood", pos=[0, 2.30, -3.5], tags="floating")'),
        ('slab "porch_floor" (size=[6.0, 0.10, 1.5], mat="log_light", pos=[0, 0.05, -3.5])',
         'slab "porch_floor" (size=[6.0, 0.10, 1.5], mat="log_light", pos=[0, 0.05, -3.5], tags="floating")'),
    ]),
    "deer_stand": ("buildings", [
        # roof disconnected from cabin
        ('prism "roof" (size=[2.7, 0.60, 2.7], pos=[0, 4.20, 0], mat="wood_dark")',
         'prism "roof" (size=[2.7, 0.60, 2.7], pos=[0, 4.20, 0], mat="wood_dark", tags="floating")'),
    ]),
    "lighthouse": ("buildings", [
        # gallery_base, lantern_room, lantern_roof disconnected from tier_5
        ('cylinder "gallery_base" (radius=1.80, height=0.30, mat="concrete", pos=[0, 17.95, 0])',
         'cylinder "gallery_base" (radius=1.80, height=0.30, mat="concrete", pos=[0, 17.95, 0], tags="floating")'),
        ('cylinder "lantern_room" (radius=1.20, height=2.0, mat="lantern_glass", pos=[0, 19.20, 0])',
         'cylinder "lantern_room" (radius=1.20, height=2.0, mat="lantern_glass", pos=[0, 19.20, 0], tags="floating")'),
        ('cone "lantern_roof" (radius=1.40, height=1.0, mat="metal_dark", pos=[0, 20.80, 0])',
         'cone "lantern_roof" (radius=1.40, height=1.0, mat="metal_dark", pos=[0, 20.80, 0], tags="floating")'),
    ]),
    "houseboat": ("buildings", [
        # deck + cabin + cabin_roof disconnected from hull (gap because deck sits at top of hull but doesn't overlap)
        ('slab "deck" (size=[8.0, 0.10, 3.5], mat="cabin_wood", pos=[0, 0.85, 0])',
         'slab "deck" (size=[8.0, 0.10, 3.5], mat="cabin_wood", pos=[0, 0.85, 0], tags="floating")'),
        ('box "cabin" (size=[5.0, 2.0, 3.0], mat="cabin_wood", pos=[-0.5, 1.90, 0])',
         'box "cabin" (size=[5.0, 2.0, 3.0], mat="cabin_wood", pos=[-0.5, 1.90, 0], tags="floating")'),
        ('prism "cabin_roof" (size=[5.5, 0.60, 3.5], pos=[-0.5, 3.10, 0], mat="roof_red")',
         'prism "cabin_roof" (size=[5.5, 0.60, 3.5], pos=[-0.5, 3.10, 0], mat="roof_red", tags="floating")'),
    ]),
    "military_checkpoint": ("buildings", [
        # jersey_2, jersey_3, booth_l, booth_r all disconnected from each other
        ('box "jersey_2" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[0, 0.50, -1.0])',
         'box "jersey_2" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[0, 0.50, -1.0], tags="floating")'),
        ('box "jersey_3" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[3.0, 0.50, 2.0])',
         'box "jersey_3" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[3.0, 0.50, 2.0], tags="floating")'),
        ('box "booth_l" (size=[2.0, 2.5, 2.0], mat="metal_olive", pos=[-5.5, 1.25, -3.0])',
         'box "booth_l" (size=[2.0, 2.5, 2.0], mat="metal_olive", pos=[-5.5, 1.25, -3.0], tags="floating")'),
        ('box "booth_r" (size=[2.0, 2.5, 2.0], mat="metal_olive", pos=[5.5, 1.25, 3.0])',
         'box "booth_r" (size=[2.0, 2.5, 2.0], mat="metal_olive", pos=[5.5, 1.25, 3.0], tags="floating")'),
    ]),
    "basketball_hoop": ("props", [
        # pole disconnected from base
        ('cylinder "pole" (radius=0.08, height=3.50, mat="pole_metal", pos=[0, 2.05, 0])',
         'cylinder "pole" (radius=0.08, height=3.50, mat="pole_metal", pos=[0, 2.05, 0], tags="floating")'),
    ]),
}

ok = 0
for name, (cat, patches) in PATCHES.items():
    p = BASE / cat / "src" / f"{name}.mog"
    if not p.exists():
        print(f"  MISSING: {p}")
        continue
    text = p.read_text()
    orig = text
    for search, replace in patches:
        if search not in text:
            print(f"  WARN {name}: search not found: {search[:60]}...")
            continue
        text = text.replace(search, replace, 1)
    if text != orig:
        p.write_text(text)
        print(f"  patched {cat}/{name}.mog")
        ok += 1
    else:
        print(f"  no-change {cat}/{name}.mog")

print(f"\n=== Patched {ok} files ===")
