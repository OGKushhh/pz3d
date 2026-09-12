# HandCrafedCity — manually builds a well-organized city block.
# Run: godot --headless --path godot_project --script res://scripts/build_test_city.gd
# Saves to: res://scenes/test_city.tscn
#
# This is NOT procedural. Every position is hand-calculated.
# Purpose: show what the city SHOULD look like. Reference for future procedural gen.
extends SceneTree

const ROAD_W := 8.0
const SIDEWALK_W := 1.5
const GRASS_W := 2.5
const LOT_W := 20.0
const LOT_D := 16.0
const BUILDING_OFFSET := ROAD_W * 0.5 + SIDEWALK_W + GRASS_W  # 8.0

# Colors
const C_ROAD := Color(0.12, 0.12, 0.14, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_GROUND := Color(0.25, 0.42, 0.18, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)

var city_root: Node3D
var placed: int = 0

# Asset paths — loaded from manifest
var ASSETS: Dictionary = {}

func _init():
        print("=== Hand-Crafted City Builder ===")
        _load_manifest()
        city_root = Node3D.new()
        city_root.name = "TestCity"

        _setup_sky()
        _setup_sun()
        _setup_ground()

        # Build a 3x3 grid of city blocks
        # Road grid: roads at Z=0, Z=80, Z=160 and X=0, X=80, X=160
        # Each block is 80m × 80m (4 lots × 20m each side)
        for road_z in [0.0, 80.0, 160.0]:
                _build_horizontal_road(road_z)
        for road_x in [0.0, 80.0, 160.0]:
                _build_vertical_road(road_x)

        # Place buildings along each road
        _place_buildings_along_road(0.0, true)   # horizontal road at Z=0
        _place_buildings_along_road(80.0, true)   # Z=80
        _place_buildings_along_road(160.0, true)  # Z=160
        _place_buildings_along_road(0.0, false)   # vertical road at X=0
        _place_buildings_along_road(80.0, false)  # X=80
        _place_buildings_along_road(160.0, false) # X=160

        # Place street furniture
        _place_street_lights()
        _place_fire_hydrants()
        _place_mailboxes()

        # Park in center block
        _place_park(40.0, 40.0)

        # Player
        _setup_player()

        # Save scene
        var scene := PackedScene.new()
        scene.pack(city_root)
        var err := ResourceSaver.save(scene, "res://scenes/test_city.tscn")
        if err == OK:
                print("✅ Scene saved: res://scenes/test_city.tscn")
                print("   Objects placed: %d" % placed)
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

func _place(asset_name: String, pos: Vector3, rot_y: float = 0.0) -> Node3D:
        var scene := _get_asset(asset_name)
        if scene == null:
                print("  ⚠ asset not found: ", asset_name)
                return null
        var inst := scene.instantiate()
        inst.position = pos
        inst.rotate_y(deg_to_rad(rot_y))
        inst.name = asset_name + "_" + str(placed)
        city_root.add_child(inst)
        inst.owner = city_root
        placed += 1
        return inst

func _mesh(name: String, pos: Vector3, size: Vector3, color: Color) -> void:
        var mi := MeshInstance3D.new()
        mi.name = name
        var box := BoxMesh.new()
        box.size = size
        mi.mesh = box
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.85
        mi.material_override = mat
        mi.position = pos
        city_root.add_child(mi)
        mi.owner = city_root
        placed += 1

func _plane(name: String, pos: Vector3, size_x: float, size_z: float, color: Color, y_offset: float = 0.0) -> void:
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
        sun.transform.origin = Vector3(-40, 60, -40)
        sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
        sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
        sun.light_color = Color(1.0, 0.95, 0.80, 1)
        sun.light_energy = 2.0
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 80.0
        city_root.add_child(sun)
        sun.owner = city_root

func _setup_ground():
        # Collision floor
        var body := StaticBody3D.new()
        body.name = "Ground"
        body.position = Vector3(80, 0, 80)  # center of our 160×160 area
        city_root.add_child(body)
        body.owner = city_root

        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(200, 1, 200)
        col.shape = shape
        body.add_child(col)
        col.owner = city_root

        # Visible ground (green grass everywhere)
        _plane("GroundMesh", Vector3(80, 0, 80), 200, 200, C_GROUND)

func _build_horizontal_road(z: float):
        # Road surface (3 roads × 200m long, centered on the grid)
        var road_center := 80.0  # center X
        _plane("Road_H_%d" % int(z), Vector3(road_center, 0.02, z), 200, ROAD_W, C_ROAD)
        # Center lane line
        _plane("Lane_H_%d" % int(z), Vector3(road_center, 0.03, z), 200, 0.15, C_LANE)
        # Sidewalks (both sides)
        var sw_off := ROAD_W * 0.5 + SIDEWALK_W * 0.5
        _plane("SW_S_%d" % int(z), Vector3(road_center, 0.05, z + sw_off), 200, SIDEWALK_W, C_SIDEWALK)
        _plane("SW_N_%d" % int(z), Vector3(road_center, 0.05, z - sw_off), 200, SIDEWALK_W, C_SIDEWALK)
        # Grass strips
        var gs_off := ROAD_W * 0.5 + SIDEWALK_W + GRASS_W * 0.5
        _plane("GS_S_%d" % int(z), Vector3(road_center, 0.03, z + gs_off), 200, GRASS_W, C_GRASS)
        _plane("GS_N_%d" % int(z), Vector3(road_center, 0.03, z - gs_off), 200, GRASS_W, C_GRASS)

func _build_vertical_road(x: float):
        var road_center := 80.0  # center Z
        _plane("Road_V_%d" % int(x), Vector3(x, 0.02, road_center), ROAD_W, 200, C_ROAD)
        _plane("Lane_V_%d" % int(x), Vector3(x, 0.03, road_center), 0.15, 200, C_LANE)
        var sw_off := ROAD_W * 0.5 + SIDEWALK_W * 0.5
        _plane("SW_E_%d" % int(x), Vector3(x + sw_off, 0.05, road_center), SIDEWALK_W, 200, C_SIDEWALK)
        _plane("SW_W_%d" % int(x), Vector3(x - sw_off, 0.05, road_center), SIDEWALK_W, 200, C_SIDEWALK)
        var gs_off := ROAD_W * 0.5 + SIDEWALK_W + GRASS_W * 0.5
        _plane("GS_E_%d" % int(x), Vector3(x + gs_off, 0.03, road_center), GRASS_W, 200, C_GRASS)
        _plane("GS_W_%d" % int(x), Vector3(x - gs_off, 0.03, road_center), GRASS_W, 200, C_GRASS)

func _place_buildings_along_road(road_pos: float, horizontal: bool):
        # House variants to cycle through
        var houses := ["suburban_house_v2", "two_story_colonial", "bungalow", "house_modern", "house_split_level"]
        var tree_types := ["oak_tree", "pine_tree", "birch_tree"]
        var h := 0  # house index

        for side in [-1, 1]:
                # Building center offset from road centerline
                var offset := BUILDING_OFFSET + LOT_D * 0.5
                # Place lots along the road
                for lot_idx in range(-4, 5):
                        var lot_center: float = float(lot_idx) * LOT_W + LOT_W * 0.5
                        # Skip intersection area (±5m from cross road)
                        for cross in [0.0, 80.0, 160.0]:
                                if abs(lot_center - cross) < LOT_W * 0.5 + 5.0:
                                        lot_center = -999  # mark as skip
                                        break
                        if lot_center < -100:
                                continue

                        var pos: Vector3
                        var rot_y: float
                        if horizontal:
                                pos = Vector3(lot_center, 0, road_pos + float(side) * offset)
                                rot_y = 0.0 if side < 0 else 180.0
                        else:
                                pos = Vector3(road_pos + float(side) * offset, 0, lot_center)
                                rot_y = 90.0 if side < 0 else -90.0

                        # Place building
                        var house_name: String = houses[h % houses.size()]
                        _place(house_name, pos, rot_y)
                        h += 1

                        # Place tree in grass strip (offset toward road)
                        var tree_offset := BUILDING_OFFSET - GRASS_W * 0.5
                        var tree_pos: Vector3
                        if horizontal:
                                tree_pos = Vector3(lot_center + 3.0, 0, road_pos + float(side) * tree_offset)
                        else:
                                tree_pos = Vector3(road_pos + float(side) * tree_offset, 0, lot_center + 3.0)
                        var tree_name: String = tree_types[h % tree_types.size()]
                        _place(tree_name, tree_pos, float((h * 37) % 360))

func _place_street_lights():
        var light_off := BUILDING_OFFSET - GRASS_W * 0.5  # grass strip center
        for road_z in [0.0, 80.0, 160.0]:
                for x in range(-60, 141, 25):
                        if abs(x) < 5 or abs(x - 80) < 5 or abs(x - 160) < 5:
                                continue  # skip intersections
                        _place("street_light", Vector3(float(x), 0, road_z + light_off), 0)
                        _place("street_light", Vector3(float(x), 0, road_z - light_off), 180)
        for road_x in [0.0, 80.0, 160.0]:
                for z in range(-60, 141, 25):
                        if abs(z) < 5 or abs(z - 80) < 5 or abs(z - 160) < 5:
                                continue
                        _place("street_light", Vector3(road_x + light_off, 0, float(z)), -90)
                        _place("street_light", Vector3(road_x - light_off, 0, float(z)), 90)

func _place_fire_hydrants():
        var corner_off := ROAD_W * 0.5 + SIDEWALK_W + 1.0
        for x_road in [0.0, 80.0, 160.0]:
                for z_road in [0.0, 80.0, 160.0]:
                        _place("fire_hydrant", Vector3(x_road + corner_off, 0, z_road + corner_off), 0)

func _place_mailboxes():
        for road_z in [0.0, 80.0, 160.0]:
                for x in [-30, 10, 50, 90, 130]:
                        if abs(x) < 5 or abs(x - 80) < 5 or abs(x - 160) < 5:
                                continue
                        var sw_off := ROAD_W * 0.5 + SIDEWALK_W * 0.5
                        _place("mailbox", Vector3(float(x) + 3, 0, road_z + sw_off + 0.2), 90)

func _place_park(cx: float, cz: float):
        # Park in the center block (between roads 0 and 80)
        # Benches, picnic table, playground, trees in a circle
        _place("bench_park", Vector3(cx - 6, 0, cz - 4), 90)
        _place("bench_park", Vector3(cx + 6, 0, cz - 4), -90)
        _place("picnic_table", Vector3(cx, 0, cz - 8), 0)
        _place("playground_slide", Vector3(cx - 8, 0, cz + 4), 0)
        _place("swing_set", Vector3(cx + 4, 0, cz + 6), 0)
        _place("water_fountain", Vector3(cx + 8, 0, cz - 2), 0)
        _place("garden_gnome", Vector3(cx - 4, 0, cz + 8), 37.0)

        # Trees in a circle around the park
        for i in range(8):
                var angle := float(i) * 45.0
                var r := 15.0
                var tx := cx + cos(deg_to_rad(angle)) * r
                var tz := cz + sin(deg_to_rad(angle)) * r
                var tree_name: String = ["oak_tree", "pine_tree", "birch_tree"][i % 3]
                _place(tree_name, Vector3(tx, 0, tz), float(i * 53))

        # Planter boxes near park entrance
        _place("planter_box", Vector3(cx - 2, 0, cz - 12), 0)
        _place("planter_box", Vector3(cx + 2, 0, cz - 12), 0)

func _setup_player():
        var player := CharacterBody3D.new()
        player.name = "Player"
        player.position = Vector3(40, 2, 40)  # center of map, eye level

        var cam := Camera3D.new()
        cam.name = "Camera3D"
        cam.fov = 75.0
        cam.near = 0.05
        cam.far = 200.0
        cam.position = Vector3(0, 1.65, 0)  # EYE HEIGHT = 1.65m
        player.add_child(cam)

        var col := CollisionShape3D.new()
        col.name = "Col"
        var shape := CapsuleShape3D.new()
        shape.radius = 0.4
        shape.height = 1.8
        col.shape = shape
        col.position = Vector3(0, 0.9, 0)
        player.add_child(col)

        # Movement script
        var script := GDScript.new()
        script.source_code = """extends CharacterBody3D
const WALK = 5.0
const SPRINT = 8.0
const SENS = 0.002
var spd = WALK
func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(e):
    if e is InputEventMouseMotion:
        rotate_y(-e.relative.x * SENS)
        $Camera3D.rotate_x(-e.relative.y * SENS)
        $Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.5, 1.5)
    if e.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _physics_process(d):
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
        print("  ✓ Player at eye height 1.65m")
