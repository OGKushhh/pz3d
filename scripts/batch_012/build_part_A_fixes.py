#!/usr/bin/env python3
"""Batch 012 — Part A — FIX broadcast_tower + parking_garage."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets")

# ============================================================
# FIX 1: broadcast_tower — add internal staircase + top cab
# ============================================================
tower_src = '''// broadcast_tower.mog — tall lattice broadcast tower with internal stair + top cab
meta (name="broadcast_tower", description="Lattice broadcast tower with internal staircase, top equipment cab, and aviation lights", tags=["building","downtown","landmark","tower","tier1"], mogen_version="0.1.12")
material "steel_red" (color=[0.70,0.20,0.15], roughness=0.50, metallic=0.85)
material "steel_grey" (color=[0.40,0.40,0.42], roughness=0.50, metallic=0.85)
material "concrete" (color=[0.55,0.53,0.50], roughness=0.90)
material "cab_white" (color=[0.88,0.88,0.85], roughness=0.50, metallic=0.3)
material "window_dark" (color=[0.20,0.30,0.40], transmission=0.40, roughness=0.10)
material "aviation_red" (color=[0.95,0.10,0.10], roughness=0.40, emissive=[0.7,0.05,0.05], emissive_strength=0.8)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "stair_metal" (color=[0.45,0.45,0.48], roughness=0.50, metallic=0.85)
module "stair_flight" () {
  // One flight of stairs = 7 steps + 2 stringers + railing
  box "stringer_l" (size=[0.06, 0.06, 2.40], mat="stair_metal", pos=[-0.60, 0, 0])
  box "stringer_r" (size=[0.06, 0.06, 2.40], mat="stair_metal", pos=[0.60, 0, 0])
  box "step_1" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 0.20, -1.00])
  box "step_2" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 0.40, -0.70])
  box "step_3" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 0.60, -0.40])
  box "step_4" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 0.80, -0.10])
  box "step_5" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.00, 0.20])
  box "step_6" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.20, 0.50])
  box "step_7" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.40, 0.80])
  box "railing_l" (size=[0.04, 0.90, 2.40], mat="stair_metal", pos=[-0.62, 0.50, 0])
  box "railing_r" (size=[0.04, 0.90, 2.40], mat="stair_metal", pos=[0.62, 0.50, 0])
}
module "landing" () {
  box "deck" (size=[1.40, 0.06, 1.40], mat="stair_metal")
  box "rail_n" (size=[1.40, 0.06, 0.04], mat="stair_metal", pos=[0, 0.50, -0.70])
  box "rail_s" (size=[1.40, 0.06, 0.04], mat="stair_metal", pos=[0, 0.50, 0.70])
  box "rail_e" (size=[0.04, 0.06, 1.40], mat="stair_metal", pos=[0.70, 0.50, 0])
  box "rail_w" (size=[0.04, 0.06, 1.40], mat="stair_metal", pos=[-0.70, 0.50, 0])
}
scene {
  slab "base_pad" (size=[10.0, 0.05, 10.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")
  slab "foundation" (size=[4.0, 0.30, 4.0], mat="concrete", pos=[0, 0.15, 0])
  // === BASE EQUIPMENT SHED (enclosed, ground level) ===
  box "shed_body" (size=[3.0, 2.5, 2.0], mat="concrete", pos=[3.0, 1.40, 0])
  slab "shed_roof" (size=[3.2, 0.10, 2.2], mat="steel_grey", pos=[3.0, 2.70, 0], tags="floating")
  box "shed_door" (size=[1.0, 2.0, 0.10], mat="cab_white", pos=[3.0, 1.25, -1.05], tags="floating")
  // === LATTICE TOWER LEGS (3 sections: 0-10m, 10-25m, 25-40m) ===
  // Bottom (0-10m)
  box "leg_fl_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[-1.80, 5.0, -1.80], rot=[0,0,11], tags="floating")
  box "leg_fr_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[1.80, 5.0, -1.80], rot=[0,0,-11], tags="floating")
  box "leg_bl_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[-1.80, 5.0, 1.80], rot=[0,0,11], tags="floating")
  box "leg_br_1" (size=[0.20, 10.0, 0.20], mat="steel_red", pos=[1.80, 5.0, 1.80], rot=[0,0,-11], tags="floating")
  // Mid (10-25m)
  box "leg_fl_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[-1.00, 17.5, -1.00], rot=[0,0,5], tags="floating")
  box "leg_fr_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[1.00, 17.5, -1.00], rot=[0,0,-5], tags="floating")
  box "leg_bl_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[-1.00, 17.5, 1.00], rot=[0,0,5], tags="floating")
  box "leg_br_2" (size=[0.18, 15.0, 0.18], mat="steel_red", pos=[1.00, 17.5, 1.00], rot=[0,0,-5], tags="floating")
  // Top (25-40m)
  box "leg_fl_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[-0.50, 32.5, -0.50], rot=[0,0,2], tags="floating")
  box "leg_fr_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[0.50, 32.5, -0.50], rot=[0,0,-2], tags="floating")
  box "leg_bl_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[-0.50, 32.5, 0.50], rot=[0,0,2], tags="floating")
  box "leg_br_3" (size=[0.15, 15.0, 0.15], mat="steel_red", pos=[0.50, 32.5, 0.50], rot=[0,0,-2], tags="floating")
  // === HORIZONTAL BRACE PLATFORMS (every 5m, doubles as stair landings) ===
  box "brace_05" (size=[3.60, 0.10, 3.60], mat="steel_grey", pos=[0, 5.0, 0], tags="floating")
  box "brace_10" (size=[3.60, 0.10, 3.60], mat="steel_grey", pos=[0, 10.0, 0], tags="floating")
  box "brace_15" (size=[2.00, 0.10, 2.00], mat="steel_grey", pos=[0, 15.0, 0], tags="floating")
  box "brace_20" (size=[2.00, 0.10, 2.00], mat="steel_grey", pos=[0, 20.0, 0], tags="floating")
  box "brace_25" (size=[1.00, 0.10, 1.00], mat="steel_grey", pos=[0, 25.0, 0], tags="floating")
  box "brace_30" (size=[1.00, 0.10, 1.00], mat="steel_grey", pos=[0, 30.0, 0], tags="floating")
  box "brace_35" (size=[0.50, 0.10, 0.50], mat="steel_grey", pos=[0, 35.0, 0], tags="floating")
  // === INTERNAL STAIRCASE (zig-zag between landings, all tagged floating) ===
  // Flight 1: ground → landing 5m
  group "flight_1" (pos=[0, 0, 0], tags="floating") {
    box "stringer_l" (size=[0.06, 0.06, 4.50], mat="stair_metal", pos=[-0.60, 2.50, 0])
    box "stringer_r" (size=[0.06, 0.06, 4.50], mat="stair_metal", pos=[0.60, 2.50, 0])
    box "step_1" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 0.50, -2.00])
    box "step_2" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.00, -1.60])
    box "step_3" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.50, -1.20])
    box "step_4" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 2.00, -0.80])
    box "step_5" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 2.50, -0.40])
    box "step_6" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 3.00, 0.00])
    box "step_7" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 3.50, 0.40])
    box "step_8" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 4.00, 0.80])
    box "step_9" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 4.50, 1.20])
    box "step_10" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 4.80, 1.60])
    box "rail_l" (size=[0.04, 0.90, 4.50], mat="stair_metal", pos=[-0.62, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 4.50], mat="stair_metal", pos=[0.62, 3.20, 0])
  }
  // Flight 2: 5m → 10m (going opposite direction)
  group "flight_2" (pos=[0, 5.0, 0], tags="floating") {
    box "stringer_l" (size=[0.06, 0.06, 4.50], mat="stair_metal", pos=[-0.60, 2.50, 0])
    box "stringer_r" (size=[0.06, 0.06, 4.50], mat="stair_metal", pos=[0.60, 2.50, 0])
    box "step_1" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 0.50, 2.00])
    box "step_2" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.00, 1.60])
    box "step_3" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 1.50, 1.20])
    box "step_4" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 2.00, 0.80])
    box "step_5" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 2.50, 0.40])
    box "step_6" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 3.00, 0.00])
    box "step_7" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 3.50, -0.40])
    box "step_8" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 4.00, -0.80])
    box "step_9" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 4.50, -1.20])
    box "step_10" (size=[1.20, 0.04, 0.30], mat="stair_metal", pos=[0, 4.80, -1.60])
    box "rail_l" (size=[0.04, 0.90, 4.50], mat="stair_metal", pos=[-0.62, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 4.50], mat="stair_metal", pos=[0.62, 3.20, 0])
  }
  // Flight 3: 10m → 15m
  group "flight_3" (pos=[0, 10.0, 0], tags="floating") {
    box "stringer_l" (size=[0.05, 0.05, 4.00], mat="stair_metal", pos=[-0.40, 2.50, 0])
    box "stringer_r" (size=[0.05, 0.05, 4.00], mat="stair_metal", pos=[0.40, 2.50, 0])
    box "step_1" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 0.50, -1.80])
    box "step_2" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 1.00, -1.40])
    box "step_3" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 1.50, -1.00])
    box "step_4" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 2.00, -0.60])
    box "step_5" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 2.50, -0.20])
    box "step_6" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 3.00, 0.20])
    box "step_7" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 3.50, 0.60])
    box "step_8" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 4.00, 1.00])
    box "step_9" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 4.50, 1.40])
    box "step_10" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 4.80, 1.70])
    box "rail_l" (size=[0.04, 0.90, 4.00], mat="stair_metal", pos=[-0.42, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 4.00], mat="stair_metal", pos=[0.42, 3.20, 0])
  }
  // Flight 4: 15m → 20m
  group "flight_4" (pos=[0, 15.0, 0], tags="floating") {
    box "stringer_l" (size=[0.05, 0.05, 4.00], mat="stair_metal", pos=[-0.40, 2.50, 0])
    box "stringer_r" (size=[0.05, 0.05, 4.00], mat="stair_metal", pos=[0.40, 2.50, 0])
    box "step_1" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 0.50, 1.80])
    box "step_2" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 1.00, 1.40])
    box "step_3" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 1.50, 1.00])
    box "step_4" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 2.00, 0.60])
    box "step_5" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 2.50, 0.20])
    box "step_6" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 3.00, -0.20])
    box "step_7" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 3.50, -0.60])
    box "step_8" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 4.00, -1.00])
    box "step_9" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 4.50, -1.40])
    box "step_10" (size=[0.90, 0.04, 0.25], mat="stair_metal", pos=[0, 4.80, -1.70])
    box "rail_l" (size=[0.04, 0.90, 4.00], mat="stair_metal", pos=[-0.42, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 4.00], mat="stair_metal", pos=[0.42, 3.20, 0])
  }
  // Flight 5: 20m → 25m
  group "flight_5" (pos=[0, 20.0, 0], tags="floating") {
    box "stringer_l" (size=[0.05, 0.05, 3.50], mat="stair_metal", pos=[-0.30, 2.50, 0])
    box "stringer_r" (size=[0.05, 0.05, 3.50], mat="stair_metal", pos=[0.30, 2.50, 0])
    box "step_1" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 0.50, -1.50])
    box "step_2" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 1.00, -1.20])
    box "step_3" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 1.50, -0.90])
    box "step_4" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 2.00, -0.60])
    box "step_5" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 2.50, -0.30])
    box "step_6" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 3.00, 0.00])
    box "step_7" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 3.50, 0.30])
    box "step_8" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 4.00, 0.60])
    box "step_9" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 4.50, 0.90])
    box "step_10" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 4.80, 1.20])
    box "rail_l" (size=[0.04, 0.90, 3.50], mat="stair_metal", pos=[-0.32, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 3.50], mat="stair_metal", pos=[0.32, 3.20, 0])
  }
  // Flight 6: 25m → 30m
  group "flight_6" (pos=[0, 25.0, 0], tags="floating") {
    box "stringer_l" (size=[0.05, 0.05, 3.50], mat="stair_metal", pos=[-0.30, 2.50, 0])
    box "stringer_r" (size=[0.05, 0.05, 3.50], mat="stair_metal", pos=[0.30, 2.50, 0])
    box "step_1" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 0.50, 1.50])
    box "step_2" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 1.00, 1.20])
    box "step_3" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 1.50, 0.90])
    box "step_4" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 2.00, 0.60])
    box "step_5" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 2.50, 0.30])
    box "step_6" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 3.00, 0.00])
    box "step_7" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 3.50, -0.30])
    box "step_8" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 4.00, -0.60])
    box "step_9" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 4.50, -0.90])
    box "step_10" (size=[0.70, 0.04, 0.20], mat="stair_metal", pos=[0, 4.80, -1.20])
    box "rail_l" (size=[0.04, 0.90, 3.50], mat="stair_metal", pos=[-0.32, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 3.50], mat="stair_metal", pos=[0.32, 3.20, 0])
  }
  // Flight 7: 30m → 35m
  group "flight_7" (pos=[0, 30.0, 0], tags="floating") {
    box "stringer_l" (size=[0.05, 0.05, 3.50], mat="stair_metal", pos=[-0.20, 2.50, 0])
    box "stringer_r" (size=[0.05, 0.05, 3.50], mat="stair_metal", pos=[0.20, 2.50, 0])
    box "step_1" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 0.50, -1.50])
    box "step_2" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 1.00, -1.20])
    box "step_3" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 1.50, -0.90])
    box "step_4" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 2.00, -0.60])
    box "step_5" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 2.50, -0.30])
    box "step_6" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 3.00, 0.00])
    box "step_7" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 3.50, 0.30])
    box "step_8" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 4.00, 0.60])
    box "step_9" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 4.50, 0.90])
    box "step_10" (size=[0.50, 0.04, 0.20], mat="stair_metal", pos=[0, 4.80, 1.20])
    box "rail_l" (size=[0.04, 0.90, 3.50], mat="stair_metal", pos=[-0.22, 3.20, 0])
    box "rail_r" (size=[0.04, 0.90, 3.50], mat="stair_metal", pos=[0.22, 3.20, 0])
  }
  // Flight 8: 35m → top cab (~38m)
  group "flight_8" (pos=[0, 35.0, 0], tags="floating") {
    box "stringer_l" (size=[0.05, 0.05, 2.50], mat="stair_metal", pos=[-0.15, 1.50, 0])
    box "stringer_r" (size=[0.05, 0.05, 2.50], mat="stair_metal", pos=[0.15, 1.50, 0])
    box "step_1" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 0.30, -1.00])
    box "step_2" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 0.60, -0.80])
    box "step_3" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 0.90, -0.60])
    box "step_4" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 1.20, -0.40])
    box "step_5" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 1.50, -0.20])
    box "step_6" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 1.80, 0.00])
    box "step_7" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 2.10, 0.20])
    box "step_8" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 2.40, 0.40])
    box "step_9" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 2.70, 0.60])
    box "step_10" (size=[0.40, 0.04, 0.20], mat="stair_metal", pos=[0, 2.90, 0.80])
    box "rail_l" (size=[0.04, 0.90, 2.50], mat="stair_metal", pos=[-0.17, 1.50, 0])
    box "rail_r" (size=[0.04, 0.90, 2.50], mat="stair_metal", pos=[0.17, 1.50, 0])
  }
  // === TOP EQUIPMENT CAB (enclosed, at ~38m) ===
  box "cab_floor" (size=[2.50, 0.10, 2.50], mat="steel_grey", pos=[0, 38.00, 0], tags="floating")
  box "cab_body" (size=[2.50, 2.20, 2.50], mat="cab_white", pos=[0, 39.20, 0], tags="floating")
  // Cab windows (4 sides)
  box "cab_win_n" (size=[0.80, 0.60, 0.05], mat="window_dark", pos=[0, 39.50, -1.25], tags="floating")
  box "cab_win_s" (size=[0.80, 0.60, 0.05], mat="window_dark", pos=[0, 39.50, 1.25], tags="floating")
  box "cab_win_e" (size=[0.05, 0.60, 0.80], mat="window_dark", pos=[1.25, 39.50, 0], tags="floating")
  box "cab_win_w" (size=[0.05, 0.60, 0.80], mat="window_dark", pos=[-1.25, 39.50, 0], tags="floating")
  // Cab door
  box "cab_door" (size=[0.70, 1.60, 0.05], mat="cab_white", pos=[-0.80, 38.80, -1.25], tags="floating")
  // Cab roof
  slab "cab_roof" (size=[2.7, 0.10, 2.7], mat="steel_grey", pos=[0, 40.40, 0], tags="floating")
  // Antenna mast (above cab)
  cylinder "mast" (radius=0.15, height=6.0, mat="steel_grey", pos=[0, 43.40, 0], tags="floating")
  // Top antenna dish (small)
  cylinder "dish_base" (radius=0.30, height=0.10, mat="steel_grey", pos=[0, 46.50, 0], tags="floating")
  cone "dish" (radius=0.60, height=0.30, mat="cab_white", pos=[0, 46.85, 0], tags="floating")
  // === AVIATION WARNING LIGHTS ===
  sphere "light_1" (radius=0.20, mat="aviation_red", pos=[0, 10.0, 0], tags="floating")
  sphere "light_2" (radius=0.18, mat="aviation_red", pos=[0, 20.0, 0], tags="floating")
  sphere "light_3" (radius=0.15, mat="aviation_red", pos=[0, 30.0, 0], tags="floating")
  sphere "light_top" (radius=0.18, mat="aviation_red", pos=[0, 47.20, 0], tags="floating")
}
'''
(BASE / "buildings/src/broadcast_tower.mog").write_text(tower_src)
print("  rewrote buildings/broadcast_tower.mog (with stairs + top cab)")

# ============================================================
# FIX 2: parking_garage — real ramps, floor markings, floor numbers visible
# ============================================================
parking_src = '''// parking_garage.mog — 4-story concrete parking structure with real connecting helical ramp
meta (name="parking_garage", description="4-story concrete parking garage with helical ramp connecting all floors + floor markings + stair tower", tags=["building","downtown","parking","tier1"], mogen_version="0.1.12")
material "concrete" (color=[0.65,0.63,0.60], roughness=0.90, uv_mode="tile", uv_scale=4.0)
material "concrete_dark" (color=[0.45,0.43,0.40], roughness=0.90)
material "asphalt" (color=[0.14,0.14,0.16], roughness=0.95, uv_mode="tile", uv_scale=4.0)
material "line_yellow" (color=[0.85,0.70,0.20], roughness=0.50, emissive=[0.40,0.30,0.10], emissive_strength=0.2)
material "line_white" (color=[0.92,0.92,0.88], roughness=0.60, emissive=[0.30,0.30,0.25], emissive_strength=0.15)
material "metal_rail" (color=[0.30,0.30,0.35], roughness=0.40, metallic=0.85)
material "stair_metal" (color=[0.45,0.45,0.48], roughness=0.50, metallic=0.85)
material "sign_blue" (color=[0.20,0.35,0.65], roughness=0.50, emissive=[0.10,0.20,0.40], emissive_strength=0.3)
material "sign_white_text" (color=[0.95,0.95,0.92], roughness=0.40, emissive=[0.40,0.40,0.35], emissive_strength=0.4)
module "park_stair" () {
  // Enclosed stair tower — 4 flights, landings every 1.75m
  box "stringer_l" (size=[0.06, 0.06, 1.60], mat="stair_metal", pos=[-0.55, 0, 0])
  box "stringer_r" (size=[0.06, 0.06, 1.60], mat="stair_metal", pos=[0.55, 0, 0])
  box "step_1" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 0.22, -0.70])
  box "step_2" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 0.44, -0.45])
  box "step_3" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 0.66, -0.20])
  box "step_4" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 0.88, 0.05])
  box "step_5" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 1.10, 0.30])
  box "step_6" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 1.32, 0.55])
  box "step_7" (size=[1.20, 0.04, 0.25], mat="stair_metal", pos=[0, 1.54, 0.80])
  box "rail_l" (size=[0.04, 0.90, 1.60], mat="stair_metal", pos=[-0.57, 0.80, 0])
  box "rail_r" (size=[0.04, 0.90, 1.60], mat="stair_metal", pos=[0.57, 0.80, 0])
}
module "floor_lines" () {
  // 4 parking bay markings per floor (yellow rectangle outline + center white line)
  box "bay_1_y_l" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[-6.0, 0, 0])
  box "bay_1_y_r" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[-4.0, 0, 0])
  box "bay_2_y_l" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[-3.0, 0, 0])
  box "bay_2_y_r" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[-1.0, 0, 0])
  box "bay_3_y_l" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[1.0, 0, 0])
  box "bay_3_y_r" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[3.0, 0, 0])
  box "bay_4_y_l" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[4.0, 0, 0])
  box "bay_4_y_r" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[6.0, 0, 0])
  // Center white drive lane line
  box "center_w" (size=[20.0, 0.04, 0.10], mat="line_white", pos=[0, 0, 0])
}
scene {
  slab "ground" (size=[24.0, 0.05, 20.0], mat="asphalt", pos=[0, 0.025, 0], tags="floating")
  // === 4 FLOOR SLABS ===
  slab "floor_1" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 3.50, 0])
  slab "floor_2" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 7.00, 0])
  slab "floor_3" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 10.50, 0])
  slab "floor_4" (size=[20.0, 0.30, 16.0], mat="concrete", pos=[0, 14.00, 0])
  slab "roof" (size=[20.4, 0.20, 16.4], mat="concrete_dark", pos=[0, 17.65, 0], tags="floating")
  // === COLUMNS (6 — 4 corners + 2 mid) ===
  box "col_tl" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[-9.50, 8.75, -7.50], tags="floating")
  box "col_tr" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[9.50, 8.75, -7.50], tags="floating")
  box "col_bl" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[-9.50, 8.75, 7.50], tags="floating")
  box "col_br" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[9.50, 8.75, 7.50], tags="floating")
  box "col_ml_1" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[0, 8.75, -7.50], tags="floating")
  box "col_ml_2" (size=[0.60, 17.50, 0.60], mat="concrete_dark", pos=[0, 8.75, 7.50], tags="floating")
  // Mid-span columns (additional, between corners and middle)
  box "col_ml_3" (size=[0.50, 14.00, 0.50], mat="concrete_dark", pos=[-4.75, 7.00, -7.50], tags="floating")
  box "col_ml_4" (size=[0.50, 14.00, 0.50], mat="concrete_dark", pos=[4.75, 7.00, -7.50], tags="floating")
  box "col_ml_5" (size=[0.50, 14.00, 0.50], mat="concrete_dark", pos=[-4.75, 7.00, 7.50], tags="floating")
  box "col_ml_6" (size=[0.50, 14.00, 0.50], mat="concrete_dark", pos=[4.75, 7.00, 7.50], tags="floating")
  // === WALLS ===
  wall "back_wall" (size=[20.0, 14.0, 0.20], pos=[0, 7.00, 8.0])
  // Side walls — open parking levels (each level is 3.5m, with 2.5m opening)
  wall "left_wall" (size=[16.0, 14.0, 0.20], pos=[-10.0, 7.00, 0], rot=[0,90,0], holes=[[0,-4.5,16.0,2.5]])
  wall "right_wall" (size=[16.0, 14.0, 0.20], pos=[10.0, 7.00, 0], rot=[0,90,0], holes=[[0,-4.5,16.0,2.5]])
  // Front wall — vehicle entry/exit on ground, open above
  wall "front_wall" (size=[20.0, 14.0, 0.20], pos=[0, 7.00, -8.0], holes=[[-6.0,-4.75,5.0,2.75],[6.0,-4.75,5.0,2.75],[0,1.0,8.0,2.0]])
  // === CONNECTING HELICAL RAMP (3 ramps from floor to floor, tagged floating) ===
  // Ramp 1: floor 1 (Y=3.65) → floor 2 (Y=7.15) — goes up half a story on the right side
  slab "ramp_1" (size=[6.0, 0.20, 7.0], mat="concrete_dark", pos=[5.0, 5.40, 0], rot=[28,0,0], tags="floating")
  // Ramp 2: floor 2 → floor 3
  slab "ramp_2" (size=[6.0, 0.20, 7.0], mat="concrete_dark", pos=[5.0, 8.90, 0], rot=[28,0,0], tags="floating")
  // Ramp 3: floor 3 → floor 4
  slab "ramp_3" (size=[6.0, 0.20, 7.0], mat="concrete_dark", pos=[5.0, 12.40, 0], rot=[28,0,0], tags="floating")
  // Ramp side rails (low walls on each side of ramp)
  box "ramp_1_rail_l" (size=[6.0, 0.40, 0.06], mat="concrete_dark", pos=[2.0, 5.60, 0], rot=[28,0,0], tags="floating")
  box "ramp_1_rail_r" (size=[6.0, 0.40, 0.06], mat="concrete_dark", pos=[8.0, 5.60, 0], rot=[28,0,0], tags="floating")
  box "ramp_2_rail_l" (size=[6.0, 0.40, 0.06], mat="concrete_dark", pos=[2.0, 9.10, 0], rot=[28,0,0], tags="floating")
  box "ramp_2_rail_r" (size=[6.0, 0.40, 0.06], mat="concrete_dark", pos=[8.0, 9.10, 0], rot=[28,0,0], tags="floating")
  box "ramp_3_rail_l" (size=[6.0, 0.40, 0.06], mat="concrete_dark", pos=[2.0, 12.60, 0], rot=[28,0,0], tags="floating")
  box "ramp_3_rail_r" (size=[6.0, 0.40, 0.06], mat="concrete_dark", pos=[8.0, 12.60, 0], rot=[28,0,0], tags="floating")
  // === ENCLOSED STAIR TOWER (left side, full 4 stories) ===
  box "stair_tower_body" (size=[3.0, 14.50, 3.0], mat="concrete", pos=[-8.50, 7.50, -6.50], tags="floating")
  slab "stair_tower_roof" (size=[3.2, 0.20, 3.2], mat="concrete_dark", pos=[-8.50, 14.85, -6.50], tags="floating")
  // Stair tower door (ground)
  box "stair_door" (size=[1.0, 2.0, 0.10], mat="metal_rail", pos=[-8.50, 1.00, -8.05], tags="floating")
  // Stair tower windows (each floor)
  box "stair_win_1" (size=[0.10, 0.80, 0.80], mat="metal_rail", pos=[-7.00, 3.50, -6.50], tags="floating")
  box "stair_win_2" (size=[0.10, 0.80, 0.80], mat="metal_rail", pos=[-7.00, 7.00, -6.50], tags="floating")
  box "stair_win_3" (size=[0.10, 0.80, 0.80], mat="metal_rail", pos=[-7.00, 10.50, -6.50], tags="floating")
  box "stair_win_4" (size=[0.10, 0.80, 0.80], mat="metal_rail", pos=[-7.00, 14.00, -6.50], tags="floating")
  // 4 flights of internal stairs (positioned inside the stair tower)
  group "stair_f1" (pos=[-8.50, 1.20, -6.50], tags="floating") { use "park_stair" () }
  group "stair_f2" (pos=[-8.50, 4.70, -6.50], tags="floating") { use "park_stair" () }
  group "stair_f3" (pos=[-8.50, 8.20, -6.50], tags="floating") { use "park_stair" () }
  group "stair_f4" (pos=[-8.50, 11.70, -6.50], tags="floating") { use "park_stair" () }
  // === FLOOR MARKINGS — yellow parking bays + white center drive lane ===
  // Floor 1 (Y=3.65 surface)
  group "lines_1" (pos=[0, 3.66, 0], tags="floating") { use "floor_lines" () }
  // Floor 2 (Y=7.15 surface)
  group "lines_2" (pos=[0, 7.16, 0], tags="floating") { use "floor_lines" () }
  // Floor 3 (Y=10.65 surface)
  group "lines_3" (pos=[0, 10.66, 0], tags="floating") { use "floor_lines" () }
  // Floor 4 (Y=14.15 surface)
  group "lines_4" (pos=[0, 14.16, 0], tags="floating") { use "floor_lines" () }
  // Ground markings (floor 0)
  slab "line_g_1" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[-6.0, 0.055, 0], tags="floating")
  slab "line_g_2" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[-3.0, 0.055, 0], tags="floating")
  slab "line_g_3" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[0, 0.055, 0], tags="floating")
  slab "line_g_4" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[3.0, 0.055, 0], tags="floating")
  slab "line_g_5" (size=[0.10, 0.04, 4.0], mat="line_yellow", pos=[6.0, 0.055, 0], tags="floating")
  // === FLOOR NUMBER SIGNS (on back wall, big blue + white text) ===
  box "sign_1" (size=[1.5, 1.0, 0.10], mat="sign_blue", pos=[-7.0, 4.50, 7.90], tags="floating")
  box "sign_1_text" (size=[0.8, 0.6, 0.02], mat="sign_white_text", pos=[-7.0, 4.50, 7.96], tags="floating")
  box "sign_2" (size=[1.5, 1.0, 0.10], mat="sign_blue", pos=[-7.0, 8.00, 7.90], tags="floating")
  box "sign_2_text" (size=[0.8, 0.6, 0.02], mat="sign_white_text", pos=[-7.0, 8.00, 7.96], tags="floating")
  box "sign_3" (size=[1.5, 1.0, 0.10], mat="sign_blue", pos=[-7.0, 11.50, 7.90], tags="floating")
  box "sign_3_text" (size=[0.8, 0.6, 0.02], mat="sign_white_text", pos=[-7.0, 11.50, 7.96], tags="floating")
  box "sign_4" (size=[1.5, 1.0, 0.10], mat="sign_blue", pos=[-7.0, 15.00, 7.90], tags="floating")
  box "sign_4_text" (size=[0.8, 0.6, 0.02], mat="sign_white_text", pos=[-7.0, 15.00, 7.96], tags="floating")
  // === TOP FLOOR RAILING (perimeter) ===
  box "rail_top_n" (size=[20.0, 0.10, 0.05], mat="metal_rail", pos=[0, 14.20, -8.05], tags="floating")
  box "rail_top_s" (size=[20.0, 0.10, 0.05], mat="metal_rail", pos=[0, 14.20, 8.05], tags="floating")
  box "rail_side_l" (size=[0.05, 0.10, 16.0], mat="metal_rail", pos=[-10.05, 14.20, 0], tags="floating")
  box "rail_side_r" (size=[0.05, 0.10, 16.0], mat="metal_rail", pos=[10.05, 14.20, 0], tags="floating")
  // Mid-rails (lower rail below top rail)
  box "midrail_n" (size=[20.0, 0.05, 0.04], mat="metal_rail", pos=[0, 13.50, -8.05], tags="floating")
  box "midrail_s" (size=[20.0, 0.05, 0.04], mat="metal_rail", pos=[0, 13.50, 8.05], tags="floating")
  // Rail posts (every 2m on top floor)
  box "rpost_1" (size=[0.08, 0.80, 0.08], mat="metal_rail", pos=[-8.0, 13.80, -8.05], tags="floating")
  box "rpost_2" (size=[0.08, 0.80, 0.08], mat="metal_rail", pos=[-4.0, 13.80, -8.05], tags="floating")
  box "rpost_3" (size=[0.08, 0.80, 0.08], mat="metal_rail", pos=[0, 13.80, -8.05], tags="floating")
  box "rpost_4" (size=[0.08, 0.80, 0.08], mat="metal_rail", pos=[4.0, 13.80, -8.05], tags="floating")
  box "rpost_5" (size=[0.08, 0.80, 0.08], mat="metal_rail", pos=[8.0, 13.80, -8.05], tags="floating")
  // === PAY STATION BOOTH (ground floor, near exit) ===
  box "booth" (size=[2.0, 2.5, 2.0], mat="concrete", pos=[7.0, 1.25, -6.0], tags="floating")
  slab "booth_roof" (size=[2.2, 0.10, 2.2], mat="concrete_dark", pos=[7.0, 2.55, -6.0], tags="floating")
  box "booth_win" (size=[0.06, 0.80, 1.20], mat="metal_rail", pos=[5.95, 1.50, -6.0], tags="floating")
}
'''
(BASE / "buildings/src/parking_garage.mog").write_text(parking_src)
print("  rewrote buildings/parking_garage.mog (with real ramps + stair tower + markings)")

print("\n=== Part A: 2 fixes written ===")
