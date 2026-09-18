class_name CogitoPlayerSimpleState
extends CogitoPlayerState


@export var version : int = 1
@export var player_inventory : CogitoInventory

@export var player_quickslots : Array[InventorySlotPD]

@export var saved_wieldable_charges : Array

@export var player_position : Vector3
@export var player_rotation : Vector3
@export var player_try_crouch : bool

#Using Vector2 for saving player attributes. X = current, Y = max.
@export var player_health: Vector2
@export var player_stamina : Vector2
@export var player_sanity : Vector2

#New way of saving player attributes
@export var player_attributes : Dictionary

# Saving currencies
@export var player_currencies : Dictionary

# Saving world dict
@export var world_dictionary : Dictionary

#Saving parameters from the player interaction component
@export var interaction_component_state : Array

#Saving quests:
@export var player_active_quests : Array[CogitoQuest]
@export var player_active_quest_progression : Dictionary
@export var player_completed_quests : Array[CogitoQuest]
@export var player_failed_quests : Array[CogitoQuest]

# Sitting vars
@export var is_sitting: bool = false
@export var sittable_look_marker: Vector3 = Vector3()
@export var sittable_look_angle: float = 0.0
@export var moving_seat: bool = false
@export var displacement_position: Vector3 = Vector3()
@export var original_position: Transform3D = Transform3D()
@export var original_neck_basis: Basis = Basis()
@export var is_ejected: bool = false
@export var currently_tweening: bool = false
@export var current_sittable_path: NodePath

#Collision shapes
@export var standing_collision_shape_enabled : bool = true
@export var crouching_collision_shape_enabled : bool = false

@export var player_transform: Transform3D
@export var body_transform: Transform3D
@export var neck_transform: Transform3D
@export var head_transform: Transform3D
@export var eyes_transform: Transform3D
@export var camera_transform: Transform3D

@export var main_velocity: Vector3
@export var last_velocity: Vector3
@export var direction: Vector3

@export var current_speed: float


func populate_player_data(player):
	player.inventory_data = self.player_inventory # Loading inventory data from saved player state to current player inventory.
	player.inventory_data.assigned_quickslots = self.player_quickslots
	
	# Loading quests from player state with proper initialization:
	CogitoQuestManager.active.clear_group()
	for quest in self.player_active_quests:
		quest.start(true)  # Initialize active quests (mute audio)
		CogitoQuestManager.active.add_quest(quest)
	
	var _temp_active_quest_dir = self.player_active_quest_progression
	for entry in _temp_active_quest_dir:
		for quest in CogitoQuestManager.active.quests:
			if quest.quest_name == entry:
				quest.quest_counter = _temp_active_quest_dir[entry]
				CogitoGlobals.debug_log(true,"CSM", "Loading active quests. Quest " + quest.quest_name + " found. Setting progression to " + str(_temp_active_quest_dir[entry]) )
	
	CogitoQuestManager.completed.clear_group()
	for quest in self.player_completed_quests:
		quest.complete(true)  # Initialize completed quests (mute audio)
		CogitoQuestManager.completed.add_quest(quest)
	
	CogitoQuestManager.failed.clear_group()
	for quest in self.player_failed_quests:
		quest.failed(true)  # Initialize failed quests (mute audio)
		CogitoQuestManager.failed.add_quest(quest)
	
	# Loading saved charges of wieldables
	var array_of_wieldable_charges = self.saved_wieldable_charges
	for data in array_of_wieldable_charges:
		if data == null:
			continue
		else:
			for slot in player.inventory_data.inventory_slots:
				if slot and slot.inventory_item and slot.inventory_item == data["resource"]:
					CogitoGlobals.debug_log(true,"CSM","Match found: " + str(slot.inventory_item))
					slot.inventory_item.charge_current = data["charge_current"]
					
	player.inventory_data.force_inventory_update()
	
	# New way of loading player attributes:
	var loaded_attribute_data = self.player_attributes
	for attribute in loaded_attribute_data:
		var attribute_data: Vector2 = loaded_attribute_data[attribute]
		var cur_value = attribute_data.x
		var max_value = attribute_data.y
		player.player_attributes[attribute].set_attribute(cur_value, max_value)
	
	# Loading player currencies
	var loaded_currency_data = self.player_currencies
	for currency in loaded_currency_data:
		var currency_data: Vector2 = loaded_currency_data[currency]
		var cur_value = currency_data.x
		var max_value = currency_data.y
		player.player_currencies[currency].set_currency(cur_value, max_value)
	
	# Loading world dictionary
	var local_dict_copy : Dictionary = self.world_dictionary.duplicate(true)
	CogitoSceneManager._current_world_dict.clear()
	for entry in local_dict_copy:
		CogitoSceneManager._current_world_dict.get_or_add(entry, local_dict_copy[entry])
	
	player.global_position = self.player_position
	player.body.global_rotation = self.player_rotation
	player.try_crouch = self.player_try_crouch
	# important: ensures the player isn't crouching on game load, regardless
	# of whether the option "Toggle Crouching" is set to OFF or ON
	
	## Loading player sitting state
	self.load_sitting_state(player) 
	self.load_collision_shapes(player)
	self.load_node_transforms(player)
	
	# Loading player interaction component state
	var player_interaction_component_state = self.interaction_component_state
	for state_data in player_interaction_component_state:
		for data in state_data.keys():
			player.player_interaction_component.set(data, state_data[data])
		player.player_interaction_component.set_state.call_deferred() # Calling this deferred as some state calls need to make sure the scene is finished loading.
	
	player.is_dead = false
	
	if CogitoSceneManager.scene_load_mode != CogitoSceneManager.CogitoSceneLoadMode.TEMP:
		player.main_velocity = self.main_velocity
		player.last_velocity = self.last_velocity
		player.direction = self.direction
		
		player.current_speed = self.current_speed
	
	player.is_crouching = player.try_crouch


func populate_save_data(player, slot):
	self.player_inventory = player.inventory_data # Saving player inventory
	self.player_quickslots = player.inventory_data.assigned_quickslots # Saving assigned quickslots
	
	# Saving current quests to player state.
	self.player_active_quests.clear()
	for quest in CogitoQuestManager.active.quests:
		self.player_active_quests.append(quest)
		
	self.player_completed_quests.clear()
	for quest in CogitoQuestManager.completed.quests:
		self.player_completed_quests.append(quest)
		
	self.player_failed_quests.clear()
	for quest in CogitoQuestManager.failed.quests:
		self.player_failed_quests.append(quest)  # FIXED: Save failed quests to correct list
	
	# Saving active quests with progression counter
	self.player_active_quest_progression.clear()
	for quest in CogitoQuestManager.active.quests:
		self.add_to_active_quest_dictionary(quest.quest_name, quest.quest_counter_current)
	
	self.clear_saved_wieldable_charges()
	for item_slot in player.inventory_data.inventory_slots:
		if item_slot and item_slot.inventory_item and item_slot.inventory_item.has_method("update_wieldable_data"): # Checking for wieldables.
			var item_save_data = item_slot.inventory_item.save()
			self.append_saved_wieldable_charges(item_save_data)
			CogitoGlobals.debug_log(true,"CSM","Saved charge for " + str(item_slot.inventory_item) )
	
	self.player_current_scene = CogitoSceneManager._current_scene_name
	CogitoGlobals.debug_log(true,"CSM","Save_player_state(): setting player_current_scene to " + CogitoSceneManager._current_scene_name)
	self.player_current_scene_path = CogitoSceneManager._current_scene_path
	self.player_position = player.global_position
	self.player_rotation = player.body.global_rotation
	self.player_try_crouch = player.try_crouch
	
	## New way of saving attributes:
	self.clear_saved_attribute_data()
	for attribute in player.player_attributes:
		var cur_value
		if !player.player_attributes[attribute].dont_save_current_value:
			cur_value = player.player_attributes[attribute].value_current
		else:
			cur_value = 0
		var max_value = player.player_attributes[attribute].value_max
		var attribute_data := Vector2(cur_value, max_value)
		self.add_player_attribute_to_state_data(attribute, attribute_data)
	
	## Save player sitting state
	self.save_sitting_state(player)
	self.save_collision_shapes(player)
	self.save_node_transforms(player)
	
	self.clear_saved_currency_data()
	for currency in player.player_currencies:
		var cur_value
		if !player.player_currencies[currency].dont_save_current_value:
			cur_value = player.player_currencies[currency].value_current
		else:
			cur_value = 0
		var max_value = player.player_currencies[currency].value_max
		var currency_data := Vector2(cur_value, max_value)
		self.add_player_currency_to_state_data(currency, currency_data)
	
	## Saving world dictionary
	var local_dict_copy : Dictionary = CogitoSceneManager._current_world_dict.duplicate(true)
	self.clear_world_dictionary()
	for entry in local_dict_copy:
		CogitoGlobals.debug_log(true,"CSM", "World Dict: attemtping to save key: " + str(entry) )
		self.add_to_world_dictionary(entry, local_dict_copy[entry])

	## Adding a screenshot
	var screenshot_path : String = str(self.player_state_dir + slot + ".png")
	
	if CogitoSceneManager._screenshot_to_save:
		if slot != "temp":
			CogitoSceneManager._screenshot_to_save.save_png(screenshot_path)
			self.player_state_screenshot_file = screenshot_path
	else:
		CogitoGlobals.debug_log(true,"CSM","No screenshot to save was passed.")
	
	## Getting time of saving
	self.player_state_savetime = int(Time.get_unix_time_from_system())
	self.player_state_slot_name = slot

	# Writing the state from current player interaction component:
	var current_player_interaction_component = player.player_interaction_component
	self.clear_saved_interaction_component_state()
	self.add_interaction_component_state_data_to_array(current_player_interaction_component.save())
	
	self.main_velocity = player.main_velocity
	self.last_velocity = player.last_velocity
	self.direction = player.direction
	
	self.current_speed = player.current_speed


func save_node_transforms(player):
	player_transform = player.transform
	body_transform = player.get_node("Body").transform
	neck_transform = player.get_node("Body/Neck").transform
	head_transform = player.get_node("Body/Neck/Head").transform
	eyes_transform = player.get_node("Body/Neck/Head/Eyes").transform
	camera_transform = player.get_node("Body/Neck/Head/Eyes/Camera").transform


func load_node_transforms(player):
	player.transform = player_transform
	player.get_node("Body").transform = body_transform
	player.get_node("Body/Neck").transform = neck_transform
	player.get_node("Body/Neck/Head").transform = head_transform
	player.get_node("Body/Neck/Head/Eyes").transform = eyes_transform
	player.get_node("Body/Neck/Head/Eyes/Camera").transform = camera_transform


# Save the state of the player's collision shapes
func save_collision_shapes(player):
	standing_collision_shape_enabled = not player.standing_collision_shape.disabled
	crouching_collision_shape_enabled = not player.crouching_collision_shape.disabled


# Load the state of the player's collision shapes
func load_collision_shapes(player):
	player.standing_collision_shape.disabled = not standing_collision_shape_enabled
	player.crouching_collision_shape.disabled = not crouching_collision_shape_enabled


func save_sitting_state(player):
	is_sitting = player.is_sitting
	sittable_look_marker = player.sittable_look_marker if player.is_sitting else Vector3()
	sittable_look_angle = player.sittable_look_angle if player.is_sitting else 0.0
	moving_seat = player.moving_seat
	displacement_position = player.displacement_position if player.is_sitting else Vector3()
	original_position = player.original_position if player.is_sitting else Transform3D()
	original_neck_basis = player.original_neck_basis if player.is_sitting else Basis()
	is_ejected = player.is_ejected
	currently_tweening = player.currently_tweening
	if is_sitting:
		current_sittable_path = CogitoSceneManager._current_sittable_node.get_path()


func load_sitting_state(player):
	player.is_sitting = is_sitting
	player.sittable_look_marker = sittable_look_marker
	player.sittable_look_angle = sittable_look_angle
	player.moving_seat = moving_seat
	player.displacement_position = displacement_position
	player.original_position = original_position
	player.original_neck_basis = original_neck_basis
	player.is_ejected = is_ejected
	player.currently_tweening = currently_tweening
	if is_sitting and current_sittable_path != null:
		CogitoSceneManager._current_sittable_node = CogitoSceneManager.get_node(current_sittable_path)


# Functions for attributes
func add_player_attribute_to_state_data(name: String, attribute_data:Vector2):
	player_attributes[name] = attribute_data


func clear_saved_attribute_data():
	player_attributes.clear()


# Functions for currencies
func add_player_currency_to_state_data(name: String, currency_data:Vector2):
	player_currencies[name] = currency_data


func clear_saved_currency_data():
	player_currencies.clear()


# Functions for world dictionary
func add_to_world_dictionary(world_property_name: String, world_property_data):
	if world_dictionary.has(world_property_name):
		world_dictionary[world_property_name] = world_property_data
		CogitoGlobals.debug_log(true, "CogitoPlayerState", "world dict key found and value saved: " + str(world_property_name) + " " + str(world_property_data) )
	else:
		world_dictionary.get_or_add(world_property_name)
		world_dictionary[world_property_name] = world_property_data
		CogitoGlobals.debug_log(true, "CogitoPlayerState", "world dict key not found. Added and value saved: " + str(world_property_name) + " " + str(world_property_data) )


func add_to_active_quest_dictionary(quest_name: String, current_quest_counter: int):
	player_active_quest_progression.get_or_add(quest_name)
	player_active_quest_progression[quest_name] = current_quest_counter
	CogitoGlobals.debug_log(true, "CogitoPlayerState", "Acitve quest added and counter value saved: " + str(quest_name) + " " + str(current_quest_counter) )


func clear_world_dictionary():
	world_dictionary.clear()


func add_interaction_component_state_data_to_array(state_data):
	interaction_component_state.append(state_data)


func clear_saved_interaction_component_state():
	interaction_component_state.clear()


func append_saved_wieldable_charges(saved_item_data):
	saved_wieldable_charges.append(saved_item_data)

func clear_saved_wieldable_charges():
	saved_wieldable_charges.clear()
