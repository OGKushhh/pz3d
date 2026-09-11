#!/usr/bin/env python3
"""Generate a proper Godot scene (.tscn) that loads actual GLB files."""
import os
from pathlib import Path

GODOT_PROJECT = Path("/home/z/my-project/godot_project")
ASSETS_DIR = GODOT_PROJECT / "assets"

# Assets to place in the Suburbia test scene
# (asset_path, position_x, position_y, position_z, rotation_y, scale)
SCENE_ASSETS = [
    # === 5 HOUSES along a street ===
    ("buildings/suburban_house_v2.glb", -15, 0, -10, 0, 1),
    ("buildings/two_story_colonial.glb", 15, 0, -10, 0, 1),
    ("buildings/bungalow.glb", -15, 0, 10, 180, 1),
    ("buildings/house_modern.glb", 15, 0, 10, 180, 1),
    ("buildings/house_split_level.glb", 0, 0, -25, 0, 1),

    # === SHEDS behind houses ===
    ("buildings/shed.glb", -20, 0, -15, 90, 1),
    ("buildings/garden_shed_wood.glb", 20, 0, -15, -90, 1),

    # === TREES along the street ===
    ("foliage/oak_tree.glb", -8, 0, -5, 0, 1),
    ("foliage/oak_tree.glb", 8, 0, -5, 0, 1),
    ("foliage/oak_tree.glb", -8, 0, 5, 0, 1),
    ("foliage/pine_tree.glb", 8, 0, 5, 0, 1),
    ("foliage/birch_tree.glb", 0, 0, 15, 0, 1),

    # === BUSHES scattered ===
    ("foliage/bush.glb", -12, 0, -12, 0, 1),
    ("foliage/bush.glb", 12, 0, -12, 0, 1),
    ("foliage/bush.glb", -12, 0, 12, 0, 1),
    ("foliage/bush.glb", 12, 0, 12, 0, 1),

    # === STREET LIGHTS ===
    ("environment/street_light.glb", -10, 0, 0, 0, 1),
    ("environment/street_light.glb", 10, 0, 0, 180, 1),

    # === MAILBOXES ===
    ("environment/mailbox.glb", -18, 0, -8, 90, 1),
    ("environment/mailbox.glb", 18, 0, -8, -90, 1),

    # === TRASH CANS ===
    ("environment/trash_can.glb", -12, 0, -8, 0, 1),
    ("environment/trash_can.glb", 12, 0, -8, 0, 1),

    # === FENCE SEGMENTS ===
    ("environment/picket_fence.glb", -13, 0, -10, 90, 1),
    ("environment/picket_fence.glb", -11, 0, -10, 90, 1),
    ("environment/picket_fence.glb", 13, 0, -10, 90, 1),
    ("environment/picket_fence.glb", 11, 0, -10, 90, 1),
    ("environment/picket_fence.glb", -13, 0, 10, 90, 1),
    ("environment/picket_fence.glb", -11, 0, 10, 90, 1),
    ("environment/picket_fence.glb", 13, 0, 10, 90, 1),
    ("environment/picket_fence.glb", 11, 0, 10, 90, 1),

    # === FIRE HYDRANT ===
    ("environment/fire_hydrant.glb", 0, 0, 0, 0, 1),

    # === PLAYGROUND ===
    ("environment/playground_slide.glb", -25, 0, 15, 0, 1),
    ("environment/swing_set.glb", -25, 0, 20, 0, 1),
    ("environment/picnic_table.glb", -22, 0, 18, 0, 1),

    # === SCHOOL BUS (parked) ===
    ("environment/school_bus.glb", 25, 0, 18, 90, 1),

    # === BENCH ===
    ("environment/bench_park.glb", 5, 0, 15, 180, 1),
    ("environment/bench_park.glb", -5, 0, 15, 180, 1),

    # === GARDEN GNOME ===
    ("environment/garden_gnome.glb", -16, 0, -14, 0, 1),
    ("environment/garden_gnome.glb", 16, 0, -14, 0, 1),
]

# Build the .tscn file
lines = []
lines.append('[gd_scene load_steps=4 format=3 uid="uid://mazar_suburbia_test"]')
lines.append('')
lines.append('[sub_resource type="BoxShape3D" id="ground_col"]')
lines.append('size = Vector3(200, 1, 200)')
lines.append('')
lines.append('[sub_resource type="Environment" id="env"]')
lines.append('background_mode = 1')
lines.append('background_color = Color(0.35, 0.38, 0.42, 1)')
lines.append('ambient_light_source = 2')
lines.append('ambient_light_color = Color(0.45, 0.48, 0.52, 1)')
lines.append('ambient_light_energy = 0.6')
lines.append('fog_enabled = true')
lines.append('fog_light_color = Color(0.35, 0.38, 0.42, 1)')
lines.append('fog_density = 0.012')
lines.append('fog_aerial_perspective = 0.5')
lines.append('')
lines.append('[sub_resource type="GDScript" id="player_script"]')
lines.append('resource_name = "player_controller"')
lines.append('script/source = """extends CharacterBody3D')
lines.append('')
lines.append('const WALK_SPEED = 5.0')
lines.append('const SPRINT_SPEED = 8.0')
lines.append('const MOUSE_SENS = 0.002')
lines.append('const EYE_HEIGHT = 1.65')
lines.append('var gravity = 9.8')
lines.append('var current_speed = WALK_SPEED')
lines.append('@onready var camera = $Camera3D')
lines.append('')
lines.append('func _ready():')
lines.append('    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED')
lines.append('    camera.position.y = EYE_HEIGHT')
lines.append('')
lines.append('func _input(event):')
lines.append('    if event is InputEventMouseMotion:')
lines.append('        rotate_y(-event.relative.x * MOUSE_SENS)')
lines.append('        camera.rotate_x(-event.relative.y * MOUSE_SENS)')
lines.append('        camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)')
lines.append('    if event.is_action_pressed("ui_cancel"):')
lines.append('        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE')
lines.append('')
lines.append('func _physics_process(delta):')
lines.append('    if not is_on_floor():')
lines.append('        velocity.y -= gravity * delta')
lines.append('    if Input.is_action_just_pressed("jump") and is_on_floor():')
lines.append('        velocity.y = 4.5')
lines.append('    if Input.is_action_pressed("sprint"):')
lines.append('        current_speed = SPRINT_SPEED')
lines.append('    else:')
lines.append('        current_speed = WALK_SPEED')
lines.append('    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")')
lines.append('    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()')
lines.append('    if direction:')
lines.append('        velocity.x = direction.x * current_speed')
lines.append('        velocity.z = direction.z * current_speed')
lines.append('    else:')
lines.append('        velocity.x = move_toward(velocity.x, 0, current_speed * delta * 10)')
lines.append('        velocity.z = move_toward(velocity.z, 0, current_speed * delta * 10)')
lines.append('    move_and_slide()')
lines.append('"""')
lines.append('')
lines.append('[node name="SuburbiaTest" type="Node3D"]')
lines.append('')
lines.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
lines.append('environment = SubResource("env")')
lines.append('')
lines.append('[node name="Sun" type="DirectionalLight3D" parent="."]')
lines.append('transform = Transform3D(0.7, -0.5, 0.5, 0, 0.7, 0.7, -0.7, -0.5, 0.5, -50, 80, -50)')
lines.append('light_color = Color(1.0, 0.95, 0.85, 1)')
lines.append('light_energy = 2.5')
lines.append('shadow_enabled = true')
lines.append('directional_shadow_max_distance = 100.0')
lines.append('')

# Ground
lines.append('[node name="Ground" type="StaticBody3D" parent="."]')
lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)')
lines.append('')
lines.append('[node name="GroundMesh" type="CSGBox3D" parent="Ground"]')
lines.append('size = Vector3(200, 1, 200)')
lines.append('material = StandardMaterial3D.new()')
lines.append('material.albedo_color = Color(0.25, 0.45, 0.18, 1)')
lines.append('')
lines.append('[node name="GroundCollider" type="CollisionShape3D" parent="Ground"]')
lines.append('shape = SubResource("ground_col")')
lines.append('')

# Road (asphalt strip)
lines.append('[node name="Road" type="CSGBox3D" parent="."]')
lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.01, 0)')
lines.append('size = Vector3(200, 0.02, 6)')
lines.append('material = StandardMaterial3D.new()')
lines.append('material.albedo_color = Color(0.18, 0.18, 0.20, 1)')
lines.append('')

# Player
lines.append('[node name="Player" type="CharacterBody3D" parent="."]')
lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.65, 20)')
lines.append('script = SubResource("player_script")')
lines.append('')
lines.append('[node name="Camera3D" type="Camera3D" parent="Player"]')
lines.append('fov = 75.0')
lines.append('near = 0.05')
lines.append('far = 150.0')
lines.append('')
lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Player"]')
lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)')
lines.append('shape = CapsuleShape3D.new()')
lines.append('shape.radius = 0.4')
lines.append('shape.height = 1.8')
lines.append('')

# Place all assets
for i, (asset_path, x, y, z, rot_y, scale) in enumerate(SCENE_ASSETS):
    full_path = ASSETS_DIR / asset_path
    if full_path.exists():
        node_name = f"Asset_{i}_{Path(asset_path).stem}"
        res_path = f"res://assets/{asset_path}"
        lines.append(f'[node name="{node_name}" type="MeshInstance3D" parent="."]')
        lines.append(f'transform = Transform3D({scale}, 0, 0, 0, {scale}, 0, 0, 0, {scale}, {x}, {y}, {z})')
        lines.append(f'geometry = load("{res_path}")')
        lines.append('')
    else:
        # Pink box placeholder for missing assets
        node_name = f"MISSING_{i}_{Path(asset_path).stem}"
        lines.append(f'[node name="{node_name}" type="MeshInstance3D" parent="."]')
        lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, 0.5, {z})')
        lines.append(f'mesh = SphereMesh.new()')
        lines.append(f'mesh.radius = 0.5')
        lines.append(f'material_override = StandardMaterial3D.new()')
        lines.append(f'material_override.albedo_color = Color(1, 0, 1, 1)')
        lines.append('')

# Write the scene file
scene_path = GODOT_PROJECT / "scenes" / "test_suburbia.tscn"
scene_path.write_text('\n'.join(lines))
print(f"Scene saved: {scene_path}")
print(f"Assets placed: {len(SCENE_ASSETS)}")
print(f"Missing: {sum(1 for a, _, _, _, _, _ in SCENE_ASSETS if not (ASSETS_DIR / a).exists())}")
