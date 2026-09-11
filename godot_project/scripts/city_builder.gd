extends SceneTree

## Mazar City Builder — generates the entire Suburbia scene autonomously
## Run via: godot --headless --script res://scripts/city_builder.gd --path godot_project/
##
## Places: roads, buildings, trees, street lights, props — ALL with proper
## positioning (nothing in the middle of the street!)

const ROAD_WIDTH = 8.0
const SIDEWALK_WIDTH = 2.0
const BUILDING_SETBACK = 3.0  # distance from road edge to building
const LOT_WIDTH = 14.0  # width of each building lot
const LOT_DEPTH = 12.0  # depth of each building lot

# Asset paths (res://)
const ASSETS = {
        "buildings": {
                "suburban_house_v2": "res://assets/buildings/suburban_house_v2.glb",
                "two_story_colonial": "res://assets/buildings/two_story_colonial.glb",
                "bungalow": "res://assets/buildings/bungalow.glb",
                "house_modern": "res://assets/buildings/house_modern.glb",
                "house_split_level": "res://assets/buildings/house_split_level.glb",
                "shed": "res://assets/buildings/shed.glb",
                "garden_shed_wood": "res://assets/buildings/garden_shed_wood.glb",
                "barn": "res://assets/buildings/barn.glb",
                "corner_store": "res://assets/buildings/corner_store.glb",
                "cottage": "res://assets/buildings/cottage.glb",
                "garage_detached": "res://assets/buildings/garage_detached.glb",
                "utility_shed_metal": "res://assets/buildings/utility_shed_metal.glb",
        },
        "foliage": {
                "oak_tree": "res://assets/foliage/oak_tree.glb",
                "pine_tree": "res://assets/foliage/pine_tree.glb",
                "birch_tree": "res://assets/foliage/birch_tree.glb",
                "bush": "res://assets/foliage/bush.glb",
                "dead_tree": "res://assets/foliage/dead_tree.glb",
                "flower_patch": "res://assets/foliage/flower_patch.glb",
                "hedge": "res://assets/foliage/hedge.glb",
        },
        "environment": {
                "street_light": "res://assets/environment/street_light.glb",
                "mailbox": "res://assets/environment/mailbox.glb",
                "trash_can": "res://assets/environment/trash_can.glb",
                "fire_hydrant": "res://assets/environment/fire_hydrant.glb",
                "picket_fence": "res://assets/environment/picket_fence.glb",
                "brick_wall_segment": "res://assets/environment/brick_wall_segment.glb",
                "traffic_cone": "res://assets/environment/traffic_cone.glb",
                "road_sign": "res://assets/environment/road_sign.glb",
                "bench_park": "res://assets/environment/bench_park.glb",
                "picnic_table": "res://assets/environment/picnic_table.glb",
                "playground_slide": "res://assets/environment/playground_slide.glb",
                "swing_set": "res://assets/environment/swing_set.glb",
                "school_bus": "res://assets/environment/school_bus.glb",
                "garden_gnome": "res://assets/environment/garden_gnome.glb",
                "utility_pole": "res://assets/environment/utility_pole.glb",
                "bollard": "res://assets/environment/bollard.glb",
                "planter_box": "res://assets/environment/planter_box.glb",
                "chain_link_fence": "res://assets/environment/chain_link_fence.glb",
        },
}

# Building variants for residential lots
const HOUSE_VARIANTS = [
        "suburban_house_v2", "two_story_colonial", "bungalow",
        "house_modern", "house_split_level"
]

var rng = RandomNumberGenerator.new()
var city_root: Node3D
var placed_positions: Array[Vector3] = []

func _init():
        rng.seed = 42
        print("=== Mazar City Builder ===")
        print("Building Suburbia scene...")
        
        # Create root scene
        city_root = Node3D.new()
        city_root.name = "MazarSuburbia"
        
        # 1. Sky + Environment
        _setup_sky_and_environment()
        
        # 2. Sun
        _setup_sun()
        
        # 3. Ground (large grass plane)
        _setup_ground()
        
        # 4. Roads (grid pattern)
        _setup_roads()
        
        # 5. Place buildings along roads
        _place_buildings()
        
        # 6. Place street furniture (lights, hydrants, mailboxes) on SIDEWALKS
        _place_street_furniture()
        
        # 7. Place trees and foliage in yards
        _place_foliage()
        
        # 8. Place fences
        _place_fences()
        
        # 9. Place playground area
        _place_playground()
        
        # 10. Place scattered props
        _place_scattered_props()
        
        # 11. Player spawn
        _setup_player()
        
        # Save scene
        var scene = PackedScene.new()
        scene.pack(city_root)
        var err = ResourceSaver.save(scene, "res://scenes/suburbia_city.tscn")
        if err == OK:
                print("Scene saved: res://scenes/suburbia_city.tscn")
        else:
                print("ERROR saving scene: ", err)
        
        print("=== City build complete ===")
        print("Total objects placed: ", placed_positions.size())
        quit()

func _setup_sky_and_environment():
        var env = Environment.new()
        
        # Sky
        var sky = ProceduralSkyMaterial.new()
        sky.sky_top_color = Color(0.25, 0.45, 0.75, 1)
        sky.sky_horizon_color = Color(0.65, 0.75, 0.85, 1)
        sky.ground_bottom_color = Color(0.35, 0.35, 0.35, 1)
        sky.ground_horizon_color = Color(0.55, 0.55, 0.55, 1)
        sky.sun_angle_max = 35.0
        sky.sun_curve = 0.15
        sky.use_debanding = true
        
        env.background_mode = Environment.BG_SKY
        env.sky = Sky.new()
        env.sky.sky_material = sky
        
        # Ambient
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_color = Color(0.6, 0.65, 0.7, 1)
        env.ambient_light_energy = 0.8
        
        # Fog (draw distance — lore-justified)
        env.fog_enabled = true
        env.fog_light_color = Color(0.5, 0.55, 0.6, 1)
        env.fog_density = 0.008
        env.fog_aerial_perspective = 0.5
        env.fog_sky_affect = 0.3
        
        # Tonemapping
        env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        env.tonemap_white = 1.0
        
        # SSAO (subtle)
        env.ssao_enabled = true
        env.ssao_radius = 1.0
        env.ssao_intensity = 1.5
        env.ssao_power = 1.2
        
        var world_env = WorldEnvironment.new()
        world_env.name = "WorldEnvironment"
        world_env.environment = env
        city_root.add_child(world_env)
        world_env.owner = city_root
        
        print("  ✓ Sky + environment (procedural sky, fog, SSAO)")

func _setup_sun():
        var sun = DirectionalLight3D.new()
        sun.name = "Sun"
        # Position high, angled
        sun.transform.origin = Vector3(-50, 80, -50)
        # Rotation: 45° azimuth, 55° elevation
        var rot = Transform3D()
        rot = rot.rotated(Vector3.UP, deg_to_rad(45))
        rot = rot.rotated(Vector3.RIGHT, deg_to_rad(-35))
        sun.transform.basis = rot.basis
        sun.light_color = Color(1.0, 0.95, 0.82, 1)
        sun.light_energy = 2.5
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 80.0
        sun.directional_shadow_size = 2048
        city_root.add_child(sun)
        sun.owner = city_root
        
        print("  ✓ Sun (directional light, shadows enabled)")

func _setup_ground():
        # Large grass plane
        var ground_body = StaticBody3D.new()
        ground_body.name = "Ground"
        
        var ground_mesh = MeshInstance3D.new()
        ground_mesh.name = "GroundMesh"
        var box_mesh = BoxMesh.new()
        box_mesh.size = Vector3(400, 1, 400)
        ground_mesh.mesh = box_mesh
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.22, 0.40, 0.16, 1)
        mat.roughness = 0.90
        ground_mesh.material_override = mat
        ground_body.add_child(ground_mesh)
        
        var col = CollisionShape3D.new()
        col.name = "GroundCollider"
        var shape = BoxShape3D.new()
        shape.size = Vector3(400, 1, 400)
        col.shape = shape
        ground_body.add_child(col)
        
        ground_body.transform.origin = Vector3(0, -0.5, 0)
        city_root.add_child(ground_body)
        ground_body.owner = city_root
        
        print("  ✓ Ground (400x400 grass plane)")

func _setup_roads():
        # Main horizontal road (runs along X axis at Z=0)
        _create_road("Road_Horizontal", Vector3(0, 0.02, 0), Vector3(200, 0.02, ROAD_WIDTH))
        
        # Main vertical road (runs along Z axis at X=0)
        _create_road("Road_Vertical", Vector3(0, 0.02, 0), Vector3(ROAD_WIDTH, 0.02, 200))
        
        # Secondary roads (parallel, 60m apart)
        _create_road("Road_H2", Vector3(0, 0.02, 60), Vector3(200, 0.02, ROAD_WIDTH))
        _create_road("Road_V2", Vector3(60, 0.02, 0), Vector3(ROAD_WIDTH, 0.02, 200))
        _create_road("Road_H3", Vector3(0, 0.02, -60), Vector3(200, 0.02, ROAD_WIDTH))
        _create_road("Road_V3", Vector3(-60, 0.02, 0), Vector3(ROAD_WIDTH, 0.02, 200))
        
        print("  ✓ Roads (7 road segments, grid pattern)")

func _create_road(name: String, pos: Vector3, size: Vector3):
        var road = MeshInstance3D.new()
        road.name = name
        var mesh = BoxMesh.new()
        mesh.size = size
        road.mesh = mesh
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.14, 0.14, 0.16, 1)
        mat.roughness = 0.95
        road.material_override = mat
        road.transform.origin = pos
        city_root.add_child(road)
        road.owner = city_root

func _place_buildings():
        var count = 0
        
        # Place buildings along the main horizontal road (Z=0)
        # Buildings go on both sides: Z > 0 (south side) and Z < 0 (north side)
        # Building setback from road: ROAD_WIDTH/2 + SIDEWALK_WIDTH + BUILDING_SETBACK
        
        var building_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH + BUILDING_SETBACK
        
        # East-west along main road
        for x in range(-80, 81, int(LOT_WIDTH)):
                if abs(x) < 10:  # Skip the intersection
                        continue
                
                # South side (Z > 0)
                var variant_s = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
                _place_asset("buildings", variant_s, Vector3(x, 0, building_offset + LOT_DEPTH/2), 0)
                count += 1
                
                # North side (Z < 0) — rotated 180°
                var variant_n = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
                _place_asset("buildings", variant_n, Vector3(x, 0, -(building_offset + LOT_DEPTH/2)), 180)
                count += 1
        
        # Along vertical road (X=0)
        for z in range(-80, 81, int(LOT_WIDTH)):
                if abs(z) < 10:
                        continue
                
                # East side (X > 0) — rotated -90°
                var variant_e = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
                _place_asset("buildings", variant_e, Vector3(building_offset + LOT_DEPTH/2, 0, z), -90)
                count += 1
                
                # West side (X < 0) — rotated 90°
                var variant_w = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
                _place_asset("buildings", variant_w, Vector3(-(building_offset + LOT_DEPTH/2), 0, z), 90)
                count += 1
        
        # Along secondary roads
        for x in range(-70, 71, int(LOT_WIDTH)):
                if abs(x) < 10:
                        continue
                # South side of H2 road (Z=60)
                var v = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
                _place_asset("buildings", v, Vector3(x, 0, 60 + building_offset + LOT_DEPTH/2), 0)
                count += 1
                # North side of H2
                v = HOUSE_VARIANTS[rng.randi() % HOUSE_VARIANTS.size()]
                _place_asset("buildings", v, Vector3(x, 0, 60 - building_offset - LOT_DEPTH/2), 180)
                count += 1
        
        print("  ✓ Buildings placed: ", count)

func _place_street_furniture():
        # Street lights: on sidewalk edge, NOT in middle of road
        # Place at regular intervals along road, offset to sidewalk
        var light_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2
        var count = 0
        
        for x in range(-80, 81, 20):
                if abs(x) < 10:
                        continue
                # South sidewalk
                _place_asset("environment", "street_light", Vector3(x, 0, light_offset), 0)
                count += 1
                # North sidewalk
                _place_asset("environment", "street_light", Vector3(x, 0, -light_offset), 180)
                count += 1
        
        # Fire hydrants: on corners (NOT middle of road)
        # Place at intersection corners
        var corner_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2 + 0.5
        for corner in [Vector3(corner_offset, 0, corner_offset), Vector3(-corner_offset, 0, corner_offset), Vector3(corner_offset, 0, -corner_offset), Vector3(-corner_offset, 0, -corner_offset)]:
                _place_asset("environment", "fire_hydrant", corner, 0)
                count += 1
        
        # Mailboxes: in front of some houses (on sidewalk, near road edge)
        for x in range(-70, 71, 28):
                if abs(x) < 10:
                        continue
                _place_asset("environment", "mailbox", Vector3(x + 2, 0, light_offset + 0.5), 90)
                count += 1
                _place_asset("environment", "mailbox", Vector3(x - 2, 0, -light_offset - 0.5), -90)
                count += 1
        
        # Trash cans: near some houses
        for x in range(-60, 61, 42):
                if abs(x) < 10:
                        continue
                _place_asset("environment", "trash_can", Vector3(x + 4, 0, light_offset + 1.0), 0)
                count += 1
        
        # Utility poles: along road, set back from sidewalk
        for x in range(-75, 76, 30):
                if abs(x) < 10:
                        continue
                _place_asset("environment", "utility_pole", Vector3(x, 0, light_offset + 2.5), 0)
                count += 1
        
        print("  ✓ Street furniture placed: ", count)

func _place_foliage():
        var count = 0
        var building_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH + BUILDING_SETBACK
        
        # Trees in front yards (between sidewalk and building)
        for x in range(-80, 81, int(LOT_WIDTH)):
                if abs(x) < 10:
                        continue
                
                # South side yard trees
                if rng.randf() > 0.3:  # 70% chance of a tree
                        var tree_type = ["oak_tree", "pine_tree", "birch_tree"][rng.randi() % 3]
                        var px = x + rng.randf_range(-3, 3)
                        var pz = building_offset - 2 + rng.randf_range(-1, 1)
                        _place_asset("foliage", tree_type, Vector3(px, 0, pz), rng.randf_range(0, 360))
                        count += 1
                
                # North side yard trees
                if rng.randf() > 0.3:
                        var tree_type = ["oak_tree", "pine_tree", "birch_tree"][rng.randi() % 3]
                        var px = x + rng.randf_range(-3, 3)
                        var pz = -(building_offset - 2) + rng.randf_range(-1, 1)
                        _place_asset("foliage", tree_type, Vector3(px, 0, pz), rng.randf_range(0, 360))
                        count += 1
                
                # Bushes near building entrances
                if rng.randf() > 0.5:
                        _place_asset("foliage", "bush", Vector3(x - 3, 0, building_offset + 1), 0)
                        count += 1
                if rng.randf() > 0.5:
                        _place_asset("foliage", "bush", Vector3(x + 3, 0, building_offset + 1), 0)
                        count += 1
        
        # Dead trees scattered (atmosphere)
        for i in range(5):
                var px = rng.randf_range(-90, 90)
                var pz = rng.randf_range(-90, 90)
                # Don't place on roads
                if abs(pz) < ROAD_WIDTH/2 + 1 or abs(px) < ROAD_WIDTH/2 + 1:
                        continue
                _place_asset("foliage", "dead_tree", Vector3(px, 0, pz), rng.randf_range(0, 360))
                count += 1
        
        # Flower patches near some houses
        for x in range(-60, 61, 28):
                if abs(x) < 10:
                        continue
                _place_asset("foliage", "flower_patch", Vector3(x + 5, 0, building_offset + 0.5), 0)
                count += 1
        
        print("  ✓ Foliage placed: ", count)

func _place_fences():
        var count = 0
        var building_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH + BUILDING_SETBACK
        
        # Picket fences along front property lines
        for x in range(-80, 81, int(LOT_WIDTH)):
                if abs(x) < 10:
                        continue
                
                # South side fence (runs along X at Z = building_offset - 3)
                for fx in range(-5, 6, 2):  # 5 fence segments per lot
                        _place_asset("environment", "picket_fence", Vector3(x + fx, 0, building_offset - 3), 0)
                        count += 1
                
                # North side fence
                for fx in range(-5, 6, 2):
                        _place_asset("environment", "picket_fence", Vector3(x + fx, 0, -(building_offset - 3)), 0)
                        count += 1
        
        print("  ✓ Fences placed: ", count)

func _place_playground():
        # Place playground at a park area (away from roads)
        var park_pos = Vector3(40, 0, 40)
        
        _place_asset("environment", "playground_slide", park_pos + Vector3(-3, 0, 0), 0)
        _place_asset("environment", "swing_set", park_pos + Vector3(3, 0, 0), 0)
        _place_asset("environment", "picnic_table", park_pos + Vector3(0, 0, -5), 0)
        _place_asset("environment", "bench_park", park_pos + Vector3(-5, 0, -3), 90)
        _place_asset("environment", "bench_park", park_pos + Vector3(5, 0, -3), -90)
        
        # Trees around park
        for i in range(6):
                var angle = i * 60.0
                var r = 8.0
                var px = park_pos.x + cos(deg_to_rad(angle)) * r
                var pz = park_pos.z + sin(deg_to_rad(angle)) * r
                _place_asset("foliage", "oak_tree", Vector3(px, 0, pz), 0)
        
        print("  ✓ Playground area placed")

func _place_scattered_props():
        var count = 0
        var building_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH + BUILDING_SETBACK
        
        # Garden gnomes in some yards
        for x in range(-50, 51, 35):
                if abs(x) < 10:
                        continue
                _place_asset("environment", "garden_gnome", Vector3(x + 4, 0, building_offset + 3), rng.randf_range(0, 360))
                count += 1
        
        # Bollards at intersection edges
        var b_offset = ROAD_WIDTH / 2 + SIDEWALK_WIDTH + 0.3
        for bx in [-b_offset - 0.5, b_offset + 0.5]:
                for bz in [-b_offset - 0.5, b_offset + 0.5]:
                        _place_asset("environment", "bollard", Vector3(bx, 0, bz), 0)
                        count += 1
        
        # Planter boxes near some houses
        for x in range(-40, 41, 20):
                if abs(x) < 10:
                        continue
                _place_asset("environment", "planter_box", Vector3(x + 2, 0, building_offset + 2), 0)
                count += 1
        
        # School bus parked on side
        _place_asset("environment", "school_bus", Vector3(70, 0, ROAD_WIDTH/2 + SIDEWALK_WIDTH + 1), 90)
        count += 1
        
        print("  ✓ Scattered props placed: ", count)

func _setup_player():
        var player = CharacterBody3D.new()
        player.name = "Player"
        player.transform.origin = Vector3(0, 1.65, 25)
        
        # Camera
        var cam = Camera3D.new()
        cam.name = "Camera3D"
        cam.fov = 75.0
        cam.near = 0.05
        cam.far = 150.0
        cam.transform.origin = Vector3(0, 0, 0)
        player.add_child(cam)
        
        # Collision
        var col = CollisionShape3D.new()
        col.name = "CollisionShape3D"
        var shape = CapsuleShape3D.new()
        shape.radius = 0.4
        shape.height = 1.8
        col.shape = shape
        col.transform.origin = Vector3(0, 0.9, 0)
        player.add_child(col)
        
        # Load player script
        var script_path = "res://scripts/player_controller.gd"
        if ResourceLoader.exists(script_path):
                player.set_script(load(script_path))
        
        city_root.add_child(player)
        player.owner = city_root
        
        print("  ✓ Player placed at spawn point")

func _place_asset(category: String, asset_name: String, pos: Vector3, rot_y: float):
        var path = ASSETS.get(category, {}).get(asset_name, "")
        if path == "":
                print("    WARNING: Asset not found: ", category, "/", asset_name)
                return
        
        if not ResourceLoader.has_cached(path) and not ResourceLoader.exists(path):
                print("    WARNING: Resource doesn't exist: ", path)
                return
        
        var packed = load(path)
        if packed == null:
                print("    WARNING: Failed to load: ", path)
                return
        
        var instance = packed.instantiate()
        if instance == null:
                print("    WARNING: Failed to instantiate: ", path)
                return
        
        instance.name = asset_name + "_" + str(placed_positions.size())
        instance.transform.origin = pos
        instance.rotate_y(deg_to_rad(rot_y))
        
        city_root.add_child(instance)
        instance.owner = city_root
        placed_positions.append(pos)
