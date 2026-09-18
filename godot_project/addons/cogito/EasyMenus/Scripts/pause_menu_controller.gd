class_name CogitoPauseMenu
extends Control

## You can override this class to add buttons to your pause menu
## look at the function open_options_menu for an example of showing a submenu


# Signals
signal pause_menu_closed
signal pause_menu_opened

#region Variables
@export var nodes_to_focus: Array[Control]
@export var sound_hover : AudioStream
@export var sound_click : AudioStream
@export var empty_slot_texture : Texture

var playback : AudioStreamPlaybackPolyphonic
var temp_screenshot : Image

@onready var resume_game_button: Button = %ResumeGameButton
@onready var save_button: CogitoUiButton = %SaveButton
@onready var load_button: CogitoUiButton = %LoadButton
@onready var label_active_slot: Label = %Label_ActiveSlot
@onready var options_tab_menu: OptionsTabMenu = $Content/OptionsTabMenu
@onready var game_menu: MarginContainer = $Content/GameMenu
@onready var save_load_menu: Control = $Content/SaveLoadMenu
#endregion


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
		node.focus_entered.connect(_play_hover)
		node.pressed.connect(_play_pressed)


func _play_hover() -> void:
	playback.play_stream(sound_hover, 0, 0, 1)


func _play_pressed() -> void:
	playback.play_stream(sound_click, 0, 0, 1)


func _ready() -> void:
	#Stops game and shows pause menu
	get_tree().paused = true
	pause_menu_opened.emit()
	
	InputHelper.device_changed.connect(_on_input_device_changed)
	
	CogitoSceneManager.switch_active_slot_to(CogitoSceneManager._active_slot)
	if CogitoSceneManager._player_state:
		label_active_slot.text = tr("TXT_CURRENT_SLOT") + ": " + CogitoSceneManager._active_slot
	else:
		label_active_slot.visible = false
		
	temp_screenshot = CogitoSceneManager.grab_screenshot(CogitoGlobals.screenshot_scale)
	options_tab_menu.hide()
	update_load_related_gui()
	nodes_to_focus[0].grab_focus.call_deferred()
	
	InputRouter.push(on_input)
	if InputHelper.device_index == -1:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exit_tree() -> void:
	InputHelper.device_changed.disconnect(_on_input_device_changed)

func on_input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")):
		if options_tab_menu.visible:
			accept_event()
			options_tab_menu.hide()
			#options_tab_menu.load_options()
			CogitoGameConfig.load_options()
			CogitoSceneManager.previous_menu_button_pressed = ""
			save_load_menu.hide()
			game_menu.show()
			update_load_related_gui()
			resume_game_button.grab_focus.call_deferred()
			
		elif save_load_menu.visible:
			accept_event()
			save_load_menu.hide()
			CogitoSceneManager.previous_menu_button_pressed = ""
			game_menu.show()
			update_load_related_gui()
			resume_game_button.grab_focus.call_deferred()
			
		else:
			accept_event()
			close_pause_menu()


func update_load_related_gui():
	if CogitoSceneManager.is_loaded_from_start_new_game:
		CogitoSceneManager._active_slot = ""
		%Screenshot_Spot.texture = empty_slot_texture
		%Label_SaveTime.text = ""
		%Label_Lastsave.visible = false
		%Label_SaveTime.visible = false
	
	if CogitoSceneManager.is_loaded_from_start_new_game or CogitoSceneManager.is_saved_slots_empty() or CogitoSceneManager.is_saved_slot_exist(CogitoSceneManager._active_slot):
		%QuickLoadButton.disabled = false
	else:
		%QuickLoadButton.disabled = true
	
	if not CogitoSceneManager.is_saved_slots_empty():
		load_button.disabled = false
		if load_current_slot_data(): # If slot save data found
			label_active_slot.visible = true
		else:
			label_active_slot.visible = false
			%Label_SaveTime.text = ""
			%Label_Lastsave.visible = false
			%Label_SaveTime.visible = false
	else:
		%Screenshot_Spot.texture = empty_slot_texture
		%Label_SaveTime.text = ""
		%Label_Lastsave.visible = false
		%Label_SaveTime.visible = false
		load_button.disabled = true
		label_active_slot.visible = false


func load_slot_data():
	label_active_slot.text = tr("TXT_CURRENT_SLOT") + ": " + CogitoSceneManager._active_slot
	
	update_load_related_gui()
	
	resume_game_button.grab_focus.call_deferred()


func open_options_menu():
	options_tab_menu.show()
	#options_tab_menu.load_options(true)
	CogitoGameConfig.load_options()
	options_tab_menu.have_options_changed = false
	
	var current_tab: int = options_tab_menu.tab_container.current_tab
	if current_tab != options_tab_menu.tab_container.tab_index_of_bindings:
		options_tab_menu.tab_container.nodes_to_focus[current_tab].grab_focus.call_deferred()
	else:
		var temp_button = options_tab_menu.tab_container.find_input_bind_focus_node()
		if temp_button:
			CogitoGlobals.debug_log(true, "pause_menu_controller.gd", "Grabbing focus on " + str(temp_button) + " with action " + temp_button.action)
			temp_button.grab_focus.call_deferred()
	
	game_menu.hide()


func load_current_slot_data() -> bool:
	# Load screenshot
	var image_path : String = CogitoSceneManager.get_active_slot_player_state_screenshot_path()
	if image_path != "":
		var image : Image = Image.load_from_file(image_path)
		var texture = ImageTexture.create_from_image(image)
		%Screenshot_Spot.texture = texture
	else:
		%Screenshot_Spot.texture = empty_slot_texture
		%Label_Lastsave.visible = false
		%Label_SaveTime.visible = false
		CogitoGlobals.debug_log(true,"pause_menu_controller.gd", "No screenshot for slot " + CogitoSceneManager._active_slot + " found.")
		return false
		
	# Load save state time
	var savetime : int
	if CogitoSceneManager._player_state:
		savetime = CogitoSceneManager._player_state.player_state_savetime
	if savetime == null or typeof(savetime) != TYPE_INT or savetime == 0:
		%Label_Lastsave.visible = false
		%Label_SaveTime.visible = false
		return false
	else:
		var timeoffset = Time.get_time_zone_from_system().bias*60
		var save_time_string = Time.get_datetime_string_from_unix_time(savetime+timeoffset,true)
		%Label_Lastsave.visible = true
		%Label_SaveTime.visible = true
		%Label_SaveTime.text = save_time_string
		return true


func close_pause_menu():
	get_tree().paused = false
	InputRouter.pop()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_menu_closed.emit()
	queue_free()


func _on_resume_game_button_pressed():
	close_pause_menu()


func _on_quit_button_pressed():
	CogitoSceneManager.delete_temp_saves()
	get_tree().quit()


func _on_save_button_pressed() -> void:
	CogitoSceneManager._screenshot_to_save = temp_screenshot
	save_load_menu.initialize()
	save_load_menu.show()
	save_load_menu.focus_slot_on_save()
	game_menu.hide()
	CogitoSceneManager.previous_menu = "pause_menu"
	CogitoSceneManager.previous_menu_button_pressed = "save"
	CogitoSceneManager.pause_menu = self
	CogitoSceneManager.save_load_menu = save_load_menu
	CogitoSceneManager.game_menu = game_menu


func _on_load_button_pressed() -> void:
	CogitoGlobals.debug_log(true,"pause_menu_controller.gd","LOAD button pressed.")
	save_load_menu.initialize()
	save_load_menu.show()
	save_load_menu.focus_slot_on_load()
	game_menu.hide()
	CogitoSceneManager.previous_menu = "pause_menu"
	CogitoSceneManager.previous_menu_button_pressed = "load"
	CogitoSceneManager.pause_menu = self
	CogitoSceneManager.save_load_menu = save_load_menu
	CogitoSceneManager.game_menu = game_menu


func _on_quickload_button_pressed() -> void:
	CogitoGlobals.debug_log(true,"pause_menu_controller.gd","QUICK LOAD button pressed.")
	if CogitoSceneManager.is_loaded_from_start_new_game or CogitoSceneManager.is_saved_slots_empty():
		start_new_game()
		return
	
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.delete_temp_saves()
	CogitoSceneManager.copy_slot_saves_to_temp(CogitoSceneManager._active_slot)
	#CogitoSceneManager.loading_saved_game(CogitoSceneManager._active_slot)
	
	_on_resume_game_button_pressed()


func start_new_game():
	if CogitoGlobals.cogito_settings.new_game_start_scene:
		CogitoSceneManager.is_starting_new_game = true
		CogitoSceneManager.delete_temp_saves()
		var path_to_scene = CogitoGlobals.cogito_settings.new_game_start_scene.resource_path
		CogitoSceneManager.load_next_scene(path_to_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
		#Setting new game world state:
		CogitoSceneManager._current_world_dict = CogitoGlobals.cogito_settings.new_game_world_state.get_world_dict()
		get_tree().paused = false
	#if start_game_scene: 
		#CogitoSceneManager.load_next_scene(start_game_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
	else:
		CogitoGlobals.debug_log(true, "CogitoPauseManu", "ISSUE: No start game scene set.")


func _on_back_to_main_menu_pressed() -> void:
	if CogitoGlobals.cogito_settings.main_menu_scene:
		CogitoSceneManager.delete_temp_saves()
		var path_to_scene = CogitoGlobals.cogito_settings.main_menu_scene.resource_path
		
		# Cleanup
		get_tree().paused = false
		InputRouter.pop()
		
		CogitoSceneManager.load_next_scene(path_to_scene, "", "temp", CogitoSceneManager.CogitoSceneLoadMode.RESET) #Load_mode 2 means there's no attempt to load a state.
	else:
		CogitoGlobals.debug_log(true, "CogitoPauseMenu", "ISSUE: No main menu scene set.")

func _on_input_device_changed(device: String, device_index: int) -> void:
	Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE if device_index < 0 else Input.MouseMode.MOUSE_MODE_CAPTURED
