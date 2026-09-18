@tool
extends EditorPlugin
const cogito_plugin_icon : Texture2D = preload("./Cogito.svg")
const cogito_default_settings = preload("./CogitoSettings.tres")

var cog_settings : CogitoSettings

var parser_plugin: EditorTranslationParserPlugin

func _enter_tree():
	add_autoload_singleton("CogitoGlobals", "/cogito_globals.gd")
	add_autoload_singleton("CogitoGameConfig", "/Scripts/cogito_game_config.gd")
	add_autoload_singleton("CogitoSceneManager", "/SceneManagement/cogito_scene_manager.gd")
	add_autoload_singleton("CogitoQuestManager", "/QuestSystem/cogito_quest_manager.gd")
	add_autoload_singleton("MenuTemplateManager", "/EasyMenus/Nodes/menu_template_manager.tscn")
	add_autoload_singleton("InputRouter", "/Scripts/input_router.gd")
	
	add_custom_type("FluidArea3D", "RigidBody3D", preload("res://addons/cogito/FloatableBody/fluid_area_3d.gd"), null)
	add_custom_type("FloatableBody3D", "RigidBody3D", preload("res://addons/cogito/FloatableBody/floatable_body_3d.gd"), null)
	
	# Initialization of the plugin goes here.
	parser_plugin = load("res://addons/cogito/Localization/scripts/loc_resource_parser.gd").new()
	add_translation_parser_plugin(parser_plugin)
	
	cog_settings = cogito_default_settings
	

func _exit_tree():
	
	remove_custom_type("FloatableBody3D")
	remove_custom_type("FluidArea3D")

	remove_autoload_singleton("InputRouter")
	remove_autoload_singleton("CogitoQuestManager")
	remove_autoload_singleton("MenuTemplateManager")
	remove_autoload_singleton("CogitoSceneManager")
	remove_autoload_singleton("CogitoGameConfig")
	remove_autoload_singleton("CogitoGlobals")

	remove_translation_parser_plugin(parser_plugin)


func _get_plugin_name():
	return "Cogito"


func _get_plugin_icon():
	return cogito_plugin_icon
