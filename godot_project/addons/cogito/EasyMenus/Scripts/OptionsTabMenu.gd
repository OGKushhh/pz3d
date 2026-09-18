class_name OptionsTabMenu
extends Control
signal options_updated

# Grabbing TabContainer node for gamepad navigation
@onready var tab_container: CogitoTabMenu = $VBoxContainer/TabContainer

const HSliderWLabel = preload("res://addons/cogito/EasyMenus/Scripts/slider_w_labels.gd")
var config = ConfigFile.new()

var have_options_changed := false
var has_windowed_resolution_changed := false

# GAMEPLAY
@onready var invert_y_check_button: CheckBox = %InvertYAxisCheckButton
@onready var toggle_crouching_check_button: CheckBox = %ToggleCrouchingCheckButton
@onready var headbob_option_button: OptionButton = %HeadbobOptionButton
@onready var mouse_sens_slider: HSlider = %MouseSensSlider
@onready var mouse_sens_value_label: Label = %MouseSensValueLabel
@onready var gp_look_sens_value_label: Label = %GPLookSensValueLabel
@onready var gp_look_sens_slider: HSlider = %GPLookSensSlider


# AUDIO
@onready var sfx_volume_slider: HSliderWLabel = %HBoxContainer_SFXVolumeSlider
@onready var music_volume_slider: HSliderWLabel = %HBoxContainer_MusicVolumeSlider


# GRAPHICS
@onready var fullscreen_resolution_slider: Slider = %FullscreenResolutionSlider
@onready var fullscreen_resolution_current_value_label: Label = %FullscreenResolutionCurrentValueLabel
@onready var h_box_container_fullscreen_resolution: HBoxContainer = %HBoxContainer_FullscreenResolution
@onready var windowed_resolution_option_button: OptionButton = %WindowedResolutionOptionButton
@onready var gui_scale_current_value_label: Label = %GUIScaleCurrentValueLabel
@onready var gui_scale_slider: HSlider = %GUIScaleSlider
@onready var vsync_check_button: CheckBox = %VSyncCheckButton
@onready var anti_aliasing_2d_option_button: OptionButton = $%AntiAliasing2DOptionButton
@onready var anti_aliasing_3d_option_button: OptionButton = $%AntiAliasing3DOptionButton
@onready var fullscreen_mode_check_button: CheckBox = %FullscreenModeCheckButton


const window_operations_delay = 0.25


# INPUT BINDING
@export var remap_entry: PackedScene
@export var separator_entry: PackedScene

@onready var bindings_container: VBoxContainer = %BindingsContainer

@export var rebind_dictionary: Dictionary


func _ready() -> void:
	reset()
	
	CogitoGameConfig.options_saved.connect(_on_options_saved)
	CogitoGameConfig.options_loaded.connect(_on_options_loaded)
	
	# GAMEPLAY
	add_headbob_items()
	headbob_option_button.item_selected.connect(on_headbob_selected)
	mouse_sens_slider.value_changed.connect(_on_mouse_sens_slider_value_changed)
	gp_look_sens_slider.value_changed.connect(_on_gp_looksens_slider_value_changed)
	invert_y_check_button.toggled.connect(_on_invert_y_toggled)
	toggle_crouching_check_button.toggled.connect(_on_toggle_crouch_toggled)
	
	# GRAPHICS
	init_fullscreen_mode()
	init_windowed_resolution()
	vsync_check_button.toggled.connect(_on_v_sync_check_button_toggled)
	fullscreen_mode_check_button.toggled.connect(_on_fullscreen_mode_toggled)
	windowed_resolution_option_button.item_selected.connect(CogitoGameConfig._on_resolution_selected)
	gui_scale_slider.value_changed.connect(_on_gui_scale_slider_value_changed)
	
	# AUDIO
	CogitoGameConfig.sfx_bus_index = AudioServer.get_bus_index(OptionsConstants.sfx_bus_name)
	CogitoGameConfig.music_bus_index = AudioServer.get_bus_index(OptionsConstants.music_bus_name)
	sfx_volume_slider.hslider.value_changed.connect(_on_sfx_volume_slider_value_changed)
	music_volume_slider.hslider.value_changed.connect(_on_music_volume_slider_value_changed)
	
	CogitoGameConfig.load_options()
	load_keybindings_from_config()
	create_action_remap_items()


# Called from outside initializes the options menu
func on_open():
	pass


#region GAMEPLAY OPTIONS
# Adding headbob options to the button
func add_headbob_items() -> void:
	for headbob_option in CogitoGameConfig.HEADBOB_DICTIONARY:
		headbob_option_button.add_item(headbob_option)


func on_headbob_selected(index: int) -> void:
	CogitoGameConfig.set_headbob_strength(CogitoGameConfig.HEADBOB_DICTIONARY.values()[index])


func _on_mouse_sens_slider_value_changed(value):
	CogitoGameConfig.mouse_sens = value
	mouse_sens_value_label.text = str(value)
	

func _on_gp_looksens_slider_value_changed(value):
	CogitoGameConfig.gp_looksens = value
	gp_look_sens_value_label.text = str(value)


func _on_invert_y_toggled(is_on: bool) -> void:
	CogitoGameConfig.invert_y = is_on


func _on_toggle_crouch_toggled(is_on: bool) -> void:
	CogitoGameConfig.toggle_crouching = is_on
#endregion

# Initialize the fullscreen mode check button to reflect current state.
func init_fullscreen_mode() -> void:
	fullscreen_mode_check_button.set_pressed_no_signal(CogitoGameConfig.is_fullscreen())


# Initialize all windowed resolutions and set the current windowed resolution on the button
func init_windowed_resolution() -> void:
	for resolution_text in CogitoGameConfig.RESOLUTION_DICTIONARY:
		windowed_resolution_option_button.add_item(resolution_text)

	CogitoGameConfig.windowed_resolution = get_window().size
	CogitoGameConfig.prev_windowed_resolution = CogitoGameConfig.windowed_resolution

	var idx = CogitoGameConfig.get_resolution_index_for_window_size(get_window().size)
	if idx != -1:
		windowed_resolution_option_button.selected = idx


func get_gui_scale_max_value(resolution_y):
	var scale_max_value = (resolution_y / CogitoGameConfig.resolutions_min_y) * CogitoGameConfig.max_gui_scale_ratio
	var remainder = fmod(scale_max_value, gui_scale_slider.step)
	if remainder < gui_scale_slider.step - 0.0001:
		scale_max_value -= remainder
	
	return scale_max_value


func _on_fullscreen_mode_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		
		gui_scale_slider.max_value = get_gui_scale_max_value(DisplayServer.screen_get_size().y)
		gui_scale_slider.value = CogitoGameConfig.gui_scale
		apply_gui_scale_value()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		
		var scale_max_value = get_gui_scale_max_value(CogitoGameConfig.windowed_resolution.y)
		gui_scale_slider.max_value = scale_max_value
		if gui_scale_slider.value >= scale_max_value:
			gui_scale_slider.value = scale_max_value
		apply_gui_scale_value()
		
		var window = get_window()
		await get_tree().create_timer(window_operations_delay).timeout
		window.size = CogitoGameConfig.windowed_resolution
		window.content_scale_size = Vector2i.ZERO
		window.scaling_3d_scale = 1.0
		CogitoGameConfig.center_window()
		
	refresh_resolution_controls()



func _on_fullscreen_resolution_slider_value_changed(value: float) -> void:
	var scale = value / 100.00
	CogitoGameConfig.fullscreen_resolution_scale_val = scale
	update_fullscreen_resolution_slider_label()
	have_options_changed = true

func _on_sfx_volume_slider_value_changed(value):
	CogitoGameConfig.set_volume(CogitoGameConfig.sfx_bus_index, value)


func _on_music_volume_slider_value_changed(value):
	CogitoGameConfig.set_volume(CogitoGameConfig.music_bus_index, value)


# Loads options and sets the controls values to loaded values. Uses default values if config file does not exist
func _on_options_loaded(skip_applying:bool):
	# LOADING GAMEPLAY CFG
	invert_y_check_button.set_pressed_no_signal(CogitoGameConfig.invert_y)
	toggle_crouching_check_button.set_pressed(CogitoGameConfig.toggle_crouching)
	
	invert_y_check_button.toggled.emit(invert_y_check_button.is_pressed())
	toggle_crouching_check_button.toggled.emit(invert_y_check_button.is_pressed())
	
	match CogitoGameConfig.headbob_strength:
		1: headbob_option_button.selected = 0
		3: headbob_option_button.selected = 1
		7: headbob_option_button.selected = 2

	if !skip_applying:
		headbob_option_button.item_selected.emit(headbob_option_button.selected)

	mouse_sens_slider.value = CogitoGameConfig.mouse_sens
	mouse_sens_value_label.text = str(CogitoGameConfig.mouse_sens)

	gp_look_sens_slider.value = CogitoGameConfig.gp_looksens
	gp_look_sens_value_label.text = str(CogitoGameConfig.gp_looksens)

	# LOADING AUDIO CFG
	sfx_volume_slider.hslider.value = CogitoGameConfig.sfx_volume
	music_volume_slider.hslider.value = CogitoGameConfig.music_volume

	# LOADING GRAPHICS CFG
	# Setting index based on the option button.
	#windowed_resolution_option_button.selected = CogitoGameConfig.current_resolution_index
	refresh_resolution_controls()
	
	update_fullscreen_resolution_slider_value()
	update_fullscreen_resolution_slider_label()
	
	# Need to set it like that to guarantee signal to be triggered
	vsync_check_button.set_pressed_no_signal(CogitoGameConfig.vsync)
	vsync_check_button.toggled.emit(vsync_check_button.is_pressed())
	
	anti_aliasing_2d_option_button.selected = CogitoGameConfig.msaa_2d
	anti_aliasing_3d_option_button.selected = CogitoGameConfig.msaa_3d
	
	fullscreen_mode_check_button.set_pressed_no_signal(CogitoGameConfig.fullscreen_mode)
	if CogitoGameConfig.resolution_index:
		windowed_resolution_option_button.selected = CogitoGameConfig.current_resolution_index
	
	if CogitoGameConfig.fullscreen_mode:
		gui_scale_slider.max_value = get_gui_scale_max_value(DisplayServer.screen_get_size().y)
	else:
		gui_scale_slider.max_value = get_gui_scale_max_value(CogitoGameConfig.windowed_resolution.y)
	
	gui_scale_slider.value = CogitoGameConfig.gui_scale
	gui_scale_current_value_label.text = "%d%%" % (CogitoGameConfig.gui_scale * 100)
	
	if !skip_applying:
		apply_gui_scale_value()
	
	# Only apply window mode + resolution + refresh when a config actually exists,
	# and when we're not skipping applying.
	if !skip_applying and CogitoGameConfig.have_cfg:
		anti_aliasing_2d_option_button.emit_signal("item_selected", CogitoGameConfig.msaa_2d)
		anti_aliasing_3d_option_button.emit_signal("item_selected", CogitoGameConfig.msaa_3d)
		windowed_resolution_option_button.select(CogitoGameConfig.current_resolution_index)
		#windowed_resolution_option_button.item_selected.emit(CogitoGameConfig.current_resolution_index)
		fullscreen_mode_check_button.toggled.emit(CogitoGameConfig.fullscreen_mode)
		#CogitoGameConfig.refresh_render()

	refresh_resolution_controls()


func refresh_resolution_controls():
	fullscreen_resolution_slider.visible = CogitoGameConfig.fullscreen_mode
	# Show fullscreen resolution slider only in fullscreen mode
	h_box_container_fullscreen_resolution.visible = CogitoGameConfig.fullscreen_mode

	# Show windowed resolution selector only in windowed mode
	windowed_resolution_option_button.visible = !CogitoGameConfig.fullscreen_mode

	if CogitoGameConfig.fullscreen_mode:
		update_fullscreen_resolution_slider_value()
		update_fullscreen_resolution_slider_label()


func update_fullscreen_resolution_slider_value() -> void:
	fullscreen_resolution_slider.value = CogitoGameConfig.fullscreen_resolution_scale_val * 100.0


func update_fullscreen_resolution_slider_label() -> void:
	var scale = CogitoGameConfig.fullscreen_resolution_scale_val
	var window_size = DisplayServer.screen_get_size()
	var pct = roundi(scale * 100.0)
	var res_x = roundi(window_size.x * scale)
	var res_y = roundi(window_size.y * scale)
	fullscreen_resolution_current_value_label.text = "%d%% - %dx%d" % [pct, res_x, res_y]



func _on_gui_scale_slider_value_changed(value):
	gui_scale_current_value_label.text = "%d%%" % int(value * 100)
	have_options_changed = true


func _on_gui_scale_slider_drag_ended(_value_changed):
	gui_scale_current_value_label.text = "%d%%" % int(gui_scale_slider.value * 100)
	have_options_changed = true


func apply_gui_scale_value():
	CogitoGameConfig.apply_content_scale_factor(gui_scale_slider.value)
	gui_scale_current_value_label.text = "%d%%" % (gui_scale_slider.value * 100)


func _on_v_sync_check_button_toggled(button_pressed):
	CogitoGameConfig.set_vsync(button_pressed)


func _on_anti_aliasing_2d_option_button_item_selected(index):
	CogitoGameConfig.set_msaa("msaa_2d", index)


func _on_anti_aliasing_3d_option_button_item_selected(index):
	CogitoGameConfig.set_msaa("msaa_3d", index)



func load_keybindings_from_config():
	var err = config.load(OptionsConstants.config_file_name)
	if err != 0:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Keybindings: Loading options config failed.")
		#save_keybindings_to_config()
		
	var serialized_inputs = config.get_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string, CogitoGameConfig.serialized_default_inputs)
	if serialized_inputs:
		InputHelper.deserialize_inputs_for_actions(serialized_inputs)
	else:
		CogitoGlobals.debug_log(true, "OptionsTabMenu.gd", "Keybindings: No saved bindings found.")


func save_keybindings_to_config():
	var serialized_inputs = InputHelper.serialize_inputs_for_actions()
	config.set_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string, serialized_inputs)
	config.save(OptionsConstants.config_file_name)

	
func create_action_remap_items() -> void:
	for action in CogitoGameConfig.input_actions:
		if action.contains("separator"):
			var separator = separator_entry.instantiate()
			bindings_container.add_child(separator)
			separator.separator_text = CogitoGameConfig.input_actions[action]
		else:
			var input_entry = remap_entry.instantiate()
			input_entry.action = action
			bindings_container.add_child(input_entry)
			input_entry.label.text = tr(CogitoGameConfig.input_actions[action])


func _on_apply_changes_pressed() -> void:
	CogitoGameConfig.save_options()

	
func _on_options_saved() -> void:
	apply_gui_scale_value()

	if have_options_changed:
		CogitoGameConfig.refresh_render()

	if has_windowed_resolution_changed:
		CogitoGameConfig.center_window()
	
	reset()
	options_updated.emit()


func reset():
	get_window().content_scale_size = Vector2i.ZERO
	have_options_changed = false
	has_windowed_resolution_changed = false



func _on_tab_menu_resume():
	# reload options
	CogitoGameConfig.load_options.call_deferred()
