extends Area3D
class_name CogitoCutsceneTrigger

## The animation player containing the cutscene to play
@export var cutscene_animation_player : AnimationPlayer
## Name of the cutscene to play
@export var cutscene_animation_name : String
## If true, the player can cancel the cutscene by pressing the UI_cancel input map action.
@export var allow_cancel : bool = false
## If true, this cutscene allows repeat triggering
@export var allow_repeat : bool = false
## If true, the player HUD will be hidden while playing the cutscene.
@export var hide_hud : bool = true

var player_reference : CogitoPlayer
var has_been_triggered : bool = false #Used to avoid double-triggering.
var cutscene_timer : Timer = Timer.new()

func _ready() -> void:
	add_to_group("save_object_state")
	cutscene_timer.one_shot = true
	cutscene_timer.timeout.connect(finish_cutscene)
	self.add_child(cutscene_timer)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and allow_cancel:
		finish_cutscene()


func _on_body_entered(body: Node3D):
	if !body.is_in_group("Player"):
		return
	
	player_reference = body
	play_cutscene()


func _on_body_exited(body: Node3D):
	if !body.is_in_group("Player"):
		return


func play_cutscene() -> void:
	if has_been_triggered and !allow_repeat:
		return
	if !cutscene_animation_player or !cutscene_animation_name:
		return
	
	print("Cutscene started.")
	InputRouter.push(on_input)
	
	if hide_hud:
		player_reference.player_hud.set_visible(false)
	

	cutscene_animation_player.play(cutscene_animation_name)
	cutscene_timer.wait_time = cutscene_animation_player.current_animation_length
	cutscene_timer.start()


func finish_cutscene() -> void:
	print("Cutscene finished.")
	cutscene_timer.stop()
	cutscene_animation_player.stop()
	has_been_triggered = true
	if hide_hud:
		player_reference.player_hud.set_visible(true)
	player_reference.camera.make_current()
	InputRouter.pop()



func set_state() -> void:
	pass
	
func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"has_been_triggered" : has_been_triggered,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
