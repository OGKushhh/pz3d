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
@export var height_scale_min := -10.0     # min height in meters
@export var height_scale_max := 15.0      # max height in meters

var terrain: Terrain3D
var _height_fn: TerrainHeight

func _ready() -> void:
        _height_fn = TerrainHeight.new(1337, RiverNetwork.new())
        _build_terrain()

func _build_terrain() -> void:
        print("[TerrainBaker] Building terrain (resolution=%d, scale=%.0f..%.0f)" % [
                heightmap_resolution, height_scale_min, height_scale_max])

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
        # region_size=2048 means terrain covers 0..2048m in X and Z.
        # If we sample 0..4000m and stuff it into a 2048m region, the terrain
        # gets horizontally compressed 2x and heights won't match world positions.
        # Fix: sample only within the region area (0..region_size).
        var region_m: float = float(2048)  # must match terrain.region_size below
        var origin := Vector3(0.0, 0, 0.0)  # terrain starts at world origin

        var img := Image.create_empty(heightmap_resolution, heightmap_resolution, false, Image.FORMAT_RF)
        for x in range(heightmap_resolution):
                for y in range(heightmap_resolution):
                        var world_x: float = origin.x + (float(x) / float(heightmap_resolution)) * region_m
                        var world_z: float = origin.z + (float(y) / float(heightmap_resolution)) * region_m
                        var h: float = _height_fn.height_at(world_x, world_z)
                        # Normalize to 0-1 range for storage
                        var normalized := (h - height_scale_min) / (height_scale_max - height_scale_min)
                        normalized = clamp(normalized, 0.0, 1.0)
                        img.set_pixel(x, y, Color(normalized, 0.0, 0.0, 1.0))

        print("[TerrainBaker] Heightmap generated (%d×%d)" % [heightmap_resolution, heightmap_resolution])

        # Import heightmap into Terrain3D
        # Terrain3D requires region_size to be power-of-2 (64, 128, 256, 512, 1024, 2048).
        # Our map is 4000×3000m. Use region_size=2048, which covers most of the map.
        # Player spawn at (1750, 1500) is within this region.
        # TODO: add second region for the remaining ~2000m of map width.
        terrain.region_size = 2048
        terrain.data.import_images([img, null, null], origin, height_scale_min, height_scale_max)

        # Enable collision (so player walks on terrain)
        terrain.collision.mode = Terrain3DCollision.DYNAMIC_EDITOR

        print("[TerrainBaker] Terrain3D ready (region_size=%d, origin=%s)" % [
                terrain.region_size, origin])

func _create_solid_texture(name: String, color: Color) -> Terrain3DTextureAsset:
        var ta := Terrain3DTextureAsset.new()
        ta.resource_name = name
        # Create a simple 64×64 albedo texture
        var albedo_img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
        albedo_img.fill(color)
        var albedo_tex := ImageTexture.create_from_image(albedo_img)
        ta.albedo_texture = albedo_tex
        return ta
