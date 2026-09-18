## Sight detection system that transitions to an investigation state once a certain threshold is tripped,
## then combat state once the second threshold is tripped.
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_SightSystem.svg")
@tool
extends Node3D
class_name SightDetection

## References to the Area3D detection area
@export var detection_area: Area3D
## Reference to the cone collider itself
@export var cone_collider: CollisionShape3D
## Reference to the parented NPC, easier visually than using get_parent()
@export var npc: CogitoNPC
## Texture for visually representing where the current attention target is, this will be an eye since its sight
@export var attention_target_sprite_texture: Texture2D
## Shows relevant info about the current sight indicator state
@export var show_debug_info: bool = false

@export_group("Suspicion Build-Up")
## Visual indicator for showing an NPCs sight suspicion buildup
@export var sight_suspicion_indicator: DetectionIndicator
## The threshold point at which an NPC starts investigating. Suspicion buildup becomes a lot faster in this state.
@export var investigation_threshold: float = 3
## The threshold point at which the NPC enters a combat state
@export var aggro_threshold: float = 5
## Determines the multiplier for suspicion buildup when an object is the maximum distance
@export var max_distance_multiplier: float = 0.1
## How quickly suspicion grows while not in an investigation state
@export var buildup_to_investigation_rate: float = 1.0
## How quickly suspicion grows while not in an investigation state
@export var buildup_to_aggro_rate: float = 3.0
## How quickly suspicion decays over time
@export var suspicion_decay_rate: float = 0.3
## How long (in seconds) without being detected before the suspicion starts decaying
@export var delay_before_suspicion_decays: float = 2
## Curve for converting visibility to a multiplier, default is linear 1 -> 0.01
@export var visibility_modifier_curve: Curve = _linear_curve()
## The minimum value required by the player visibility attribute to make the player detectable.
## If the player does not use a visibility attribute, this value is ignored.
@export_range(0, 100) var minimum_visibility: int = 30

## The square sight range radius vector in metres per axis. Players in this collider will be detectable if they can be hit by the detection raycast.
@export var sight_range_cone: Vector3 = Vector3(10, 10, 15)
## Shows the raycast if the player is seen by the sight detection system
@export var show_detection_line: bool = false
var debug_line = preload("res://addons/cogito/Scripts/debug_line.gd").new()

## Current suspicion of the player
var current_suspicion: float = 0
## Delay timer for controlling when the suspicion should start decaying
var decay_timer: Timer
## State check for whether or not to decay the suspicion
var is_decaying: bool = false
## Store a reference to the player so it can be assigned a target
var ref_to_player: CogitoPlayer
## Reference to last raycasted target
var last_raycasted_target: Node3D
## Reference to the last collision point that saw the player
var player_sight_collision_point: Vector3 = Vector3.ZERO

## All nodes present inside the NPC sight cone. Objects in this array will be attacked by raycasts
var nodes_inside_cone: Array = []

var behaviour = CogitoNPC.BehaviourState

## A default linear curve used for the visiblity modifier. Not recommended to be called externally,
## instead use the Inspector to modify the existing default curve.
static func _linear_curve() -> Curve:
	var curve = Curve.new()
	curve.max_domain = 100
	curve.min_domain = 0
	curve.max_value = 1
	curve.min_value = 0
	curve.add_point(Vector2(0,0),0,1,0,Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(100,1),1,0,1,Curve.TANGENT_LINEAR)
	return curve

func _ready() -> void:
	if show_detection_line:
		add_child(debug_line)
	connect_detection_signals()
	#generate_sight_range_collider()
	create_decay_timer()


func create_decay_timer():
	decay_timer = Timer.new()
	decay_timer.wait_time = delay_before_suspicion_decays
	decay_timer.timeout.connect(func(): is_decaying = true)
	decay_timer.one_shot = true
	add_child(decay_timer)


## Generates a square cone based on the Sight Range Cone vector formed of a 5 point triangular shape along the axes
func generate_sight_range_collider():
	var sight_cone = ConvexPolygonShape3D.new()
	sight_cone.points.append(Vector3(0,0,0)) # Start point
	sight_cone.points.append(Vector3(-sight_range_cone.x,sight_range_cone.y, sight_range_cone.z)) # Top Left
	sight_cone.points.append(Vector3(sight_range_cone.x,sight_range_cone.y, sight_range_cone.z)) # Top Right
	sight_cone.points.append(Vector3(sight_range_cone.x,-sight_range_cone.y, sight_range_cone.z)) # Bottom Right
	sight_cone.points.append(Vector3(-sight_range_cone.x,-sight_range_cone.y, sight_range_cone.z)) # Bottom Left
	cone_collider.shape = sight_cone

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Disable processing if the npc is currently in combat
	if npc.in_state([behaviour.Chasing, behaviour.Attacking]):
		return
	
	update_suspicion_indicator()
	
	for	node in nodes_inside_cone:
		if node is CogitoPlayer and npc.response_to_player != "Hostile":
			continue
		if fire_raycast_at(node):
			decay_timer.stop()
			is_decaying = false
			# Get the initial buildup amount based on current npc state
			var initial_amount = (buildup_to_investigation_rate if npc.in_state([behaviour.Patrolling, behaviour.Idle]) else buildup_to_aggro_rate)
			# Get the final amount by factoring distance to the target as well as visibility * deltatime
			var amount = initial_amount * get_distance_modifier_to(node) * get_visibility_modifier(node) * delta
			current_suspicion = clamp(current_suspicion + amount, 0, aggro_threshold + 0.5)
	
	decay_suspicion(delta)
	
	state_trigger_checks()


func check_if_player_in_los() -> bool:
	for	node in nodes_inside_cone:
		if node is CogitoPlayer:
			return fire_raycast_at(node)
	return false


## Handles decaying of suspicion over time with delta-time
func decay_suspicion(delta):
	# Suspicion decay logic
	if decay_timer.is_stopped() and not is_decaying:
		decay_timer.start()
	elif is_decaying and current_suspicion > 0:
		current_suspicion -= (suspicion_decay_rate * delta)
	if current_suspicion <= 0 and npc.in_state([behaviour.Investigating]):
		npc.try_end_investigation()


## Updates the suspicion indicator if configured to this detection system
func update_suspicion_indicator():
	if sight_suspicion_indicator and current_suspicion > 0:
		if current_suspicion < investigation_threshold:
			sight_suspicion_indicator.is_investigating = false
			sight_suspicion_indicator.update(current_suspicion, investigation_threshold)
		else:
			sight_suspicion_indicator.is_investigating = true
			sight_suspicion_indicator.update(current_suspicion, aggro_threshold)


## Check current suspicion against the thresholds and trigger state changes if they're hit
func state_trigger_checks():
	if current_suspicion >= aggro_threshold and ref_to_player and npc.in_state([behaviour.Investigating]):
		current_suspicion = investigation_threshold
		npc.attention_target = ref_to_player
		npc.state_chart.send_event("chase")
	elif current_suspicion >= investigation_threshold and ref_to_player and npc.in_state([behaviour.Idle, behaviour.Patrolling, behaviour.Alerted]):
		generate_attention_target(ref_to_player.global_position)
		npc.state_chart.send_event("investigate")


func get_distance_modifier_to(node: Node3D) -> float:
	var cone_magnitude = sight_range_cone.length_squared()
	var distance_to = npc.global_position.distance_squared_to(node.global_position)
	return lerp(1.0, max_distance_multiplier, distance_to/cone_magnitude)


func get_visibility_modifier(node: Node3D) -> float:
	if node is not CogitoPlayer:
		return 1.0
	elif node.visibility_attribute:
		return visibility_modifier_curve.sample(node.visibility_attribute.value_current)
	return 1.0


## Fires a raycast at the object in the list of targets currently within the detection cone.
## Returns true if the raycast hits, extra logic checks that the player is visible
func fire_raycast_at(node: Node3D) -> bool:
	# Get the space state of the world, construct a ray to fire from the npc to the spotted target
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(npc.head.global_position, node.head.global_position if node is CogitoPlayer else node.global_position)
	query.exclude = [self, detection_area.get_rid()]
	var result = space_state.intersect_ray(query)
	# If the raycast hits a player, check that they are visible via attribute
	last_raycasted_target = result["collider"] if result else null
	if not last_raycasted_target:
		player_sight_collision_point = Vector3.ZERO
		return false
	if last_raycasted_target is not CogitoPlayer:
		var object: CogitoObject = last_raycasted_target as CogitoObject
		if object:
			for interaction_component: InteractionComponent in object.interaction_nodes:
				if interaction_component is CogitoCarryableComponent and interaction_component.is_being_carried and interaction_component.carrier is CogitoPlayer:
					var player: CogitoPlayer = interaction_component.carrier as CogitoPlayer
					return _fire_raycast_at_player_result(player.global_position, player)
		player_sight_collision_point = Vector3.ZERO
		return false
	else:
		var player: CogitoPlayer = last_raycasted_target as CogitoPlayer
		return _fire_raycast_at_player_result(result["position"], player)
	
	return false


func _fire_raycast_at_player_result(position: Vector3, player: CogitoPlayer) -> bool:
	player_sight_collision_point = position
	if show_detection_line:
		debug_line.draw_3d_line(npc.head.global_position, player.global_position, Color(1,0,0), 0.1)
	ref_to_player = player
	if ref_to_player.visibility_attribute:
		return ref_to_player.visibility_attribute.value_current >= minimum_visibility
	else:
		return true


func reset():
	current_suspicion = 0
	sight_suspicion_indicator.visible = false


func connect_detection_signals():
	if not detection_area.body_entered.is_connected(on_body_entered):
		detection_area.body_entered.connect(on_body_entered)
	if not detection_area.body_exited.is_connected(on_body_exited):
		detection_area.body_exited.connect(on_body_exited)


func on_body_entered(body: Node3D):
	if body is CogitoPlayer:
		nodes_inside_cone.append(body)


func on_body_exited(body: Node3D):
	if body in nodes_inside_cone:
		nodes_inside_cone.erase(body)


func generate_attention_target(position: Vector3):
	var attention_point = CogitoPoint.new(attention_target_sprite_texture, show_debug_info)
	get_tree().current_scene.add_child(attention_point)
	attention_point.global_position = position
	npc.attention_target = attention_point
