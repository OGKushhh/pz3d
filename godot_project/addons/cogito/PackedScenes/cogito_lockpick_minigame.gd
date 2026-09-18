class_name CogitoLockpickGame extends Node3D

signal unlocked # a signal emmited when the lock has been unlocked
signal cancelled # Emitted when the player cancels out by pressing 'menu'
signal lockpick_broke # Emitted when a lockpick breaks.

## NOTE: Use this variable to scale difficulity, the closer the number to 0 the harder the lockpicking is
@export var default_sweet_spot_range: float = 10.0
## Difficulty modifier


@export var max_range: float = 10.0 # the range in which the sweet spot can go from
@export var lockpick_move_sensitivity: float = 0.003 # The sensitivity in which the lockpick moves

@export var lockpick_pivot: Node3D
@export var keyhole_pivot: Node3D

@export var lockpick_health_max : float = 5
@export_range(1,10,0.5,"Default = 2.0") var lockpick_damage_per_second_min = 2.0
@export_range(1,10,0.5,"Default = 8.0") var lockpick_damage_per_second_max = 8.0

@export_subgroup("Attribute Skill Settings")
@export var attribute_influences_difficulty : bool = true
@export var attribute_influences_lockpick_health : bool = true

@export_subgroup("Animations")
@export var start_animation : String = "start"
@export var grab_new_lockpick_animation : String = "grab_new_lockpick"
@export var jiggle_animation : String = "jiggle_lock"
@export var lockpick_break_animation : String = "lockpick_breaks"
@export var unlock_animation : String = "unlocking"

@export_subgroup("Audio")
@export var unlock_sound : AudioStream
@export var jiggle_sound : AudioStream
@export var lockpick_break_sound : AudioStream

var lockpick_health : float:
	set(value):
		lockpick_health = maxf(value,0)

# Some state bools
var is_unlocked: bool = false
var is_turning_keyhole: bool = false
var is_changing_lockpicks : bool = false
var is_jiggling: bool = false

var sweet_spot_range : float
var lockpick_spot: float = 0.0 # the lockpick postion tanges from MIN_RANGE to max_range
var keyhole_rotation_speed: float = 4.0 # the speed in which the keyhole rotates when pressing right
var sweet_spot: float = 0.0  # The distance to the sweet spot.

var lockpick_attribute : CogitoAttribute

# Variables for gamepad input
var joystick_v_event
var joystick_h_event

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const MIN_RANGE: float = 0.0 # i'm not sure why would you change this
const LOCKPICK_SUCCESS_ZONE : float = -90.0 
var unlock_difficulty_modifier: float = 0 # Used if attribute influences difficulty. This gets added to the lockpick success zone, making the lock unlock on a smaller angle and thus easier to pick.


func _ready() -> void:
	InputRouter.push(on_input)
	lockpick_spot = max_range / 2 	# make the lockpick at the center
	lockpick_health = lockpick_health_max
	sweet_spot_range = default_sweet_spot_range
	
	animation_player.play(start_animation)
	await animation_player.animation_finished
	
	place_sweetspot(max_range)

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# if the keyhole isn't turning and we haven't unlocked it yet
		if not is_turning_keyhole and not is_changing_lockpicks and not is_unlocked:
			# rotate the lockpick along the z axis AND making sure it dosen't go beyong -90 and 90 degrees
			lockpick_pivot.rotate_z(-event.relative.x * lockpick_move_sensitivity)
			lockpick_pivot.rotation.z = clamp(lockpick_pivot.rotation.z, deg_to_rad(-90), deg_to_rad(90))
	
	# Controlling lockpick with gamepad right thumbstick
	if event is InputEventJoypadMotion:
		if event.get_axis() == 2:
			joystick_h_event = event
		if event.get_axis() == 3:
			joystick_v_event = event
	
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		cancelled.emit()
		InputRouter.pop()


func _physics_process(delta: float) -> void:
	# we remap the lockpick spot from -90 and 90 to a value that goes from MIN_RANGE to max_range, then we snap it for easier controls
	lockpick_spot = snappedf(remap(rad_to_deg(lockpick_pivot.rotation.z), -90, 90, MIN_RANGE, max_range), 0.1)
	
	if not is_unlocked:
		_handle_keyhole(delta)


# generating a random number via godot's RandomNumberGenerator class, call this function when you want to reinitialise the sweet spot
func place_sweetspot(sweetspot_range: float) -> void:
	var rand_range: RandomNumberGenerator = RandomNumberGenerator.new()
	# snapping the value so the lock for better solvability
	sweet_spot = snappedf(rand_range.randf_range(MIN_RANGE, max_range), 0.1)


func _handle_keyhole(delta: float) -> void:
	if is_jiggling or is_changing_lockpicks:
		return
		
	if joystick_h_event and not is_turning_keyhole and not is_changing_lockpicks:
		lockpick_pivot.rotate_z(joystick_h_event.axis_value * delta)
		lockpick_pivot.rotation.z = clamp(lockpick_pivot.rotation.z, deg_to_rad(-90), deg_to_rad(90))
	
	# If we're pressing the right input map action, rotate the keyhole
	if Input.is_action_pressed("right"):
		keyhole_pivot.rotate_z(-keyhole_rotation_speed * delta)
		is_turning_keyhole = true
		
	else:
		# otherwise rotate back
		keyhole_pivot.rotation.z = lerp_angle(keyhole_pivot.rotation.z, 0, 4 * delta)
		is_turning_keyhole = false
	
	# gradually block the keyhole rotation depenting on the distance to the sweetspot
	var distance: float = abs(lockpick_spot - sweet_spot) # the distance to the sweet spot acording to the lockpick position
	# we remap that distance to be in the range from 0 to the success degree, we also snap it for convience
	var grad_lock: float = snappedf(remap(distance, sweet_spot_range, 0, 0, LOCKPICK_SUCCESS_ZONE), 0.1)
	# clamping the rotation so we don't go beyond LOCKPICK_SUCCSESS_ZONE
	keyhole_pivot.rotation_degrees.z = clamp(keyhole_pivot.rotation_degrees.z, grad_lock, 0)
	
	# Unlock the lock when the keyhole has turned 90 degrees
	if rad_to_deg(keyhole_pivot.rotation.z) <= LOCKPICK_SUCCESS_ZONE + unlock_difficulty_modifier:
		unlock_lock()
	elif is_turning_keyhole :
		if distance <= 1: # Within range where keyhole turns
			if abs(grad_lock - rad_to_deg(keyhole_pivot.rotation.z) ) <= 1: # is within hitting the grad_lock range:
				jiggle_lock(delta, distance)
		else:
			jiggle_lock(delta, distance)


func jiggle_lock(delta: float, distance_to_unlock: float) -> void:
	if is_changing_lockpicks:
		return
	
	is_jiggling = true
	Audio.play_sound(jiggle_sound)

	var  lockpick_damage_range : float = lockpick_damage_per_second_max - lockpick_damage_per_second_min
	var lockpick_damage : float = remap(distance_to_unlock, 0, 10, lockpick_damage_per_second_min, lockpick_damage_per_second_max)
	
	CogitoGlobals.debug_log(true, "CogitoLockpickGame", "Jiggling the lock. distance_to_unlock=" + str(distance_to_unlock) + ". lockpick_damage_range=" + str(lockpick_damage_range) + ". lockpick_damage=" + str(lockpick_damage) )
	lockpick_health = lockpick_health - ( lockpick_damage * delta )
	
	if lockpick_health == 0:
		on_lockpick_break()
	else:
		animation_player.play(jiggle_animation)
		await animation_player.animation_finished
	
	is_jiggling = false


func pass_player_attribute( passed_lockpick_attribute: CogitoAttribute) -> void:
	lockpick_attribute = passed_lockpick_attribute
	set_attribute_dependencies()

func set_attribute_dependencies() -> void:
	var normalized_lockpick_attribute = lockpick_attribute.value_current/lockpick_attribute.value_max
	
	if attribute_influences_difficulty:
		sweet_spot_range = normalized_lockpick_attribute * default_sweet_spot_range
		unlock_difficulty_modifier = (normalized_lockpick_attribute * 10)
		CogitoGlobals.debug_log(true, "CogitoLockpickGame", "Player attribute " + lockpick_attribute.name + "=" + str(lockpick_attribute.value_current) + ". Setting sweetspot range to " + str(sweet_spot_range) + ". unlock_difficulty_modifier=" + str(unlock_difficulty_modifier) )
	
	if attribute_influences_lockpick_health:
		var adjusted_lockpick_health = lockpick_health_max * normalized_lockpick_attribute
		lockpick_health_max = adjusted_lockpick_health
		lockpick_health = adjusted_lockpick_health
		CogitoGlobals.debug_log(true, "CogitoLockpickGame", "Player attribute " + lockpick_attribute.name + "=" + str(lockpick_attribute.value_current) + ". Setting lockpick max health to " + str(adjusted_lockpick_health) )


func unlock_lock() -> void:
	Audio.play_sound(unlock_sound)
	
	is_unlocked = true
	
	if unlock_animation:
		animation_player.play(unlock_animation)
		await animation_player.animation_finished
		
	unlocked.emit()
	InputRouter.pop()


func on_lockpick_break() -> void:
	is_changing_lockpicks = true
	
	Audio.play_sound(lockpick_break_sound)
	
	if lockpick_break_animation:
		animation_player.play(lockpick_break_animation)
		await animation_player.animation_finished
	
	lockpick_broke.emit()



func grab_new_lockpick() -> void:
	is_changing_lockpicks = true
	
	if grab_new_lockpick_animation:
		animation_player.play(grab_new_lockpick_animation)
		await animation_player.animation_finished

	lockpick_health = lockpick_health_max
	is_changing_lockpicks = false


func exit_game() -> void:
	if start_animation:
		animation_player.play_backwards(start_animation)
		await animation_player.animation_finished
		
	cancelled.emit()
	InputRouter.pop()
