extends Resource
class_name InventoryItemPD

## Name of Item as it appears in game.
@export var name : String = ""
## Description of Item as it'll appear in the HUD / Inventory menu
@export_multiline var description : String = ""
## Icon of Item for HUD / Inventory
@export var icon : Texture2D
## Sets if an item can be stackable or not. Usually used for consumables or ammo.
@export var is_stackable : bool = false
## Sets if an item can be dropped or not. Used for important items so they can't get lost. Items can still be moved to external inventories.
@export var is_droppable : bool = true
## LootComponent - Sets the item as a unique. Meaning there can be only one copy in player inventory and all the loot bags.
@export var is_unique : bool = false
@export_range(1, 99) var stack_size : int
## Path to Scene that will be spawned when item is removed from inventory to be dropped into the world.
@export_file("*.tscn") var drop_scene
## Physical size as a spherical radius - used to account for the space an item takes up when being dropped in the world. (e.g. an item thats 1m long should have a drop size of .5 as that checks for a sphere with 1m diameter.
@export var item_drop_size : float = 0.5
## Icon that is displayed with the hint that pops up when used. If left blank, the default hint icon is shown.
@export var hint_icon_on_use : Texture2D
## Hint that is displayed when used. For example "Potion replenished 10 HP!"
@export var hint_text_on_use : String
@export var item_size : Vector2i = Vector2i(1,1)

@export_subgroup("Audio")
## Audio that plays when item is used.
@export var sound_use : AudioStream
@export var sound_pickup : AudioStream
@export var sound_drop : AudioStream

@export_category("Auto Quickslot Settings")
## When set to true, this item will be automatically bound to an empty quickslot on pickup.
@export var can_auto_slot: bool = false
## Quickslot number this item will be  bound to on pickup.
@export var slot_number: int = -1

# Variables for Wielded Items
var player_interaction_component : PlayerInteractionComponent
var is_being_wielded : bool
var wielded_item 

## Item rotation variables
@export var rotated: bool = false
var rotated_texture: Texture2D:
	get: return rotated_texture if rotated_texture else set_rotated_icon()

var square_icon: Texture2D:
	get: return get_square_icon()
var cached_sq_icon: Texture2D

func get_square_icon() -> Texture2D:
	if cached_sq_icon:
		return cached_sq_icon
	# Get the difference in pixels between the height and the width and check if its wider
	var width_diff = icon.get_width() - icon.get_height()
	var wider = width_diff > 0 
	# Get the buffer by halving the diff, then define offset based on if its wider or taller
	var buffer := int(abs(width_diff) / 2)
	var offset := Vector2i(0 if wider else buffer, buffer if wider else 0)
	# Create an empty square image, then copy the icon onto it with the offset
	var square_dim = icon.get_width() if wider else icon.get_height()
	var square_image = Image.create_empty(square_dim, square_dim, false, Image.FORMAT_RGBA8)
	square_image.blit_rect(icon.get_image(), Rect2i(Vector2i.ZERO, icon.get_size()), offset)
	# Cache the icon, and you're done!
	cached_sq_icon = ImageTexture.create_from_image(square_image)
	return cached_sq_icon

func set_rotated_icon() -> Texture2D:
	var rotated_image = icon.get_image()
	rotated_image.rotate_90(CLOCKWISE if rotated else COUNTERCLOCKWISE)
	rotated_texture = ImageTexture.create_from_image(rotated_image)
	return rotated_texture

func rotate():
	rotated = !rotated
	item_size = Vector2i(item_size.y, item_size.x) # why does godot not have orthogonal for vec2is????
	set_rotated_icon()

func get_region(x, y) -> Image:
	var image: Image = rotated_texture.get_image() if rotated else icon.get_image()
	var x_chunk = image.get_width() / item_size.x
	var y_chunk = image.get_height() / item_size.y
	var region = Rect2i(Vector2i(x * x_chunk, y * y_chunk), Vector2i(x_chunk, y_chunk))
	return image.get_region(region)
