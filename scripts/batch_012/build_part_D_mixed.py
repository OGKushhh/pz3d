#!/usr/bin/env python3
"""Batch 012 — Part D — 4 decals + 3 forest + 3 farmland = 10 assets."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# ============================================================
# DECALS (4) — flat decals applied to surfaces, very low-poly
# ============================================================

w("decals", "blood_splatter", '''// blood_splatter.mog — surface blood stain decal
meta (name="blood_splatter", description="Surface blood splatter decal — irregular dark red stain", tags=["decal","blood","horror","tier1"], mogen_version="0.1.12")
material "blood_dried" (color=[0.30,0.05,0.05], roughness=0.95, transmission=0.10)
material "blood_fresh" (color=[0.55,0.08,0.05], roughness=0.70, transmission=0.20)
scene {
  // Main splatter — flat irregular blob (simulated with overlapping ellipses)
  slab "main_blood" (size=[1.20, 0.02, 1.00], mat="blood_dried")
  // Splash droplets around the main pool
  sphere "drop_1" (radius=0.10, mat="blood_fresh", pos=[0.80, 0.02, 0.30], tags="floating")
  sphere "drop_2" (radius=0.06, mat="blood_fresh", pos=[-0.60, 0.02, 0.50], tags="floating")
  sphere "drop_3" (radius=0.08, mat="blood_fresh", pos=[0.40, 0.02, -0.60], tags="floating")
  sphere "drop_4" (radius=0.05, mat="blood_fresh", pos=[-0.80, 0.02, -0.30], tags="floating")
  sphere "drop_5" (radius=0.07, mat="blood_fresh", pos=[0.20, 0.02, 0.70], tags="floating")
  // Smear trail
  slab "smear" (size=[0.60, 0.025, 0.10], mat="blood_dried", pos=[0.50, 0.015, 0.20], rot=[0,30,0], tags="floating")
  // Small spatter dots
  sphere "dot_1" (radius=0.02, mat="blood_fresh", pos=[1.00, 0.015, -0.20], tags="floating")
  sphere "dot_2" (radius=0.02, mat="blood_fresh", pos=[-0.95, 0.015, 0.10], tags="floating")
  sphere "dot_3" (radius=0.02, mat="blood_fresh", pos=[0.10, 0.015, -0.85], tags="floating")
  sphere "dot_4" (radius=0.02, mat="blood_fresh", pos=[-0.30, 0.015, 0.85], tags="floating")
}
''')

w("decals", "poster_torn", '''// poster_torn.mog — torn wall poster decal
meta (name="poster_torn", description="Torn wall poster decal — missing-missing person or propaganda poster, partially ripped", tags=["decal","poster","urban","horror","tier1"], mogen_version="0.1.12")
material "paper_white" (color=[0.88,0.86,0.78], roughness=0.85, transmission=0.10)
material "paper_dark" (color=[0.45,0.40,0.30], roughness=0.85)
material "ink_black" (color=[0.10,0.10,0.10], roughness=0.80)
material "tape_yellow" (color=[0.80,0.70,0.40], roughness=0.70, transmission=0.30)
scene {
  // Main poster — flat against wall (XZ plane lying down for now, will be repositioned)
  slab "paper_main" (size=[1.00, 0.02, 1.40], mat="paper_white")
  // Torn corner (top-right) — replaced with darker fragment
  slab "torn_corner" (size=[0.30, 0.025, 0.40], mat="paper_dark", pos=[0.35, 0.015, -0.50], rot=[0,0,-15], tags="floating")
  // Torn edge (bottom)
  slab "torn_bottom" (size=[1.00, 0.025, 0.20], mat="paper_dark", pos=[0, 0.015, 0.60], rot=[0,0,5], tags="floating")
  // Missing person text (visible printed lines)
  box "text_top" (size=[0.80, 0.025, 0.05], mat="ink_black", pos=[0, 0.025, -0.55], tags="floating")
  box "text_l_1" (size=[0.70, 0.025, 0.03], mat="ink_black", pos=[-0.10, 0.025, -0.40], tags="floating")
  box "text_l_2" (size=[0.70, 0.025, 0.03], mat="ink_black", pos=[-0.10, 0.025, -0.30], tags="floating")
  box "text_l_3" (size=[0.50, 0.025, 0.03], mat="ink_black", pos=[-0.20, 0.025, -0.20], tags="floating")
  box "text_l_4" (size=[0.60, 0.025, 0.03], mat="ink_black", pos=[-0.15, 0.025, -0.10], tags="floating")
  box "text_l_5" (size=[0.40, 0.025, 0.03], mat="ink_black", pos=[-0.25, 0.025, 0.00], tags="floating")
  box "text_l_6" (size=[0.65, 0.025, 0.03], mat="ink_black", pos=[-0.12, 0.025, 0.10], tags="floating")
  box "text_l_7" (size=[0.30, 0.025, 0.03], mat="ink_black", pos=[-0.30, 0.025, 0.20], tags="floating")
  // Photo area (rectangle suggesting a photo)
  box "photo_border" (size=[0.50, 0.025, 0.50], mat="ink_black", pos=[0, 0.025, 0.10], tags="floating")
  box "photo_inner" (size=[0.46, 0.020, 0.46], mat="paper_dark", pos=[0, 0.027, 0.10], tags="floating")
  // Tape strips (top corners)
  box "tape_tl" (size=[0.20, 0.030, 0.10], mat="tape_yellow", pos=[-0.30, 0.028, -0.60], rot=[0,0,30], tags="floating")
  box "tape_tr" (size=[0.20, 0.030, 0.10], mat="tape_yellow", pos=[0.30, 0.028, -0.60], rot=[0,0,-30], tags="floating")
  // Smaller torn bit
  slab "torn_bit" (size=[0.30, 0.020, 0.20], mat="paper_white", pos=[0.90, 0.015, 0.20], rot=[0,30,15], tags="floating")
}
''')

w("decals", "grime_dirt", '''// grime_dirt.mog — surface grime / dirt stain decal
meta (name="grime_dirt", description="Surface grime and dirt stain decal — for walls and floors", tags=["decal","grime","urban","horror","tier1"], mogen_version="0.1.12")
material "grime_dark" (color=[0.20,0.18,0.14], roughness=0.95, transmission=0.10)
material "grime_mid" (color=[0.35,0.30,0.24], roughness=0.90, transmission=0.15)
material "mold_green" (color=[0.25,0.35,0.18], roughness=0.95, transmission=0.20)
material "rust_brown" (color=[0.40,0.25,0.15], roughness=0.85)
scene {
  // Main grime — irregular patch
  slab "grime_main" (size=[2.00, 0.02, 1.50], mat="grime_dark")
  // Darker inner patch
  slab "grime_inner" (size=[1.20, 0.025, 0.80], mat="grime_mid", pos=[-0.20, 0.015, 0.10], tags="floating")
  // Drip stains (vertical streaks)
  slab "drip_1" (size=[0.10, 0.025, 0.60], mat="grime_dark", pos=[-0.60, 0.015, 0.30], tags="floating")
  slab "drip_2" (size=[0.06, 0.025, 0.40], mat="grime_dark", pos=[0.40, 0.015, -0.30], tags="floating")
  slab "drip_3" (size=[0.08, 0.025, 0.80], mat="grime_dark", pos=[0.80, 0.015, 0.10], tags="floating")
  // Mold patches (green, biological)
  slab "mold_1" (size=[0.30, 0.020, 0.20], mat="mold_green", pos=[0.40, 0.015, 0.50], tags="floating")
  slab "mold_2" (size=[0.20, 0.020, 0.30], mat="mold_green", pos=[-0.70, 0.015, -0.30], tags="floating")
  // Rust spots
  sphere "rust_1" (radius=0.08, mat="rust_brown", pos=[0.50, 0.020, -0.40], tags="floating")
  sphere "rust_2" (radius=0.06, mat="rust_brown", pos=[-0.80, 0.020, 0.40], tags="floating")
  // Tiny dots
  sphere "dot_1" (radius=0.015, mat="grime_dark", pos=[0.90, 0.015, 0.60], tags="floating")
  sphere "dot_2" (radius=0.015, mat="grime_dark", pos=[-0.90, 0.015, -0.60], tags="floating")
  sphere "dot_3" (radius=0.015, mat="grime_dark", pos=[0.20, 0.015, 0.80], tags="floating")
}
''')

w("decals", "crack_road", '''// crack_road.mog — road surface crack decal
meta (name="crack_road", description="Road surface crack decal — branching cracks and small potholes", tags=["decal","crack","road","urban","tier1"], mogen_version="0.1.12")
material "crack_dark" (color=[0.10,0.10,0.08], roughness=0.95)
material "pothole_dark" (color=[0.15,0.13,0.10], roughness=0.95)
material "asphalt_around" (color=[0.18,0.18,0.20], roughness=0.95, transmission=0.05)
scene {
  // Main asphalt patch (slightly darker than surrounding road, marking the damaged area)
  slab "asphalt_patch" (size=[3.00, 0.015, 3.00], mat="asphalt_around")
  // Main crack line (zig-zag)
  box "crack_1" (size=[0.04, 0.020, 0.50], mat="crack_dark", pos=[-1.00, 0.018, -0.80], tags="floating")
  box "crack_2" (size=[0.04, 0.020, 0.50], mat="crack_dark", pos=[-0.70, 0.018, -0.30], rot=[0,15,0], tags="floating")
  box "crack_3" (size=[0.04, 0.020, 0.60], mat="crack_dark", pos=[-0.40, 0.018, 0.20], rot=[0,-10,0], tags="floating")
  box "crack_4" (size=[0.04, 0.020, 0.50], mat="crack_dark", pos=[0.00, 0.018, 0.70], rot=[0,20,0], tags="floating")
  box "crack_5" (size=[0.04, 0.020, 0.40], mat="crack_dark", pos=[0.40, 0.018, 1.00], rot=[0,-15,0], tags="floating")
  // Branch cracks
  box "branch_1" (size=[0.03, 0.020, 0.30], mat="crack_dark", pos=[-0.50, 0.018, 0.00], rot=[0,45,0], tags="floating")
  box "branch_2" (size=[0.03, 0.020, 0.30], mat="crack_dark", pos=[-0.20, 0.018, 0.50], rot=[0,-45,0], tags="floating")
  // Pothole (bigger darker patch)
  cylinder "pothole_1" (radius=0.20, height=0.030, mat="pothole_dark", pos=[0.70, 0.020, -0.40], tags="floating")
  cylinder "pothole_2" (radius=0.15, height=0.030, mat="pothole_dark", pos=[-0.80, 0.020, 0.60], tags="floating")
  // Small fragments
  sphere "frag_1" (radius=0.04, mat="pothole_dark", pos=[0.50, 0.018, -0.20], tags="floating")
  sphere "frag_2" (radius=0.03, mat="pothole_dark", pos=[-0.60, 0.018, 0.80], tags="floating")
}
''')

# ============================================================
# FOREST FILLS (3)
# ============================================================

w("buildings", "cave_entrance", '''// cave_entrance.mog — rocky cave entrance in hillside
meta (name="cave_entrance", description="Rocky cave entrance in hillside — dark maw with boulders around opening", tags=["building","forest","cave","natural","tier1"], mogen_version="0.1.12")
material "rock_grey" (color=[0.45,0.43,0.40], roughness=0.90, uv_mode="tile", uv_scale=3.0)
material "rock_dark" (color=[0.30,0.28,0.25], roughness=0.95)
material "hill_green" (color=[0.22,0.35,0.16], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "cave_black" (color=[0.05,0.05,0.05], roughness=0.95, transmission=0.10)
material "moss_green" (color=[0.30,0.45,0.18], roughness=0.95, transmission=0.20)
scene {
  // Hill behind cave
  box "hill_base" (size=[12.0, 5.0, 5.0], mat="hill_green", pos=[0, 2.50, 1.5])
  box "hill_top" (size=[10.0, 3.0, 4.0], mat="hill_green", pos=[0, 5.00, 2.0])
  // Rocky face around opening
  box "rock_face" (size=[6.0, 4.5, 0.50], mat="rock_grey", pos=[0, 2.25, -1.00])
  // Cave opening (oval — approximated with box + dark interior)
  box "opening" (size=[2.50, 3.0, 0.50], mat="cave_black", pos=[0, 1.70, -1.20], tags="floating")
  // Dark interior (tunnel going back)
  box "interior" (size=[2.20, 2.5, 3.0], mat="cave_black", pos=[0, 1.70, -2.50], tags="floating")
  // Boulders around entrance
  sphere "boulder_l" (radius=0.60, mat="rock_grey", pos=[-2.0, 0.50, -0.50], tags="floating")
  sphere "boulder_r" (radius=0.50, mat="rock_grey", pos=[2.0, 0.40, -0.50], tags="floating")
  sphere "boulder_top" (radius=0.70, mat="rock_grey", pos=[0, 4.20, -0.80], tags="floating")
  sphere "boulder_small_1" (radius=0.30, mat="rock_dark", pos=[-1.20, 0.20, -1.20], tags="floating")
  sphere "boulder_small_2" (radius=0.25, mat="rock_dark", pos=[1.30, 0.20, -1.20], tags="floating")
  // Moss patches on rocks
  slab "moss_1" (size=[0.50, 0.05, 0.40], mat="moss_green", pos=[-2.20, 0.85, -0.50], tags="floating")
  slab "moss_2" (size=[0.40, 0.05, 0.50], mat="moss_green", pos=[1.80, 0.75, -0.50], tags="floating")
  // Stalactite hint (hanging from top of opening)
  cone "stalactite_1" (radius=0.10, height=0.40, mat="rock_dark", pos=[-0.50, 3.10, -1.20], tags="floating")
  cone "stalactite_2" (radius=0.08, height=0.30, mat="rock_dark", pos=[0.40, 3.00, -1.20], tags="floating")
}
''')

w("buildings", "logging_camp_shed", '''// logging_camp_shed.mog — small logging camp storage shed with saw
meta (name="logging_camp_shed", description="Small logging camp storage shed with chainsaw and stacked logs", tags=["building","forest","logging","industrial","tier1"], mogen_version="0.1.12")
material "wall_wood" (color=[0.40,0.28,0.18], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_metal" (color=[0.40,0.38,0.36], roughness=0.60, metallic=0.6)
material "log_tan" (color=[0.55,0.42,0.25], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "log_dark" (color=[0.30,0.20,0.12], roughness=0.85)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "concrete" (color=[0.50,0.48,0.45], roughness=0.90)
scene {
  slab "ground" (size=[10.0, 0.04, 8.0], mat="grass", tags="floating")
  slab "foundation" (size=[5.0, 0.20, 4.0], mat="concrete", pos=[0, 0.10, 0])
  // Open-front shed (3 walls + roof)
  wall "back_wall" (size=[5.0, 2.5, 0.10], pos=[0, 1.30, 2.0], mat="wall_wood")
  wall "left_wall" (size=[4.0, 2.5, 0.10], pos=[-2.5, 1.30, 0], rot=[0,90,0], mat="wall_wood")
  wall "right_wall" (size=[4.0, 2.5, 0.10], pos=[2.5, 1.30, 0], rot=[0,90,0], mat="wall_wood")
  // Roof (corrugated metal, sloped)
  slab "roof" (size=[5.5, 0.08, 4.5], mat="roof_metal", pos=[0, 2.55, 0], rot=[5,0,0], tags="floating")
  // Front posts
  box "post_fl" (size=[0.15, 2.5, 0.15], mat="wall_wood", pos=[-2.4, 1.30, -2.0], tags="floating")
  box "post_fr" (size=[0.15, 2.5, 0.15], mat="wall_wood", pos=[2.4, 1.30, -2.0], tags="floating")
  // Lintel across front
  box "lintel" (size=[5.0, 0.20, 0.20], mat="wall_wood", pos=[0, 2.40, -2.0], tags="floating")
  // Stacked logs (3 piles, each pile = 3 logs)
  // Pile 1 (left)
  cylinder "log_p1_1" (radius=0.20, height=2.0, mat="log_tan", pos=[-1.50, 0.30, -1.0], rot=[0,0,90], tags="floating")
  cylinder "log_p1_2" (radius=0.20, height=2.0, mat="log_dark", pos=[-1.50, 0.70, -0.80], rot=[0,0,90], tags="floating")
  cylinder "log_p1_3" (radius=0.20, height=2.0, mat="log_tan", pos=[-1.50, 0.30, -0.60], rot=[0,0,90], tags="floating")
  // Pile 2 (right)
  cylinder "log_p2_1" (radius=0.20, height=2.0, mat="log_tan", pos=[1.50, 0.30, -1.0], rot=[0,0,90], tags="floating")
  cylinder "log_p2_2" (radius=0.20, height=2.0, mat="log_dark", pos=[1.50, 0.70, -0.80], rot=[0,0,90], tags="floating")
  cylinder "log_p2_3" (radius=0.20, height=2.0, mat="log_tan", pos=[1.50, 0.30, -0.60], rot=[0,0,90], tags="floating")
  // Chainsaw (on workbench)
  box "workbench" (size=[2.0, 0.10, 0.80], mat="log_dark", pos=[0, 0.80, 1.0], tags="floating")
  box "bench_leg_1" (size=[0.10, 0.80, 0.10], mat="log_dark", pos=[-0.90, 0.40, 1.0], tags="floating")
  box "bench_leg_2" (size=[0.10, 0.80, 0.10], mat="log_dark", pos=[0.90, 0.40, 1.0], tags="floating")
  // Chainsaw body (small dark box + bar)
  box "saw_body" (size=[0.40, 0.20, 0.20], mat="metal_dark", pos=[-0.20, 0.95, 1.0], tags="floating")
  box "saw_handle" (size=[0.30, 0.10, 0.10], mat="log_dark", pos=[-0.20, 1.10, 1.0], tags="floating")
  box "saw_bar" (size=[0.06, 0.10, 0.50], mat="metal_dark", pos=[0.05, 0.95, 1.0], tags="floating")
  // Axe leaning on post
  cylinder "axe_handle" (radius=0.03, height=0.80, mat="log_tan", pos=[2.30, 0.50, -1.80], rot=[0,0,15], tags="floating")
  box "axe_head" (size=[0.15, 0.20, 0.05], mat="metal_dark", pos=[2.45, 0.85, -1.80], tags="floating")
}
''')

w("buildings", "ranger_lean_to", '''// ranger_lean_to.mog — simple 3-post lean-to shelter with sloped roof
meta (name="ranger_lean_to", description="Simple forest lean-to shelter — 3 posts, sloped roof, open front, fire ring in front", tags=["building","forest","shelter","simple","tier1"], mogen_version="0.1.12")
material "wood_dark" (color=[0.30,0.20,0.12], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_wood" (color=[0.25,0.18,0.10], roughness=0.85)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "stone_grey" (color=[0.50,0.48,0.45], roughness=0.90)
material "log_dark" (color=[0.30,0.20,0.12], roughness=0.85)
scene {
  slab "ground" (size=[8.0, 0.04, 8.0], mat="grass", tags="floating")
  // 3 back posts (taller) + 1 front post (shorter, creates the lean)
  box "post_bl_l" (size=[0.15, 2.50, 0.15], mat="wood_dark", pos=[-1.80, 1.25, 1.50], tags="floating")
  box "post_bl_c" (size=[0.15, 2.50, 0.15], mat="wood_dark", pos=[0, 1.25, 1.50], tags="floating")
  box "post_bl_r" (size=[0.15, 2.50, 0.15], mat="wood_dark", pos=[1.80, 1.25, 1.50], tags="floating")
  // Front posts (shorter)
  box "post_fl_l" (size=[0.15, 1.50, 0.15], mat="wood_dark", pos=[-1.80, 0.75, -1.50], tags="floating")
  box "post_fl_r" (size=[0.15, 1.50, 0.15], mat="wood_dark", pos=[1.80, 0.75, -1.50], tags="floating")
  // Roof (sloped from back-high to front-low)
  slab "roof" (size=[4.0, 0.10, 3.5], mat="roof_wood", pos=[0, 1.95, 0], rot=[30,0,0], tags="floating")
  // Back wall (3 horizontal logs)
  cylinder "back_log_1" (radius=0.10, height=4.0, mat="log_dark", pos=[0, 0.20, 1.55], rot=[0,90,0], tags="floating")
  cylinder "back_log_2" (radius=0.10, height=4.0, mat="log_dark", pos=[0, 0.60, 1.55], rot=[0,90,0], tags="floating")
  cylinder "back_log_3" (radius=0.10, height=4.0, mat="log_dark", pos=[0, 1.00, 1.55], rot=[0,90,0], tags="floating")
  // Side walls (small sections, log-built)
  cylinder "side_l_1" (radius=0.10, height=3.0, mat="log_dark", pos=[-1.85, 0.30, 0], rot=[90,0,0], tags="floating")
  cylinder "side_l_2" (radius=0.10, height=3.0, mat="log_dark", pos=[-1.85, 0.70, 0], rot=[90,0,0], tags="floating")
  cylinder "side_r_1" (radius=0.10, height=3.0, mat="log_dark", pos=[1.85, 0.30, 0], rot=[90,0,0], tags="floating")
  cylinder "side_r_2" (radius=0.10, height=3.0, mat="log_dark", pos=[1.85, 0.70, 0], rot=[90,0,0], tags="floating")
  // Sleeping platform (raised wood)
  slab "platform" (size=[3.0, 0.10, 1.50], mat="wood_dark", pos=[0, 0.40, 0.80], tags="floating")
  // Fire ring in front (small circle of stones)
  sphere "fire_stone_1" (radius=0.20, mat="stone_grey", pos=[-0.50, 0.20, -2.50], tags="floating")
  sphere "fire_stone_2" (radius=0.18, mat="stone_grey", pos=[-0.20, 0.20, -2.80], tags="floating")
  sphere "fire_stone_3" (radius=0.22, mat="stone_grey", pos=[0.30, 0.20, -2.80], tags="floating")
  sphere "fire_stone_4" (radius=0.18, mat="stone_grey", pos=[0.60, 0.20, -2.50], tags="floating")
  sphere "fire_stone_5" (radius=0.20, mat="stone_grey", pos=[0.30, 0.20, -2.20], tags="floating")
  sphere "fire_stone_6" (radius=0.18, mat="stone_grey", pos=[-0.20, 0.20, -2.20], tags="floating")
  // Ash pit
  cylinder "ash" (radius=0.40, height=0.04, mat="wood_dark", pos=[0, 0.04, -2.50], tags="floating")
  // Woodpile beside lean-to
  cylinder "wood_1" (radius=0.10, height=1.5, mat="log_dark", pos=[2.30, 0.30, 1.0], rot=[0,0,90], tags="floating")
  cylinder "wood_2" (radius=0.10, height=1.5, mat="log_dark", pos=[2.30, 0.50, 1.0], rot=[0,0,90], tags="floating")
  cylinder "wood_3" (radius=0.10, height=1.5, mat="log_dark", pos=[2.30, 0.30, 0.80], rot=[0,0,90], tags="floating")
}
''')

# ============================================================
# FARMLAND FILLS (3)
# ============================================================

w("environment", "irrigation_canal", '''// irrigation_canal.mog — 10m irrigation canal section with water
meta (name="irrigation_canal", description="10m irrigation canal section with concrete banks and slow water flow", tags=["environment","farmland","water","canal","tier1"], mogen_version="0.1.12")
material "concrete_bank" (color=[0.60,0.58,0.55], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "water_canal" (color=[0.20,0.35,0.45], roughness=0.10, transmission=0.40, metallic=0.2)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "soil_dark" (color=[0.30,0.22,0.14], roughness=0.95, uv_mode="tile", uv_scale=3.0)
scene {
  // Ground on both sides of canal
  slab "ground_l" (size=[10.0, 0.04, 4.0], mat="grass", pos=[0, 0.02, -3.0])
  slab "ground_r" (size=[10.0, 0.04, 4.0], mat="grass", pos=[0, 0.02, 3.0])
  // Canal banks (sloped concrete, V-shape cross-section)
  slab "bank_l" (size=[10.0, 0.20, 1.50], mat="concrete_bank", pos=[0, 0.10, -1.50], rot=[20,0,0])
  slab "bank_r" (size=[10.0, 0.20, 1.50], mat="concrete_bank", pos=[0, 0.10, 1.50], rot=[-20,0,0])
  // Water surface (flat, slightly below bank top)
  slab "water" (size=[10.0, 0.04, 1.0], mat="water_canal", pos=[0, 0.30, 0], tags="floating")
  // Concrete canal edge (lip at top of bank)
  slab "edge_l" (size=[10.0, 0.10, 0.30], mat="concrete_bank", pos=[0, 0.45, -2.10])
  slab "edge_r" (size=[10.0, 0.10, 0.30], mat="concrete_bank", pos=[0, 0.45, 2.10])
  // Control gate (sluice) at one end
  box "gate_frame_l" (size=[0.20, 1.50, 2.50], mat="concrete_bank", pos=[-4.90, 0.75, 0], tags="floating")
  box "gate_frame_r" (size=[0.20, 1.50, 2.50], mat="concrete_bank", pos=[4.90, 0.75, 0], tags="floating")
  // Sluice gate (vertical metal plate, half-raised)
  box "sluice" (size=[0.10, 0.80, 1.80], mat="concrete_bank", pos=[0, 0.60, 0], tags="floating")
  // Gate handle (above)
  cylinder "gate_handle" (radius=0.10, height=0.40, mat="concrete_bank", pos=[0, 1.80, 0], tags="floating")
  cylinder "gate_stem" (radius=0.04, height=1.00, mat="concrete_bank", pos=[0, 1.30, 0], tags="floating")
  // Soil patches (where farmers plant)
  slab "soil_l" (size=[10.0, 0.06, 2.0], mat="soil_dark", pos=[0, 0.03, -3.5], tags="floating")
  slab "soil_r" (size=[10.0, 0.06, 2.0], mat="soil_dark", pos=[0, 0.03, 3.5], tags="floating")
}
''')

w("environment", "hay_bale", '''// hay_bale.mog — large round hay bale
meta (name="hay_bale", description="Large round hay bale — cylindrical straw bale wrapped in netting", tags=["environment","farmland","hay","prop","tier1"], mogen_version="0.1.12")
material "hay_yellow" (color=[0.78,0.65,0.30], roughness=0.95, uv_mode="tile", uv_scale=8.0)
material "hay_dark" (color=[0.55,0.45,0.20], roughness=0.95, uv_mode="tile", uv_scale=6.0)
material "net_white" (color=[0.85,0.85,0.80], roughness=0.85, transmission=0.30)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
scene {
  slab "ground" (size=[4.0, 0.04, 4.0], mat="grass", tags="floating")
  // Main bale body — large cylinder lying on its side
  cylinder "bale_body" (radius=0.80, height=1.60, mat="hay_yellow", pos=[0, 0.80, 0], rot=[0,90,0])
  // Darker hay rings (visible texture lines)
  torus "ring_1" (radius=0.81, tube_radius=0.03, mat="hay_dark", pos=[-0.60, 0.80, 0], rot=[90,0,0], tags="floating")
  torus "ring_2" (radius=0.81, tube_radius=0.03, mat="hay_dark", pos=[-0.30, 0.80, 0], rot=[90,0,0], tags="floating")
  torus "ring_3" (radius=0.81, tube_radius=0.03, mat="hay_dark", pos=[0, 0.80, 0], rot=[90,0,0], tags="floating")
  torus "ring_4" (radius=0.81, tube_radius=0.03, mat="hay_dark", pos=[0.30, 0.80, 0], rot=[90,0,0], tags="floating")
  torus "ring_5" (radius=0.81, tube_radius=0.03, mat="hay_dark", pos=[0.60, 0.80, 0], rot=[90,0,0], tags="floating")
  // Net wrap (cylindrical, slightly larger than bale)
  cylinder "net_wrap" (radius=0.82, height=1.65, mat="net_white", pos=[0, 0.80, 0], rot=[0,90,0], tags="floating")
  // End cap texture (visible hay strands on flat end)
  box "end_l_strand_1" (size=[0.04, 0.40, 0.10], mat="hay_dark", pos=[-0.81, 0.80, 0], tags="floating")
  box "end_l_strand_2" (size=[0.04, 0.30, 0.15], mat="hay_dark", pos=[-0.81, 0.60, -0.20], tags="floating")
  box "end_l_strand_3" (size=[0.04, 0.50, 0.08], mat="hay_dark", pos=[-0.81, 0.90, 0.20], tags="floating")
  box "end_r_strand_1" (size=[0.04, 0.40, 0.10], mat="hay_dark", pos=[0.81, 0.80, 0], tags="floating")
  box "end_r_strand_2" (size=[0.04, 0.30, 0.15], mat="hay_dark", pos=[0.81, 0.60, 0.20], tags="floating")
  box "end_r_strand_3" (size=[0.04, 0.50, 0.08], mat="hay_dark", pos=[0.81, 0.90, -0.20], tags="floating")
  // Loose hay scattered on ground
  box "scatter_1" (size=[0.30, 0.04, 0.20], mat="hay_yellow", pos=[1.50, 0.04, 0.50], rot=[0,20,0], tags="floating")
  box "scatter_2" (size=[0.20, 0.04, 0.30], mat="hay_yellow", pos=[-1.50, 0.04, 0.30], rot=[0,-15,0], tags="floating")
  box "scatter_3" (size=[0.40, 0.04, 0.15], mat="hay_dark", pos=[1.30, 0.04, -0.80], rot=[0,30,0], tags="floating")
}
''')

w("buildings", "grain_storage_shed", '''// grain_storage_shed.mog — open-sided grain storage shed with silos
meta (name="grain_storage_shed", description="Open-sided grain storage shed with 2 small silos and conveyor", tags=["building","farmland","industrial","storage","tier1"], mogen_version="0.1.12")
material "wall_metal" (color=[0.45,0.42,0.40], roughness=0.60, metallic=0.6, uv_mode="tile", uv_scale=4.0)
material "roof_metal" (color=[0.40,0.38,0.36], roughness=0.60, metallic=0.6)
material "silo_white" (color=[0.92,0.90,0.85], roughness=0.70, uv_mode="tile", uv_scale=4.0)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "grain_yellow" (color=[0.78,0.65,0.30], roughness=0.95, uv_mode="tile", uv_scale=2.0)
scene {
  slab "ground" (size=[14.0, 0.04, 10.0], mat="grass", tags="floating")
  slab "foundation" (size=[10.0, 0.20, 6.0], mat="concrete", pos=[0, 0.10, 0])
  // Open shed — 4 posts + roof
  box "post_fl" (size=[0.20, 3.50, 0.20], mat="metal_dark", pos=[-4.80, 1.75, -2.80], tags="floating")
  box "post_fr" (size=[0.20, 3.50, 0.20], mat="metal_dark", pos=[4.80, 1.75, -2.80], tags="floating")
  box "post_bl" (size=[0.20, 3.50, 0.20], mat="metal_dark", pos=[-4.80, 1.75, 2.80], tags="floating")
  box "post_br" (size=[0.20, 3.50, 0.20], mat="metal_dark", pos=[4.80, 1.75, 2.80], tags="floating")
  // Back wall (partial — lower half)
  wall "back_wall_low" (size=[10.0, 1.50, 0.10], pos=[0, 0.85, 2.80], mat="wall_metal")
  // Side walls (partial)
  wall "left_wall_low" (size=[6.0, 1.50, 0.10], pos=[-4.80, 0.85, 0], rot=[0,90,0], mat="wall_metal")
  wall "right_wall_low" (size=[6.0, 1.50, 0.10], pos=[4.80, 0.85, 0], rot=[0,90,0], mat="wall_metal")
  // Roof (low slope)
  slab "roof" (size=[10.5, 0.10, 6.5], mat="roof_metal", pos=[0, 3.55, 0], rot=[3,0,0], tags="floating")
  // 2 small silos (left side, inside shed)
  cylinder "silo_1_body" (radius=1.00, height=4.50, mat="silo_white", pos=[-2.50, 2.30, 0])
  cone "silo_1_cap" (radius=1.10, height=0.80, mat="metal_dark", pos=[-2.50, 4.90, 0], tags="floating")
  cylinder "silo_2_body" (radius=1.00, height=4.50, mat="silo_white", pos=[0, 2.30, 0])
  cone "silo_2_cap" (radius=1.10, height=0.80, mat="metal_dark", pos=[0, 4.90, 0], tags="floating")
  // Silo bands (corrugation rings)
  torus "silo_1_band_1" (radius=1.02, tube_radius=0.04, mat="silo_white", pos=[-2.50, 1.50, 0], rot=[90,0,0], tags="floating")
  torus "silo_1_band_2" (radius=1.02, tube_radius=0.04, mat="silo_white", pos=[-2.50, 3.50, 0], rot=[90,0,0], tags="floating")
  torus "silo_2_band_1" (radius=1.02, tube_radius=0.04, mat="silo_white", pos=[0, 1.50, 0], rot=[90,0,0], tags="floating")
  torus "silo_2_band_2" (radius=1.02, tube_radius=0.04, mat="silo_white", pos=[0, 3.50, 0], rot=[90,0,0], tags="floating")
  // Auger conveyor (going from silo to truck-loading spout)
  cylinder "auger" (radius=0.10, height=4.50, mat="metal_dark", pos=[1.50, 2.50, -1.50], rot=[45,0,30], tags="floating")
  // Loading spout (vertical pipe)
  cylinder "spout" (radius=0.15, height=1.50, mat="metal_dark", pos=[3.20, 1.50, -1.50], tags="floating")
  // Grain pile (on ground, in front of spout)
  cone "grain_pile" (radius=0.80, height=0.50, mat="grain_yellow", pos=[3.20, 0.30, -1.50], tags="floating")
  // Ladder on side of silo 1
  box "ladder_l" (size=[0.05, 4.0, 0.05], mat="metal_dark", pos=[-3.40, 2.30, 0.95], tags="floating")
  box "ladder_r" (size=[0.05, 4.0, 0.05], mat="metal_dark", pos=[-3.20, 2.30, 0.95], tags="floating")
  box "rung_1" (size=[0.25, 0.04, 0.04], mat="metal_dark", pos=[-3.30, 1.0, 0.95], tags="floating")
  box "rung_2" (size=[0.25, 0.04, 0.04], mat="metal_dark", pos=[-3.30, 1.5, 0.95], tags="floating")
  box "rung_3" (size=[0.25, 0.04, 0.04], mat="metal_dark", pos=[-3.30, 2.0, 0.95], tags="floating")
  box "rung_4" (size=[0.25, 0.04, 0.04], mat="metal_dark", pos=[-3.30, 2.5, 0.95], tags="floating")
  box "rung_5" (size=[0.25, 0.04, 0.04], mat="metal_dark", pos=[-3.30, 3.0, 0.95], tags="floating")
  box "rung_6" (size=[0.25, 0.04, 0.04], mat="metal_dark", pos=[-3.30, 3.5, 0.95], tags="floating")
}
''')

print("\n=== Part D: 4 decals + 3 forest + 3 farmland = 10 assets written ===")
