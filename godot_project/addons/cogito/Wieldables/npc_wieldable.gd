## NPC Wieldable class. This extends the CogitoWieldable class but is built specifically for npc behaviours when wielding the weapon.
## This current implementation exists only for ranged weapons, can be extended to support melee weapons in future if needed.
extends CogitoWieldable
class_name NpcWieldable

## Determines what kind of ranged attack is performed when firing the weapon.
enum AttackType {
	## Fires a projectile towards the target
	Projectile,
	## If the target is visible, fires a ray at the target
	Hitscan
}

@export_group("NPC Wieldable Settings")
## Range of this NPC wieldable
@export var npc_wieldable_range : float = 15
## Damage of this NPC wieldable
@export var npc_wieldable_damage: float = 1
## Determines delay between shots aka fire rate.
@export var firing_delay : float = 0.2
## Determines what type of Attack is used
@export var attack_type: AttackType = AttackType.Hitscan
## Node for the projectile or hitscan origin
@onready var bullet_point: Node3D = %Bullet_Point

## Settings if Projectile is selected as Attack Type
@export_group("Projectile Settings")
## Path to the projectile prefab scene
@export var projectile_prefab : PackedScene
## Speed the projectile spawns with
@export var projectile_velocity : float = 80
## How many projectiles can exist as part of this wieldable before they begin to disappear/be-reused
@export_range(0, 1000) var pool_size : int = 0
var projectile_pool := []
var _last_index := -1

## Settings if Hitscan is selected as Attack Type
@export_group("Hitscan Settings")
## Prefab of weapon tracer
@export var tracer : PackedScene
## How long tracer lingers in the air
@export var tracer_lifespan : float = 5.0
## Prefab of bullet_decal
@export var bullet_decal_prefab : PackedScene

@export_group("Collisions")
## Spawn hit decal on Collision hit
@export var decal_spawn : bool = true
## Hit decal texture, if blank will be set to default bullet decal texture
@export var decal_texture : Texture2D
## Scene that spawns when a bullet of the weapon collides with anything. Used for impact vfx.
@export var collision_scene : PackedScene

@export_group("Audio")
@export var sound_primary_use : AudioStream
@export var sound_secondary_use : AudioStream
@export var sound_reload : AudioStream

var npc_wielding: bool = false
var spawn_node : Node
var is_firing : bool = false
var firing_cooldown : float
var wielding_rid : RID


func _ready():
	super._ready()
	wieldable_mesh.hide()
	firing_cooldown = 0
	wielding_rid = CogitoSceneManager._current_player_node.get_rid()
	if projectile_prefab:
		build_projectile_pool()


func _physics_process(_delta: float) -> void:
	if firing_cooldown > 0:
		firing_cooldown -= _delta


func can_npc_attack(attacking_npc: CogitoNPC) -> bool:
	if npc_wieldable_range <= 0.0:
		return true
	# Check the weapon range is within player distance
	var ref_to_player: CogitoPlayer = attacking_npc.sight_detection.ref_to_player
	if not ref_to_player:
		return false
	return not firing_cooldown > 0 and attacking_npc.global_position.distance_to(ref_to_player.global_position) <= npc_wieldable_range


func npc_do_attack(attacking_npc: CogitoNPC):
	if not can_npc_attack(attacking_npc):
		return
	
	# Set the spawn node point if it hasn't already been set, on player it sets on equip
	if not spawn_node:
		spawn_node = get_tree().get_current_scene()
	# Check that the RID has been re-assigned
	if wielding_rid != attacking_npc.get_rid():
		wielding_rid = attacking_npc.get_rid()
	
	var player_sight_collision_point = attacking_npc.sight_detection.player_sight_collision_point
	if player_sight_collision_point != Vector3.ZERO:
		if attack_type == AttackType.Hitscan:
			hit_scan_collision(player_sight_collision_point) #Do the hitscan
		else:
			fire_projectile(player_sight_collision_point)
		animation_player.play(anim_action_primary)
		if audio_stream_player_3d and sound_primary_use:
			audio_stream_player_3d.stream = sound_primary_use
			audio_stream_player_3d.play()
		firing_cooldown = firing_delay


## Overrides the existing action_primary, since no _passed_item_reference exists for NPCs
func action_primary(_passed_item_reference : InventoryItemPD, _is_released: bool):
	if _is_released:
		is_firing = false
	else:
		is_firing = true

## Secondary action is not necessary for NPCs since its usually a player action like ADS. Could be overriden if
## weapon has two weapon functions depending on scenario (like primary shoots bullets, secondary fires a grenade like an M16A4)
func action_secondary(is_released:bool):
	pass


#region Projectile Methods
func build_projectile_pool():
	projectile_pool.clear()
	for i in pool_size:
		projectile_pool.append(projectile_prefab.instantiate())


func get_projectile() -> CogitoProjectile:
	# Allow an unlimited pool size if you don't want projectiles to vanish
	if pool_size <= 0:
		return projectile_prefab.instantiate()
	# Cycle the index between `0` (included) and `pool_size` (excluded).
	_last_index = wrapi(_last_index + 1, 0, pool_size)
	return projectile_pool[_last_index]


func fire_projectile(collision_point:Vector3):
	var direction = (collision_point - bullet_point.get_global_transform().origin).normalized()
	
	# Spawning projectile
	var projectile = get_projectile()
	bullet_point.add_child(projectile)
	projectile.set_global_position(Vector3(bullet_point.global_position.x,bullet_point.global_position.y,bullet_point.global_position.z))
	projectile.global_transform.basis = bullet_point.global_transform.basis
	projectile.damage_amount = npc_wieldable_damage
	projectile.set_linear_velocity(direction * projectile_velocity)
	projectile.direction = direction
	projectile.reparent(get_tree().get_current_scene())
#endregion

#region Hitscan Methods
func hit_scan_collision(collision_point:Vector3):
	var bullet_direction = (collision_point - bullet_point.get_global_transform().origin).normalized()
	var new_intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, collision_point + bullet_direction * 2)
	new_intersection.exclude = [wielding_rid]
	
	var bullet_collision = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	# Spawning a laser ray
	var instantiated_ray = tracer.instantiate()
	instantiated_ray.draw_ray(bullet_point.get_global_transform().origin, collision_point)
	spawn_node.add_child(instantiated_ray)
	
	if bullet_collision:
		hit_scan_damage(bullet_collision.collider, bullet_direction, bullet_collision.position)
		
		if collision_scene !=null: # Spawning impact particle effects
			var spawned_impact_scene = collision_scene.instantiate()
			add_child(spawned_impact_scene)
			spawned_impact_scene.global_position = collision_point
		
		if decal_spawn == true:
			var bullet_collider = bullet_collision.collider
			var bullet_collision_position = bullet_collision.position
			var bullet_collision_normal = bullet_collision.normal
			var bullet_global_basis = bullet_point.get_global_transform().basis
			# Spawn bullet decal with collision parameters
			BulletDecalPool.spawn_bullet_decal(bullet_decal_prefab, bullet_collision_position, bullet_collision_normal, bullet_collider, bullet_global_basis,decal_texture)


func hit_scan_damage(collider, bullet_direction, bullet_position):
	if collider.has_signal("damage_received"):
		collider.damage_received.emit(npc_wieldable_damage, self, bullet_direction,bullet_position)
	elif collider is CogitoPlayer:
		var player = collider as CogitoPlayer
		player.decrease_attribute("health", npc_wieldable_damage)
#endregion
