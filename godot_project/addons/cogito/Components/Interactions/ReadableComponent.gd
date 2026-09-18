extends InteractionComponent
class_name ReadableComponent

signal has_been_read

@onready var label_title: Label = $ReadableUi/Bindings/ScrollContainer/VBoxContainer/ReadableTitle
@onready var label_content: RichTextLabel = $ReadableUi/Bindings/ScrollContainer/VBoxContainer/ReadableContent
@onready var readable_ui: Control = $ReadableUi

@export_group("Readable Settings")
@export var interact_sound : AudioStream
@export var readable_title : String
@export_multiline var readable_content : String
@export var rich_text : bool

var player: PlayerInteractionComponent

func _ready():
	readable_ui.hide()
	label_title.text = readable_title
	if rich_text:
		label_content.bbcode_enabled = true
		label_content.bbcode_text = readable_content
	else: 
		label_content.text = readable_content

func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		close(player)

func interact(_player_interaction_component: PlayerInteractionComponent):
	Audio.play_sound_3d(interact_sound).global_position = self.global_position
	
	if readable_ui.visible:
		close(_player_interaction_component)
	else:
		open(_player_interaction_component)


func open(_player: PlayerInteractionComponent):
	player = _player
	InputRouter.push(on_input)
	player.get_parent().toggled_interface.emit(true)
	player.get_parent().menu_pressed.connect(close) #Connecting input action menu to close function.
	readable_ui.show()
	has_been_read.emit()
	
	if InputHelper.device_index == -1:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close(_player: PlayerInteractionComponent):
	readable_ui.hide()
	_player.get_parent().menu_pressed.disconnect(close)
	_player.get_parent().toggled_interface.emit(false)
	InputRouter.pop()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
