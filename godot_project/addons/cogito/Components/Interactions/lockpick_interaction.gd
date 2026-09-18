extends InteractionComponent
class_name LockpickInteraction

## Gets emitted when the lockpick interaction succeeds
signal lockpick_success

## PackedScene reference to the lockpick minigame. Uses its signals to control cancel / success / lockpick breaking.
@export var lockpick_minigame : PackedScene
## Item that is required to initialize the interaction. Will check player inventory for it.
@export var required_lockpick_item : InventoryItemPD
## Reference to doors (if not/additionally to parent)
@export var doors_to_unlock : Array[CogitoDoor]

@export_subgroup("Hint messages")
## Hint message if player has no lockpicks. Leave blank to not send one.
@export var lockpick_item_hint : String = "HINT_item_required"
## Hint message when the lockpick breaks, displays the item name first (eg. "[ITEM NAME] broke!" )
@export var lockpick_item_breaks_hint : String = "HINT_item_broke"
## Hint message when succeeding the interaction
@export var lockpick_success_hint : String = "HINT_lockpick_success"

var spawned_lockpick_game
var player_interaction_component : PlayerInteractionComponent

@onready var lockpick_ui: Control = $LockpickUI
@onready var label_amount_lockpicks: Label = $LockpickUI/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/AmountLockpicks
@onready var item_icon_texture: TextureRect = $LockpickUI/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/ItemIconTexture


func _ready() -> void:	
	# Precache lockpick minigame:
	spawned_lockpick_game = lockpick_minigame.instantiate()
	lockpick_ui.hide()
	
	if doors_to_unlock:
		for door in doors_to_unlock:
			door.lock_state_changed.connect(on_door_lock_state_change)


func interact(_player_interaction_component: PlayerInteractionComponent) -> void:
	# Check if player has lockpick item:
	if not check_for_item(_player_interaction_component, required_lockpick_item):
		if lockpick_item_hint:
			_player_interaction_component.send_hint(null, lockpick_item_hint)
		return
	
	player_interaction_component = _player_interaction_component
	player_interaction_component.get_parent().toggled_interface.emit(true)
	
	if !spawned_lockpick_game:
		spawned_lockpick_game = lockpick_minigame.instantiate()
	player_interaction_component.player.head.add_child(spawned_lockpick_game)
	
	spawned_lockpick_game.unlocked.connect(on_lock_picked)
	spawned_lockpick_game.cancelled.connect(on_cancel)
	spawned_lockpick_game.lockpick_broke.connect(discard_lockpick)
	
	# Pass player attribute if attribute check is not NONE
	if attribute_check != AttributeCheck.NONE:
		var fetched_attribute : CogitoAttribute
		fetched_attribute = player_interaction_component.player.player_attributes.get(attribute_to_check)
		spawned_lockpick_game.pass_player_attribute(fetched_attribute)
	
	# Set the UI to show the lockpick item icon and how many lockpicks the player is carrying:
	item_icon_texture.texture = required_lockpick_item.square_icon
	label_amount_lockpicks.text = str(get_lockpick_amount_in_inventory(required_lockpick_item.name))
	
	lockpick_ui.show()


func on_lock_picked() -> void:
	if lockpick_success_hint:
		player_interaction_component.send_hint(null, tr(lockpick_success_hint))
		
	lockpick_ui.hide()
	player_interaction_component.get_parent().toggled_interface.emit(false)
	
	if doors_to_unlock:
		for door in doors_to_unlock:
			door.unlock_door()

	lockpick_success.emit()
	spawned_lockpick_game.queue_free()
	player_interaction_component._rebuild_interaction_prompts()


func on_cancel() -> void:
	player_interaction_component.get_parent().toggled_interface.emit(false)
	spawned_lockpick_game.queue_free()
	lockpick_ui.hide()


func check_for_item(interactor, item) -> bool:
	var inventory = interactor.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == item:
			return true
	return false


func discard_lockpick() -> void:
	#	Lockpick Discard Logic, used when a lockpick breaks to remove one from inventory.
	var inventory = player_interaction_component.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == required_lockpick_item:
			player_interaction_component.send_hint(null, tr(required_lockpick_item.name) + " " + tr(lockpick_item_breaks_hint) )
			inventory.remove_item_from_stack(slot_data)
	
	var lockpicks_left : int = get_lockpick_amount_in_inventory(required_lockpick_item.name)
	
	# Refresh the lockpick amount display.
	label_amount_lockpicks.text = str(lockpicks_left)
	
	# Quit the minigame if the player runs out of lockpicks.
	if lockpicks_left <= 0:
		spawned_lockpick_game.exit_game()
	else:
		spawned_lockpick_game.grab_new_lockpick()


func get_lockpick_amount_in_inventory(item_name_to_check_for: String) -> int:
	var item_count : int = 0
	if player_interaction_component.get_parent().inventory_data != null:
		var inventory_to_check = player_interaction_component.get_parent().inventory_data
		for slot in inventory_to_check.inventory_slots:
			if slot != null and slot.inventory_item.name == item_name_to_check_for:
				item_count += slot.quantity
				
	return item_count


func on_door_lock_state_change(is_locked: bool) -> void:
	if is_locked:
		self.is_disabled = false
	else:
		self.is_disabled = true
