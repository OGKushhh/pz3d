extends CharacterBody3D

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
		$Col.disabled = fly_mode

func _physics_process(d):
	if fly_mode:
		var i = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
		if dir:
			velocity = dir * FLY
		else:
			velocity = velocity.move_toward(Vector3.ZERO, FLY * d * 5)
		if Input.is_action_pressed("jump"):
			velocity.y = FLY
		if Input.is_action_pressed("crouch"):
			velocity.y = -FLY
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= 9.8 * d
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 4.5
	spd = SPRINT if Input.is_action_pressed("sprint") else WALK
	var i = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir = (transform.basis * Vector3(i.x, 0, i.y)).normalized()
	if dir:
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0, spd * d * 10)
		velocity.z = move_toward(velocity.z, 0, spd * d * 10)
	move_and_slide()
