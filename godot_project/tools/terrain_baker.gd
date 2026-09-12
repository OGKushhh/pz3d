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

# B.5: Place bridges at locations defined in city_config.gd::bridges()
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
		var deck_y: float = 0.0  # Flat ground
		var inst: Node3D = bridge_scene.instantiate()
		inst.position = Vector3(x_center, deck_y, z)
		inst.name = "Bridge_%s" % b.get("name", "unnamed")
		add_child(inst)
		placed += 1
	print("[TerrainBaker] Bridges placed: %d" % placed)

# Phase D: Water surface at Y=-1 (below flat ground to avoid z-fighting)
func _place_water() -> void:
	var river_x: float = 2250.0
	var water_w: float = 70.0
	var water_l: float = 3000.0

	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(water_w, water_l)

	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.15, 0.30, 0.45, 0.7)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.05
	water_mat.metallic = 0.3
	water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var water_mi := MeshInstance3D.new()
	water_mi.name = "WaterSurface"
	water_mi.mesh = water_mesh
	water_mi.material_override = water_mat
	water_mi.position = Vector3(river_x, -1.0, 1500.0)  # Below flat ground
	add_child(water_mi)
	print("[TerrainBaker] Water surface at X=%.0f, Y=-1.0, %.0f×%.0fm" % [river_x, water_w, water_l])
