extends PanelContainer
class_name InventoryUI

const Slot = preload("./Slot.tscn")

@export var inventory_name : String = ""

@export var color_can_swap : Color = Color.YELLOW
@export var color_can_not_place : Color = Color.DARK_RED
@export var color_can_place : Color = Color.LIME_GREEN

@onready var grid_container = $MarginContainer/VBoxContainer/GridContainer
@onready var label = $MarginContainer/VBoxContainer/Label
@onready var button_take_all: Button = $MarginContainer/VBoxContainer/Button_TakeAll

var slot_array: Array[InventorySlot] = []
var first_slot : InventorySlotPD
var grabbed_slot : SlotPanel
var loaded_inventory_data : CogitoInventory
var currently_focused_slot : SlotPanel

func _ready():
	label.text = inventory_name
	button_take_all.hide()


func set_inventory_data(inventory_data : CogitoInventory):
	if !inventory_data.inventory_updated.is_connected(populate_item_grid):
		inventory_data.inventory_updated.connect(populate_item_grid)
	label.text = inventory_name
	loaded_inventory_data = inventory_data
	populate_item_grid(inventory_data)


func clear_inventory_data(inventory_data : CogitoInventory):
	inventory_data.inventory_updated.disconnect(populate_item_grid)
	slot_array.clear()


func populate_item_grid(inventory_data : CogitoInventory) -> void:
	CogitoGlobals.debug_log(true,"InventoryUI.gd", "Populate_item_grid called." )
	
	for child in grid_container.get_children():
		child.queue_free()
	
	# Clearing array for gamepad navigation.
	slot_array.clear()
	
	if inventory_data.grid:
		# set grid container columns to the width (x) of the inventory
		grid_container.columns = inventory_data.inventory_size.x
	
	var index = 0
	for slot_data in inventory_data.inventory_slots:
		var slot = Slot.instantiate()
		grid_container.add_child(slot)
		# Filling array for gamepad navigation.
		slot_array.append(slot)
	
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		slot.slot_pressed.connect(inventory_data.on_slot_button_pressed)
		slot.highlight_slot.connect(highlight_slots_if_grabbed)
		slot.using_grid(inventory_data.grid)
	
		if slot_data:
			slot.set_slot_data(slot_data, index, false, grid_container.columns)
			slot.set_hotbar_icon()
			
		index += 1
	
	override_slot_focus_neighbors()
	
	if inventory_data.grid:
		apply_slot_icon_regions()


func override_slot_focus_neighbors():
	var index = 0
	for slot in slot_array:
		# SETTING LEFT NEIGHBOR
		if index != 0:
			slot.set_focus_neighbor(SIDE_LEFT, slot_array[index-1].get_path())
		
		# SETTING RIGHT NEIGHBOR
		if index != slot_array.size() - 1:
			slot.set_focus_neighbor(SIDE_RIGHT, slot_array[index+1].get_path())
			
		# SETTING UP NEIGHBOR:
		if (index - loaded_inventory_data.inventory_size.x) >= 0: #This checks if the selected slot is NOT already in the top row.
			slot.set_focus_neighbor(SIDE_TOP, slot_array[index - loaded_inventory_data.inventory_size.x].get_path())

		# SETTING UP DOWN NEIGHOR:
		if (index + loaded_inventory_data.inventory_size.x) < slot_array.size(): #This checks that the slot is NOT already in the bottom row.
			slot.set_focus_neighbor(SIDE_BOTTOM, slot_array[index + loaded_inventory_data.inventory_size.x].get_path() )

		index += 1


func apply_slot_icon_regions():
	var added_items = []
	for slot in slot_array:
		if slot.item_data and not added_items.has(slot.origin_index):
			added_items.append(slot.origin_index)
			apply_item_icons(slot.item_data, slot.origin_index)
		else:
			continue


func apply_item_icons(item_data : InventoryItemPD, origin_index: int):
	var icon_slot_size = item_data.item_size
	for x in icon_slot_size.x:
		for y in icon_slot_size.y:
			var index = origin_index + x + (y*grid_container.columns)
			slot_array[index].set_icon_region(x, y)
			CogitoGlobals.debug_log(true,"InventoryUI.gd","apply_item_icons: item_data=" + item_data.name + " set_icon_region(" + str(x) + "," + str(y) + ")")


func unhighlight_all_slots():
	for slot in slot_array:
		slot.highlight_panel.hide()
		slot.selection_panel.hide()


func detach_grabbed_slot():
	unhighlight_all_slots()
	grabbed_slot = null


## Highlight all the slots an item occupies when hovered over.
func highlight_item(focused_slot, highlight: bool):
	if InputHelper.device_index != -1: # Don't highlight for gamepad
		return
	var item_data = focused_slot.item_data
	var origin_index = focused_slot.origin_index
	if !item_data:
		return
	# No need to highlight more slots if an item is 1x1
	var highlight_size = item_data.item_size
	if highlight_size == Vector2i(1,1):
		return
	# Highlight the origin point (top-left) first:
	slot_array[origin_index].highlight_panel.set_visible(highlight)
	for x in highlight_size.x:
		for y in highlight_size.y:
			var slot = slot_array[origin_index + x + (y*grid_container.columns)]
			slot.highlight_panel.set_visible(highlight)
			slot.highlight_panel.modulate = Color(255,255,255,0.1)
			

## Highlight all the slots that will be occupied when moving an item. Colour code to determine
## if the item can be moved or not.
func highlight_slots_if_grabbed(index: int, highlight: bool):
	if !grabbed_slot or !grabbed_slot.item_data or !grabbed_slot.grid:
		return false # Let the slot know it should reset its fill
	var highlight_size : Vector2i = grabbed_slot.item_data.item_size if grabbed_slot.grid else Vector2i(1,1)
	var item_intersections = count_intersecting_items(index, highlight_size)
	for x in highlight_size.x:
		for y in highlight_size.y:
			if out_of_bounds(index, x, y):
				continue
			var slot = slot_array[index + x + (y*grid_container.columns)]
			var selection = slot.selection_panel
			var fill = slot.highlight_panel
			if highlight:
				selection.show()
				fill.show()
			else:
				selection.hide()
				fill.hide()
	change_slot_colours(highlight_size, index, item_intersections)
	return true


func change_slot_colours(slot_group: Vector2i, index, item_intersections):
	for x in slot_group.x:
		for y in slot_group.y:
			if out_of_bounds(index, x, y):
				continue
			var slot:SlotPanel = slot_array[index + x + (y*grid_container.columns)]
			slot.change_slot_colour(set_colour(item_intersections))


# count intersections to check if item can be swapped out
func count_intersecting_items(index: int, intersect_size: Vector2i):
	var intersecting_origins = []
	for x in intersect_size.x:
		for y in intersect_size.y:
			if out_of_bounds(index, x, y):
				return -1
			var adj_item = slot_array[index + x + (y*grid_container.columns)]
			if not adj_item:
				continue
			if adj_item.origin_index != -1 and not intersecting_origins.has(adj_item.origin_index):
				intersecting_origins.append(adj_item.origin_index)
	return intersecting_origins.size()


func set_colour(item_intersections):
	if item_intersections == -1 or item_intersections > 1:
		return color_can_not_place
	elif item_intersections == 1:
		return color_can_swap
	else:
		return color_can_place


func out_of_bounds(index: int, x, y):
	# check outside of y bounds
	if (index + x + (y*grid_container.columns)) >= slot_array.size():
		return true
	var right_edge: int = index + x
	# check row does not shift
	if (int(index / grid_container.columns) != int(right_edge / grid_container.columns)):
		return true
	return false


func _on_visibility_changed():
	# This is here because to prevent a dead end signal error in the inspector.
	pass
