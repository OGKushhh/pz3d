extends StateProcessor

@export var alerted_bark: AudioStream
@export var must_have_been_the_wind_bark: AudioStream
## How long should it take once alerted should they start moving? Allows them to turn around during that time
@export var initial_shock_time: float = 1.5
## Once they navigate to the source of the alert (or can't), how long to wait for?
@export var wait_time_once_reached: float = 5.0
@export var show_attention_target_sprite: bool = false

var shock_timer: Timer
var return_to_patrol_timer: Timer
var target: Vector3


func _enter_tree() -> void:
	shock_timer = create_timer(initial_shock_time, start_moving)
	return_to_patrol_timer = create_timer(wait_time_once_reached, return_to_patrol)


func _on_alerted_state_entered() -> void:
	super.enter_state()
	shock_timer.start()
	target = npc.attention_target.global_position
	bark(alerted_bark)
	npc.attention_target.visible =  show_attention_target_sprite


func _on_alerted_state_exited() -> void:
	super.exit_state()
	# Hide the attention_target
	if show_attention_target_sprite and npc.attention_target:
		npc.attention_target.visible = false


func start_moving():
	npc.nav_agent.target_position = target


func return_to_patrol():
	state_chart.send_event("patrol")
	bark(must_have_been_the_wind_bark)


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.attention_target:
		CogitoGlobals.debug_log(true, "npc_state_alerted", "Null Attention Point, likely due to reload. Returning to patrol")
		state_chart.send_event("patrol")
		return
	
	if not shock_timer.is_stopped() or not return_to_patrol_timer.is_stopped():
		npc.face_direction(npc.attention_target.global_position)
	
	if npc.nav_agent.target_position == npc.attention_target.global_position and not npc.nav_agent.is_target_reached():
		npc.move_npc_to_next_position(delta)
	else:
		npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
		npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
		npc.move_and_slide()
	
	if (npc.nav_agent.is_target_reached() or not npc.nav_agent.is_target_reachable()) and return_to_patrol_timer.is_stopped():
		CogitoGlobals.debug_log(true, "npc_state_alerted", "Attention point has been reached, waiting for %s sec until returning to patrol" % [wait_time_once_reached])
		return_to_patrol_timer.start()


func create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer
