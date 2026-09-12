#!/usr/bin/env python3
"""Batch 011 — Part 2 of 4 — Forest (4) + River/Coastal (5) + Military (5)."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# ============================================================
# 11. hunting_cabin.mog — log cabin with porch
# ============================================================
w("buildings", "hunting_cabin", '''// hunting_cabin.mog — Forest log cabin with covered porch
meta (name="hunting_cabin", description="Forest log cabin with covered porch and antler mount", tags=["building","forest","cabin","tier1"], mogen_version="0.1.12")
material "log_dark" (color=[0.30,0.20,0.12], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "log_light" (color=[0.45,0.32,0.20], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "roof_wood" (color=[0.25,0.18,0.10], roughness=0.80, uv_mode="tile", uv_scale=3.0)
material "trim_dark" (color=[0.20,0.15,0.10], roughness=0.85)
material "window_amber" (color=[0.65,0.55,0.30], transmission=0.30, roughness=0.10, emissive=[0.40,0.30,0.15], emissive_strength=0.6)
material "door_wood" (color=[0.20,0.12,0.08], roughness=0.65)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
module "hc_win" () {
  box "frame" (size=[0.70, 0.80, 0.06], mat="trim_dark")
  box "glass" (size=[0.55, 0.65, 0.02], mat="window_amber", pos=[0,0,-0.04])
}
scene {
  slab "ground" (size=[14.0, 0.04, 12.0], mat="grass")
  slab "foundation" (size=[6.0, 0.30, 5.0], mat="concrete", pos=[0, 0.15, 0])
  // Log walls — simulate horizontal log courses with stacked boxes
  box "log_row_1" (size=[6.0, 0.30, 0.25], mat="log_dark", pos=[0, 0.45, -2.5])
  box "log_row_2" (size=[6.0, 0.30, 0.25], mat="log_light", pos=[0, 0.75, -2.5])
  box "log_row_3" (size=[6.0, 0.30, 0.25], mat="log_dark", pos=[0, 1.05, -2.5])
  box "log_row_4" (size=[6.0, 0.30, 0.25], mat="log_light", pos=[0, 1.35, -2.5])
  box "log_row_5" (size=[6.0, 0.30, 0.25], mat="log_dark", pos=[0, 1.65, -2.5])
  // Use a real wall primitive for back (solid)
  wall "back_wall" (size=[6.0, 2.20, 0.20], pos=[0, 1.40, 2.5], mat="log_dark")
  wall "left_wall" (size=[5.0, 2.20, 0.20], pos=[-3.0, 1.40, 0], rot=[0,90,0], mat="log_dark")
  wall "right_wall" (size=[5.0, 2.20, 0.20], pos=[3.0, 1.40, 0], rot=[0,90,0], mat="log_dark")
  // Front wall with door + window holes
  wall "front_l" (size=[6.0, 2.20, 0.20], pos=[0, 1.40, -2.5], mat="log_dark", holes=[[-1.5,-0.30,1.00,2.00],[1.5,0.30,0.80,0.80]])
  // Roof
  prism "roof" (size=[6.5, 1.50, 5.5], pos=[0, 3.30, 0], mat="roof_wood")
  // Chimney
  box "chimney" (size=[0.40, 1.50, 0.40], mat="concrete", pos=[1.5, 3.80, 0], tags="floating")
  box "chim_cap" (size=[0.50, 0.10, 0.50], mat="metal_dark", pos=[1.5, 4.55, 0], tags="floating")
  // Porch overhang
  slab "porch_roof" (size=[6.5, 0.10, 1.5], mat="roof_wood", pos=[0, 2.30, -3.5])
  box "porch_post_l" (size=[0.15, 2.30, 0.15], mat="trim_dark", pos=[-2.9, 1.15, -3.5], tags="floating")
  box "porch_post_r" (size=[0.15, 2.30, 0.15], mat="trim_dark", pos=[2.9, 1.15, -3.5], tags="floating")
  slab "porch_floor" (size=[6.0, 0.10, 1.5], mat="log_light", pos=[0, 0.05, -3.5])
  // Antler mount on front wall
  box "antler_l" (size=[0.05, 0.40, 0.15], mat="trim_dark", pos=[-0.30, 1.90, -2.60], rot=[0,0,30], tags="floating")
  box "antler_r" (size=[0.05, 0.40, 0.15], mat="trim_dark", pos=[0.30, 1.90, -2.60], rot=[0,0,-30], tags="floating")
  // Group placements
  group "door_g" (pos=[-1.5, 1.20, -2.5]) {
    box "door_frame" (size=[1.10, 2.10, 0.06], mat="trim_dark")
    box "door" (size=[0.95, 1.95, 0.05], mat="door_wood", pos=[0,0,-0.08])
  }
  group "win_g" (pos=[1.5, 1.90, -2.5]) { use "hc_win" () }
  // Side windows
  group "wls" (pos=[-3.0, 1.70, 0], rot=[0,90,0]) { use "hc_win" () }
  group "wrs" (pos=[3.0, 1.70, 0], rot=[0,90,0]) { use "hc_win" () }
}
''')

# ============================================================
# 12. ranger_station.mog — small wooden ranger building
# ============================================================
w("buildings", "ranger_station", '''// ranger_station.mog — Forest ranger station with flagpole
meta (name="ranger_station", description="Small wooden ranger station with flagpole and signage", tags=["building","forest","ranger","tier1"], mogen_version="0.1.12")
material "wall_wood" (color=[0.55,0.40,0.25], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_dark" (color=[0.35,0.25,0.15], roughness=0.85)
material "roof_green" (color=[0.20,0.35,0.18], roughness=0.80, uv_mode="tile", uv_scale=3.0)
material "trim_cream" (color=[0.90,0.88,0.82], roughness=0.60)
material "window_glass" (color=[0.40,0.55,0.65], transmission=0.45, roughness=0.05)
material "door_wood" (color=[0.25,0.15,0.08], roughness=0.65)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "flag_green" (color=[0.20,0.45,0.20], roughness=0.70)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
module "rs2_win" () {
  chamfered_box "frame" (size=[1.00, 1.00, 0.06], radius=0.015, mat="trim_cream")
  box "glass" (size=[0.85, 0.85, 0.02], mat="window_glass", pos=[0,0,-0.03])
}
module "rs2_door" () {
  chamfered_box "frame" (size=[1.10, 2.10, 0.06], radius=0.02, mat="trim_cream")
  chamfered_box "panel" (size=[0.95, 1.95, 0.05], radius=0.015, mat="door_wood", pos=[0,0,-0.08])
}
scene {
  slab "ground" (size=[14.0, 0.04, 12.0], mat="grass")
  slab "foundation" (size=[7.0, 0.30, 5.0], mat="concrete", pos=[0, 0.15, 0])
  // Body
  box "body" (size=[7.0, 2.50, 5.0], mat="wall_wood", pos=[0, 1.55, 0])
  // Lower accent band
  box "lower_band" (size=[7.05, 0.60, 5.05], mat="wall_dark", pos=[0, 0.55, 0])
  // Roof
  prism "roof" (size=[7.5, 1.20, 5.5], pos=[0, 2.95, 0], mat="roof_green")
  // Flagpole
  cylinder "pole" (radius=0.05, height=5.0, mat="metal_dark", pos=[3.5, 3.10, -2.5], tags="floating")
  box "flag" (size=[0.8, 0.5, 0.02], mat="flag_green", pos=[3.9, 4.5, -2.5], tags="floating")
  // Sign on front
  box "sign" (size=[2.0, 0.6, 0.10], mat="trim_cream", pos=[0, 2.20, -2.55], tags="floating")
  // Holes
  wall "front_wall" (size=[7.0, 2.50, 0.20], pos=[0, 1.55, -2.5], holes=[[0.0,-0.20,1.10,2.10],[-2.20,0.30,1.00,1.00],[2.20,0.30,1.00,1.00]])
  wall "back_wall" (size=[7.0, 2.50, 0.20], pos=[0, 1.55, 2.5], holes=[[-2.00,0.30,1.00,1.00],[0.0,0.30,1.00,1.00],[2.00,0.30,1.00,1.00]])
  wall "left_wall" (size=[5.0, 2.50, 0.20], pos=[-3.5, 1.55, 0], rot=[0,90,0], holes=[[0.0,0.30,1.00,1.00]])
  wall "right_wall" (size=[5.0, 2.50, 0.20], pos=[3.5, 1.55, 0], rot=[0,90,0], holes=[[0.0,0.30,1.00,1.00]])
  // Group placements
  group "door_g" (pos=[0, 1.05, -2.5]) { use "rs2_door" () }
  group "wf_l" (pos=[-2.20, 1.85, -2.5]) { use "rs2_win" () }
  group "wf_r" (pos=[2.20, 1.85, -2.5]) { use "rs2_win" () }
  group "wb_l" (pos=[-2.0, 1.85, 2.5]) { use "rs2_win" () }
  group "wb_c" (pos=[0, 1.85, 2.5]) { use "rs2_win" () }
  group "wb_r" (pos=[2.0, 1.85, 2.5]) { use "rs2_win" () }
  group "wl" (pos=[-3.5, 1.85, 0], rot=[0,90,0]) { use "rs2_win" () }
  group "wr" (pos=[3.5, 1.85, 0], rot=[0,90,0]) { use "rs2_win" () }
}
''')

# ============================================================
# 13. camping_tent.mog — small dome tent
# ============================================================
w("buildings", "camping_tent", '''// camping_tent.mog — small dome camping tent
meta (name="camping_tent", description="Small 2-person dome camping tent with rain fly", tags=["building","forest","camping","prop","tier1"], mogen_version="0.1.12")
material "tent_orange" (color=[0.85,0.55,0.20], roughness=0.85, transmission=0.10)
material "fly_green" (color=[0.30,0.40,0.20], roughness=0.85)
material "pole_metal" (color=[0.40,0.40,0.42], roughness=0.40, metallic=0.85)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "mesh_black" (color=[0.10,0.10,0.10], roughness=0.70)
scene {
  slab "ground" (size=[6.0, 0.04, 6.0], mat="grass")
  // Tent body — half-cylinder (use cylinder rotated)
  cylinder "tent_body" (radius=1.20, height=2.50, mat="tent_orange", pos=[0, 1.20, 0], rot=[0,0,90])
  // Rain fly — slightly larger, separate
  cylinder "rain_fly" (radius=1.30, height=2.60, mat="fly_green", pos=[0, 1.25, 0], rot=[0,0,90])
  // Door flap (open)
  box "door_flap_l" (size=[0.02, 1.50, 0.80], mat="tent_orange", pos=[-0.70, 0.75, 1.25], rot=[0,0,-30], tags="floating")
  box "door_flap_r" (size=[0.02, 1.50, 0.80], mat="tent_orange", pos=[0.70, 0.75, 1.25], rot=[0,0,30], tags="floating")
  // Mesh window
  box "mesh" (size=[0.50, 0.40, 0.02], mat="mesh_black", pos=[0, 1.40, -1.30], tags="floating")
  // Poles (visible arches at front + back)
  torus "pole_front" (radius=1.20, tube_radius=0.04, mat="pole_metal", pos=[0, 1.20, 1.25], rot=[0,0,90], tags="floating")
  torus "pole_back" (radius=1.20, tube_radius=0.04, mat="pole_metal", pos=[0, 1.20, -1.25], rot=[0,0,90], tags="floating")
  // Stakes (small)
  box "stake_fl" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[-1.30, 0.15, 1.20], tags="floating")
  box "stake_fr" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[1.30, 0.15, 1.20], tags="floating")
  box "stake_bl" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[-1.30, 0.15, -1.20], tags="floating")
  box "stake_br" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[1.30, 0.15, -1.20], tags="floating")
}
''')

# ============================================================
# 14. deer_stand.mog — elevated wooden hunting platform
# ============================================================
w("buildings", "deer_stand", '''// deer_stand.mog — elevated wooden hunting platform (deer stand)
meta (name="deer_stand", description="Elevated wooden hunting platform (deer stand) with ladder and railing", tags=["building","forest","hunting","tier1"], mogen_version="0.1.12")
material "wood_brown" (color=[0.45,0.32,0.20], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wood_dark" (color=[0.30,0.20,0.12], roughness=0.85)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "ground" (size=[6.0, 0.04, 6.0], mat="grass")
  // 4 support legs (3m tall)
  box "leg_fl" (size=[0.15, 3.0, 0.15], mat="wood_dark", pos=[-1.0, 1.50, -1.0], tags="floating")
  box "leg_fr" (size=[0.15, 3.0, 0.15], mat="wood_dark", pos=[1.0, 1.50, -1.0], tags="floating")
  box "leg_bl" (size=[0.15, 3.0, 0.15], mat="wood_dark", pos=[-1.0, 1.50, 1.0], tags="floating")
  box "leg_br" (size=[0.15, 3.0, 0.15], mat="wood_dark", pos=[1.0, 1.50, 1.0], tags="floating")
  // Cross braces (diagonal stability)
  box "brace_x_fl_bl" (size=[0.10, 3.0, 0.10], mat="wood_dark", pos=[-1.0, 1.50, 0], rot=[0,45,0], tags="floating")
  box "brace_x_fr_br" (size=[0.10, 3.0, 0.10], mat="wood_dark", pos=[1.0, 1.50, 0], rot=[0,-45,0], tags="floating")
  box "brace_z_fl_fr" (size=[0.10, 3.0, 0.10], mat="wood_dark", pos=[0, 1.50, -1.0], rot=[45,0,0], tags="floating")
  box "brace_z_bl_br" (size=[0.10, 3.0, 0.10], mat="wood_dark", pos=[0, 1.50, 1.0], rot=[-45,0,0], tags="floating")
  // Platform floor
  slab "platform" (size=[2.5, 0.10, 2.5], mat="wood_brown", pos=[0, 3.05, 0])
  // Railings (3 sides, front open)
  box "rail_l" (size=[0.10, 0.80, 2.5], mat="wood_brown", pos=[-1.20, 3.55, 0], tags="floating")
  box "rail_r" (size=[0.10, 0.80, 2.5], mat="wood_brown", pos=[1.20, 3.55, 0], tags="floating")
  box "rail_b" (size=[2.5, 0.80, 0.10], mat="wood_brown", pos=[0, 3.55, 1.20], tags="floating")
  // Mid rails
  box "midrail_l" (size=[0.05, 0.05, 2.5], mat="wood_dark", pos=[-1.20, 3.25, 0], tags="floating")
  box "midrail_r" (size=[0.05, 0.05, 2.5], mat="wood_dark", pos=[1.20, 3.25, 0], tags="floating")
  box "midrail_b" (size=[2.5, 0.05, 0.05], mat="wood_dark", pos=[0, 3.25, 1.20], tags="floating")
  // Roof (small shed roof)
  prism "roof" (size=[2.7, 0.60, 2.7], pos=[0, 4.20, 0], mat="wood_dark")
  // Ladder (back side, going down to ground)
  box "ladder_l" (size=[0.05, 3.5, 0.05], mat="wood_dark", pos=[-0.30, 1.50, 1.50], rot=[10,0,0], tags="floating")
  box "ladder_r" (size=[0.05, 3.5, 0.05], mat="wood_dark", pos=[0.30, 1.50, 1.50], rot=[10,0,0], tags="floating")
  box "rung_1" (size=[0.60, 0.04, 0.04], mat="wood_dark", pos=[0, 0.70, 1.30], tags="floating")
  box "rung_2" (size=[0.60, 0.04, 0.04], mat="wood_dark", pos=[0, 1.40, 1.45], tags="floating")
  box "rung_3" (size=[0.60, 0.04, 0.04], mat="wood_dark", pos=[0, 2.10, 1.60], tags="floating")
  box "rung_4" (size=[0.60, 0.04, 0.04], mat="wood_dark", pos=[0, 2.80, 1.75], tags="floating")
}
''')

# ============================================================
# 15. lighthouse.mog — tall white tower with light
# ============================================================
w("buildings", "lighthouse", '''// lighthouse.mog — Coastal lighthouse (River/Coastal civic landmark)
meta (name="lighthouse", description="Coastal lighthouse with tapered white tower and rotating light", tags=["building","coastal","landmark","lighthouse","tier1"], mogen_version="0.1.12")
material "wall_white" (color=[0.92,0.92,0.90], roughness=0.80, uv_mode="tile", uv_scale=4.0)
material "wall_red" (color=[0.65,0.20,0.15], roughness=0.80, uv_mode="tile", uv_scale=4.0)
material "lantern_glass" (color=[0.95,0.85,0.45], transmission=0.40, roughness=0.05, emissive=[0.80,0.70,0.40], emissive_strength=1.0)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "rock_grey" (color=[0.50,0.48,0.45], roughness=0.90, uv_mode="tile", uv_scale=2.0)
scene {
  slab "rock_base" (size=[10.0, 0.50, 10.0], mat="rock_grey", pos=[0, 0.25, 0])
  slab "foundation" (size=[5.0, 0.30, 5.0], mat="concrete", pos=[0, 0.65, 0])
  // Tapered tower (stacked cylinders)
  cylinder "tier_1" (radius=1.80, height=4.0, mat="wall_white", pos=[0, 2.65, 0])
  cylinder "tier_2" (radius=1.70, height=4.0, mat="wall_red", pos=[0, 6.65, 0])
  cylinder "tier_3" (radius=1.60, height=4.0, mat="wall_white", pos=[0, 10.65, 0])
  cylinder "tier_4" (radius=1.50, height=3.0, mat="wall_red", pos=[0, 14.15, 0])
  cylinder "tier_5" (radius=1.40, height=2.0, mat="wall_white", pos=[0, 16.65, 0])
  // Gallery deck (wider than tower)
  cylinder "gallery_base" (radius=1.80, height=0.30, mat="concrete", pos=[0, 17.95, 0])
  // Lantern room
  cylinder "lantern_room" (radius=1.20, height=2.0, mat="lantern_glass", pos=[0, 19.20, 0])
  // Lantern roof
  cone "lantern_roof" (radius=1.40, height=1.0, mat="metal_dark", pos=[0, 20.80, 0])
  // Vent ball on top
  sphere "vent" (radius=0.20, mat="metal_dark", pos=[0, 21.50, 0], tags="floating")
  // Lightning rod
  cylinder "rod" (radius=0.02, height=1.0, mat="metal_dark", pos=[0, 22.10, 0], tags="floating")
  // Gallery railing
  torus "rail_gallery" (radius=1.80, tube_radius=0.05, mat="metal_dark", pos=[0, 18.30, 0], rot=[90,0,0], tags="floating")
  // Door at base
  box "door" (size=[0.80, 1.80, 0.10], mat="metal_dark", pos=[0, 1.55, 1.75], tags="floating")
  // Small windows
  box "win_1" (size=[0.40, 0.60, 0.10], mat="lantern_glass", pos=[0, 4.0, 1.79], tags="floating")
  box "win_2" (size=[0.40, 0.60, 0.10], mat="lantern_glass", pos=[0, 8.0, 1.69], tags="floating")
  box "win_3" (size=[0.40, 0.60, 0.10], mat="lantern_glass", pos=[0, 12.0, 1.59], tags="floating")
  // Adjacent keeper's house
  box "house" (size=[4.0, 2.5, 3.0], mat="wall_white", pos=[3.5, 1.75, 0], tags="floating")
  prism "house_roof" (size=[4.2, 0.80, 3.2], pos=[3.5, 3.40, 0], mat="wall_red", tags="floating")
  box "house_door" (size=[0.80, 1.80, 0.10], mat="metal_dark", pos=[3.5, 1.40, -1.50], tags="floating")
}
''')

# ============================================================
# 16. fishing_hut.mog — small hut on stilts
# ============================================================
w("buildings", "fishing_hut", '''// fishing_hut.mog — Fishing hut on wooden stilts over water
meta (name="fishing_hut", description="Small fishing hut on wooden stilts with dock ladder", tags=["building","coastal","fishing","tier1"], mogen_version="0.1.12")
material "wall_wood" (color=[0.55,0.40,0.25], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_dark" (color=[0.35,0.25,0.15], roughness=0.85)
material "roof_wood" (color=[0.30,0.20,0.12], roughness=0.80)
material "stilt_dark" (color=[0.25,0.18,0.10], roughness=0.85)
material "window_amber" (color=[0.65,0.55,0.30], transmission=0.30, roughness=0.10, emissive=[0.40,0.30,0.15], emissive_strength=0.5)
material "door_wood" (color=[0.25,0.15,0.08], roughness=0.65)
material "water_dark" (color=[0.10,0.25,0.30], roughness=0.20, transmission=0.30)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "water" (size=[10.0, 0.04, 10.0], mat="water_dark")
  // 4 stilts
  cylinder "stilt_fl" (radius=0.10, height=2.0, mat="stilt_dark", pos=[-1.5, 1.0, -1.5], tags="floating")
  cylinder "stilt_fr" (radius=0.10, height=2.0, mat="stilt_dark", pos=[1.5, 1.0, -1.5], tags="floating")
  cylinder "stilt_bl" (radius=0.10, height=2.0, mat="stilt_dark", pos=[-1.5, 1.0, 1.5], tags="floating")
  cylinder "stilt_br" (radius=0.10, height=2.0, mat="stilt_dark", pos=[1.5, 1.0, 1.5], tags="floating")
  // Floor platform
  slab "floor" (size=[4.0, 0.15, 4.0], mat="wall_wood", pos=[0, 2.10, 0])
  // Hut body
  box "body" (size=[3.5, 2.0, 3.5], mat="wall_wood", pos=[0, 3.20, 0])
  // Roof
  prism "roof" (size=[4.0, 0.80, 4.0], pos=[0, 4.40, 0], mat="roof_wood")
  // Door (front)
  box "door_frame" (size=[1.0, 1.8, 0.06], mat="wall_dark", pos=[0, 3.10, -1.75], tags="floating")
  box "door" (size=[0.85, 1.65, 0.05], mat="door_wood", pos=[0, 3.10, -1.80], tags="floating")
  // Side window
  box "win_l" (size=[0.06, 0.60, 0.60], mat="window_amber", pos=[-1.75, 3.30, 0], tags="floating")
  box "win_r" (size=[0.06, 0.60, 0.60], mat="window_amber", pos=[1.75, 3.30, 0], tags="floating")
  // Ladder down to water
  box "ladder_l" (size=[0.05, 2.0, 0.05], mat="metal_dark", pos=[-0.30, 1.10, -2.20], rot=[10,0,0], tags="floating")
  box "ladder_r" (size=[0.05, 2.0, 0.05], mat="metal_dark", pos=[0.30, 1.10, -2.20], rot=[10,0,0], tags="floating")
  box "rung_1" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 0.55, -2.05], tags="floating")
  box "rung_2" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 1.10, -2.15], tags="floating")
  box "rung_3" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 1.65, -2.25], tags="floating")
  // Small deck extension at front
  slab "deck" (size=[4.0, 0.10, 1.5], mat="wall_wood", pos=[0, 2.05, -2.50])
  // Fishing nets on rail
  box "rail_post_1" (size=[0.10, 0.80, 0.10], mat="stilt_dark", pos=[-1.8, 2.50, -2.50], tags="floating")
  box "rail_post_2" (size=[0.10, 0.80, 0.10], mat="stilt_dark", pos=[1.8, 2.50, -2.50], tags="floating")
  box "rail_top" (size=[4.0, 0.06, 0.06], mat="stilt_dark", pos=[0, 2.85, -2.50], tags="floating")
}
''')

# ============================================================
# 17. pier_dock.mog — wooden pier extending into water
# ============================================================
w("buildings", "pier_dock", '''// pier_dock.mog — Wooden pier extending into water
meta (name="pier_dock", description="Wooden pier extending into water with pilings and railings", tags=["building","coastal","pier","tier1"], mogen_version="0.1.12")
material "wood_wood" (color=[0.55,0.40,0.25], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wood_dark" (color=[0.35,0.25,0.15], roughness=0.85)
material "water_dark" (color=[0.10,0.25,0.30], roughness=0.20, transmission=0.30)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "water" (size=[20.0, 0.04, 12.0], mat="water_dark")
  // Pier deck (long rectangle)
  slab "deck" (size=[12.0, 0.20, 4.0], mat="wood_wood", pos=[3.0, 0.80, 0])
  // Deck planking lines
  box "plank_1" (size=[0.05, 0.04, 4.0], mat="wood_dark", pos=[0.5, 0.92, 0], tags="floating")
  box "plank_2" (size=[0.05, 0.04, 4.0], mat="wood_dark", pos=[2.0, 0.92, 0], tags="floating")
  box "plank_3" (size=[0.05, 0.04, 4.0], mat="wood_dark", pos=[4.0, 0.92, 0], tags="floating")
  box "plank_4" (size=[0.05, 0.04, 4.0], mat="wood_dark", pos=[6.0, 0.92, 0], tags="floating")
  box "plank_5" (size=[0.05, 0.04, 4.0], mat="wood_dark", pos=[8.0, 0.92, 0], tags="floating")
  box "plank_6" (size=[0.05, 0.04, 4.0], mat="wood_dark", pos=[10.0, 0.92, 0], tags="floating")
  // Pilings (down into water, every 3m on each side)
  cylinder "pile_1_l" (radius=0.10, height=2.0, mat="wood_dark", pos=[-2.0, -0.20, -1.8], tags="floating")
  cylinder "pile_1_r" (radius=0.10, height=2.0, mat="wood_dark", pos=[-2.0, -0.20, 1.8], tags="floating")
  cylinder "pile_2_l" (radius=0.10, height=2.0, mat="wood_dark", pos=[1.0, -0.20, -1.8], tags="floating")
  cylinder "pile_2_r" (radius=0.10, height=2.0, mat="wood_dark", pos=[1.0, -0.20, 1.8], tags="floating")
  cylinder "pile_3_l" (radius=0.10, height=2.0, mat="wood_dark", pos=[4.0, -0.20, -1.8], tags="floating")
  cylinder "pile_3_r" (radius=0.10, height=2.0, mat="wood_dark", pos=[4.0, -0.20, 1.8], tags="floating")
  cylinder "pile_4_l" (radius=0.10, height=2.0, mat="wood_dark", pos=[7.0, -0.20, -1.8], tags="floating")
  cylinder "pile_4_r" (radius=0.10, height=2.0, mat="wood_dark", pos=[7.0, -0.20, 1.8], tags="floating")
  cylinder "pile_5_l" (radius=0.10, height=2.0, mat="wood_dark", pos=[10.0, -0.20, -1.8], tags="floating")
  cylinder "pile_5_r" (radius=0.10, height=2.0, mat="wood_dark", pos=[10.0, -0.20, 1.8], tags="floating")
  // Cross-bracing between pilings
  box "xbrace_1" (size=[3.0, 0.06, 0.06], mat="wood_dark", pos=[-0.5, 0.10, -1.80], rot=[0,0,15], tags="floating")
  box "xbrace_2" (size=[3.0, 0.06, 0.06], mat="wood_dark", pos=[2.5, 0.10, -1.80], rot=[0,0,15], tags="floating")
  box "xbrace_3" (size=[3.0, 0.06, 0.06], mat="wood_dark", pos=[5.5, 0.10, -1.80], rot=[0,0,15], tags="floating")
  box "xbrace_4" (size=[3.0, 0.06, 0.06], mat="wood_dark", pos=[-0.5, 0.10, 1.80], rot=[0,0,15], tags="floating")
  box "xbrace_5" (size=[3.0, 0.06, 0.06], mat="wood_dark", pos=[2.5, 0.10, 1.80], rot=[0,0,15], tags="floating")
  box "xbrace_6" (size=[3.0, 0.06, 0.06], mat="wood_dark", pos=[5.5, 0.10, 1.80], rot=[0,0,15], tags="floating")
  // Railing (one side only)
  box "rail_post_1" (size=[0.10, 0.80, 0.10], mat="wood_dark", pos=[-2.0, 1.30, -1.95], tags="floating")
  box "rail_post_2" (size=[0.10, 0.80, 0.10], mat="wood_dark", pos=[1.0, 1.30, -1.95], tags="floating")
  box "rail_post_3" (size=[0.10, 0.80, 0.10], mat="wood_dark", pos=[4.0, 1.30, -1.95], tags="floating")
  box "rail_post_4" (size=[0.10, 0.80, 0.10], mat="wood_dark", pos=[7.0, 1.30, -1.95], tags="floating")
  box "rail_post_5" (size=[0.10, 0.80, 0.10], mat="wood_dark", pos=[10.0, 1.30, -1.95], tags="floating")
  box "rail_top" (size=[12.5, 0.06, 0.06], mat="wood_dark", pos=[3.0, 1.70, -1.95], tags="floating")
  box "rail_mid" (size=[12.5, 0.04, 0.04], mat="wood_dark", pos=[3.0, 1.30, -1.95], tags="floating")
  // Cleats for tying boats
  box "cleat_1" (size=[0.30, 0.15, 0.10], mat="metal_dark", pos=[0, 0.95, 0], tags="floating")
  box "cleat_2" (size=[0.30, 0.15, 0.10], mat="metal_dark", pos=[6, 0.95, 0], tags="floating")
  // End of pier — wider section
  slab "end_deck" (size=[2.0, 0.20, 4.0], mat="wood_wood", pos=[10.0, 0.80, 0])
}
''')

# ============================================================
# 18. houseboat.mog — small floating house
# ============================================================
w("buildings", "houseboat", '''// houseboat.mog — Small houseboat floating on water
meta (name="houseboat", description="Small houseboat with cabin and small deck", tags=["building","coastal","houseboat","tier1"], mogen_version="0.1.12")
material "hull_white" (color=[0.85,0.82,0.78], roughness=0.70, uv_mode="tile", uv_scale=3.0)
material "hull_trim" (color=[0.30,0.40,0.50], roughness=0.60, metallic=0.3)
material "cabin_wood" (color=[0.55,0.40,0.25], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_red" (color=[0.50,0.20,0.15], roughness=0.80, uv_mode="tile", uv_scale=4.0)
material "window_amber" (color=[0.65,0.55,0.30], transmission=0.30, roughness=0.10, emissive=[0.40,0.30,0.15], emissive_strength=0.5)
material "door_wood" (color=[0.25,0.15,0.08], roughness=0.65)
material "water_dark" (color=[0.10,0.25,0.30], roughness=0.20, transmission=0.30)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "water" (size=[16.0, 0.04, 8.0], mat="water_dark")
  // Hull (rectangular box hull — pontoon style)
  box "hull" (size=[8.0, 0.80, 3.5], mat="hull_white", pos=[0, 0.40, 0])
  // Hull trim (waterline)
  box "trim_band" (size=[8.05, 0.10, 3.55], mat="hull_trim", pos=[0, 0.50, 0])
  // Bow (slight wedge)
  box "bow" (size=[0.50, 0.80, 3.5], mat="hull_white", pos=[4.0, 0.40, 0], rot=[0,0,0])
  // Deck (top of hull)
  slab "deck" (size=[8.0, 0.10, 3.5], mat="cabin_wood", pos=[0, 0.85, 0])
  // Cabin
  box "cabin" (size=[5.0, 2.0, 3.0], mat="cabin_wood", pos=[-0.5, 1.90, 0])
  // Cabin roof (slight overhang)
  prism "cabin_roof" (size=[5.5, 0.60, 3.5], pos=[-0.5, 3.10, 0], mat="roof_red")
  // Door
  box "door" (size=[0.85, 1.65, 0.05], mat="door_wood", pos=[-0.5, 1.85, -1.50], tags="floating")
  // Windows (front, side, back)
  box "win_f_1" (size=[0.80, 0.60, 0.05], mat="window_amber", pos=[-1.50, 2.10, -1.50], tags="floating")
  box "win_f_2" (size=[0.80, 0.60, 0.05], mat="window_amber", pos=[0.50, 2.10, -1.50], tags="floating")
  box "win_l" (size=[0.05, 0.60, 0.80], mat="window_amber", pos=[-3.05, 2.10, 0], tags="floating")
  box "win_r" (size=[0.05, 0.60, 0.80], mat="window_amber", pos=[2.05, 2.10, 0], tags="floating")
  box "win_b" (size=[0.80, 0.60, 0.05], mat="window_amber", pos=[-0.5, 2.10, 1.50], tags="floating")
  // Chimney
  box "chimney" (size=[0.30, 1.0, 0.30], mat="roof_red", pos=[1.5, 3.50, 0], tags="floating")
  // Front deck railing
  box "rail_post_1" (size=[0.08, 0.70, 0.08], mat="metal_dark", pos=[3.0, 1.25, -1.60], tags="floating")
  box "rail_post_2" (size=[0.08, 0.70, 0.08], mat="metal_dark", pos=[3.0, 1.25, 1.60], tags="floating")
  box "rail_post_3" (size=[0.08, 0.70, 0.08], mat="metal_dark", pos=[3.9, 1.25, -1.60], tags="floating")
  box "rail_post_4" (size=[0.08, 0.70, 0.08], mat="metal_dark", pos=[3.9, 1.25, 1.60], tags="floating")
  box "rail_front" (size=[0.05, 0.70, 3.2], mat="metal_dark", pos=[3.95, 1.25, 0], tags="floating")
  // Mooring cleats
  box "cleat_1" (size=[0.20, 0.10, 0.10], mat="metal_dark", pos=[3.5, 0.95, -1.5], tags="floating")
  box "cleat_2" (size=[0.20, 0.10, 0.10], mat="metal_dark", pos=[3.5, 0.95, 1.5], tags="floating")
  // Antenna
  cylinder "antenna" (radius=0.02, height=1.5, mat="metal_dark", pos=[-2.0, 3.95, -1.0], tags="floating")
}
''')

# ============================================================
# 19. bridge_section.mog — 20m span with railings
# ============================================================
w("buildings", "bridge_section", '''// bridge_section.mog — 20m bridge span with railings (hero asset)
meta (name="bridge_section", description="20m bridge span with steel girders and concrete deck", tags=["building","coastal","bridge","landmark","tier1"], mogen_version="0.1.12")
material "concrete_deck" (color=[0.55,0.53,0.50], roughness=0.90, uv_mode="tile", uv_scale=6.0)
material "concrete_pier" (color=[0.50,0.48,0.45], roughness=0.90)
material "steel_grey" (color=[0.40,0.40,0.42], roughness=0.50, metallic=0.85)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "line_yellow" (color=[0.85,0.70,0.20], roughness=0.50, emissive=[0.40,0.30,0.10], emissive_strength=0.2)
material "rail_metal" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "water_dark" (color=[0.10,0.25,0.30], roughness=0.20, transmission=0.30)
scene {
  slab "water" (size=[30.0, 0.04, 14.0], mat="water_dark")
  // 2 piers (water foundation)
  box "pier_l" (size=[2.0, 4.0, 4.0], mat="concrete_pier", pos=[-7.0, -1.80, 0], tags="floating")
  box "pier_r" (size=[2.0, 4.0, 4.0], mat="concrete_pier", pos=[7.0, -1.80, 0], tags="floating")
  // Abutments (end supports)
  box "abut_l" (size=[2.0, 3.0, 12.0], mat="concrete_pier", pos=[-11.0, -1.30, 0], tags="floating")
  box "abut_r" (size=[2.0, 3.0, 12.0], mat="concrete_pier", pos=[11.0, -1.30, 0], tags="floating")
  // Deck (roadway)
  slab "deck" (size=[22.0, 0.40, 10.0], mat="concrete_deck", pos=[0, 0.50, 0])
  // Asphalt surface
  slab "asphalt" (size=[22.0, 0.05, 7.0], mat="asphalt", pos=[0, 0.725, 0])
  // Yellow center line
  slab "center_line" (size=[22.0, 0.06, 0.15], mat="line_yellow", pos=[0, 0.755, 0], tags="floating")
  // Steel girder (under deck, visible)
  box "girder_main" (size=[22.0, 1.0, 0.30], mat="steel_grey", pos=[0, 0.0, -3.5], tags="floating")
  box "girder_back" (size=[22.0, 1.0, 0.30], mat="steel_grey", pos=[0, 0.0, 3.5], tags="floating")
  // Cross beams
  box "xbeam_1" (size=[0.20, 0.60, 7.0], mat="steel_grey", pos=[-9.0, 0.20, 0], tags="floating")
  box "xbeam_2" (size=[0.20, 0.60, 7.0], mat="steel_grey", pos=[-5.0, 0.20, 0], tags="floating")
  box "xbeam_3" (size=[0.20, 0.60, 7.0], mat="steel_grey", pos=[0, 0.20, 0], tags="floating")
  box "xbeam_4" (size=[0.20, 0.60, 7.0], mat="steel_grey", pos=[5.0, 0.20, 0], tags="floating")
  box "xbeam_5" (size=[0.20, 0.60, 7.0], mat="steel_grey", pos=[9.0, 0.20, 0], tags="floating")
  // Railings (both sides)
  box "rail_top_l" (size=[22.0, 0.06, 0.06], mat="rail_metal", pos=[0, 1.30, -5.0], tags="floating")
  box "rail_mid_l" (size=[22.0, 0.04, 0.04], mat="rail_metal", pos=[0, 0.95, -5.0], tags="floating")
  box "rail_top_r" (size=[22.0, 0.06, 0.06], mat="rail_metal", pos=[0, 1.30, 5.0], tags="floating")
  box "rail_mid_r" (size=[22.0, 0.04, 0.04], mat="rail_metal", pos=[0, 0.95, 5.0], tags="floating")
  // Rail posts (every 2m)
  box "rpost_l_1" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-10.0, 0.95, -5.0], tags="floating")
  box "rpost_l_2" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-7.0, 0.95, -5.0], tags="floating")
  box "rpost_l_3" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-4.0, 0.95, -5.0], tags="floating")
  box "rpost_l_4" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-1.0, 0.95, -5.0], tags="floating")
  box "rpost_l_5" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[2.0, 0.95, -5.0], tags="floating")
  box "rpost_l_6" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[5.0, 0.95, -5.0], tags="floating")
  box "rpost_l_7" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[8.0, 0.95, -5.0], tags="floating")
  box "rpost_r_1" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-10.0, 0.95, 5.0], tags="floating")
  box "rpost_r_2" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-7.0, 0.95, 5.0], tags="floating")
  box "rpost_r_3" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-4.0, 0.95, 5.0], tags="floating")
  box "rpost_r_4" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[-1.0, 0.95, 5.0], tags="floating")
  box "rpost_r_5" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[2.0, 0.95, 5.0], tags="floating")
  box "rpost_r_6" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[5.0, 0.95, 5.0], tags="floating")
  box "rpost_r_7" (size=[0.08, 0.80, 0.08], mat="rail_metal", pos=[8.0, 0.95, 5.0], tags="floating")
  // Street light at each end
  box "light_l" (size=[0.15, 3.0, 0.15], mat="rail_metal", pos=[-10.5, 2.30, -5.0], tags="floating")
  box "light_r" (size=[0.15, 3.0, 0.15], mat="rail_metal", pos=[10.5, 2.30, 5.0], tags="floating")
}
''')

# ============================================================
# 20. military_checkpoint.mog — gate + barriers
# ============================================================
w("buildings", "military_checkpoint", '''// military_checkpoint.mog — Military checkpoint gate with barriers
meta (name="military_checkpoint", description="Military checkpoint with gate, jersey barriers, and guard posts", tags=["building","military","checkpoint","tier1"], mogen_version="0.1.12")
material "concrete_khaki" (color=[0.55,0.50,0.38], roughness=0.90, uv_mode="tile", uv_scale=3.0)
material "metal_olive" (color=[0.30,0.32,0.20], roughness=0.60, metallic=0.7)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "wood_dark" (color=[0.30,0.22,0.12], roughness=0.85)
material "stripe_red" (color=[0.65,0.15,0.10], roughness=0.70, emissive=[0.30,0.05,0.05], emissive_strength=0.3)
material "stripe_white" (color=[0.92,0.90,0.85], roughness=0.60)
material "warning_red" (color=[0.85,0.10,0.10], roughness=0.50, emissive=[0.6,0.05,0.05], emissive_strength=0.5)
material "window_glass" (color=[0.30,0.40,0.30], transmission=0.30, roughness=0.10)
scene {
  slab "road" (size=[20.0, 0.05, 12.0], mat="asphalt", pos=[0, 0.025, 0])
  // Gate arm (horizontal striped pole)
  cylinder "gate_pole_l" (radius=0.05, height=2.5, mat="metal_olive", pos=[-4.0, 1.50, 0], tags="floating")
  cylinder "gate_pole_r" (radius=0.05, height=2.5, mat="metal_olive", pos=[4.0, 1.50, 0], tags="floating")
  box "gate_arm" (size=[8.0, 0.15, 0.06], mat="stripe_red", pos=[0, 2.50, 0], tags="floating")
  // Stripes on arm (alternating red/white)
  box "stripe_1" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[-3.5, 2.50, 0], tags="floating")
  box "stripe_2" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[-2.5, 2.50, 0], tags="floating")
  box "stripe_3" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[-1.5, 2.50, 0], tags="floating")
  box "stripe_4" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[-0.5, 2.50, 0], tags="floating")
  box "stripe_5" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[0.5, 2.50, 0], tags="floating")
  box "stripe_6" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[1.5, 2.50, 0], tags="floating")
  box "stripe_7" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[2.5, 2.50, 0], tags="floating")
  box "stripe_8" (size=[0.40, 0.16, 0.07], mat="stripe_white", pos=[3.5, 2.50, 0], tags="floating")
  // Jersey barriers (3 across road, slight offset)
  box "jersey_1" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[-3.0, 0.50, 2.0])
  box "jersey_2" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[0, 0.50, -1.0])
  box "jersey_3" (size=[2.0, 1.0, 0.50], mat="concrete_khaki", pos=[3.0, 0.50, 2.0])
  // Guard booth (left)
  box "booth_l" (size=[2.0, 2.5, 2.0], mat="metal_olive", pos=[-5.5, 1.25, -3.0])
  slab "booth_l_roof" (size=[2.2, 0.10, 2.2], mat="metal_olive", pos=[-5.5, 2.55, -3.0])
  box "booth_l_win" (size=[0.06, 0.80, 1.20], mat="window_glass", pos=[-4.50, 1.40, -3.0], tags="floating")
  box "booth_l_win_f" (size=[1.20, 0.80, 0.06], mat="window_glass", pos=[-5.5, 1.40, -3.95], tags="floating")
  // Guard booth (right)
  box "booth_r" (size=[2.0, 2.5, 2.0], mat="metal_olive", pos=[5.5, 1.25, 3.0])
  slab "booth_r_roof" (size=[2.2, 0.10, 2.2], mat="metal_olive", pos=[5.5, 2.55, 3.0])
  box "booth_r_win" (size=[0.06, 0.80, 1.20], mat="window_glass", pos=[4.50, 1.40, 3.0], tags="floating")
  box "booth_r_win_f" (size=[1.20, 0.80, 0.06], mat="window_glass", pos=[5.5, 1.40, 3.95], tags="floating")
  // Warning sign
  box "sign_post" (size=[0.10, 2.5, 0.10], mat="metal_olive", pos=[-5.0, 1.25, 5.0], tags="floating")
  box "sign_board" (size=[1.5, 1.0, 0.10], mat="warning_red", pos=[-5.0, 2.50, 5.0], tags="floating")
  box "sign_text" (size=[1.2, 0.30, 0.02], mat="stripe_white", pos=[-5.0, 2.70, 5.06], tags="floating")
  // Sandbags around booth (defensive)
  box "sandbag_l_1" (size=[0.60, 0.30, 0.40], mat="concrete_khaki", pos=[-6.5, 0.15, -3.5], tags="floating")
  box "sandbag_l_2" (size=[0.60, 0.30, 0.40], mat="concrete_khaki", pos=[-6.0, 0.45, -3.8], tags="floating")
  box "sandbag_l_3" (size=[0.60, 0.30, 0.40], mat="concrete_khaki", pos=[-6.7, 0.45, -3.0], tags="floating")
  box "sandbag_r_1" (size=[0.60, 0.30, 0.40], mat="concrete_khaki", pos=[6.5, 0.15, 3.5], tags="floating")
  box "sandbag_r_2" (size=[0.60, 0.30, 0.40], mat="concrete_khaki", pos=[6.0, 0.45, 3.8], tags="floating")
  box "sandbag_r_3" (size=[0.60, 0.30, 0.40], mat="concrete_khaki", pos=[6.7, 0.45, 3.0], tags="floating")
}
''')

# ============================================================
# 21. watchtower.mog — tall wooden military watchtower
# ============================================================
w("buildings", "watchtower", '''// watchtower.mog — Tall wooden military observation tower
meta (name="watchtower", description="Tall wooden military observation tower with ladder and railing", tags=["building","military","watchtower","tier1"], mogen_version="0.1.12")
material "wood_olive" (color=[0.40,0.42,0.28], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wood_dark" (color=[0.25,0.20,0.12], roughness=0.85)
material "metal_olive" (color=[0.30,0.32,0.20], roughness=0.60, metallic=0.7)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "glass_dark" (color=[0.20,0.30,0.25], transmission=0.30, roughness=0.10)
scene {
  slab "ground" (size=[6.0, 0.04, 6.0], mat="grass")
  // 4 main legs (5m tall)
  box "leg_fl" (size=[0.20, 5.0, 0.20], mat="wood_olive", pos=[-1.2, 2.50, -1.2], tags="floating")
  box "leg_fr" (size=[0.20, 5.0, 0.20], mat="wood_olive", pos=[1.2, 2.50, -1.2], tags="floating")
  box "leg_bl" (size=[0.20, 5.0, 0.20], mat="wood_olive", pos=[-1.2, 2.50, 1.2], tags="floating")
  box "leg_br" (size=[0.20, 5.0, 0.20], mat="wood_olive", pos=[1.2, 2.50, 1.2], tags="floating")
  // Diagonal cross braces (lower section)
  box "xb_low_1" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[-1.2, 1.30, 0], rot=[0,0,65], tags="floating")
  box "xb_low_2" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[1.2, 1.30, 0], rot=[0,0,-65], tags="floating")
  box "xb_low_3" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[0, 1.30, -1.2], rot=[65,0,0], tags="floating")
  box "xb_low_4" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[0, 1.30, 1.2], rot=[-65,0,0], tags="floating")
  // Diagonal cross braces (upper section)
  box "xb_high_1" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[-1.2, 3.80, 0], rot=[0,0,65], tags="floating")
  box "xb_high_2" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[1.2, 3.80, 0], rot=[0,0,-65], tags="floating")
  box "xb_high_3" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[0, 3.80, -1.2], rot=[65,0,0], tags="floating")
  box "xb_high_4" (size=[0.10, 2.5, 0.10], mat="wood_dark", pos=[0, 3.80, 1.2], rot=[-65,0,0], tags="floating")
  // Platform floor
  slab "platform" (size=[3.0, 0.10, 3.0], mat="wood_olive", pos=[0, 5.05, 0])
  // Observation cabin
  box "cabin" (size=[2.5, 1.8, 2.5], mat="wood_olive", pos=[0, 5.95, 0])
  // Cabin windows (4 sides)
  box "win_n" (size=[0.80, 0.50, 0.06], mat="glass_dark", pos=[0, 6.10, -1.25], tags="floating")
  box "win_s" (size=[0.80, 0.50, 0.06], mat="glass_dark", pos=[0, 6.10, 1.25], tags="floating")
  box "win_e" (size=[0.06, 0.50, 0.80], mat="glass_dark", pos=[1.25, 6.10, 0], tags="floating")
  box "win_w" (size=[0.06, 0.50, 0.80], mat="glass_dark", pos=[-1.25, 6.10, 0], tags="floating")
  // Roof
  prism "roof" (size=[2.8, 0.80, 2.8], pos=[0, 7.10, 0], mat="wood_dark")
  // Railings around platform
  box "rail_n" (size=[3.0, 0.80, 0.08], mat="wood_dark", pos=[0, 5.55, -1.50], tags="floating")
  box "rail_s" (size=[3.0, 0.80, 0.08], mat="wood_dark", pos=[0, 5.55, 1.50], tags="floating")
  box "rail_e" (size=[0.08, 0.80, 3.0], mat="wood_dark", pos=[1.50, 5.55, 0], tags="floating")
  box "rail_w" (size=[0.08, 0.80, 3.0], mat="wood_dark", pos=[-1.50, 5.55, 0], tags="floating")
  // Ladder
  box "ladder_l" (size=[0.06, 5.0, 0.06], mat="metal_olive", pos=[-0.30, 2.50, 1.30], rot=[10,0,0], tags="floating")
  box "ladder_r" (size=[0.06, 5.0, 0.06], mat="metal_olive", pos=[0.30, 2.50, 1.30], rot=[10,0,0], tags="floating")
  box "rung_1" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 1.0, 1.20], tags="floating")
  box "rung_2" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 1.6, 1.30], tags="floating")
  box "rung_3" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 2.2, 1.40], tags="floating")
  box "rung_4" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 2.8, 1.50], tags="floating")
  box "rung_5" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 3.4, 1.60], tags="floating")
  box "rung_6" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 4.0, 1.70], tags="floating")
  box "rung_7" (size=[0.60, 0.04, 0.04], mat="metal_olive", pos=[0, 4.6, 1.80], tags="floating")
  // Searchlight
  box "searchlight" (size=[0.40, 0.30, 0.40], mat="metal_olive", pos=[0, 6.85, -1.30], tags="floating")
}
''')

# ============================================================
# 22. bunker_entrance.mog — hillside steel door
# ============================================================
w("buildings", "bunker_entrance", '''// bunker_entrance.mog — Hillside bunker entrance with steel door
meta (name="bunker_entrance", description="Hillside bunker entrance with reinforced steel door", tags=["building","military","bunker","tier1"], mogen_version="0.1.12")
material "concrete_grey" (color=[0.50,0.48,0.45], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "concrete_dark" (color=[0.35,0.33,0.30], roughness=0.90)
material "steel_door" (color=[0.30,0.32,0.25], roughness=0.50, metallic=0.85)
material "hill_green" (color=[0.22,0.35,0.16], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "rock_grey" (color=[0.45,0.43,0.40], roughness=0.90, uv_mode="tile", uv_scale=2.0)
material "warning_yellow" (color=[0.85,0.70,0.10], roughness=0.60, emissive=[0.40,0.30,0.05], emissive_strength=0.3)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
scene {
  // Hill shape — sloped back from entrance
  box "hill_base" (size=[12.0, 4.0, 6.0], mat="hill_green", pos=[0, 2.00, 2.0])
  box "hill_top" (size=[10.0, 2.0, 4.0], mat="hill_green", pos=[0, 4.50, 2.0])
  // Rock facing around entrance
  box "rock_face" (size=[6.0, 4.0, 0.30], mat="rock_grey", pos=[0, 2.00, -1.0])
  // Concrete frame around door
  box "frame" (size=[4.5, 4.0, 0.50], mat="concrete_grey", pos=[0, 2.00, -0.85])
  // Steel door (heavy)
  box "door_l" (size=[1.50, 3.20, 0.20], mat="steel_door", pos=[-0.80, 1.60, -1.05])
  box "door_r" (size=[1.50, 3.20, 0.20], mat="steel_door", pos=[0.80, 1.60, -1.05])
  // Door hinges
  cylinder "hinge_l_t" (radius=0.08, height=0.30, mat="metal_dark", pos=[-1.55, 3.0, -1.05], rot=[0,90,0], tags="floating")
  cylinder "hinge_l_b" (radius=0.08, height=0.30, mat="metal_dark", pos=[-1.55, 0.5, -1.05], rot=[0,90,0], tags="floating")
  cylinder "hinge_r_t" (radius=0.08, height=0.30, mat="metal_dark", pos=[1.55, 3.0, -1.05], rot=[0,90,0], tags="floating")
  cylinder "hinge_r_b" (radius=0.08, height=0.30, mat="metal_dark", pos=[1.55, 0.5, -1.05], rot=[0,90,0], tags="floating")
  // Center seam (between doors)
  box "seam" (size=[0.05, 3.20, 0.22], mat="metal_dark", pos=[0, 1.60, -1.07], tags="floating")
  // Door handles (wheel-style, for vault)
  cylinder "handle_l" (radius=0.20, height=0.10, mat="metal_dark", pos=[-0.20, 1.60, -1.20], rot=[90,0,0], tags="floating")
  cylinder "handle_r" (radius=0.20, height=0.10, mat="metal_dark", pos=[0.20, 1.60, -1.20], rot=[90,0,0], tags="floating")
  // Spokes on handles
  box "spoke_l_1" (size=[0.05, 0.40, 0.05], mat="metal_dark", pos=[-0.20, 1.60, -1.20], rot=[0,0,0], tags="floating")
  box "spoke_l_2" (size=[0.05, 0.40, 0.05], mat="metal_dark", pos=[-0.20, 1.60, -1.20], rot=[0,0,90], tags="floating")
  // Warning sign above door
  box "sign_board" (size=[1.5, 0.8, 0.10], mat="warning_yellow", pos=[0, 3.80, -0.80], tags="floating")
  // Vent pipe
  cylinder "vent" (radius=0.20, height=6.0, mat="metal_dark", pos=[2.0, 5.00, 0], rot=[0,0,0], tags="floating")
  // Concrete step at door
  slab "step" (size=[4.5, 0.20, 1.0], mat="concrete_dark", pos=[0, 0.10, -1.50])
  // Sandbags in front
  box "sandbag_1" (size=[0.50, 0.30, 0.40], mat="concrete_grey", pos=[-2.5, 0.15, -1.5], tags="floating")
  box "sandbag_2" (size=[0.50, 0.30, 0.40], mat="concrete_grey", pos=[2.5, 0.15, -1.5], tags="floating")
  box "sandbag_3" (size=[0.50, 0.30, 0.40], mat="concrete_grey", pos=[-2.5, 0.45, -1.7], tags="floating")
  box "sandbag_4" (size=[0.50, 0.30, 0.40], mat="concrete_grey", pos=[2.5, 0.45, -1.7], tags="floating")
}
''')

# ============================================================
# 23. helipad.mog — flat circle with H marking
# ============================================================
w("buildings", "helipad", '''// helipad.mog — Flat circular helipad with H marking and perimeter lights
meta (name="helipad", description="Circular concrete helipad with H marking and perimeter lights", tags=["building","military","helipad","tier1"], mogen_version="0.1.12")
material "concrete_pad" (color=[0.50,0.48,0.45], roughness=0.90, uv_mode="tile", uv_scale=6.0)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "h_white" (color=[0.92,0.92,0.90], roughness=0.60, emissive=[0.40,0.40,0.38], emissive_strength=0.3)
material "perim_yellow" (color=[0.85,0.70,0.10], roughness=0.60, emissive=[0.40,0.30,0.05], emissive_strength=0.4)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "ground" (size=[20.0, 0.04, 20.0], mat="grass")
  // Square asphalt approach
  slab "approach" (size=[14.0, 0.05, 14.0], mat="asphalt", pos=[0, 0.025, 0])
  // Circular concrete pad (approximate as cylinder, very flat)
  cylinder "pad" (radius=5.0, height=0.20, mat="concrete_pad", pos=[0, 0.10, 0])
  // H marking (center) — two vertical bars + horizontal crossbar
  box "h_left" (size=[0.40, 0.06, 3.0], mat="h_white", pos=[-0.80, 0.205, 0], tags="floating")
  box "h_right" (size=[0.40, 0.06, 3.0], mat="h_white", pos=[0.80, 0.205, 0], tags="floating")
  box "h_cross" (size=[2.0, 0.06, 0.40], mat="h_white", pos=[0, 0.205, 0], tags="floating")
  // Perimeter lights (8 around edge)
  sphere "light_1" (radius=0.15, mat="perim_yellow", pos=[5.0, 0.30, 0], tags="floating")
  sphere "light_2" (radius=0.15, mat="perim_yellow", pos=[-5.0, 0.30, 0], tags="floating")
  sphere "light_3" (radius=0.15, mat="perim_yellow", pos=[0, 0.30, 5.0], tags="floating")
  sphere "light_4" (radius=0.15, mat="perim_yellow", pos=[0, 0.30, -5.0], tags="floating")
  sphere "light_5" (radius=0.15, mat="perim_yellow", pos=[3.54, 0.30, 3.54], tags="floating")
  sphere "light_6" (radius=0.15, mat="perim_yellow", pos=[-3.54, 0.30, 3.54], tags="floating")
  sphere "light_7" (radius=0.15, mat="perim_yellow", pos=[3.54, 0.30, -3.54], tags="floating")
  sphere "light_8" (radius=0.15, mat="perim_yellow", pos=[-3.54, 0.30, -3.54], tags="floating")
  // Wind sock pole (one corner)
  cylinder "windsock_pole" (radius=0.05, height=3.0, mat="metal_dark", pos=[7.0, 1.50, 7.0], tags="floating")
  box "windsock" (size=[0.80, 0.20, 0.10], mat="h_white", pos=[7.50, 2.90, 7.0], tags="floating")
  // Light stand (small floodlight)
  box "flood_base" (size=[0.40, 0.50, 0.40], mat="metal_dark", pos=[6.0, 0.25, 0], tags="floating")
  box "flood_head" (size=[0.30, 0.30, 0.20], mat="perim_yellow", pos=[6.0, 0.55, 0.10], tags="floating")
  // Taxiway markings (yellow lines from edge)
  slab "taxi_line" (size=[3.0, 0.04, 0.15], mat="perim_yellow", pos=[5.50, 0.055, 0], tags="floating")
}
''')

# ============================================================
# 24. field_hospital_tent.mog — white medical tent
# ============================================================
w("buildings", "field_hospital_tent", '''// field_hospital_tent.mog — White military field hospital tent
meta (name="field_hospital_tent", description="White military field hospital tent with red cross", tags=["building","military","medical","tent","tier1"], mogen_version="0.1.12")
material "tent_white" (color=[0.92,0.90,0.85], roughness=0.85, transmission=0.05, uv_mode="tile", uv_scale=4.0)
material "cross_red" (color=[0.85,0.10,0.10], roughness=0.50, emissive=[0.50,0.05,0.05], emissive_strength=0.4)
material "pole_metal" (color=[0.40,0.40,0.42], roughness=0.40, metallic=0.85)
material "grass" (color=[0.22,0.38,0.16], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "rope_tan" (color=[0.60,0.50,0.30], roughness=0.80)
material "ground_dark" (color=[0.30,0.25,0.20], roughness=0.85)
scene {
  slab "ground" (size=[12.0, 0.04, 8.0], mat="grass")
  // Tent body — large half-cylinder lying on its side
  cylinder "tent_body" (radius=2.0, height=6.0, mat="tent_white", pos=[0, 2.0, 0], rot=[0,90,90])
  // End caps (slightly conical)
  cone "end_cap_l" (radius=2.0, height=1.0, mat="tent_white", pos=[-3.5, 2.0, 0], rot=[0,90,0], tags="floating")
  cone "end_cap_r" (radius=2.0, height=1.0, mat="tent_white", pos=[3.5, 2.0, 0], rot=[0,-90,0], tags="floating")
  // Door flap (open, front)
  box "door_flap_l" (size=[0.05, 1.80, 1.20], mat="tent_white", pos=[-1.00, 0.90, 2.00], rot=[0,0,-25], tags="floating")
  box "door_flap_r" (size=[0.05, 1.80, 1.20], mat="tent_white", pos=[1.00, 0.90, 2.00], rot=[0,0,25], tags="floating")
  // Red cross on side
  box "cross_v" (size=[0.10, 1.50, 0.05], mat="cross_red", pos=[0, 2.50, -2.05], tags="floating")
  box "cross_h" (size=[1.50, 0.10, 0.05], mat="cross_red", pos=[0, 2.50, -2.05], tags="floating")
  // Cross on opposite side
  box "cross_v_2" (size=[0.10, 1.50, 0.05], mat="cross_red", pos=[0, 2.50, 2.05], tags="floating")
  box "cross_h_2" (size=[1.50, 0.10, 0.05], mat="cross_red", pos=[0, 2.50, 2.05], tags="floating")
  // Tent poles (internal support visible at ends)
  cylinder "pole_l" (radius=0.10, height=4.0, mat="pole_metal", pos=[-3.0, 2.00, 0], tags="floating")
  cylinder "pole_r" (radius=0.10, height=4.0, mat="pole_metal", pos=[3.0, 2.00, 0], tags="floating")
  // Guy ropes (4 corners)
  cylinder "rope_fl" (radius=0.02, height=2.83, mat="rope_tan", pos=[-3.5, 1.40, -2.5], rot=[45,0,45], tags="floating")
  cylinder "rope_fr" (radius=0.02, height=2.83, mat="rope_tan", pos=[3.5, 1.40, -2.5], rot=[-45,0,45], tags="floating")
  cylinder "rope_bl" (radius=0.02, height=2.83, mat="rope_tan", pos=[-3.5, 1.40, 2.5], rot=[45,0,-45], tags="floating")
  cylinder "rope_br" (radius=0.02, height=2.83, mat="rope_tan", pos=[3.5, 1.40, 2.5], rot=[-45,0,-45], tags="floating")
  // Tent stakes (small at rope ends)
  box "stake_fl" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[-4.50, 0.15, -3.50], tags="floating")
  box "stake_fr" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[4.50, 0.15, -3.50], tags="floating")
  box "stake_bl" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[-4.50, 0.15, 3.50], tags="floating")
  box "stake_br" (size=[0.05, 0.30, 0.05], mat="pole_metal", pos=[4.50, 0.15, 3.50], tags="floating")
  // Small ground cloth at entrance
  slab "ground_cloth" (size=[3.0, 0.02, 1.5], mat="ground_dark", pos=[0, 0.03, 2.5])
  // Vent at top
  box "vent" (size=[0.40, 0.20, 0.20], mat="pole_metal", pos=[0, 3.95, 0], tags="floating")
}
''')

print("=== Part 2: 14 buildings written ===")
