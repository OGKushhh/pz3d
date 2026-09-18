extends Resource
class_name CogitoInventory

signal inventory_interact(inventory_data: CogitoInventory, index: int, mouse_button: int)
signal inventory_button_press(inventory_data: CogitoInventory, index: int, action: String)
signal inventory_updated(inventory_data: CogitoInventory)
signal unbind_quickslot_by_index(quickslot_index: int)
signal picked_up_new_inventory_item(slot_data: InventorySlotPD)

## Enables grid inventory. If using, make sure player and ALL interactables have this set to true.
@export var grid: bool
## Injects items from this into the inventory slots
# @export var starter_inventory : Array[InventorySlotPD]
@export var inventory_size : Vector2i = Vector2i(4,1)
@export var inventory_slots : Array[InventorySlotPD]

var assigned_quickslots : Array[InventorySlotPD]
var owner : Node

@export var first_slot : InventorySlotPD

# Cache a valid inventory state. Contains origin_index and rotation state since inventory slots
# are resources and thus aren't affected by deep copy duplication
var valid_inventory_state : Array[InventoryState]
class InventoryState:
	var slot: InventorySlotPD
	var origin_index: int
	var rotated: bool
	
	func _init(_slot, _origin_index):
		slot = _slot
		origin_index = _origin_index
		if slot and slot.inventory_item:
			rotated = slot.inventory_item.rotated


func _init():
	if inventory_slots.size() > 0:
		first_slot = inventory_slots[0]


# Call this in your initial scene
#func apply_initial_inventory():
	#inventory_slots.resize(inventory_size.x * inventory_size.y)
	#for item in starter_inventory:
		#pick_up_slot_data(item)
	#if inventory_slots.size() > 0:
		#first_slot = inventory_slots[0]


## Cache the current state of the inventory. Only called when opening inventory or dropping items. 
func refresh_valid_state():
	CogitoGlobals.debug_log(true, "cogito_inventory.gd", "Refreshing valid state for inventory...")
	valid_inventory_state.clear()
	for slot in inventory_slots:
		valid_inventory_state.append(InventoryState.new(slot, slot.origin_index if slot else -1))


## If an item cannot be dropped and cannot be returned to the inventory, reset the inventory to its last cached valid state.
func reset_to_valid_state():
	CogitoGlobals.debug_log(true, "cogito_inventory.gd", "Inventory state is invalid, resetting to previously good state...")
	# Rewrite each inventory slot with the state of the original, as well as origin index and rotation state
	for index in range(valid_inventory_state.size()):
		var slot = valid_inventory_state[index].slot
		inventory_slots[index] = slot
		if slot:
			inventory_slots[index].origin_index = valid_inventory_state[index].origin_index
			if slot.inventory_item and slot.inventory_item.rotated != valid_inventory_state[index].rotated:
				slot.inventory_item.rotate()
	inventory_updated.emit(self)


func on_slot_clicked(index: int, mouse_button: int):
	inventory_interact.emit(self, index, mouse_button)


func on_slot_button_pressed(index: int, action: String):
	CogitoGlobals.debug_log(true,"cogito_inventory.gd", "on_slot_button_pressed. index=" + str(index) + ", action=" + str(action) )
	inventory_button_press.emit(self, index, action)


func null_out_slots(slot_data: InventorySlotPD):
	if not slot_data:
		return
	var size = slot_data.inventory_item.item_size if grid else Vector2i(1,1)
	for x in size.x:
		for y in size.y:
			inventory_slots[slot_data.origin_index + x + (y*inventory_size.x)] = null


func find_slots(target: String) -> Array[InventorySlotPD]:
	var matched_slots: Array[InventorySlotPD] = []
	for index in range(inventory_slots.size()):
		var slot = inventory_slots[index] 
		if slot == null or slot.origin_index != index:
			continue
		if slot.inventory_item.name == target:
			matched_slots.append(slot)
	return matched_slots

# Returns slot data without actually changing the slot
func get_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	if slot_data:
		return slot_data
	else:
		return null


func grab_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	if slot_data:
		null_out_slots(slot_data)
		inventory_updated.emit(self)
		return slot_data
	else:
		return null


func grab_single_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	if slot_data:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			null_out_slots(slot_data)
		inventory_updated.emit(self)
		return slot_data
	else:
		return null


func use_slot_data(index: int):
	if index == -1: # No item assigned to hotbar
		return
	
	var slot_data = inventory_slots[index]
	
	if not slot_data:
		return
	
	if !slot_data.inventory_item.has_method("use"):
		return

	var use_successful : bool = slot_data.inventory_item.use(owner)
	if slot_data.inventory_item.has_method("is_consumable") and use_successful:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			null_out_slots(slot_data)
	
	inventory_updated.emit(self)
	
	
# Function to remove a specific item from inventory directly (without picking it up etc)
# Used for example by KEY items to be discarded after using them
func remove_slot_data(slot_data_to_remove: InventorySlotPD):
	var index = inventory_slots.find(slot_data_to_remove,0)
	if index == -1:
		CogitoGlobals.debug_log(true,"cogito_inventory.gd", "Couldn't remove item from inventory as it wasn't found.")
		return
	else:
		print("Removing ", slot_data_to_remove, " at index ", index)
		null_out_slots(slot_data_to_remove)
		inventory_updated.emit(self)


func remove_item_from_stack(slot_data: InventorySlotPD):
	var index = inventory_slots.find(slot_data,0)
	if index == -1:
		CogitoGlobals.debug_log(true,"cogito_inventory.gd", "Couldn't remove item from item stack as it wasn't found.")
		return
	else:
		print("Removing ", slot_data, " at index ", index)
		inventory_slots[index].quantity -= 1
		# What happens if last item of stack is removed.
		if inventory_slots[index].quantity <= 0:
			null_out_slots(slot_data)
			
			# If inventory slot was bind to a quick slot, unbind it.
			var quickslot_index = assigned_quickslots.find(inventory_slots[index],0)
			if quickslot_index > -1:
				unbind_quickslot_by_index.emit(quickslot_index)
				
		inventory_updated.emit(self)


## Try to put the grabbed item back into the inventory. Returns a new 'grabbed' item:
## grabbed_slot_data: The original grabbed item if there was a failure to release it
## item_to_swap: An item displaced by the released item
## null: Nothing is grabbed now, item was successfully released
func release_slot_data(grabbed_slot_data: InventorySlotPD, index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	var return_slot_data : InventorySlotPD
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	elif is_enough_space(grabbed_slot_data, index, false):
		# Swap out item
		var item_to_swap = get_item_to_swap(grabbed_slot_data, index)
		
		# If item to swap is being wielded, cancel the swap
		if item_to_swap and item_to_swap.inventory_item and item_to_swap.inventory_item.is_being_wielded:
			print("cogito_inventory.gd: ERROR - cants swap out item thats being wielded.")
			return grabbed_slot_data
		
		null_out_slots(item_to_swap)
		grabbed_slot_data.origin_index = index
		inventory_slots[index] = grabbed_slot_data
		add_adjacent_slots(index)
		return_slot_data = item_to_swap
	else:
		# do nothing, the grabbed slot remains the same
		return grabbed_slot_data
		
	inventory_updated.emit(self)
	return return_slot_data

## See release_slot_data above. This is for releasing an item when invoked by a gamepad.
func release_single_slot_data(grabbed_slot_data: InventorySlotPD, index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	if not slot_data and is_enough_space(grabbed_slot_data, index, false):
		inventory_slots[index] = grabbed_slot_data.create_single_slot_data(index)
		add_adjacent_slots(index)
		CogitoGlobals.debug_log(true,"cogito_inventory.gd", "release_single_slot_data(...): grabbed item placed in inventory.")
	elif not slot_data:
		return grabbed_slot_data
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data(slot_data.origin_index))
		CogitoGlobals.debug_log(true,"cogito_inventory.gd", "release_single_slot_data(...): grabbed item fully merged with target.")
		#return null
	# Logic for ammo items
	elif slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.has_method("is_ammo_item") and slot_data.inventory_item.get_current_ammo().name == grabbed_slot_data.inventory_item.name:
		CogitoGlobals.debug_log(true,"cogito_inventory.gd", "release_single_slot_data(...): AmmoItem detected. Attempting to reload target.")
		# Check if there's room for charge
		if slot_data.inventory_item.charge_max - slot_data.inventory_item.charge_current >= grabbed_slot_data.inventory_item.reload_amount:
			CogitoSceneManager._current_player_node.player_interaction_component.send_hint(null,"Charging " + slot_data.inventory_item.name + " by " + str(grabbed_slot_data.inventory_item.reload_amount))
			slot_data.inventory_item.add(grabbed_slot_data.inventory_item.reload_amount)
			grabbed_slot_data.quantity -= 1
		else:
			CogitoGlobals.debug_log(true,"cogito_inventory.gd", "release_single_slot_data(...): AmmoItem detected. Target charge is too high to be reloaded.")
	# Check if grabbed item is a combinable AND check if slot item is the target combine item:
	elif grabbed_slot_data.inventory_item.has_method("is_combinable") and slot_data.inventory_item.name == grabbed_slot_data.inventory_item.target_item_combine :
		# Reduce/destroy both items.
		remove_slot_data(slot_data)
		grabbed_slot_data.quantity -= 1
		# Add resulting item to inventory:
		pick_up_slot_data(grabbed_slot_data.inventory_item.resulting_item)
	
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null
		
	#if grabbed_slot_data.quantity > 0:
		## Swapping items
		#var item_to_swap = get_item_to_swap(grabbed_slot_data, index)
		#null_out_slots(item_to_swap)
		#return grabbed_slot_data
	#else:
		## Placing items
		#print("cogito_inventory.gd: release_single_slot_data( grabbed item name=", grabbed_slot_data.inventory_item.name, ", ", index, "): Placing items reached.")
		#return null


## Attempt to pick up slot data by first attempting a merge, then attempt an add if there is space.
## Will perform an item rotation on the first failed attempt at either strategy.
func pick_up_slot_data(slot_data: InventorySlotPD) -> bool:	
	# Try and merge slots if they exist, rotate the item on failure
	var merged = try_merge_slots(slot_data)
	if not merged:
		slot_data.inventory_item.rotate()
		merged = try_merge_slots(slot_data)
	# If merge was successful return true, else rotate the item back to normal
	if merged:
		return true
	else:
		slot_data.inventory_item.rotate()
	
	# Try and add slots if there is space, rotate the item on failure	
	var added = try_add_slots(slot_data)
	if not added:
		slot_data.inventory_item.rotate()
		added = try_add_slots(slot_data)
	# If add was successful return true, else rotate the item back to normal
	if added:
		return true
	else:
		slot_data.inventory_item.rotate()

	return false


## Try and merge existing slots if they exist. Return true if this was successful.
func try_merge_slots(slot_data: InventorySlotPD) -> bool:
	for index in inventory_slots.size():
		slot_data.origin_index = index
		if inventory_slots[index] and inventory_slots[index].can_fully_merge_with(slot_data):
			slot_data.origin_index = index
			inventory_slots[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			return true
	return false


## Try and add an item if there is existing space. Return true if this was successful.
func try_add_slots(slot_data: InventorySlotPD) -> bool:
	for index in inventory_slots.size():
		slot_data.origin_index = index
		if not inventory_slots[index] and is_enough_space(slot_data, index, true):
			inventory_slots[index] = slot_data
			add_adjacent_slots(index)
			inventory_updated.emit(self)
			picked_up_new_inventory_item.emit(slot_data)
			return true
	return false


## LootComponent - Gets all items in inventory
func get_all_items() -> Array[InventoryItemPD]:
	var result: Array[InventoryItemPD] = []
	for slot in inventory_slots:
		if slot != null:
			result.append(slot.inventory_item)
	return result


# Function to attempt to take all the items from this inventory into target inventory.
func take_all_items(target_inventory: CogitoInventory):
	for slot in inventory_slots:
		if slot != null:
			#grab item in slot and add it to target inventory
			if target_inventory.pick_up_slot_data(slot.duplicate()):
				print("Grabbed ", slot.inventory_item.name)
				remove_slot_data(slot) #Empty the slot
				force_inventory_update()
			else:
				CogitoSceneManager.send_player_hint(slot.inventory_item.square_icon, "Unable to pick-up %s." % slot.inventory_item.name)


func force_inventory_update():
	print("Forced inventory update: ", self)
	inventory_updated.emit(self)


func add_adjacent_slots(index: int):
	if not grid:
		return
	var size = inventory_slots[index].inventory_item.item_size
	for x in size.x:
		for y in size.y:
			inventory_slots[index + x + (y*inventory_size.x)] = inventory_slots[index]


# check if an item either has free slots to occupy or can swap one item out
func is_enough_space(grabbed_slot_data: InventorySlotPD, to_place_index: int, pickup: bool):
	var swap_origin = -1
	var size = grabbed_slot_data.inventory_item.item_size if grid else Vector2i(1,1)
	# check outside of y bounds
	if (to_place_index + (size.x-1) + ((size.y-1)*inventory_size.x)) >= inventory_slots.size():
		return false
	var right_edge: int = to_place_index + size.x-1
	# check row does not shift
	if (int(to_place_index / inventory_size.x) != int(right_edge / inventory_size.x)):
		return false
	for x in size.x:
		for y in size.y:
			var adj_item = inventory_slots[to_place_index + x + (y*inventory_size.x)]
			if not adj_item:
				continue
			elif pickup: # if picking up an item, swap logic should not be invoked
				return false
			elif swap_origin == -1 and adj_item.origin_index != -1:
				swap_origin = adj_item.origin_index	
			elif adj_item.origin_index != swap_origin and adj_item.origin_index != -1:
				return false
	return true


func get_item_to_swap(grabbed_slot_data: InventorySlotPD, to_place_index: int):
	var size = grabbed_slot_data.inventory_item.item_size if grid else Vector2i(1,1)
	for x in size.x:
		for y in size.y:
			var adj_item = inventory_slots[to_place_index + x + (y*inventory_size.x)]
			if not adj_item:
				continue
			if adj_item.origin_index != -1:
				return adj_item


## Returns whether the given item fits in inventory
func can_pick_up_slot_data(slot_data: InventorySlotPD) -> bool:
	for index in inventory_slots.size():
		if inventory_slots[index] and inventory_slots[index].can_fully_merge_with(slot_data):
			return true
	for index in inventory_slots.size():
		if not inventory_slots[index] and is_enough_space(slot_data, index, true):
			return true
	return false
