extends InteractionComponent
class_name CogitoCarryableComponent

signal carry_state_changed(is_being_carried : bool)
signal thrown(impulse)

@export_group("Carriable Settings")
@export var audio_stream_player_3d: AudioStreamPlayer3D
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
##Sets whether the object can be carried while wielding a weapon
@export var is_carryable_while_wielding : bool = false
## Use this to adjust the carry position distance from the player. Per default it's the interaction raycast length. Negative values are closer, positive values are further away.
@export var carry_distance_offset : float = 0
## Set if the object should not rotate when being carried. Usually true is preferred.
@export var lock_rotation_when_carried : bool = true
## Sets how fast the carriable is being pulled towards the carrying position. The lower, the "floatier" it will feel.
@export var carrying_velocity_multiplier : float = 10
## Sets how far away the carried object needs to be from the carry_position before it gets dropped.
@export var drop_distance : float = 1.5
## Sets if object can be rotated while being carried
@export var enable_manual_rotating : bool = true
## How fast the object rotates (in degrees per second)
@export var rotation_speed : float = 10
## Extra rotation speed multiplier for gamepad joysticks
@export var gamepad_sensitivity : float = 20

var camera : Camera3D
var parent_object
var is_being_carried : bool
var is_being_rotated : bool = false
var player_interaction_component : PlayerInteractionComponent
var carry_position : Vector3 #Position the carriable "floats towards".
var gamepad_rotation: Vector2
var carrier = null


func _ready():
	if !audio_stream_player_3d:
		var players: Array[Node] = find_children("", "AudioStreamPlayer3D")
		if len(players): audio_stream_player_3d = players[0]
	
	parent_object = get_parent()
	
	if parent_object.has_signal("body_entered"):
		parent_object.body_entered.connect(_on_body_entered) #Connecting to body entered signal
	else:
		CogitoGlobals.debug_log(true,"CarryableComponent.gd", parent_object.name + ": CarriableComponent needs to be child to a RigidBody3D to work.")


func interact(_player_interaction_component:PlayerInteractionComponent):
	if !is_disabled:
		if attribute_check == AttributeCheck.NONE:
			carry(_player_interaction_component)
			was_interacted_with.emit(interaction_text,input_map_action)
		else:
			if check_attribute(_player_interaction_component):
				carry(_player_interaction_component)
				was_interacted_with.emit(interaction_text,input_map_action)


func carry(_player_interaction_component:PlayerInteractionComponent):
	player_interaction_component = _player_interaction_component
	#if player_interaction_component.is_wielding and not is_carryable_while_wielding:
		#player_interaction_component.send_hint(null, tr("HINT_cant_carry") )
		#return
	
	if is_being_carried:
		leave()
	elif player_interaction_component.is_wielding:
		if is_carryable_while_wielding:
			hold()
		elif !player_interaction_component.is_changing_wieldables:
			# Unequip and store the current wieldable when carrying, and automatically reequip it after carrying
			player_interaction_component.setup_wieldable_to_auto_equip()
			hold()
	else:
		hold()


func _physics_process(_delta):
	if is_being_carried:
		#carry_position = player_interaction_component.get_interaction_raycast_tip(carry_distance_offset)
		carry_position = player_interaction_component.get_carryable_destination_point(carry_distance_offset)
		parent_object.set_linear_velocity((carry_position - parent_object.global_position) * carrying_velocity_multiplier)
		
		if Input.is_action_pressed("action_secondary") and enable_manual_rotating:
			player_interaction_component.player.is_mouselook_active = false
			is_being_rotated = true
		
		# Resume player movement when input action is released
		if is_being_rotated:
			if Input.is_action_just_released("action_secondary"):
				player_interaction_component.player.is_mouselook_active = true
				is_being_rotated = false
				
			if gamepad_rotation.length() >= 0.2:
				rotate_object(gamepad_rotation)
		
		if (carry_position-parent_object.global_position).length() >= drop_distance:
			leave()


func _input(event: InputEvent) -> void:
	if !is_being_rotated: return
	
	if event is InputEventMouseMotion:
		rotate_object(event.relative)
		
	if event is InputEventJoypadMotion:
		match event.get_axis():
			2:
				gamepad_rotation.x = event.get_axis_value() * gamepad_sensitivity
			3:
				gamepad_rotation.y = event.get_axis_value() * gamepad_sensitivity


func rotate_object(input_dir: Vector2):	
	if input_dir.length() > 0:
		if not camera:
			camera = get_viewport().get_camera_3d()
		
		var rotation_basis: Basis = camera.global_basis.rotated(camera.global_basis.x, -camera.global_rotation.x)
		var rotation_vector: Vector3 = rotation_basis * Vector3(input_dir.y, input_dir.x, 0).normalized()
		parent_object.global_rotate(rotation_vector, deg_to_rad(rotation_speed * input_dir.length() * get_process_delta_time()) )


func _on_body_entered(body):
	if body.is_in_group("Player") and is_being_carried:
		leave()


func _exit_tree():
	if is_being_carried:
		leave()


func hold():
	if parent_object is RigidBody3D:
		if lock_rotation_when_carried:
			parent_object.set_lock_rotation_enabled(true)
		parent_object.freeze = false
	player_interaction_component.start_carrying(self)
	player_interaction_component.interaction_raycast.add_exception(parent_object)
	
	# Play Pick up sound.
	if audio_stream_player_3d and pick_up_sound != null:
		audio_stream_player_3d.stream = pick_up_sound
		audio_stream_player_3d.play()
	
	is_being_carried = true
	carrier = player_interaction_component.player
	carry_state_changed.emit(is_being_carried)


func leave():
	# Making sure the player movement resumes when object is dropped while being rotated
	if is_being_rotated:
		player_interaction_component.player.is_mouselook_active = true
		
	if parent_object is RigidBody3D and lock_rotation_when_carried:
		parent_object.set_lock_rotation_enabled(false)
	if player_interaction_component and is_instance_valid(player_interaction_component):
		player_interaction_component.stop_carrying()
		player_interaction_component.auto_equip_last_wieldable()
		player_interaction_component.interaction_raycast.remove_exception(parent_object)
	is_being_carried = false
	carrier = null
	carry_state_changed.emit(is_being_carried)


func throw(power):
	leave()
	if audio_stream_player_3d and drop_sound:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()
	var impulse = player_interaction_component.get_look_direction() * power
	if parent_object is CogitoObject:
		parent_object.was_thrown = true
		parent_object.throw_point = parent_object.global_position
	parent_object.apply_central_impulse(impulse)
	thrown.emit(impulse)
