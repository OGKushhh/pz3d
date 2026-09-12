#!/usr/bin/env python3
"""Batch 012 — Part E — final 16 assets: 3 coastal + 3 subway + 2 military + 3 commercial + 3 suburban + 2 misc."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# ============================================================
# COASTAL FILLS (3)
# ============================================================

w("environment", "boardwalk_section", '''// boardwalk_section.mog — 10m wooden boardwalk section with railings
meta (name="boardwalk_section", description="10m elevated wooden boardwalk section with railings and lampposts", tags=["environment","coastal","boardwalk","pier","tier1"], mogen_version="0.1.12")
material "wood_plank" (color=[0.60,0.45,0.28], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wood_dark" (color=[0.35,0.25,0.15], roughness=0.85)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "sand_tan" (color=[0.80,0.70,0.50], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "lamp_yellow" (color=[0.95,0.85,0.45], roughness=0.20, emissive=[0.80,0.65,0.30], emissive_strength=0.6)
scene {
  // Sand underneath
  slab "sand" (size=[12.0, 0.04, 6.0], mat="sand_tan", pos=[0, 0.02, 0], tags="floating")
  // Boardwalk deck (elevated)
  slab "deck" (size=[10.0, 0.20, 4.0], mat="wood_plank", pos=[0, 0.50, 0])
  // Plank lines (visible deck boards)
  slab "plank_1" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[-4.0, 0.61, 0], tags="floating")
  slab "plank_2" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[-2.0, 0.61, 0], tags="floating")
  slab "plank_3" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[0, 0.61, 0], tags="floating")
  slab "plank_4" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[2.0, 0.61, 0], tags="floating")
  slab "plank_5" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[4.0, 0.61, 0], tags="floating")
  // Support beams underneath
  box "beam_1" (size=[4.0, 0.20, 0.20], mat="wood_dark", pos=[0, 0.30, -3.0], rot=[0,90,0], tags="floating")
  box "beam_2" (size=[4.0, 0.20, 0.20], mat="wood_dark", pos=[0, 0.30, 3.0], rot=[0,90,0], tags="floating")
  // Pilings (down into sand, every 2.5m on each side)
  cylinder "pile_1_l" (radius=0.10, height=1.0, mat="wood_dark", pos=[-4.0, 0.20, -1.8], tags="floating")
  cylinder "pile_1_r" (radius=0.10, height=1.0, mat="wood_dark", pos=[-4.0, 0.20, 1.8], tags="floating")
  cylinder "pile_2_l" (radius=0.10, height=1.0, mat="wood_dark", pos=[-1.5, 0.20, -1.8], tags="floating")
  cylinder "pile_2_r" (radius=0.10, height=1.0, mat="wood_dark", pos=[-1.5, 0.20, 1.8], tags="floating")
  cylinder "pile_3_l" (radius=0.10, height=1.0, mat="wood_dark", pos=[1.5, 0.20, -1.8], tags="floating")
  cylinder "pile_3_r" (radius=0.10, height=1.0, mat="wood_dark", pos=[1.5, 0.20, 1.8], tags="floating")
  cylinder "pile_4_l" (radius=0.10, height=1.0, mat="wood_dark", pos=[4.0, 0.20, -1.8], tags="floating")
  cylinder "pile_4_r" (radius=0.10, height=1.0, mat="wood_dark", pos=[4.0, 0.20, 1.8], tags="floating")
  // Railings (both sides)
  box "rail_top_l" (size=[10.0, 0.08, 0.08], mat="wood_dark", pos=[0, 1.10, -2.00], tags="floating")
  box "rail_mid_l" (size=[10.0, 0.06, 0.06], mat="wood_dark", pos=[0, 0.85, -2.00], tags="floating")
  box "rail_top_r" (size=[10.0, 0.08, 0.08], mat="wood_dark", pos=[0, 1.10, 2.00], tags="floating")
  box "rail_mid_r" (size=[10.0, 0.06, 0.06], mat="wood_dark", pos=[0, 0.85, 2.00], tags="floating")
  // Rail posts (every 2.5m)
  box "rpost_l_1" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[-4.0, 0.85, -2.00], tags="floating")
  box "rpost_l_2" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[-1.5, 0.85, -2.00], tags="floating")
  box "rpost_l_3" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[1.5, 0.85, -2.00], tags="floating")
  box "rpost_l_4" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[4.0, 0.85, -2.00], tags="floating")
  box "rpost_r_1" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[-4.0, 0.85, 2.00], tags="floating")
  box "rpost_r_2" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[-1.5, 0.85, 2.00], tags="floating")
  box "rpost_r_3" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[1.5, 0.85, 2.00], tags="floating")
  box "rpost_r_4" (size=[0.10, 0.70, 0.10], mat="wood_dark", pos=[4.0, 0.85, 2.00], tags="floating")
  // 2 lampposts
  box "lamp_post_1" (size=[0.10, 2.50, 0.10], mat="metal_dark", pos=[-3.0, 1.75, -1.80], tags="floating")
  sphere "lamp_1_head" (radius=0.10, mat="lamp_yellow", pos=[-3.0, 3.10, -1.80], tags="floating")
  box "lamp_post_2" (size=[0.10, 2.50, 0.10], mat="metal_dark", pos=[3.0, 1.75, 1.80], tags="floating")
  sphere "lamp_2_head" (radius=0.10, mat="lamp_yellow", pos=[3.0, 3.10, 1.80], tags="floating")
  // Bench on boardwalk
  box "bench_seat" (size=[1.50, 0.10, 0.40], mat="wood_plank", pos=[0, 0.80, 1.50], tags="floating")
  box "bench_back" (size=[1.50, 0.50, 0.10], mat="wood_plank", pos=[0, 1.10, 1.70], tags="floating")
  box "bench_leg_l" (size=[0.10, 0.50, 0.30], mat="wood_dark", pos=[-0.65, 0.55, 1.50], tags="floating")
  box "bench_leg_r" (size=[0.10, 0.50, 0.30], mat="wood_dark", pos=[0.65, 0.55, 1.50], tags="floating")
}
''')

w("foliage", "marsh_grass", '''// marsh_grass.mog — tall marsh reeds / grass cluster
meta (name="marsh_grass", description="Tall marsh grass cluster — dense reeds for wetland biomes", tags=["foliage","coastal","marsh","grass","wetland","tier1"], mogen_version="0.1.12")
material "reed_green" (color=[0.30,0.45,0.18], roughness=0.85, transmission=0.20)
material "reed_dark" (color=[0.20,0.35,0.12], roughness=0.85, transmission=0.20)
material "reed_tan" (color=[0.55,0.50,0.25], roughness=0.85, transmission=0.20)
material "mud_dark" (color=[0.25,0.22,0.15], roughness=0.95, uv_mode="tile", uv_scale=2.0)
material "water_dark" (color=[0.15,0.25,0.30], roughness=0.20, transmission=0.40)
scene {
  // Mud patch (small)
  slab "mud" (size=[3.0, 0.04, 3.0], mat="mud_dark", pos=[0, 0.02, 0], tags="floating")
  // Shallow water (small puddle around mud)
  slab "water" (size=[3.5, 0.04, 3.5], mat="water_dark", pos=[0, 0.015, 0], tags="floating")
  // Many thin reeds — 18 stems in a cluster
  // Cluster 1 (center)
  cylinder "r_1" (radius=0.025, height=1.80, mat="reed_green", pos=[0, 0.90, 0], rot=[5,0,5], tags="floating")
  cylinder "r_2" (radius=0.025, height=1.60, mat="reed_dark", pos=[0.15, 0.80, 0.10], rot=[-5,0,8], tags="floating")
  cylinder "r_3" (radius=0.025, height=1.70, mat="reed_green", pos=[-0.10, 0.85, 0.15], rot=[3,0,-5], tags="floating")
  cylinder "r_4" (radius=0.025, height=1.50, mat="reed_tan", pos=[0.20, 0.75, -0.10], rot=[-3,0,5], tags="floating")
  cylinder "r_5" (radius=0.025, height=1.65, mat="reed_green", pos=[-0.15, 0.82, -0.15], rot=[4,0,-3], tags="floating")
  // Cluster 2 (left)
  cylinder "r_6" (radius=0.025, height=1.70, mat="reed_dark", pos=[-0.80, 0.85, 0.30], rot=[3,0,4], tags="floating")
  cylinder "r_7" (radius=0.025, height=1.55, mat="reed_green", pos=[-0.70, 0.78, 0.45], rot=[-4,0,6], tags="floating")
  cylinder "r_8" (radius=0.025, height=1.45, mat="reed_tan", pos=[-0.90, 0.73, 0.20], rot=[5,0,-4], tags="floating")
  cylinder "r_9" (radius=0.025, height=1.60, mat="reed_green", pos=[-0.65, 0.80, 0.15], rot=[-3,0,5], tags="floating")
  // Cluster 3 (right)
  cylinder "r_10" (radius=0.025, height=1.75, mat="reed_dark", pos=[0.80, 0.88, -0.30], rot=[3,0,-5], tags="floating")
  cylinder "r_11" (radius=0.025, height=1.50, mat="reed_green", pos=[0.70, 0.75, -0.45], rot=[-4,0,4], tags="floating")
  cylinder "r_12" (radius=0.025, height=1.65, mat="reed_tan", pos=[0.90, 0.83, -0.20], rot=[5,0,3], tags="floating")
  cylinder "r_13" (radius=0.025, height=1.55, mat="reed_green", pos=[0.85, 0.78, 0.10], rot=[-3,0,-4], tags="floating")
  // Cluster 4 (back)
  cylinder "r_14" (radius=0.025, height=1.70, mat="reed_dark", pos=[0.10, 0.85, 0.80], rot=[3,0,7], tags="floating")
  cylinder "r_15" (radius=0.025, height=1.50, mat="reed_green", pos=[-0.10, 0.75, 0.70], rot=[-3,0,5], tags="floating")
  cylinder "r_16" (radius=0.025, height=1.55, mat="reed_tan", pos=[0.20, 0.78, 0.90], rot=[4,0,-3], tags="floating")
  // Cluster 5 (front)
  cylinder "r_17" (radius=0.025, height=1.60, mat="reed_green", pos=[-0.20, 0.80, -0.80], rot=[-4,0,4], tags="floating")
  cylinder "r_18" (radius=0.025, height=1.45, mat="reed_dark", pos=[0.10, 0.73, -0.70], rot=[5,0,-4], tags="floating")
  // Cattail accents (3, on the edges)
  cylinder "cattail_1" (radius=0.04, height=1.80, mat="reed_dark", pos=[-1.10, 0.90, -0.50], tags="floating")
  cylinder "cat_head_1" (radius=0.05, height=0.30, mat="reed_tan", pos=[-1.10, 1.95, -0.50], tags="floating")
  cylinder "cattail_2" (radius=0.04, height=1.70, mat="reed_dark", pos=[1.00, 0.85, 0.60], tags="floating")
  cylinder "cat_head_2" (radius=0.05, height=0.25, mat="reed_tan", pos=[1.00, 1.80, 0.60], tags="floating")
}
''')

w("buildings", "marsh_pier", '''// marsh_pier.mog — small wooden marsh pier / fishing platform
meta (name="marsh_pier", description="Small wooden marsh pier — 4x4m platform with railings and a small bench", tags=["building","coastal","marsh","pier","tier1"], mogen_version="0.1.12")
material "wood_plank" (color=[0.55,0.42,0.25], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wood_dark" (color=[0.30,0.22,0.12], roughness=0.85)
material "water_dark" (color=[0.12,0.25,0.30], roughness=0.20, transmission=0.30)
material "reed_green" (color=[0.30,0.45,0.18], roughness=0.85, transmission=0.20)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
scene {
  slab "water" (size=[8.0, 0.04, 8.0], mat="water_dark", tags="floating")
  // 4x4 platform deck
  slab "deck" (size=[4.0, 0.15, 4.0], mat="wood_plank", pos=[0, 0.50, 0])
  // Plank lines
  slab "plank_1" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[-1.5, 0.585, 0], tags="floating")
  slab "plank_2" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[-0.5, 0.585, 0], tags="floating")
  slab "plank_3" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[0.5, 0.585, 0], tags="floating")
  slab "plank_4" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[1.5, 0.585, 0], tags="floating")
  // 4 corner pilings
  cylinder "pile_fl" (radius=0.12, height=1.5, mat="wood_dark", pos=[-1.85, 0.20, -1.85], tags="floating")
  cylinder "pile_fr" (radius=0.12, height=1.5, mat="wood_dark", pos=[1.85, 0.20, -1.85], tags="floating")
  cylinder "pile_bl" (radius=0.12, height=1.5, mat="wood_dark", pos=[-1.85, 0.20, 1.85], tags="floating")
  cylinder "pile_br" (radius=0.12, height=1.5, mat="wood_dark", pos=[1.85, 0.20, 1.85], tags="floating")
  // Railings (3 sides — front open)
  box "rail_l" (size=[0.08, 0.80, 4.0], mat="wood_dark", pos=[-2.0, 0.95, 0], tags="floating")
  box "rail_r" (size=[0.08, 0.80, 4.0], mat="wood_dark", pos=[2.0, 0.95, 0], tags="floating")
  box "rail_b" (size=[4.0, 0.80, 0.08], mat="wood_dark", pos=[0, 0.95, 2.0], tags="floating")
  // Mid-rails (lower)
  box "midrail_l" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[-2.0, 0.70, 0], tags="floating")
  box "midrail_r" (size=[0.04, 0.04, 4.0], mat="wood_dark", pos=[2.0, 0.70, 0], tags="floating")
  box "midrail_b" (size=[4.0, 0.04, 0.04], mat="wood_dark", pos=[0, 0.70, 2.0], tags="floating")
  // Bench (back of platform)
  box "bench_seat" (size=[2.0, 0.10, 0.40], mat="wood_plank", pos=[0, 0.80, 1.50], tags="floating")
  box "bench_back" (size=[2.0, 0.45, 0.08], mat="wood_plank", pos=[0, 1.10, 1.70], tags="floating")
  box "bench_leg_l" (size=[0.08, 0.45, 0.30], mat="wood_dark", pos=[-0.85, 0.55, 1.50], tags="floating")
  box "bench_leg_r" (size=[0.08, 0.45, 0.30], mat="wood_dark", pos=[0.85, 0.55, 1.50], tags="floating")
  // Fishing rod holder (small post with notch)
  box "rod_holder" (size=[0.10, 0.60, 0.10], mat="wood_dark", pos=[-1.50, 0.80, -1.50], tags="floating")
  // Reeds (clumps around pier)
  cylinder "reed_1" (radius=0.04, height=1.20, mat="reed_green", pos=[-3.0, 0.60, -2.50], tags="floating")
  cylinder "reed_2" (radius=0.04, height=1.00, mat="reed_green", pos=[-2.80, 0.50, -2.80], tags="floating")
  cylinder "reed_3" (radius=0.04, height=1.10, mat="reed_green", pos=[-3.20, 0.55, -2.20], tags="floating")
  cylinder "reed_4" (radius=0.04, height=1.20, mat="reed_green", pos=[3.0, 0.60, 2.50], tags="floating")
  cylinder "reed_5" (radius=0.04, height=1.00, mat="reed_green", pos=[3.20, 0.50, 2.80], tags="floating")
  cylinder "reed_6" (radius=0.04, height=1.10, mat="reed_green", pos=[2.80, 0.55, 2.20], tags="floating")
  // Lantern on post (small accent)
  box "lantern_post" (size=[0.06, 1.50, 0.06], mat="metal_dark", pos=[1.80, 1.30, -1.80], tags="floating")
  box "lantern_box" (size=[0.20, 0.30, 0.20], mat="wood_dark", pos=[1.80, 2.10, -1.80], tags="floating")
}
''')

# ============================================================
# SUBWAY FILLS (3)
# ============================================================

w("buildings", "maintenance_tunnel_junction", '''// maintenance_tunnel_junction.mog — T-junction of subway maintenance tunnels
meta (name="maintenance_tunnel_junction", description="T-junction of subway maintenance tunnels — 3-way intersection with pipes and cables", tags=["building","subway","tunnel","maintenance","tier1"], mogen_version="0.1.12")
material "concrete_tunnel" (color=[0.35,0.33,0.30], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "concrete_dark" (color=[0.20,0.18,0.16], roughness=0.95)
material "pipe_red" (color=[0.65,0.20,0.15], roughness=0.50)
material "pipe_blue" (color=[0.20,0.40,0.65], roughness=0.50)
material "cable_grey" (color=[0.30,0.30,0.32], roughness=0.60)
material "metal_stainless" (color=[0.75,0.75,0.78], roughness=0.30, metallic=0.85)
material "light_amber" (color=[0.95,0.85,0.50], roughness=0.20, emissive=[0.80,0.65,0.30], emissive_strength=0.6)
material "warning_yellow" (color=[0.85,0.70,0.10], roughness=0.60, emissive=[0.40,0.30,0.05], emissive_strength=0.3)
scene {
  // 3 tunnel openings meeting at center — half-cylinder for each + central cube
  // North tunnel (going forward)
  cylinder "tunnel_n" (radius=2.50, height=6.0, mat="concrete_tunnel", pos=[0, 0, -3.0], rot=[0,90,90])
  // West tunnel (going left)
  cylinder "tunnel_w" (radius=2.50, height=6.0, mat="concrete_tunnel", pos=[-3.0, 0, 0], rot=[0,0,90])
  // East tunnel (going right)
  cylinder "tunnel_e" (radius=2.50, height=6.0, mat="concrete_tunnel", pos=[3.0, 0, 0], rot=[0,0,90])
  // Central junction box (cube)
  box "junction_body" (size=[5.0, 5.0, 5.0], mat="concrete_tunnel", pos=[0, 0, 0])
  // Floor (central)
  slab "floor" (size=[8.0, 0.20, 8.0], mat="concrete_dark", pos=[0, -2.40, 0], tags="floating")
  // Pipes along walls (red — high-pressure)
  cylinder "pipe_red_n" (radius=0.20, height=6.0, mat="pipe_red", pos=[-2.20, 0.80, -3.0], rot=[0,90,0], tags="floating")
  cylinder "pipe_red_w" (radius=0.20, height=6.0, mat="pipe_red", pos=[-3.0, 0.80, 2.20], rot=[90,0,0], tags="floating")
  cylinder "pipe_red_e" (radius=0.20, height=6.0, mat="pipe_red", pos=[3.0, 0.80, -2.20], rot=[90,0,0], tags="floating")
  // Pipes (blue — low-pressure)
  cylinder "pipe_blue_n" (radius=0.15, height=6.0, mat="pipe_blue", pos=[-2.0, 0.20, -3.0], rot=[0,90,0], tags="floating")
  cylinder "pipe_blue_w" (radius=0.15, height=6.0, mat="pipe_blue", pos=[-3.0, 0.20, 2.0], rot=[90,0,0], tags="floating")
  cylinder "pipe_blue_e" (radius=0.15, height=6.0, mat="pipe_blue", pos=[3.0, 0.20, -2.0], rot=[90,0,0], tags="floating")
  // Cable clusters
  box "cable_n" (size=[6.0, 0.08, 0.08], mat="cable_grey", pos=[0, 1.50, -2.30], rot=[0,90,0], tags="floating")
  box "cable_w" (size=[0.08, 0.08, 6.0], mat="cable_grey", pos=[-2.30, 1.50, 0], tags="floating")
  box "cable_e" (size=[0.08, 0.08, 6.0], mat="cable_grey", pos=[2.30, 1.50, 0], tags="floating")
  // Junction box (electrical panel on wall)
  box "junction_panel" (size=[0.80, 1.20, 0.20], mat="metal_stainless", pos=[2.30, 0, 0], tags="floating")
  box "panel_door" (size=[0.70, 1.10, 0.05], mat="warning_yellow", pos=[2.41, 0, 0], tags="floating")
  // Warning light
  sphere "warning_light" (radius=0.10, mat="light_amber", pos=[0, 2.30, 0], tags="floating")
  // Floor drains (small dark squares)
  box "drain_1" (size=[0.30, 0.025, 0.30], mat="concrete_dark", pos=[0, -2.30, 0], tags="floating")
  box "drain_grate_1" (size=[0.25, 0.025, 0.05], mat="metal_stainless", pos=[0, -2.30, 0], tags="floating")
  box "drain_grate_2" (size=[0.05, 0.025, 0.25], mat="metal_stainless", pos=[0, -2.30, 0], tags="floating")
  // Rubble pile (corner)
  box "rubble_1" (size=[0.50, 0.30, 0.50], mat="concrete_dark", pos=[-2.0, -2.20, -1.50], tags="floating")
  box "rubble_2" (size=[0.40, 0.20, 0.40], mat="concrete_dark", pos=[-1.80, -2.40, -1.30], tags="floating")
  box "rubble_3" (size=[0.30, 0.15, 0.30], mat="concrete_dark", pos=[-2.20, -2.30, -1.70], tags="floating")
}
''')

w("buildings", "emergency_exit_stairs", '''// emergency_exit_stairs.mog — emergency exit stairwell from subway to surface
meta (name="emergency_exit_stairs", description="Emergency exit stairwell — concrete shaft with stairs from subway level to street level", tags=["building","subway","emergency","stairs","tier1"], mogen_version="0.1.12")
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "concrete_dark" (color=[0.35,0.33,0.30], roughness=0.90)
material "metal_rail" (color=[0.30,0.30,0.35], roughness=0.40, metallic=0.85)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "light_amber" (color=[0.95,0.85,0.50], roughness=0.20, emissive=[0.80,0.65,0.30], emissive_strength=0.6)
material "sign_green" (color=[0.20,0.65,0.20], roughness=0.50, emissive=[0.10,0.45,0.10], emissive_strength=0.6)
material "sign_white_text" (color=[0.95,0.95,0.92], roughness=0.40, emissive=[0.40,0.40,0.35], emissive_strength=0.4)
module "stair_flight_15" () {
  // 15-step flight going up ~3m, with railings
  box "step_1" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.10, -1.40])
  box "step_2" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.30, -1.15])
  box "step_3" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.50, -0.90])
  box "step_4" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.70, -0.65])
  box "step_5" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.90, -0.40])
  box "step_6" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.10, -0.15])
  box "step_7" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.30, 0.10])
  box "step_8" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.50, 0.35])
  box "step_9" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.70, 0.60])
  box "step_10" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.90, 0.85])
  box "step_11" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.10, 1.10])
  box "step_12" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.30, 1.35])
  box "step_13" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.50, 1.60])
  box "step_14" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.70, 1.85])
  box "step_15" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.90, 2.10])
  // Stringer
  box "stringer_l" (size=[0.10, 0.10, 3.80], mat="concrete_dark", pos=[-0.75, 1.50, 0.35], rot=[37,0,0], tags="floating")
  box "stringer_r" (size=[0.10, 0.10, 3.80], mat="concrete_dark", pos=[0.75, 1.50, 0.35], rot=[37,0,0], tags="floating")
  // Handrails
  box "rail_l" (size=[0.05, 0.90, 3.80], mat="metal_rail", pos=[-0.80, 1.95, 0.35], rot=[37,0,0], tags="floating")
  box "rail_r" (size=[0.05, 0.90, 3.80], mat="metal_rail", pos=[0.80, 1.95, 0.35], rot=[37,0,0], tags="floating")
}
scene {
  // Shaft walls (4 sides, 6m tall — from subway level to street)
  wall "wall_n" (size=[4.0, 6.0, 0.20], pos=[0, 3.0, -2.0], mat="concrete", holes=[[0,1.0,1.20,2.00]])
  wall "wall_s" (size=[4.0, 6.0, 0.20], pos=[0, 3.0, 2.0], mat="concrete")
  wall "wall_e" (size=[4.0, 6.0, 0.20], pos=[2.0, 3.0, 0], rot=[0,90,0], mat="concrete")
  wall "wall_w" (size=[4.0, 6.0, 0.20], pos=[-2.0, 3.0, 0], rot=[0,90,0], mat="concrete")
  // Floor (subway level — at Y=0)
  slab "floor_subway" (size=[4.0, 0.20, 4.0], mat="concrete_dark", pos=[0, 0.10, 0])
  // Top (street level — at Y=6)
  slab "roof" (size=[4.0, 0.20, 4.0], mat="concrete_dark", pos=[0, 6.10, 0], tags="floating")
  // 2 flights of stairs (switchback)
  group "flight_1" (pos=[0, 0, 0]) {
    box "step_1" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.20, -1.40])
    box "step_2" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.40, -1.15])
    box "step_3" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.60, -0.90])
    box "step_4" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.80, -0.65])
    box "step_5" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.00, -0.40])
    box "step_6" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.20, -0.15])
    box "step_7" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.40, 0.10])
    box "step_8" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.60, 0.35])
    box "step_9" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.80, 0.60])
    box "step_10" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.00, 0.85])
    box "step_11" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.20, 1.10])
    box "step_12" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.40, 1.35])
    box "step_13" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.60, 1.60])
    box "step_14" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.80, 1.85])
    box "step_15" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 3.00, 2.10])
    box "rail_l" (size=[0.05, 0.90, 3.80], mat="metal_rail", pos=[-0.80, 2.05, 0.35], rot=[37,0,0], tags="floating")
    box "rail_r" (size=[0.05, 0.90, 3.80], mat="metal_rail", pos=[0.80, 2.05, 0.35], rot=[37,0,0], tags="floating")
  }
  // Mid landing (at Y=3.20)
  slab "landing_mid" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 3.20, 0])
  // Second flight (going up the other direction)
  group "flight_2" (pos=[0, 3.20, 0]) {
    box "step_1" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.10, 1.40])
    box "step_2" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.30, 1.15])
    box "step_3" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.50, 0.90])
    box "step_4" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.70, 0.65])
    box "step_5" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 0.90, 0.40])
    box "step_6" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.10, 0.15])
    box "step_7" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.30, -0.10])
    box "step_8" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.50, -0.35])
    box "step_9" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.70, -0.60])
    box "step_10" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 1.90, -0.85])
    box "step_11" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.10, -1.10])
    box "step_12" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.30, -1.35])
    box "step_13" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.50, -1.60])
    box "step_14" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.70, -1.85])
    box "step_15" (size=[1.60, 0.04, 0.25], mat="concrete", pos=[0, 2.90, -2.10])
    box "rail_l" (size=[0.05, 0.90, 3.80], mat="metal_rail", pos=[-0.80, 2.05, -0.35], rot=[-37,0,0], tags="floating")
    box "rail_r" (size=[0.05, 0.90, 3.80], mat="metal_rail", pos=[0.80, 2.05, -0.35], rot=[-37,0,0], tags="floating")
  }
  // Top landing
  slab "landing_top" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 6.00, 0])
  // Exit door (street level)
  box "exit_door" (size=[1.20, 2.00, 0.10], mat="metal_dark", pos=[0, 4.00, -2.05], tags="floating")
  box "exit_handle" (size=[0.04, 0.20, 0.05], mat="metal_dark", pos=[0.40, 4.00, -2.15], tags="floating")
  // Emergency light (on wall, glowing)
  box "elight" (size=[0.30, 0.20, 0.10], mat="light_amber", pos=[1.80, 5.50, 0], tags="floating")
  // Exit sign (green with white arrow)
  box "sign_back" (size=[0.80, 0.40, 0.10], mat="sign_green", pos=[0, 5.30, -2.05], tags="floating")
  box "sign_arrow" (size=[0.40, 0.10, 0.02], mat="sign_white_text", pos=[0, 5.30, -2.10], tags="floating")
  // Pipe running up corner
  cylinder "pipe_corner" (radius=0.10, height=6.0, mat="metal_dark", pos=[1.80, 3.00, 1.80], tags="floating")
  // Rubble at base
  box "rubble_1" (size=[0.50, 0.30, 0.50], mat="concrete_dark", pos=[1.50, 0.15, -1.50], tags="floating")
  box "rubble_2" (size=[0.40, 0.20, 0.40], mat="concrete_dark", pos=[1.30, 0.10, -1.30], tags="floating")
}
''')

w("buildings", "subway_pipe_cluster", '''// subway_pipe_cluster.mog — wall-mounted cluster of pipes + cables + valves
meta (name="subway_pipe_cluster", description="Wall-mounted cluster of subway pipes, cables, valves, and junction boxes", tags=["building","subway","infrastructure","pipes","tier1"], mogen_version="0.1.12")
material "concrete_wall" (color=[0.35,0.33,0.30], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "pipe_red" (color=[0.65,0.20,0.15], roughness=0.50)
material "pipe_blue" (color=[0.20,0.40,0.65], roughness=0.50)
material "pipe_yellow" (color=[0.75,0.60,0.15], roughness=0.50)
material "pipe_green" (color=[0.30,0.55,0.20], roughness=0.50)
material "cable_grey" (color=[0.30,0.30,0.32], roughness=0.60)
material "cable_black" (color=[0.10,0.10,0.12], roughness=0.70)
material "metal_stainless" (color=[0.75,0.75,0.78], roughness=0.30, metallic=0.85)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "valve_wheel_red" (color=[0.65,0.15,0.10], roughness=0.40, metallic=0.4)
material "warning_yellow" (color=[0.85,0.70,0.10], roughness=0.60, emissive=[0.40,0.30,0.05], emissive_strength=0.3)
scene {
  // Wall behind pipes
  wall "wall_back" (size=[6.0, 4.0, 0.20], pos=[0, 2.0, -1.0], mat="concrete_wall")
  // Horizontal pipes (4 levels, different colors/sizes)
  // Red pipe (top, largest)
  cylinder "pipe_red_h" (radius=0.20, height=5.0, mat="pipe_red", pos=[0, 3.50, -0.80], rot=[0,90,0], tags="floating")
  // Pipe supports (U-brackets)
  box "bracket_r_1" (size=[0.10, 0.40, 0.10], mat="metal_stainless", pos=[-2.0, 3.50, -0.80], tags="floating")
  box "bracket_r_2" (size=[0.10, 0.40, 0.10], mat="metal_stainless", pos=[2.0, 3.50, -0.80], tags="floating")
  // Yellow pipe (medium, second level)
  cylinder "pipe_yellow_h" (radius=0.15, height=5.0, mat="pipe_yellow", pos=[0, 3.0, -0.80], rot=[0,90,0], tags="floating")
  box "bracket_y_1" (size=[0.08, 0.30, 0.08], mat="metal_stainless", pos=[-1.5, 3.0, -0.80], tags="floating")
  box "bracket_y_2" (size=[0.08, 0.30, 0.08], mat="metal_stainless", pos=[1.5, 3.0, -0.80], tags="floating")
  // Blue pipe (third level)
  cylinder "pipe_blue_h" (radius=0.12, height=5.0, mat="pipe_blue", pos=[0, 2.50, -0.80], rot=[0,90,0], tags="floating")
  box "bracket_b_1" (size=[0.08, 0.25, 0.08], mat="metal_stainless", pos=[-2.0, 2.50, -0.80], tags="floating")
  box "bracket_b_2" (size=[0.08, 0.25, 0.08], mat="metal_stainless", pos=[2.0, 2.50, -0.80], tags="floating")
  // Green pipe (smallest, lowest)
  cylinder "pipe_green_h" (radius=0.08, height=5.0, mat="pipe_green", pos=[0, 2.10, -0.80], rot=[0,90,0], tags="floating")
  // Vertical drops (3 pipes dropping down from main runs)
  cylinder "drop_red" (radius=0.20, height=1.0, mat="pipe_red", pos=[-1.50, 2.90, -0.80], tags="floating")
  cylinder "drop_yellow" (radius=0.15, height=1.0, mat="pipe_yellow", pos=[0.50, 2.50, -0.80], tags="floating")
  cylinder "drop_blue" (radius=0.12, height=1.0, mat="pipe_blue", pos=[1.80, 2.10, -0.80], tags="floating")
  // Elbow joints (90-degree turns)
  torus "elbow_red" (radius=0.20, tube_radius=0.20, mat="pipe_red", pos=[-1.50, 2.40, -0.80], rot=[90,0,0], tags="floating")
  torus "elbow_yellow" (radius=0.15, tube_radius=0.15, mat="pipe_yellow", pos=[0.50, 2.00, -0.80], rot=[90,0,0], tags="floating")
  torus "elbow_blue" (radius=0.12, tube_radius=0.12, mat="pipe_blue", pos=[1.80, 1.60, -0.80], rot=[90,0,0], tags="floating")
  // Horizontal pipe continuing forward after drops
  cylinder "cont_red" (radius=0.20, height=2.0, mat="pipe_red", pos=[-1.50, 1.90, -0.80], rot=[90,0,0], tags="floating")
  cylinder "cont_yellow" (radius=0.15, height=2.0, mat="pipe_yellow", pos=[0.50, 1.50, -0.80], rot=[90,0,0], tags="floating")
  cylinder "cont_blue" (radius=0.12, height=2.0, mat="pipe_blue", pos=[1.80, 1.10, -0.80], rot=[90,0,0], tags="floating")
  // Valve wheels (3 — red, yellow, blue pipes)
  cylinder "valve_red" (radius=0.25, height=0.05, mat="valve_wheel_red", pos=[-1.50, 0.90, -0.80], rot=[90,0,0], tags="floating")
  box "valve_red_spoke_1" (size=[0.05, 0.50, 0.04], mat="valve_wheel_red", pos=[-1.50, 0.90, -0.80], tags="floating")
  box "valve_red_spoke_2" (size=[0.50, 0.05, 0.04], mat="valve_wheel_red", pos=[-1.50, 0.90, -0.80], tags="floating")
  cylinder "valve_yellow" (radius=0.20, height=0.04, mat="metal_dark", pos=[0.50, 0.50, -0.80], rot=[90,0,0], tags="floating")
  cylinder "valve_blue" (radius=0.15, height=0.04, mat="metal_dark", pos=[1.80, 0.10, -0.80], rot=[90,0,0], tags="floating")
  // Electrical junction box (mounted on wall)
  box "junction_box" (size=[1.0, 1.20, 0.30], mat="metal_dark", pos=[-2.0, 1.0, -0.90], tags="floating")
  box "junction_door" (size=[0.85, 1.0, 0.05], mat="warning_yellow", pos=[-2.0, 1.0, -1.05], tags="floating")
  // Cables (hanging in loops between pipes)
  box "cable_1" (size=[0.04, 0.60, 0.04], mat="cable_grey", pos=[0, 1.50, -0.50], rot=[15,0,0], tags="floating")
  box "cable_2" (size=[0.04, 0.50, 0.04], mat="cable_black", pos=[0.50, 1.50, -0.50], rot=[-10,0,0], tags="floating")
  box "cable_3" (size=[0.04, 0.70, 0.04], mat="cable_grey", pos=[1.0, 1.50, -0.50], rot=[20,0,0], tags="floating")
  // Warning labels on pipes (small stripes)
  box "label_red_1" (size=[0.40, 0.10, 0.02], mat="warning_yellow", pos=[-1.0, 3.50, -0.61], tags="floating")
  box "label_yellow_1" (size=[0.30, 0.10, 0.02], mat="warning_yellow", pos=[1.0, 3.00, -0.66], tags="floating")
}
''')

# ============================================================
# MILITARY FILLS (2)
# ============================================================

w("environment", "mass_grave", '''// mass_grave.mog — dark mass grave with mounds and crosses
meta (name="mass_grave", description="Mass grave site — disturbed earth mounds with simple wooden crosses and dark atmosphere", tags=["environment","military","grave","horror","dark","tier1"], mogen_version="0.1.12")
material "soil_dark" (color=[0.20,0.16,0.10], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "soil_mound" (color=[0.25,0.20,0.14], roughness=0.95, uv_mode="tile", uv_scale=3.0)
material "cross_wood" (color=[0.35,0.28,0.18], roughness=0.85)
material "grass_dead" (color=[0.30,0.32,0.18], roughness=0.95, uv_mode="tile", uv_scale=2.5)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "warning_red" (color=[0.65,0.15,0.10], roughness=0.50, emissive=[0.30,0.05,0.05], emissive_strength=0.4)
scene {
  // Outer dead grass area
  slab "ground" (size=[16.0, 0.04, 12.0], mat="grass_dead", tags="floating")
  // 3 main burial mounds (elongated, irregular)
  cone "mound_1" (radius=3.0, height=1.2, mat="soil_mound", pos=[-3.0, 0.60, 0], tags="floating")
  cone "mound_2" (radius=2.8, height=1.0, mat="soil_mound", pos=[2.0, 0.50, -1.0], tags="floating")
  cone "mound_3" (radius=2.5, height=0.9, mat="soil_mound", pos=[0, 0.45, 2.0], tags="floating")
  // Smaller disturbed earth patches
  slab "soil_patch_1" (size=[4.0, 0.05, 3.0], mat="soil_dark", pos=[-4.0, 0.04, -2.0], tags="floating")
  slab "soil_patch_2" (size=[3.0, 0.05, 4.0], mat="soil_dark", pos=[3.0, 0.04, 2.0], tags="floating")
  // 5 wooden crosses (stuck in mounds)
  // Cross 1
  box "cross_1_v" (size=[0.10, 1.20, 0.10], mat="cross_wood", pos=[-3.0, 0.60, 0], tags="floating")
  box "cross_1_h" (size=[0.50, 0.10, 0.10], mat="cross_wood", pos=[-3.0, 1.10, 0], tags="floating")
  // Cross 2
  box "cross_2_v" (size=[0.10, 1.00, 0.10], mat="cross_wood", pos=[2.0, 0.50, -1.0], tags="floating")
  box "cross_2_h" (size=[0.40, 0.10, 0.10], mat="cross_wood", pos=[2.0, 0.90, -1.0], tags="floating")
  // Cross 3 (leaning)
  box "cross_3_v" (size=[0.10, 1.10, 0.10], mat="cross_wood", pos=[0, 0.50, 2.0], rot=[0,0,15], tags="floating")
  box "cross_3_h" (size=[0.40, 0.10, 0.10], mat="cross_wood", pos=[0.10, 0.95, 2.0], rot=[0,0,15], tags="floating")
  // Cross 4
  box "cross_4_v" (size=[0.10, 0.90, 0.10], mat="cross_wood", pos=[-5.0, 0.50, 1.0], tags="floating")
  box "cross_4_h" (size=[0.40, 0.10, 0.10], mat="cross_wood", pos=[-5.0, 0.85, 1.0], tags="floating")
  // Cross 5 (broken, lying on ground)
  box "cross_5_v" (size=[0.10, 0.80, 0.10], mat="cross_wood", pos=[4.0, 0.05, 1.0], rot=[0,0,90], tags="floating")
  box "cross_5_h" (size=[0.40, 0.10, 0.10], mat="cross_wood", pos=[3.60, 0.05, 1.0], rot=[0,0,90], tags="floating")
  // Warning sign
  box "sign_post" (size=[0.10, 1.80, 0.10], mat="metal_dark", pos=[-6.0, 0.90, -3.0], tags="floating")
  box "sign_board" (size=[1.0, 0.60, 0.05], mat="warning_red", pos=[-6.0, 1.50, -3.0], tags="floating")
  // Barbed wire around perimeter (corner posts only, for simplicity)
  box "wire_post_1" (size=[0.10, 1.20, 0.10], mat="metal_dark", pos=[-7.0, 0.60, -5.0], tags="floating")
  box "wire_post_2" (size=[0.10, 1.20, 0.10], mat="metal_dark", pos=[7.0, 0.60, -5.0], tags="floating")
  box "wire_post_3" (size=[0.10, 1.20, 0.10], mat="metal_dark", pos=[-7.0, 0.60, 5.0], tags="floating")
  box "wire_post_4" (size=[0.10, 1.20, 0.10], mat="metal_dark", pos=[7.0, 0.60, 5.0], tags="floating")
  // Barbed wire strands
  box "wire_1" (size=[14.0, 0.03, 0.03], mat="metal_dark", pos=[0, 1.50, -5.0], tags="floating")
  box "wire_2" (size=[14.0, 0.03, 0.03], mat="metal_dark", pos=[0, 0.50, -5.0], tags="floating")
  box "wire_3" (size=[14.0, 0.03, 0.03], mat="metal_dark", pos=[0, 1.50, 5.0], tags="floating")
  box "wire_4" (size=[14.0, 0.03, 0.03], mat="metal_dark", pos=[0, 0.50, 5.0], tags="floating")
  box "wire_5" (size=[0.03, 0.03, 10.0], mat="metal_dark", pos=[-7.0, 1.50, 0], tags="floating")
  box "wire_6" (size=[0.03, 0.03, 10.0], mat="metal_dark", pos=[7.0, 1.50, 0], tags="floating")
  // Some bones scattered (small white shapes)
  box "bone_1" (size=[0.40, 0.05, 0.05], mat="cross_wood", pos=[1.0, 0.05, 0.50], rot=[0,30,0], tags="floating")
  box "bone_2" (size=[0.30, 0.05, 0.05], mat="cross_wood", pos=[-2.0, 0.05, 1.50], rot=[0,-45,0], tags="floating")
  box "bone_3" (size=[0.25, 0.05, 0.05], mat="cross_wood", pos=[3.0, 0.05, -2.0], rot=[0,15,0], tags="floating")
}
''')

w("buildings", "helipad_control_room", '''// helipad_control_room.mog — small air traffic control room for helipad
meta (name="helipad_control_room", description="Small control room for helipad — glass-walled cabin on short tower with radar dish", tags=["building","military","control","tower","tier1"], mogen_version="0.1.12")
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "metal_olive" (color=[0.30,0.32,0.20], roughness=0.60, metallic=0.7)
material "glass_dark" (color=[0.20,0.30,0.30], transmission=0.40, roughness=0.10)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "metal_stainless" (color=[0.75,0.75,0.78], roughness=0.30, metallic=0.85)
material "light_warm" (color=[0.95,0.85,0.55], roughness=0.20, emissive=[0.80,0.65,0.30], emissive_strength=0.6)
material "warning_red" (color=[0.95,0.10,0.10], roughness=0.40, emissive=[0.7,0.05,0.05], emissive_strength=0.8)
scene {
  // Concrete base
  slab "base" (size=[4.0, 0.30, 4.0], mat="concrete", pos=[0, 0.15, 0])
  // Tower shaft (5m tall, tapered slightly)
  box "tower_shaft" (size=[2.0, 5.0, 2.0], mat="metal_olive", pos=[0, 2.80, 0])
  // Control cabin (glass-walled, on top of shaft)
  box "cabin_body" (size=[4.0, 2.50, 4.0], mat="metal_olive", pos=[0, 6.50, 0])
  // Glass windows (4 sides, slightly recessed)
  box "win_n" (size=[3.50, 1.80, 0.05], mat="glass_dark", pos=[0, 6.70, -2.00], tags="floating")
  box "win_s" (size=[3.50, 1.80, 0.05], mat="glass_dark", pos=[0, 6.70, 2.00], tags="floating")
  box "win_e" (size=[0.05, 1.80, 3.50], mat="glass_dark", pos=[2.00, 6.70, 0], tags="floating")
  box "win_w" (size=[0.05, 1.80, 3.50], mat="glass_dark", pos=[-2.00, 6.70, 0], tags="floating")
  // Roof
  slab "cabin_roof" (size=[4.2, 0.20, 4.2], mat="metal_olive", pos=[0, 7.85, 0], tags="floating")
  // Radar dome on roof (small)
  cylinder "radar_base" (radius=0.40, height=0.30, mat="metal_olive", pos=[0, 8.10, 0], tags="floating")
  sphere "radar_dome" (radius=0.45, mat="metal_stainless", pos=[0, 8.50, 0], tags="floating")
  // Radar dish (small, on side of dome)
  cylinder "dish_pole" (radius=0.05, height=0.60, mat="metal_dark", pos=[0.60, 8.50, 0], rot=[0,0,30], tags="floating")
  cone "dish" (radius=0.40, height=0.20, mat="metal_stainless", pos=[0.90, 8.80, 0], rot=[0,0,90], tags="floating")
  // Antenna mast (tall thin)
  cylinder "antenna" (radius=0.03, height=2.0, mat="metal_dark", pos=[-0.50, 9.20, 0], tags="floating")
  sphere "antenna_light" (radius=0.06, mat="warning_red", pos=[-0.50, 10.20, 0], tags="floating")
  // Door at base of tower
  box "tower_door" (size=[0.80, 1.80, 0.10], mat="metal_dark", pos=[0, 1.40, -1.05], tags="floating")
  // Interior light visible through windows
  box "int_light" (size=[0.30, 0.20, 0.10], mat="light_warm", pos=[0, 6.50, -1.50], tags="floating")
  // Exterior light (above door)
  box "ext_light" (size=[0.30, 0.20, 0.10], mat="light_warm", pos=[0, 2.50, -1.05], tags="floating")
  // Ladder / external stair on tower side (visible steps)
  box "stair_str_l" (size=[0.06, 5.0, 0.06], mat="metal_dark", pos=[1.05, 2.50, 0], rot=[0,0,10], tags="floating")
  box "stair_str_r" (size=[0.06, 5.0, 0.06], mat="metal_dark", pos=[1.30, 2.50, 0], rot=[0,0,10], tags="floating")
  box "rung_1" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.15, 0.60, 0], tags="floating")
  box "rung_2" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.18, 1.20, 0], tags="floating")
  box "rung_3" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.21, 1.80, 0], tags="floating")
  box "rung_4" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.24, 2.40, 0], tags="floating")
  box "rung_5" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.27, 3.00, 0], tags="floating")
  box "rung_6" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.30, 3.60, 0], tags="floating")
  box "rung_7" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.33, 4.20, 0], tags="floating")
  box "rung_8" (size=[0.30, 0.04, 0.04], mat="metal_dark", pos=[1.36, 4.80, 0], tags="floating")
  // Concrete landing pad next to tower
  slab "landing_pad" (size=[8.0, 0.20, 8.0], mat="concrete", pos=[6.0, 0.10, 0])
  // H marker on pad
  box "h_pad_l" (size=[0.40, 0.04, 2.0], mat="warning_red", pos=[5.20, 0.21, 0], tags="floating")
  box "h_pad_r" (size=[0.40, 0.04, 2.0], mat="warning_red", pos=[6.80, 0.21, 0], tags="floating")
  box "h_pad_cross" (size=[2.0, 0.04, 0.40], mat="warning_red", pos=[6.0, 0.21, 0], tags="floating")
}
''')

# ============================================================
# COMMERCIAL FILLS (3)
# ============================================================

w("buildings", "salon", '''// salon.mog — hair salon with large storefront windows
meta (name="salon", description="Hair salon with large storefront windows, awning, and pole", tags=["building","commercial","salon","downtown","tier1"], mogen_version="0.1.12")
material "wall_stucco" (color=[0.80,0.65,0.55], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_white" (color=[0.92,0.90,0.85], roughness=0.85)
material "roof_flat" (color=[0.20,0.20,0.22], roughness=0.90)
material "trim_white" (color=[0.95,0.95,0.93], roughness=0.60)
material "window_glass" (color=[0.30,0.45,0.55], transmission=0.60, roughness=0.03)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.60, roughness=0.04)
material "awning_pink" (color=[0.85,0.55,0.65], roughness=0.70)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "chair_red" (color=[0.55,0.20,0.18], roughness=0.70)
material "mirror_glass" (color=[0.85,0.90,0.95], roughness=0.05, metallic=0.6)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "salon_chair" () {
  box "base" (size=[0.60, 0.20, 0.60], mat="metal_dark")
  box "seat" (size=[0.55, 0.10, 0.55], mat="chair_red", pos=[0, 0.30, 0])
  box "back" (size=[0.55, 0.80, 0.10], mat="chair_red", pos=[0, 0.75, -0.25])
  box "arm_l" (size=[0.10, 0.30, 0.40], mat="chair_red", pos=[-0.30, 0.50, 0])
  box "arm_r" (size=[0.10, 0.30, 0.40], mat="chair_red", pos=[0.30, 0.50, 0])
  // Mirror in front
  box "mirror_frame" (size=[0.50, 1.0, 0.06], mat="trim_white", pos=[0, 1.0, -0.80])
  box "mirror" (size=[0.40, 0.90, 0.02], mat="mirror_glass", pos=[0, 1.0, -0.84], tags="floating")
}
scene {
  slab "sidewalk" (size=[10.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0], tags="floating")
  slab "foundation" (size=[8.0, 0.30, 6.0], mat="concrete", pos=[0, 0.15, 0])
  // Body
  box "body" (size=[8.0, 3.20, 6.0], mat="wall_stucco", pos=[0, 1.90, 0])
  // Lower accent
  box "lower" (size=[8.0, 0.60, 6.0], mat="wall_white", pos=[0, 0.50, 0])
  // Roof
  slab "roof" (size=[8.4, 0.20, 6.4], mat="roof_flat", pos=[0, 3.60, 0], tags="floating")
  // Awning (pink, sloped)
  prism "awning" (size=[8.0, 0.30, 1.50], pos=[0, 3.30, -3.5], mat="awning_pink")
  // Front wall — big storefront window + door
  wall "front_wall" (size=[8.0, 3.20, 0.20], pos=[0, 1.90, -3.0], holes=[[-2.0,-0.20,2.50,2.30],[1.5,-0.20,1.10,2.30]])
  // Back wall (smaller windows)
  wall "back_wall" (size=[8.0, 3.20, 0.20], pos=[0, 1.90, 3.0], holes=[[-2.5,0.30,1.20,1.20],[2.5,0.30,1.20,1.20]])
  // Side walls
  wall "left_wall" (size=[6.0, 3.20, 0.20], pos=[-4.0, 1.90, 0], rot=[0,90,0], holes=[[-1.5,0.30,1.20,1.20],[1.5,0.30,1.20,1.20]])
  wall "right_wall" (size=[6.0, 3.20, 0.20], pos=[4.0, 1.90, 0], rot=[0,90,0], holes=[[-1.5,0.30,1.20,1.20],[1.5,0.30,1.20,1.20]])
  // Storefront window (big glass)
  box "storefront_frame" (size=[2.60, 2.40, 0.06], mat="trim_white", pos=[-2.0, 1.10, -3.0], tags="floating")
  box "storefront_glass" (size=[2.40, 2.20, 0.02], mat="window_glass", pos=[-2.0, 1.10, -3.04], tags="floating")
  // Door
  box "door_frame" (size=[1.20, 2.30, 0.06], mat="trim_white", pos=[1.5, 1.05, -3.0], tags="floating")
  box "door_glass" (size=[1.05, 2.15, 0.02], mat="door_glass", pos=[1.5, 1.05, -3.04], tags="floating")
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[1.95, 1.05, -3.06], tags="floating")
  // Sign on roof
  box "sign_post_l" (size=[0.08, 0.50, 0.08], mat="trim_white", pos=[-2.5, 3.95, -3.0], tags="floating")
  box "sign_post_r" (size=[0.08, 0.50, 0.08], mat="trim_white", pos=[2.5, 3.95, -3.0], tags="floating")
  box "sign_board" (size=[5.0, 0.60, 0.10], mat="trim_white", pos=[0, 4.40, -3.0], tags="floating")
  box "sign_text" (size=[4.0, 0.05, 0.02], mat="awning_pink", pos=[0, 4.40, -3.06], tags="floating")
  // Interior salon chairs (3, visible through storefront window)
  group "chair_1" (pos=[-2.50, 0.30, -1.50]) { use "salon_chair" () }
  group "chair_2" (pos=[-1.20, 0.30, -1.50]) { use "salon_chair" () }
  group "chair_3" (pos=[0.10, 0.30, -1.50]) { use "salon_chair" () }
  // Reception desk (small, near door)
  box "reception" (size=[1.50, 1.00, 0.60], mat="wall_white", pos=[2.0, 0.50, -1.50], tags="floating")
  box "reception_top" (size=[1.60, 0.05, 0.70], mat="trim_white", pos=[2.0, 1.05, -1.50], tags="floating")
}
''')

w("buildings", "grocery_store", '''// grocery_store.mog — small neighborhood grocery with storefront windows
meta (name="grocery_store", description="Small neighborhood grocery store with storefront windows and shopping cart return", tags=["building","commercial","downtown","tier1"], mogen_version="0.1.12")
material "wall_brick" (color=[0.55,0.30,0.25], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wall_stucco" (color=[0.75,0.70,0.60], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_flat" (color=[0.20,0.20,0.22], roughness=0.90)
material "trim_white" (color=[0.95,0.95,0.93], roughness=0.60)
material "window_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "sign_red" (color=[0.65,0.15,0.10], roughness=0.70, emissive=[0.40,0.05,0.05], emissive_strength=0.4)
material "shelf_wood" (color=[0.45,0.32,0.20], roughness=0.85)
material "produce_orange" (color=[0.85,0.55,0.20], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "produce_green" (color=[0.30,0.55,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "cart_metal" (color=[0.40,0.40,0.42], roughness=0.50, metallic=0.85)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "gro_shelf" () {
  // 4-tier shelf with produce
  box "frame_l" (size=[0.10, 2.0, 0.10], mat="shelf_wood", pos=[-0.80, 1.00, 0])
  box "frame_r" (size=[0.10, 2.0, 0.10], mat="shelf_wood", pos=[0.80, 1.00, 0])
  box "shelf_1" (size=[1.70, 0.05, 0.40], mat="shelf_wood", pos=[0, 0.30, 0])
  box "shelf_2" (size=[1.70, 0.05, 0.40], mat="shelf_wood", pos=[0, 0.80, 0])
  box "shelf_3" (size=[1.70, 0.05, 0.40], mat="shelf_wood", pos=[0, 1.30, 0])
  box "shelf_4" (size=[1.70, 0.05, 0.40], mat="shelf_wood", pos=[0, 1.80, 0])
  // Produce (small spheres) on each shelf
  sphere "p_1a" (radius=0.10, mat="produce_orange", pos=[-0.60, 0.45, 0], tags="floating")
  sphere "p_1b" (radius=0.10, mat="produce_orange", pos=[-0.30, 0.45, 0], tags="floating")
  sphere "p_1c" (radius=0.10, mat="produce_green", pos=[0, 0.45, 0], tags="floating")
  sphere "p_1d" (radius=0.10, mat="produce_green", pos=[0.30, 0.45, 0], tags="floating")
  sphere "p_1e" (radius=0.10, mat="produce_orange", pos=[0.60, 0.45, 0], tags="floating")
  sphere "p_2a" (radius=0.10, mat="produce_green", pos=[-0.60, 0.95, 0], tags="floating")
  sphere "p_2b" (radius=0.10, mat="produce_green", pos=[-0.30, 0.95, 0], tags="floating")
  sphere "p_2c" (radius=0.10, mat="produce_orange", pos=[0, 0.95, 0], tags="floating")
  sphere "p_2d" (radius=0.10, mat="produce_orange", pos=[0.30, 0.95, 0], tags="floating")
  sphere "p_2e" (radius=0.10, mat="produce_green", pos=[0.60, 0.95, 0], tags="floating")
  sphere "p_3a" (radius=0.10, mat="produce_orange", pos=[-0.40, 1.45, 0], tags="floating")
  sphere "p_3b" (radius=0.10, mat="produce_green", pos=[0.40, 1.45, 0], tags="floating")
}
module "shopping_cart_small" () {
  // Simplified cart
  box "basket" (size=[0.60, 0.40, 0.40], mat="cart_metal")
  box "handle" (size=[0.05, 0.50, 0.05], mat="cart_metal", pos=[0, 0.45, -0.25], tags="floating")
  box "handle_top" (size=[0.30, 0.05, 0.05], mat="cart_metal", pos=[0, 0.70, -0.25], tags="floating")
  cylinder "wheel_fl" (radius=0.10, height=0.05, mat="cart_metal", pos=[-0.30, 0.05, -0.20], rot=[90,0,0], tags="floating")
  cylinder "wheel_fr" (radius=0.10, height=0.05, mat="cart_metal", pos=[0.30, 0.05, -0.20], rot=[90,0,0], tags="floating")
  cylinder "wheel_bl" (radius=0.10, height=0.05, mat="cart_metal", pos=[-0.30, 0.05, 0.20], rot=[90,0,0], tags="floating")
  cylinder "wheel_br" (radius=0.10, height=0.05, mat="cart_metal", pos=[0.30, 0.05, 0.20], rot=[90,0,0], tags="floating")
}
scene {
  slab "parking" (size=[14.0, 0.05, 8.0], mat="asphalt", pos=[0, 0.025, 3.0], tags="floating")
  slab "foundation" (size=[12.0, 0.30, 7.0], mat="concrete", pos=[0, 0.15, 0])
  // Lower brick band
  box "lower_brick" (size=[12.0, 1.0, 7.0], mat="wall_brick", pos=[0, 0.70, 0])
  // Upper stucco
  box "upper_stucco" (size=[12.0, 2.50, 7.0], mat="wall_stucco", pos=[0, 2.45, 0])
  // Roof
  slab "roof" (size=[12.4, 0.20, 7.4], mat="roof_flat", pos=[0, 3.80, 0], tags="floating")
  // Front wall — 2 storefront windows + central door
  wall "front_wall" (size=[12.0, 3.50, 0.20], pos=[0, 2.25, -3.5], holes=[[-3.50,-0.40,3.00,2.50],[3.50,-0.40,3.00,2.50],[0,-0.30,1.50,2.40]])
  // Back wall (small windows)
  wall "back_wall" (size=[12.0, 3.50, 0.20], pos=[0, 2.25, 3.5], holes=[[-4.0,0.5,1.20,1.20],[-2.0,0.5,1.20,1.20],[2.0,0.5,1.20,1.20],[4.0,0.5,1.20,1.20]])
  // Side walls
  wall "left_wall" (size=[7.0, 3.50, 0.20], pos=[-6.0, 2.25, 0], rot=[0,90,0], holes=[[-2.0,0.5,1.20,1.20],[2.0,0.5,1.20,1.20]])
  wall "right_wall" (size=[7.0, 3.50, 0.20], pos=[6.0, 2.25, 0], rot=[0,90,0], holes=[[-2.0,0.5,1.20,1.20],[2.0,0.5,1.20,1.20]])
  // Storefront windows
  box "storefront_l_frame" (size=[3.10, 2.60, 0.06], mat="trim_white", pos=[-3.50, 1.10, -3.5], tags="floating")
  box "storefront_l_glass" (size=[2.90, 2.40, 0.02], mat="window_glass", pos=[-3.50, 1.10, -3.54], tags="floating")
  box "storefront_r_frame" (size=[3.10, 2.60, 0.06], mat="trim_white", pos=[3.50, 1.10, -3.5], tags="floating")
  box "storefront_r_glass" (size=[2.90, 2.40, 0.02], mat="window_glass", pos=[3.50, 1.10, -3.54], tags="floating")
  // Door
  box "door_frame" (size=[1.60, 2.40, 0.06], mat="trim_white", pos=[0, 1.05, -3.5], tags="floating")
  box "door_glass" (size=[1.45, 2.25, 0.02], mat="door_glass", pos=[0, 1.05, -3.54], tags="floating")
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.60, 1.05, -3.56], tags="floating")
  // Sign (big, on roof)
  box "sign_back" (size=[10.0, 1.50, 0.20], mat="sign_red", pos=[0, 4.80, -3.5], tags="floating")
  box "sign_text_1" (size=[8.0, 0.20, 0.02], mat="trim_white", pos=[0, 5.20, -3.61], tags="floating")
  box "sign_text_2" (size=[6.0, 0.20, 0.02], mat="trim_white", pos=[0, 4.80, -3.61], tags="floating")
  // Interior shelves (visible through windows)
  group "shelf_l" (pos=[-3.50, 0.30, -1.0]) { use "gro_shelf" () }
  group "shelf_r" (pos=[3.50, 0.30, -1.0]) { use "gro_shelf" () }
  // Shopping cart return (outside, on parking)
  box "cart_corral_l" (size=[0.05, 1.0, 3.0], mat="cart_metal", pos=[-1.50, 0.50, 5.0], tags="floating")
  box "cart_corral_r" (size=[0.05, 1.0, 3.0], mat="cart_metal", pos=[1.50, 0.50, 5.0], tags="floating")
  box "cart_corral_b" (size=[3.0, 1.0, 0.05], mat="cart_metal", pos=[0, 0.50, 6.50], tags="floating")
  // 2 shopping carts in the corral
  group "cart_1" (pos=[-0.70, 0.10, 5.50]) { use "shopping_cart_small" () }
  group "cart_2" (pos=[0.50, 0.10, 5.50]) { use "shopping_cart_small" () }
  // Entrance mat
  slab "mat" (size=[2.0, 0.04, 1.0], mat="wall_brick", pos=[0, 0.04, -4.0], tags="floating")
}
''')

w("buildings", "bank_branch", '''// bank_branch.mog — small bank branch with classical columns + ATM
meta (name="bank_branch", description="Small bank branch with classical columns, vaulted entrance, and ATM", tags=["building","commercial","bank","downtown","tier1"], mogen_version="0.1.12")
material "wall_stone" (color=[0.70,0.65,0.55], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wall_marble" (color=[0.85,0.82,0.75], roughness=0.50, uv_mode="tile", uv_scale=3.0)
material "column_marble" (color=[0.92,0.90,0.85], roughness=0.40)
material "roof_flat" (color=[0.20,0.20,0.22], roughness=0.90)
material "window_glass" (color=[0.30,0.40,0.50], transmission=0.45, roughness=0.05)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
material "sign_blue" (color=[0.15,0.30,0.55], roughness=0.50, emissive=[0.05,0.10,0.20], emissive_strength=0.3)
material "sign_white_text" (color=[0.95,0.95,0.92], roughness=0.40, emissive=[0.40,0.40,0.35], emissive_strength=0.4)
material "atm_screen" (color=[0.15,0.30,0.50], roughness=0.20, emissive=[0.10,0.20,0.40], emissive_strength=0.6)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
module "bank_column" () {
  box "base" (size=[0.80, 0.20, 0.80], mat="column_marble")
  cylinder "shaft" (radius=0.30, height=3.80, mat="column_marble", pos=[0, 2.10, 0])
  box "capital" (size=[0.80, 0.30, 0.80], mat="column_marble", pos=[0, 4.15, 0])
}
module "atm" () {
  box "body" (size=[1.20, 2.20, 0.80], mat="metal_dark")
  box "screen_frame" (size=[0.90, 0.70, 0.05], mat="metal_dark", pos=[0, 0.40, 0.40], tags="floating")
  box "screen" (size=[0.80, 0.60, 0.02], mat="atm_screen", pos=[0, 0.40, 0.43], tags="floating")
  // Card reader
  box "card_slot" (size=[0.30, 0.05, 0.05], mat="metal_dark", pos=[0, 0.0, 0.43], tags="floating")
  // Cash dispenser slot
  box "cash_slot" (size=[0.40, 0.05, 0.05], mat="metal_dark", pos=[0, -0.50, 0.43], tags="floating")
  // Key pad
  box "keypad" (size=[0.30, 0.30, 0.05], mat="metal_dark", pos=[0, -0.20, 0.43], tags="floating")
  // Branded top
  box "top_sign" (size=[1.30, 0.30, 0.10], mat="sign_blue", pos=[0, 1.20, 0.45], tags="floating")
  box "top_text" (size=[1.0, 0.05, 0.02], mat="sign_white_text", pos=[0, 1.20, 0.51], tags="floating")
}
scene {
  slab "sidewalk" (size=[12.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0], tags="floating")
  slab "foundation" (size=[10.0, 0.40, 6.0], mat="concrete", pos=[0, 0.20, 0])
  // Body
  box "body" (size=[10.0, 4.50, 6.0], mat="wall_stone", pos=[0, 2.65, 0])
  // Lower marble band
  box "lower_marble" (size=[10.0, 1.0, 6.0], mat="wall_marble", pos=[0, 0.80, 0])
  // Roof (with cornice)
  slab "roof" (size=[10.4, 0.30, 6.4], mat="wall_marble", pos=[0, 5.00, 0], tags="floating")
  slab "cornice" (size=[10.2, 0.20, 6.2], mat="wall_stone", pos=[0, 4.65, 0], tags="floating")
  // 4 columns (front)
  group "col_1" (pos=[-4.0, 0.40, -3.0]) { use "bank_column" () }
  group "col_2" (pos=[-1.33, 0.40, -3.0]) { use "bank_column" () }
  group "col_3" (pos=[1.33, 0.40, -3.0]) { use "bank_column" () }
  group "col_4" (pos=[4.0, 0.40, -3.0]) { use "bank_column" () }
  // Pediment (triangular gable on top)
  prism "pediment" (size=[10.0, 1.20, 1.50], pos=[0, 4.80, -3.0], mat="wall_marble")
  // Front wall — door + 2 windows (between columns)
  wall "front_wall" (size=[10.0, 4.50, 0.20], pos=[0, 2.65, -3.0], holes=[[0,-0.50,2.50,3.20],[-3.0,0.5,1.50,1.50],[3.0,0.5,1.50,1.50]])
  // Back wall (small windows)
  wall "back_wall" (size=[10.0, 4.50, 0.20], pos=[0, 2.65, 3.0], holes=[[-3.0,0.5,1.50,1.50],[3.0,0.5,1.50,1.50]])
  // Side walls
  wall "left_wall" (size=[6.0, 4.50, 0.20], pos=[-5.0, 2.65, 0], rot=[0,90,0], holes=[[-2.0,0.5,1.50,1.50],[2.0,0.5,1.50,1.50]])
  wall "right_wall" (size=[6.0, 4.50, 0.20], pos=[5.0, 2.65, 0], rot=[0,90,0], holes=[[-2.0,0.5,1.50,1.50],[2.0,0.5,1.50,1.50]])
  // Main door (big double glass doors)
  box "door_frame" (size=[2.60, 3.30, 0.06], mat="column_marble", pos=[0, 1.20, -3.0], tags="floating")
  box "door_l" (size=[1.20, 3.10, 0.05], mat="door_glass", pos=[-0.65, 1.20, -3.04], tags="floating")
  box "door_r" (size=[1.20, 3.10, 0.05], mat="door_glass", pos=[0.65, 1.20, -3.04], tags="floating")
  box "handle_l" (size=[0.04, 0.20, 0.03], mat="brass", pos=[-0.20, 1.20, -3.06], tags="floating")
  box "handle_r" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.20, 1.20, -3.06], tags="floating")
  // Bank sign on pediment (blue with white text)
  box "sign_back" (size=[4.0, 0.80, 0.10], mat="sign_blue", pos=[0, 5.30, -3.0], tags="floating")
  box "sign_text_1" (size=[3.0, 0.15, 0.02], mat="sign_white_text", pos=[0, 5.45, -3.06], tags="floating")
  box "sign_text_2" (size=[2.0, 0.15, 0.02], mat="sign_white_text", pos=[0, 5.20, -3.06], tags="floating")
  // 2 ATMs (on side wall, exterior)
  group "atm_l" (pos=[-5.20, 0.40, -1.0]) { use "atm" () }
  group "atm_r" (pos=[5.20, 0.40, -1.0]) { use "atm" () }
  // Steps (front)
  slab "step_1" (size=[8.0, 0.20, 1.0], mat="wall_marble", pos=[0, 0.30, -4.0])
  slab "step_2" (size=[8.0, 0.20, 1.0], mat="wall_marble", pos=[0, 0.10, -5.0])
  // Bronze eagle / logo on top of pediment
  sphere "ornament" (radius=0.30, mat="brass", pos=[0, 6.20, -3.0], tags="floating")
  cylinder "ornament_pole" (radius=0.05, height=0.40, mat="brass", pos=[0, 5.90, -3.0], tags="floating")
}
''')

# ============================================================
# SUBURBAN FILLS (3)
# ============================================================

w("props", "bird_house", '''// bird_house.mog — small decorative birdhouse on a pole
meta (name="bird_house", description="Small decorative birdhouse on a pole — suburban garden accent", tags=["prop","suburban","garden","decorative","tier1"], mogen_version="0.1.12")
material "wood_light" (color=[0.65,0.50,0.30], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "wood_dark" (color=[0.30,0.20,0.12], roughness=0.85)
material "roof_red" (color=[0.55,0.20,0.15], roughness=0.80)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
scene {
  slab "ground" (size=[2.0, 0.04, 2.0], mat="grass", tags="floating")
  // Pole (going from ground up)
  cylinder "pole" (radius=0.04, height=1.50, mat="metal_dark", pos=[0, 0.75, 0])
  // Birdhouse body (small box)
  box "body" (size=[0.30, 0.30, 0.30], mat="wood_light", pos=[0, 1.65, 0])
  // Roof (small pyramid/cone)
  cone "roof" (radius=0.25, height=0.20, mat="roof_red", pos=[0, 1.95, 0], tags="floating")
  // Entrance hole (small dark circle on front)
  cylinder "hole" (radius=0.05, height=0.05, mat="wood_dark", pos=[0, 1.65, -0.16], rot=[90,0,0], tags="floating")
  // Perch (small stick below hole)
  cylinder "perch" (radius=0.01, height=0.10, mat="wood_dark", pos=[0, 1.55, -0.20], rot=[90,0,0], tags="floating")
  // Base bracket (where pole meets birdhouse)
  box "bracket" (size=[0.10, 0.05, 0.10], mat="wood_dark", pos=[0, 1.50, 0], tags="floating")
  // Decorative trim (small ring around base of roof)
  torus "trim_ring" (radius=0.20, tube_radius=0.02, mat="wood_dark", pos=[0, 1.82, 0], tags="floating")
}
''')

w("props", "garden_pergola", '''// garden_pergola.mog — small wooden garden pergola with lattice sides
meta (name="garden_pergola", description="Small wooden garden pergola — 4 posts with horizontal beam top and lattice sides", tags=["prop","suburban","garden","pergola","tier1"], mogen_version="0.1.12")
material "wood_white" (color=[0.88,0.86,0.80], roughness=0.85, uv_mode="tile", uv_scale=2.0)
material "wood_dark" (color=[0.35,0.25,0.15], roughness=0.85)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "leaf_green" (color=[0.30,0.50,0.18], roughness=0.85, transmission=0.20)
scene {
  slab "ground" (size=[6.0, 0.04, 4.0], mat="grass", tags="floating")
  // 4 vertical posts
  box "post_fl" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[-2.30, 1.40, -1.50])
  box "post_fr" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[2.30, 1.40, -1.50])
  box "post_bl" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[-2.30, 1.40, 1.50])
  box "post_br" (size=[0.15, 2.80, 0.15], mat="wood_white", pos=[2.30, 1.40, 1.50])
  // Horizontal beams (top — 2 along the length)
  box "beam_l" (size=[0.20, 0.20, 4.0], mat="wood_white", pos=[-2.30, 2.80, 0], rot=[90,0,0], tags="floating")
  box "beam_r" (size=[0.20, 0.20, 4.0], mat="wood_white", pos=[2.30, 2.80, 0], rot=[90,0,0], tags="floating")
  // Cross rafters (5, perpendicular)
  box "rafter_1" (size=[5.0, 0.15, 0.15], mat="wood_white", pos=[0, 2.95, -1.60], tags="floating")
  box "rafter_2" (size=[5.0, 0.15, 0.15], mat="wood_white", pos=[0, 2.95, -0.80], tags="floating")
  box "rafter_3" (size=[5.0, 0.15, 0.15], mat="wood_white", pos=[0, 2.95, 0], tags="floating")
  box "rafter_4" (size=[5.0, 0.15, 0.15], mat="wood_white", pos=[0, 2.95, 0.80], tags="floating")
  box "rafter_5" (size=[5.0, 0.15, 0.15], mat="wood_white", pos=[0, 2.95, 1.60], tags="floating")
  // Decorative end caps on beams (scalloped look)
  box "end_cap_fl" (size=[0.05, 0.20, 0.30], mat="wood_white", pos=[-2.30, 2.80, -2.20], tags="floating")
  box "end_cap_fr" (size=[0.05, 0.20, 0.30], mat="wood_white", pos=[2.30, 2.80, -2.20], tags="floating")
  box "end_cap_bl" (size=[0.05, 0.20, 0.30], mat="wood_white", pos=[-2.30, 2.80, 2.20], tags="floating")
  box "end_cap_br" (size=[0.05, 0.20, 0.30], mat="wood_white", pos=[2.30, 2.80, 2.20], tags="floating")
  // Lattice panels (sides — diagonal pattern simulated with thin strips)
  // Left side lattice (4 vertical + 4 horizontal strips)
  box "lat_l_v_1" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[-2.40, 1.10, -1.20], tags="floating")
  box "lat_l_v_2" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[-2.40, 1.10, -0.60], tags="floating")
  box "lat_l_v_3" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[-2.40, 1.10, 0], tags="floating")
  box "lat_l_v_4" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[-2.40, 1.10, 0.60], tags="floating")
  box "lat_l_v_5" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[-2.40, 1.10, 1.20], tags="floating")
  box "lat_l_h_1" (size=[0.04, 0.04, 2.60], mat="wood_white", pos=[-2.40, 0.50, 0], tags="floating")
  box "lat_l_h_2" (size=[0.04, 0.04, 2.60], mat="wood_white", pos=[-2.40, 1.10, 0], tags="floating")
  box "lat_l_h_3" (size=[0.04, 0.04, 2.60], mat="wood_white", pos=[-2.40, 1.70, 0], tags="floating")
  // Right side lattice
  box "lat_r_v_1" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[2.40, 1.10, -1.20], tags="floating")
  box "lat_r_v_2" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[2.40, 1.10, -0.60], tags="floating")
  box "lat_r_v_3" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[2.40, 1.10, 0], tags="floating")
  box "lat_r_v_4" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[2.40, 1.10, 0.60], tags="floating")
  box "lat_r_v_5" (size=[0.04, 1.80, 0.04], mat="wood_white", pos=[2.40, 1.10, 1.20], tags="floating")
  box "lat_r_h_1" (size=[0.04, 0.04, 2.60], mat="wood_white", pos=[2.40, 0.50, 0], tags="floating")
  box "lat_r_h_2" (size=[0.04, 0.04, 2.60], mat="wood_white", pos=[2.40, 1.10, 0], tags="floating")
  box "lat_r_h_3" (size=[0.04, 0.04, 2.60], mat="wood_white", pos=[2.40, 1.70, 0], tags="floating")
  // Climbing plant (vines on left lattice — small green spheres)
  sphere "vine_l_1" (radius=0.20, mat="leaf_green", pos=[-2.40, 0.60, -0.80], tags="floating")
  sphere "vine_l_2" (radius=0.25, mat="leaf_green", pos=[-2.40, 1.20, 0.20], tags="floating")
  sphere "vine_l_3" (radius=0.20, mat="leaf_green", pos=[-2.40, 1.70, 0.80], tags="floating")
  sphere "vine_r_1" (radius=0.20, mat="leaf_green", pos=[2.40, 0.60, 0.80], tags="floating")
  sphere "vine_r_2" (radius=0.25, mat="leaf_green", pos=[2.40, 1.20, -0.20], tags="floating")
  sphere "vine_r_3" (radius=0.20, mat="leaf_green", pos=[2.40, 1.70, -0.80], tags="floating")
  // Vines on top (over rafters)
  sphere "vine_top_1" (radius=0.30, mat="leaf_green", pos=[-1.0, 3.0, 0.50], tags="floating")
  sphere "vine_top_2" (radius=0.25, mat="leaf_green", pos=[0.50, 3.10, -0.50], tags="floating")
  sphere "vine_top_3" (radius=0.30, mat="leaf_green", pos=[1.50, 3.0, 0.80], tags="floating")
}
''')

w("buildings", "apartment_tower_high", '''// apartment_tower_high.mog — 8-story residential apartment tower
meta (name="apartment_tower_high", description="8-story residential apartment tower with balconies and repeating window pattern", tags=["building","downtown","residential","highrise","tier1"], mogen_version="0.1.12")
material "wall_tan" (color=[0.78,0.72,0.60], roughness=0.85, uv_mode="tile", uv_scale=8.0)
material "wall_white" (color=[0.88,0.86,0.80], roughness=0.85, uv_mode="tile", uv_scale=6.0)
material "roof_flat" (color=[0.20,0.20,0.22], roughness=0.90)
material "trim_white" (color=[0.95,0.95,0.93], roughness=0.60)
material "balcony_rail" (color=[0.30,0.30,0.35], roughness=0.40, metallic=0.85)
material "balcony_floor" (color=[0.40,0.35,0.30], roughness=0.85)
material "window_glass" (color=[0.30,0.40,0.50], transmission=0.40, roughness=0.05)
material "window_amber" (color=[0.65,0.55,0.30], transmission=0.20, roughness=0.10, emissive=[0.40,0.30,0.15], emissive_strength=0.5)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
module "apt_window" () {
  box "frame" (size=[1.20, 1.30, 0.06], mat="trim_white")
  box "glass" (size=[1.05, 1.15, 0.02], mat="window_glass", pos=[0,0,-0.04])
}
module "apt_window_lit" () {
  box "frame" (size=[1.20, 1.30, 0.06], mat="trim_white")
  box "glass" (size=[1.05, 1.15, 0.02], mat="window_amber", pos=[0,0,-0.04])
}
module "balcony" () {
  // Floor slab projecting from wall
  slab "floor" (size=[3.0, 0.10, 1.20], mat="balcony_floor", pos=[0, 0, 0.60])
  // Railings (3 sides — front + 2 sides)
  box "rail_front" (size=[3.0, 0.90, 0.05], mat="balcony_rail", pos=[0, 0.50, 1.20], tags="floating")
  box "rail_left" (size=[0.05, 0.90, 1.20], mat="balcony_rail", pos=[-1.50, 0.50, 0.60], tags="floating")
  box "rail_right" (size=[0.05, 0.90, 1.20], mat="balcony_rail", pos=[1.50, 0.50, 0.60], tags="floating")
  // Mid rail (lower)
  box "midrail_front" (size=[3.0, 0.05, 0.04], mat="balcony_rail", pos=[0, 0.25, 1.18], tags="floating")
  // Vertical balusters (4)
  box "bal_1" (size=[0.04, 0.80, 0.04], mat="balcony_rail", pos=[-1.20, 0.45, 1.20], tags="floating")
  box "bal_2" (size=[0.04, 0.80, 0.04], mat="balcony_rail", pos=[-0.40, 0.45, 1.20], tags="floating")
  box "bal_3" (size=[0.04, 0.80, 0.04], mat="balcony_rail", pos=[0.40, 0.45, 1.20], tags="floating")
  box "bal_4" (size=[0.04, 0.80, 0.04], mat="balcony_rail", pos=[1.20, 0.45, 1.20], tags="floating")
}
scene {
  slab "plaza" (size=[20.0, 0.05, 14.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")
  slab "foundation" (size=[12.0, 0.50, 8.0], mat="concrete", pos=[0, 0.25, 0])
  // Main body (8 stories ~ 24m)
  box "body" (size=[12.0, 24.0, 8.0], mat="wall_tan", pos=[0, 12.50, 0])
  // Horizontal floor bands (visible between windows)
  box "band_1" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 3.00, 0], tags="floating")
  box "band_2" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 6.00, 0], tags="floating")
  box "band_3" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 9.00, 0], tags="floating")
  box "band_4" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 12.00, 0], tags="floating")
  box "band_5" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 15.00, 0], tags="floating")
  box "band_6" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 18.00, 0], tags="floating")
  box "band_7" (size=[12.05, 0.10, 8.05], mat="wall_white", pos=[0, 21.00, 0], tags="floating")
  // Roof slab + parapet
  slab "roof" (size=[12.4, 0.30, 8.4], mat="roof_flat", pos=[0, 24.70, 0], tags="floating")
  box "parapet_n" (size=[12.4, 0.50, 0.20], mat="wall_tan", pos=[0, 25.10, -4.10], tags="floating")
  box "parapet_s" (size=[12.4, 0.50, 0.20], mat="wall_tan", pos=[0, 25.10, 4.10], tags="floating")
  box "parapet_e" (size=[0.20, 0.50, 8.4], mat="wall_tan", pos=[6.10, 25.10, 0], tags="floating")
  box "parapet_w" (size=[0.20, 0.50, 8.4], mat="wall_tan", pos=[-6.10, 25.10, 0], tags="floating")
  // Rooftop water tank
  cylinder "tank_body" (radius=1.20, height=2.0, mat="wall_white", pos=[-3.0, 26.20, 0], tags="floating")
  cone "tank_top" (radius=1.30, height=0.80, mat="roof_flat", pos=[-3.0, 27.60, 0], tags="floating")
  // Rooftop AC units
  box "ac_1" (size=[1.50, 1.0, 1.50], mat="metal_dark", pos=[3.0, 25.40, 0], tags="floating")
  box "ac_2" (size=[1.0, 0.80, 1.0], mat="metal_dark", pos=[0, 25.30, 2.0], tags="floating")
  // Front wall — balconies on alternate floors + windows on others
  // Use wall with many holes pattern: each floor has 4 windows
  wall "front_wall" (size=[12.0, 24.0, 0.20], pos=[0, 12.50, -4.0], holes=[
    [-4.5,1.0,3.0,1.30],[-1.5,1.0,3.0,1.30],[1.5,1.0,3.0,1.30],[4.5,1.0,3.0,1.30],
    [-4.5,4.0,3.0,1.30],[-1.5,4.0,3.0,1.30],[1.5,4.0,3.0,1.30],[4.5,4.0,3.0,1.30],
    [-4.5,7.0,3.0,1.30],[-1.5,7.0,3.0,1.30],[1.5,7.0,3.0,1.30],[4.5,7.0,3.0,1.30],
    [-4.5,10.0,3.0,1.30],[-1.5,10.0,3.0,1.30],[1.5,10.0,3.0,1.30],[4.5,10.0,3.0,1.30],
    [-4.5,13.0,3.0,1.30],[-1.5,13.0,3.0,1.30],[1.5,13.0,3.0,1.30],[4.5,13.0,3.0,1.30],
    [-4.5,16.0,3.0,1.30],[-1.5,16.0,3.0,1.30],[1.5,16.0,3.0,1.30],[4.5,16.0,3.0,1.30],
    [-4.5,19.0,3.0,1.30],[-1.5,19.0,3.0,1.30],[1.5,19.0,3.0,1.30],[4.5,19.0,3.0,1.30],
    [-4.5,22.0,3.0,1.30],[-1.5,22.0,3.0,1.30],[1.5,22.0,3.0,1.30],[4.5,22.0,3.0,1.30],
  ])
  // Back wall (similar pattern, no balconies)
  wall "back_wall" (size=[12.0, 24.0, 0.20], pos=[0, 12.50, 4.0], holes=[
    [-4.5,1.0,1.20,1.30],[-1.5,1.0,1.20,1.30],[1.5,1.0,1.20,1.30],[4.5,1.0,1.20,1.30],
    [-4.5,4.0,1.20,1.30],[-1.5,4.0,1.20,1.30],[1.5,4.0,1.20,1.30],[4.5,4.0,1.20,1.30],
    [-4.5,7.0,1.20,1.30],[-1.5,7.0,1.20,1.30],[1.5,7.0,1.20,1.30],[4.5,7.0,1.20,1.30],
    [-4.5,10.0,1.20,1.30],[-1.5,10.0,1.20,1.30],[1.5,10.0,1.20,1.30],[4.5,10.0,1.20,1.30],
    [-4.5,13.0,1.20,1.30],[-1.5,13.0,1.20,1.30],[1.5,13.0,1.20,1.30],[4.5,13.0,1.20,1.30],
    [-4.5,16.0,1.20,1.30],[-1.5,16.0,1.20,1.30],[1.5,16.0,1.20,1.30],[4.5,16.0,1.20,1.30],
    [-4.5,19.0,1.20,1.30],[-1.5,19.0,1.20,1.30],[1.5,19.0,1.20,1.30],[4.5,19.0,1.20,1.30],
    [-4.5,22.0,1.20,1.30],[-1.5,22.0,1.20,1.30],[1.5,22.0,1.20,1.30],[4.5,22.0,1.20,1.30],
  ])
  // Side walls
  wall "left_wall" (size=[8.0, 24.0, 0.20], pos=[-6.0, 12.50, 0], rot=[0,90,0], holes=[[-2.0,1.0,1.20,1.30],[2.0,1.0,1.20,1.30],[-2.0,4.0,1.20,1.30],[2.0,4.0,1.20,1.30],[-2.0,7.0,1.20,1.30],[2.0,7.0,1.20,1.30],[-2.0,10.0,1.20,1.30],[2.0,10.0,1.20,1.30],[-2.0,13.0,1.20,1.30],[2.0,13.0,1.20,1.30],[-2.0,16.0,1.20,1.30],[2.0,16.0,1.20,1.30],[-2.0,19.0,1.20,1.30],[2.0,19.0,1.20,1.30],[-2.0,22.0,1.20,1.30],[2.0,22.0,1.20,1.30]])
  wall "right_wall" (size=[8.0, 24.0, 0.20], pos=[6.0, 12.50, 0], rot=[0,90,0], holes=[[-2.0,1.0,1.20,1.30],[2.0,1.0,1.20,1.30],[-2.0,4.0,1.20,1.30],[2.0,4.0,1.20,1.30],[-2.0,7.0,1.20,1.30],[2.0,7.0,1.20,1.30],[-2.0,10.0,1.20,1.30],[2.0,10.0,1.20,1.30],[-2.0,13.0,1.20,1.30],[2.0,13.0,1.20,1.30],[-2.0,16.0,1.20,1.30],[2.0,16.0,1.20,1.30],[-2.0,19.0,1.20,1.30],[2.0,19.0,1.20,1.30],[-2.0,22.0,1.20,1.30],[2.0,22.0,1.20,1.30]])
  // Balconies on front (every other floor: floors 1, 3, 5, 7)
  group "bal_f1_1" (pos=[-4.5, 3.10, -4.0]) { use "balcony" () }
  group "bal_f1_2" (pos=[-1.5, 3.10, -4.0]) { use "balcony" () }
  group "bal_f1_3" (pos=[1.5, 3.10, -4.0]) { use "balcony" () }
  group "bal_f1_4" (pos=[4.5, 3.10, -4.0]) { use "balcony" () }
  group "bal_f3_1" (pos=[-4.5, 9.10, -4.0]) { use "balcony" () }
  group "bal_f3_2" (pos=[-1.5, 9.10, -4.0]) { use "balcony" () }
  group "bal_f3_3" (pos=[1.5, 9.10, -4.0]) { use "balcony" () }
  group "bal_f3_4" (pos=[4.5, 9.10, -4.0]) { use "balcony" () }
  group "bal_f5_1" (pos=[-4.5, 15.10, -4.0]) { use "balcony" () }
  group "bal_f5_2" (pos=[-1.5, 15.10, -4.0]) { use "balcony" () }
  group "bal_f5_3" (pos=[1.5, 15.10, -4.0]) { use "balcony" () }
  group "bal_f5_4" (pos=[4.5, 15.10, -4.0]) { use "balcony" () }
  group "bal_f7_1" (pos=[-4.5, 21.10, -4.0]) { use "balcony" () }
  group "bal_f7_2" (pos=[-1.5, 21.10, -4.0]) { use "balcony" () }
  group "bal_f7_3" (pos=[1.5, 21.10, -4.0]) { use "balcony" () }
  group "bal_f7_4" (pos=[4.5, 21.10, -4.0]) { use "balcony" () }
  // Ground floor entrance (lobby door)
  box "lobby_door" (size=[3.0, 2.50, 0.10], mat="balcony_rail", pos=[0, 1.30, -4.05], tags="floating")
  // Ground floor windows on either side of lobby
  box "lobby_win_l" (size=[1.50, 1.50, 0.05], mat="window_glass", pos=[-4.50, 1.50, -4.04], tags="floating")
  box "lobby_win_r" (size=[1.50, 1.50, 0.05], mat="window_glass", pos=[4.50, 1.50, -4.04], tags="floating")
  // Address plate near door
  box "address_plate" (size=[0.60, 0.30, 0.05], mat="trim_white", pos=[2.50, 1.50, -4.04], tags="floating")
}
''')

# ============================================================
# MISC (2)
# ============================================================

w("buildings", "train_boxcar_derelict", '''// train_boxcar_derelict.mog — abandoned train boxcar with rust and graffiti hint
meta (name="train_boxcar_derelict", description="Abandoned train boxcar — rusted metal walls, broken door, derailed", tags=["building","industrial","train","derelict","vehicle","tier1"], mogen_version="0.1.12")
material "metal_rust" (color=[0.55,0.30,0.18], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "metal_red" (color=[0.50,0.20,0.15], roughness=0.70, metallic=0.4, uv_mode="tile", uv_scale=4.0)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "roof_metal" (color=[0.40,0.30,0.22], roughness=0.60, metallic=0.5)
material "wheel_dark" (color=[0.15,0.15,0.18], roughness=0.50, metallic=0.85)
material "gravel_grey" (color=[0.45,0.42,0.40], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "wood_dark" (color=[0.30,0.22,0.12], roughness=0.85)
scene {
  // Gravel bed (tracks area)
  slab "gravel" (size=[20.0, 0.10, 4.0], mat="gravel_grey", pos=[0, 0.05, 0], tags="floating")
  // Rails (2 parallel)
  box "rail_l" (size=[20.0, 0.15, 0.10], mat="metal_dark", pos=[0, 0.13, -0.75], tags="floating")
  box "rail_r" (size=[20.0, 0.15, 0.10], mat="metal_dark", pos=[0, 0.13, 0.75], tags="floating")
  // Ties (wooden, every 1.5m)
  box "tie_1" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[-8.0, 0.10, 0], tags="floating")
  box "tie_2" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[-6.0, 0.10, 0], tags="floating")
  box "tie_3" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[-4.0, 0.10, 0], tags="floating")
  box "tie_4" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[-2.0, 0.10, 0], tags="floating")
  box "tie_5" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[0, 0.10, 0], tags="floating")
  box "tie_6" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[2.0, 0.10, 0], tags="floating")
  box "tie_7" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[4.0, 0.10, 0], tags="floating")
  box "tie_8" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[6.0, 0.10, 0], tags="floating")
  box "tie_9" (size=[0.20, 0.10, 2.0], mat="wood_dark", pos=[8.0, 0.10, 0], tags="floating")
  // Boxcar body (12m long, 3m wide, 3.5m tall)
  box "body" (size=[12.0, 3.20, 2.80], mat="metal_red", pos=[0, 2.40, 0])
  // Rust patches (overlay)
  box "rust_1" (size=[2.0, 1.50, 0.02], mat="metal_rust", pos=[-3.0, 2.50, -1.41], tags="floating")
  box "rust_2" (size=[1.50, 2.0, 0.02], mat="metal_rust", pos=[2.0, 2.40, -1.41], tags="floating")
  box "rust_3" (size=[1.0, 1.0, 0.02], mat="metal_rust", pos=[4.0, 3.0, -1.41], tags="floating")
  box "rust_4" (size=[2.0, 1.50, 0.02], mat="metal_rust", pos=[-3.0, 2.50, 1.41], tags="floating")
  box "rust_5" (size=[1.50, 2.0, 0.02], mat="metal_rust", pos=[2.0, 2.40, 1.41], tags="floating")
  // Roof (curved corrugated — flat slab for simplicity)
  slab "roof" (size=[12.2, 0.20, 3.0], mat="roof_metal", pos=[0, 4.10, 0], tags="floating")
  // Roof ribs (corrugation lines)
  box "rib_1" (size=[12.2, 0.04, 0.04], mat="metal_dark", pos=[0, 4.22, -1.0], tags="floating")
  box "rib_2" (size=[12.2, 0.04, 0.04], mat="metal_dark", pos=[0, 4.22, 0], tags="floating")
  box "rib_3" (size=[12.2, 0.04, 0.04], mat="metal_dark", pos=[0, 4.22, 1.0], tags="floating")
  // Sliding door (left side, half-open — visible as gap)
  box "door_l_track" (size=[12.0, 0.05, 0.05], mat="metal_dark", pos=[0, 1.10, -1.41], tags="floating")
  box "door_l_top" (size=[12.0, 0.05, 0.05], mat="metal_dark", pos=[0, 3.70, -1.41], tags="floating")
  // Open door (slid to the right, exposing interior)
  box "door_l_open" (size=[4.0, 2.40, 0.10], mat="metal_red", pos=[3.0, 2.30, -1.45], tags="floating")
  // Door handle (stuck out)
  box "door_handle" (size=[0.40, 0.05, 0.10], mat="metal_dark", pos=[1.50, 2.30, -1.50], tags="floating")
  // Interior floor (visible through open door)
  slab "int_floor" (size=[11.5, 0.05, 2.5], mat="wood_dark", pos=[0, 0.85, 0], tags="floating")
  // Some cargo debris inside (visible through opening)
  box "debris_1" (size=[1.0, 0.80, 1.0], mat="wood_dark", pos=[-3.0, 1.30, 0], tags="floating")
  box "debris_2" (size=[0.80, 0.60, 0.80], mat="metal_dark", pos=[-2.0, 1.20, -0.50], tags="floating")
  box "debris_3" (size=[1.20, 1.0, 1.20], mat="wood_dark", pos=[0.50, 1.40, 0.50], tags="floating")
  // Bogies (2 — wheel trucks at each end)
  box "bogie_l" (size=[2.0, 0.60, 2.0], mat="metal_dark", pos=[-4.50, 0.50, 0], tags="floating")
  box "bogie_r" (size=[2.0, 0.60, 2.0], mat="metal_dark", pos=[4.50, 0.50, 0], tags="floating")
  // Wheels (4 per bogie, 8 total)
  cylinder "wheel_fl_l" (radius=0.40, height=0.10, mat="wheel_dark", pos=[-5.0, 0.40, -0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_fr_l" (radius=0.40, height=0.10, mat="wheel_dark", pos=[-5.0, 0.40, 0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_bl_l" (radius=0.40, height=0.10, mat="wheel_dark", pos=[-4.0, 0.40, -0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_br_l" (radius=0.40, height=0.10, mat="wheel_dark", pos=[-4.0, 0.40, 0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_fl_r" (radius=0.40, height=0.10, mat="wheel_dark", pos=[4.0, 0.40, -0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_fr_r" (radius=0.40, height=0.10, mat="wheel_dark", pos=[4.0, 0.40, 0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_bl_r" (radius=0.40, height=0.10, mat="wheel_dark", pos=[5.0, 0.40, -0.75], rot=[90,0,0], tags="floating")
  cylinder "wheel_br_r" (radius=0.40, height=0.10, mat="wheel_dark", pos=[5.0, 0.40, 0.75], rot=[90,0,0], tags="floating")
  // Couplers (front + back)
  box "coupler_f" (size=[0.30, 0.20, 0.20], mat="metal_dark", pos=[-6.20, 0.80, 0], tags="floating")
  box "coupler_b" (size=[0.30, 0.20, 0.20], mat="metal_dark", pos=[6.20, 0.80, 0], tags="floating")
  // Car number stencil (hint — small dark rectangle on side)
  box "stencil_1" (size=[1.50, 0.40, 0.02], mat="metal_dark", pos=[-2.0, 3.20, -1.41], tags="floating")
  // Graffiti hint (small colored patches)
  box "graf_1" (size=[1.0, 0.60, 0.02], mat="metal_rust", pos=[1.50, 2.0, -1.41], tags="floating")
}
''')

print("\n=== Part E: 14 assets written (3 coastal + 3 subway + 2 military + 3 commercial + 3 suburban/misc) ===")
