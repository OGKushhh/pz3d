extends InteractionComponent

#region inspector settings
@export_group("Spinner Settings")
@export var rotating_object : Node3D
## Sets the spinning axis for the rotating object.
@export var spinning_axis : Vector3
## In radian
@export var rotation_speed : float = .05
## Move object as you rotate it
@export var rise_when_rotate : float = 0
## Keep rotating even when a spinner min or max value is hit.
@export var overrotate : bool = true
## Show when interacting
@export var interacting_gizmo : Node

@export_group("Spinner Input Settings")
## The amount of values needed to be collected before spin gets registered. This has the biggest impact to responsiveness. The lower, the more responsive, but also the easier to overtrigger.
@export var array_threshold : int = 10
@export var angle_threshold : float = 200.00
## The threshold for mouse movement change to register for spinning.
@export var mouse_effort : float = 1.0

@export_group("Spinner Signal Setting")
## The value the spinner starts at. Does not get saved.
@export var spinner_min_value : float = 0
## Spinner value starts at 0. If spinner goal gets hit, a signal is sent. Set bigger than min_value for clockwise, smaller for counter-clockwise. Set to 0 if not using. Does not get saved.
@export var spinner_goal_value : float = 0
## Destroys the object if spinner goal is met.
@export var destroy_on_goal_met : bool = false
@export var sound_on_goal_met : AudioStream


#region Cogito interaction variables
# Check for if this object is being interacted with
var is_being_controlled : bool
var player_interaction_component : PlayerInteractionComponent
signal object_state_updated(interaction_text : String)
#endregion

#region Spin detection variables
var current_angle : float = 0.0
var previous_angle : float = 0.0
var angle_array : Array = [0.0]
var spinning_clockwise : bool = false
var spinning_anticlockwise : bool = false
var array_size : int = 1
## Spinner value is used as a goal for signals. Eg. Spin from 0 to 100 to meet the goal.
var spinner_value : float = 0.0 :
	set(value):
		if spinner_min_value < spinner_goal_value : # Goal is going clockwise
			spinner_value = clampf(value, spinner_min_value, spinner_goal_value)
		elif spinner_min_value > spinner_goal_value : # Goal is going counter-clockwise
			spinner_value = clampf(value, spinner_goal_value, spinner_min_value)


signal spin_clockwise
signal spin_counterclockwise
signal spinner_goal_met

var screen_center : Vector2
#endregion


func _ready() -> void:
	is_being_controlled = false
	if interacting_gizmo: interacting_gizmo.set_visible(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		force_exit()


## Input event for input routing
func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		exit(player_interaction_component)


func interact(_player_interaction_component: PlayerInteractionComponent) -> void:
	if is_being_controlled:
		exit(_player_interaction_component)
	else:
		enter(_player_interaction_component)


func enter(_pic: PlayerInteractionComponent) -> void:
	player_interaction_component = _pic
	InputRouter.push(on_input)
	player_interaction_component.get_parent().toggled_interface.emit(true)

	screen_center = Vector2(get_window().size.x / 2, get_window().size.y / 2 )
	
	is_being_controlled = true
	if interacting_gizmo: interacting_gizmo.set_visible(true)

	if InputHelper.device_index == -1:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func exit(_player: PlayerInteractionComponent) -> void:
	if interacting_gizmo: interacting_gizmo.set_visible(false)
	_player.get_parent().toggled_interface.emit(false)
	InputRouter.pop()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_being_controlled = false


func force_exit() -> void:
	if is_being_controlled:
		exit(player_interaction_component)


func _physics_process(delta: float) -> void:
	if is_being_controlled:
		# Switch between mouse spin detection or gamepad spin detection based on input device
		if InputHelper.device_index == -1:
			mouse_spin_detection()
		else:
			gamepad_spin_detection()
		signal_bools()
		
		if ( spinner_goal_value < 0 and spinner_value <= spinner_goal_value ) or ( spinner_goal_value > 0 and spinner_value >= spinner_goal_value ) :
			spinner_goal_met.emit()
			if sound_on_goal_met :
				Audio.play_sound_3d(sound_on_goal_met).position = self.position
			if destroy_on_goal_met:
				get_parent().queue_free()


func mouse_spin_detection():
	var mouse_position := get_viewport().get_mouse_position()
	var mouse_pos_relative_to_center = mouse_position - screen_center
	
	current_angle = mouse_pos_relative_to_center.angle() * -1
	current_angle = rad_to_deg(current_angle)
	
	if abs(current_angle - previous_angle) > mouse_effort:
		spin_detection(current_angle)
	else:
		# if stick input doesn't pass dead zone, variables are reset.
		array_size = 1
		angle_array.resize(array_size)
		reset_bools()
		
	previous_angle = current_angle


# Detecting spinning the right thumb stick on gamepad
func gamepad_spin_detection():
	# get joystick vector
	var stick_rotation: Vector2 = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y), Input.get_joy_axis(0, JOY_AXIS_RIGHT_X))
	# reverse stick value (so it’s pointing the right way)
	#stick_rotation *= -1.0
	if stick_rotation.length() > 0.3:
		# convert to angle
		current_angle = stick_rotation.angle()
		current_angle = rad_to_deg(current_angle)

		spin_detection(current_angle)
	else:
		# if stick input doesn't pass dead zone, variables are reset.
		array_size = 1
		angle_array.resize(array_size)
		reset_bools()
	# finally, set previous frame's angle to current angle
	previous_angle = current_angle


func spin_detection(angle:float) -> void:
	# compare current angle to previous angle
	var angle_diff = previous_angle - angle
	# throw away angle differences if they’re too big a difference
	# this discounts the change that can happen between 179 to -179 or vice versa
	if (angle_diff >= angle_threshold) or (angle_diff <= -angle_threshold):
		pass
	else:
		angle_array.resize(array_size)
		angle_array.push_front(angle_diff)
		array_size += 1
	# check when list is long enough / enough time has passed
	if angle_array.size() > array_threshold:
		var mean = calculate_mean(angle_array)
		# depending on if the average is positive or negative, plus past a certain threshold
		# slow spinning will mean the threshold will not get met
		if mean < -10:
			spinning_anticlockwise = true
			spinning_clockwise = false
		elif mean > 10:
			spinning_clockwise = true
			spinning_anticlockwise = false
		elif mean < 10 or mean > -10:
			reset_bools()
		# once the array reaches the threshold size and the logic has been applied the array is cleared
		# this allows spinning to be detected in either direction without having to reset to deadzone to reset the array
		array_size = 1
		angle_array.resize(array_size)


func calculate_mean(arr):
	var sum = 0.0
	var count = arr.size()
	for i in arr:
		sum += i
	var mean : float = sum / count
	return mean


func signal_bools():
	if spinning_clockwise:
		spin_clockwise.emit()
		spinner_value += 1
		apply_rotation(1)
		
	elif spinning_anticlockwise:
		spin_counterclockwise.emit()
		spinner_value -= 1
		apply_rotation(-1)


func reset_bools():
	spinning_clockwise = false
	spinning_anticlockwise = false


func apply_rotation(direction:int) -> void:
	if !rotating_object:
		return
		
	if !overrotate and ( spinner_value == spinner_goal_value or spinner_value == spinner_min_value):
		return
	
	rotating_object.rotate_object_local(spinning_axis,rotation_speed * direction)
	
	if rise_when_rotate:
		rotating_object.position.y += rise_when_rotate * direction * -1
		if rotating_object.position.y < 0: # Avoid object sinking below zero.
			rotating_object.position.y = 0
