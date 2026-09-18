extends CharacterBody3D
class_name CogitoNPC

## Emitted when received damage. Used with the HitboxComponent
signal damage_received(damage_value:float)
signal object_exits_tree()

#region Cogito Interaction variables needed
@export var cogito_name : String = self.name
## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String

enum PromptPositionMode{
	ORIGIN, ## at the objects origin point. Recommended for smaller objects.
	MARKER, ## at the position of an assigned Marker3D node. Will throw an error if no marker is assigned. Recommended for big objects/doors.
	AABB_CENTER, ## at the center of the calculated AABoundingBox. Works well but has a slight performance impact. 
}
## This sets where interaction prompt gets displayed on the object.
@export var prompt_pos_mode : PromptPositionMode = PromptPositionMode.ORIGIN
@export var prompt_marker : Marker3D

@export var head: Node3D
var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var properties : int
#endregion

@export var patrol_path : CogitoPatrolPath

## Should be a class that supports uid
var attention_target : Node3D
var last_reachable_path: Vector3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_group("Movement")
var move_speed : float = 2
@export var walk_speed : float = 2
@export var sprint_speed : float = 4
@export var acceleration : float = 10.0
@export var rotation_speed : float = 0.2

var knockback_force: Vector3 = Vector3.ZERO
var knockback_timer: float = 0.0
@export var knockback_duration: float = 0.5
@export var knockback_strength: float = 10.0

var last_direction

@export_group("NPC Behaviour")
@export_enum("Friendly", "Neutral", "Hostile") var response_to_player: String = "Neutral"
@export var change_material_on_response: bool = false
@export var materials: Dictionary[String, StandardMaterial3D]
@export var sight_detection: SightDetection
@export var hearing_detection: HearingDetection
@export var behaviour_compound_state: CompoundState
@export var weapon: NpcWieldable

@export_group("Head LookAt")
@export var head_turner: LookAtModifier3D


#FootstepPlayer variables
@export_group ("Footstep Player")
##Determines if Footsteps are enabled for NPC
@export var footsteps_enabled: bool = true
##Sets Walk volume in dB
@export var walk_volume_db: float = -12
##Sets Walk volume in dB
@export var sprint_volume_db: float = -4
##Determines the footstep occurence frequency for Walking
@export var WIGGLE_ON_WALKING_SPEED: float = 12.0
##Determines the footstep occurence frequency for Sprinting
@export var WIGGLE_ON_SPRINTING_SPEED: float = 16.0

var can_play_footstep: bool = true
var wiggle_vector : Vector2 = Vector2.ZERO
var wiggle_index : float = 0.0

@onready var footstep_player = $FootstepPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var velocity_debug_shape: MeshInstance3D = $VelocityDebugShape
@onready var hand_slot: Node3D = %HandSlot

# NPC State related vars
@onready var state_chart: StateChart = $StateChart
var serialized_state : SerializedStateChart
var patrol_path_nodepath : NodePath
var attention_target_uid: int

var health: CogitoHealthAttribute


enum BehaviourState {
	## Null state for state processor defaults or if you want a processor to handle multiple states
	None,
	## NPC is Idle, just chilling
	Idle,
	## NPC is moving along a patrol path
	Patrolling,
	## NPC is suspicious of a potential target either by sight or sound
	Investigating,
	## NPC is checking out a disturbance, either loud noise or being hit by something
	Alerted,
	## NPC is chasing after the player
	Chasing,
	## NPC has caught up to the player and is attacking them
	Attacking,
	## NPC has lost the player in a chase, and is now searching for them
	Searching
}
var previous_behaviour: BehaviourState
var current_behaviour: BehaviourState


func in_state(states: Array) -> bool:
	return states.any(func(state): return current_behaviour == state)


## Gets the active state processor. Requires the state processor to be childed to the Atomic State.
func get_active_state() -> StateProcessor:
	var active_state = behaviour_compound_state._active_state
	if active_state:
		var processor = active_state.find_children("", "StateProcessor", false)
		if len(processor) > 0:
			return processor.front()
	return null


func try_end_investigation():
	if hearing_detection.current_suspicion <= 0 and sight_detection.current_suspicion <= 0:
		state_chart.send_event("patrol")


func _ready():
	self.add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()
	find_cogito_properties()
	connect_weapon_to_hand()
	find_health_attribute()


func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


func find_health_attribute():
	health = find_children("","CogitoHealthAttribute", true).front()


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]


func connect_weapon_to_hand():
	# Look for a cogito wieldable childed to the NPC, then automatically connect it to the hand attachment if applicable
	if weapon:
		weapon.reparent(hand_slot, false)
		weapon.npc_wielding = true


func change_player_response(response: String):
	response_to_player = response
	if change_material_on_response:
		var mannequin: MeshInstance3D = %Mannequin
		mannequin.mesh.surface_set_material(0, materials[response])


func is_dead():
	if health:
		return health.value_current <= 0


func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_force
		knockback_force = lerp(knockback_force, Vector3.ZERO, delta * 5)
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if footsteps_enabled:
		npc_footsteps(delta)
	
	#move_and_slide()


func move_npc_to_next_position(_delta: float) -> void:
	var current_location = global_transform.origin
	var next_position = nav_agent.get_next_path_position()
	
	if nav_agent.is_target_reachable():
		last_reachable_path = next_position
		
	var new_velocity = (next_position - current_location).normalized() * move_speed 
	# Add the gravity.
	if not is_on_floor():
		new_velocity += get_gravity() * _delta

	var direction = global_position.direction_to(next_position)
	var face_direction := Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z)

	if direction:
		face_direction(face_direction)
		velocity.x = velocity.move_toward(new_velocity, .25).x
		velocity.z = velocity.move_toward(new_velocity, .25).z
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	move_and_slide()


func face_direction(face_direction: Vector3) -> void:
	var face_at_target = global_position.direction_to(face_direction)
	var face_at_target_xz := Vector3(face_at_target.x, 0, face_at_target.z)
	if face_at_target_xz != Vector3.ZERO:
		var target_basis = Basis.looking_at(face_at_target_xz, Vector3.UP, false)
		basis = basis.slerp(target_basis, rotation_speed)


# NPC Footstep system, adapted from players
func npc_footsteps(delta):
	# Sprinting Case, so using defined number from Chase speed.
	# rounded velocity.length used due to tiny speed fluctuations
	
	if round(velocity.length()) >= sprint_speed:
		wiggle_vector.y = sin(wiggle_index)
		wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
		
		if can_play_footstep and wiggle_vector.y > 0.9:
			footstep_player.volume_db = sprint_volume_db
			footstep_player._play_interaction("footstep", 1)
			can_play_footstep = false
		
		if !can_play_footstep and wiggle_vector.y < 0.9:
			can_play_footstep = true
	
	# Walking Case, so only checks if the NPC has any speed before playing sound
	elif velocity.length() >= 0.2:
		wiggle_vector.y = sin(wiggle_index)
		wiggle_index += WIGGLE_ON_WALKING_SPEED * delta
		
		if can_play_footstep and wiggle_vector.y > 0.9:
			footstep_player.volume_db = walk_volume_db
			footstep_player._play_interaction("footstep", 1)
			can_play_footstep = false
		
		if !can_play_footstep and wiggle_vector.y < 0.9:
			can_play_footstep = true


func apply_knockback(direction: Vector3):
	knockback_force = direction.normalized() * knockback_strength
	knockback_timer = knockback_duration


# Method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	find_cogito_properties()
	load_nodepaths()
	load_state_chart()
	load_attention_target()

	
# Function to handle persistence and saving
func save():
	if patrol_path:
		patrol_path_nodepath = patrol_path.get_path()
	if attention_target:
		attention_target_uid = attention_target.uid
	
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		"patrol_path_nodepath" : patrol_path_nodepath,
		"serialized_state" : StateChartSerializer.serialize(state_chart),
		"attention_target_uid": attention_target_uid,
		"response_to_player": response_to_player
	}
	return node_data


func load_nodepaths():
	if patrol_path_nodepath:
		CogitoGlobals.debug_log(true,"CogitoNPC","Loading patrol path: " + str(patrol_path_nodepath))
		patrol_path = get_node(patrol_path_nodepath)


func load_state_chart():
	var errors = StateChartSerializer.deserialize(serialized_state, state_chart)
	CogitoGlobals.debug_log(true, "CogitoNPC", "Deserialising state chart, errors: %s" % errors)


func load_attention_target():
	if attention_target_uid:
		# Do a fast check for uid matching player before scanning the tree
		var player = CogitoSceneManager._current_player_node
		if attention_target_uid == player.uid:
			attention_target = player
		else:
			attention_target = CogitoSceneManager.find_object_from_uid(attention_target_uid)


func _on_hitbox_component_got_hit(object) -> void:
	if object is CogitoProjectile:
		sight_detection.generate_attention_target(object.throw_point)
	elif object is CogitoWieldable:
		sight_detection.generate_attention_target(object.global_position)
	elif object is CogitoObject:
		look_at(object.throw_point)
		attention_target = object
	state_chart.send_event("alerted")
	animation_tree.set("parameters/Transition/transition_request","hit")
