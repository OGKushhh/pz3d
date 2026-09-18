@abstract class_name CogitoPlayerState
extends Resource

@abstract func populate_player_data(player)
@abstract func populate_save_data(player, slot)

var player_state_dir : String = CogitoSceneManager.cogito_state_dir + CogitoSceneManager.cogito_player_state_prefix

@export var player_current_scene : String
@export var player_current_scene_path : String

#Saving some extra data for save game management/UI
@export var player_state_screenshot_file : String
@export var player_state_savetime : int
@export var player_state_slot_name : String


func write_state(state_slot : String) -> void:
	var dir = DirAccess.open("user://")
	dir.make_dir(CogitoSceneManager.cogito_state_dir)
	dir = DirAccess.open(CogitoSceneManager.cogito_state_dir)
	dir.make_dir(str(state_slot))
	var player_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_player_state_prefix + ".res")
	#var player_state_file = str(player_state_dir + state_slot + ".res")
	ResourceSaver.save(self, player_state_file, ResourceSaver.FLAG_CHANGE_PATH)
	CogitoGlobals.debug_log(true, "CogitoPlayerState", "Player state saved as " + str(player_state_file) )


func state_exists(state_slot : String) -> bool:
	#var player_state_file = str(player_state_dir + state_slot + ".res")
	var player_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_player_state_prefix + ".res")
	#return ResourceLoader.exists(player_state_file)
	return FileAccess.file_exists(player_state_file)
 

func load_state(state_slot : String) -> Resource:
	#var player_state_file = str(player_state_dir + state_slot + ".res")
	var player_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_player_state_prefix + ".res")
	return ResourceLoader.load(player_state_file, "", ResourceLoader.CACHE_MODE_IGNORE)
	
