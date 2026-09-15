extends CharacterBody3D

# Test player for shooting range — simple FPS controller with weapon system.
# WASD to move, mouse to look, left click to shoot, 1/2/3/4 to switch weapons.

const SPEED := 8.0
const MOUSE_SENS := 0.002

var _yaw: float = 0.0
var _pitch: float = 0.0
var _camera: Camera3D
var _weapon_system: Node
var _weapon_viewmodel: Node

func _ready() -> void:
        _camera = $Camera3D
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        # Phase #5: set player collision_layer to "player" (layer 2 = bit 1, value 2)
        collision_layer = 2  # player layer
        collision_mask = 1   # collide with world only
        # Setup weapon system
        _weapon_system = preload("res://weapons/weapon_system.gd").new()
        _weapon_system.name = "WeaponSystem"
        _camera.add_child(_weapon_system)
        _weapon_system.equip("pistol")
        # Set world root to this player's parent (the scene root)
        _weapon_system.set_world_root(get_parent())
        # Setup weapon viewmodel (visible gun in first person)
        _weapon_viewmodel = preload("res://weapons/weapon_viewmodel.gd").new()
        _weapon_viewmodel.name = "WeaponViewModel"
        _camera.add_child(_weapon_viewmodel)

func _input(event: InputEvent) -> void:
        if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                _yaw -= event.relative.x * MOUSE_SENS
                _pitch -= event.relative.y * MOUSE_SENS
                _pitch = clamp(_pitch, -PI/2 + 0.1, PI/2 - 0.1)
        if event is InputEventKey and event.pressed:
                # Phase #3: emit signals instead of calling weapon_system directly
                var sb := get_node_or_null("/root/SignalBus")
                match event.keycode:
                        KEY_1: _switch_weapon("pistol")
                        KEY_2: _switch_weapon("rifle")
                        KEY_3: _switch_weapon("shotgun")
                        KEY_4: _switch_weapon("sniper_rifle")
                        KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
                # Phase #3: emit fire signal instead of calling fire() directly
                var sb := get_node_or_null("/root/SignalBus")
                if sb: sb.fire_input.emit()

# Camera feel state (head bob + crouch + sprint FOV + land dip)
var _bob_timer: float = 0.0
var _cam_base_y: float = 0.0
var _cam_crouch_y: float = -0.65
var _is_crouching: bool = false
var _is_sprinting: bool = false
var _was_on_floor: bool = true
var _land_dip: float = 0.0
var _base_fov: float = 75.0

func _physics_process(delta: float) -> void:
        # Apply look rotation + recoil offset
        var recoil: Vector2 = _weapon_system.get_recoil_offset()
        _camera.rotation.y = _yaw + deg_to_rad(recoil.y)
        _camera.rotation.x = _pitch + deg_to_rad(recoil.x)
        # Crouch + sprint state
        _is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
        _is_sprinting = Input.is_action_pressed("sprint") and not _is_crouching
        var spd: float = 2.0 if _is_crouching else (SPEED * 1.5 if _is_sprinting else SPEED)
        # Movement
        var input_dir := Vector2.ZERO
        if Input.is_action_pressed("move_forward"): input_dir.y -= 1
        if Input.is_action_pressed("move_back"): input_dir.y += 1
        if Input.is_action_pressed("move_left"): input_dir.x -= 1
        if Input.is_action_pressed("move_right"): input_dir.x += 1
        input_dir = input_dir.normalized()
        var forward := -_camera.global_transform.basis.z
        forward.y = 0
        forward = forward.normalized()
        var right := _camera.global_transform.basis.x
        right.y = 0
        right = right.normalized()
        var vel := (forward * -input_dir.y + right * input_dir.x) * spd
        velocity = vel
        if not is_on_floor():
                velocity.y -= 9.8 * delta
        if Input.is_action_just_pressed("jump") and is_on_floor():
                velocity.y = 4.5
        move_and_slide()
        # Landing dip
        if not _was_on_floor and is_on_floor():
                _land_dip = 1.0
        _was_on_floor = is_on_floor()
        # Camera feel: head bob + crouch + FOV + land dip
        var moving := input_dir != Vector2.ZERO and is_on_floor()
        _update_camera_feel(delta, moving)

func _update_camera_feel(delta: float, moving: bool) -> void:
        # Crouch Y
        var target_y: float = _cam_crouch_y if _is_crouching else _cam_base_y
        # Head bob
        var bob_y: float = 0.0
        var bob_z: float = 0.0
        if moving and not _is_crouching:
                var freq: float = 12.0 if _is_sprinting else 8.0
                _bob_timer += delta * freq
                var amp: float = 0.05 if _is_sprinting else 0.04
                bob_y = sin(_bob_timer) * amp
                bob_z = sin(_bob_timer * 0.5) * 0.5
        else:
                _bob_timer = 0.0
        # Land dip
        var land_y: float = 0.0
        if _land_dip > 0.0:
                land_y = -0.15 * _land_dip
                _land_dip = max(0.0, _land_dip - delta * 4.0)
        # Apply
        var combined_y: float = target_y + bob_y + land_y
        _camera.position.y = lerp(_camera.position.y, combined_y, delta * 12.0)
        _camera.rotation.z = lerp(_camera.rotation.z, deg_to_rad(bob_z), delta * 10.0)
        # Sprint FOV
        var target_fov: float = 80.0 if _is_sprinting else _base_fov
        _camera.fov = lerp(_camera.fov, target_fov, delta * 8.0)

# Switch weapon: updates both weapon_system (gameplay) + weapon_viewmodel (visual)
func _switch_weapon(weapon_class: String) -> void:
        if _weapon_system:
                _weapon_system.equip(weapon_class)
        if _weapon_viewmodel:
                _weapon_viewmodel.equip(weapon_class)
        # Also emit signal so SignalBus listeners (if any) get notified
        var sb := get_node_or_null("/root/SignalBus")
        if sb:
                sb.weapon_switch.emit(weapon_class)
