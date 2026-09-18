extends StateProcessor

var attention_spot: Sprite3D
@export var investigate_bark: AudioStream

func _on_investigate_state_entered() -> void:
	super.enter_state()
	state_chart.send_event("ubody_raise_weapon")
	if npc.attention_target is Sprite3D:
		attention_spot = npc.attention_target
		npc.nav_agent.target_position = attention_spot.global_position
	bark(investigate_bark)


func _on_investigating_state_exited() -> void:
	super.exit_state()
	if attention_spot:
		attention_spot.visible = false


func _on_investigate_state_physics_processing(delta: float) -> void:
	npc.move_npc_to_next_position(delta)
