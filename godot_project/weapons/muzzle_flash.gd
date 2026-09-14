# MuzzleFlash — one sprite, spawn + fade. ~20 lines.
#
# Phase: Gun System (2026-09-14)
# Per user spec: "Muzzle flash — one sprite, spawn + fade. 20 lines."
#
# Spawns a Sprite3D at the muzzle position, scales it, fades over FLASH_TIME,
# then frees itself. Uses an emissive material so it's visible in daylight.
class_name MuzzleFlash
extends Sprite3D

const FLASH_TIME := 0.05

var _elapsed: float = 0.0
var _material: StandardMaterial3D
var _base_scale: float

# Spawn a muzzle flash at position. Faces the camera (billboard).
static func spawn(parent: Node3D, pos: Vector3, scale: float) -> MuzzleFlash:
	var flash := MuzzleFlash.new()
	flash.position = pos
	flash._base_scale = scale
	flash.scale = Vector3(scale, scale, scale)
	# Create a simple white texture via a 16x16 placeholder (GradientTexture2D)
	var tex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 0.9, 0.5, 1))
	grad.set_color(1, Color(1, 0.5, 0.1, 0))
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	flash.texture = tex
	flash.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flash._material = StandardMaterial3D.new()
	flash._material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash._material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash._material.albedo_color = Color(1, 0.9, 0.5, 1)
	flash._material.emission_enabled = true
	flash._material.emission = Color(1, 0.8, 0.3, 1)
	flash._material.emission_energy_multiplier = 5.0
	flash.material_override = flash._material
	flash.no_depth_test = true
	parent.add_child(flash)
	return flash

func _process(delta: float) -> void:
	_elapsed += delta
	var alpha: float = 1.0 - (_elapsed / FLASH_TIME)
	if alpha <= 0.0:
		queue_free()
		return
	_material.albedo_color.a = alpha
	_material.emission_energy_multiplier = 5.0 * alpha
	# Shrink slightly as it fades
	var s := _base_scale * alpha
	scale = Vector3(s, s, s)
