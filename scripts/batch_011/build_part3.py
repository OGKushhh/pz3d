#!/usr/bin/env python3
"""Batch 011 — Part 3 of 4 — Subway (4) + Commercial (4) + Treehouse (1)."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

def w(cat, name, content):
    d = BASE / cat / "src"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.mog").write_text(content)
    print(f"  wrote {cat}/{name}.mog")

# ============================================================
# 25. subway_platform.mog — raised platform with edge
# ============================================================
w("buildings", "subway_platform", '''// subway_platform.mog — Subway station raised platform with yellow safety edge
meta (name="subway_platform", description="Subway station raised platform with yellow safety edge and tiled walls", tags=["building","subway","platform","tier1"], mogen_version="0.1.12")
material "tile_white" (color=[0.88,0.88,0.85], roughness=0.50, uv_mode="tile", uv_scale=8.0)
material "tile_dark" (color=[0.20,0.20,0.22], roughness=0.50, uv_mode="tile", uv_scale=8.0)
material "concrete" (color=[0.50,0.48,0.45], roughness=0.90)
material "edge_yellow" (color=[0.85,0.70,0.20], roughness=0.50, emissive=[0.40,0.30,0.05], emissive_strength=0.3)
material "metal_stainless" (color=[0.75,0.75,0.78], roughness=0.30, metallic=0.85)
material "track_dark" (color=[0.10,0.10,0.12], roughness=0.95)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
scene {
  slab "track_floor" (size=[20.0, 0.04, 8.0], mat="track_dark", pos=[0, 0.02, 0])
  // Track rails
  box "rail_l" (size=[20.0, 0.10, 0.10], mat="metal_stainless", pos=[0, 0.10, -1.5], tags="floating")
  box "rail_r" (size=[20.0, 0.10, 0.10], mat="metal_stainless", pos=[0, 0.10, 1.5], tags="floating")
  // Wooden ties
  box "tie_1" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[-9, 0.06, 0], tags="floating")
  box "tie_2" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[-6, 0.06, 0], tags="floating")
  box "tie_3" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[-3, 0.06, 0], tags="floating")
  box "tie_4" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[0, 0.06, 0], tags="floating")
  box "tie_5" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[3, 0.06, 0], tags="floating")
  box "tie_6" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[6, 0.06, 0], tags="floating")
  box "tie_7" (size=[0.20, 0.08, 3.0], mat="concrete", pos=[9, 0.06, 0], tags="floating")
  // Platform (left side)
  slab "platform_l" (size=[20.0, 1.20, 4.0], mat="tile_white", pos=[0, 0.60, -5.0])
  // Platform edge (yellow warning strip)
  slab "edge_strip_l" (size=[20.0, 0.06, 0.50], mat="edge_yellow", pos=[0, 1.225, -3.30], tags="floating")
  // Platform (right side)
  slab "platform_r" (size=[20.0, 1.20, 4.0], mat="tile_white", pos=[0, 0.60, 5.0])
  slab "edge_strip_r" (size=[20.0, 0.06, 0.50], mat="edge_yellow", pos=[0, 1.225, 3.30], tags="floating")
  // Back wall (left platform)
  wall "wall_l" (size=[20.0, 3.0, 0.20], pos=[0, 2.40, -7.0], mat="tile_white", holes=[[-7.0,1.0,2.0,1.50],[7.0,1.0,2.0,1.50]])
  wall "wall_r" (size=[20.0, 3.0, 0.20], pos=[0, 2.40, 7.0], mat="tile_white", holes=[[-7.0,1.0,2.0,1.50],[7.0,1.0,2.0,1.50]])
  // Lower wall band (dark, below platform level)
  box "wall_l_low" (size=[20.0, 1.0, 0.20], mat="tile_dark", pos=[0, 0.50, -7.10], tags="floating")
  box "wall_r_low" (size=[20.0, 1.0, 0.20], mat="tile_dark", pos=[0, 0.50, 7.10], tags="floating")
  // Ceiling
  slab "ceiling" (size=[20.0, 0.20, 14.0], mat="concrete", pos=[0, 3.90, 0])
  // Ceiling lights (fluorescent tubes)
  box "light_1" (size=[2.0, 0.10, 0.40], mat="tile_white", pos=[-7, 3.75, 0], tags="floating")
  box "light_2" (size=[2.0, 0.10, 0.40], mat="tile_white", pos=[0, 3.75, 0], tags="floating")
  box "light_3" (size=[2.0, 0.10, 0.40], mat="tile_white", pos=[7, 3.75, 0], tags="floating")
  // Platform columns (between platform and back wall)
  box "col_l_1" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[-10.0, 2.40, -6.0], tags="floating")
  box "col_l_2" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[-3.0, 2.40, -6.0], tags="floating")
  box "col_l_3" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[3.0, 2.40, -6.0], tags="floating")
  box "col_l_4" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[10.0, 2.40, -6.0], tags="floating")
  box "col_r_1" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[-10.0, 2.40, 6.0], tags="floating")
  box "col_r_2" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[-3.0, 2.40, 6.0], tags="floating")
  box "col_r_3" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[3.0, 2.40, 6.0], tags="floating")
  box "col_r_4" (size=[0.50, 3.0, 0.50], mat="metal_stainless", pos=[10.0, 2.40, 6.0], tags="floating")
  // Sign (subway line marker)
  box "sign_l" (size=[2.0, 0.50, 0.10], mat="tile_dark", pos=[0, 2.50, -7.10], tags="floating")
  box "sign_r" (size=[2.0, 0.50, 0.10], mat="tile_dark", pos=[0, 2.50, 7.10], tags="floating")
}
''')

# ============================================================
# 26. subway_tunnel.mog — curved tunnel section
# ============================================================
w("buildings", "subway_tunnel", '''// subway_tunnel.mog — Curved subway tunnel section
meta (name="subway_tunnel", description="Curved subway tunnel section with concrete lining and tracks", tags=["building","subway","tunnel","tier1"], mogen_version="0.1.12")
material "concrete_tunnel" (color=[0.35,0.33,0.30], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "concrete_dark" (color=[0.20,0.18,0.16], roughness=0.95)
material "metal_stainless" (color=[0.75,0.75,0.78], roughness=0.30, metallic=0.85)
material "track_dark" (color=[0.05,0.05,0.07], roughness=0.95)
material "pipe_red" (color=[0.65,0.20,0.15], roughness=0.50)
material "pipe_blue" (color=[0.20,0.40,0.65], roughness=0.50)
material "cable_grey" (color=[0.30,0.30,0.32], roughness=0.60)
material "light_amber" (color=[0.95,0.85,0.50], roughness=0.20, emissive=[0.80,0.65,0.30], emissive_strength=0.6)
scene {
  // Tunnel ceiling — half-cylinder
  cylinder "ceiling" (radius=4.0, height=15.0, mat="concrete_tunnel", pos=[0, 0, 0], rot=[0,90,90])
  // Tunnel floor (flat)
  slab "floor" (size=[15.0, 0.20, 8.0], mat="concrete_dark", pos=[0, -3.90, 0])
  // Track rails
  box "rail_l" (size=[15.0, 0.10, 0.10], mat="metal_stainless", pos=[0, -3.80, -1.5], tags="floating")
  box "rail_r" (size=[15.0, 0.10, 0.10], mat="metal_stainless", pos=[0, -3.80, 1.5], tags="floating")
  // Wooden ties (every 2m)
  box "tie_1" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[-6.5, -3.85, 0], tags="floating")
  box "tie_2" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[-4.5, -3.85, 0], tags="floating")
  box "tie_3" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[-2.5, -3.85, 0], tags="floating")
  box "tie_4" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[-0.5, -3.85, 0], tags="floating")
  box "tie_5" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[1.5, -3.85, 0], tags="floating")
  box "tie_6" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[3.5, -3.85, 0], tags="floating")
  box "tie_7" (size=[0.20, 0.08, 3.0], mat="concrete_dark", pos=[5.5, -3.85, 0], tags="floating")
  // Wall pipes (left side)
  cylinder "pipe_red_l" (radius=0.15, height=15.0, mat="pipe_red", pos=[-3.30, 1.50, 0], rot=[0,90,0], tags="floating")
  cylinder "pipe_blue_l" (radius=0.10, height=15.0, mat="pipe_blue", pos=[-3.20, 1.00, 0], rot=[0,90,0], tags="floating")
  // Wall pipes (right side)
  cylinder "pipe_red_r" (radius=0.15, height=15.0, mat="pipe_red", pos=[3.30, 1.50, 0], rot=[0,90,0], tags="floating")
  cylinder "pipe_blue_r" (radius=0.10, height=15.0, mat="pipe_blue", pos=[3.20, 1.00, 0], rot=[0,90,0], tags="floating")
  // Cables (small, near ceiling)
  box "cable_l" (size=[15.0, 0.05, 0.05], mat="cable_grey", pos=[0, 2.50, -3.0], tags="floating")
  box "cable_r" (size=[15.0, 0.05, 0.05], mat="cable_grey", pos=[0, 2.50, 3.0], tags="floating")
  // Emergency lights (every 3m)
  box "elight_1" (size=[0.30, 0.20, 0.10], mat="light_amber", pos=[-6, 2.0, -3.20], tags="floating")
  box "elight_2" (size=[0.30, 0.20, 0.10], mat="light_amber", pos=[-3, 2.0, -3.20], tags="floating")
  box "elight_3" (size=[0.30, 0.20, 0.10], mat="light_amber", pos=[0, 2.0, -3.20], tags="floating")
  box "elight_4" (size=[0.30, 0.20, 0.10], mat="light_amber", pos=[3, 2.0, -3.20], tags="floating")
  box "elight_5" (size=[0.30, 0.20, 0.10], mat="light_amber", pos=[6, 2.0, -3.20], tags="floating")
  // End cap (tunnel entrance/exit — dark concrete wall)
  box "end_cap_l" (size=[0.50, 8.0, 8.0], mat="concrete_dark", pos=[-7.50, 0, 0], tags="floating")
  // Refuse pile (rubble on floor)
  box "rubble_1" (size=[0.50, 0.30, 0.50], mat="concrete_dark", pos=[-3.0, -3.70, 2.5], tags="floating")
  box "rubble_2" (size=[0.40, 0.20, 0.40], mat="concrete_dark", pos=[-2.5, -3.75, 2.0], tags="floating")
  box "rubble_3" (size=[0.30, 0.15, 0.30], mat="concrete_dark", pos=[-3.5, -3.80, 2.7], tags="floating")
}
''')

# ============================================================
# 27. subway_train_car.mog — derelict subway car
# ============================================================
w("buildings", "subway_train_car", '''// subway_train_car.mog — Derelict subway train car with open doors
meta (name="subway_train_car", description="Derelict subway train car with multiple open doors", tags=["building","subway","train","vehicle","tier1"], mogen_version="0.1.12")
material "car_silver" (color=[0.75,0.75,0.78], roughness=0.50, metallic=0.6, uv_mode="tile", uv_scale=4.0)
material "car_red_band" (color=[0.55,0.15,0.10], roughness=0.60)
material "window_dark" (color=[0.20,0.25,0.30], transmission=0.30, roughness=0.20)
material "interior_dark" (color=[0.15,0.15,0.18], roughness=0.85)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.85)
material "roof_grey" (color=[0.40,0.38,0.36], roughness=0.60, metallic=0.6)
material "wheel_dark" (color=[0.15,0.15,0.18], roughness=0.50, metallic=0.85)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
scene {
  slab "ground" (size=[26.0, 0.04, 5.0], mat="asphalt", pos=[0, 0.02, 0])
  // Train body — main box
  box "body" (size=[20.0, 3.0, 2.6], mat="car_silver", pos=[0, 2.0, 0])
  // Red stripe (decoration)
  box "stripe" (size=[20.0, 0.30, 2.65], mat="car_red_band", pos=[0, 2.5, 0], tags="floating")
  // Roof (slightly curved, just a slab)
  slab "roof" (size=[20.0, 0.20, 2.8], mat="roof_grey", pos=[0, 3.50, 0])
  // Floor (interior)
  slab "floor" (size=[20.0, 0.10, 2.4], mat="interior_dark", pos=[0, 0.50, 0])
  // Windows along both sides (multiple)
  // Left side windows
  box "win_l_1" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[-7.0, 2.2, -1.30], tags="floating")
  box "win_l_2" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[-4.0, 2.2, -1.30], tags="floating")
  box "win_l_3" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[-1.0, 2.2, -1.30], tags="floating")
  box "win_l_4" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[2.0, 2.2, -1.30], tags="floating")
  box "win_l_5" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[5.0, 2.2, -1.30], tags="floating")
  // Right side windows
  box "win_r_1" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[-7.0, 2.2, 1.30], tags="floating")
  box "win_r_2" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[-4.0, 2.2, 1.30], tags="floating")
  box "win_r_3" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[-1.0, 2.2, 1.30], tags="floating")
  box "win_r_4" (size=[0.05, 1.0, 1.5], mat="window_dark", pos=[2.0, 2.2, 1.30], tags="floating")
  box "win_r_5" (size="[0.05, 1.0, 1.5]", mat="window_dark", pos=[5.0, 2.2, 1.30], tags="floating")
  // Open doorways (left side)
  box "door_l_1_open" (size=[0.05, 2.0, 1.0], mat="interior_dark", pos=[-8.5, 1.5, -1.30], tags="floating")
  box "door_l_2_open" (size=[0.05, 2.0, 1.0], mat="interior_dark", pos=[8.5, 1.5, -1.30], tags="floating")
  // Front cab window (large)
  box "cab_win" (size=[1.5, 1.2, 0.05], mat="window_dark", pos=[10.0, 2.4, 0], tags="floating")
  // Headlights (front)
  cylinder "headlight_l" (radius=0.20, height=0.10, mat="metal_dark", pos=[10.0, 1.5, -0.8], rot=[0,90,0], tags="floating")
  cylinder "headlight_r" (radius=0.20, height=0.10, mat="metal_dark", pos=[10.0, 1.5, 0.8], rot=[0,90,0], tags="floating")
  // Wheels (bogie — 4 wheels visible, 2 bogies)
  cylinder "wheel_fl" (radius=0.40, height=0.20, mat="wheel_dark", pos=[-7.0, 0.40, -1.5], rot=[90,0,0], tags="floating")
  cylinder "wheel_fr" (radius=0.40, height=0.20, mat="wheel_dark", pos=[-7.0, 0.40, 1.5], rot=[90,0,0], tags="floating")
  cylinder "wheel_bl" (radius=0.40, height=0.20, mat="wheel_dark", pos=[7.0, 0.40, -1.5], rot=[90,0,0], tags="floating")
  cylinder "wheel_br" (radius=0.40, height=0.20, mat="wheel_dark", pos=[7.0, 0.40, 1.5], rot=[90,0,0], tags="floating")
  // Couplers (front + back)
  box "coupler_f" (size=[0.30, 0.20, 0.20], mat="metal_dark", pos=[10.20, 0.60, 0], tags="floating")
  box "coupler_b" (size=[0.30, 0.20, 0.20], mat="metal_dark", pos=[-10.20, 0.60, 0], tags="floating")
  // Interior seats (visible through windows)
  box "seat_l_1" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[-7.0, 0.80, -0.8], tags="floating")
  box "seat_l_2" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[-4.0, 0.80, -0.8], tags="floating")
  box "seat_l_3" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[-1.0, 0.80, -0.8], tags="floating")
  box "seat_l_4" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[2.0, 0.80, -0.8], tags="floating")
  box "seat_l_5" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[5.0, 0.80, -0.8], tags="floating")
  box "seat_r_1" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[-7.0, 0.80, 0.8], tags="floating")
  box "seat_r_2" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[-4.0, 0.80, 0.8], tags="floating")
  box "seat_r_3" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[-1.0, 0.80, 0.8], tags="floating")
  box "seat_r_4" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[2.0, 0.80, 0.8], tags="floating")
  box "seat_r_5" (size=[1.0, 0.40, 0.40], mat="interior_dark", pos=[5.0, 0.80, 0.8], tags="floating")
}
''')

# ============================================================
# 28. ticket_booth.mog — small subway ticket booth
# ============================================================
w("buildings", "ticket_booth", '''// ticket_booth.mog — Small subway ticket booth with window
meta (name="ticket_booth", description="Small subway ticket booth with service window", tags=["building","subway","ticket","tier1"], mogen_version="0.1.12")
material "wall_wood" (color=[0.45,0.32,0.20], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_dark" (color=[0.30,0.22,0.15], roughness=0.85)
material "window_glass" (color=[0.40,0.55,0.65], transmission=0.45, roughness=0.05)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
material "light_warm" (color=[0.95,0.85,0.55], roughness=0.20, emissive=[0.80,0.65,0.30], emissive_strength=0.6)
scene {
  slab "floor" (size=[4.0, 0.05, 4.0], mat="asphalt", pos=[0, 0.025, 0])
  slab "base" (size=[2.5, 0.20, 2.0], mat="concrete", pos=[0, 0.10, 0])
  // Booth body
  box "body" (size=[2.5, 2.20, 2.0], mat="wall_wood", pos=[0, 1.30, 0])
  // Roof
  slab "roof" (size=[2.7, 0.10, 2.2], mat="wall_dark", pos=[0, 2.45, 0])
  // Service window (large, front)
  box "win_frame" (size=[1.50, 0.80, 0.06], mat="wall_dark", pos=[0, 1.40, -1.00], tags="floating")
  box "win_glass" (size=[1.40, 0.70, 0.02], mat="window_glass", pos=[0, 1.40, -1.02], tags="floating")
  // Window shelf
  box "shelf" (size=[1.55, 0.05, 0.20], mat="wall_dark", pos=[0, 1.05, -1.05], tags="floating")
  // Small side window
  box "win_side" (size=[0.06, 0.60, 0.80], mat="window_glass", pos=[-1.25, 1.50, 0], tags="floating")
  // Door (side, employee entrance)
  box "door_frame" (size=[0.80, 1.80, 0.06], mat="wall_dark", pos=[0, 1.20, 1.00], tags="floating")
  box "door" (size=[0.70, 1.70, 0.05], mat="wall_wood", pos=[0, 1.20, 1.02], tags="floating")
  box "knob" (size=[0.05, 0.10, 0.05], mat="brass", pos=[0.25, 1.20, 1.08], tags="floating")
  // Interior light (warm glow visible through windows)
  box "light" (size=[0.40, 0.20, 0.10], mat="light_warm", pos=[0, 2.10, 0], tags="floating")
  // Sign on roof
  box "sign_post_l" (size=[0.05, 0.50, 0.05], mat="metal_dark", pos=[-0.80, 2.70, 0], tags="floating")
  box "sign_post_r" (size=[0.05, 0.50, 0.05], mat="metal_dark", pos=[0.80, 2.70, 0], tags="floating")
  box "sign_board" (size=[2.0, 0.40, 0.06], mat="wall_dark", pos=[0, 3.00, 0], tags="floating")
  // Sign text (simulated with stripe)
  box "sign_text" (size=[1.8, 0.05, 0.02], mat="light_warm", pos=[0, 3.05, 0.03], tags="floating")
  // Small step at service window
  slab "step" (size=[1.80, 0.10, 0.50], mat="concrete", pos=[0, 0.05, -1.30])
}
''')

# ============================================================
# 29. strip_mall.mog — long multi-storefront building
# ============================================================
w("buildings", "strip_mall", '''// strip_mall.mog — Long multi-storefront commercial strip mall
meta (name="strip_mall", description="Long multi-storefront commercial strip mall with 4 units", tags=["building","commercial","downtown","tier1"], mogen_version="0.1.12")
material "wall_stucco" (color=[0.75,0.65,0.55], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "wall_stone" (color=[0.55,0.50,0.45], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "roof_flat" (color=[0.20,0.20,0.22], roughness=0.90)
material "trim_cream" (color=[0.92,0.90,0.85], roughness=0.60)
material "awning_red" (color=[0.55,0.20,0.18], roughness=0.70)
material "awning_green" (color=[0.30,0.45,0.20], roughness=0.70)
material "awning_blue" (color=[0.20,0.35,0.55], roughness=0.70)
material "awning_yellow" (color=[0.75,0.60,0.20], roughness=0.70)
material "window_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.05)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "sm_win" () {
  box "frame" (size=[1.40, 1.80, 0.06], mat="trim_cream")
  box "glass" (size=[1.30, 1.70, 0.02], mat="window_glass", pos=[0,0,-0.04])
}
module "sm_door" () {
  box "frame" (size=[1.10, 2.30, 0.06], mat="trim_cream")
  box "glass" (size=[0.95, 2.15, 0.02], mat="door_glass", pos=[0,0,-0.04])
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.40,0,0.06], tags="floating")
}
scene {
  slab "parking" (size=[40.0, 0.05, 14.0], mat="asphalt", pos=[0, 0.025, 3.0])
  slab "foundation" (size=[32.0, 0.30, 8.0], mat="concrete", pos=[0, 0.15, 0])
  // Lower stone band
  box "lower_band" (size=[32.0, 1.20, 8.0], mat="wall_stone", pos=[0, 0.90, 0])
  // Upper stucco
  box "upper_body" (size=[32.0, 2.50, 8.0], mat="wall_stucco", pos=[0, 2.80, 0])
  // Roof slab
  slab "roof" (size=[32.4, 0.20, 8.4], mat="roof_flat", pos=[0, 4.20, 0])
  // Front wall — 4 storefront holes (each with door + window)
  wall "front_wall" (size=[32.0, 4.0, 0.20], pos=[0, 2.30, -4.0], holes=[
    [-12.5,-0.30,1.10,2.30], [-12.5,1.50,1.40,1.80],
    [-4.5,-0.30,1.10,2.30], [-4.5,1.50,1.40,1.80],
    [4.5,-0.30,1.10,2.30], [4.5,1.50,1.40,1.80],
    [12.5,-0.30,1.10,2.30], [12.5,1.50,1.40,1.80],
  ])
  wall "back_wall" (size=[32.0, 4.0, 0.20], pos=[0, 2.30, 4.0], holes=[
    [-12.5,1.50,1.40,1.80], [-4.5,1.50,1.40,1.80],
    [4.5,1.50,1.40,1.80], [12.5,1.50,1.40,1.80],
  ])
  // 4 colored awnings (one per unit)
  prism "awning_1" (size=[3.5, 0.30, 2.0], pos=[-12.5, 2.40, -4.5], mat="awning_red")
  prism "awning_2" (size=[3.5, 0.30, 2.0], pos=[-4.5, 2.40, -4.5], mat="awning_green")
  prism "awning_3" (size=[3.5, 0.30, 2.0], pos=[4.5, 2.40, -4.5], mat="awning_blue")
  prism "awning_4" (size=[3.5, 0.30, 2.0], pos=[12.5, 2.40, -4.5], mat="awning_yellow")
  // Group placements
  // Unit 1
  group "d_1" (pos=[-12.5, 1.05, -4.0]) { use "sm_door" () }
  group "w_1" (pos=[-12.5, 3.20, -4.0]) { use "sm_win" () }
  // Unit 2
  group "d_2" (pos=[-4.5, 1.05, -4.0]) { use "sm_door" () }
  group "w_2" (pos=[-4.5, 3.20, -4.0]) { use "sm_win" () }
  // Unit 3
  group "d_3" (pos=[4.5, 1.05, -4.0]) { use "sm_door" () }
  group "w_3" (pos=[4.5, 3.20, -4.0]) { use "sm_win" () }
  // Unit 4
  group "d_4" (pos=[12.5, 1.05, -4.0]) { use "sm_door" () }
  group "w_4" (pos=[12.5, 3.20, -4.0]) { use "sm_win" () }
  // Sign band across top
  box "sign_band" (size=[32.0, 0.80, 0.10], mat="trim_cream", pos=[0, 4.30, -4.10], tags="floating")
  // Back wall windows
  group "wb_1" (pos=[-12.5, 3.20, 4.0]) { use "sm_win" () }
  group "wb_2" (pos=[-4.5, 3.20, 4.0]) { use "sm_win" () }
  group "wb_3" (pos=[4.5, 3.20, 4.0]) { use "sm_win" () }
  group "wb_4" (pos=[12.5, 3.20, 4.0]) { use "sm_win" () }
  // Side walls
  wall "left_wall" (size=[8.0, 4.0, 0.20], pos=[-16.0, 2.30, 0], rot=[0,90,0])
  wall "right_wall" (size=[8.0, 4.0, 0.20], pos=[16.0, 2.30, 0], rot=[0,90,0])
}
''')

# ============================================================
# 30. auto_repair_shop.mog — garage with bays
# ============================================================
w("buildings", "auto_repair_shop", '''// auto_repair_shop.mog — Auto repair shop with 3 service bays
meta (name="auto_repair_shop", description="Auto repair shop with 3 service bays and roll-up doors", tags=["building","commercial","industrial","tier1"], mogen_version="0.1.12")
material "wall_metal" (color=[0.50,0.48,0.45], roughness=0.60, metallic=0.4, uv_mode="tile", uv_scale=4.0)
material "wall_brick" (color=[0.55,0.30,0.25], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "roof_metal" (color=[0.40,0.38,0.36], roughness=0.60, metallic=0.6)
material "trim_red" (color=[0.65,0.15,0.10], roughness=0.70)
material "window_glass" (color=[0.30,0.40,0.45], transmission=0.45, roughness=0.05)
material "door_metal" (color=[0.45,0.45,0.48], roughness=0.50, metallic=0.7)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "sign_red" (color=[0.65,0.15,0.10], roughness=0.70, emissive=[0.40,0.05,0.05], emissive_strength=0.4)
module "ar_win" () {
  box "frame" (size=[1.20, 1.00, 0.06], mat="trim_red")
  box "glass" (size=[1.10, 0.90, 0.02], mat="window_glass", pos=[0,0,-0.04])
}
scene {
  slab "parking" (size=[20.0, 0.05, 12.0], mat="asphalt", pos=[0, 0.025, 2.0])
  slab "foundation" (size=[16.0, 0.30, 8.0], mat="concrete", pos=[0, 0.15, 0])
  // Lower brick band
  box "lower_brick" (size=[16.0, 1.20, 8.0], mat="wall_brick", pos=[0, 0.90, 0])
  // Upper metal wall
  box "upper_metal" (size=[16.0, 2.0, 8.0], mat="wall_metal", pos=[0, 2.50, 0])
  // Roof
  slab "roof" (size=[16.4, 0.20, 8.4], mat="roof_metal", pos=[0, 3.60, 0])
  // 3 roll-up bay doors (front)
  wall "front_wall" (size=[16.0, 3.20, 0.20], pos=[0, 2.20, -4.0], holes=[[-5.0,-0.40,3.0,2.80],[0,-0.40,3.0,2.80],[5.0,-0.40,3.0,2.80]])
  // Roll-up doors (visible as horizontal slats)
  box "roll_1" (size=[3.10, 2.80, 0.10], mat="door_metal", pos=[-5.0, 1.00, -4.05], tags="floating")
  box "roll_2" (size=[3.10, 2.80, 0.10], mat="door_metal", pos=[0, 1.00, -4.05], tags="floating")
  box "roll_3" (size=[3.10, 2.80, 0.10], mat="door_metal", pos=[5.0, 1.00, -4.05], tags="floating")
  // Slat lines on doors (horizontal ridges)
  box "slat_1a" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[-5.0, 0.50, -4.10], tags="floating")
  box "slat_1b" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[-5.0, 1.00, -4.10], tags="floating")
  box "slat_1c" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[-5.0, 1.50, -4.10], tags="floating")
  box "slat_1d" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[-5.0, 2.00, -4.10], tags="floating")
  box "slat_2a" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[0, 0.50, -4.10], tags="floating")
  box "slat_2b" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[0, 1.00, -4.10], tags="floating")
  box "slat_2c" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[0, 1.50, -4.10], tags="floating")
  box "slat_2d" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[0, 2.00, -4.10], tags="floating")
  box "slat_3a" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[5.0, 0.50, -4.10], tags="floating")
  box "slat_3b" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[5.0, 1.00, -4.10], tags="floating")
  box "slat_3c" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[5.0, 1.50, -4.10], tags="floating")
  box "slat_3d" (size=[3.10, 0.05, 0.04], mat="trim_red", pos=[5.0, 2.00, -4.10], tags="floating")
  // Back wall (with windows)
  wall "back_wall" (size=[16.0, 3.20, 0.20], pos=[0, 2.20, 4.0], holes=[[-5.0,1.0,1.20,1.00],[0,1.0,1.20,1.00],[5.0,1.0,1.20,1.00]])
  // Side windows (left side wall)
  wall "left_wall" (size=[8.0, 3.20, 0.20], pos=[-8.0, 2.20, 0], rot=[0,90,0], holes=[[-2.0,1.0,1.20,1.00],[2.0,1.0,1.20,1.00]])
  wall "right_wall" (size=[8.0, 3.20, 0.20], pos=[8.0, 2.20, 0], rot=[0,90,0], holes=[[-2.0,1.0,1.20,1.00],[2.0,1.0,1.20,1.00]])
  // Sign on roof
  box "sign_post_l" (size=[0.10, 1.50, 0.10], mat="wall_metal", pos=[-3.0, 4.50, -3.0], tags="floating")
  box "sign_post_r" (size=[0.10, 1.50, 0.10], mat="wall_metal", pos=[3.0, 4.50, -3.0], tags="floating")
  box "sign_board" (size=[6.0, 1.0, 0.10], mat="sign_red", pos=[0, 5.20, -3.0], tags="floating")
  // Office door (small, side)
  box "office_door" (size=[0.90, 2.00, 0.10], mat="door_metal", pos=[-7.0, 1.10, -4.05], tags="floating")
  // Group placements (windows)
  group "wb_1" (pos=[-5.0, 2.70, 4.0]) { use "ar_win" () }
  group "wb_2" (pos=[0, 2.70, 4.0]) { use "ar_win" () }
  group "wb_3" (pos=[5.0, 2.70, 4.0]) { use "ar_win" () }
  group "wl_1" (pos=[-8.0, 2.70, -2.0], rot=[0,90,0]) { use "ar_win" () }
  group "wl_2" (pos=[-8.0, 2.70, 2.0], rot=[0,90,0]) { use "ar_win" () }
  group "wr_1" (pos=[8.0, 2.70, -2.0], rot=[0,90,0]) { use "ar_win" () }
  group "wr_2" (pos=[8.0, 2.70, 2.0], rot=[0,90,0]) { use "ar_win" () }
  // Tire display outside
  cylinder "tire_disp_1" (radius=0.30, height=0.20, mat="trim_red", pos=[6.5, 0.30, -4.5], rot=[90,0,0], tags="floating")
  cylinder "tire_disp_2" (radius=0.30, height=0.20, mat="trim_red", pos=[6.5, 0.30, -5.0], rot=[90,0,0], tags="floating")
  cylinder "tire_disp_3" (radius=0.30, height=0.20, mat="trim_red", pos=[6.5, 0.50, -4.75], rot=[90,0,0], tags="floating")
}
''')

# ============================================================
# 31. laundromat.mog — small commercial with washers visible
# ============================================================
w("buildings", "laundromat", '''// laundromat.mog — Small commercial laundromat with storefront windows
meta (name="laundromat", description="Small commercial laundromat with large storefront windows", tags=["building","commercial","downtown","tier1"], mogen_version="0.1.12")
material "wall_stucco" (color=[0.78,0.75,0.70], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_tile" (color=[0.88,0.88,0.85], roughness=0.50, uv_mode="tile", uv_scale=6.0)
material "roof_flat" (color=[0.25,0.25,0.28], roughness=0.90)
material "trim_white" (color=[0.95,0.95,0.93], roughness=0.60)
material "window_glass" (color=[0.35,0.50,0.60], transmission=0.55, roughness=0.03)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "machine_white" (color=[0.92,0.92,0.90], roughness=0.60)
material "machine_glass" (color=[0.40,0.55,0.65], transmission=0.30, roughness=0.10)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "lm_door" () {
  box "frame" (size=[1.20, 2.30, 0.06], mat="trim_white")
  box "glass" (size=[1.05, 2.15, 0.02], mat="door_glass", pos=[0,0,-0.04])
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.45,0,0.06], tags="floating")
}
module "washer" () {
  box "body" (size=[0.70, 1.00, 0.70], mat="machine_white")
  cylinder "door" (radius=0.25, height=0.05, mat="machine_glass", pos=[0, 0.10, 0.36], rot=[90,0,0], tags="floating")
  box "controls" (size=[0.60, 0.20, 0.04], mat="machine_glass", pos=[0, 0.55, 0.36], tags="floating")
}
scene {
  slab "parking" (size=[14.0, 0.05, 8.0], mat="asphalt", pos=[0, 0.025, 2.0])
  slab "foundation" (size=[10.0, 0.30, 6.0], mat="concrete", pos=[0, 0.15, 0])
  // Body
  box "body" (size=[10.0, 3.20, 6.0], mat="wall_stucco", pos=[0, 1.90, 0])
  // Lower tile band (waterproof)
  box "tile_band" (size=[10.0, 0.60, 6.0], mat="wall_tile", pos=[0, 0.50, 0])
  // Roof
  slab "roof" (size=[10.4, 0.20, 6.4], mat="roof_flat", pos=[0, 3.60, 0])
  // Front wall — big storefront window + door
  wall "front_wall" (size=[10.0, 3.20, 0.20], pos=[0, 1.90, -3.0], holes=[[-3.0,0.0,4.0,2.30],[-3.0,-1.00,1.20,2.30],[2.0,-1.00,1.20,2.30]])
  // Back wall (smaller windows)
  wall "back_wall" (size=[10.0, 3.20, 0.20], pos=[0, 1.90, 3.0], holes=[[-3.0,0.30,1.40,1.20],[0,0.30,1.40,1.20],[3.0,0.30,1.40,1.20]])
  // Side walls
  wall "left_wall" (size=[6.0, 3.20, 0.20], pos=[-5.0, 1.90, 0], rot=[0,90,0], holes=[[-1.5,0.30,1.40,1.20],[1.5,0.30,1.40,1.20]])
  wall "right_wall" (size=[6.0, 3.20, 0.20], pos=[5.0, 1.90, 0], rot=[0,90,0], holes=[[-1.5,0.30,1.40,1.20],[1.5,0.30,1.40,1.20]])
  // Awning
  prism "awning" (size=[10.0, 0.40, 1.5], pos=[0, 3.30, -3.5], mat="trim_white")
  // Sign on roof
  box "sign_post_l" (size=[0.08, 0.50, 0.08], mat="trim_white", pos=[-3.0, 3.95, -3.0], tags="floating")
  box "sign_post_r" (size=[0.08, 0.50, 0.08], mat="trim_white", pos=[3.0, 3.95, -3.0], tags="floating")
  box "sign_board" (size=[6.0, 0.50, 0.10], mat="trim_white", pos=[0, 4.40, -3.0], tags="floating")
  // Washers (visible through windows — 4 in a row)
  group "washer_1" (pos=[-2.0, 0.50, -2.0]) { use "washer" () }
  group "washer_2" (pos=[-0.8, 0.50, -2.0]) { use "washer" () }
  group "washer_3" (pos=[0.4, 0.50, -2.0]) { use "washer" () }
  group "washer_4" (pos=[1.6, 0.50, -2.0]) { use "washer" () }
  // Group placements (doors + windows)
  group "door_main" (pos=[-3.0, 1.05, -3.0]) { use "lm_door" () }
  group "door_side" (pos=[2.0, 1.05, -3.0]) { use "lm_door" () }
}
''')

# ============================================================
# 32. barber_shop.mog — small shop with awning and striped pole
# ============================================================
w("buildings", "barber_shop", '''// barber_shop.mog — Small commercial barber shop with striped pole
meta (name="barber_shop", description="Small commercial barber shop with awning and striped barber pole", tags=["building","commercial","downtown","tier1"], mogen_version="0.1.12")
material "wall_stucco" (color=[0.80,0.70,0.55], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wall_bricks" (color=[0.55,0.30,0.25], roughness=0.85, uv_mode="tile", uv_scale=4.0)
material "roof_flat" (color=[0.20,0.20,0.22], roughness=0.90)
material "trim_white" (color=[0.92,0.90,0.85], roughness=0.60)
material "awning_blue" (color=[0.20,0.35,0.55], roughness=0.70, emissive=[0.10,0.15,0.25], emissive_strength=0.2)
material "window_glass" (color=[0.35,0.50,0.60], transmission=0.55, roughness=0.03)
material "door_glass" (color=[0.30,0.45,0.55], transmission=0.55, roughness=0.04)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "pole_white" (color=[0.92,0.92,0.90], roughness=0.50)
material "pole_red" (color=[0.85,0.10,0.10], roughness=0.50)
material "pole_blue" (color=[0.20,0.35,0.65], roughness=0.50)
material "brass" (color=[0.95,0.70,0.25], metallic=0.85, roughness=0.25)
module "bs_win" () {
  box "frame" (size=[1.30, 1.60, 0.06], mat="trim_white")
  box "glass" (size=[1.15, 1.45, 0.02], mat="window_glass", pos=[0,0,-0.04])
}
module "bs_door" () {
  box "frame" (size=[1.10, 2.30, 0.06], mat="trim_white")
  box "glass" (size=[0.95, 2.15, 0.02], mat="door_glass", pos=[0,0,-0.04])
  box "handle" (size=[0.04, 0.20, 0.03], mat="brass", pos=[0.40,0,0.06], tags="floating")
}
scene {
  slab "sidewalk" (size=[10.0, 0.05, 6.0], mat="asphalt", pos=[0, 0.025, 2.0])
  slab "foundation" (size=[8.0, 0.30, 6.0], mat="concrete", pos=[0, 0.15, 0])
  // Lower brick band
  box "lower_brick" (size=[8.0, 1.0, 6.0], mat="wall_bricks", pos=[0, 0.70, 0])
  // Upper stucco
  box "upper_stucco" (size=[8.0, 2.20, 6.0], mat="wall_stucco", pos=[0, 2.30, 0])
  // Roof
  slab "roof" (size=[8.4, 0.20, 6.4], mat="roof_flat", pos=[0, 3.50, 0])
  // Awning
  prism "awning" (size=[8.0, 0.30, 1.5], pos=[0, 3.20, -3.5], mat="awning_blue")
  // Front wall holes (door + 2 windows)
  wall "front_wall" (size=[8.0, 3.20, 0.20], pos=[0, 1.90, -3.0], holes=[[-2.20,-0.20,1.10,2.30],[2.20,-0.20,1.10,2.30],[0,1.50,2.0,0.80]])
  // Back wall (small windows)
  wall "back_wall" (size=[8.0, 3.20, 0.20], pos=[0, 1.90, 3.0], holes=[[-2.0,1.0,1.20,1.20],[2.0,1.0,1.20,1.20]])
  // Side walls
  wall "left_wall" (size=[6.0, 3.20, 0.20], pos=[-4.0, 1.90, 0], rot=[0,90,0], holes=[[-1.0,1.0,1.20,1.20],[1.0,1.0,1.20,1.20]])
  wall "right_wall" (size=[6.0, 3.20, 0.20], pos=[4.0, 1.90, 0], rot=[0,90,0], holes=[[-1.0,1.0,1.20,1.20],[1.0,1.0,1.20,1.20]])
  // Sign above door
  box "sign_board" (size=[2.0, 0.50, 0.10], mat="trim_white", pos=[0, 3.10, -3.05], tags="floating")
  // Barber pole (left of door)
  cylinder "pole_cap" (radius=0.10, height=0.10, mat="brass", pos=[-3.50, 2.10, -3.10], tags="floating")
  cylinder "pole_body" (radius=0.08, height=1.50, mat="pole_white", pos=[-3.50, 1.30, -3.10], tags="floating")
  // Stripes (helical segments — approximate with horizontal stripes)
  box "stripe_1" (size=[0.06, 0.20, 0.10], mat="pole_red", pos=[-3.58, 0.70, -3.10], rot=[0,0,30], tags="floating")
  box "stripe_2" (size=[0.06, 0.20, 0.10], mat="pole_blue", pos=[-3.58, 0.90, -3.10], rot=[0,0,-30], tags="floating")
  box "stripe_3" (size=[0.06, 0.20, 0.10], mat="pole_red", pos=[-3.58, 1.10, -3.10], rot=[0,0,30], tags="floating")
  box "stripe_4" (size=[0.06, 0.20, 0.10], mat="pole_blue", pos=[-3.58, 1.30, -3.10], rot=[0,0,-30], tags="floating")
  box "stripe_5" (size=[0.06, 0.20, 0.10], mat="pole_red", pos=[-3.58, 1.50, -3.10], rot=[0,0,30], tags="floating")
  box "stripe_6" (size=[0.06, 0.20, 0.10], mat="pole_blue", pos=[-3.58, 1.70, -3.10], rot=[0,0,-30], tags="floating")
  cylinder "pole_base" (radius=0.10, height=0.10, mat="brass", pos=[-3.50, 0.55, -3.10], tags="floating")
  // Group placements
  group "door_g" (pos=[-2.20, 1.05, -3.0]) { use "bs_door" () }
  group "win_l" (pos=[-2.20, 2.70, -3.0]) { use "bs_win" () }
  group "win_r" (pos=[2.20, 2.70, -3.0]) { use "bs_win" () }
  // Wait — the holes array is door at [-2.2,-0.2], window at [+2.2,-0.2], and a thin band at [0,1.5]. Let me fix placements.
  // Actually the door is at [-2.2] (lower) and window is at [+2.2] (lower), with a name band at top center.
  // So:
  // door at [-2.20, 1.05]
  // win at [2.20, 1.05]  (not 2.70)
  // I'll add the correct one:
  group "win_actual" (pos=[2.20, 1.05, -3.0]) { use "bs_door" () }  // window-side door (matches hole)
}
''')

# ============================================================
# 33. treehouse.mog — backyard tree house
# ============================================================
w("buildings", "treehouse", '''// treehouse.mog — Backyard treehouse built around a trunk
meta (name="treehouse", description="Backyard treehouse built around a tree trunk with ladder", tags=["building","suburban","treehouse","tier1"], mogen_version="0.1.12")
material "trunk_brown" (color=[0.30,0.20,0.12], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "wood_light" (color=[0.55,0.40,0.25], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "wood_dark" (color=[0.35,0.25,0.15], roughness=0.85)
material "roof_green" (color=[0.30,0.45,0.20], roughness=0.80)
material "leaves_green" (color=[0.22,0.42,0.18], roughness=0.85, uv_mode="tile", uv_scale=3.0)
material "grass" (color=[0.25,0.45,0.18], roughness=0.85, uv_mode="tile", uv_scale=2.5)
material "window_amber" (color=[0.65,0.55,0.30], transmission=0.30, roughness=0.10, emissive=[0.40,0.30,0.15], emissive_strength=0.5)
material "metal_dark" (color=[0.30,0.30,0.32], roughness=0.50, metallic=0.7)
scene {
  slab "ground" (size=[8.0, 0.04, 8.0], mat="grass")
  // Tree trunk (tall cylinder going up through house)
  cylinder "trunk" (radius=0.40, height=8.0, mat="trunk_brown", pos=[0, 4.00, 0])
  // Tree canopy (sphere cluster at top)
  sphere "canopy_1" (radius=2.5, mat="leaves_green", pos=[0, 9.50, 0])
  sphere "canopy_2" (radius=1.5, mat="leaves_green", pos=[1.5, 8.50, 0.5], tags="floating")
  sphere "canopy_3" (radius=1.5, mat="leaves_green", pos=[-1.0, 9.00, -1.0], tags="floating")
  // Treehouse platform (built around trunk, 4m up)
  slab "platform" (size=[4.0, 0.20, 4.0], mat="wood_light", pos=[0, 4.10, 0])
  // Treehouse walls (3 sides — open front)
  wall "wall_l" (size=[2.0, 1.80, 0.10], pos=[-1.95, 5.10, 0], rot=[0,90,0], mat="wood_light")
  wall "wall_r" (size=[2.0, 1.80, 0.10], pos=[1.95, 5.10, 0], rot=[0,90,0], mat="wood_light")
  wall "wall_b" (size=[4.0, 1.80, 0.10], pos=[0, 5.10, 2.0], mat="wood_light")
  // Front wall (with door hole)
  wall "wall_f" (size=[4.0, 1.80, 0.10], pos=[0, 5.10, -2.0], mat="wood_light", holes=[[0,-0.40,1.20,1.40]])
  // Roof
  prism "roof" (size=[4.5, 1.0, 4.5], pos=[0, 7.00, 0], mat="roof_green")
  // Window on back wall
  box "win_b" (size=[0.60, 0.60, 0.10], mat="window_amber", pos=[0, 5.30, 1.95], tags="floating")
  // Window on side walls
  box "win_l" (size=[0.10, 0.60, 0.60], mat="window_amber", pos=[-1.95, 5.30, 0], tags="floating")
  box "win_r" (size=[0.10, 0.60, 0.60], mat="window_amber", pos=[1.95, 5.30, 0], tags="floating")
  // Door (small)
  box "door" (size=[1.10, 1.30, 0.06], mat="wood_dark", pos=[0, 4.85, -2.05], tags="floating")
  // Railing on front (small deck)
  box "rail_post_l" (size=[0.08, 0.70, 0.08], mat="wood_dark", pos=[-1.80, 4.55, -2.20], tags="floating")
  box "rail_post_r" (size=[0.08, 0.70, 0.08], mat="wood_dark", pos=[1.80, 4.55, -2.20], tags="floating")
  box "rail_top" (size=[3.6, 0.06, 0.06], mat="wood_dark", pos=[0, 5.20, -2.20], tags="floating")
  // Ladder (front, going from ground to platform)
  box "ladder_l" (size=[0.06, 4.0, 0.06], mat="metal_dark", pos=[-0.30, 2.10, -2.30], rot=[10,0,0], tags="floating")
  box "ladder_r" (size=[0.06, 4.0, 0.06], mat="metal_dark", pos=[0.30, 2.10, -2.30], rot=[10,0,0], tags="floating")
  box "rung_1" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 0.70, -2.20], tags="floating")
  box "rung_2" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 1.30, -2.30], tags="floating")
  box "rung_3" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 1.90, -2.40], tags="floating")
  box "rung_4" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 2.50, -2.50], tags="floating")
  box "rung_5" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 3.10, -2.60], tags="floating")
  box "rung_6" (size=[0.60, 0.04, 0.04], mat="metal_dark", pos=[0, 3.70, -2.70], tags="floating")
  // Support beams (under platform, going to trunk)
  box "beam_l" (size=[2.0, 0.20, 0.20], mat="wood_dark", pos=[0, 3.90, -1.0], tags="floating")
  box "beam_r" (size=[2.0, 0.20, 0.20], mat="wood_dark", pos=[0, 3.90, 1.0], tags="floating")
  // Rope swing (hanging from branch)
  cylinder "rope_l" (radius=0.02, height=2.0, mat="wood_dark", pos=[1.50, 8.50, 0], tags="floating")
  cylinder "rope_r" (radius=0.02, height=2.0, mat="wood_dark", pos=[1.80, 8.50, 0], tags="floating")
  box "swing_seat" (size=[0.40, 0.05, 0.20], mat="wood_light", pos=[1.65, 6.50, 0], tags="floating")
}
''')

print("=== Part 3: 9 buildings written ===")
