extends StateProcessor

@export var animation_tree: AnimationTree

var upper_body_state: AnimationNodeStateMachinePlayback

func _on_walking_state_physics_processing(delta: float) -> void:
	var relative_velocity = npc.global_basis.inverse() * ((npc.velocity * Vector3(0.5,0,0.5)) / npc.walk_speed)
	set_animation_ready(relative_velocity)
	
func _on_running_state_physics_processing(delta: float) -> void:
	var relative_velocity = npc.global_basis.inverse() * ((npc.velocity * Vector3(1,0,1)) / npc.sprint_speed)
	set_animation_ready(relative_velocity)

func set_animation_ready(relative_velocity):
	var rel_velocity_xz = Vector2(relative_velocity.x, -relative_velocity.z)
	npc.velocity_debug_shape.position = relative_velocity
	if rel_velocity_xz.length_squared() > 0:
		animation_tree.set("parameters/Movement/blend_position", rel_velocity_xz)
	else:
		animation_tree.set("parameters/Movement/blend_position", Vector2.ZERO)

## Upper body posture
func _on_neutral_state_entered() -> void:
	upper_body_travel("Neutral")
	var weapon = npc.weapon
	if weapon:
		weapon.wieldable_mesh.hide()


func _on_raised_weapon_state_entered() -> void:
	var weapon = npc.weapon
	if weapon:
		weapon.animation_player.play(weapon.anim_equip)
		weapon.wieldable_mesh.show()
		upper_body_travel("PistolReady")
	else:
		upper_body_travel("RaisedFists")


func _on_attack_state_entered() -> void:
	animation_tree.set("parameters/UpperBodyState/RaisedFists/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_attack_state_physics_processing(delta: float) -> void:
	var is_attack_active = animation_tree.get("parameters/UpperBodyState/RaisedFists/attack/active")
	if !is_attack_active:
		state_chart.send_event("ubody_raise_weapon")


func upper_body_travel(state: String):
	upper_body_state = animation_tree.get("parameters/UpperBodyState/playback")
	if upper_body_state.get_current_node() != state:
		upper_body_state.travel(state)
