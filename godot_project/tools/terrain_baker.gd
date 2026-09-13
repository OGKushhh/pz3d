# TerrainBaker — creates terrain features (bridges, water) at startup.
#
# Terrain3D is DISABLED — it causes z-fighting with the flat ground and
# its collision doesn't work properly. The FlatGround in main.tscn
# provides visible ground + collision at Y=0.
#
# This script still places bridges and water surface (they're independent
# of the terrain mesh).
#
# TODO: re-enable Terrain3D when we solve:
# 1. Z-fighting between Terrain3D mesh and FlatGround
# 2. DYNAMIC_GAME collision not working on GTX 1050
# 3. Proper Forward+ renderer support testing
class_name TerrainBaker
extends Node3D

const CFG := preload("res://tools/city_config.gd")
const TerrainHeight := preload("res://tools/terrain_height.gd")
const RiverNetwork := preload("res://tools/river_network.gd")

var _height_fn: TerrainHeight

func _ready() -> void:
        _height_fn = TerrainHeight.new(1337, RiverNetwork.new())
        _build_terrain()

func _build_terrain() -> void:
        print("[TerrainBaker] Terrain3D DISABLED — using flat ground only")
        _place_bridges()
        _place_water()

# B.5 + Phase A.11: Place bridges at locations defined in city_config.gd::bridges()
# Phase A.11: bridges now have ELEVATED decks (Y=+3m above water) + visible
# support piers at each end. Was flat at Y=0 (looked like a wider road).
# Now visually distinct from regular roads — players can see they're crossing
# a bridge, not just walking on a flat street.
func _place_bridges() -> void:
        var manifest_path := "res://data/city_manifest.json"
        var f := FileAccess.open(manifest_path, FileAccess.READ)
        if f == null:
                return
        var manifest: Dictionary = JSON.parse_string(f.get_as_text())
        if not manifest.has("bridge_section"):
                return
        var bridge_scene: PackedScene = load(manifest["bridge_section"]["path"]) as PackedScene
        if bridge_scene == null:
                return

        var placed := 0
        for b in CFG.bridges():
                var z: float = float(b["row"]) * 500.0 + 250.0
                var x_center: float = (float(b["from_col"]) + float(b["to_col"])) * 500.0 / 2.0 + 250.0
                # Phase A.11: elevated deck — bridge sits 3m above water (Y=0)
                # so it's visually distinct from flat roads. Players see the
                # bridge structure + can look down at the river below.
                var deck_y: float = 3.0
                var inst: Node3D = bridge_scene.instantiate()
                inst.position = Vector3(x_center, deck_y, z)
                inst.name = "Bridge_%s" % b.get("name", "unnamed")
                add_child(inst)
                # Phase A.11: add support piers at each end of the bridge
                _place_bridge_piers(x_center, z, deck_y)
                placed += 1
        print("[TerrainBaker] Bridges placed: %d (elevated +3m, with piers)" % placed)

# Phase A.11: place visible support piers at the 4 corners of each bridge.
# Piers are simple cylinders from Y=0 (water level) up to the deck (Y=3).
# Visual only — no collision (player can't walk into the river anyway).
func _place_bridge_piers(x_center: float, z: float, deck_y: float) -> void:
        var pier_scene: PackedScene = null
        # Try loading a pier asset; if not in manifest, use a simple cylinder mesh
        var pier_mat := StandardMaterial3D.new()
        pier_mat.albedo_color = Color(0.40, 0.38, 0.35, 1)
        pier_mat.roughness = 0.9
        # Bridge spans from_col*500 to (to_col+1)*500, so width ~ 1500m
        # Place piers at the 4 corners of the bridge deck
        var pier_offset_x: float = 480.0  # near the bridge ends
        var pier_offset_z: float = 4.0     # near the bridge edges
        for dx in [-pier_offset_x, pier_offset_x]:
                for dz in [-pier_offset_z, pier_offset_z]:
                        var mi := MeshInstance3D.new()
                        mi.name = "BridgePier_%d_%d" % [int(dx), int(dz)]
                        var cyl := CylinderMesh.new()
                        cyl.top_radius = 0.8
                        cyl.bottom_radius = 1.0
                        cyl.height = deck_y + 1.0  # extend slightly above deck
                        mi.mesh = cyl
                        mi.material_override = pier_mat
                        mi.position = Vector3(x_center + dx, deck_y * 0.5, z + dz)
                        add_child(mi)

# Phase A.4: Water surface follows the river polyline (was a single vertical
# strip at X=2250 in Phase D). For each segment in the polyline, we place a
# water plane sized to the segment length × water_width, rotated to align
# with the segment direction. This produces a wandering water ribbon instead
# of a rigid vertical strip.
func _place_water() -> void:
        var river := RiverNetwork.new()
        var cps: Array = river.get_control_points()
        if cps.size() < 2:
                print("[TerrainBaker] river has <2 control_points — skipping water")
                return

        var water_w: float = river.get_half_width() * 2.0  # full width = 2 × half_width
        var water_y: float = river.get_water_level() - 1.0  # below flat ground to avoid z-fighting

        var water_mat := StandardMaterial3D.new()
        water_mat.albedo_color = Color(0.15, 0.30, 0.45, 0.7)
        water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        water_mat.roughness = 0.05
        water_mat.metallic = 0.3
        water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

        var segments_placed := 0
        for i in range(cps.size() - 1):
                var a: Vector2 = cps[i]
                var b: Vector2 = cps[i + 1]
                var mid: Vector2 = (a + b) * 0.5
                var seg_vec: Vector2 = b - a
                var seg_len: float = seg_vec.length()
                if seg_len < 1.0:
                        continue
                # Yaw rotation: align plane's local +Z with the segment direction.
                # In 2D (XZ plane), segment direction is (seg_vec.x, seg_vec.y)
                # where seg_vec.y maps to world Z. atan2(x, z) gives the yaw that
                # rotates default-forward (0,0,1) to (seg_vec.x, 0, seg_vec.y).
                var yaw: float = atan2(seg_vec.x, seg_vec.y)

                var water_mesh := PlaneMesh.new()
                water_mesh.size = Vector2(water_w, seg_len)

                var mi := MeshInstance3D.new()
                mi.name = "WaterSurface_%d" % i
                mi.mesh = water_mesh
                mi.material_override = water_mat
                mi.position = Vector3(mid.x, water_y, mid.y)
                mi.rotation.y = yaw
                add_child(mi)
                segments_placed += 1
        print("[TerrainBaker] Water surface: %d segments following polyline (%.0fm wide × variable length)" % [segments_placed, water_w])
