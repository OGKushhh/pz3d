# WieldableHitscan — extends CogitoWieldable with hitscan firing.
#
# This is how we extend Cogito: we subclass their wieldable base and override
# action_primary() to do instant raycast (hitscan) instead of spawning projectiles.
#
# Pattern matches Cogito's own wieldable_laser_rifle.gd which also uses hitscan.
#
# Features ported from our weapon_system.gd:
#	- Per-weapon spread patterns (cyclic or random within cone)
#	- Tracer visual line (tracer.gd)
#	- Muzzle flash sprite (muzzle_flash.gd)
#	- Recoil controller (recoil_controller.gd)
#	- Multi-pellet support (shotgun = 8 raycasts)
#
# Ammo: reads from CogitoInventory via item_reference.charge_current
# Damage: from weapon_spreads.gd WEAPON_DATA
# Fire rate: enforced by animation_player (Cogito's pattern)

extends CogitoWieldable
class_name WieldableHitscan

const WeaponSpreads := preload("res://data/weapon_spreads.gd")
const Tracer := preload("res://weapons/tracer.gd")
const MuzzleFlash := preload("res://weapons/muzzle_flash.gd")
const RecoilController := preload("res://weapons/recoil_controller.gd")

@export_group("Hitscan Settings")
## Weapon class name — determines spread, damage, fire rate, tracer color
@export var weapon_class: String = "pistol"
## Node where tracer/flash spawns (usually the camera or a muzzle point)
@export var bullet_point: Node3D
## Scene root where tracers + flashes are spawned (world space, not camera space)
@export var world_root: Node3D

var _shot_index: int = 0
var _recoil: RecoilController
var _camera: Camera3D
var _weapon_data: Dictionary

func _ready() -> void:
		super._ready()
		_weapon_data = WeaponSpreads.get_weapon_data(weapon_class)
		# Find camera (CogitoPlayer has it at Body/Neck/Head/Eyes/Camera)
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
				# Walk up to find Camera3D
				var p := get_parent()
				while p and not (p is Camera3D):
						p = p.get_parent()
				_camera = p as Camera3D
		# Setup recoil controller as sibling of camera
		if _camera:
				_recoil = RecoilController.new()
				_recoil.name = "RecoilController"
				_camera.add_child(_recoil)
		# Find bullet_point if not assigned
		if bullet_point == null:
				bullet_point = _camera
		# Find world root
		if world_root == null:
				world_root = get_tree().current_scene
		print("[WieldableHitscan] ready: weapon=%s dmg=%d rate=%.1f spread=%.1f°" % [
				weapon_class,
				_weapon_data.get("damage", 0),
				_weapon_data.get("fire_rate", 1.0),
				_weapon_data.get("spread_deg", 0.0),
		])

func equip(_player_interaction_component: PlayerInteractionComponent) -> void:
		# Don't call super.equip() — it tries animation_player.play() which is null
		# when this wieldable is created via .new() (not from a scene).
		player_interaction_component = _player_interaction_component
		if animation_player:
				animation_player.play(anim_equip)
		print("[WieldableHitscan] equipped: %s" % weapon_class)

# Override action_primary — called by PlayerInteractionComponent on left click
func action_primary(_passed_item_reference: InventoryItemPD, _is_released: bool) -> void:
		if _is_released:
				return
		# Enforce fire rate via animation_player (Cogito's pattern)
		if animation_player and animation_player.is_playing():
				return
		# Check ammo via CogitoInventory
		if _passed_item_reference and _passed_item_reference.charge_current <= 0:
				_passed_item_reference.send_empty_hint()
				return
		# Consume ammo
		if _passed_item_reference:
				_passed_item_reference.subtract(1)
		# Play fire animation
		if animation_player:
				animation_player.play(anim_action_primary)
		# Play sound
		if audio_stream_player_3d and _weapon_data.get("sound_primary_use", null):
				audio_stream_player_3d.stream = _weapon_data["sound_primary_use"]
				audio_stream_player_3d.play()
		# Fire each pellet (shotgun = 8, others = 1)
		var pellets: int = int(_weapon_data.get("pellets_per_shot", 1))
		for i in range(pellets):
				_fire_single_pellet(i)
		# Add recoil
		if _recoil:
				_recoil.add_recoil(
						float(_weapon_data.get("recoil_pitch_deg", 0.0)),
						float(_weapon_data.get("recoil_yaw_deg", 0.0)),
						float(_weapon_data.get("recovery_rate_deg", 8.0))
				)
		_shot_index += 1

# Override action_secondary — ADS (aim down sights)
func action_secondary(_is_released: bool) -> void:
		if not _is_released:
				# Enter ADS — lower FOV, move viewmodel to center
				if _camera:
						var ads_fov: float = float(_weapon_data.get("ads_fov", 65.0))
						_camera.fov = lerp(_camera.fov, ads_fov, 0.3)
		else:
				# Exit ADS — restore FOV
				if _camera:
						_camera.fov = lerp(_camera.fov, 75.0, 0.3)

func _fire_single_pellet(pellet_index: int) -> void:
		if _camera == null:
				return
		# Compute ray origin + direction with spread
		var origin: Vector3 = _camera.global_position
		var forward: Vector3 = -_camera.global_transform.basis.z
		# Apply spread: cyclic pattern OR random within cone
		var spread_offset: Vector2 = Vector2.ZERO
		var pattern: Array = _weapon_data.get("spread_pattern", [])
		if not pattern.is_empty():
				spread_offset = WeaponSpreads.get_pattern_offset(weapon_class, _shot_index)
				if pellet_index > 0:
						# For shotguns: add random spread to each pellet on top of the pattern
						var spread_deg: float = float(_weapon_data.get("spread_deg", 0.0))
						spread_offset += Vector2(
								randf_range(-spread_deg, spread_deg),
								randf_range(-spread_deg, spread_deg)
						)
		else:
				var spread_deg: float = float(_weapon_data.get("spread_deg", 0.0))
				spread_offset = Vector2(
						randf_range(-spread_deg, spread_deg),
						randf_range(-spread_deg, spread_deg)
				)
		# Rotate the forward vector by spread offset (yaw = x, pitch = y)
		var dir: Vector3 = forward.rotated(_camera.global_transform.basis.x, deg_to_rad(spread_offset.y))
		dir = dir.rotated(_camera.global_transform.basis.y, deg_to_rad(spread_offset.x))
		dir = dir.normalized()
		var range_m: float = float(_weapon_data.get("range_m", 100.0))
		var end_pos: Vector3 = origin + dir * range_m
		# Hitscan raycast
		var space_state := _camera.get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(origin, end_pos)
		# Collision mask: world (1) + targets (4) = 5
		query.collision_mask = 5
		# Exclude player
		var exclude_rids: Array[RID] = []
		var node: Node = _camera
		while node:
				if node is CollisionObject3D:
						exclude_rids.append((node as CollisionObject3D).get_rid())
				node = node.get_parent()
				if node == world_root or node == null:
						break
		query.exclude = exclude_rids
		var result: Dictionary = space_state.intersect_ray(query)
		if result.size() > 0:
				end_pos = result["position"]
				var collider: Object = result["collider"]
				# Apply damage if collider has take_damage method
				if collider.has_method("take_damage"):
						collider.take_damage(int(_weapon_data.get("damage", 0)))
				# Also check for Cogito's HitboxComponent
				if collider.has_method("_on_hit"):
						collider._on_hit(int(_weapon_data.get("damage", 0)), dir)
		# Spawn tracer
		var tracer_color: Color = _weapon_data.get("tracer_color", Color(1, 0.8, 0.3, 1))
		var tracer_width: float = float(_weapon_data.get("tracer_width", 0.03))
		var muzzle_pos: Vector3 = origin + forward * 0.5
		if bullet_point:
				muzzle_pos = bullet_point.global_position
		Tracer.spawn(world_root, muzzle_pos, end_pos, tracer_color, tracer_width)
		# Spawn muzzle flash
		var flash_scale: float = float(_weapon_data.get("muzzle_flash_scale", 0.5))
		MuzzleFlash.spawn(world_root, muzzle_pos, flash_scale)

# Returns recoil offset for player controller to add to camera rotation
func get_recoil_offset() -> Vector2:
		if _recoil:
				return _recoil.get_recoil_offset()
		return Vector2.ZERO
