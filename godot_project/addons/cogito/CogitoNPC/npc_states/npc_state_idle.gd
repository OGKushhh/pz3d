extends StateProcessor

func _on_idle_state_entered() -> void:
	super.enter_state()
	CogitoGlobals.debug_log(true, "npc_state_idle.gd", "Idle state entered")
	if npc.patrol_path:
		state_chart.send_event("patrol")
		state_chart.send_event("body_walk")


func _on_idle_state_exited() -> void:
	super.exit_state()
	CogitoGlobals.debug_log(true, "npc_state_idle.gd", "Idle state exiting")
