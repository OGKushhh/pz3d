extends StateProcessor

## Reference to the sight detection system so cone detection checks can be done after the first point is reached
@export var sight_detection: SightDetection

## How long does the player need to be in view of the NPC before restarting the chase? 
@export var reacquire_time: float = 0.5
## How far does the NPC turn their head from side to side in degrees?
@export var head_target_rotation_angle: float = 60
## Resets both hearing and sight suspicion to zero when the search ends
@export var reset_suspicion_when_search_ends: bool = true
## How long (in seconds) should the NPC wait at the first point before moving to the next?
@export var wait_at_first_point: float = 5.0
## How long (in seconds) before the NPC gives up searching once reaching the last known player position?
@export var end_search_after_second_point: float = 3.0
## If the NPC can't pathfind to where the player was, how long should they wait?
@export var end_search_if_stuck_for: float = 10.0
## What does the NPC bark when start searching?
@export var searching_bark: AudioStream
## What does the NPC bark when they end the search?
@export var end_search_bark: AudioStream
## Optional audio cue for if the player is being detected again
@export var i_see_you_bark: AudioStream

## Pivot that rotates the look-ahead to make the head move
@export var searching_look_ahead_pivot: Node3D
## Invisible point that the NPC looks at
@export var searching_look_ahead: Node3D

## For debugging purposes, shows the search points in 3d space 
@export var show_search_points: bool = false
var search_point_one_label: Label3D
var search_point_two_label: Label3D

## The point where the player's line of sight was broken
var broken_los_point: Vector3
## The point where the player was when the line of sight timer finished
var last_known_player_point: Vector3

var player: CogitoPlayer:
	get:
		if not player:
			return CogitoSceneManager._current_player_node
		return player

var los_point_reached: bool = false
var last_known_point_reached: bool = false

var reacquire_timer: Timer
var first_wait_timer: Timer
var second_wait_timer: Timer 

var stuck_timer: Timer

var head: LookAtModifier3D

func _enter_tree() -> void:
	if show_search_points:
		search_point_one_label = create_debug_label("1")
		search_point_two_label = create_debug_label("2")
	
	first_wait_timer = create_timer(wait_at_first_point, search_next_point)
	second_wait_timer = create_timer(end_search_after_second_point, end_search)
	reacquire_timer = create_timer(reacquire_time, start_chasing)
	stuck_timer = create_timer(end_search_if_stuck_for, end_search)
	

func _on_searching_state_entered() -> void:
	if show_search_points and not search_point_one_label.is_inside_tree():
			get_tree().current_scene.add_child(search_point_one_label)
			get_tree().current_scene.add_child(search_point_two_label)
	
	npc.nav_agent.target_position = broken_los_point
	if not npc.nav_agent.target_reached.is_connected(reached_target):
		npc.nav_agent.target_reached.connect(reached_target)
	
	first_wait_timer.stop()
	second_wait_timer.stop()
	reacquire_timer.stop()
	
	bark(searching_bark)
	state_chart.send_event("body_walk")
	npc.move_speed = npc.walk_speed
	los_point_reached = false
	last_known_point_reached = false
	head = npc.head_turner
	head.active = true
	head.target_node = searching_look_ahead.get_path()


func _on_searching_state_exited() -> void:
	searching_look_ahead_pivot.rotation_degrees.y = 0
	head.target_node = NodePath("")
	if show_search_points:
		search_point_one_label.visible = false
		search_point_two_label.visible = false
	super.exit_state()


func _on_searching_state_physics_processing(delta: float) -> void:
	if show_search_points:
		search_point_one_label.visible = true
		search_point_one_label.global_position = broken_los_point
		search_point_two_label.visible = true
		search_point_two_label.global_position = last_known_player_point
	
	sight_detection_check()
	if npc.nav_agent.is_target_reached():
		npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
		npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
	else:
		# Test LOS of the player, start an reacquire timer if they are seen
		if reacquire_timer.is_stopped():
			turn_head(delta)
			npc.move_npc_to_next_position(delta)
			
		# If the place can't be reached start the stuck timer
		if not npc.nav_agent.is_target_reachable() and stuck_timer.is_stopped():
			stuck_timer.start()


## Calls the sight detection mechanism to determine if a player is within the cone and visible.
func sight_detection_check():
	if sight_detection.check_if_player_in_los():
		stuck_timer.stop()
		if reacquire_timer.is_stopped():
			head.target_node = player.head.get_path()
			bark(i_see_you_bark)
			reacquire_timer.start()
	else:
		head.target_node = searching_look_ahead.get_path()
		reacquire_timer.stop()


func start_chasing():
	npc.attention_target = player
	state_chart.send_event("chase")


func reached_target():
	if not los_point_reached:
		los_point_reached = true
		first_wait_timer.start()
	elif not last_known_point_reached:
		last_known_point_reached = true
		second_wait_timer.start()


func search_next_point():
	npc.nav_agent.target_position = last_known_player_point


func end_search():
	bark(end_search_bark)
	if reset_suspicion_when_search_ends:
		if npc.hearing_detection:
			npc.hearing_detection.reset()
		if npc.sight_detection:
			npc.sight_detection.reset()
	state_chart.send_event("ubody_neutral")
	state_chart.send_event("patrol")


func turn_head(delta: float) -> void:#
	if head_target_rotation_angle > 0:
		searching_look_ahead_pivot.rotate_y(deg_to_rad(-180)*delta)
		if searching_look_ahead_pivot.rotation_degrees.y >= head_target_rotation_angle:
			head_target_rotation_angle *= -1
	else:
		searching_look_ahead_pivot.rotate_y(deg_to_rad(-180)*delta)
		if searching_look_ahead_pivot.rotation_degrees.y <= head_target_rotation_angle:
			head_target_rotation_angle *= -1


func create_timer(wait_time: float, call_on_timeout: Callable) -> Timer:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(call_on_timeout)
	add_child(timer)
	return timer


func create_debug_label(text: String) -> Label3D:
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.text = text
	return label
