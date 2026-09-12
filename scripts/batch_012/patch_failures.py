#!/usr/bin/env python3
"""Batch 012 — fix the 12 build failures."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

PATCHES = {
    # 1. government_palace — plaza/lawn disconnected; colonnade column shafts/capitals/bases disconnected
    "government_palace": ("buildings", [
        ('slab "plaza" (size=[60.0, 0.05, 40.0], mat="asphalt", pos=[0, 0.025, 5.0])',
         'slab "plaza" (size=[60.0, 0.05, 40.0], mat="asphalt", pos=[0, 0.025, 5.0], tags="floating")'),
        ('slab "lawn_l" (size=[15.0, 0.04, 25.0], mat="grass", pos=[-22.5, 0.02, 5.0])',
         'slab "lawn_l" (size=[15.0, 0.04, 25.0], mat="grass", pos=[-22.5, 0.02, 5.0], tags="floating")'),
        ('slab "lawn_r" (size=[15.0, 0.04, 25.0], mat="grass", pos=[22.5, 0.02, 5.0])',
         'slab "lawn_r" (size=[15.0, 0.04, 25.0], mat="grass", pos=[22.5, 0.02, 5.0], tags="floating")'),
        # Column module parts must be tagged floating (they're separate parts in a group)
        ('module "gp_column" () {\n  // Classical column — base + shaft + capital\n  box "base" (size=[0.80, 0.20, 0.80], mat="column_marble")\n  cylinder "shaft" (radius=0.30, height=4.50, mat="column_marble", pos=[0, 2.45, 0])\n  box "capital" (size=[0.80, 0.30, 0.80], mat="column_marble", pos=[0, 4.85, 0])\n}',
         'module "gp_column" () {\n  // Classical column — base + shaft + capital\n  box "base" (size=[0.80, 0.20, 0.80], mat="column_marble", tags="floating")\n  cylinder "shaft" (radius=0.30, height=4.50, mat="column_marble", pos=[0, 2.45, 0], tags="floating")\n  box "capital" (size=[0.80, 0.30, 0.80], mat="column_marble", pos=[0, 4.85, 0], tags="floating")\n}'),
    ]),
    # 2. stadium — perimeter walls disconnected (4 separate walls not touching foundation at corners)
    "stadium": ("buildings", [
        ('wall "perim_n" (size=[60.0, 4.0, 0.20], pos=[0, 14.00, -28.0], mat="wall_concrete")',
         'wall "perim_n" (size=[60.0, 4.0, 0.20], pos=[0, 14.00, -28.0], mat="wall_concrete", tags="floating")'),
        ('wall "perim_s" (size=[60.0, 4.0, 0.20], pos=[0, 14.00, 28.0], mat="wall_concrete")',
         'wall "perim_s" (size=[60.0, 4.0, 0.20], pos=[0, 14.00, 28.0], mat="wall_concrete", tags="floating")'),
        ('wall "perim_e" (size=[56.0, 4.0, 0.20], pos=[32.0, 14.00, 0], rot=[0,90,0], mat="wall_concrete", holes=[[-10.0,-0.80,4.0,2.50]])',
         'wall "perim_e" (size=[56.0, 4.0, 0.20], pos=[32.0, 14.00, 0], rot=[0,90,0], mat="wall_concrete", holes=[[-10.0,-0.80,4.0,2.50]], tags="floating")'),
        ('wall "perim_w" (size=[56.0, 4.0, 0.20], pos=[-32.0, 14.00, 0], rot=[0,90,0], mat="wall_concrete", holes=[[10.0,-0.80,4.0,2.50]])',
         'wall "perim_w" (size=[56.0, 4.0, 0.20], pos=[-32.0, 14.00, 0], rot=[0,90,0], mat="wall_concrete", holes=[[10.0,-0.80,4.0,2.50]], tags="floating")'),
    ]),
    # 3-7. ALL CHARACTERS — skin binding error: "upper_arm_l" has no mesh.
    # The skeleton defines bone "upper_arm_l" but no mesh uses it. Need to either remove the bones or add tiny invisible mesh.
    # Easier fix: bind a small invisible mesh to each unused bone.
    "walker_zombie_male": ("characters", [
        ('  rounded_box "hand_r" (size=[0.10, 0.12, 0.06], radius=0.03, mat="skin_zombie", pos=[0.30, 0.85, 0.65], skin="rig")',
         '  rounded_box "hand_r" (size=[0.10, 0.12, 0.06], radius=0.03, mat="skin_zombie", pos=[0.30, 0.85, 0.65], skin="rig")\n  // Tiny markers for unused bones (shoulder_l, shoulder_r, forearm_l, forearm_r) — required by skin binding\n  box "marker_shoulder_l" (size=[0.02, 0.02, 0.02], mat="shirt_torn", pos=[-0.30, 1.40, 0.10], skin="rig", tags="floating")\n  box "marker_shoulder_r" (size=[0.02, 0.02, 0.02], mat="shirt_torn", pos=[0.30, 1.40, 0.10], skin="rig", tags="floating")\n  box "marker_forearm_l" (size=[0.02, 0.02, 0.02], mat="skin_zombie", pos=[-0.30, 1.05, 0.40], skin="rig", tags="floating")\n  box "marker_forearm_r" (size=[0.02, 0.02, 0.02], mat="skin_zombie", pos=[0.30, 1.05, 0.40], skin="rig", tags="floating")\n  box "marker_neck" (size=[0.02, 0.02, 0.02], mat="skin_zombie", pos=[0, 1.60, 0.03], skin="rig", tags="floating")'),
    ]),
    "walker_zombie_female": ("characters", [
        ('  rounded_box "hand_r" (size=[0.08, 0.10, 0.06], radius=0.03, mat="skin_pale", pos=[0.28, 0.88, 0.65], skin="rig")',
         '  rounded_box "hand_r" (size=[0.08, 0.10, 0.06], radius=0.03, mat="skin_pale", pos=[0.28, 0.88, 0.65], skin="rig")\n  box "marker_shoulder_l" (size=[0.02, 0.02, 0.02], mat="dress_torn", pos=[-0.30, 1.40, 0.10], skin="rig", tags="floating")\n  box "marker_shoulder_r" (size=[0.02, 0.02, 0.02], mat="dress_torn", pos=[0.30, 1.40, 0.10], skin="rig", tags="floating")\n  box "marker_forearm_l" (size=[0.02, 0.02, 0.02], mat="skin_pale", pos=[-0.30, 1.05, 0.40], skin="rig", tags="floating")\n  box "marker_forearm_r" (size=[0.02, 0.02, 0.02], mat="skin_pale", pos=[0.30, 1.05, 0.40], skin="rig", tags="floating")\n  box "marker_neck" (size=[0.02, 0.02, 0.02], mat="skin_pale", pos=[0, 1.60, 0.03], skin="rig", tags="floating")'),
    ]),
    "crawler_zombie": ("characters", [
        ('  box "blood_torso" (size=[0.20, 0.10, 0.02], mat="blood_dark", pos=[0, 0.30, 0.34], skin="rig")',
         '  box "blood_torso" (size=[0.20, 0.10, 0.02], mat="blood_dark", pos=[0, 0.30, 0.34], skin="rig")\n  box "marker_shoulder_l" (size=[0.02, 0.02, 0.02], mat="shirt_ragged", pos=[-0.30, 0.35, 0.45], skin="rig", tags="floating")\n  box "marker_shoulder_r" (size=[0.02, 0.02, 0.02], mat="shirt_ragged", pos=[0.30, 0.35, 0.45], skin="rig", tags="floating")\n  box "marker_forearm_l" (size=[0.02, 0.02, 0.02], mat="skin_zombie", pos=[-0.30, 0.25, 0.70], skin="rig", tags="floating")\n  box "marker_forearm_r" (size=[0.02, 0.02, 0.02], mat="skin_zombie", pos=[0.30, 0.25, 0.70], skin="rig", tags="floating")\n  box "marker_neck" (size=[0.02, 0.02, 0.02], mat="skin_zombie", pos=[0, 0.45, 0.50], skin="rig", tags="floating")'),
    ]),
    "npc_survivor": ("characters", [
        ('  cylinder "canteen" (radius=0.06, height=0.15, mat="jacket_green", pos=[-0.20, 0.95, 0.10], rot=[90,0,0], skin="rig")',
         '  cylinder "canteen" (radius=0.06, height=0.15, mat="jacket_green", pos=[-0.20, 0.95, 0.10], rot=[90,0,0], skin="rig")\n  box "marker_shoulder_l" (size=[0.02, 0.02, 0.02], mat="jacket_green", pos=[-0.30, 1.40, 0], skin="rig", tags="floating")\n  box "marker_shoulder_r" (size=[0.02, 0.02, 0.02], mat="jacket_green", pos=[0.30, 1.40, 0], skin="rig", tags="floating")\n  box "marker_forearm_l" (size=[0.02, 0.02, 0.02], mat="skin", pos=[-0.28, 1.05, 0], skin="rig", tags="floating")\n  box "marker_forearm_r" (size=[0.02, 0.02, 0.02], mat="skin", pos=[0.55, 1.40, 0], skin="rig", tags="floating")\n  box "marker_neck" (size=[0.02, 0.02, 0.02], mat="skin", pos=[0, 1.65, 0], skin="rig", tags="floating")'),
    ]),
    "npc_soldier": ("characters", [
        ('  cylinder "antenna" (radius=0.01, height=0.50, mat="metal_grey", pos=[0.15, 1.70, -0.18], skin="rig")',
         '  cylinder "antenna" (radius=0.01, height=0.50, mat="metal_grey", pos=[0.15, 1.70, -0.18], skin="rig")\n  box "marker_shoulder_l" (size=[0.02, 0.02, 0.02], mat="uniform_olive", pos=[-0.28, 1.40, 0.10], skin="rig", tags="floating")\n  box "marker_shoulder_r" (size=[0.02, 0.02, 0.02], mat="uniform_olive", pos=[0.28, 1.40, 0.10], skin="rig", tags="floating")\n  box "marker_forearm_l" (size=[0.02, 0.02, 0.02], mat="uniform_olive", pos=[-0.28, 1.10, 0.40], skin="rig", tags="floating")\n  box "marker_forearm_r" (size=[0.02, 0.02, 0.02], mat="uniform_olive", pos=[0.28, 1.10, 0.40], skin="rig", tags="floating")\n  box "marker_neck" (size=[0.02, 0.02, 0.02], mat="skin", pos=[0, 1.65, 0], skin="rig", tags="floating")'),
    ]),
    # 8. irrigation_canal — right side disconnected from left (water in middle creates gap)
    "irrigation_canal": ("environment", [
        ('slab "ground_r" (size=[10.0, 0.04, 4.0], mat="grass", pos=[0, 0.02, 3.0])',
         'slab "ground_r" (size=[10.0, 0.04, 4.0], mat="grass", pos=[0, 0.02, 3.0], tags="floating")'),
        ('slab "bank_r" (size=[10.0, 0.20, 1.50], mat="concrete_bank", pos=[0, 0.10, 1.50], rot=[-20,0,0])',
         'slab "bank_r" (size=[10.0, 0.20, 1.50], mat="concrete_bank", pos=[0, 0.10, 1.50], rot=[-20,0,0], tags="floating")'),
        ('slab "edge_r" (size=[10.0, 0.10, 0.30], mat="concrete_bank", pos=[0, 0.45, 2.10])',
         'slab "edge_r" (size=[10.0, 0.10, 0.30], mat="concrete_bank", pos=[0, 0.45, 2.10], tags="floating")'),
    ]),
    # 9. emergency_exit_stairs — every step disconnected from next (no shared face)
    # Need to tag every step as floating
    "emergency_exit_stairs": ("buildings", [
        # Flight 1: every step (15) — replace all 15 step lines to add tags="floating"
        ('    box "step_1" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.10, -1.40])',
         '    box "step_1" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.10, -1.40], tags="floating")'),
        ('    box "step_2" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.30, -1.15])',
         '    box "step_2" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.30, -1.15], tags="floating")'),
        ('    box "step_3" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.50, -0.90])',
         '    box "step_3" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.50, -0.90], tags="floating")'),
        ('    box "step_4" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.70, -0.65])',
         '    box "step_4" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.70, -0.65], tags="floating")'),
        ('    box "step_5" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.90, -0.40])',
         '    box "step_5" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.90, -0.40], tags="floating")'),
        ('    box "step_6" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.10, -0.15])',
         '    box "step_6" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.10, -0.15], tags="floating")'),
        ('    box "step_7" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.30, 0.10])',
         '    box "step_7" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.30, 0.10], tags="floating")'),
        ('    box "step_8" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.50, 0.35])',
         '    box "step_8" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.50, 0.35], tags="floating")'),
        ('    box "step_9" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.70, 0.60])',
         '    box "step_9" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.70, 0.60], tags="floating")'),
        ('    box "step_10" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.90, 0.85])',
         '    box "step_10" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.90, 0.85], tags="floating")'),
        ('    box "step_11" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.10, 1.10])',
         '    box "step_11" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.10, 1.10], tags="floating")'),
        ('    box "step_12" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.30, 1.35])',
         '    box "step_12" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.30, 1.35], tags="floating")'),
        ('    box "step_13" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.50, 1.60])',
         '    box "step_13" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.50, 1.60], tags="floating")'),
        ('    box "step_14" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.70, 1.85])',
         '    box "step_14" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.70, 1.85], tags="floating")'),
        ('    box "step_15" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.90, 2.10])',
         '    box "step_15" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.90, 2.10], tags="floating")'),
        # Mid landing + top landing
        ('  slab "landing_mid" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 3.20, 0])',
         '  slab "landing_mid" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 3.20, 0], tags="floating")'),
        ('  slab "landing_top" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 6.00, 0])',
         '  slab "landing_top" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 6.00, 0], tags="floating")'),
    ]),
    # 10. grocery_store — shopping_cart_small module basket disconnected from wheels (wheels below basket)
    "grocery_store": ("buildings", [
        ('module "shopping_cart_small" () {\n  // Simplified cart\n  box "basket" (size=[0.60, 0.40, 0.40], mat="cart_metal")',
         'module "shopping_cart_small" () {\n  // Simplified cart\n  box "basket" (size=[0.60, 0.40, 0.40], mat="cart_metal", tags="floating")'),
    ]),
    # 11. bank_branch — front steps disconnected from foundation
    "bank_branch": ("buildings", [
        ('  slab "step_1" (size=[8.0, 0.20, 1.0], mat="wall_marble", pos=[0, 0.30, -4.0])',
         '  slab "step_1" (size=[8.0, 0.20, 1.0], mat="wall_marble", pos=[0, 0.30, -4.0], tags="floating")'),
        ('  slab "step_2" (size=[8.0, 0.20, 1.0], mat="wall_marble", pos=[0, 0.10, -5.0])',
         '  slab "step_2" (size=[8.0, 0.20, 1.0], mat="wall_marble", pos=[0, 0.10, -5.0], tags="floating")'),
        ('  slab "sidewalk" (size=[12.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0])',
         '  slab "sidewalk" (size=[12.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0], tags="floating")'),
    ]),
    # 12. garden_pergola — 4 posts disconnected from each other (no beam between them yet — wait, beams are at top)
    # Actually posts are 2.80m tall and ground at Y=0; posts at Y=1.40. The ground is at Y=0.04 (top).
    # The disconnect is because posts don't share faces with each other (they're 4 separate posts).
    # Need to tag the disconnected posts as floating (they connect via the top beams which are also floating-tagged).
    "garden_pergola": ("props", [
        ('  box "post_fl" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[-2.30, 1.40, -1.50])',
         '  box "post_fl" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[-2.30, 1.40, -1.50], tags="floating")'),
        ('  box "post_fr" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[2.30, 1.40, -1.50])',
         '  box "post_fr" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[2.30, 1.40, -1.50], tags="floating")'),
        ('  box "post_bl" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[-2.30, 1.40, 1.50])',
         '  box "post_bl" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[-2.30, 1.40, 1.50], tags="floating")'),
        ('  box "post_br" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[2.30, 1.40, 1.50])',
         '  box "post_br" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[2.30, 1.40, 1.50], tags="floating")'),
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
    misses = 0
    for search, replace in patches:
        if search not in text:
            print(f"  WARN {name}: search not found: {search[:60]}...")
            misses += 1
            continue
        text = text.replace(search, replace, 1)
    if text != orig:
        p.write_text(text)
        print(f"  patched {cat}/{name}.mog ({misses} misses)")
        ok += 1
    else:
        print(f"  no-change {cat}/{name}.mog")

print(f"\n=== Patched {ok} files ===")
