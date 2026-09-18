extends Control

@export var minimum_slots_count: int = 5
@export var maximum_slots_count: int = 100
@export var save_slot_container_scene : PackedScene


func _ready() -> void:
	load_all_save_slots()


func load_all_save_slots(auto_scroll=true):
	var last_active_slot = ""
	if CogitoSceneManager._player_state:
		last_active_slot = CogitoSceneManager._player_state.player_state_slot_name
	
	if %VBoxContainer.get_children().size() == 0:
		var max_slot_number = CogitoSceneManager.max_saved_slot_nubmer()
		var slots_count = max(minimum_slots_count, max_slot_number)
		for i in range(slots_count):
			var save_slot_container = save_slot_container_scene.instantiate()
			%VBoxContainer.add_child(save_slot_container)
			var save_slot = save_slot_container.get_node("SaveSlot")
			save_slot.save_slot_manager_node = %SaveSlotManager
			save_slot.manual_save_slot_name = str(i+1)
			save_slot.set_data_from_state(load_slot_data(save_slot.manual_save_slot_name))
	else:
		var save_slots = %VBoxContainer.get_children()
		
		for i in range(save_slots.size()):
			var save_slot = save_slots[i].get_node("SaveSlot")
			save_slot.save_slot_manager_node = %SaveSlotManager
			save_slot.manual_save_slot_name = str(i+1)
			save_slot.set_data_from_state(load_slot_data(save_slot.manual_save_slot_name))
		
		var max_slot_number = CogitoSceneManager.max_saved_slot_nubmer()
		if save_slots.size() == max_slot_number and save_slots.size() < maximum_slots_count:
			var save_slot_container = save_slot_container_scene.instantiate()
			%VBoxContainer.add_child(save_slot_container)
			var save_slot = save_slot_container.get_node("SaveSlot")
			save_slot.save_slot_manager_node = %SaveSlotManager
			save_slot.manual_save_slot_name = str(save_slots.size() + 1)
			save_slot.set_data_from_state(load_slot_data(save_slot.manual_save_slot_name))
		elif save_slots.size() > max_slot_number + 1 and save_slots.size() > minimum_slots_count:
			var empty_slots_count = save_slots.size() - max(minimum_slots_count, max_slot_number + 1)
			for i in range(empty_slots_count):
				var empty_slot = save_slots.pop_back()
				%VBoxContainer.remove_child(empty_slot)
	
	if last_active_slot:
		if last_active_slot != "temp":
			CogitoSceneManager.switch_active_slot_to(last_active_slot)
		else:
			CogitoSceneManager.switch_active_slot_to(CogitoSceneManager.get_last_saved_slot())
	
	if auto_scroll:
		await get_tree().process_frame
		%ScrollContainer.scroll_vertical = %ScrollContainer.get_v_scroll_bar().max_value


func focus_slot_on_load():
	var last_save_index = 0
	var last_save_slot = CogitoSceneManager.get_last_saved_slot()
	if last_save_slot:
		last_save_index = int(last_save_slot) - 1
	var save_slots = %VBoxContainer.get_children()
	
	var slot = save_slots[last_save_index]
	slot.get_node("SaveSlot").grab_focus.call_deferred()


func focus_slot_on_save():
	var save_slots = %VBoxContainer.get_children()
	var last_save_slot_index = 0

	for i in range(save_slots.size(), 0, -1):
		if CogitoSceneManager.is_saved_slot_exist(str(i)):
			last_save_slot_index = i
			break
	
	if last_save_slot_index == maximum_slots_count:
		last_save_slot_index -= 1
	
	var slot = save_slots[last_save_slot_index]
	slot.get_node("SaveSlot").grab_focus.call_deferred()


func load_slot_data(save_slot: String) -> CogitoPlayerState:
	# Set CSM active slot to slot to load
	CogitoSceneManager.switch_active_slot_to(save_slot)
	if CogitoSceneManager._player_state == null:
		return null
	else:
		return CogitoSceneManager._player_state
	

func start_new_game():
	if CogitoGlobals.cogito_settings.new_game_start_scene:
		var path_to_scene = CogitoGlobals.cogito_settings.new_game_start_scene.resource_path
		CogitoSceneManager.load_next_scene(path_to_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
		#Setting new game world state:
		CogitoSceneManager._current_world_dict = CogitoGlobals.cogito_settings.new_game_world_state.get_world_dict()
	#if start_game_scene: 
		#CogitoSceneManager.load_next_scene(start_game_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
	else:
		print("ISSUE: No start game scene set.")
