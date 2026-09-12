extends CharacterBody3D

# First-person controller for Mazar Alpha
# WASD movement, mouse look, sprint, crouch, jump

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const CROUCH_SPEED = 2.5
const MOUSE_SENSITIVITY = 0.002
const JUMP_VELOCITY = 4.5
const EYE_HEIGHT = 1.65
const CROUCH_HEIGHT = 0.9

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = WALK_SPEED
var is_crouching = false

@onready var camera = $Camera3D
@onready var collision_shape = $CollisionShape3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Set initial camera height
	camera.position.y = EYE_HEIGHT

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate camera (pitch) and body (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Clamp pitch so you can't flip
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Crouch
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		current_speed = CROUCH_SPEED
		camera.position.y = lerp(camera.position.y, CROUCH_HEIGHT, delta * 10)
		collision_shape.shape.height = CROUCH_HEIGHT + 0.2
		collision_shape.position.y = (CROUCH_HEIGHT + 0.2) / 2
	else:
		is_crouching = false
		# Sprint
		if Input.is_action_pressed("sprint"):
			current_speed = SPRINT_SPEED
		else:
			current_speed = WALK_SPEED
		camera.position.y = lerp(camera.position.y, EYE_HEIGHT, delta * 10)
		collision_shape.shape.height = 1.8
		collision_shape.position.y = 0.9

	# Movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta * 10)

	move_and_slide()
