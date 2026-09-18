class_name InventorySlot extends SlotPanel

@onready var icon_texture = $MarginContainer/Icon
@onready var quantity_label = $QuantityLabel
@onready var charge_label = $ChargeLabel
@onready var highlight_panel = $Highlight
@onready var slot_border = $SlotBorder

## Displays a grid around adjacent slots when checking for space
@export var enable_border_highlight:bool = true
## Changes the whole slot colour when checking for space
@export var enable_fill_colour:bool = true
## Displays a small border inside the slot to give a grid appearance
@export var enable_grid_texture:bool
@export var highlight_color : Color
## AudioStream that plays when slot gets highlighted.

var item_data: InventoryItemPD = null
var origin_index : int = -1
var grid : bool
var ammo_slot : bool
var quantity_slot : bool

signal slot_clicked(index: int, mouse_button: int)
signal slot_pressed(index: int, action: String)
signal highlight_slot(index: int, highlight: bool)

func get_item() -> InventoryItemPD:
	return item_data


func using_grid(using_grid: bool):
	slot_border.set_visible(enable_grid_texture)
	grid = using_grid


func set_icon_region(x, y):
	var region = item_data.get_region(x, y)
	icon_texture.texture = ImageTexture.create_from_image(region)


func set_hotbar_icon():
	icon_texture.texture = item_data.rotated_texture if item_data.rotated else item_data.icon


func set_slot_data(slot_data: InventorySlotPD, index: int, moving: bool, x_size: int):
	item_data = slot_data.inventory_item
	if moving:
		slot_data.origin_index = index
		origin_index = index
	else:
		origin_index = slot_data.origin_index
	
	# Set quantity and ammo slots if they sit in the top right or bottom right of the grid
	check_if_top_right_slot(slot_data, index)
	check_if_bottom_right_slot(slot_data, index, x_size)
	
	if slot_data.quantity > 1 and quantity_slot:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()
		
	# Check if item is a WIELDABLE
	if item_data.has_signal("charge_changed") and not item_data.no_reload and ammo_slot:
		charge_label.text = str(int(item_data.charge_current))
		if !item_data.charge_changed.is_connected(_on_charge_changed):
			item_data.charge_changed.connect(_on_charge_changed)
		charge_label.show()
	else:
		if item_data.has_signal("charge_changed") and item_data.charge_changed.is_connected(_on_charge_changed):
			item_data.charge_changed.disconnect(_on_charge_changed)
		charge_label.hide()


func check_if_top_right_slot(slot_data: InventorySlotPD, index: int):
	if not item_data:
		return
	if index == slot_data.origin_index + item_data.item_size.x-1:
		quantity_slot = true


func check_if_bottom_right_slot(slot_data: InventorySlotPD, index: int, x_size: int):
	if not item_data:
		return
	if index == slot_data.origin_index + item_data.item_size.x-1 + ((item_data.item_size.y-1)*x_size):
		ammo_slot = true


func _on_charge_changed():
	if item_data.has_signal("charge_changed"): #Making sure this is a wieldable.
		charge_label.text = str(int(item_data.charge_current)) 


func _on_gui_input(event: InputEvent):
	# Setting SLOT GAMPEAD INTERACTIONS HERE
	if event.is_action_pressed("inventory_move_item"):
		slot_pressed.emit(get_index(), "inventory_move_item")
		highlight_slot.emit(get_index(), true)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("inventory_use_item"):
		print("Slot.gd: inventory_use_item pressed on slot ", get_index())
		slot_pressed.emit(get_index(), "inventory_use_item")
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("inventory_drop_item"):
		slot_pressed.emit(get_index(), "inventory_drop_item")
		highlight_slot.emit(get_index(), false)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("inventory_assign_item"):
		slot_pressed.emit(get_index(), "inventory_assign_item")
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("interact") or event.is_action_pressed("interact2"):
		get_viewport().set_input_as_handled()


func set_grabbed_dimensions():
	var item_size = item_data.item_size if grid else Vector2i(1,1)
	size = Vector2i(64 * item_size.x, 64 * item_size.y)
	set_hotbar_icon()

## Rotate the item by flipping its item size x,y and rotate the icon texture 90 degrees.
## Rotating again will revert the state back to its original form.
func rotate():
	item_data.rotate()
	set_grabbed_dimensions()

func set_selection(is_selected : bool):
	print(name, ": set_selection called. selection panel should be visible. (is_selected = ", is_selected, ")")
	selection_panel.visible = is_selected

## Called when checking space availability of neighbouring slots to change the slot colour
func change_slot_colour(colour):
	selection_panel.modulate = colour
	if !enable_border_highlight:
		selection_panel.set_visible(false)
	if enable_fill_colour:
		highlight_panel.modulate = Color(colour.r, colour.g, colour.b, 0.1)

# Hide the slot border (if using) for grabbed items so it doesn't look weird	
func hide_slot_border():
	$SlotBorder.set_visible(false)

func _on_mouse_entered():
	grab_focus()

func _on_mouse_exited():
	release_focus()

func _on_hidden():
	release_focus()

func _on_focus_entered() -> void:
	highlight_panel.modulate = Color(255, 255, 255, 0.1)
	Audio.play_sound(sound_highlight)
	highlight_slot.emit(get_index(), true)
	highlight_panel.show()

func _on_focus_exited() -> void:
	highlight_panel.modulate = Color(255, 255, 255, 0.1)
	highlight_slot.emit(get_index(), false)
	highlight_panel.hide()
