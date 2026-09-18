@tool
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends Node3D
class_name CogitoObject

signal damage_received(damage_value:float)
signal object_exits_tree()

signal entered_to_fluid(Vector3)
signal exited_to_fluid(Vector3)

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


@export_group("Object Size and Shape")
## Set a custom shape used for calculating object size when dropping.
@export var custom_aabb : AABB = AABB():
	set(new_aabb):
		custom_aabb = new_aabb
		if show_aabb_debug_shape:
			CogitoGlobals.draw_box_aabb(get_aabb(), Color.AQUA)

## Shows the objects AABB debug shape in Editor.
@export var show_aabb_debug_shape : bool = false:
	set(new_show_debug_shape):
		show_aabb_debug_shape = new_show_debug_shape
		if Engine.is_editor_hint() and show_aabb_debug_shape:
			CogitoGlobals.draw_box_aabb(get_aabb(), Color.AQUA)
		else:
			CogitoGlobals.clear_debug_shape()

@export_group("Fluid Floating Parameters")
@export var fluid_influence_enabled := true
@export var use_collision_shapes := true
@export var fluid_damp := 4.0
@onready var fluid_interactor := FluidInteractor3D.new()

@export_group("Environment Interactions")
@export_flags_3d_physics var noise_collision_layer = 512
## This determines the sound this object makes when scaled with velocity
@export var noise_magnitude_when_impacting: float = 0.0
## How much damage does this object do when it collides with other objects while airborne? Ignored if the object is projectile
@export var damage_dealt_when_airborne: float = 0.0
## When true, the faster the object, the more damage it deals and vice versa
@export var damage_scales_with_velocity: bool = true
## When true, the heavier the object, the more damage it deals and vice versa
@export var damage_scales_with_mass: bool = true
## How fast must the object be moving to inflict damage? Protects the player from being damaged while pushing objects
@export var minimum_velocity_to_inflict_damage: float = 2
## When true, the object also takes damage when colliding with other objects 
@export var self_damage_when_airborne: bool = true
## Show the noise created as a debug mesh
@export var show_noise_as_debug_mesh: bool = true
## This is the location that the object was thrown from. If an NPC is hit by the object then they will navigate to this point.
var throw_point: Vector3
var was_thrown: bool = false
var physics_frame_velocity_scalar: float = 0.0

var rigid_body : RigidBody3D

var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var properties : int
var spawned_loot_item: bool = false


func _ready():
	self.add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()
	find_cogito_properties()

	if not fluid_influence_enabled:
		return
	
	## Autodetect if this object has a rigidbody
	rigid_body = find_rigid_body()
	if not rigid_body:
		return
	
	if use_collision_shapes:
		for owner_id in rigid_body.get_shape_owners():
			var collision = rigid_body.shape_owner_get_owner(owner_id)
			if collision is CollisionShape3D:
				fluid_interactor.add_collision_shape(collision)


func get_aabb() -> AABB:
	if custom_aabb:
		return custom_aabb
	
	var aabb: AABB = AABB()
	var is_first: bool = true
	
	for child in find_children("*", "MeshInstance3D", true, false):
		if not child.visible:
			continue
	
		var child_aabb: AABB = child.get_aabb()
	
		var transform = child.transform
	
		var current = child.get_parent()
		while current != self:
			transform = current.transform * transform
			current = current.get_parent()
	
		child_aabb = transform * child_aabb
	
		if is_first:
			aabb = child_aabb
			is_first = false
		else:
			aabb = aabb.merge(child_aabb)
	
	return aabb


# Future method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	find_cogito_properties()
	
	if spawned_loot_item:
		add_to_group("spawned_loot_items")
		
	pass


func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]


# Function to handle persistence and saving
func save():
	if self.is_in_group("spawned_loot_items"):
		spawned_loot_item = true
		
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		#"slot_data" : slot_data,
		#"item_charge" : slot_data.inventory_item.charge_current,
		"interaction_nodes" : interaction_nodes,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		"spawned_loot_item" : spawned_loot_item,
	}

	# If the node is a RigidBody3D, then save the physics properties of it
	var rigid_body = find_rigid_body()
	if rigid_body:
		node_data["linear_velocity_x"] = rigid_body.linear_velocity.x
		node_data["linear_velocity_y"] = rigid_body.linear_velocity.y
		node_data["linear_velocity_z"] = rigid_body.linear_velocity.z
		node_data["angular_velocity_x"] = rigid_body.angular_velocity.x
		node_data["angular_velocity_y"] = rigid_body.angular_velocity.y
		node_data["angular_velocity_z"] = rigid_body.angular_velocity.z
	return node_data


func pass_inventory_data(data: InventorySlotPD):
	for child in get_children():
		if child is PickupComponent:
			var item = child as PickupComponent
			item.slot_data = data
			item.slot_data.quantity = 1


func find_rigid_body() -> RigidBody3D:
	var current = self
	while current:
		if current is RigidBody3D:
			return current as RigidBody3D
		current = current.get_parent()
	return null


func calculate_damage() -> float:
	var base_damage = damage_dealt_when_airborne
	if damage_scales_with_velocity:
		base_damage *= rigid_body.linear_velocity.length()
	if damage_scales_with_mass:
		base_damage *= rigid_body.mass
	return base_damage


func _physics_process(delta: float) -> void:
	if rigid_body:
		physics_frame_velocity_scalar = rigid_body.linear_velocity.length()
	
	if fluid_influence_enabled and rigid_body:
		fluid_interactor.process(rigid_body.global_transform, rigid_body.mass, rigid_body.gravity_scale)
		
		for floater in fluid_interactor.get_floaters():
			if floater.is_just_entered_to_fluid():
				entered_to_fluid.emit(floater.position)
			if floater.is_just_exited_from_fluid():
				exited_to_fluid.emit(floater.position)

		if not fluid_interactor.float_force.is_zero_approx():
			# Bouyancy
			rigid_body.apply_force(fluid_interactor.float_force * delta, fluid_interactor.float_position)
			# Damping
			rigid_body.linear_damp = fluid_damp
			rigid_body.angular_damp = fluid_damp
		else:
			rigid_body.linear_damp = 0.0
			rigid_body.angular_damp = 0.0


func fluid_area_enter(area: FluidArea3D) -> void:
	fluid_interactor.fluid_area_enter(area)


func fluid_area_exit(area: FluidArea3D) -> void:
	fluid_interactor.fluid_area_exit(area)


func _on_body_entered(body: Node) -> void:
	# Generate noise if the object is thrown
	if was_thrown and rigid_body and noise_magnitude_when_impacting > 0:
		was_thrown = false
		var noise = ObjectNoise.new(show_noise_as_debug_mesh)
		noise.set_parameters(ObjectNoise.NoiseType.Impact, noise_magnitude_when_impacting * physics_frame_velocity_scalar, 0.5, noise_collision_layer)
		get_tree().current_scene.add_child(noise)
		noise.global_position = global_position

	if body.has_method("save") and cogito_properties:
		cogito_properties.start_reaction_threshold_timer(body)
	
	if body.has_signal("damage_received") and rigid_body:
		if physics_frame_velocity_scalar >= minimum_velocity_to_inflict_damage:
			var damage_to_deal = calculate_damage()
			body.damage_received.emit(damage_dealt_when_airborne, self);
	
	# Make the object take damage if its moving fast enough and self damage is enabled
	if self_damage_when_airborne and physics_frame_velocity_scalar >= minimum_velocity_to_inflict_damage:
		self.damage_received.emit(calculate_damage(), self)



func _on_body_exited(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.check_for_reaction_timer_interrupt(body)


func _exit_tree() -> void:
	object_exits_tree.emit()
