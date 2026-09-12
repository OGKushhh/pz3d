# TerrainBaker — creates a Terrain3D terrain from TerrainHeight at startup.
#
# Replaces the flat Ground node with a real 3D terrain mesh.
# Samples terrain_height.height_at() on a grid, writes to a heightmap Image,
# imports into Terrain3D. Handles LOD, collision, splatting automatically.
#
# Attach to a Node3D in main.tscn (replaces the old flat Ground node).
class_name TerrainBaker
extends Node3D

const CFG := preload("res://tools/city_config.gd")
const TerrainHeight := preload("res://tools/terrain_height.gd")
const RiverNetwork := preload("res://tools/river_network.gd")

@export var heightmap_resolution := 2048  # pixels per side

var terrain: Terrain3D
var _height_fn: TerrainHeight

func _ready() -> void:
        _height_fn = TerrainHeight.new(1337, RiverNetwork.new())
        _build_terrain()

func _build_terrain() -> void:
        print("[TerrainBaker] Building terrain (resolution=%d, raw height mode)" % heightmap_resolution)

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

        # Generate heightmap Image from terrain_height.gd
        # CRITICAL: heightmap must cover the SAME area as the Terrain3D region.
        # Use region_size=4096 to cover the full map (4000×3000m) in one region.
        var region_m: float = float(2048)  # Terrain3D max region_size
        var origin := Vector3(0.0, 0, 0.0)  # terrain starts at world origin

        # Store RAW height values (not normalized).
        # import_images uses formula: height = offset + pixel_value * scale
        # With offset=0, scale=1, the pixel value IS the height in meters.
        # This ensures Terrain3D's get_height() returns exactly what
        # terrain_height.gd returns, so buildings/trees/player all align.
        var img := Image.create_empty(heightmap_resolution, heightmap_resolution, false, Image.FORMAT_RF)
        for x in range(heightmap_resolution):
                for y in range(heightmap_resolution):
                        var world_x: float = origin.x + (float(x) / float(heightmap_resolution)) * region_m
                        var world_z: float = origin.z + (float(y) / float(heightmap_resolution)) * region_m
                        var h: float = _height_fn.height_at(world_x, world_z)
                        img.set_pixel(x, y, Color(h, 0.0, 0.0, 1.0))

        print("[TerrainBaker] Heightmap generated (%d×%d)" % [heightmap_resolution, heightmap_resolution])

        # Import heightmap into Terrain3D.
        # import_images(images, global_position, offset, scale)
        # height = offset + pixel_value * scale = 0 + h * 1 = h
        # This makes Terrain3D's get_height() return EXACTLY the same value
        # as terrain_height.gd's height_at(), so everything aligns.
        terrain.region_size = 2048
        terrain.data.import_images([img, null, null], origin, 0.0, 1.0)

        # Enable collision (so player walks on terrain)
        terrain.collision.mode = Terrain3DCollision.DYNAMIC_EDITOR

        print("[TerrainBaker] Terrain3D ready (region_size=%d, origin=%s)" % [
                terrain.region_size, origin])

        # B.5: Place bridges at bridge locations
        _place_bridges()

        # Phase D: Water surface over river area
        _place_water()

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
        # River runs vertically at X=2250, RIVER_HALF_WIDTH=30m
        # Create a long thin plane covering the river within the terrain region
        var river_x: float = 2250.0
        var water_w: float = 70.0  # slightly wider than RIVER_HALF_WIDTH*2 for visual
        var water_l: float = 4096.0  # cover full terrain length

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
        water_mi.position = Vector3(river_x, 0.0, 2048.0)  # Y=0 = water level, Z center of terrain
        add_child(water_mi)
        print("[TerrainBaker] Water surface placed at X=%.0f, Y=0.0, size=%.0f×%.0f" % [river_x, water_w, water_l])
