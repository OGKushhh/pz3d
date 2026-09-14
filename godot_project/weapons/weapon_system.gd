# WeaponSystem — ties together hitscan, tracer, recoil, spread, muzzle flash.
#
# Phase: Gun System (2026-09-14)
#
# Attach to the player's camera (or a child of it). Handles:
#   - Fire input (mouse button)
#   - Fire rate limiting
#   - Hitscan raycast with spread
#   - Tracer line spawn
#   - Muzzle flash spawn
#   - Recoil kick to RecoilController
#
# Usage:
#   weapon_system.equip("pistol")  # switch weapon
#   weapon_system.fire()           # called by player input on mouse click
class_name WeaponSystem
extends Node3D

const WeaponSpreads := preload("res://data/weapon_spreads.gd")
const Tracer := preload("res://weapons/tracer.gd")
const MuzzleFlash := preload("res://weapons/muzzle_flash.gd")
const RecoilController := preload("res://weapons/recoil_controller.gd")

var _weapon_class: String = "pistol"
var _weapon_data: Dictionary = {}
var _cooldown_timer: Timer
var _shot_index: int = 0
var _camera: Camera3D
var _recoil: RecoilController
var _world_root: Node3D  # where tracers + flashes are spawned

# Equip a weapon by class name ("pistol", "rifle", "shotgun", "sniper_rifle")
func equip(weapon_class: String) -> void:
        _weapon_class = weapon_class
        _weapon_data = WeaponSpreads.get_weapon_data(weapon_class)
        _shot_index = 0
        # Phase #2: update cooldown timer to match new weapon's fire rate
        if _cooldown_timer and not _weapon_data.is_empty():
                var fire_rate: float = float(_weapon_data.get("fire_rate", 1.0))
                _cooldown_timer.wait_time = 1.0 / fire_rate
        print("[WeaponSystem] equipped: %s (dmg=%d, rate=%.1f, spread=%.1f°)" % [
                weapon_class,
                _weapon_data.get("damage", 0),
                _weapon_data.get("fire_rate", 1.0),
                _weapon_data.get("spread_deg", 0.0),
        ])

# Set the world root where tracers + muzzle flashes are spawned (should be the
# chunk root or the main scene root — NOT the camera, so they persist in world space)
func set_world_root(root: Node3D) -> void:
        _world_root = root

func _ready() -> void:
        _camera = get_parent() as Camera3D
        if _camera == null:
                var p := get_parent()
                while p and not (p is Camera3D):
                        p = p.get_parent()
                _camera = p as Camera3D
        if _camera == null:
                push_error("[WeaponSystem] no Camera3D found in parents")
        # Setup recoil controller as sibling of camera (or child of camera)
        _recoil = RecoilController.new()
        _recoil.name = "RecoilController"
        if _camera:
                _camera.add_child(_recoil)
        if _world_root == null:
                # Default to the scene root
                _world_root = get_tree().current_scene
        # Phase #2: create cooldown timer (replaces Time.get_ticks_msec() math)
        _cooldown_timer = Timer.new()
        _cooldown_timer.name = "CooldownTimer"
        _cooldown_timer.one_shot = false
        _cooldown_timer.wait_time = 0.2  # default; updated on equip()
        add_child(_cooldown_timer)

# Try to fire. Returns true if a shot was fired, false if rate-limited or no data.
# Phase #2: uses Timer (one_shot=false, but stopped/started on fire) for rate limiting.
# Tests can read _cooldown_timer.wait_time to verify fire_rate, and await its timeout.
func fire() -> bool:
        if _weapon_data.is_empty():
                return false
        # Rate-limit via timer: if timer is running, we're in cooldown
        if not _cooldown_timer.is_stopped():
                return false
        # Start cooldown timer for next shot
        _cooldown_timer.start()
        # Fire each pellet (shotgun = 8, others = 1)
        var pellets: int = int(_weapon_data.get("pellets_per_shot", 1))
        for i in range(pellets):
                _fire_single_pellet(i)
        # Add recoil
        _recoil.add_recoil(
                float(_weapon_data.get("recoil_pitch_deg", 0.0)),
                float(_weapon_data.get("recoil_yaw_deg", 0.0)),
                float(_weapon_data.get("recovery_rate_deg", 8.0))
        )
        return true

func _fire_single_pellet(pellet_index: int) -> void:
        if _camera == null:
                return
        # Compute ray origin + direction with spread
        var origin: Vector3 = _camera.global_position
        var forward: Vector3 = -_camera.global_transform.basis.z  # camera looks down -Z
        # Apply spread: cyclic pattern OR random within cone
        var spread_offset: Vector2 = Vector2.ZERO
        var pattern: Array = _weapon_data.get("spread_pattern", [])
        if not pattern.is_empty():
                # Cyclic pattern for this weapon
                spread_offset = WeaponSpreads.get_pattern_offset(_weapon_class, _shot_index)
                if pellet_index > 0:
                        # For shotguns: add random spread to each pellet on top of the pattern
                        var spread_deg: float = float(_weapon_data.get("spread_deg", 0.0))
                        spread_offset += Vector2(
                                randf_range(-spread_deg, spread_deg),
                                randf_range(-spread_deg, spread_deg)
                        )
        else:
                # Random within cone
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
        # Phase: Gun System fix — Camera3D is NOT a CollisionObject3D, so it has no
        # get_rid(). Only exclude CollisionObject3D ancestors (player CharacterBody3D).
        var space_state := _camera.get_world_3d().direct_space_state
        var query := PhysicsRayQueryParameters3D.create(origin, end_pos)
        # Build exclude list from CollisionObject3D ancestors of the camera
        var exclude_rids: Array[RID] = []
        var node: Node = _camera
        while node:
                if node is CollisionObject3D:
                        exclude_rids.append((node as CollisionObject3D).get_rid())
                node = node.get_parent()
                if node == _world_root or node == null:
                        break
        query.exclude = exclude_rids
        var result: Dictionary = space_state.intersect_ray(query)
        if result.size() > 0:
                end_pos = result["position"]
                var collider: Object = result["collider"]
                if collider.has_method("take_damage"):
                        collider.take_damage(int(_weapon_data.get("damage", 0)))
        # Spawn tracer
        var tracer_color: Color = _weapon_data.get("tracer_color", Color(1, 0.8, 0.3, 1))
        var tracer_width: float = float(_weapon_data.get("tracer_width", 0.03))
        # Muzzle position = slightly in front of camera
        var muzzle_pos: Vector3 = origin + forward * 0.5
        Tracer.spawn(_world_root, muzzle_pos, end_pos, tracer_color, tracer_width)
        # Spawn muzzle flash
        var flash_scale: float = float(_weapon_data.get("muzzle_flash_scale", 0.5))
        MuzzleFlash.spawn(_world_root, muzzle_pos, flash_scale)
        _shot_index += 1

# Called every frame by player controller to read recoil offset (for camera)
func get_recoil_offset() -> Vector2:
        if _recoil:
                return _recoil.get_recoil_offset()
        return Vector2.ZERO
