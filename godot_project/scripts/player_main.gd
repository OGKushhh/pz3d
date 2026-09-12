extends CharacterBody3D

# First-person controller for the main scene.
# WASD movement, mouse look, sprint, gravity, jump (jump action optional).
# Camera is a child named "Camera3D"; collision shape is "CollisionShape3D".

const WALK_SPEED := 5.0
const SPRINT_SPEED := 8.0
const MOUSE_SENSITIVITY := 0.002
const GRAVITY := 9.8
const EYE_HEIGHT := 1.65

var yaw: float = 0.0
var pitch: float = 0.0

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
    print("[Player] _ready: pos=%v" % global_position)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    camera.position = Vector3(0, EYE_HEIGHT, 0)
    camera.make_current()
    print("[Player] camera local_pos=%v global_pos=%v" % [camera.position, camera.global_position])

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        yaw -= event.relative.x * MOUSE_SENSITIVITY
        pitch -= event.relative.y * MOUSE_SENSITIVITY
        pitch = clamp(pitch, -1.5, 1.5)
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    rotation.y = yaw
    camera.rotation.x = pitch
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var speed: float = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
    if dir:
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed * delta * 10)
        velocity.z = move_toward(velocity.z, 0, speed * delta * 10)
    move_and_slide()
