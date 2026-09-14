# RecoilController — recoil kick + recovery. ~20 lines (recoil + recovery combined).
#
# Phase: Gun System (2026-09-14)
# Per user spec:
#   "Recoil kick — camera pitches up by N degrees per shot. 10 lines."
#   "Recovery — recoil decays toward 0 over time. 10 lines."
#
# Attached to the camera. Call add_recoil(pitch_deg, yaw_deg) on each shot.
# _process decays the accumulated recoil toward 0 at recovery_rate_deg per second.
# The camera's rotation is offset by the current recoil value each frame.
class_name RecoilController
extends Node3D

var _recoil_pitch: float = 0.0  # accumulated pitch (degrees)
var _recoil_yaw: float = 0.0   # accumulated yaw (degrees)
var _recovery_rate: float = 8.0  # degrees per second
var _camera: Camera3D

func _ready() -> void:
	_camera = get_parent() as Camera3D
	if _camera == null:
		# Walk up to find a Camera3D
		var p := get_parent()
		while p and not (p is Camera3D):
			p = p.get_parent()
		_camera = p as Camera3D

# Called by WeaponSystem on each shot. Adds to the accumulated recoil.
func add_recoil(pitch_deg: float, yaw_deg: float, recovery_rate: float) -> void:
	_recoil_pitch += pitch_deg
	_recoil_yaw += randf_range(-yaw_deg, yaw_deg)  # random yaw jitter
	_recovery_rate = recovery_rate

func _process(delta: float) -> void:
	# Decay recoil toward 0
	var decay: float = _recovery_rate * delta
	_recoil_pitch = move_toward(_recoil_pitch, 0.0, decay)
	_recoil_yaw = move_toward(_recoil_yaw, 0.0, decay)
	# Apply to camera (additive offset on top of player look rotation)
	if _camera:
		# NOTE: The player controller sets camera.rotation each frame from
		# mouse input. We apply recoil as an ADDITIVE offset AFTER the player
		# sets its rotation. To make this work without fighting the player
		# controller, we store recoil separately and the player controller
		# reads it via get_recoil_offset().
		pass

# Returns the current recoil offset (pitch, yaw) in degrees.
# The player controller should ADD this to its mouse-driven rotation.
func get_recoil_offset() -> Vector2:
	return Vector2(_recoil_pitch, _recoil_yaw)
