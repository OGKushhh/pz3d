## Hearing detection system that transitions to an investigation state once a certain threshold is tripped.
## This system does not start combat, it just influences npc pathing to make it easier to find the player.
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_HearingSystem.svg")
@tool
extends Node3D
class_name HearingDetection

@export_group("Nodepaths")
## Reference to the collision shape that defines the hearing radius
@export var collision_shape: CollisionShape3D
## Reference to the parented NPC, easier visually than using get_parent()
@export var npc: CogitoNPC
## Texture for visually representing where the current attention target is, this will be a speaker since its hearing
@export var attention_target_sprite_texture: Texture2D
@export var show_attention_target: bool = true

## Size of the hearing sphere in metres.
@export var hearing_radius: float = 10:
	set(new_radius):
		hearing_radius = new_radius
		_update_debug_state()
## For debugging. Will show the hearing radius of the NPC as a transparent sphere-mesh.
@export var show_hearing_radius: bool = false:
	set(new_value):
		show_hearing_radius = new_value
		_update_debug_state()
		
## Since footsteps will always propagate a sound, 
## this will make the NPC ignore any sounds that they hear under a certain magnitude (radius)
@export var ignore_sounds_under_x_magnitude: float = 3
## When a player makes noise while being detected this will reduce time to full detection
@export var movement_affects_sight_detection: bool = false

@export_group("Suspicion Build-Up")
## Visual indicator for showing an NPCs noise suspicion buildup
@export var noise_suspicion_indicator: DetectionIndicator
## How much noise can be generated before the NPC starts investigating
@export var suspicion_threshold_before_investigating: float = 10
## How long should noise not be detected before the suspicion starts decaying
@export var delay_before_suspicion_decays: float = 3
@export var suspicion_decay_rate: float = 0.5
## Curve for converting generated noise to suspicion buildup, default is linear
@export var noise_suspicion_curve: Curve = _linear_curve()

## Current noise suspicion of the player. Maxes out at the threshold 
var current_suspicion: float = 0
## Delay timer for controlling when the suspicion should start decaying
var decay_timer: Timer
var is_decaying: bool = false

## A default linear curve used for the noise_suspicion_curve. Not recommended to be called externally,
## instead use the Inspector to modify the existing default curve.
func _linear_curve() -> Curve:
	var curve = Curve.new()
	curve.max_domain = 10
	curve.min_domain = 0
	curve.max_value = 10
	curve.min_value = 0
	curve.add_point(Vector2(0,0),0,1,0,Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(10,10),1,0,1,Curve.TANGENT_LINEAR)
	return curve
	
## Just updates the state in editor, its a bit buggy though
func _update_debug_state() -> void:
	# Clear any existing debug meshes
	for mesh in find_children("","MeshInstance3D",false):
		mesh.free()
	if show_hearing_radius:
		generate_debug_mesh()
	if collision_shape:
		collision_shape.shape.radius = hearing_radius

func _ready() -> void:
	decay_timer = Timer.new()
	decay_timer.wait_time = delay_before_suspicion_decays
	decay_timer.timeout.connect(func(): is_decaying = true)
	decay_timer.one_shot = true
	add_child(decay_timer)

func generate_debug_mesh():
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "HearingRadiusMesh"
	var sphere = SphereMesh.new()
	sphere.radius = hearing_radius
	sphere.height = hearing_radius*2
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0,0,1,0.1)
	sphere.material = material
	mesh_instance.mesh = sphere
	add_child(mesh_instance)
	if Engine.is_editor_hint():
		mesh_instance.owner = get_tree().edited_scene_root

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if noise_suspicion_indicator and current_suspicion > 0:
		noise_suspicion_indicator.update(current_suspicion, suspicion_threshold_before_investigating)
	
	if decay_timer.is_stopped() and not is_decaying:
		decay_timer.start()
	elif is_decaying and current_suspicion > 0:
		current_suspicion -= delta
	if current_suspicion <= 0 and npc.current_behaviour == CogitoNPC.BehaviourState.Investigating:
		npc.try_end_investigation()

func _on_hearing_radius_area_entered(area: Area3D) -> void:
	if area is not ObjectNoise:
		return
	var noise: ObjectNoise = area as ObjectNoise
	# First off if the noise is an impact like a thrown object, transition to Alerted
	if noise.noise_type == ObjectNoise.NoiseType.Impact:
		generate_attention_target(noise.global_position)
		npc.state_chart.send_event("alerted")
	# Otherwise if its a footstep, build up suspicion or ignore if its not loud enough
	elif noise.magnitude > ignore_sounds_under_x_magnitude and current_suspicion < suspicion_threshold_before_investigating + 0.5:
		decay_timer.stop()
		current_suspicion += noise_suspicion_curve.sample(noise.magnitude)
	if current_suspicion > suspicion_threshold_before_investigating:
		generate_attention_target(noise.global_position)
		npc.state_chart.send_event("investigate")


func reset():
	current_suspicion = 0
	noise_suspicion_indicator.update(current_suspicion, suspicion_threshold_before_investigating)


func generate_attention_target(position: Vector3):
	var attention_point = CogitoPoint.new(attention_target_sprite_texture, show_attention_target)
	get_tree().current_scene.add_child(attention_point)
	attention_point.global_position = position
	npc.attention_target = attention_point
