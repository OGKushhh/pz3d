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

func _physics_process(delta: float) -> void:
        # Apply look rotation + recoil offset
        var recoil: Vector2 = _weapon_system.get_recoil_offset()
        _camera.rotation.y = _yaw + deg_to_rad(recoil.y)
        _camera.rotation.x = _pitch + deg_to_rad(recoil.x)
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
        var vel := (forward * -input_dir.y + right * input_dir.x) * SPEED
        velocity = vel
        move_and_slide()

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
