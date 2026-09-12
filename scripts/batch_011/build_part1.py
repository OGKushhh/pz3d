#!/usr/bin/env python3
"""Batch 011 — Part 1 of 4 — Downtown hero buildings (6) + Farmland landmarks (4)."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# ============================================================
# 1. hospital.mog — Downtown civic landmark, 3-story white building
# ============================================================
w("buildings", "hospital", '''// hospital.mog — Downtown civic landmark hospital
meta (name="hospital", description="3-story hospital with ambulance bay and red cross sign", tags=["building","civic","downtown","landmark","tier1"], mogen_version="0.1.12")
material "wall_white" (color=[0.92,0.92,0.90], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wall_grey" (color=[0.70,0.70,0.68], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "roof_flat" (color=[0.30,0.30,0.32], roughness=0.90)
material "trim_white" (color=[0.95,0.95,0.93], roughness=0.60)
material "window_blue" (color=[0.40,0.60,0.75], transmission=0.45, roughness=0.05)
material "glass_emissive" (color=[0.55,0.75,0.85], transmission=0.50, roughness=0.05, emissive=[0.30,0.45,0.55], emissive_strength=0.6)
material "red_cross" (color=[0.85,0.10,0.10], roughness=0.40, emissive=[0.6,0.05,0.05], emissive_strength=0.4)
material "concrete" (color=[0.60,0.58,0.55], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "door_glass" (color=[0.35,0.55,0.70], transmission=0.55, roughness=0.04)
module "h_win" () {
  box "frame" (size=[1.30, 1.50, 0.06], mat="trim_white")
  box "glass" (size=[1.15, 1.35, 0.02], mat="window_blue", pos=[0,0,-0.04])
}
module "amb_door" () {
  box "frame" (size=[3.00, 2.40, 0.06], mat="trim_white")
  box "glass" (size=[2.85, 2.25, 0.02], mat="door_glass", pos=[0,0,-0.04])
}
scene {
  slab "parking" (size=[20.0, 0.05, 16.0], mat="asphalt", pos=[0, 0.025, 0])
  slab "foundation" (size=[16.0, 0.30, 12.0], mat="concrete", pos=[0, 0.15, 0])
  // Main building body (3 floors visible as bands)
  box "body" (size=[15.0, 9.0, 11.0], mat="wall_white", pos=[0, 4.80, 0])
  // Ground floor accent band
  box "ground_band" (size=[15.2, 3.0, 11.2], mat="wall_grey", pos=[0, 1.65, 0])
  // Roof slab
  slab "roof" (size=[15.5, 0.20, 11.5], mat="roof_flat", pos=[0, 9.40, 0])
  // Front wall holes for ambulance bay + windows
  wall "front_g" (size=[15.0, 3.0, 0.20], pos=[0, 1.50, -5.5], holes=[[-5.0,0.0,3.00,2.40],[-2.0,0.30,1.30,1.50],[0,0.30,1.30,1.50],[2.0,0.30,1.30,1.50],[5.0,0.30,1.30,1.50]])
  wall "front_u" (size=[15.0, 6.0, 0.20], pos=[0, 6.00, -5.5], holes=[[-5.0,1.50,1.30,1.50],[-2.0,1.50,1.30,1.50],[0,1.50,1.30,1.50],[2.0,1.50,1.30,1.50],[5.0,1.50,1.30,1.50],[-5.0,-0.80,1.30,1.50],[-2.0,-0.80,1.30,1.50],[0,-0.80,1.30,1.50],[2.0,-0.80,1.30,1.50],[5.0,-0.80,1.30,1.50]])
  wall "back_wall" (size=[15.0, 9.0, 0.20], pos=[0, 4.80, 5.5], holes=[[-5.0,1.0,1.30,1.50],[-2.0,1.0,1.30,1.50],[0,1.0,1.30,1.50],[2.0,1.0,1.30,1.50],[5.0,1.0,1.30,1.50],[-5.0,-2.0,1.30,1.50],[-2.0,-2.0,1.30,1.50],[0,-2.0,1.30,1.50],[2.0,-2.0,1.30,1.50],[5.0,-2.0,1.30,1.50]])
  wall "left_wall" (size=[11.0, 9.0, 0.20], pos=[-7.5, 4.80, 0], rot=[0,90,0], holes=[[-3.0,1.0,1.30,1.50],[0,1.0,1.30,1.50],[3.0,1.0,1.30,1.50],[-3.0,-2.0,1.30,1.50],[0,-2.0,1.30,1.50],[3.0,-2.0,1.30,1.50]])
  wall "right_wall" (size=[11.0, 9.0, 0.20], pos=[7.5, 4.80, 0], rot=[0,90,0], holes=[[-3.0,1.0,1.30,1.50],[0,1.0,1.30,1.50],[3.0,1.0,1.30,1.50],[-3.0,-2.0,1.30,1.50],[0,-2.0,1.30,1.50],[3.0,-2.0,1.30,1.50]])
  // Red cross sign on front (emissive)
  box "cross_v" (size=[0.40, 2.00, 0.10], mat="red_cross", pos=[0, 11.00, -5.55], tags="floating")
  box "cross_h" (size=[2.00, 0.40, 0.10], mat="red_cross", pos=[0, 11.00, -5.55], tags="floating")
  // Rooftop helipad marker
  box "h_mark" (size=[3.0, 0.05, 3.0], mat="red_cross", pos=[0, 9.55, 0], tags="floating")
  // Group placements (windows / doors)
  group "amb_g" (pos=[-5.0, 1.20, -5.5]) { use "amb_door" () }
  group "wfg_1" (pos=[-2.0, 1.95, -5.5]) { use "h_win" () }
  group "wfg_2" (pos=[0, 1.95, -5.5]) { use "h_win" () }
  group "wfg_3" (pos=[2.0, 1.95, -5.5]) { use "h_win" () }
  group "wfg_4" (pos=[5.0, 1.95, -5.5]) { use "h_win" () }
  group "wfu_1" (pos=[-5.0, 7.50, -5.5]) { use "h_win" () }
  group "wfu_2" (pos=[-2.0, 7.50, -5.5]) { use "h_win" () }
  group "wfu_3" (pos=[0, 7.50, -5.5]) { use "h_win" () }
  group "wfu_4" (pos=[2.0, 7.50, -5.5]) { use "h_win" () }
  group "wfu_5" (pos=[5.0, 7.50, -5.5]) { use "h_win" () }
}
''')

# ============================================================
# 2. police_station.mog — 2-story brick with blue awning
# ============================================================
w("buildings", "police_station", '''// police_station.mog — Downtown civic landmark police station
meta (name="police_station", description="2-story brick police station with blue awning", tags=["building","civic","downtown","landmark","tier1"], mogen_version="0.1.12")
material "wall_brick" (color=[0.55,0.30,0.25], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wall_stone" (color=[0.65,0.62,0.58], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_flat" (color=[0.25,0.25,0.28], roughness=0.90)
material "trim_white" (color=[0.92,0.91,0.86], roughness=0.60)
material "awning_blue" (color=[0.10,0.20,0.55], roughness=0.70, emissive=[0.05,0.10,0.30], emissive_strength=0.2)
material "window_blue" (color=[0.40,0.60,0.75], transmission=0.45, roughness=0.05)
material "door_glass" (color=[0.30,0.50,0.65], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "ps_win" () {
  box "frame" (size=[1.10, 1.40, 0.06], mat="trim_white")
  box "glass" (size=[0.95, 1.25, 0.02], mat="window_blue", pos=[0,0,-0.04])
}
module "ps_door" () {
  box "frame" (size=[1.50, 2.30, 0.06], mat="trim_white")
  box "glass" (size=[1.35, 2.15, 0.02], mat="door_glass", pos=[0,0,-0.04])
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.55,0,0.06], tags="floating")
}
scene {
  slab "lawn" (size=[18.0, 0.04, 14.0], mat="grass")
  slab "parking" (size=[6.0, 0.05, 5.0], mat="asphalt", pos=[5.0, 0.025, 4.0])
  slab "foundation" (size=[14.0, 0.30, 10.0], mat="concrete", pos=[0, 0.15, 0])
  // Stone ground floor
  box "ground" (size=[14.0, 2.50, 10.0], mat="wall_stone", pos=[0, 1.45, 0])
  // Brick upper floor
  box "upper" (size=[14.0, 2.80, 10.0], mat="wall_brick", pos=[0, 4.10, 0])
  slab "roof" (size=[14.4, 0.20, 10.4], mat="roof_flat", pos=[0, 5.60, 0])
  // Awning over entrance
  prism "awning" (size=[5.0, 0.40, 3.0], pos=[0, 2.70, -5.0], mat="awning_blue")
  // Holes
  wall "front_g" (size=[14.0, 2.50, 0.20], pos=[0, 1.45, -5.0], holes=[[-4.0,-0.10,1.50,2.30],[-1.5,0.30,1.10,1.40],[1.5,0.30,1.10,1.40],[4.0,0.30,1.10,1.40]])
  wall "front_u" (size=[14.0, 2.80, 0.20], pos=[0, 4.10, -5.0], holes=[[-4.0,0.0,1.10,1.40],[-1.5,0.0,1.10,1.40],[1.5,0.0,1.10,1.40],[4.0,0.0,1.10,1.40]])
  wall "back_wall" (size=[14.0, 5.30, 0.20], pos=[0, 2.95, 5.0], holes=[[-4.0,0.50,1.10,1.40],[-1.5,0.50,1.10,1.40],[1.5,0.50,1.10,1.40],[4.0,0.50,1.10,1.40],[-2.0,-1.5,1.10,1.40],[2.0,-1.5,1.10,1.40]])
  wall "left_wall" (size=[10.0, 5.30, 0.20], pos=[-7.0, 2.95, 0], rot=[0,90,0], holes=[[-2.0,0.50,1.10,1.40],[2.0,0.50,1.10,1.40]])
  wall "right_wall" (size=[10.0, 5.30, 0.20], pos=[7.0, 2.95, 0], rot=[0,90,0], holes=[[-2.0,0.50,1.10,1.40],[2.0,0.50,1.10,1.40]])
  // Flagpole
  cylinder "pole" (radius=0.05, height=4.0, mat="trim_white", pos=[3.0, 7.60, -5.0], tags="floating")
  box "flag" (size=[0.8, 0.5, 0.02], mat="awning_blue", pos=[3.4, 9.0, -5.0], tags="floating")
  // Group placements
  group "door_g" (pos=[-4.0, 1.15, -5.0]) { use "ps_door" () }
  group "wfg_1" (pos=[-1.5, 1.85, -5.0]) { use "ps_win" () }
  group "wfg_2" (pos=[1.5, 1.85, -5.0]) { use "ps_win" () }
  group "wfg_3" (pos=[4.0, 1.85, -5.0]) { use "ps_win" () }
  group "wfu_1" (pos=[-4.0, 4.10, -5.0]) { use "ps_win" () }
  group "wfu_2" (pos=[-1.5, 4.10, -5.0]) { use "ps_win" () }
  group "wfu_3" (pos=[1.5, 4.10, -5.0]) { use "ps_win" () }
  group "wfu_4" (pos=[4.0, 4.10, -5.0]) { use "ps_win" () }
}
''')

# ============================================================
# 3. highrise_office.mog — 12-story glass tower
# ============================================================
w("buildings", "highrise_office", '''// highrise_office.mog — 12-story glass curtain wall office tower
meta (name="highrise_office", description="12-story glass curtain wall office tower", tags=["building","downtown","highrise","landmark","tier1"], mogen_version="0.1.12")
material "glass_blue" (color=[0.30,0.50,0.65], transmission=0.35, roughness=0.04, uv_mode="tile", uv_scale=8.0)
material "glass_dark" (color=[0.20,0.30,0.40], transmission=0.30, roughness=0.05, emissive=[0.15,0.25,0.30], emissive_strength=0.4)
material "frame_metal" (color=[0.30,0.30,0.35], roughness=0.40, metallic=0.85)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "roof_tar" (color=[0.12,0.10,0.08], roughness=0.95)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
scene {
  slab "plaza" (size=[22.0, 0.05, 22.0], mat="asphalt", pos=[0, 0.025, 0])
  slab "foundation" (size=[10.0, 0.50, 10.0], mat="concrete", pos=[0, 0.25, 0])
  // Glass tower body (12 stories ~ 36m)
  box "tower" (size=[10.0, 36.0, 10.0], mat="glass_blue", pos=[0, 18.50, 0])
  // Vertical mullions
  box "mull_v_1" (size=[0.15, 36.0, 10.05], mat="frame_metal", pos=[-2.5, 18.50, 0], tags="floating")
  box "mull_v_2" (size=[0.15, 36.0, 10.05], mat="frame_metal", pos=[0, 18.50, 0], tags="floating")
  box "mull_v_3" (size=[0.15, 36.0, 10.05], mat="frame_metal", pos=[2.5, 18.50, 0], tags="floating")
  box "mull_h_1" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 6.0, 0], tags="floating")
  box "mull_h_2" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 9.0, 0], tags="floating")
  box "mull_h_3" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 12.0, 0], tags="floating")
  box "mull_h_4" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 15.0, 0], tags="floating")
  box "mull_h_5" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 18.0, 0], tags="floating")
  box "mull_h_6" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 21.0, 0], tags="floating")
  box "mull_h_7" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 24.0, 0], tags="floating")
  box "mull_h_8" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 27.0, 0], tags="floating")
  box "mull_h_9" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 30.0, 0], tags="floating")
  box "mull_h_10" (size=[10.05, 0.15, 10.05], mat="frame_metal", pos=[0, 33.0, 0], tags="floating")
  // Side mullions (Z axis)
  box "mull_z_v_1" (size=[10.05, 36.0, 0.15], mat="frame_metal", pos=[0, 18.50, -2.5], tags="floating")
  box "mull_z_v_2" (size=[10.05, 36.0, 0.15], mat="frame_metal", pos=[0, 18.50, 0], tags="floating")
  box "mull_z_v_3" (size=[10.05, 36.0, 0.15], mat="frame_metal", pos=[0, 18.50, 2.5], tags="floating")
  // Darker top floor (mechanical)
  box "top_floor" (size=[10.0, 3.0, 10.0], mat="glass_dark", pos=[0, 38.0, 0])
  // Roof slab
  slab "roof" (size=[10.5, 0.20, 10.5], mat="roof_tar", pos=[0, 39.70, 0])
  // Rooftop AC unit
  box "ac_unit" (size=[2.0, 1.0, 2.0], mat="frame_metal", pos=[2.0, 40.30, 2.0], tags="floating")
  // Glass entrance lobby (ground floor protrusion)
  box "lobby" (size=[6.0, 4.0, 2.0], mat="glass_dark", pos=[0, 2.00, -5.0], tags="floating")
}
''')

# ============================================================
# 4. parking_garage.mog — 4-story concrete with open sides
# ============================================================
w("buildings", "parking_garage", '''// parking_garage.mog — 4-story concrete parking structure with ramps
meta (name="parking_garage", description="4-story concrete parking garage with open sides and ramps", tags=["building","downtown","parking","tier1"], mogen_version="0.1.12")
material "concrete" (color=[0.65,0.63,0.60], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "concrete_dark" (color=[0.45,0.43,0.40], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "line_yellow" (color=[0.85,0.70,0.20], roughness=0.50, emissive=[0.40,0.30,0.10], emissive_strength=0.2)
material "metal_rail" (color=[0.30,0.30,0.35], roughness=0.40, metallic=0.85)
scene {
  slab "ground" (size=[24.0, 0.05, 20.0], mat="asphalt", pos=[0, 0.025, 0])
  // 4 floor slabs at 0, 3.5, 7.0, 10.5
  slab "floor_1" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 3.50, 0])
  slab "floor_2" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 7.00, 0])
  slab "floor_3" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 10.50, 0])
  slab "floor_4" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 14.00, 0])
  slab "roof" (size=[20.4, 0.20, 16.4], mat="concrete_dark", pos=[0, 17.65, 0])
  // Core columns at corners + middles
  box "col_tl" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[-9.50, 8.75, -7.50], tags="floating")
  box "col_tr" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[9.50, 8.75, -7.50], tags="floating")
  box "col_bl" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[-9.50, 8.75, 7.50], tags="floating")
  box "col_br" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[9.50, 8.75, 7.50], tags="floating")
  box "col_ml_1" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[0, 8.75, -7.50], tags="floating")
  box "col_ml_2" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[0, 8.75, 7.50], tags="floating")
  // Back wall (solid)
  wall "back_wall" (size=[20.0, 14.0, 0.20], pos=[0, 7.00, 8.0])
  // Side walls with openings (open parking)
  wall "left_wall" (size=[16.0, 14.0, 0.20], pos=[-10.0, 7.00, 0], rot=[0,90,0], holes=[[0,-3.0,4.0,3.0],[0,0.5,4.0,3.0],[0,4.0,4.0,3.0],[0,7.5,4.0,3.0]])
  wall "right_wall" (size=[16.0, 14.0, 0.20], pos=[10.0, 7.00, 0], rot=[0,90,0], holes=[[0,-3.0,4.0,3.0],[0,0.5,4.0,3.0],[0,4.0,4.0,3.0],[0,7.5,4.0,3.0]])
  // Front wall with entry
  wall "front_wall" (size=[20.0, 14.0, 0.20], pos=[0, 7.00, -8.0], holes=[[-6.0,-3.5,4.0,3.5],[6.0,-3.5,4.0,3.5]])
  // Ramps between floors (visible on side)
  slab "ramp_1" (size=[3.0, 0.20, 7.0], mat="concrete_dark", pos=[8.0, 1.75, -4.0], rot=[8,0,0], tags="floating")
  slab "ramp_2" (size=[3.0, 0.20, 7.0], mat="concrete_dark", pos=[8.0, 5.25, -4.0], rot=[8,0,0], tags="floating")
  slab "ramp_3" (size=[3.0, 0.20, 7.0], mat="concrete_dark", pos=[8.0, 8.75, -4.0], rot=[8,0,0], tags="floating")
  // Yellow parking lines on ground
  slab "line_1" (size=[0.15, 0.04, 4.0], mat="line_yellow", pos=[-5.0, 0.055, 0], tags="floating")
  slab "line_2" (size=[0.15, 0.04, 4.0], mat="line_yellow", pos=[-2.0, 0.055, 0], tags="floating")
  slab "line_3" (size=[0.15, 0.04, 4.0], mat="line_yellow", pos=[1.0, 0.055, 0], tags="floating")
  slab "line_4" (size=[0.15, 0.04, 4.0], mat="line_yellow", pos=[4.0, 0.055, 0], tags="floating")
  // Top floor railing
  box "rail_top" (size=[20.0, 0.10, 0.05], mat="metal_rail", pos=[0, 14.20, -8.05], tags="floating")
  box "rail_side_l" (size=[0.05, 0.10, 16.0], mat="metal_rail", pos=[-10.05, 14.20, 0], tags="floating")
  box "rail_side_r" (size=[0.05, 0.10, 16.0], mat="metal_rail", pos=[10.05, 14.20, 0], tags="floating")
}
''')

# ============================================================
# 5. broadcast_tower.mog — lattice tower with antenna
# ============================================================
w("buildings", "broadcast_tower", '''// broadcast_tower.mog — tall lattice broadcast tower with red aviation lights
meta (name="broadcast_tower", description="Lattice broadcast tower with antenna mast and aviation lights", tags=["building","downtown","landmark","tower","tier1"], mogen_version="0.1.12")
material "steel_red" (color=[0.70,0.20,0.15], roughness=0.50, metallic=0.85)
material "steel_grey" (color=[0.40,0.40,0.42], roughness=0.50, metallic=0.85)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "aviation_red" (color=[0.95,0.10,0.10], roughness=0.40, emissive=[0.7,0.05,0.05], emissive_strength=0.8)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
scene {
  slab "base_pad" (size=[10.0, 0.05, 10.0], mat="asphalt", pos=[0, 0.025, 0])
  slab "foundation" (size=[4.0, 0.30, 4.0], mat="concrete", pos=[0, 0.15, 0])
  // Four legs splayed outward (tapered tower profile)
  // Bottom section (0-10m, wide base)
  box "leg_fl_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[-1.80, 5.0, -1.80], rot=[0,0,11], tags="floating")
  box "leg_fr_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[1.80, 5.0, -1.80], rot=[0,0,-11], tags="floating")
  box "leg_bl_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[-1.80, 5.0, 1.80], rot=[0,0,11], tags="floating")
  box "leg_br_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[1.80, 5.0, 1.80], rot=[0,0,-11], tags="floating")
  // Mid section (10-25m, narrower)
  box "leg_fl_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[-1.00, 17.5, -1.00], rot=[0,0,5], tags="floating")
  box "leg_fr_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[1.00, 17.5, -1.00], rot=[0,0,-5], tags="floating")
  box "leg_bl_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[-1.00, 17.5, 1.00], rot=[0,0,5], tags="floating")
  box "leg_br_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[1.00, 17.5, 1.00], rot=[0,0,-5], tags="floating")
  // Top section (25-40m, very narrow)
  box "leg_fl_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[-0.50, 32.5, -0.50], rot=[0,0,2], tags="floating")
  box "leg_fr_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[0.50, 32.5, -0.50], rot=[0,0,-2], tags="floating")
  box "leg_bl_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[-0.50, 32.5, 0.50], rot=[0,0,2], tags="floating")
  box "leg_br_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[0.50, 32.5, 0.50], rot=[0,0,-2], tags="floating")
  // Cross braces (horizontal at intervals)
  box "brace_5" (size=[3.60, 0.10, 3.60], mat="steel_grey", pos=[0, 5.0, 0], tags="floating")
  box "brace_10" (size=[3.60, 0.10, 3.60], mat="steel_grey", pos=[0, 10.0, 0], tags="floating")
  box "brace_15" (size=[2.00, 0.10, 2.00], mat="steel_grey", pos=[0, 15.0, 0], tags="floating")
  box "brace_20" (size=[2.00, 0.10, 2.00], mat="steel_grey", pos=[0, 20.0, 0], tags="floating")
  box "brace_25" (size=[1.00, 0.10, 1.00], mat="steel_grey", pos=[0, 25.0, 0], tags="floating")
  box "brace_30" (size=[1.00, 0.10, 1.00], mat="steel_grey", pos=[0, 30.0, 0], tags="floating")
  box "brace_35" (size=[0.50, 0.10, 0.50], mat="steel_grey", pos=[0, 35.0, 0], tags="floating")
  // Antenna mast
  cylinder "mast" (radius=0.15, height=8.0, mat="steel_grey", pos=[0, 44.0, 0], tags="floating")
  // Aviation warning lights
  sphere "light_1" (radius=0.20, mat="aviation_red", pos=[0, 10.0, 0], tags="floating")
  sphere "light_2" (radius=0.18, mat="aviation_red", pos=[0, 20.0, 0], tags="floating")
  sphere "light_3" (radius=0.15, mat="aviation_red", pos=[0, 30.0, 0], tags="floating")
  sphere "light_top" (radius=0.18, mat="aviation_red", pos=[0, 48.0, 0], tags="floating")
  // Equipment shed at base
  box "shed" (size=[3.0, 2.5, 2.0], mat="concrete", pos=[3.0, 1.25, 0], tags="floating")
}
''')

# ============================================================
# 6. railway_station.mog — brick station with clock tower
# ============================================================
w("buildings", "railway_station", '''// railway_station.mog — brick railway station with clock tower
meta (name="railway_station", description="Brick railway station with clock tower and platform canopy", tags=["building","downtown","landmark","transit","tier1"], mogen_version="0.1.12")
material "wall_brick" (color=[0.55,0.30,0.25], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wall_stone" (color=[0.65,0.62,0.58], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_tile" (color=[0.30,0.18,0.12], roughness=0.80, uv_mode="tile", uv_scale=4.0)
material "canopy_red" (color=[0.45,0.20,0.18], roughness=0.70)
material "trim_cream" (color=[0.90,0.86,0.74], roughness=0.60)
material "clock_face" (color=[0.92,0.90,0.82], roughness=0.40, emissive=[0.40,0.38,0.30], emissive_strength=0.3)
material "clock_hands" (color=[0.10,0.10,0.10], roughness=0.40)
material "window_glass" (color=[0.40,0.55,0.65], transmission=0.45, roughness=0.05)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "rs_win" () {
  box "frame" (size=[1.20, 1.60, 0.06], mat="trim_cream")
  box "glass" (size=[1.05, 1.45, 0.02], mat="window_glass", pos=[0,0,-0.04])
}
module "rs_door" () {
  box "frame" (size=[1.60, 2.40, 0.06], mat="trim_cream")
  box "glass" (size=[1.45, 2.25, 0.02], mat="door_glass", pos=[0,0,-0.04])
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.60,0,0.06], tags="floating")
}
scene {
  slab "plaza" (size=[24.0, 0.05, 16.0], mat="asphalt", pos=[0, 0.025, 0])
  slab "platform" (size=[20.0, 0.30, 5.0], mat="concrete", pos=[0, 0.15, 6.0])
  slab "foundation" (size=[16.0, 0.30, 8.0], mat="concrete", pos=[0, 0.15, 0])
  // Main body
  box "body" (size=[16.0, 4.0, 8.0], mat="wall_brick", pos=[0, 2.30, 0])
  slab "roof_main" (size=[16.5, 0.20, 8.5], mat="roof_tile", pos=[0, 4.40, 0])
  // Clock tower (front center, taller)
  box "tower" (size=[3.5, 9.0, 3.5], mat="wall_stone", pos=[0, 4.75, -2.0])
  prism "tower_roof" (size=[4.0, 2.0, 4.0], pos=[0, 10.25, -2.0], mat="roof_tile")
  // Clock face on each side
  cylinder "clock_n" (radius=0.80, height=0.10, mat="clock_face", pos=[0, 6.5, -3.80], rot=[90,0,0], tags="floating")
  cylinder "clock_s" (radius=0.80, height=0.10, mat="clock_face", pos=[0, 6.5, -0.20], rot=[90,0,0], tags="floating")
  cylinder "clock_e" (radius=0.80, height=0.10, mat="clock_face", pos=[1.80, 6.5, -2.0], rot=[0,90,0], tags="floating")
  cylinder "clock_w" (radius=0.80, height=0.10, mat="clock_face", pos=[-1.80, 6.5, -2.0], rot=[0,90,0], tags="floating")
  box "hand_h_n" (size=[0.40, 0.06, 0.04], mat="clock_hands", pos=[0.20, 6.5, -3.86], tags="floating")
  box "hand_v_n" (size=[0.06, 0.50, 0.04], mat="clock_hands", pos=[0, 6.75, -3.86], tags="floating")
  // Platform canopy
  box "canopy_post_l" (size=[0.20, 4.0, 0.20], mat="trim_cream", pos=[-9.0, 2.0, 6.0], tags="floating")
  box "canopy_post_r" (size=[0.20, 4.0, 0.20], mat="trim_cream", pos=[9.0, 2.0, 6.0], tags="floating")
  box "canopy_post_m1" (size=[0.20, 4.0, 0.20], mat="trim_cream", pos=[-3.0, 2.0, 6.0], tags="floating")
  box "canopy_post_m2" (size=[0.20, 4.0, 0.20], mat="trim_cream", pos=[3.0, 2.0, 6.0], tags="floating")
  slab "canopy_roof" (size=[20.0, 0.15, 4.0], mat="canopy_red", pos=[0, 4.10, 6.0])
  // Holes — front
  wall "front_wall" (size=[16.0, 4.0, 0.20], pos=[0, 2.30, -4.0], holes=[[-5.0,-0.40,1.60,2.40],[-2.5,0.30,1.20,1.60],[2.5,0.30,1.20,1.60],[5.0,0.30,1.20,1.60]])
  wall "back_wall" (size=[16.0, 4.0, 0.20], pos=[0, 2.30, 4.0], holes=[[-5.0,0.30,1.20,1.60],[-2.5,0.30,1.20,1.60],[0,0.30,1.20,1.60],[2.5,0.30,1.20,1.60],[5.0,0.30,1.20,1.60]])
  wall "left_wall" (size=[8.0, 4.0, 0.20], pos=[-8.0, 2.30, 0], rot=[0,90,0], holes=[[-2.0,0.30,1.20,1.60],[2.0,0.30,1.20,1.60]])
  wall "right_wall" (size=[8.0, 4.0, 0.20], pos=[8.0, 2.30, 0], rot=[0,90,0], holes=[[-2.0,0.30,1.20,1.60],[2.0,0.30,1.20,1.60]])
  // Group placements
  group "door_g" (pos=[-5.0, 1.10, -4.0]) { use "rs_door" () }
  group "wf_1" (pos=[-2.5, 2.30, -4.0]) { use "rs_win" () }
  group "wf_2" (pos=[2.5, 2.30, -4.0]) { use "rs_win" () }
  group "wf_3" (pos=[5.0, 2.30, -4.0]) { use "rs_win" () }
  group "wb_1" (pos=[-5.0, 2.30, 4.0]) { use "rs_win" () }
  group "wb_2" (pos=[-2.5, 2.30, 4.0]) { use "rs_win" () }
  group "wb_3" (pos=[0, 2.30, 4.0]) { use "rs_win" () }
  group "wb_4" (pos=[2.5, 2.30, 4.0]) { use "rs_win" () }
  group "wb_5" (pos=[5.0, 2.30, 4.0]) { use "rs_win" () }
  group "wl_1" (pos=[-8.0, 2.30, -2.0], rot=[0,90,0]) { use "rs_win" () }
  group "wl_2" (pos=[-8.0, 2.30, 2.0], rot=[0,90,0]) { use "rs_win" () }
  group "wr_1" (pos=[8.0, 2.30, -2.0], rot=[0,90,0]) { use "rs_win" () }
  group "wr_2" (pos=[8.0, 2.30, 2.0], rot=[0,90,0]) { use "rs_win" () }
}
''')

# ============================================================
# 7. grain_silo.mog — tall white cylinder cluster
# ============================================================
w("buildings", "grain_silo", '''// grain_silo.mog — cluster of grain silos (Farmland civic landmark)
meta (name="grain_silo", description="Cluster of 4 grain silos with connecting top structure", tags=["building","farmland","landmark","industrial","tier1"], mogen_version="0.1.12")
material "silo_white" (color=[0.92,0.90,0.85], roughness=0.70, uv_mode="tile", uv_scale=6.0)
material "silo_grey" (color=[0.55,0.53,0.50], roughness=0.70, uv_mode="tile", uv_scale=6.0)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "rust" (color=[0.45,0.25,0.15], roughness=0.85)
scene {
  slab "ground" (size=[16.0, 0.04, 16.0], mat="grass")
  slab "foundation" (size=[12.0, 0.20, 12.0], mat="concrete", pos=[0, 0.10, 0])
  // 4 silos in 2x2 grid
  cylinder "silo_1" (radius=2.0, height=14.0, mat="silo_white", pos=[-3.0, 7.10, -3.0])
  cylinder "silo_2" (radius=2.0, height=14.0, mat="silo_white", pos=[3.0, 7.10, -3.0])
  cylinder "silo_3" (radius=2.0, height=14.0, mat="silo_white", pos=[-3.0, 7.10, 3.0])
  cylinder "silo_4" (radius=2.0, height=14.0, mat="silo_white", pos=[3.0, 7.10, 3.0])
  // Silo caps (conical roofs)
  cone "cap_1" (radius=2.1, height=1.5, mat="metal_dark", pos=[-3.0, 14.85, -3.0], tags="floating")
  cone "cap_2" (radius=2.1, height=1.5, mat="metal_dark", pos=[3.0, 14.85, -3.0], tags="floating")
  cone "cap_3" (radius=2.1, height=1.5, mat="metal_dark", pos=[-3.0, 14.85, 3.0], tags="floating")
  cone "cap_4" (radius=2.1, height=1.5, mat="metal_dark", pos=[3.0, 14.85, 3.0], tags="floating")
  // Horizontal bands (corrugation rings)
  torus "band_1a" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[-3.0, 3.0, -3.0], rot=[90,0,0], tags="floating")
  torus "band_1b" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[-3.0, 7.0, -3.0], rot=[90,0,0], tags="floating")
  torus "band_1c" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[-3.0, 11.0, -3.0], rot=[90,0,0], tags="floating")
  torus "band_2a" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[3.0, 3.0, -3.0], rot=[90,0,0], tags="floating")
  torus "band_2b" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[3.0, 7.0, -3.0], rot=[90,0,0], tags="floating")
  torus "band_2c" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[3.0, 11.0, -3.0], rot=[90,0,0], tags="floating")
  torus "band_3a" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[-3.0, 3.0, 3.0], rot=[90,0,0], tags="floating")
  torus "band_3b" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[-3.0, 7.0, 3.0], rot=[90,0,0], tags="floating")
  torus "band_3c" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[-3.0, 11.0, 3.0], rot=[90,0,0], tags="floating")
  torus "band_4a" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[3.0, 3.0, 3.0], rot=[90,0,0], tags="floating")
  torus "band_4b" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[3.0, 7.0, 3.0], rot=[90,0,0], tags="floating")
  torus "band_4c" (radius=2.05, tube_radius=0.05, mat="silo_grey", pos=[3.0, 11.0, 3.0], rot=[90,0,0], tags="floating")
  // Connecting top platform
  slab "top_platform" (size=[10.0, 0.20, 10.0], mat="metal_dark", pos=[0, 14.10, 0], tags="floating")
  // Railing around top
  box "rail_n" (size=[10.0, 0.10, 0.05], mat="metal_dark", pos=[0, 14.50, -5.05], tags="floating")
  box "rail_s" (size=[10.0, 0.10, 0.05], mat="metal_dark", pos=[0, 14.50, 5.05], tags="floating")
  box "rail_e" (size=[0.05, 0.10, 10.0], mat="metal_dark", pos=[5.05, 14.50, 0], tags="floating")
  box "rail_w" (size=[0.05, 0.10, 10.0], mat="metal_dark", pos=[-5.05, 14.50, 0], tags="floating")
  // External ladder
  box "ladder_l" (size=[0.05, 14.0, 0.05], mat="rust", pos=[3.05, 7.10, 2.05], tags="floating")
  box "ladder_r" (size=[0.05, 14.0, 0.05], mat="rust", pos=[3.20, 7.10, 2.05], tags="floating")
  // Lower chute
  box "chute_1" (size=[1.0, 0.6, 1.0], mat="rust", pos=[-3.0, 0.50, -3.0], tags="floating")
  box "chute_2" (size=[1.0, 0.6, 1.0], mat="rust", pos=[3.0, 0.50, -3.0], tags="floating")
  box "chute_3" (size=[1.0, 0.6, 1.0], mat="rust", pos=[-3.0, 0.50, 3.0], tags="floating")
  box "chute_4" (size=[1.0, 0.6, 1.0], mat="rust", pos=[3.0, 0.50, 3.0], tags="floating")
}
''')

# ============================================================
# 8. windmill.mog — classic Dutch-style tower windmill
# ============================================================
w("buildings", "windmill", '''// windmill.mog — classic Dutch-style windmill (Farmland civic landmark)
meta (name="windmill", description="Classic Dutch-style tower windmill with rotating cap and four sails", tags=["building","farmland","landmark","windmill","tier1"], mogen_version="0.1.12")
material "wall_white" (color=[0.88,0.85,0.78], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_dark" (color=[0.30,0.20,0.15], roughness=0.85)
material "roof_wood" (color=[0.35,0.22,0.15], roughness=0.80)
material "sail_canvas" (color=[0.92,0.90,0.85], roughness=0.80, transmission=0.20)
material "sail_wood" (color=[0.40,0.28,0.18], roughness=0.80)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "ground" (size=[14.0, 0.04, 14.0], mat="grass")
  slab "foundation" (size=[6.0, 0.30, 6.0], mat="concrete", pos=[0, 0.15, 0])
  // Tower body — tapered (use stacked cylinders)
  cylinder "tier_1" (radius=2.5, height=3.0, mat="wall_white", pos=[0, 1.50, 0])
  cylinder "tier_2" (radius=2.3, height=3.0, mat="wall_white", pos=[0, 4.50, 0])
  cylinder "tier_3" (radius=2.1, height=3.0, mat="wall_white", pos=[0, 7.50, 0])
  cylinder "tier_4" (radius=1.9, height=2.0, mat="wall_white", pos=[0, 10.50, 0])
  // Cap (rotating part — conical)
  cone "cap" (radius=2.1, height=1.5, mat="roof_wood", pos=[0, 12.25, 0])
  // Door (small, at base)
  box "door" (size=[1.0, 1.8, 0.20], mat="wall_dark", pos=[0, 1.10, 2.45], tags="floating")
  // Windows (small, dark)
  box "win_1" (size=[0.6, 0.8, 0.10], mat="wall_dark", pos=[0, 4.50, 2.20], tags="floating")
  box "win_2" (size=[0.6, 0.8, 0.10], mat="wall_dark", pos=[0, 7.50, 2.10], tags="floating")
  box "win_3" (size=[0.6, 0.8, 0.10], mat="wall_dark", pos=[0, 10.50, 1.95], tags="floating")
  // Sail hub
  cylinder "hub" (radius=0.30, height=0.60, mat="metal_dark", pos=[0, 12.0, -2.30], rot=[90,0,0], tags="floating")
  // 4 sails — each is a long cross beam + canvas
  // Sail 1 (north)
  box "sail1_beam_h" (size=[8.0, 0.15, 0.15], mat="sail_wood", pos=[0, 12.0, -2.45], tags="floating")
  box "sail1_canvas_1" (size=[1.5, 2.0, 0.02], mat="sail_canvas", pos=[-3.5, 13.0, -2.48], tags="floating")
  box "sail1_canvas_2" (size=[1.5, 2.0, 0.02], mat="sail_canvas", pos=[3.5, 13.0, -2.48], tags="floating")
  box "sail1_canvas_3" (size=[1.5, 2.0, 0.02], mat="sail_canvas", pos=[-3.5, 11.0, -2.48], tags="floating")
  box "sail1_canvas_4" (size=[1.5, 2.0, 0.02], mat="sail_canvas", pos=[3.5, 11.0, -2.48], tags="floating")
  // Sail 2 (vertical)
  box "sail2_beam_v" (size=[0.15, 8.0, 0.15], mat="sail_wood", pos=[0, 12.0, -2.45], tags="floating")
  // (Canvases for sail 2 are duplicates of sail 1 — skip to keep mesh light)
  // Tail pole (back of cap)
  cylinder "tail_pole" (radius=0.08, height=3.0, mat="sail_wood", pos=[0, 11.5, 3.5], rot=[60,0,0], tags="floating")
}
''')

# ============================================================
# 9. tractor_shed.mog — corrugated metal farm shed
# ============================================================
w("buildings", "tractor_shed", '''// tractor_shed.mog — open-front corrugated metal farm shed
meta (name="tractor_shed", description="Open-front corrugated metal farm shed for tractor storage", tags=["building","farmland","shed","tier1"], mogen_version="0.1.12")
material "metal_roof" (color=[0.45,0.42,0.40], roughness=0.60, metallic=0.6, uv_mode="tile", uv_scale=6.0)
material "metal_wall" (color=[0.40,0.38,0.36], roughness=0.60, metallic=0.6)
material "wood_post" (color=[0.35,0.25,0.15], roughness=0.85)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "rust" (color=[0.45,0.25,0.15], roughness=0.85)
scene {
  slab "ground" (size=[14.0, 0.04, 10.0], mat="grass")
  slab "floor" (size=[8.0, 0.10, 6.0], mat="concrete", pos=[0, 0.05, 0])
  // Back wall
  wall "back_wall" (size=[8.0, 3.5, 0.10], pos=[0, 1.80, 3.0], mat="metal_wall")
  // Side walls (partial — open front)
  wall "left_wall" (size=[6.0, 3.5, 0.10], pos=[-4.0, 1.80, 0], rot=[0,90,0], mat="metal_wall")
  wall "right_wall" (size=[6.0, 3.5, 0.10], pos=[4.0, 1.80, 0], rot=[0,90,0], mat="metal_wall")
  // Roof (slight slope)
  slab "roof" (size=[8.5, 0.10, 6.5], mat="metal_roof", pos=[0, 3.55, 0], rot=[3,0,0])
  // Front posts (open front)
  box "post_fl" (size=[0.20, 3.5, 0.20], mat="wood_post", pos=[-3.9, 1.75, -3.0], tags="floating")
  box "post_fr" (size=[0.20, 3.5, 0.20], mat="wood_post", pos=[3.9, 1.75, -3.0], tags="floating")
  // Open beam across front
  box "lintel" (size=[8.0, 0.20, 0.20], mat="wood_post", pos=[0, 3.40, -3.0], tags="floating")
  // Corrugated roof ridges
  box "ridge_1" (size=[8.5, 0.04, 0.05], mat="rust", pos=[0, 3.62, -2.0], tags="floating")
  box "ridge_2" (size=[8.5, 0.04, 0.05], mat="rust", pos=[0, 3.62, 0], tags="floating")
  box "ridge_3" (size=[8.5, 0.04, 0.05], mat="rust", pos=[0, 3.62, 2.0], tags="floating")
  // Small side door (cut into back wall, just visual hint)
  box "door_h" (size=[2.5, 2.5, 0.12], mat="wood_post", pos=[0, 1.30, 2.95], tags="floating")
}
''')

# ============================================================
# 10. farmhouse.mog — 2-story farmhouse with wraparound porch
# ============================================================
w("buildings", "farmhouse", '''// farmhouse.mog — 2-story farmhouse with wraparound porch
meta (name="farmhouse", description="2-story farmhouse with wraparound porch and gable roof", tags=["building","farmland","house","tier1"], mogen_version="0.1.12")
material "wall_white" (color=[0.88,0.85,0.78], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_wood" (color=[0.45,0.30,0.20], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_red" (color=[0.50,0.20,0.15], roughness=0.80, uv_mode="tile", uv_scale=4.0)
material "trim_cream" (color=[0.92,0.90,0.85], roughness=0.60)
material "window_glass" (color=[0.40,0.55,0.65], transmission=0.45, roughness=0.05)
material "door_wood" (color=[0.30,0.18,0.10], roughness=0.65)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "fh_win" () {
  chamfered_box "frame" (size=[1.00, 1.20, 0.06], radius=0.015, mat="trim_cream")
  box "glass" (size=[0.85, 1.05, 0.02], mat="window_glass", pos=[0,0,-0.03])
}
module "fh_door" () {
  chamfered_box "frame" (size=[1.10, 2.20, 0.06], radius=0.02, mat="trim_cream")
  chamfered_box "panel" (size=[0.95, 2.05, 0.05], radius=0.015, mat="door_wood", pos=[0,0,-0.08])
  sphere "knob" (radius=0.04, mat="brass", pos=[0.35,-0.10,-0.13])
}
module "porch_post" () {
  box "post" (size=[0.20, 2.50, 0.20], mat="wall_wood")
  box "base" (size=[0.30, 0.20, 0.30], mat="concrete", pos=[0,-1.15,0])
  box "cap" (size=[0.25, 0.10, 0.25], mat="trim_cream", pos=[0,1.30,0])
}
scene {
  slab "lawn" (size=[24.0, 0.04, 18.0], mat="grass")
  slab "foundation" (size=[10.0, 0.30, 8.0], mat="concrete", pos=[0, 0.15, 0])
  // Main body
  box "body" (size=[10.0, 5.0, 8.0], mat="wall_white", pos=[0, 2.80, 0])
  prism "roof" (size=[10.8, 1.80, 8.8], pos=[0, 6.20, 0], mat="roof_red")
  // Chimney
  box "chimney" (size=[0.50, 1.50, 0.50], mat="wall_white", pos=[2.50, 6.80, 0], tags="floating")
  box "chim_cap" (size=[0.55, 0.10, 0.55], mat="concrete", pos=[2.50, 7.60, 0], tags="floating")
  // Wraparound porch — front + side platforms
  slab "porch_floor" (size=[12.0, 0.20, 3.0], mat="wall_wood", pos=[0, 0.10, -5.0])
  slab "porch_side" (size=[3.0, 0.20, 8.5], mat="wall_wood", pos=[-4.5, 0.10, -1.0])
  // Porch roof (low slope)
  prism "porch_roof" (size=[12.2, 0.40, 3.2], pos=[0, 3.10, -5.0], mat="roof_red")
  // Porch posts
  group "pp_1" (pos=[-5.5, 1.40, -5.0]) { use "porch_post" () }
  group "pp_2" (pos=[-2.0, 1.40, -5.0]) { use "porch_post" () }
  group "pp_3" (pos=[2.0, 1.40, -5.0]) { use "porch_post" () }
  group "pp_4" (pos=[5.5, 1.40, -5.0]) { use "porch_post" () }
  group "pp_5" (pos=[-5.5, 1.40, -3.0]) { use "porch_post" () }
  group "pp_6" (pos=[-5.5, 1.40, 1.0]) { use "porch_post" () }
  group "pp_7" (pos=[-5.5, 1.40, 4.0]) { use "porch_post" () }
  // Holes — front
  wall "front_wall" (size=[10.0, 5.0, 0.20], pos=[0, 2.80, -4.0], holes=[[0.0,-0.40,1.10,2.20],[-3.00,1.0,1.00,1.20],[3.00,1.0,1.00,1.20]])
  wall "back_wall" (size=[10.0, 5.0, 0.20], pos=[0, 2.80, 4.0], holes=[[-3.00,1.0,1.00,1.20],[0.0,1.0,1.00,1.20],[3.00,1.0,1.00,1.20]])
  wall "left_wall" (size=[8.0, 5.0, 0.20], pos=[-5.0, 2.80, 0], rot=[0,90,0], holes=[[-2.00,0.5,1.00,1.20],[2.00,0.5,1.00,1.20],[-2.00,-2.0,1.00,1.20],[2.00,-2.0,1.00,1.20]])
  wall "right_wall" (size=[8.0, 5.0, 0.20], pos=[5.0, 2.80, 0], rot=[0,90,0], holes=[[-2.00,0.5,1.00,1.20],[2.00,0.5,1.00,1.20]])
  // Group placements
  group "door_g" (pos=[0, 1.20, -4.0]) { use "fh_door" () }
  group "wf_l" (pos=[-3.0, 2.60, -4.0]) { use "fh_win" () }
  group "wf_r" (pos=[3.0, 2.60, -4.0]) { use "fh_win" () }
  group "wb_1" (pos=[-3.0, 2.60, 4.0]) { use "fh_win" () }
  group "wb_2" (pos=[0, 2.60, 4.0]) { use "fh_win" () }
  group "wb_3" (pos=[3.0, 2.60, 4.0]) { use "fh_win" () }
  group "wl_1" (pos=[-5.0, 2.10, -2.0], rot=[0,90,0]) { use "fh_win" () }
  group "wl_2" (pos=[-5.0, 2.10, 2.0], rot=[0,90,0]) { use "fh_win" () }
  group "wl_3" (pos=[-5.0, 4.10, -2.0], rot=[0,90,0]) { use "fh_win" () }
  group "wl_4" (pos=[-5.0, 4.10, 2.0], rot=[0,90,0]) { use "fh_win" () }
  group "wr_1" (pos=[5.0, 2.10, -2.0], rot=[0,90,0]) { use "fh_win" () }
  group "wr_2" (pos=[5.0, 2.10, 2.0], rot=[0,90,0]) { use "fh_win" () }
}
''')

print("=== Part 1: 10 buildings written ===")
