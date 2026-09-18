## A serialisable Sprite3D used for invisible NPC markers
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPoint.svg")
extends Sprite3D
class_name CogitoPoint

## Represents a unique value
var uid: int = -1

func _ready() -> void:
	if uid == -1:
		uid = get_instance_id()
	self.add_to_group("Persist")


func _init(sprite_texture: Texture2D, visible_to_player: bool):
	modulate = Color(1,0,0, 1 if visible_to_player else 0)
	texture = sprite_texture
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y


func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		"uid" : uid
	}
	return node_data
