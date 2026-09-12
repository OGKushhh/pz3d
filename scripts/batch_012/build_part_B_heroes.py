#!/usr/bin/env python3
"""Batch 012 — Part B — 4 HUGE hero buildings (government_palace, stadium, old_royal_palace, fort_sarran).
These are large multi-wing landmarks, 30m+ on a side, with internal courtyards / multiple stories."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# ============================================================
# 1. government_palace.mog — massive 3-wing government building with central dome
# 40m wide × 25m deep × 18m tall (3 stories) + 25m dome
# ============================================================
w("buildings", "government_palace", '''// government_palace.mog — massive 3-wing government building with central dome
meta (name="government_palace", description="Massive 3-wing government palace with central dome, colonnaded entrance, and grand steps", tags=["building","downtown","landmark","hero","civic","tier1"], mogen_version="0.1.12")
material "wall_stone" (color=[0.78,0.74,0.65], roughness=0.85, uv_mode="tile", uv_scale=6.0)
material "wall_marble" (color=[0.88,0.86,0.80], roughness=0.50, uv_mode="tile", uv_scale=4.0)
material "roof_copper" (color=[0.30,0.55,0.45], roughness=0.60, metallic=0.4, uv_mode="tile", uv_scale=4.0)
material "dome_copper" (color=[0.35,0.60,0.50], roughness=0.50, metallic=0.6)
material "column_marble" (color=[0.92,0.90,0.85], roughness=0.40)
material "trim_gold" (color=[0.85,0.65,0.20], roughness=0.30, metallic=0.85)
material "window_glass" (color=[0.30,0.40,0.50], transmission=0.40, roughness=0.05)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "grass" (color=[0.25,0.42,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "door_wood" (color=[0.30,0.18,0.10], roughness=0.65)
module "gp_column" () {
  // Classical column — base + shaft + capital
  box "base" (size=[0.80, 0.20, 0.80], mat="column_marble")
  cylinder "shaft" (radius=0.30, height=4.50, mat="column_marble", pos=[0, 2.45, 0])
  box "capital" (size=[0.80, 0.30, 0.80], mat="column_marble", pos=[0, 4.85, 0])
}
module "gp_window" () {
  box "frame" (size=[1.30, 2.20, 0.06], mat="column_marble")
  box "glass" (size=[1.15, 2.05, 0.02], mat="window_glass", pos=[0,0,-0.04])
  box "sill" (size=[1.40, 0.08, 0.15], mat="column_marble", pos=[0,-1.15,0.05])
}
module "gp_door" () {
  box "frame" (size=[3.00, 4.50, 0.20], mat="column_marble")
  box "panel_l" (size=[1.40, 4.30, 0.10], mat="door_wood", pos=[-0.75,0,-0.15])
  box "panel_r" (size=[1.40, 4.30, 0.10], mat="door_wood", pos=[0.75,0,-0.15])
  box "knob_l" (size=[0.05, 0.10, 0.05], mat="trim_gold", pos=[-0.10,0,-0.25], tags="floating")
  box "knob_r" (size=[0.05, 0.10, 0.05], mat="trim_gold", pos=[0.10,0,-0.25], tags="floating")
}
scene {
  // === PLAZA ===
  slab "plaza" (size=[60.0, 0.05, 40.0], mat="asphalt", pos=[0, 0.025, 5.0])
  slab "lawn_l" (size=[15.0, 0.04, 25.0], mat="grass", pos=[-22.5, 0.02, 5.0])
  slab "lawn_r" (size=[15.0, 0.04, 25.0], mat="grass", pos=[22.5, 0.02, 5.0])
  slab "foundation" (size=[42.0, 0.50, 25.0], mat="concrete", pos=[0, 0.25, 0])
  // === GRAND STEPS (front, 5 steps) ===
  slab "step_1" (size=[20.0, 0.20, 1.50], mat="column_marble", pos=[0, 0.20, -13.50])
  slab "step_2" (size=[20.0, 0.20, 1.50], mat="column_marble", pos=[0, 0.40, -12.50])
  slab "step_3" (size=[20.0, 0.20, 1.50], mat="column_marble", pos=[0, 0.60, -11.50])
  slab "step_4" (size=[20.0, 0.20, 1.50], mat="column_marble", pos=[0, 0.80, -10.50])
  slab "step_5" (size=[20.0, 0.20, 1.50], mat="column_marble", pos=[0, 1.00, -9.50])
  // === MAIN BODY (3 wings — center + 2 sides, all 3 stories tall) ===
  // Center wing (front, with colonnade)
  box "center_body" (size=[20.0, 14.0, 12.0], mat="wall_marble", pos=[0, 7.50, 0])
  // Left wing (set back)
  box "left_body" (size=[10.0, 14.0, 18.0], mat="wall_stone", pos=[-15.0, 7.50, 3.0])
  // Right wing (mirrored)
  box "right_body" (size=[10.0, 14.0, 18.0], mat="wall_stone", pos=[15.0, 7.50, 3.0])
  // === ROOFS (3 separate roofs, copper-green) ===
  prism "center_roof" (size=[20.5, 2.50, 12.5], pos=[0, 15.50, 0], mat="roof_copper")
  prism "left_roof" (size=[10.5, 2.00, 18.5], pos=[-15.0, 15.00, 3.0], mat="roof_copper")
  prism "right_roof" (size=[10.5, 2.00, 18.5], pos=[15.0, 15.00, 3.0], mat="roof_copper")
  // === CENTRAL DOME (above center wing) ===
  cylinder "drum" (radius=4.0, height=3.0, mat="wall_marble", pos=[0, 17.50, 0])
  sphere "dome" (radius=4.5, mat="dome_copper", pos=[0, 20.50, 0])
  // Dome finial
  cylinder "finial_pole" (radius=0.05, height=2.0, mat="trim_gold", pos=[0, 25.50, 0], tags="floating")
  sphere "finial_ball" (radius=0.30, mat="trim_gold", pos=[0, 25.00, 0], tags="floating")
  // === COLONNADE (front of center wing — 8 columns at ground level) ===
  group "col_1" (pos=[-9.0, 1.00, -7.0]) { use "gp_column" () }
  group "col_2" (pos=[-6.0, 1.00, -7.0]) { use "gp_column" () }
  group "col_3" (pos=[-3.0, 1.00, -7.0]) { use "gp_column" () }
  group "col_4" (pos=[0, 1.00, -7.0]) { use "gp_column" () }
  group "col_5" (pos=[3.0, 1.00, -7.0]) { use "gp_column" () }
  group "col_6" (pos=[6.0, 1.00, -7.0]) { use "gp_column" () }
  group "col_7" (pos=[9.0, 1.00, -7.0]) { use "gp_column" () }
  // Pediment over colonnade (triangular gable)
  prism "pediment" (size=[22.0, 2.00, 1.50], pos=[0, 14.50, -7.0], mat="wall_marble")
  // === FRONT WALL (center wing — main door + windows) ===
  wall "front_wall_center" (size=[20.0, 14.0, 0.20], pos=[0, 7.50, -6.0], holes=[[0,-3.20,3.00,4.50],[-7.0,1.0,1.30,2.20],[7.0,1.0,1.30,2.20],[-4.0,-1.0,1.30,2.20],[4.0,-1.0,1.30,2.20],[-4.0,3.5,1.30,2.20],[4.0,3.5,1.30,2.20]])
  // Left wing front wall
  wall "front_wall_left" (size=[10.0, 14.0, 0.20], pos=[-15.0, 7.50, -6.0], holes=[[-2.5,1.0,1.30,2.20],[0,1.0,1.30,2.20],[2.5,1.0,1.30,2.20],[-2.5,-2.5,1.30,2.20],[2.5,-2.5,1.30,2.20]])
  // Right wing front wall
  wall "front_wall_right" (size=[10.0, 14.0, 0.20], pos=[15.0, 7.50, -6.0], holes=[[-2.5,1.0,1.30,2.20],[0,1.0,1.30,2.20],[2.5,1.0,1.30,2.20],[-2.5,-2.5,1.30,2.20],[2.5,-2.5,1.30,2.20]])
  // Back walls (3 wings)
  wall "back_wall_center" (size=[20.0, 14.0, 0.20], pos=[0, 7.50, 6.0], holes=[[-7.0,1.0,1.30,2.20],[0,1.0,1.30,2.20],[7.0,1.0,1.30,2.20],[-4.0,-2.5,1.30,2.20],[4.0,-2.5,1.30,2.20]])
  wall "back_wall_left" (size=[18.0, 14.0, 0.20], pos=[-15.0, 7.50, 12.0], rot=[0,90,0], holes=[[-5.0,1.0,1.30,2.20],[-2.5,1.0,1.30,2.20],[0,1.0,1.30,2.20],[2.5,1.0,1.30,2.20],[5.0,1.0,1.30,2.20],[-5.0,-2.5,1.30,2.20],[5.0,-2.5,1.30,2.20]])
  wall "back_wall_right" (size=[18.0, 14.0, 0.20], pos=[15.0, 7.50, 12.0], rot=[0,90,0], holes=[[-5.0,1.0,1.30,2.20],[-2.5,1.0,1.30,2.20],[0,1.0,1.30,2.20],[2.5,1.0,1.30,2.20],[5.0,1.0,1.30,2.20],[-5.0,-2.5,1.30,2.20],[5.0,-2.5,1.30,2.20]])
  // Side walls (outer ends of left + right wings)
  wall "outer_wall_left" (size=[18.0, 14.0, 0.20], pos=[-20.0, 7.50, 3.0], rot=[0,90,0], holes=[[-5.0,1.0,1.30,2.20],[0,1.0,1.30,2.20],[5.0,1.0,1.30,2.20],[-5.0,-2.5,1.30,2.20],[5.0,-2.5,1.30,2.20]])
  wall "outer_wall_right" (size=[18.0, 14.0, 0.20], pos=[20.0, 7.50, 3.0], rot=[0,90,0], holes=[[-5.0,1.0,1.30,2.20],[0,1.0,1.30,2.20],[5.0,1.0,1.30,2.20],[-5.0,-2.5,1.30,2.20],[5.0,-2.5,1.30,2.20]])
  // === MAIN DOOR (center, grand) ===
  group "door_main" (pos=[0, 4.50, -6.0]) { use "gp_door" () }
  // === WINDOWS (placed at hole positions) ===
  // Center wing front
  group "wf_c_1" (pos=[-7.0, 8.50, -6.0]) { use "gp_window" () }
  group "wf_c_2" (pos=[7.0, 8.50, -6.0]) { use "gp_window" () }
  group "wf_c_3" (pos=[-4.0, 6.50, -6.0]) { use "gp_window" () }
  group "wf_c_4" (pos=[4.0, 6.50, -6.0]) { use "gp_window" () }
  group "wf_c_5" (pos=[-4.0, 11.00, -6.0]) { use "gp_window" () }
  group "wf_c_6" (pos=[4.0, 11.00, -6.0]) { use "gp_window" () }
  // Left wing front
  group "wf_l_1" (pos=[-17.5, 8.50, -6.0]) { use "gp_window" () }
  group "wf_l_2" (pos=[-15.0, 8.50, -6.0]) { use "gp_window" () }
  group "wf_l_3" (pos=[-12.5, 8.50, -6.0]) { use "gp_window" () }
  group "wf_l_4" (pos=[-17.5, 5.00, -6.0]) { use "gp_window" () }
  group "wf_l_5" (pos=[-12.5, 5.00, -6.0]) { use "gp_window" () }
  // Right wing front
  group "wf_r_1" (pos=[12.5, 8.50, -6.0]) { use "gp_window" () }
  group "wf_r_2" (pos=[15.0, 8.50, -6.0]) { use "gp_window" () }
  group "wf_r_3" (pos=[17.5, 8.50, -6.0]) { use "gp_window" () }
  group "wf_r_4" (pos=[12.5, 5.00, -6.0]) { use "gp_window" () }
  group "wf_r_5" (pos=[17.5, 5.00, -6.0]) { use "gp_window" () }
  // === FLAGPOLE (in front of colonnade) ===
  cylinder "flag_pole" (radius=0.10, height=10.0, mat="trim_gold", pos=[0, 5.00, -10.0], tags="floating")
  box "flag" (size=[2.0, 1.2, 0.02], mat="trim_gold", pos=[1.0, 13.50, -10.0], tags="floating")
  // === STATUES (2 flanking the grand steps) ===
  box "statue_pedestal_l" (size=[1.0, 1.5, 1.0], mat="column_marble", pos=[-7.0, 0.75, -14.0], tags="floating")
  box "statue_l" (size=[0.4, 1.0, 0.4], mat="column_marble", pos=[-7.0, 2.0, -14.0], tags="floating")
  box "statue_pedestal_r" (size=[1.0, 1.5, 1.0], mat="column_marble", pos=[7.0, 0.75, -14.0], tags="floating")
  box "statue_r" (size=[0.4, 1.0, 0.4], mat="column_marble", pos=[7.0, 2.0, -14.0], tags="floating")
}
''')

# ============================================================
# 2. stadium.mog — sports stadium, 60m diameter, 18m tall, with light pylons
# ============================================================
w("buildings", "stadium", '''// stadium.mog — large oval sports stadium with tiered seating and 4 light pylons
meta (name="stadium", description="Large oval sports stadium with tiered seating bowl, perimeter wall, and 4 corner light pylons", tags=["building","downtown","landmark","hero","sports","tier1"], mogen_version="0.1.12")
material "wall_concrete" (color=[0.65,0.63,0.60], roughness=0.90, uv_mode="tile", uv_scale=6.0)
material "wall_white" (color=[0.85,0.85,0.82], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "roof_metal" (color=[0.40,0.42,0.48], roughness=0.50, metallic=0.7)
material "grass_field" (color=[0.20,0.40,0.15], roughness=0.85, uv_mode="tile", uv_scale=8.0)
material "track_red" (color=[0.65,0.20,0.15], roughness=0.80, uv_mode="tile", uv_scale=4.0)
material "seating_grey" (color=[0.45,0.45,0.45], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "pylon_metal" (color=[0.40,0.40,0.42], roughness=0.50, metallic=0.85)
material "light_white" (color=[0.95,0.95,0.85], roughness=0.20, emissive=[0.85,0.85,0.75], emissive_strength=0.8)
material "line_white" (color=[0.92,0.92,0.88], roughness=0.60, emissive=[0.30,0.30,0.25], emissive_strength=0.15)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
scene {
  // === OUTER PARKING / PLAZA ===
  slab "plaza" (size=[80.0, 0.05, 80.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")
  slab "foundation" (size=[70.0, 0.30, 50.0], mat="concrete", pos=[0, 0.15, 0])
  // === FIELD (rectangle in middle) ===
  slab "field" (size=[40.0, 0.10, 20.0], mat="grass_field", pos=[0, 0.05, 0])
  // Yard lines (white stripes across field, every 5m)
  slab "line_1" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[-15, 0.10, 0], tags="floating")
  slab "line_2" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[-10, 0.10, 0], tags="floating")
  slab "line_3" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[-5, 0.10, 0], tags="floating")
  slab "line_4" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[0, 0.10, 0], tags="floating")
  slab "line_5" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[5, 0.10, 0], tags="floating")
  slab "line_6" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[10, 0.10, 0], tags="floating")
  slab "line_7" (size=[0.10, 0.04, 20.0], mat="line_white", pos=[15, 0.10, 0], tags="floating")
  // Track (oval-ish, approximated as rectangular border)
  slab "track_n" (size=[50.0, 0.10, 3.0], mat="track_red", pos=[0, 0.06, -13.0], tags="floating")
  slab "track_s" (size=[50.0, 0.10, 3.0], mat="track_red", pos=[0, 0.06, 13.0], tags="floating")
  slab "track_e" (size=[3.0, 0.10, 26.0], mat="track_red", pos=[23.5, 0.06, 0], tags="floating")
  slab "track_w" (size=[3.0, 0.10, 26.0], mat="track_red", pos=[-23.5, 0.06, 0], tags="floating")
  // === LOWER SEATING BOWL (4 trapezoidal tiers around field) ===
  // North stands (with sloped underside)
  box "stands_n" (size=[50.0, 8.0, 10.0], mat="seating_grey", pos=[0, 4.50, -19.0], rot=[15,0,0], tags="floating")
  box "stands_s" (size=[50.0, 8.0, 10.0], mat="seating_grey", pos=[0, 4.50, 19.0], rot=[-15,0,0], tags="floating")
  box "stands_e" (size=[10.0, 8.0, 26.0], mat="seating_grey", pos=[26.5, 4.50, 0], rot=[0,0,-15], tags="floating")
  box "stands_w" (size=[10.0, 8.0, 26.0], mat="seating_grey", pos=[-26.5, 4.50, 0], rot=[0,0,15], tags="floating")
  // === UPPER DECK (smaller, on top of lower) ===
  box "upper_n" (size=[50.0, 6.0, 6.0], mat="seating_grey", pos=[0, 10.50, -22.0], rot=[20,0,0], tags="floating")
  box "upper_s" (size=[50.0, 6.0, 6.0], mat="seating_grey", pos=[0, 10.50, 22.0], rot=[-20,0,0], tags="floating")
  box "upper_e" (size=[6.0, 6.0, 26.0], mat="seating_grey", pos=[29.0, 10.50, 0], rot=[0,0,-20], tags="floating")
  box "upper_w" (size=[6.0, 6.0, 26.0], mat="seating_grey", pos=[-29.0, 10.50, 0], rot=[0,0,20], tags="floating")
  // === PERIMETER WALL (encloses the bowl) ===
  wall "perim_n" (size=[60.0, 4.0, 0.20], pos=[0, 14.00, -28.0], mat="wall_concrete")
  wall "perim_s" (size=[60.0, 4.0, 0.20], pos=[0, 14.00, 28.0], mat="wall_concrete")
  wall "perim_e" (size=[56.0, 4.0, 0.20], pos=[32.0, 14.00, 0], rot=[0,90,0], mat="wall_concrete", holes=[[-10.0,-0.80,4.0,2.50]])
  wall "perim_w" (size=[56.0, 4.0, 0.20], pos=[-32.0, 14.00, 0], rot=[0,90,0], mat="wall_concrete", holes=[[10.0,-0.80,4.0,2.50]])
  // === ROOF CANOPY (partial — covers upper deck on N and S) ===
  box "canopy_n" (size=[50.0, 0.30, 8.0], mat="roof_metal", pos=[0, 16.50, -24.0], rot=[10,0,0], tags="floating")
  box "canopy_s" (size=[50.0, 0.30, 8.0], mat="roof_metal", pos=[0, 16.50, 24.0], rot=[-10,0,0], tags="floating")
  box "canopy_e" (size=[8.0, 0.30, 26.0], mat="roof_metal", pos=[30.0, 16.50, 0], rot=[0,0,-10], tags="floating")
  box "canopy_w" (size=[8.0, 0.30, 26.0], mat="roof_metal", pos=[-30.0, 16.50, 0], rot=[0,0,10], tags="floating")
  // === 4 LIGHT PYLONS (at 4 corners, 20m tall) ===
  // Pylon NE
  box "pyl_ne_leg_fl" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[35.0, 10.0, -30.0], rot=[0,0,8], tags="floating")
  box "pyl_ne_leg_fr" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[36.5, 10.0, -30.0], rot=[0,0,-8], tags="floating")
  box "pyl_ne_head" (size=[2.0, 3.0, 1.0], mat="pylon_metal", pos=[35.75, 21.50, -30.0], tags="floating")
  sphere "ne_light_1" (radius=0.30, mat="light_white", pos=[35.0, 21.5, -30.5], tags="floating")
  sphere "ne_light_2" (radius=0.30, mat="light_white", pos=[36.5, 21.5, -30.5], tags="floating")
  sphere "ne_light_3" (radius=0.30, mat="light_white", pos=[35.0, 22.5, -30.5], tags="floating")
  sphere "ne_light_4" (radius=0.30, mat="light_white", pos=[36.5, 22.5, -30.5], tags="floating")
  // Pylon NW
  box "pyl_nw_leg_fl" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[-36.5, 10.0, -30.0], rot=[0,0,8], tags="floating")
  box "pyl_nw_leg_fr" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[-35.0, 10.0, -30.0], rot=[0,0,-8], tags="floating")
  box "pyl_nw_head" (size=[2.0, 3.0, 1.0], mat="pylon_metal", pos=[-35.75, 21.50, -30.0], tags="floating")
  sphere "nw_light_1" (radius=0.30, mat="light_white", pos=[-36.5, 21.5, -30.5], tags="floating")
  sphere "nw_light_2" (radius=0.30, mat="light_white", pos=[-35.0, 21.5, -30.5], tags="floating")
  sphere "nw_light_3" (radius=0.30, mat="light_white", pos=[-36.5, 22.5, -30.5], tags="floating")
  sphere "nw_light_4" (radius=0.30, mat="light_white", pos=[-35.0, 22.5, -30.5], tags="floating")
  // Pylon SE
  box "pyl_se_leg_fl" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[35.0, 10.0, 30.0], rot=[0,0,8], tags="floating")
  box "pyl_se_leg_fr" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[36.5, 10.0, 30.0], rot=[0,0,-8], tags="floating")
  box "pyl_se_head" (size=[2.0, 3.0, 1.0], mat="pylon_metal", pos=[35.75, 21.50, 30.0], tags="floating")
  sphere "se_light_1" (radius=0.30, mat="light_white", pos=[35.0, 21.5, 30.5], tags="floating")
  sphere "se_light_2" (radius=0.30, mat="light_white", pos=[36.5, 21.5, 30.5], tags="floating")
  sphere "se_light_3" (radius=0.30, mat="light_white", pos=[35.0, 22.5, 30.5], tags="floating")
  sphere "se_light_4" (radius=0.30, mat="light_white", pos=[36.5, 22.5, 30.5], tags="floating")
  // Pylon SW
  box "pyl_sw_leg_fl" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[-36.5, 10.0, 30.0], rot=[0,0,8], tags="floating")
  box "pyl_sw_leg_fr" (size=[0.20, 20.0, 0.20], mat="pylon_metal", pos=[-35.0, 10.0, 30.0], rot=[0,0,-8], tags="floating")
  box "pyl_sw_head" (size=[2.0, 3.0, 1.0], mat="pylon_metal", pos=[-35.75, 21.50, 30.0], tags="floating")
  sphere "sw_light_1" (radius=0.30, mat="light_white", pos=[-36.5, 21.5, 30.5], tags="floating")
  sphere "sw_light_2" (radius=0.30, mat="light_white", pos=[-35.0, 21.5, 30.5], tags="floating")
  sphere "sw_light_3" (radius=0.30, mat="light_white", pos=[-36.5, 22.5, 30.5], tags="floating")
  sphere "sw_light_4" (radius=0.30, mat="light_white", pos=[-35.0, 22.5, 30.5], tags="floating")
  // === ENTRY GATES (2 — east and west) ===
  box "gate_e_arch" (size=[6.0, 5.0, 0.40], mat="wall_white", pos=[33.0, 4.50, 0], tags="floating")
  box "gate_e_sign" (size=[5.0, 1.0, 0.10], mat="wall_white", pos=[33.0, 7.50, 0.10], tags="floating")
  box "gate_w_arch" (size=[6.0, 5.0, 0.40], mat="wall_white", pos=[-33.0, 4.50, 0], tags="floating")
  box "gate_w_sign" (size=[5.0, 1.0, 0.10], mat="wall_white", pos=[-33.0, 7.50, 0.10], tags="floating")
  // === SCOREBOARD (north end, big screen) ===
  box "scoreboard" (size=[8.0, 4.0, 0.50], mat="wall_white", pos=[0, 16.50, -28.30], tags="floating")
}
''')

# ============================================================
# 3. old_royal_palace.mog — historic palace with towers and inner courtyard
# 50m × 40m footprint, 4 corner towers + central gatehouse, 15m tall main body
# ============================================================
w("buildings", "old_royal_palace", '''// old_royal_palace.mog — historic royal palace with 4 corner towers + central gatehouse + inner courtyard
meta (name="old_royal_palace", description="Historic royal palace with 4 corner towers, central gatehouse, inner courtyard, and crenellated walls", tags=["building","downtown","landmark","hero","historic","tier1"], mogen_version="0.1.12")
material "wall_stone" (color=[0.70,0.65,0.55], roughness=0.85, uv_mode="tile", uv_scale=6.0)
material "wall_dark" (color=[0.50,0.45,0.38], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "roof_tile" (color=[0.45,0.25,0.18], roughness=0.80, uv_mode="tile", uv_scale=6.0)
material "roof_tower" (color=[0.40,0.20,0.15], roughness=0.80)
material "trim_gold" (color=[0.85,0.65,0.20], roughness=0.30, metallic=0.85)
material "window_glass" (color=[0.25,0.30,0.40], transmission=0.30, roughness=0.10)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "grass" (color=[0.25,0.42,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "door_wood" (color=[0.25,0.15,0.08], roughness=0.65)
material "flag_purple" (color=[0.45,0.20,0.55], roughness=0.70)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
module "pal_window" () {
  box "frame" (size=[0.80, 1.20, 0.06], mat="wall_stone")
  box "glass" (size=[0.65, 1.05, 0.02], mat="window_glass", pos=[0,0,-0.04])
  box "sill" (size=[0.90, 0.06, 0.10], mat="wall_stone", pos=[0,-0.65,0.05])
}
module "tower_full" () {
  // Tower = cylinder body + cone roof + flag pole
  cylinder "body" (radius=2.5, height=12.0, mat="wall_stone", pos=[0, 6.0, 0])
  // Crenellations around top (8 small boxes)
  box "cren_1" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[0, 12.30, 2.30], tags="floating")
  box "cren_2" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[1.63, 12.30, 1.63], tags="floating")
  box "cren_3" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[2.30, 12.30, 0], tags="floating")
  box "cren_4" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[1.63, 12.30, -1.63], tags="floating")
  box "cren_5" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[0, 12.30, -2.30], tags="floating")
  box "cren_6" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[-1.63, 12.30, -1.63], tags="floating")
  box "cren_7" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[-2.30, 12.30, 0], tags="floating")
  box "cren_8" (size=[0.50, 0.60, 0.50], mat="wall_stone", pos=[-1.63, 12.30, 1.63], tags="floating")
  // Conical roof
  cone "roof" (radius=3.0, height=4.0, mat="roof_tower", pos=[0, 14.00, 0], tags="floating")
  // Flag pole + flag
  cylinder "pole" (radius=0.04, height=2.0, mat="metal_dark", pos=[0, 17.50, 0], tags="floating")
  box "flag" (size=[0.60, 0.40, 0.02], mat="flag_purple", pos=[0.30, 17.80, 0], tags="floating")
  // Tower arrow-slit windows (4 sides, narrow)
  box "win_n" (size=[0.20, 1.20, 0.05], mat="window_glass", pos=[0, 7.0, -2.45], tags="floating")
  box "win_s" (size=[0.20, 1.20, 0.05], mat="window_glass", pos=[0, 7.0, 2.45], tags="floating")
  box "win_e" (size=[0.05, 1.20, 0.20], mat="window_glass", pos=[2.45, 7.0, 0], tags="floating")
  box "win_w" (size=[0.05, 1.20, 0.20], mat="window_glass", pos=[-2.45, 7.0, 0], tags="floating")
  // Upper windows
  box "win_n_2" (size=[0.20, 1.20, 0.05], mat="window_glass", pos=[0, 10.0, -2.45], tags="floating")
  box "win_s_2" (size=[0.20, 1.20, 0.05], mat="window_glass", pos=[0, 10.0, 2.45], tags="floating")
  box "win_e_2" (size=[0.05, 1.20, 0.20], mat="window_glass", pos=[2.45, 10.0, 0], tags="floating")
  box "win_w_2" (size=[0.05, 1.20, 0.20], mat="window_glass", pos=[-2.45, 10.0, 0], tags="floating")
}
scene {
  // === LAWN / GROUNDS ===
  slab "lawn" (size=[70.0, 0.04, 60.0], mat="grass", tags="floating")
  slab "foundation" (size=[50.0, 0.40, 40.0], mat="concrete", pos=[0, 0.20, 0])
  // === 4 CORNER TOWERS ===
  group "tower_NW" (pos=[-25.0, 0, -20.0]) { use "tower_full" () }
  group "tower_NE" (pos=[25.0, 0, -20.0]) { use "tower_full" () }
  group "tower_SW" (pos=[-25.0, 0, 20.0]) { use "tower_full" () }
  group "tower_SE" (pos=[25.0, 0, 20.0]) { use "tower_full" () }
  // === MAIN BODY — 4 wings around inner courtyard ===
  // Front wing (north, with gatehouse in middle)
  box "front_wing_body" (size=[40.0, 10.0, 6.0], mat="wall_stone", pos=[0, 5.0, -17.0])
  prism "front_wing_roof" (size=[40.5, 2.00, 6.5], pos=[0, 10.50, -17.0], mat="roof_tile")
  // Crenellations on front wing
  box "fc_1" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[-19.0, 10.30, -17.0], tags="floating")
  box "fc_2" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[-17.0, 10.30, -17.0], tags="floating")
  box "fc_3" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[-15.0, 10.30, -17.0], tags="floating")
  box "fc_4" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[-13.0, 10.30, -17.0], tags="floating")
  box "fc_5" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[-11.0, 10.30, -17.0], tags="floating")
  box "fc_6" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[-9.0, 10.30, -17.0], tags="floating")
  box "fc_7" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[9.0, 10.30, -17.0], tags="floating")
  box "fc_8" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[11.0, 10.30, -17.0], tags="floating")
  box "fc_9" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[13.0, 10.30, -17.0], tags="floating")
  box "fc_10" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[15.0, 10.30, -17.0], tags="floating")
  box "fc_11" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[17.0, 10.30, -17.0], tags="floating")
  box "fc_12" (size=[1.0, 0.6, 0.20], mat="wall_stone", pos=[19.0, 10.30, -17.0], tags="floating")
  // Back wing (south)
  box "back_wing_body" (size=[40.0, 10.0, 6.0], mat="wall_stone", pos=[0, 5.0, 17.0])
  prism "back_wing_roof" (size=[40.5, 2.00, 6.5], pos=[0, 10.50, 17.0], mat="roof_tile")
  // Left wing (west)
  box "left_wing_body" (size=[6.0, 10.0, 28.0], mat="wall_stone", pos=[-17.0, 5.0, 0])
  prism "left_wing_roof" (size=[6.5, 2.00, 28.5], pos=[-17.0, 10.50, 0], mat="roof_tile", rot=[0,90,0])
  // Right wing (east)
  box "right_wing_body" (size=[6.0, 10.0, 28.0], mat="wall_stone", pos=[17.0, 5.0, 0])
  prism "right_wing_roof" (size=[6.5, 2.00, 28.5], pos=[17.0, 10.50, 0], mat="roof_tile", rot=[0,90,0])
  // === FRONT GATEHOUSE (center, taller than wing) ===
  box "gatehouse_body" (size=[10.0, 14.0, 8.0], mat="wall_dark", pos=[0, 7.0, -17.0])
  prism "gatehouse_roof" (size=[10.5, 3.0, 8.5], pos=[0, 14.50, -17.0], mat="roof_tower")
  // Gatehouse flag
  cylinder "gh_pole" (radius=0.05, height=2.5, mat="metal_dark", pos=[0, 18.00, -17.0], tags="floating")
  box "gh_flag" (size=[0.80, 0.50, 0.02], mat="flag_purple", pos=[0.40, 18.40, -17.0], tags="floating")
  // === MAIN GATE (front, double wood doors) ===
  box "gate_arch_frame" (size=[4.0, 5.5, 0.40], mat="wall_stone", pos=[0, 3.0, -20.95], tags="floating")
  box "gate_door_l" (size=[1.80, 4.50, 0.10], mat="door_wood", pos=[-0.90, 2.50, -21.00], tags="floating")
  box "gate_door_r" (size=[1.80, 4.50, 0.10], mat="door_wood", pos=[0.90, 2.50, -21.00], tags="floating")
  box "gate_knob_l" (size=[0.06, 0.10, 0.06], mat="trim_gold", pos=[-0.10, 2.50, -21.10], tags="floating")
  box "gate_knob_r" (size=[0.06, 0.10, 0.06], mat="trim_gold", pos=[0.10, 2.50, -21.10], tags="floating")
  // === COURTYARD FOUNTAIN (center) ===
  cylinder "fountain_base" (radius=2.5, height=0.40, mat="wall_stone", pos=[0, 0.20, 0], tags="floating")
  cylinder "fountain_inner" (radius=1.5, height=0.30, mat="wall_dark", pos=[0, 0.35, 0], tags="floating")
  cylinder "fountain_pillar" (radius=0.20, height=1.5, mat="wall_stone", pos=[0, 1.20, 0], tags="floating")
  sphere "fountain_top" (radius=0.40, mat="window_glass", pos=[0, 2.00, 0], tags="floating")
  // === FRONT WALLS (with windows) ===
  // Front wing facade — 4 windows + gatehouse door
  wall "front_wing_wall" (size=[40.0, 10.0, 0.20], pos=[0, 5.0, -20.0], holes=[[-12.0,1.0,0.80,1.20],[-8.0,1.0,0.80,1.20],[8.0,1.0,0.80,1.20],[12.0,1.0,0.80,1.20],[-12.0,4.0,0.80,1.20],[-8.0,4.0,0.80,1.20],[8.0,4.0,0.80,1.20],[12.0,4.0,0.80,1.20]])
  // Back wing facade — 6 windows
  wall "back_wing_wall" (size=[40.0, 10.0, 0.20], pos=[0, 5.0, 20.0], holes=[[-15.0,1.0,0.80,1.20],[-10.0,1.0,0.80,1.20],[-5.0,1.0,0.80,1.20],[5.0,1.0,0.80,1.20],[10.0,1.0,0.80,1.20],[15.0,1.0,0.80,1.20],[-15.0,4.0,0.80,1.20],[-10.0,4.0,0.80,1.20],[-5.0,4.0,0.80,1.20],[5.0,4.0,0.80,1.20],[10.0,4.0,0.80,1.20],[15.0,4.0,0.80,1.20]])
  // Left + right wing courtyard-side walls
  wall "left_inner_wall" (size=[28.0, 10.0, 0.20], pos=[-14.0, 5.0, 0], rot=[0,90,0], holes=[[-10.0,1.0,0.80,1.20],[-5.0,1.0,0.80,1.20],[5.0,1.0,0.80,1.20],[10.0,1.0,0.80,1.20],[-10.0,4.0,0.80,1.20],[-5.0,4.0,0.80,1.20],[5.0,4.0,0.80,1.20],[10.0,4.0,0.80,1.20]])
  wall "right_inner_wall" (size=[28.0, 10.0, 0.20], pos=[14.0, 5.0, 0], rot=[0,90,0], holes=[[-10.0,1.0,0.80,1.20],[-5.0,1.0,0.80,1.20],[5.0,1.0,0.80,1.20],[10.0,1.0,0.80,1.20],[-10.0,4.0,0.80,1.20],[-5.0,4.0,0.80,1.20],[5.0,4.0,0.80,1.20],[10.0,4.0,0.80,1.20]])
  // === GARDEN PATHS (decorative — flagged) ===
  slab "path_n_s" (size=[3.0, 0.04, 22.0], mat="concrete", pos=[0, 0.02, 0], tags="floating")
  slab "path_e_w" (size=[28.0, 0.04, 3.0], mat="concrete", pos=[0, 0.02, 0], tags="floating")
  // === GROUP PLACEMENTS — WINDOWS ===
  // Front wing windows
  group "wf_1" (pos=[-12.0, 6.0, -20.0]) { use "pal_window" () }
  group "wf_2" (pos=[-8.0, 6.0, -20.0]) { use "pal_window" () }
  group "wf_3" (pos=[8.0, 6.0, -20.0]) { use "pal_window" () }
  group "wf_4" (pos=[12.0, 6.0, -20.0]) { use "pal_window" () }
  group "wf_5" (pos=[-12.0, 9.0, -20.0]) { use "pal_window" () }
  group "wf_6" (pos=[-8.0, 9.0, -20.0]) { use "pal_window" () }
  group "wf_7" (pos=[8.0, 9.0, -20.0]) { use "pal_window" () }
  group "wf_8" (pos=[12.0, 9.0, -20.0]) { use "pal_window" () }
  // Back wing windows
  group "wb_1" (pos=[-15.0, 6.0, 20.0]) { use "pal_window" () }
  group "wb_2" (pos=[-10.0, 6.0, 20.0]) { use "pal_window" () }
  group "wb_3" (pos=[-5.0, 6.0, 20.0]) { use "pal_window" () }
  group "wb_4" (pos=[5.0, 6.0, 20.0]) { use "pal_window" () }
  group "wb_5" (pos=[10.0, 6.0, 20.0]) { use "pal_window" () }
  group "wb_6" (pos=[15.0, 6.0, 20.0]) { use "pal_window" () }
  group "wb_7" (pos=[-15.0, 9.0, 20.0]) { use "pal_window" () }
  group "wb_8" (pos=[-10.0, 9.0, 20.0]) { use "pal_window" () }
  group "wb_9" (pos=[-5.0, 9.0, 20.0]) { use "pal_window" () }
  group "wb_10" (pos=[5.0, 9.0, 20.0]) { use "pal_window" () }
  group "wb_11" (pos=[10.0, 9.0, 20.0]) { use "pal_window" () }
  group "wb_12" (pos=[15.0, 9.0, 20.0]) { use "pal_window" () }
}
''')

# ============================================================
# 4. fort_sarran.mog — massive military fortress, the outbreak origin
# 60m × 60m footprint, 8m tall curtain wall, 6 corner bastions + central keep
# ============================================================
w("buildings", "fort_sarran", '''// fort_sarran.mog — massive military fortress — the outbreak origin (hero asset)
meta (name="fort_sarran", description="Massive 5-pointed star fortress with curtain walls, 6 bastions, central keep, and dry moat — the outbreak origin", tags=["building","military","landmark","hero","outbreak","tier1"], mogen_version="0.1.12")
material "wall_stone_dark" (color=[0.42,0.38,0.32], roughness=0.90, uv_mode="tile", uv_scale=6.0)
material "wall_stone" (color=[0.55,0.50,0.43], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "wall_concrete" (color=[0.45,0.42,0.38], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "roof_keep" (color=[0.20,0.15,0.10], roughness=0.85)
material "roof_bastion" (color=[0.30,0.20,0.15], roughness=0.85)
material "grass_dry" (color=[0.35,0.40,0.18], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "moat_mud" (color=[0.25,0.20,0.12], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "concrete" (color=[0.40,0.38,0.32], roughness=0.90)
material "metal_dark" (color=[0.25,0.25,0.28], roughness=0.50, metallic=0.85)
material "door_steel" (color=[0.20,0.20,0.22], roughness=0.40, metallic=0.85)
material "warning_red" (color=[0.85,0.10,0.10], roughness=0.50, emissive=[0.50,0.05,0.05], emissive_strength=0.5)
material "window_glass" (color=[0.20,0.25,0.30], transmission=0.20, roughness=0.10)
material "fence_metal" (color=[0.30,0.32,0.20], roughness=0.60, metallic=0.7)
module "bastion" () {
  // Pentagonal bastion — approximated with rotated box + cylinder cap
  cylinder "body" (radius=4.0, height=8.0, mat="wall_stone_dark", pos=[0, 4.0, 0])
  // Crenellations around top
  box "cren_1" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[0, 8.40, 3.60], tags="floating")
  box "cren_2" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[2.55, 8.40, 2.55], tags="floating")
  box "cren_3" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[3.60, 8.40, 0], tags="floating")
  box "cren_4" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[2.55, 8.40, -2.55], tags="floating")
  box "cren_5" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[0, 8.40, -3.60], tags="floating")
  box "cren_6" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[-2.55, 8.40, -2.55], tags="floating")
  box "cren_7" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[-3.60, 8.40, 0], tags="floating")
  box "cren_8" (size=[0.80, 0.80, 0.50], mat="wall_stone_dark", pos=[-2.55, 8.40, 2.55], tags="floating")
  // Conical roof (small)
  cone "roof" (radius=3.0, height=1.5, mat="roof_bastion", pos=[0, 8.80, 0], tags="floating")
  // Slit windows
  box "win_n" (size=[0.20, 1.50, 0.05], mat="window_glass", pos=[0, 4.0, -3.95], tags="floating")
  box "win_s" (size=[0.20, 1.50, 0.05], mat="window_glass", pos=[0, 4.0, 3.95], tags="floating")
  box "win_e" (size=[0.05, 1.50, 0.20], mat="window_glass", pos=[3.95, 4.0, 0], tags="floating")
  box "win_w" (size=[0.05, 1.50, 0.20], mat="window_glass", pos=[-3.95, 4.0, 0], tags="floating")
}
module "keep_tower" () {
  // Tall narrow keep tower — 5 stories
  box "body" (size=[6.0, 18.0, 6.0], mat="wall_concrete", pos=[0, 9.0, 0])
  // Crenellations
  box "cren_n" (size=[0.80, 0.80, 0.50], mat="wall_concrete", pos=[-2.0, 18.40, -3.0], tags="floating")
  box "cren_n2" (size=[0.80, 0.80, 0.50], mat="wall_concrete", pos=[0, 18.40, -3.0], tags="floating")
  box "cren_n3" (size=[0.80, 0.80, 0.50], mat="wall_concrete", pos=[2.0, 18.40, -3.0], tags="floating")
  box "cren_s" (size=[0.80, 0.80, 0.50], mat="wall_concrete", pos=[-2.0, 18.40, 3.0], tags="floating")
  box "cren_s2" (size=[0.80, 0.80, 0.50], mat="wall_concrete", pos=[0, 18.40, 3.0], tags="floating")
  box "cren_s3" (size=[0.80, 0.80, 0.50], mat="wall_concrete", pos=[2.0, 18.40, 3.0], tags="floating")
  box "cren_e" (size=[0.50, 0.80, 0.80], mat="wall_concrete", pos=[3.0, 18.40, -2.0], tags="floating")
  box "cren_e2" (size=[0.50, 0.80, 0.80], mat="wall_concrete", pos=[3.0, 18.40, 0], tags="floating")
  box "cren_e3" (size=[0.50, 0.80, 0.80], mat="wall_concrete", pos=[3.0, 18.40, 2.0], tags="floating")
  box "cren_w" (size=[0.50, 0.80, 0.80], mat="wall_concrete", pos=[-3.0, 18.40, -2.0], tags="floating")
  box "cren_w2" (size=[0.50, 0.80, 0.80], mat="wall_concrete", pos=[-3.0, 18.40, 0], tags="floating")
  box "cren_w3" (size=[0.50, 0.80, 0.80], mat="wall_concrete", pos=[-3.0, 18.40, 2.0], tags="floating")
  // Flat roof
  slab "roof" (size=[6.4, 0.20, 6.4], mat="roof_keep", pos=[0, 18.20, 0], tags="floating")
  // Windows (4 floors × 4 sides = 16 — but we'll keep it minimal: 8 visible)
  box "win_n_1" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 4.0, -3.05], tags="floating")
  box "win_n_2" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 4.0, -3.05], tags="floating")
  box "win_n_3" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 8.0, -3.05], tags="floating")
  box "win_n_4" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 8.0, -3.05], tags="floating")
  box "win_n_5" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 12.0, -3.05], tags="floating")
  box "win_n_6" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 12.0, -3.05], tags="floating")
  box "win_n_7" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 16.0, -3.05], tags="floating")
  box "win_n_8" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 16.0, -3.05], tags="floating")
  box "win_s_1" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 4.0, 3.05], tags="floating")
  box "win_s_2" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 4.0, 3.05], tags="floating")
  box "win_s_3" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 8.0, 3.05], tags="floating")
  box "win_s_4" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 8.0, 3.05], tags="floating")
  box "win_s_5" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 12.0, 3.05], tags="floating")
  box "win_s_6" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 12.0, 3.05], tags="floating")
  box "win_s_7" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[-1.50, 16.0, 3.05], tags="floating")
  box "win_s_8" (size=[0.60, 0.90, 0.05], mat="window_glass", pos=[1.50, 16.0, 3.05], tags="floating")
}
scene {
  // === OUTER GROUNDS (dry, abandoned) ===
  slab "outer_ground" (size=[80.0, 0.04, 80.0], mat="grass_dry", tags="floating")
  // === DRY MOAT (around the fortress) ===
  // Moat is approximated as a ring of darker ground around the wall perimeter
  slab "moat_n" (size=[60.0, 0.04, 6.0], mat="moat_mud", pos=[0, 0.02, -33.0], tags="floating")
  slab "moat_s" (size=[60.0, 0.04, 6.0], mat="moat_mud", pos=[0, 0.02, 33.0], tags="floating")
  slab "moat_e" (size=[6.0, 0.04, 60.0], mat="moat_mud", pos=[33.0, 0.02, 0], tags="floating")
  slab "moat_w" (size=[6.0, 0.04, 60.0], mat="moat_mud", pos=[-33.0, 0.02, 0], tags="floating")
  // === FOUNDATION (inner) ===
  slab "foundation" (size=[54.0, 0.40, 54.0], mat="concrete", pos=[0, 0.20, 0])
  // === CURTAIN WALLS (4 sides, 8m tall, 2m thick) ===
  wall "wall_n" (size=[50.0, 8.0, 0.50], pos=[0, 4.0, -27.0], mat="wall_stone_dark", holes=[[0,-1.0,4.0,3.0]])
  wall "wall_s" (size=[50.0, 8.0, 0.50], pos=[0, 4.0, 27.0], mat="wall_stone_dark")
  wall "wall_e" (size=[54.0, 8.0, 0.50], pos=[27.0, 4.0, 0], rot=[0,90,0], mat="wall_stone_dark")
  wall "wall_w" (size=[54.0, 8.0, 0.50], pos=[-27.0, 4.0, 0], rot=[0,90,0], mat="wall_stone_dark")
  // === 6 CORNER + MID BASTIONS ===
  group "bastion_NW" (pos=[-25.0, 0, -25.0]) { use "bastion" () }
  group "bastion_NE" (pos=[25.0, 0, -25.0]) { use "bastion" () }
  group "bastion_SW" (pos=[-25.0, 0, 25.0]) { use "bastion" () }
  group "bastion_SE" (pos=[25.0, 0, 25.0]) { use "bastion" () }
  group "bastion_N_mid" (pos=[0, 0, -27.0]) { use "bastion" () }
  group "bastion_S_mid" (pos=[0, 0, 27.0]) { use "bastion" () }
  // === CENTRAL KEEP (5-story tower in middle) ===
  group "keep" (pos=[0, 0, 0]) { use "keep_tower" () }
  // === MAIN GATE (north wall) — double steel doors ===
  box "gate_arch_frame" (size=[5.0, 4.5, 0.60], mat="wall_stone", pos=[0, 2.50, -27.30], tags="floating")
  box "gate_door_l" (size=[1.80, 3.50, 0.15], mat="door_steel", pos=[-0.95, 2.0, -27.40], tags="floating")
  box "gate_door_r" (size=[1.80, 3.50, 0.15], mat="door_steel", pos=[0.95, 2.0, -27.40], tags="floating")
  // Heavy locking bars
  box "lock_bar_l" (size=[0.20, 4.0, 0.20], mat="metal_dark", pos=[-2.50, 2.0, -27.30], tags="floating")
  box "lock_bar_r" (size=[0.20, 4.0, 0.20], mat="metal_dark", pos=[2.50, 2.0, -27.30], tags="floating")
  // === DRAWBRIDGE (lowered across moat) ===
  slab "drawbridge" (size=[5.0, 0.20, 6.0], mat="wall_stone", pos=[0, 0.20, -30.0])
  // Chains (4 corners of drawbridge going up to gate)
  box "chain_l_1" (size=[0.05, 4.0, 0.05], mat="metal_dark", pos=[-2.0, 2.20, -28.0], rot=[20,0,0], tags="floating")
  box "chain_l_2" (size=[0.05, 4.0, 0.05], mat="metal_dark", pos=[2.0, 2.20, -28.0], rot=[20,0,0], tags="floating")
  // === BARBED WIRE FENCE (inner perimeter, just inside wall) ===
  box "fence_post_n_1" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[-20.0, 1.0, -25.5], tags="floating")
  box "fence_post_n_2" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[-10.0, 1.0, -25.5], tags="floating")
  box "fence_post_n_3" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[10.0, 1.0, -25.5], tags="floating")
  box "fence_post_n_4" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[20.0, 1.0, -25.5], tags="floating")
  box "fence_post_s_1" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[-20.0, 1.0, 25.5], tags="floating")
  box "fence_post_s_2" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[-10.0, 1.0, 25.5], tags="floating")
  box "fence_post_s_3" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[10.0, 1.0, 25.5], tags="floating")
  box "fence_post_s_4" (size=[0.10, 2.0, 0.10], mat="fence_metal", pos=[20.0, 1.0, 25.5], tags="floating")
  // Wire strands
  box "wire_n_low" (size=[40.0, 0.03, 0.03], mat="fence_metal", pos=[0, 0.50, -25.5], tags="floating")
  box "wire_n_high" (size=[40.0, 0.03, 0.03], mat="fence_metal", pos=[0, 1.80, -25.5], tags="floating")
  box "wire_s_low" (size=[40.0, 0.03, 0.03], mat="fence_metal", pos=[0, 0.50, 25.5], tags="floating")
  box "wire_s_high" (size=[40.0, 0.03, 0.03], mat="fence_metal", pos=[0, 1.80, 25.5], tags="floating")
  // === BIOHAZARD WARNING SIGN (on gate) ===
  box "sign_back" (size=[2.0, 1.0, 0.10], mat="warning_red", pos=[0, 5.50, -27.55], tags="floating")
  box "sign_text_1" (size=[1.5, 0.15, 0.02], mat="metal_dark", pos=[0, 5.80, -27.61], tags="floating")
  box "sign_text_2" (size=[1.5, 0.15, 0.02], mat="metal_dark", pos=[0, 5.50, -27.61], tags="floating")
  box "sign_text_3" (size=[1.5, 0.15, 0.02], mat="metal_dark", pos=[0, 5.20, -27.61], tags="floating")
  // === INTERIOR COURTYARD PAVING ===
  slab "courtyard_pave" (size=[40.0, 0.05, 40.0], mat="concrete", pos=[0, 0.42, 0], tags="floating")
  // === OBSERVATION LIGHT (top of keep, red beacon) ===
  sphere "keep_beacon" (radius=0.30, mat="warning_red", pos=[0, 18.50, 0], tags="floating")
  cylinder "beacon_pole" (radius=0.04, height=0.80, mat="metal_dark", pos=[0, 18.40, 0], tags="floating")
}
''')

print("\n=== Part B: 4 huge hero buildings written ===")
