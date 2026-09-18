class_name CogitoInventoryInterface
extends Control

signal drop_slot_data(slot_data : InventorySlotPD)
signal inventory_open(is_true: bool)

@export var inventory_ui : InventoryUI
@onready var grabbed_slot_node: SlotPanel = $GrabbedSlot
@onready var external_inventory_ui = $ExternalInventoryUI
@onready var quick_slots : CogitoQuickslots = $QuickSlots
@onready var info_panel = $InfoPanel
@onready var item_name = $InfoPanel/MarginContainer/VBoxContainer/ItemName
@onready var item_description: Control = $InfoPanel/MarginContainer/VBoxContainer/ItemDescription
@onready var drop_prompt: Control = $InfoPanel/MarginContainer/VBoxContainer/HBoxDrop
@onready var assign_prompt: Control = $InfoPanel/MarginContainer/VBoxContainer/HBoxAssign
@onready var use_prompt: Control = $InfoPanel/MarginContainer/VBoxContainer/HBoxUse
@onready var cogito_tab_menu: CogitoTabMenu = $CogitoTabMenu

## Sound that plays as a generic error.
@export var sound_error : AudioStream
## If true, try to drop a grabbed item if there is no space to return it when closing inventory
@export var drop_item_on_close : bool = false

@export_group("Inventory Screen")
@export var nodes_to_show : Array[Node]
@export var nodes_to_hide : Array[Node]

var is_inventory_open : bool:
	set(value):
		is_inventory_open = value
		set_process_input(is_inventory_open)
		inventory_open.emit(is_inventory_open)
var grabbed_slot_data: InventorySlotPD
		
var external_inventory_owner : Node

var previously_focused_slot: SlotPanel
var slot_in_focus: SlotPanel
var input_event = null

func _ready():
	# Connect to signal that detects change of input device
	InputHelper.device_changed.connect(_on_input_device_change)
	# Calling this function once to set proper input icons
	_on_input_device_change(InputHelper.device,InputHelper.device_index)
	
	is_inventory_open = false
	info_panel.hide()
	cogito_tab_menu.hide()
	
	grabbed_slot_node.set_mouse_filter(2) # Setting mouse filter to ignore.
	grabbed_slot_node.set_focus_mode(0) # Setting focus mode to none.


func _on_input_device_change(_device: String, _device_index: int):
	if _device == "keyboard":
		drop_prompt.hide()
		assign_prompt.hide()
	else:
		drop_prompt.show()
		assign_prompt.show()


func open_inventory():
	if is_inventory_open: return
	
	is_inventory_open = true
	info_panel.hide()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	InputRouter.push(on_input)
	
	for node in nodes_to_show:
		node.show()
	
	# Setting tab menu to the first tab (inventory)
	cogito_tab_menu.current_tab = 0
	
	if InputHelper.device_index != -1: # Check if gamepad is used
		inventory_ui.slot_array[0].grab_focus.call_deferred() # Grab focus of inventory slot for gamepad users.
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	for slot_panel in inventory_ui.slot_array:
		if !slot_panel.mouse_entered.is_connected(_slot_on_mouse_entered):
			slot_panel.mouse_entered.connect(_slot_on_mouse_entered)
			
	# Cache the valid state of the inventory on open
	inventory_ui.loaded_inventory_data.refresh_valid_state()


func close_inventory():
	if is_inventory_open:
		if grabbed_slot_data != null: # If the player was holding/moving items, these will be added back to the inventory.
			# If there is space, return the item. If not, drop the item (short circuit if drop_item_on_close is false). If the item can't be dropped, reset the inventory to a previously valid state
			var is_space = get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data)
			if not is_space and (not drop_item_on_close or not _drop_item(grabbed_slot_data)):
				inventory_ui.loaded_inventory_data.reset_to_valid_state()
			grabbed_slot_data = null
		is_inventory_open = false
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)
		if slot_in_focus:
			slot_in_focus.release_focus()
		
		# Clearing out UI grabbed slot
		if inventory_ui.grabbed_slot:
			inventory_ui.detach_grabbed_slot()
		
		for node in nodes_to_show:
			node.hide()
		
		if external_inventory_owner:
			external_inventory_owner.close()

		grabbed_slot_node.hide()
		info_panel.hide()
		external_inventory_ui.hide()
		
		InputRouter.pop()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		inventory_open.emit(false)


## When the info panel is visible, this will check that if the mouse goes off the grid, 
## it will unhighlight the previously hovered item and hide the info box.
func out_of_bounds_check_mouse():
	var slot_size = 32
	var grid = inventory_ui.grid_container
	var ui_rect = Rect2(grid.global_position - Vector2(0, slot_size), grid.size + Vector2(slot_size/4,slot_size/2))
	var mouse_rect = Rect2(get_global_mouse_position(), Vector2(1,1))
	if !ui_rect.encloses(mouse_rect):
		inventory_ui.highlight_item(slot_in_focus, false)
		info_panel.hide()


func _on_focus_changed(control: Control):
	if control is not SlotPanel:
		CogitoGlobals.debug_log(true,"inventory_interface.gd", "_on_focus_changed: Not a slot. returning.")
		return
	
	# Keep a hold of the previously focused control to compare with the current
	if control != null:
		previously_focused_slot = slot_in_focus if slot_in_focus else control
		slot_in_focus = control
	
	# Quick check to see if this is a quickslot
	if slot_in_focus is CogitoQuickslotContainer:
		return
	
	# This shows the info panel for an item when highlighted
	if slot_in_focus.item_data and !grabbed_slot_node.visible:
		item_name.text = slot_in_focus.item_data.name
		item_description.text = slot_in_focus.item_data.description
		if InputHelper.device_index != -1:
			info_panel.global_position = slot_in_focus.global_position + Vector2(0,slot_in_focus.size.y)
		
		if slot_in_focus.item_data.is_droppable:
			drop_prompt.show()
		else: drop_prompt.hide()
		
		if !slot_in_focus.item_data.has_method("use"):
			use_prompt.hide()
		else:
			use_prompt.show()

		info_panel.show()
		# Highlight all the slots that occupy the size of the item
		inventory_ui.highlight_item(slot_in_focus, true)
		unhighlight_slots_if_moving_between()

		if !control.mouse_entered.is_connected(_slot_on_mouse_entered):
			control.mouse_entered.connect(_slot_on_mouse_entered)
		
	else:
		unhighlight_slots_if_moving_between()
		info_panel.hide()
	
	# Updating the currently focused slot in the inventory_ui
	inventory_ui.currently_focused_slot = slot_in_focus
	
	# How a grabbed item gets displayed.
	if grabbed_slot_node.visible:
		grabbed_slot_node.hide_slot_border()
		grabbed_slot_node.set_mouse_filter(2) # Setting mouse filter to ignore.
		grabbed_slot_node.set_focus_mode(0) # Setting focus mode to none.
		if InputHelper.device_index != -1: # Updating grabbed item position if using gamepad
			update_grabbed_slot_position()


func _slot_on_mouse_entered():
	if !slot_in_focus or !previously_focused_slot:
		return
	unhighlight_slots_if_moving_between()


## Remove an existing highlighted item if focus shifts to another item or a blank slot
func unhighlight_slots_if_moving_between():
	if previously_focused_slot is CogitoQuickslotContainer or slot_in_focus is CogitoQuickslotContainer:
		return
	if slot_in_focus.origin_index != previously_focused_slot.origin_index:
		inventory_ui.highlight_item(previously_focused_slot, false)


func update_grabbed_slot_position():
	if slot_in_focus == null:
		return
	# print("Inventory interface: update grabbed slot position to ", slot_in_focus, " at ", slot_in_focus.global_position)
	grabbed_slot_node.global_position = slot_in_focus.global_position + (slot_in_focus.size / 2)


func _apply_grabbed_slot_position_after_layout():
	if slot_in_focus == null:
		return
	# Wait for the next frame to ensure layout is complete
	await get_tree().process_frame
	if slot_in_focus != null and grabbed_slot_node.visible:
		grabbed_slot_node.global_position = slot_in_focus.global_position + (slot_in_focus.size / 2)
		# Now make it visible
		grabbed_slot_node.modulate.a = 1


func _physics_process(_delta):
	if InputHelper.device_index == -1: #Checking for keyboard/mouse control.
		if input_event:
			mouse_button_check(input_event)
			input_event = null
			update_grabbed_slot()
		if grabbed_slot_node.visible:
			grabbed_slot_node.global_position = get_global_mouse_position() + Vector2(5, 5)
			return
			
		if info_panel.visible:
			info_panel.global_position = get_global_mouse_position() + Vector2(5, 5)
			out_of_bounds_check_mouse()


func set_external_inventory(_external_inventory_owner):
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	inventory_data.owner = external_inventory_owner # Setting reference to external inventory owner node
	if !inventory_data.inventory_button_press.is_connected(on_inventory_button_press):
		inventory_data.inventory_button_press.connect(on_inventory_button_press.bind(external_inventory_ui))
	external_inventory_ui.inventory_name = external_inventory_owner.display_name
	external_inventory_ui.set_inventory_data(inventory_data)
	
	external_inventory_ui.show()
	external_inventory_ui.button_take_all.show()
	if !external_inventory_ui.button_take_all.pressed.is_connected(_on_take_all_pressed):
		external_inventory_ui.button_take_all.pressed.connect(_on_take_all_pressed)


## Loot Component added
func get_external_inventory():
	return external_inventory_owner
	

func _on_take_all_pressed():
	external_inventory_owner.inventory_data.take_all_items(get_parent().player.inventory_data)


func clear_external_inventory():
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
		inventory_data.inventory_button_press.disconnect(on_inventory_button_press)
		external_inventory_ui.inventory_name = ""
		external_inventory_ui.clear_inventory_data(inventory_data)
		external_inventory_ui.hide()
		external_inventory_owner = null


func set_player_inventory_data(inventory_data : CogitoInventory):
	inventory_data.owner = CogitoSceneManager._current_player_node  # Setting player inventory owner reference to player node
	
	if !inventory_data.inventory_button_press.is_connected(on_inventory_button_press):
		inventory_data.inventory_button_press.connect(on_inventory_button_press.bind(inventory_ui))
	inventory_ui.set_inventory_data(inventory_data)
	
	quick_slots.show()
	# Quickslots need reference to inventory when quickslot buttons are pressed
	quick_slots.inventory_reference = inventory_data
		
	if !inventory_open.is_connected(quick_slots.update_inventory_status):
		inventory_open.connect(quick_slots.update_inventory_status)
	grabbed_slot_node.using_grid(inventory_data.grid)


# Inventory handling on gamepad buttons
func on_inventory_button_press(inventory_data: CogitoInventory, index: int, action: String, local_inventory_ui):
	# Update slot_in_focus immediately to ensure grabbed slot positioning is correct
	slot_in_focus = local_inventory_ui.slot_array[index]
	input_event = null
	
	match [grabbed_slot_data, action]:
		[_, "inventory_rotate_item"]:
			rotate_item()
		[null, "inventory_move_item"]:
			# Check if item is being wielded before grabbing it.
			var temp_slot_data = inventory_data.get_slot_data(index)
			if temp_slot_data and temp_slot_data.inventory_item and temp_slot_data.inventory_item.is_being_wielded:
					Audio.play_sound(sound_error)
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't move item while its being wielded.")
			else:
				grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, "inventory_move_item"]:
			grabbed_slot_data = inventory_data.release_slot_data(grabbed_slot_data, index)
		[null, "inventory_use_item"]:
			inventory_data.use_slot_data(index)
		[_, "inventory_use_item"]:
			print("Inventory_interface.gd: Gamepad use_item pressed while grabbed_slot_data. Calling release_single_slot_data...")
			grabbed_slot_data = inventory_data.release_single_slot_data(grabbed_slot_data, index)
		[null, "inventory_drop_item"]:
			grabbed_slot_data = inventory_data.get_slot_data(index)
			if grabbed_slot_data:
				if !grabbed_slot_data.inventory_item.is_droppable:
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Item is not droppable.")
					Audio.play_sound(sound_error)
					grabbed_slot_data = null
					return
				if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
				#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
					Audio.play_sound(sound_error)
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop while wielding this item.")
					grabbed_slot_data = null
				else:
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Dropping slot data via gamepad ")
					grabbed_slot_data = inventory_data.grab_single_slot_data(index)
					if not _drop_item(grabbed_slot_data):
						Audio.play_sound(sound_error)
						get_parent().player.player_interaction_component.send_hint(null, "Not enough space to drop item.")
						CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop because there isn't enough space.")
					else:
						grabbed_slot_data = null
						inventory_ui.loaded_inventory_data.refresh_valid_state()
		
		[null, "inventory_assign_item"]: # Pressing "Assign quickslot" on gamepad
			CogitoGlobals.debug_log(true, "inventory_interface.gd", "Grabbing focus of quickslots.")
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			quick_slots.quickslot_containers[0].grab_focus.call_deferred()
			
		[_, "inventory_assign_item"]: # When player cancels out assigning a quickslot on gamepad
			get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data)
			grabbed_slot_data = null
			update_grabbed_slot()
		
		[_, "inventory_drop_item"]:
			Audio.play_sound(sound_error)
			CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop while moving an item.")

	# When connecting to the signal, we have bind the inventory_ui so we can use that to set focus.
	local_inventory_ui.slot_array[index].grab_focus()
	update_grabbed_slot()
	update_wieldable_if_equipped()


func update_wieldable_if_equipped():
	CogitoSceneManager._current_player_node.player_interaction_component.update_equipped()


func update_grabbed_slot():
	if grabbed_slot_data:
		# For gamepad users, hide with alpha to avoid flicker while we position
		if InputHelper.device_index != -1:
			grabbed_slot_node.modulate.a = 0
		grabbed_slot_node.show()
		grabbed_slot_node.set_slot_data(grabbed_slot_data, grabbed_slot_node.get_index(), true, 0)
		inventory_ui.grabbed_slot = grabbed_slot_node
		if external_inventory_ui.visible:
			external_inventory_ui.grabbed_slot = grabbed_slot_node
		grabbed_slot_node.set_grabbed_dimensions()
		# Position and reveal after layout is ready
		if InputHelper.device_index != -1:
			_apply_grabbed_slot_position_after_layout.call_deferred()
	else:
		grabbed_slot_node.hide()
		grabbed_slot_node.modulate.a = 1
		inventory_ui.detach_grabbed_slot()
		external_inventory_ui.detach_grabbed_slot()
		# Focus callback to show info box after placing the item when using mouse
		if slot_in_focus and InputHelper.device_index == -1:
			_on_focus_changed(slot_in_focus)


func _on_bind_grabbed_slot_to_quickslot(quickslotcontainer: CogitoQuickslotContainer):
	if grabbed_slot_data:
		input_event = null
		CogitoGlobals.debug_log(true, "inventory_interface.gd", "Binding to quickslot container: " + str(grabbed_slot_data) + " -> " + str(quickslotcontainer) )
		#get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data) #Swapped with line below
		quick_slots.bind_to_quickslot(grabbed_slot_data, quickslotcontainer)
		
		#inventory_ui.detach_grabbed_slot()
		#grabbed_slot_data = null
		#update_grabbed_slot()
	else:
		CogitoGlobals.debug_log(true, "inventory_interface.gd", "No grabbed slot data.")


# Rotating the item using the keyboard
func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") or event.is_action_pressed("ui_cancel"):
		close_inventory()
	
	if event is InputEventMouseButton \
		and event.is_pressed() \
		and grabbed_slot_data:
			input_event = event
	
	if Input.is_action_just_pressed("inventory_rotate_item") and grabbed_slot_data:
		rotate_item()


func mouse_button_check(event):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if !grabbed_slot_data:
			return
		if !grabbed_slot_data.inventory_item.is_droppable:
			error_log("This item isn't droppable.")
			return
		if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
			error_log("Can't drop while wielding this item.")
		else:
			if not _drop_item(grabbed_slot_data):
				error_log("Can't drop because there isn't enough space.")
				get_parent().player.player_interaction_component.send_hint(null, "Not enough space to drop item.")
			else:
				grabbed_slot_data.create_single_slot_data(grabbed_slot_data.origin_index)
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
					inventory_ui.loaded_inventory_data.refresh_valid_state()


func error_log(error: String):
	Audio.play_sound(sound_error)
	CogitoGlobals.debug_log(true, "inventory_interface.gd", error)


func _on_visibility_changed():
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()


func _on_inventory_ui_hidden() -> void:
	# Hides item info panel if the inventory UI screen gets hidden.
	info_panel.hide()


func rotate_item() -> void:
	# Don't bother rotating if the items x and y size are equivalent
	var item_size = grabbed_slot_node.get_item().item_size
	if item_size.x == item_size.y:
		return
	# Unhighlight all slots first
	inventory_ui.unhighlight_all_slots()
	# Rotate the slot and item texture
	grabbed_slot_node.rotate()
	# Call the highlight slots method using the index of the hovered slot
	inventory_ui.highlight_slots_if_grabbed(slot_in_focus.get_index(), true)
	update_grabbed_slot()


func _drop_item(slot_data: InventorySlotPD) -> bool:
	var player = get_parent().player
	var player_radius = player.radius
	var shape_cast = player.item_drop_shapecast
	var item_drop_distance_offset = player.player_hud.item_drop_distance_offset
	var camera_basis_z = get_viewport().get_camera_3d().get_global_transform().basis.z
	
	var drop_distance = abs(shape_cast.target_position.z - item_drop_distance_offset)
	
	var scene_to_drop = load(slot_data.inventory_item.drop_scene)
	var dropped_item = scene_to_drop.instantiate()
	
	if dropped_item is not CogitoObject:		
		return false
	
	# Pass the existing data of the slot to the object, otherwise infinite ammo glitch
	dropped_item.pass_inventory_data(slot_data.duplicate())
		
	var item_aabb = dropped_item.get_aabb()
	var item_length = item_aabb.size.z
	
	shape_cast.add_exception(player)
	
	shape_cast.shape.size = item_aabb.size
	
	var previous_target_position = shape_cast.target_position
	shape_cast.target_position = Vector3.ZERO
	
	shape_cast.force_shapecast_update()
	
	if shape_cast.is_colliding():
		shape_cast.target_position = previous_target_position
		return false
	
	shape_cast.target_position = previous_target_position
	
	shape_cast.force_shapecast_update()
	
	var collision_safe_fraction = shape_cast.get_closest_collision_safe_fraction()
	var safe_drop_distance = drop_distance * collision_safe_fraction
	
	if item_length < player_radius:
		if safe_drop_distance < player_radius:
			return false
	else:
		if safe_drop_distance < item_length:
			return false
			
	CogitoSceneManager._current_scene_root_node.add_child(dropped_item)
	dropped_item.global_rotation = player.body.global_rotation
	dropped_item.position = shape_cast.global_position + (safe_drop_distance - item_length / 2) * -camera_basis_z
		
	Audio.play_sound(slot_data.inventory_item.sound_drop)
	
	if item_length < player_radius:
		dropped_item.position = shape_cast.global_position + (safe_drop_distance - item_length / 2) * -camera_basis_z
	else:
		dropped_item.position = shape_cast.global_position + (safe_drop_distance - item_length / 2 + player_radius) * -camera_basis_z
		
	dropped_item.find_interaction_nodes()
	for node in dropped_item.interaction_nodes:
		if node.has_method("get_item_type"):
			node.slot_data = slot_data
	return true
