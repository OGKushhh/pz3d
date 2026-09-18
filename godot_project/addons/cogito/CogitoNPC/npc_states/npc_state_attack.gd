extends StateProcessor

## Which state to move back to once they finish attacking
@export var state_after_attack : String
## If the NPC has a ranged weapon can they can immediately attack once in range?
@export var can_attack_while_moving: bool = false

@export_group("Unarmed Attack Properties")
## The collider that checks for the player or is checked by the player
@export var attack_impact_zone: ImpactZone
## How long this attack takes.
@export var attack_duration : float = 1
@export var attack_sound : AudioStream

var target : Node3D = null
var count_down : float = 0


func _on_attacking_state_entered() -> void:
	super.enter_state()
	target = npc.attention_target
	
	if !target:
		CogitoGlobals.debug_log(true,"NPC State Attack","Target was null, going to previous state...")
		state_chart.send_event(state_after_attack)
	else:
		count_down = attack_duration
		if attack_while_moving():
			attempt_attack()


func _on_attacking_state_exited() -> void:
	super.exit_state()
	# Disable the collider once the attack finishes
	attack_impact_zone.set_collision(false)


func _on_attacking_state_physics_processing(delta: float) -> void:
	# Lerping down the velocity
	npc.velocity.x = move_toward(npc.velocity.x, 0, delta * npc.move_speed)
	npc.velocity.z = move_toward(npc.velocity.z, 0, delta * npc.move_speed)
	npc.face_direction(target.global_position)
	npc.move_and_slide()
	
	if count_down <= 0 and attack_while_moving():
		attempt_attack()
		state_chart.send_event(state_after_attack)
	else:
		count_down -= delta


func attack_while_moving() -> bool:
	# NPC can attack while moving if they have a melee weapon or can_attack_while_moving is true
	if can_attack_while_moving or not npc.weapon:
		return true
	return npc.velocity.length_squared() == 0


func attempt_attack():
	count_down = attack_duration
	# play the punching animation if no weapon is equipped
	if not npc.weapon:
		state_chart.send_event("ubody_attack")
		if npc.global_position.distance_to(target.global_position) <= 1.5:
			punch_attack(target)
	else:
		npc.sight_detection.check_if_player_in_los()
		npc.weapon.npc_do_attack(npc)


func punch_attack(target: Node3D):
	var dir = npc.global_position.direction_to(target.global_position)
	Audio.play_sound_3d(attack_sound).global_position = npc.global_position
	
	# Activate the collider for the attack
	attack_impact_zone.set_collision(true)
