# HandCraftedCityV2 — multi-biome hand-authored city map.
# Run: godot --headless --path godot_project --script res://scripts/build_test_city_v2.gd
# Saves to: res://scenes/test_city_v2.tscn
#
# Same organization as build_test_city.gd (road grid + lots + player + sky + sun)
# but LARGER (5x5 blocks = 400m × 400m) and BIOME-DIVERSE:
#   NW corner = Forest (cabin + dense trees)
#   NE corner = Downtown (highrises + bollards)
#   SW corner = Farmland (farmhouse + barn + silo + crops)
#   SE corner = Industrial (warehouse + containers)
#   Center N/S = Suburbia (houses + garages)
#   Center = Park (gazebo + benches)
#
# Output is PLAYABLE: WASD + mouse + jump + sprint.

extends SceneTree

const ROAD_W := 8.0
const SIDEWALK_W := 1.5
const GRASS_W := 2.5
const LOT_W := 20.0
const LOT_D := 16.0
const BLOCK_SIZE := 80.0
const BUILDING_OFFSET := ROAD_W * 0.5 + SIDEWALK_W + GRASS_W  # 8.0
const MAP_BLOCKS := 5  # 5x5 grid of blocks
const MAP_SIZE := BLOCK_SIZE * MAP_BLOCKS  # 400m × 400m

# Colors
const C_ROAD := Color(0.12, 0.12, 0.14, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_GROUND := Color(0.25, 0.42, 0.18, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SAND := Color(0.72, 0.67, 0.47, 1)
const C_WATER := Color(0.15, 0.30, 0.45, 0.7)
const C_PARK := Color(0.18, 0.38, 0.14, 1)

var city_root: Node3D
var placed: int = 0
var ASSETS: Dictionary = {}

func _init():
        print("=== Hand-Crafted City V2 (multi-biome) ===")
        _load_manifest()
        city_root = Node3D.new()
        city_root.name = "TestCityV2"

        _setup_sky()
        _setup_sun()
        _setup_ground()

        # Build road grid: roads at Z=0,80,160,240,320 and X=0,80,160,240,320
        for i in range(MAP_BLOCKS + 1):
                var pos := float(i) * BLOCK_SIZE
                _build_horizontal_road(pos)
                _build_vertical_road(pos)

        # Place biome-specific content per block
        # Block (col, row) at world origin (col*80, row*80)
        for col in range(MAP_BLOCKS):
                for row in range(MAP_BLOCKS):
                        var block_origin := Vector3(col * BLOCK_SIZE, 0, row * BLOCK_SIZE)
                        _place_biome_content(col, row, block_origin)

        # Player
        _setup_player()

        # Save scene
        var scene := PackedScene.new()
        scene.pack(city_root)
        var err := ResourceSaver.save(scene, "res://scenes/test_city_v2.tscn")
        if err == OK:
                print("✅ Scene saved: res://scenes/test_city_v2.tscn")
                print("   Objects placed: %d" % placed)
                print("   Map size: %dm × %dm" % [MAP_SIZE, MAP_SIZE])
        else:
                print("❌ Error saving: ", err)
        quit()

func _load_manifest():
        var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
        if f:
                ASSETS = JSON.parse_string(f.get_as_text())
        print("  Manifest loaded: %d assets" % ASSETS.size())

func _get_asset(name: String) -> PackedScene:
        if not ASSETS.has(name):
                return null
        var path: String = ASSETS[name]["path"]
        if not ResourceLoader.exists(path):
                return null
        return load(path) as PackedScene

func _place(asset_name: String, pos: Vector3, rot_y: float = 0.0, scale: float = 1.0) -> Node3D:
        var scene := _get_asset(asset_name)
        if scene == null:
                return null
        var inst := scene.instantiate()
        inst.position = pos
        inst.rotate_y(deg_to_rad(rot_y))
        if scale != 1.0:
                inst.scale = Vector3(scale, scale, scale)
        inst.name = asset_name + "_" + str(placed)
        city_root.add_child(inst)
        inst.owner = city_root
        placed += 1
        return inst

func _plane(name: String, pos: Vector3, size_x: float, size_z: float, color: Color, y_offset: float = 0.0):
        var mi := MeshInstance3D.new()
        mi.name = name
        var p := PlaneMesh.new()
        p.size = Vector2(size_x, size_z)
        mi.mesh = p
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.85
        mi.material_override = mat
        mi.position = Vector3(pos.x, pos.y + y_offset, pos.z)
        city_root.add_child(mi)
        mi.owner = city_root
        placed += 1

func _setup_sky():
        var env := Environment.new()
        var sky_mat := ProceduralSkyMaterial.new()
        sky_mat.sky_top_color = Color(0.15, 0.35, 0.70, 1)
        sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.88, 1)
        sky_mat.ground_bottom_color = Color(0.25, 0.22, 0.18, 1)
        sky_mat.ground_horizon_color = Color(0.50, 0.48, 0.42, 1)
        sky_mat.sun_angle_max = 30.0
        sky_mat.sun_curve = 0.12
        sky_mat.use_debanding = true
        var sky := Sky.new()
        sky.sky_material = sky_mat
        env.background_mode = Environment.BG_SKY
        env.sky = sky
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_color = Color(0.55, 0.60, 0.65, 1)
        env.ambient_light_energy = 0.6
        env.fog_enabled = true
        env.fog_light_color = Color(0.50, 0.55, 0.60, 1)
        env.fog_density = 0.005
        env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        env.tonemap_white = 1.0
        var we := WorldEnvironment.new()
        we.name = "WorldEnvironment"
        we.environment = env
        city_root.add_child(we)
        we.owner = city_root

func _setup_sun():
        var sun := DirectionalLight3D.new()
        sun.name = "Sun"
        sun.transform.origin = Vector3(-100, 150, -100)
        sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
        sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
        sun.light_color = Color(1.0, 0.95, 0.80, 1)
        sun.light_energy = 2.0
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 200.0
        city_root.add_child(sun)
        sun.owner = city_root

func _setup_ground():
        # Ground collision (big box)
        var body := StaticBody3D.new()
        body.name = "Ground"
        body.position = Vector3(MAP_SIZE * 0.5, 0, MAP_SIZE * 0.5)
        city_root.add_child(body)
        body.owner = city_root
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(MAP_SIZE + 50, 1, MAP_SIZE + 50)
        col.shape = shape
        body.add_child(col)
        col.owner = city_root
        # Ground mesh
        _plane("GroundMesh", Vector3(MAP_SIZE * 0.5, 0, MAP_SIZE * 0.5), MAP_SIZE + 50, MAP_SIZE + 50, C_GROUND)

func _build_horizontal_road(z: float):
        var cx := MAP_SIZE * 0.5
        _plane("Road_H_%d" % int(z), Vector3(cx, 0, z), MAP_SIZE + 50, ROAD_W, C_ROAD, 0.02)
        _plane("Lane_H_%d" % int(z), Vector3(cx, 0, z), MAP_SIZE + 50, 0.15, C_LANE, 0.03)
        var sw := ROAD_W * 0.5 + SIDEWALK_W * 0.5
        _plane("SW_S_%d" % int(z), Vector3(cx, 0, z + sw), MAP_SIZE + 50, SIDEWALK_W, C_SIDEWALK, 0.05)
        _plane("SW_N_%d" % int(z), Vector3(cx, 0, z - sw), MAP_SIZE + 50, SIDEWALK_W, C_SIDEWALK, 0.05)
        var gs := ROAD_W * 0.5 + SIDEWALK_W + GRASS_W * 0.5
        _plane("GS_S_%d" % int(z), Vector3(cx, 0, z + gs), MAP_SIZE + 50, GRASS_W, C_GRASS, 0.03)
        _plane("GS_N_%d" % int(z), Vector3(cx, 0, z - gs), MAP_SIZE + 50, GRASS_W, C_GRASS, 0.03)

func _build_vertical_road(x: float):
        var cz := MAP_SIZE * 0.5
        _plane("Road_V_%d" % int(x), Vector3(x, 0, cz), ROAD_W, MAP_SIZE + 50, C_ROAD, 0.02)
        _plane("Lane_V_%d" % int(x), Vector3(x, 0, cz), 0.15, MAP_SIZE + 50, C_LANE, 0.03)
        var sw := ROAD_W * 0.5 + SIDEWALK_W * 0.5
        _plane("SW_E_%d" % int(x), Vector3(x + sw, 0, cz), SIDEWALK_W, MAP_SIZE + 50, C_SIDEWALK, 0.05)
        _plane("SW_W_%d" % int(x), Vector3(x - sw, 0, cz), SIDEWALK_W, MAP_SIZE + 50, C_SIDEWALK, 0.05)
        var gs := ROAD_W * 0.5 + SIDEWALK_W + GRASS_W * 0.5
        _plane("GS_E_%d" % int(x), Vector3(x + gs, 0, cz), GRASS_W, MAP_SIZE + 50, C_GRASS, 0.03)
        _plane("GS_W_%d" % int(x), Vector3(x - gs, 0, cz), GRASS_W, MAP_SIZE + 50, C_GRASS, 0.03)

# === BIOME CONTENT PER BLOCK ===
# Block (col, row) → biome assignment:
#   (0,0)=Forest  (1,0)=Suburbia  (2,0)=Park  (3,0)=Suburbia  (4,0)=Downtown
#   (0,1)=Forest  (1,1)=Suburbia  (2,1)=Park  (3,1)=Suburbia  (4,1)=Downtown
#   (0,2)=Farm    (1,2)=Suburbia  (2,2)=Park  (3,2)=Commerce  (4,2)=Industrial
#   (0,3)=Farm    (1,3)=Suburbia  (2,3)=Park  (3,3)=Commerce  (4,3)=Industrial
#   (0,4)=Beach   (1,4)=Wetland   (2,4)=Park  (3,4)=Commerce  (4,4)=Industrial
func _place_biome_content(col: int, row: int, origin: Vector3):
        var biome := _biome_at(col, row)
        match biome:
                "forest": _fill_forest(origin)
                "suburbia": _fill_suburbia(origin)
                "park": _fill_park(origin)
                "farm": _fill_farm(origin)
                "commerce": _fill_commerce(origin)
                "industrial": _fill_industrial(origin)
                "beach": _fill_beach(origin)
                "wetland": _fill_wetland(origin)
                "downtown": _fill_downtown(origin)
                _: _fill_suburbia(origin)

func _biome_at(col: int, row: int) -> String:
        # NW quadrant = Forest
        if col <= 1 and row <= 1: return "forest"
        # SW quadrant = Farmland
        if col <= 1 and row >= 3: return "farm" if row == 3 else "beach"
        if col == 0 and row == 4: return "beach"
        if col == 1 and row == 4: return "wetland"
        # Center column = Park
        if col == 2: return "park"
        # NE quadrant = Downtown
        if col >= 3 and row <= 1: return "downtown"
        # SE quadrant = Industrial
        if col >= 3 and row >= 3: return "industrial"
        if col >= 3 and row == 2: return "commerce"
        # Default = Suburbia (between biomes)
        return "suburbia"

# === FOREST ===
func _fill_forest(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Hunting cabin center
        _place("hunting_cabin", Vector3(cx, 0, cz), 180)
        # Ranger station
        _place("ranger_station", Vector3(cx - 25, 0, cz - 25), 90)
        # Deer stand
        _place("deer_stand", Vector3(cx + 25, 0, cz + 25))
        # Camping tent
        _place("camping_tent", Vector3(cx + 25, 0, cz - 25))
        # Cave entrance
        _place("cave_entrance", Vector3(cx - 25, 0, cz + 25), 90)
        # Dense trees (20 scattered)
        var rng := RandomNumberGenerator.new()
        rng.seed = int(origin.x) * 31 + int(origin.z) * 17
        for i in range(20):
                var tx := cx + rng.randf_range(-35, 35)
                var tz := cz + rng.randf_range(-35, 35)
                # Skip if too close to cabin
                if Vector2(tx - cx, tz - cz).length() < 8: continue
                var trees := ["pine_tree", "oak_tree", "birch_tree", "pine_tree", "pine_tree"]
                var pick: String = trees[rng.randi() % trees.size()]
                _place(pick, Vector3(tx, 0, tz), rng.randf() * 360, rng.randf_range(0.8, 1.3))
        # Bushes, ferns, mushrooms scattered
        for i in range(8):
                var bx := cx + rng.randf_range(-30, 30)
                var bz := cz + rng.randf_range(-30, 30)
                _place("bush", Vector3(bx, 0, bz), rng.randf() * 360)
        for i in range(6):
                _place("fern", Vector3(cx + rng.randf_range(-30, 30), 0, cz + rng.randf_range(-30, 30)))
        _place("mushrooms", Vector3(cx - 15, 0, cz - 15))
        _place("mushrooms", Vector3(cx + 15, 0, cz + 15))
        _place("fallen_log", Vector3(cx - 20, 0, cz + 10), 30)

# === SUBURBIA ===
func _fill_suburbia(origin: Vector3):
        var houses := ["suburban_house_v2", "bungalow", "two_story_colonial", "house_ranch", "house_cape_cod", "house_victorian", "house_tudor", "house_cottage_stone", "house_modern"]
        var rng := RandomNumberGenerator.new()
        rng.seed = int(origin.x) * 13 + int(origin.z) * 7
        # 4 houses per block (2x2 grid inside block)
        for hx in [-1, 1]:
                for hz in [-1, 1]:
                        var house_pos := Vector3(origin.x + BLOCK_SIZE * 0.5 + hx * 20, 0, origin.z + BLOCK_SIZE * 0.5 + hz * 20)
                        var pick: String = houses[rng.randi() % houses.size()]
                        var rot := 180.0 if hz < 0 else 0.0
                        _place(pick, house_pos, rot)
                        # Garage beside house
                        _place("garage_detached", house_pos + Vector3(12, 0, 0), rot)
                        # Mailbox at curb
                        var mailbox_pos := house_pos + Vector3(0, 0, 12 if hz < 0 else -12)
                        _place("mailbox", mailbox_pos)
                        # Trash can
                        _place("trash_can", house_pos + Vector3(-4, 0, 6 if hz < 0 else -6))
                        # Bush
                        _place("bush", house_pos + Vector3(-6, 0, 0))
        # Street lights at block corners
        for cx in [10, 70]:
                for cz in [10, 70]:
                        _place("street_light", Vector3(origin.x + cx, 0, origin.z + cz))
        # Fire hydrant
        _place("fire_hydrant", Vector3(origin.x + 40, 0, origin.z + 40))
        # Trees scattered
        for i in range(4):
                _place("oak_tree", Vector3(origin.x + rng.randf_range(10, 70), 0, origin.z + rng.randf_range(10, 70)), 0, rng.randf_range(0.9, 1.2))

# === PARK ===
func _fill_park(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Park ground color override (brighter green)
        _plane("ParkGround_%d_%d" % [int(origin.x), int(origin.z)], Vector3(cx, 0, cz), BLOCK_SIZE - 10, BLOCK_SIZE - 10, C_PARK, 0.005)
        # Gazebo center
        _place("gazebo", Vector3(cx, 0, cz))
        # 4 benches around gazebo
        _place("bench_park", Vector3(cx - 8, 0, cz - 4), 90)
        _place("bench_park", Vector3(cx + 8, 0, cz - 4), -90)
        _place("bench_park", Vector3(cx - 8, 0, cz + 4), 90)
        _place("bench_park", Vector3(cx + 8, 0, cz + 4), -90)
        # Picnic tables (4 corners of park)
        _place("picnic_table", Vector3(cx - 25, 0, cz - 25))
        _place("picnic_table", Vector3(cx + 25, 0, cz - 25))
        _place("picnic_table", Vector3(cx - 25, 0, cz + 25))
        _place("picnic_table", Vector3(cx + 25, 0, cz + 25))
        # Water fountain
        _place("water_fountain", Vector3(cx - 15, 0, cz))
        # Playground
        _place("playground_slide", Vector3(cx + 20, 0, cz - 15))
        _place("swing_set", Vector3(cx + 20, 0, cz + 15))
        _place("seesaw", Vector3(cx + 15, 0, cz))
        # Trees in circle around gazebo
        for i in range(8):
                var angle := float(i) * 45.0
                var r := 15.0
                var tx := cx + cos(deg_to_rad(angle)) * r
                var tz := cz + sin(deg_to_rad(angle)) * r
                var trees := ["oak_tree", "pine_tree", "birch_tree", "maple_tree", "willow_tree"]
                _place(trees[i % trees.size()], Vector3(tx, 0, tz), float(i * 53), rng_range(0.9, 1.3))
        # Flower patches
        for i in range(4):
                _place("flower_patch", Vector3(cx + rng_range(-20, 20), 0, cz + rng_range(-20, 20)))
        # Bushes
        for i in range(6):
                _place("bush", Vector3(cx + rng_range(-25, 25), 0, cz + rng_range(-25, 25)))
        # Park sign at "entrance"
        _place("park_sign", Vector3(origin.x + 5, 0, cz), 90)
        # Trash cans
        _place("trash_can", Vector3(cx - 20, 0, cz - 20))
        _place("trash_can", Vector3(cx + 20, 0, cz + 20))

# === FARMLAND ===
func _fill_farm(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Farmhouse (north)
        _place("farmhouse", Vector3(cx, 0, cz - 25), 180)
        # Barn (east)
        _place("barn", Vector3(cx + 25, 0, cz - 25), 180)
        # Tractor shed (west)
        _place("tractor_shed", Vector3(cx - 25, 0, cz - 25), 180)
        # Grain silo
        _place("grain_silo", Vector3(cx + 25, 0, cz))
        # Windmill
        _place("windmill", Vector3(cx - 25, 0, cz + 25))
        # Grain storage shed
        _place("grain_storage_shed", Vector3(cx - 25, 0, cz))
        # Crops (corn fields, 4 patches)
        _place("crop_field_corn", Vector3(cx, 0, cz + 20), 0, 1.5)
        _place("crop_field_corn", Vector3(cx + 15, 0, cz + 20), 0, 1.5)
        _place("crop_field_corn", Vector3(cx - 15, 0, cz + 20), 0, 1.5)
        # Hay bales scattered
        for i in range(5):
                var hx := cx + rng_range(-20, 20)
                var hz := cz + rng_range(-20, 20)
                _place("hay_bale", Vector3(hx, 0, hz))
        # Irrigation canal
        _place("irrigation_canal", Vector3(cx, 0, cz + 35), 90, 2.5)
        # Oak tree (shade tree)
        _place("oak_tree", Vector3(cx - 30, 0, cz - 30), 0, 1.4)
        # Tall grass
        _place("tall_grass", Vector3(cx + 10, 0, cz + 15))
        _place("tall_grass", Vector3(cx - 10, 0, cz + 15))
        # Garden gnome
        _place("garden_gnome", Vector3(cx + 5, 0, cz - 20))

# === COMMERCIAL ===
func _fill_commerce(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Storefronts along north edge
        _place("corner_store", Vector3(cx - 30, 0, cz - 30), 180)
        _place("grocery_store", Vector3(cx - 10, 0, cz - 30), 180)
        _place("store_pharmacy", Vector3(cx + 10, 0, cz - 30), 180)
        _place("store_supermarket", Vector3(cx + 30, 0, cz - 30), 180)
        # Gas station on SW corner
        _place("gas_station", Vector3(cx - 30, 0, cz + 30), 0)
        # Diner
        _place("diner", Vector3(cx - 10, 0, cz + 30), 0)
        # Auto repair
        _place("auto_repair_shop", Vector3(cx + 10, 0, cz + 30), 0)
        # Laundromat
        _place("laundromat", Vector3(cx + 30, 0, cz + 30), 0)
        # Parking lot center
        _plane("Parking_%d_%d" % [int(origin.x), int(origin.z)], Vector3(cx, 0, cz), 50, 50, Color(0.18, 0.18, 0.20, 1), 0.03)
        # Parking meters (4)
        _place("parking_meter", Vector3(cx - 15, 0, cz - 10))
        _place("parking_meter", Vector3(cx, 0, cz - 10))
        _place("parking_meter", Vector3(cx + 15, 0, cz - 10))
        # Dumpsters behind stores
        _place("dumpster", Vector3(cx - 25, 0, cz - 20))
        _place("dumpster", Vector3(cx + 25, 0, cz - 20))
        # Shopping cart (stray)
        _place("shopping_cart", Vector3(cx + 5, 0, cz + 5), 45)
        # Bollards
        _place("bollard", Vector3(cx - 30, 0, cz - 15))
        _place("bollard", Vector3(cx + 30, 0, cz - 15))
        # Street trees (small)
        _place("oak_tree", Vector3(cx - 15, 0, cz), 0, 0.7)
        _place("oak_tree", Vector3(cx + 15, 0, cz), 0, 0.7)

# === INDUSTRIAL ===
func _fill_industrial(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Warehouse (north)
        _place("warehouse_large", Vector3(cx - 20, 0, cz - 25), 180)
        # Factory (east)
        _place("factory_small", Vector3(cx + 20, 0, cz - 25), 180)
        # Storage tanks (3)
        _place("storage_tank", Vector3(cx - 30, 0, cz + 20))
        _place("storage_tank", Vector3(cx - 15, 0, cz + 20))
        _place("storage_tank", Vector3(cx, 0, cz + 20))
        # Loading dock
        _place("loading_dock", Vector3(cx + 20, 0, cz + 25))
        # Shipping containers (6 scattered, varied rotation)
        _place("shipping_container", Vector3(cx + 5, 0, cz - 5))
        _place("shipping_container", Vector3(cx + 10, 0, cz - 5), 90)
        _place("shipping_container", Vector3(cx + 15, 0, cz - 5))
        _place("shipping_container", Vector3(cx + 5, 0, cz + 5), 0)
        _place("shipping_container", Vector3(cx + 10, 0, cz + 5), 90)
        _place("shipping_container", Vector3(cx + 15, 0, cz + 5))
        # Chain link fence around perimeter
        _place("chain_link_fence", Vector3(cx, 0, origin.z + 5), 0, 3.0)
        _place("chain_link_fence", Vector3(cx, 0, origin.z + BLOCK_SIZE - 5), 0, 3.0)
        _place("chain_link_fence", Vector3(origin.x + 5, 0, cz), 90, 3.0)
        _place("chain_link_fence", Vector3(origin.x + BLOCK_SIZE - 5, 0, cz), 90, 3.0)
        # Dumpsters
        _place("dumpster", Vector3(cx + 25, 0, cz - 10))
        _place("dumpster", Vector3(cx + 25, 0, cz))
        # Dead tree
        _place("dead_tree", Vector3(cx - 30, 0, cz + 30))
        # Utility shed
        _place("utility_shed_metal", Vector3(cx - 30, 0, cz - 5))

# === BEACH ===
func _fill_beach(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Sand ground override
        _plane("Sand_%d_%d" % [int(origin.x), int(origin.z)], Vector3(cx, 0, cz), BLOCK_SIZE, BLOCK_SIZE, C_SAND, 0.005)
        # Water (south half)
        _plane("Water_%d_%d" % [int(origin.x), int(origin.z)], Vector3(cx, 0, cz + 20), BLOCK_SIZE, 40, C_WATER, -0.5)
        # Lighthouse
        _place("lighthouse", Vector3(cx - 30, 0, cz - 30))
        # Pier dock extending into water
        _place("pier_dock", Vector3(cx, 0, cz + 25), 90)
        # Fishing hut on stilts
        _place("fishing_hut", Vector3(cx + 20, 0, cz + 25))
        # Palm trees (5 scattered)
        _place("palm_tree", Vector3(cx - 15, 0, cz - 10), 0, 1.1)
        _place("palm_tree", Vector3(cx + 15, 0, cz - 10), 0, 0.9)
        _place("palm_tree", Vector3(cx, 0, cz - 25), 0, 1.0)
        _place("palm_tree", Vector3(cx - 25, 0, cz), 0, 1.0)
        _place("palm_tree", Vector3(cx + 25, 0, cz), 0, 1.1)
        # Benches
        _place("bench_park", Vector3(cx - 10, 0, cz - 25), 180)
        _place("bench_park", Vector3(cx + 10, 0, cz - 25), 180)
        # Trash cans
        _place("trash_can", Vector3(cx - 5, 0, cz - 25))
        _place("trash_can", Vector3(cx + 5, 0, cz - 25))
        # Gazebo (beach pavilion)
        _place("gazebo", Vector3(cx, 0, cz - 15))

# === WETLANDS ===
func _fill_wetland(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Water surface (south half)
        _plane("MarshWater_%d_%d" % [int(origin.x), int(origin.z)], Vector3(cx, 0, cz + 20), BLOCK_SIZE, 40, C_WATER, -0.3)
        # Fishing hut
        _place("fishing_hut", Vector3(cx, 0, cz + 25))
        # Marsh pier
        _place("marsh_pier", Vector3(cx, 0, cz + 10))
        # Boardwalks
        _place("boardwalk_section", Vector3(cx - 15, 0, cz + 15), 90, 2.0)
        _place("boardwalk_section", Vector3(cx + 15, 0, cz + 15), 90, 2.0)
        # Cattails (8 scattered)
        for i in range(8):
                var ang := float(i) * 45.0
                var r := 20.0
                var tx := cx + cos(deg_to_rad(ang)) * r
                var tz := cz + sin(deg_to_rad(ang)) * r + 15
                _place("cattail", Vector3(tx, 0, tz))
        # Marsh grass
        _place("marsh_grass", Vector3(cx - 25, 0, cz + 20), 0, 1.2)
        _place("marsh_grass", Vector3(cx + 25, 0, cz + 20), 0, 1.2)
        _place("marsh_grass", Vector3(cx, 0, cz + 30), 0, 1.5)
        # Willow trees (wetland signature)
        _place("willow_tree", Vector3(cx - 25, 0, cz - 25), 0, 1.2)
        _place("willow_tree", Vector3(cx + 25, 0, cz - 25), 0, 1.0)
        # Tall grass
        _place("tall_grass", Vector3(cx - 10, 0, cz - 10))
        _place("tall_grass", Vector3(cx + 10, 0, cz - 10))
        # Mushrooms (foragable)
        _place("mushrooms", Vector3(cx - 15, 0, cz))
        # Bush
        _place("bush", Vector3(cx + 15, 0, cz))

# === DOWNTOWN ===
func _fill_downtown(origin: Vector3):
        var cx := origin.x + BLOCK_SIZE * 0.5
        var cz := origin.z + BLOCK_SIZE * 0.5
        # Highrise office (NE)
        _place("highrise_office", Vector3(cx + 20, 0, cz - 20), 180)
        # Apartment tower high (NW)
        _place("apartment_tower_high", Vector3(cx - 20, 0, cz - 20), 180)
        # Bank branch (SE)
        _place("bank_branch", Vector3(cx + 20, 0, cz + 20), 0)
        # Parking garage (SW)
        _place("parking_garage", Vector3(cx - 20, 0, cz + 20), 0)
        # Bollards (defensive, 8 around perimeter)
        for i in range(4):
                var off := float(i) * 15.0 - 22.5
                _place("bollard", Vector3(cx + off, 0, cz - 10))
                _place("bollard", Vector3(cx + off, 0, cz + 10))
        # Planter boxes with trees
        _place("planter_box", Vector3(cx - 10, 0, cz - 10))
        _place("planter_box", Vector3(cx + 10, 0, cz - 10))
        _place("planter_box", Vector3(cx - 10, 0, cz + 10))
        _place("planter_box", Vector3(cx + 10, 0, cz + 10))
        # Traffic light at intersection
        _place("traffic_light", Vector3(cx, 0, cz))
        # Street lights
        _place("street_light", Vector3(cx - 30, 0, cz - 30))
        _place("street_light", Vector3(cx + 30, 0, cz - 30))
        _place("street_light", Vector3(cx - 30, 0, cz + 30))
        _place("street_light", Vector3(cx + 30, 0, cz + 30))
        # Trash cans
        _place("trash_can", Vector3(cx - 10, 0, cz - 15))
        _place("trash_can", Vector3(cx + 10, 0, cz - 15))
        _place("trash_can", Vector3(cx - 10, 0, cz + 15))
        _place("trash_can", Vector3(cx + 10, 0, cz + 15))

# === PLAYER ===
func _setup_player():
        var player := CharacterBody3D.new()
        player.name = "Player"
        player.position = Vector3(MAP_SIZE * 0.5, 2, MAP_SIZE * 0.5)
        var cam := Camera3D.new()
        cam.name = "Camera3D"
        cam.fov = 75.0
        cam.near = 0.05
        cam.far = 300.0
        cam.position = Vector3(0, 1.65, 0)
        player.add_child(cam)
        var col := CollisionShape3D.new()
        col.name = "Col"
        var shape := CapsuleShape3D.new()
        shape.radius = 0.4
        shape.height = 1.8
        col.shape = shape
        col.position = Vector3(0, 0.9, 0)
        player.add_child(col)
        var script := GDScript.new()
        script.source_code = """extends CharacterBody3D
const WALK = 5.0
const SPRINT = 8.0
const SENS = 0.002
const FLY = 15.0
var spd = WALK
var fly_mode = false
func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(e):
    if e is InputEventMouseMotion:
        rotate_y(-e.relative.x * SENS)
        $Camera3D.rotate_x(-e.relative.y * SENS)
        $Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.5, 1.5)
    if e.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if e.is_action_pressed("fly_toggle"):
        fly_mode = !fly_mode
        if fly_mode:
            $Col.disabled = true
        else:
            $Col.disabled = false
func _physics_process(d):
    if fly_mode:
        var i = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
        if dir: velocity = dir * FLY
        else: velocity = velocity.move_toward(Vector3.ZERO, FLY * d * 5)
        if Input.is_action_pressed("jump"): velocity.y = FLY
        if Input.is_action_pressed("crouch"): velocity.y = -FLY
        move_and_slide()
        return
    if not is_on_floor(): velocity.y -= 9.8 * d
    if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = 4.5
    spd = SPRINT if Input.is_action_pressed("sprint") else WALK
    var i = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
    if dir: velocity.x = dir.x * spd; velocity.z = dir.z * spd
    else: velocity.x = move_toward(velocity.x, 0, spd*d*10); velocity.z = move_toward(velocity.z, 0, spd*d*10)
    move_and_slide()"""
        player.set_script(script)
        city_root.add_child(player)
        player.owner = city_root
        placed += 1
        print("  ✓ Player at center, fly mode toggle added")

# === Helpers ===
func rng_range(lo: float, hi: float) -> float:
        var rng := RandomNumberGenerator.new()
        rng.randomize()
        return rng.randf_range(lo, hi)
