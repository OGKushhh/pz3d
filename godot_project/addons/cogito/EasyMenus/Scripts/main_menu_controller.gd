class_name CogitoMainMenuController
extends Control
signal start_game_pressed

@export var first_focus_button: Button
@export var credits_packed_scene : PackedScene
@onready var v_box_container_title: VBoxContainer = %VBoxContainerTitle
@onready var game_menu: MarginContainer = $ContentMain/GameMenu
@onready var options_tab_menu: OptionsTabMenu = $ContentMain/OptionsTabMenu
@onready var options_button: CogitoUiButton = $ContentMain/GameMenu/VBoxContainer/MarginContainer4/OptionsButton
@onready var save_load_menu: Control = $ContentMain/SaveLoadMenu

var sub_menu : Node
var is_sub_menu_open : bool = false
var previously_focused_button : Button = null

#region UI AUDIO
@export var sound_hover : AudioStream
@export var sound_click : AudioStream
var playback : AudioStreamPlaybackPolyphonic


func _enter_tree() -> void:
	# Create an audio player
	var player = AudioStreamPlayer.new()
	add_child(player)

	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	player.stream = stream
	player.play()
	# Get the polyphonic playback stream to play sounds
	playback = player.get_stream_playback()

	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node:Node) -> void:
	if node is Button:
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.mouse_entered.connect(_play_hover)
		node.pressed.connect(_play_pressed)


func _play_hover() -> void:
	playback.play_stream(sound_hover, 0, 0, 1)


func _play_pressed() -> void:
	playback.play_stream(sound_click, 0, 0, 1)
#endregion


func _ready():
	var last_saved_slot: String = CogitoSceneManager.get_last_saved_slot()
	if last_saved_slot:
		%Continue.disabled = false
		
	if not first_focus_button.disabled:
		first_focus_button.grab_focus()
	else:
		%NewGame.grab_focus()


func quit():
	get_tree().quit()


func _input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")) and !game_menu.visible:
		accept_event()
		if is_sub_menu_open:
			return
		
		options_tab_menu.hide()
		CogitoGameConfig.load_options()
		v_box_container_title.show()
		CogitoSceneManager.previous_menu_button_pressed = ""
		save_load_menu.hide()
		game_menu.show()
		options_button.grab_focus.call_deferred()
	
		var last_saved_slot: String = CogitoSceneManager.get_last_saved_slot()
		if last_saved_slot:
			%Continue.disabled = false
		else:
			%Continue.disabled = true


func open_options_menu():
	options_tab_menu.show()
	
	var current_tab: int = options_tab_menu.tab_container.current_tab
	if current_tab != options_tab_menu.tab_container.tab_index_of_bindings:
		options_tab_menu.tab_container.nodes_to_focus[current_tab].grab_focus.call_deferred()
	else:
		var temp_button = options_tab_menu.tab_container.find_input_bind_focus_node()
		if temp_button:
			CogitoGlobals.debug_log(true, "main_menu_controller.gd", "Grabbing focus on " + str(temp_button) + " with action " + temp_button.action)
			temp_button.grab_focus.call_deferred()
	
	game_menu.hide()


func _open_sub_menu(credits_scene : PackedScene) -> Node:
	# Store button the focus was on before submenu.
	previously_focused_button = get_viewport().gui_get_focus_owner() 
	
	is_sub_menu_open = true
	sub_menu = credits_scene.instantiate()
	add_child(sub_menu)
	v_box_container_title.hide()
	game_menu.hide()
	
	if sub_menu and sub_menu.has_signal("closed"):
		sub_menu.closed.connect(_close_sub_menu)
	
	sub_menu.hidden.connect(_close_sub_menu, CONNECT_ONE_SHOT)
	sub_menu.tree_exiting.connect(_close_sub_menu, CONNECT_ONE_SHOT)
	return sub_menu


func _close_sub_menu() -> void:
	is_sub_menu_open = false
	if sub_menu == null:
		return
	sub_menu.queue_free()
	sub_menu = null
	await get_tree().create_timer(0.25).timeout
	v_box_container_title.show()
	game_menu.show()
	# When using gamepad, set focus back to previously focused button:
	if InputHelper.device_index != -1:
		if previously_focused_button : previously_focused_button.grab_focus()


func _on_start_game_button_pressed():
	emit_signal("start_game_pressed")


func _on_credits_button_pressed() -> void:
	_open_sub_menu(credits_packed_scene)


func _on_main_menu_new_game_pressed() -> void:
	start_new_game()


func start_new_game():
	if CogitoGlobals.cogito_settings.new_game_start_scene:
		CogitoSceneManager.is_loaded_from_start_new_game = true
		CogitoSceneManager.is_starting_new_game = true
		var path_to_scene = CogitoGlobals.cogito_settings.new_game_start_scene.resource_path
		CogitoSceneManager.load_next_scene(path_to_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
		#Setting new game world state:
		CogitoSceneManager._current_world_dict = CogitoGlobals.cogito_settings.new_game_world_state.get_world_dict()
	#if start_game_scene: 
		#CogitoSceneManager.load_next_scene(start_game_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
	else:
		print("ISSUE: No start game scene set.")


func open_save_load_menu() -> void:
	save_load_menu.initialize()
	save_load_menu.show()
	save_load_menu.focus_slot_on_load()
	game_menu.hide()


func _on_main_menu_continue_pressed() -> void:
	var last_saved_slot: String = CogitoSceneManager.get_last_saved_slot()
	
	CogitoSceneManager.switch_active_slot_to(last_saved_slot)
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.delete_temp_saves()
	CogitoSceneManager.copy_slot_saves_to_temp(last_saved_slot)
	CogitoSceneManager._active_slot = last_saved_slot
