@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoWieldable.svg")
extends Node3D
class_name CogitoWieldable

@export_group("General Wieldable Settings")
## Item resource that this wieldable refers to.
var item_reference : WieldableItemPD
## Visible parts of the wieldable. Used to hide/show on equip/unequip.
@export var wieldable_mesh : Node3D
## Which ammo type the Wieldable is currently using. Set by the WieldableItemPD
@export var current_ammo_type : int = 0
@export var audio_stream_player_3d: AudioStreamPlayer3D
@export var show_debug: bool = false

@export_group("Animations")
@export var animation_player: AnimationPlayer
@export var anim_equip: String = "equip"
@export var anim_unequip: String = "unequip"
@export var anim_action_primary: String = "action_primary"
@export var anim_action_secondary: String = "action_secondary"
@export var anim_reload: String = "reload"

var player_interaction_component : PlayerInteractionComponent

### Every wieldable needs the following functions:
### equip(_player_interaction_component), unequip(), action_primary(), action_secondary(), reload()

func _ready():
	if !audio_stream_player_3d:
		var players: Array[Node] = find_children("", "AudioStreamPlayer3D")
		if len(players): audio_stream_player_3d = players[0]
	
	if !animation_player:
		var anim_players: Array[Node] = find_children("", "AnimationPlayer")
		if len(anim_players): animation_player = anim_players[0]
		
	if wieldable_mesh:
		wieldable_mesh.hide()


# Function called when wieldable is unequipped.
func equip(_player_interaction_component: PlayerInteractionComponent):
	animation_player.play(anim_equip)
	player_interaction_component = _player_interaction_component


# Function called when wieldable is unequipped.
func unequip():
	animation_player.play(anim_unequip)


# Primary action called by the Player Interaction Component when wieldable is wielded.
func action_primary(_passed_item_reference:InventoryItemPD, _is_released: bool):
	pass


# Secondary action called by the Player Interaction Component when wieldable is wielded.
func action_secondary(_is_released: bool):
	pass


# Function called when wieldable reload is attempted
func reload() -> bool:
	var player: CogitoPlayer = player_interaction_component.player if player_interaction_component else CogitoSceneManager._current_player_node
	var inventory: CogitoInventory = player.inventory_data
	# Some safety checks if reload should even be triggered.
	if inventory == null:
		CogitoGlobals.debug_log(true,"CogitoWieldable", "Could not get reference to player inventory!")
		return false

	if animation_player.is_playing():
		CogitoGlobals.debug_log(true,"CogitoWieldable", "Cannot reload during animation")
		return false

	# If the item doesn't use reloading, return.
	if item_reference.no_reload:
		CogitoGlobals.debug_log(true,"CogitoWieldable", "This wieldable does not do reloading!")
		return false

	var ammo_needed: int = abs(item_reference.charge_max - item_reference.charge_current)
	if ammo_needed <= 0:
		CogitoGlobals.debug_log(true,"CogitoWieldable", "Wieldable is already fully loaded")
		return false

	if item_reference.get_item_amount_in_inventory(item_reference.get_current_ammo()) <= 0:
		CogitoGlobals.debug_log(true,"CogitoWieldable", "You have no ammo for this wieldable.")
		return false

	for slot: InventorySlotPD in inventory.inventory_slots:
		if ammo_needed <= 0:
			break
		if slot == null or slot.inventory_item.name != item_reference.get_current_ammo().name:
			continue

		var ammo_used: int
		var slot_ammo: AmmoItemPD = slot.inventory_item
		var quantity_needed: int = ceili(float(ammo_needed) / slot_ammo.reload_amount)

		if slot.quantity <= quantity_needed:
			ammo_used = slot_ammo.reload_amount * slot.quantity
			inventory.remove_slot_data(slot)
		elif slot.quantity > quantity_needed:
			ammo_used = slot_ammo.reload_amount * quantity_needed
			slot.quantity -= quantity_needed

		item_reference.add(ammo_used)
		ammo_needed -= ammo_used

	inventory.inventory_updated.emit(inventory)
	item_reference.update_wieldable_data(player_interaction_component)
	return true

# Function called when wieldable ammo change is attempted
func change_ammo():
	pass
	
func set_ammo_type(index: int) -> void:
	pass
	
# Override this with your debug stats
func debug(id, data):
	if player_interaction_component:
		player_interaction_component.player.debug(id, data)
