class_name SlotPanel extends PanelContainer

@export var sound_highlight : AudioStream
@onready var selection_panel = $Selected

func get_item() -> InventoryItemPD:
	return


func set_slot_data(slot_data: InventorySlotPD, index: int, moving: bool, x_size: int):
	pass
