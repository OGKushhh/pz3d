# TerrainBaker — creates a Terrain3D terrain from TerrainHeight at startup.
#
# Replaces the flat Ground node with a real 3D terrain mesh.
# Samples terrain_height.height_at() on a grid, writes to heightmap Image,
# imports into Terrain3D. Handles LOD, collision, splatting automatically.
#
# Multi-region: Terrain3D v1.0.2 max region_size=2048. Map is 4000×3000m.
# We use 4 regions: (0,0), (2048,0), (0,2048), (2048,2048).
# Each region gets its own heightmap bake.
#
# Attach to a Node3D in main.tscn (replaces the old flat Ground node).
class_name TerrainBaker
extends Node3D

const CFG := preload("res://tools/city_config.gd")
const TerrainHeight := preload("res://tools/terrain_height.gd")
const RiverNetwork := preload("res://tools/river_network.gd")

const REGION_SIZE := 2048  # Terrain3D max per region

@export var heightmap_resolution := 1024  # pixels per side per region (lower = faster bake)

var terrain: Terrain3D
var _height_fn: TerrainHeight

func _ready() -> void:
        _height_fn = TerrainHeight.new(1337, RiverNetwork.new())
        _build_terrain()

func _build_terrain() -> void:
        print("[TerrainBaker] Building terrain (multi-region, res=%d/region)" % heightmap_resolution)

        # Create Terrain3D node
        terrain = Terrain3D.new()
        terrain.name = "Terrain3D"
        add_child(terrain, true)

        # Set material — world background = none (no infinite plane beyond map)
        terrain.material.world_background = Terrain3DMaterial.NONE
        terrain.material.auto_shader = true
        terrain.material.set_shader_param("auto_slope", 10)
        terrain.material.set_shader_param("blend_sharpness", 0.975)

        # Create basic texture assets
        var grass_ta := _create_solid_texture("Grass", Color(0.25, 0.45, 0.18))
        grass_ta.uv_scale = 0.05
        var dirt_ta := _create_solid_texture("Dirt", Color(0.45, 0.32, 0.20))
        dirt_ta.uv_scale = 0.03
        var sand_ta := _create_solid_texture("Sand", Color(0.75, 0.65, 0.40))
        sand_ta.uv_scale = 0.04
        var rock_ta := _create_solid_texture("Rock", Color(0.50, 0.48, 0.45))
        rock_ta.uv_scale = 0.02

        terrain.assets = Terrain3DAssets.new()
        terrain.assets.set_texture(0, grass_ta)
        terrain.assets.set_texture(1, dirt_ta)
        terrain.assets.set_texture(2, sand_ta)
        terrain.assets.set_texture(3, rock_ta)

        # Set region size BEFORE importing
        terrain.region_size = REGION_SIZE

        # Multi-region: bake heightmap for each region covering the 4000×3000m map.
        # Regions are placed at 2048m intervals.
        # Region (0,0): X=0..2048, Z=0..2048 (covers most of spawn area)
        # Region (1,0): X=2048..4096, Z=0..2048 (covers east half including river at X=2250)
        # Region (0,1): X=0..2048, Z=2048..4096 (covers south half)
        # Region (1,1): X=2048..4096, Z=2048..4096 (covers southeast)
        var regions := [
                Vector2i(0, 0),  # NW
                Vector2i(1, 0),  # NE (has river at X=2250)
                Vector2i(0, 1),  # SW
                Vector2i(1, 1),  # SE
        ]

        for region in regions:
                var origin := Vector3(
                        float(region.x) * REGION_SIZE,
                        0.0,
                        float(region.y) * REGION_SIZE
                )
                var img := _bake_region(origin, REGION_SIZE)
                terrain.data.import_images([img, null, null], origin, 0.0, 1.0)
                print("[TerrainBaker] Region (%d,%d) baked at origin=%s" % [region.x, region.y, origin])

        # Enable collision (so player walks on terrain)
        # DYNAMIC_GAME = runtime collision (works in exported builds + editor play)
        # DYNAMIC_EDITOR = editor-only (player falls through in actual game!)
        terrain.collision.mode = Terrain3DCollision.DYNAMIC_GAME

        print("[TerrainBaker] Terrain3D ready (%d regions, region_size=%d)" % [regions.size(), REGION_SIZE])

        # B.5: Place bridges at bridge locations
        _place_bridges()

        # Phase D: Water surface over river area
        _place_water()

# Bake a single region's heightmap from terrain_height.gd
func _bake_region(origin: Vector3, size_m: float) -> Image:
        var img := Image.create_empty(heightmap_resolution, heightmap_resolution, false, Image.FORMAT_RF)
        for x in range(heightmap_resolution):
                for y in range(heightmap_resolution):
                        var world_x: float = origin.x + (float(x) / float(heightmap_resolution)) * size_m
                        var world_z: float = origin.z + (float(y) / float(heightmap_resolution)) * size_m
                        var h: float = _height_fn.height_at(world_x, world_z)
                        img.set_pixel(x, y, Color(h, 0.0, 0.0, 1.0))
        return img

func _create_solid_texture(name: String, color: Color) -> Terrain3DTextureAsset:
        var ta := Terrain3DTextureAsset.new()
        ta.resource_name = name
        var albedo_img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
        albedo_img.fill(color)
        var albedo_tex := ImageTexture.create_from_image(albedo_img)
        ta.albedo_texture = albedo_tex
        return ta

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
                # Bridge deck Y = terrain height at the bridge approach (land, not river)
                var deck_y: float = _height_fn.height_at(x_center - 200.0, z)
                var inst: Node3D = bridge_scene.instantiate()
                inst.position = Vector3(x_center, deck_y, z)
                inst.name = "Bridge_%s" % b.get("name", "unnamed")
                add_child(inst)
                placed += 1
        print("[TerrainBaker] Bridges placed: %d" % placed)

# Phase D: Water surface at Y=0 over river + coastal areas
func _place_water() -> void:
        var river_x: float = 2250.0
        var water_w: float = 70.0
        var water_l: float = 3000.0  # full map depth

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
        water_mi.position = Vector3(river_x, 0.0, 1500.0)  # centered on map depth
        add_child(water_mi)
        print("[TerrainBaker] Water surface at X=%.0f, Y=0.0, %.0f×%.0fm" % [river_x, water_w, water_l])
