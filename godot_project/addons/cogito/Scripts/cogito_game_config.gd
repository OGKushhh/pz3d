extends Node
signal options_updated
signal options_have_changed
signal options_loaded(skip_applying:bool)
signal windowed_resolution_has_changed
signal options_saved

### Game Config File
var config = ConfigFile.new()
var have_cfg : bool

# GAMEPLAY
var invert_y: bool
var toggle_crouching: bool
var gp_looksens: float
var mouse_sens: float
var headbob_strength: int

var HEADBOB_DICTIONARY: Dictionary = {
	"1": 1,
	"3": 3,
	"7": 7,
}

# AUDIO
var sfx_bus_index
var music_bus_index
var sfx_volume
var music_volume

# GRAPHICS
var windowed_resolution: Vector2i
var prev_windowed_resolution: Vector2i
var fullscreen_mode: bool
var fullscreen_resolution_scale_val := 1.0
var gui_scale: float
var resolutions_min_y := 540.0
var current_resolution_index
var resolution_index
var vsync: bool

var msaa_2d: int
var msaa_3d: int

const window_operations_delay = 0.25
const max_gui_scale_ratio = 1.00

var RESOLUTION_DICTIONARY: Dictionary = {
	"800x600 (4:3)": Vector2i(800, 600),
	"960x540 (16:9)": Vector2i(960, 540),
	"1024x576 (16:9)": Vector2i(1024, 576),
	"1024x640 (16:10)": Vector2i(1024, 640),
	"1024x768 (4:3)": Vector2i(1024, 768),
	"1152x648 (16:9)": Vector2i(1152, 648),
	"1280x720 (16:9)": Vector2i(1280, 720),
	"1280x800 (16:10)": Vector2i(1280, 800),
	"1366x768 (16:9)": Vector2i(1366, 768),
	"1440x900 (16:10)": Vector2i(1440, 900),
	"1600x1200 (4:3)": Vector2i(1600, 1200),
	"1600x900 (16:9)": Vector2i(1600, 900),
	"1680x720 (21:9)": Vector2i(1680, 720),
	"1920x1080 (16:9)": Vector2i(1920, 1080),
	"1920x1200 (16:10)": Vector2i(1920, 1200),
	"2560x1080 (21:9)": Vector2i(2560, 1080),
	"2560x1440 (16:9)": Vector2i(2560, 1440),
	"3440x1440 (21:9)": Vector2i(3440, 1440),
	"3840x2160 (16:9)": Vector2i(3840, 2160),
}

# INPUT BINDING
@export var rebind_dictionary: Dictionary

var input_actions = {
	"separator_movement": "SEPARATOR_MOVEMENT",
	"forward": "INPUT_move_forward",
	"back": "INPUT_move_backward",
	"left": "INPUT_move_left",
	"right": "INPUT_move_right",
	"jump": "INPUT_jump",
	"crouch": "INPUT_crouch",
	"separator_actions": "SEPARATOR_ACTIONS",
	"action_primary": "INPUT_primary_action",
	"action_secondary": "INPUT_secondary_action",
	"interact": "INPUT_interact_1",
	"interact2": "INPUT_interact_2",
	"reload": "INPUT_reload",
	"change_ammo_type": "INPUT_change_ammo_type",
	"quickslot_1": "INPUT_quickslot_1",
	"quickslot_2": "INPUT_quickslot_2",
	"quickslot_3": "INPUT_quickslot_3",
	"quickslot_4": "INPUT_quickslot_4",
	"quickslot_prev_wieldable": "INPUT_quickslot_prev",
	"quickslot_next_wieldable": "INPUT_quickslot_next",
	"separator_inventory": "SEPARATOR_MENUES",
	"menu": "INPUT_pause",
	"inventory": "INPUT_inventory",
	"inventory_use_item": "INPUT_item_use",
	"inventory_move_item": "INPUT_item_move",
	"inventory_drop_item": "INPUT_item_quick_drop",
	"inventory_rotate_item": "INPUT_item_rotate",
}

const serialized_default_inputs: String = "{\"action_primary\":{\"joypad\":[\"5|0.345098\"],\"keyboard\":[],\"mouse\":[1]},\"action_secondary\":{\"joypad\":[\"4|0.223529\"],\"keyboard\":[],\"mouse\":[2]},\"back\":{\"joypad\":[\"1|0.207062\"],\"keyboard\":[\"S\"],\"mouse\":[]},\"crouch\":{\"joypad\":[1],\"keyboard\":[\"C\"],\"mouse\":[]},\"forward\":{\"joypad\":[\"1|-0.225074\"],\"keyboard\":[\"W\"],\"mouse\":[]},\"free_look\":{\"joypad\":[],\"keyboard\":[\"CapsLock\"],\"mouse\":[]},\"interact\":{\"joypad\":[2],\"keyboard\":[\"F\"],\"mouse\":[]},\"interact2\":{\"joypad\":[3],\"keyboard\":[\"E\"],\"mouse\":[]},\"inventory\":{\"joypad\":[4],\"keyboard\":[\"Tab\"],\"mouse\":[]},\"inventory_drop_item\":{\"joypad\":[3],\"keyboard\":[\"G\"],\"mouse\":[]},\"inventory_move_item\":{\"joypad\":[0],\"keyboard\":[],\"mouse\":[1]},\"inventory_use_item\":{\"joypad\":[1],\"keyboard\":[],\"mouse\":[2]},\"jump\":{\"joypad\":[0],\"keyboard\":[\"Space\"],\"mouse\":[]},\"left\":{\"joypad\":[\"0|-0.172882\"],\"keyboard\":[\"A\"],\"mouse\":[]},\"menu\":{\"joypad\":[6],\"keyboard\":[\"Escape\"],\"mouse\":[]},\"quickslot_1\":{\"joypad\":[13],\"keyboard\":[\"1\"],\"mouse\":[]},\"quickslot_2\":{\"joypad\":[11],\"keyboard\":[\"2\"],\"mouse\":[]},\"quickslot_3\":{\"joypad\":[14],\"keyboard\":[\"3\"],\"mouse\":[]},\"quickslot_4\":{\"joypad\":[12],\"keyboard\":[\"4\"],\"mouse\":[]},\"reload\":{\"joypad\":[2],\"keyboard\":[\"R\"],\"mouse\":[]},\"right\":{\"joypad\":[\"0|0.136204\"],\"keyboard\":[\"D\"],\"mouse\":[]},\"sprint\":{\"joypad\":[7],\"keyboard\":[\"Shift\"],\"mouse\":[]},\"ui_accept\":{\"joypad\":[0],\"keyboard\":[\"Enter\",\"Kp Enter\",\"Space\"],\"mouse\":[]},\"ui_cancel\":{\"joypad\":[1],\"keyboard\":[\"Escape\"],\"mouse\":[]},\"ui_copy\":{\"joypad\":[],\"keyboard\":[\"C|ctrl\",\"Insert|ctrl\"],\"mouse\":[]},\"ui_cut\":{\"joypad\":[],\"keyboard\":[\"X|ctrl\",\"Delete|shift\"],\"mouse\":[]},\"ui_down\":{\"joypad\":[12,\"1|1.000000\"],\"keyboard\":[\"Down\"],\"mouse\":[]},\"ui_end\":{\"joypad\":[],\"keyboard\":[\"End\"],\"mouse\":[]},\"ui_filedialog_refresh\":{\"joypad\":[],\"keyboard\":[\"F5\"],\"mouse\":[]},\"ui_filedialog_show_hidden\":{\"joypad\":[],\"keyboard\":[\"H\"],\"mouse\":[]},\"ui_filedialog_up_one_level\":{\"joypad\":[],\"keyboard\":[\"Backspace\"],\"mouse\":[]},\"ui_focus_next\":{\"joypad\":[],\"keyboard\":[\"Tab\"],\"mouse\":[]},\"ui_focus_prev\":{\"joypad\":[],\"keyboard\":[\"Tab|shift\"],\"mouse\":[]},\"ui_graph_delete\":{\"joypad\":[],\"keyboard\":[\"Delete\"],\"mouse\":[]},\"ui_graph_duplicate\":{\"joypad\":[],\"keyboard\":[\"D|ctrl\"],\"mouse\":[]},\"ui_home\":{\"joypad\":[],\"keyboard\":[\"Home\"],\"mouse\":[]},\"ui_left\":{\"joypad\":[13,\"0|-1.000000\"],\"keyboard\":[\"Left\"],\"mouse\":[]},\"ui_menu\":{\"joypad\":[],\"keyboard\":[\"Menu\"],\"mouse\":[]},\"ui_next_tab\":{\"joypad\":[10],\"keyboard\":[\"E\"],\"mouse\":[]},\"ui_page_down\":{\"joypad\":[],\"keyboard\":[\"PageDown\"],\"mouse\":[]},\"ui_page_up\":{\"joypad\":[],\"keyboard\":[\"PageUp\"],\"mouse\":[]},\"ui_paste\":{\"joypad\":[],\"keyboard\":[\"V|ctrl\",\"Insert|shift\"],\"mouse\":[]},\"ui_prev_tab\":{\"joypad\":[9],\"keyboard\":[\"Q\"],\"mouse\":[]},\"ui_redo\":{\"joypad\":[],\"keyboard\":[\"Z|shift,ctrl\",\"Y|ctrl\"],\"mouse\":[]},\"ui_right\":{\"joypad\":[14,\"0|1.000000\"],\"keyboard\":[\"Right\"],\"mouse\":[]},\"ui_select\":{\"joypad\":[3],\"keyboard\":[\"Space\"],\"mouse\":[]},\"ui_swap_input_direction\":{\"joypad\":[],\"keyboard\":[\"QuoteLeft|ctrl\"],\"mouse\":[]},\"ui_text_add_selection_for_next_occurrence\":{\"joypad\":[],\"keyboard\":[\"D|ctrl\"],\"mouse\":[]},\"ui_text_backspace\":{\"joypad\":[],\"keyboard\":[\"Backspace\",\"Backspace|shift\"],\"mouse\":[]},\"ui_text_backspace_all_to_left\":{\"joypad\":[],\"keyboard\":[],\"mouse\":[]},\"ui_text_backspace_all_to_left.macos\":{\"joypad\":[],\"keyboard\":[\"Backspace|ctrl\"],\"mouse\":[]},\"ui_text_backspace_word\":{\"joypad\":[],\"keyboard\":[\"Backspace|ctrl\"],\"mouse\":[]},\"ui_text_backspace_word.macos\":{\"joypad\":[],\"keyboard\":[\"Backspace|alt\"],\"mouse\":[]},\"ui_text_caret_add_above\":{\"joypad\":[],\"keyboard\":[\"Up|shift,ctrl\"],\"mouse\":[]},\"ui_text_caret_add_above.macos\":{\"joypad\":[],\"keyboard\":[\"O|shift,ctrl\"],\"mouse\":[]},\"ui_text_caret_add_below\":{\"joypad\":[],\"keyboard\":[\"Down|shift,ctrl\"],\"mouse\":[]},\"ui_text_caret_add_below.macos\":{\"joypad\":[],\"keyboard\":[\"L|shift,ctrl\"],\"mouse\":[]},\"ui_text_caret_document_end\":{\"joypad\":[],\"keyboard\":[\"End|ctrl\"],\"mouse\":[]},\"ui_text_caret_document_end.macos\":{\"joypad\":[],\"keyboard\":[\"Down|ctrl\",\"End|ctrl\"],\"mouse\":[]},\"ui_text_caret_document_start\":{\"joypad\":[],\"keyboard\":[\"Home|ctrl\"],\"mouse\":[]},\"ui_text_caret_document_start.macos\":{\"joypad\":[],\"keyboard\":[\"Up|ctrl\",\"Home|ctrl\"],\"mouse\":[]},\"ui_text_caret_down\":{\"joypad\":[],\"keyboard\":[\"Down\"],\"mouse\":[]},\"ui_text_caret_left\":{\"joypad\":[],\"keyboard\":[\"Left\"],\"mouse\":[]},\"ui_text_caret_line_end\":{\"joypad\":[],\"keyboard\":[\"End\"],\"mouse\":[]},\"ui_text_caret_line_end.macos\":{\"joypad\":[],\"keyboard\":[\"E|ctrl\",\"Right|ctrl\",\"End\"],\"mouse\":[]},\"ui_text_caret_line_start\":{\"joypad\":[],\"keyboard\":[\"Home\"],\"mouse\":[]},\"ui_text_caret_line_start.macos\":{\"joypad\":[],\"keyboard\":[\"A|ctrl\",\"Left|ctrl\",\"Home\"],\"mouse\":[]},\"ui_text_caret_page_down\":{\"joypad\":[],\"keyboard\":[\"PageDown\"],\"mouse\":[]},\"ui_text_caret_page_up\":{\"joypad\":[],\"keyboard\":[\"PageUp\"],\"mouse\":[]},\"ui_text_caret_right\":{\"joypad\":[],\"keyboard\":[\"Right\"],\"mouse\":[]},\"ui_text_caret_up\":{\"joypad\":[],\"keyboard\":[\"Up\"],\"mouse\":[]},\"ui_text_caret_word_left\":{\"joypad\":[],\"keyboard\":[\"Left|ctrl\"],\"mouse\":[]},\"ui_text_caret_word_left.macos\":{\"joypad\":[],\"keyboard\":[\"Left|alt\"],\"mouse\":[]},\"ui_text_caret_word_right\":{\"joypad\":[],\"keyboard\":[\"Right|ctrl\"],\"mouse\":[]},\"ui_text_caret_word_right.macos\":{\"joypad\":[],\"keyboard\":[\"Right|alt\"],\"mouse\":[]},\"ui_text_clear_carets_and_selection\":{\"joypad\":[],\"keyboard\":[\"Escape\"],\"mouse\":[]},\"ui_text_completion_accept\":{\"joypad\":[],\"keyboard\":[\"Enter\",\"Kp Enter\"],\"mouse\":[]},\"ui_text_completion_query\":{\"joypad\":[],\"keyboard\":[\"Space|ctrl\"],\"mouse\":[]},\"ui_text_completion_replace\":{\"joypad\":[],\"keyboard\":[\"Tab\"],\"mouse\":[]},\"ui_text_dedent\":{\"joypad\":[],\"keyboard\":[\"Tab|shift\"],\"mouse\":[]},\"ui_text_delete\":{\"joypad\":[],\"keyboard\":[\"Delete\"],\"mouse\":[]},\"ui_text_delete_all_to_right\":{\"joypad\":[],\"keyboard\":[],\"mouse\":[]},\"ui_text_delete_all_to_right.macos\":{\"joypad\":[],\"keyboard\":[\"Delete|ctrl\"],\"mouse\":[]},\"ui_text_delete_word\":{\"joypad\":[],\"keyboard\":[\"Delete|ctrl\"],\"mouse\":[]},\"ui_text_delete_word.macos\":{\"joypad\":[],\"keyboard\":[\"Delete|alt\"],\"mouse\":[]},\"ui_text_indent\":{\"joypad\":[],\"keyboard\":[\"Tab\"],\"mouse\":[]},\"ui_text_newline\":{\"joypad\":[],\"keyboard\":[\"Enter\",\"Kp Enter\"],\"mouse\":[]},\"ui_text_newline_above\":{\"joypad\":[],\"keyboard\":[\"Enter|shift,ctrl\",\"Kp Enter|shift,ctrl\"],\"mouse\":[]},\"ui_text_newline_blank\":{\"joypad\":[],\"keyboard\":[\"Enter|ctrl\",\"Kp Enter|ctrl\"],\"mouse\":[]},\"ui_text_scroll_down\":{\"joypad\":[],\"keyboard\":[\"Down|ctrl\"],\"mouse\":[]},\"ui_text_scroll_down.macos\":{\"joypad\":[],\"keyboard\":[\"Down|alt,ctrl\"],\"mouse\":[]},\"ui_text_scroll_up\":{\"joypad\":[],\"keyboard\":[\"Up|ctrl\"],\"mouse\":[]},\"ui_text_scroll_up.macos\":{\"joypad\":[],\"keyboard\":[\"Up|alt,ctrl\"],\"mouse\":[]},\"ui_text_select_all\":{\"joypad\":[],\"keyboard\":[\"A|ctrl\"],\"mouse\":[]},\"ui_text_select_word_under_caret\":{\"joypad\":[],\"keyboard\":[\"G|alt\"],\"mouse\":[]},\"ui_text_select_word_under_caret.macos\":{\"joypad\":[],\"keyboard\":[\"G|ctrl,meta\"],\"mouse\":[]},\"ui_text_skip_selection_for_next_occurrence\":{\"joypad\":[],\"keyboard\":[\"D|alt,ctrl\"],\"mouse\":[]},\"ui_text_submit\":{\"joypad\":[],\"keyboard\":[\"Enter\",\"Kp Enter\"],\"mouse\":[]},\"ui_text_toggle_insert_mode\":{\"joypad\":[],\"keyboard\":[\"Insert\"],\"mouse\":[]},\"ui_undo\":{\"joypad\":[],\"keyboard\":[\"Z|ctrl\"],\"mouse\":[]},\"ui_up\":{\"joypad\":[11,\"1|-1.000000\"],\"keyboard\":[\"Up\"],\"mouse\":[]}}"


func _ready() -> void:
	remove_unsupported_resolutions()
	resolutions_min_y = get_resolutions_min_y()
	
	# AUDIO
	sfx_bus_index = AudioServer.get_bus_index(OptionsConstants.sfx_bus_name)
	music_bus_index = AudioServer.get_bus_index(OptionsConstants.music_bus_name)
	
	load_options()
	load_keybindings_from_config()


func set_headbob_strength(value: int) -> void:
	headbob_strength = value


func set_mouse_sens_value(value):
	mouse_sens = value


func set_gamepad_looksens_value(value):
	gp_looksens = value


func get_resolution_index_for_window_size(size: Vector2i) -> int:
	var resolution_values = RESOLUTION_DICTIONARY.values();
	for i in resolution_values.size():
		var v := Vector2i(resolution_values[i])
		if v == size:
			return i
	return -1


func toggle_fullscreen(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		apply_content_scale_factor(gui_scale)
		fullscreen_mode = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		apply_content_scale_factor(gui_scale)
		fullscreen_mode = false
		
		var window = get_window()
		await get_tree().create_timer(window_operations_delay).timeout
		window.size = windowed_resolution
		window.content_scale_size = Vector2i.ZERO
		window.scaling_3d_scale = 1.0
		center_window()


func apply_content_scale_factor(value:float) -> void:
	gui_scale = value
	get_viewport().content_scale_factor = gui_scale


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func refresh_render():
	var window = get_window()
	print("CogitoGameConfig: refresh_render() : Current resolution index is ", current_resolution_index)
	windowed_resolution = RESOLUTION_DICTIONARY.values()[current_resolution_index]
	
	toggle_fullscreen(fullscreen_mode)
	
	if fullscreen_mode:
		window.scaling_3d_scale = fullscreen_resolution_scale_val
	else:
		window.size = windowed_resolution
		window.content_scale_size = Vector2i.ZERO
		window.scaling_3d_scale = 1.0
	
	msaa_2d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, 0)
	msaa_3d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, 0)
	set_msaa("msaa_2d", msaa_2d)
	set_msaa("msaa_3d", msaa_3d)
	set_vsync(vsync)


# Function to change resolution. Hooked up to the windowed_resolution_option_button.
func _on_resolution_selected(index: int) -> void:
	# Setting the current_resolution index to the passed index from the drop down button.
	current_resolution_index = index
	
	prev_windowed_resolution = windowed_resolution
	windowed_resolution = RESOLUTION_DICTIONARY.values()[current_resolution_index]
	
	# gui_scale_slider.max_value = get_gui_scale_max_value(windowed_resolution.y)
	apply_content_scale_factor(gui_scale)
	
	if prev_windowed_resolution != windowed_resolution:
		var window = get_window()
		window.size = windowed_resolution
		window.content_scale_size = Vector2i.ZERO
		center_window()
		
		options_have_changed.emit()
		windowed_resolution_has_changed.emit()


# Sets the volume for the given audio bus
func set_volume(bus_index, value):
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	match bus_index:
		music_bus_index:
			music_volume = value
		sfx_bus_index:
			sfx_volume = value

	options_have_changed.emit()


# Saves the options
func save_options():
	config.set_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, invert_y)
	config.set_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, toggle_crouching)
	config.set_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, headbob_strength)
	config.set_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, mouse_sens)
	config.set_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, gp_looksens)
	config.set_value(OptionsConstants.section_name, OptionsConstants.fullscreen_mode_key_name, is_fullscreen())
	config.set_value(OptionsConstants.section_name, OptionsConstants.resolution_index_key_name, current_resolution_index)
	config.set_value(OptionsConstants.section_name, OptionsConstants.fullscreen_resolution_scale_key, fullscreen_resolution_scale_val)
	config.set_value(OptionsConstants.section_name, OptionsConstants.gui_scale_key, gui_scale)
	config.set_value(OptionsConstants.section_name, OptionsConstants.vsync_key, vsync)
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, msaa_2d)
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, msaa_3d)

	# We previously removed the legacy `render_scale` key – clean it if present
	if config.has_section_key(OptionsConstants.section_name, "render_scale"):
		config.erase_section_key(OptionsConstants.section_name, "render_scale")

	config.set_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, sfx_volume)
	config.set_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, music_volume)
	
	# SAVING INPUT MAP
	var serialized_inputs = InputHelper.serialize_inputs_for_actions()
	config.set_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string, serialized_inputs)
	
	if config.save(OptionsConstants.config_file_name) != OK:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Saving config file failed.")
	else:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Saving config file OK")
		
	options_saved.emit()


# Loads options and sets the controls values to loaded values. Uses default values if config file does not exist
func load_options(skip_applying: bool = false):
	var err = config.load(OptionsConstants.config_file_name)
	# If the config file does not yet exist, we will NOT immediately
	# apply (emit) resolution/window size changes. This prevents the first launch
	# from overriding the ProjectSettings default resolution (e.g. 1920x1080) with
	# our menu's first resolution entry. We still populate UI controls so the user
	# can see/change them, but we only perform window/content_scale modifications
	# once a valid config exists (subsequent launches) or when the user explicitly
	# applies changes.
	have_cfg = (err == OK)
	if !have_cfg:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Loading options config failed (likely first run). Using project defaults until user applies settings.")
	
	invert_y = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
	toggle_crouching = config.get_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, true)
	mouse_sens = config.get_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, 0.25)
	gp_looksens = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)
	headbob_strength = config.get_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, 2)
	fullscreen_mode = config.get_value(OptionsConstants.section_name, OptionsConstants.fullscreen_mode_key_name, is_fullscreen())
	# current_resolution_index := windowed_resolution_option_button.selected
	current_resolution_index = config.get_value(OptionsConstants.section_name, OptionsConstants.resolution_index_key_name, 0)
	fullscreen_resolution_scale_val = config.get_value(OptionsConstants.section_name, OptionsConstants.fullscreen_resolution_scale_key, 1.0)
	gui_scale = config.get_value(OptionsConstants.section_name, OptionsConstants.gui_scale_key, 1)
	vsync = config.get_value(OptionsConstants.section_name, OptionsConstants.vsync_key, true)

	msaa_2d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, 0)
	msaa_3d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, 0)

	sfx_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, 1)
	music_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, 1)
	
	# Sending signal so any post options-loaded actions can be taken.
	options_loaded.emit(skip_applying)
	
	# Only apply window mode + resolution + refresh when a config actually exists,
	# and when we're not skipping applying.
	if !skip_applying and have_cfg:
		refresh_render()


# Centers the window in the middle of the user's current screen
func center_window() -> void:
	var window = get_window()
	var center_of_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_size = window.get_size_with_decorations()
	await get_tree().create_timer(window_operations_delay).timeout
	window.position = center_of_screen - window_size / 2


func set_vsync(is_enabled:bool):
	# There are multiple V-Sync Methods supported by Godot 
	# For now we just use the simple ones could be worth a consideration to add the others
	# Just sets V-Sync for the first window. So no support for multi window games
	if is_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	vsync = is_enabled


func set_msaa(mode, index):
	match index:
		0:
			get_viewport().set(mode, Viewport.MSAA_DISABLED)
		1:
			get_viewport().set(mode, Viewport.MSAA_2X)
		2:
			get_viewport().set(mode, Viewport.MSAA_4X)
		3:
			get_viewport().set(mode, Viewport.MSAA_8X)


func load_keybindings_from_config():
	var err = config.load(OptionsConstants.config_file_name)
	if err != 0:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Keybindings: Loading options config failed.")
		#save_keybindings_to_config()
		
	var serialized_inputs = config.get_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string, serialized_default_inputs)
	if serialized_inputs:
		InputHelper.deserialize_inputs_for_actions(serialized_inputs)
	else:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Keybindings: No saved bindings found.")


func save_keybindings_to_config():
	var serialized_inputs = InputHelper.serialize_inputs_for_actions()
	config.set_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string, serialized_inputs)
	config.save(OptionsConstants.config_file_name)


func remove_unsupported_resolutions():
	var screen_size = DisplayServer.screen_get_size()
	for resolution_key in RESOLUTION_DICTIONARY:
		var resolution = RESOLUTION_DICTIONARY[resolution_key]
		if resolution.x > screen_size.x or resolution.y > screen_size.y:
			RESOLUTION_DICTIONARY.erase(resolution_key)


func get_resolutions_min_y():
	var screen_size = DisplayServer.screen_get_size()
	var min_y = screen_size.y
	for resolution_key in RESOLUTION_DICTIONARY:
		var resolution = RESOLUTION_DICTIONARY[resolution_key]
		if resolution.y < min_y:
			min_y = resolution.y
	
	return min_y
