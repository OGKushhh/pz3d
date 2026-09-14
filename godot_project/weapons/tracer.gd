# Tracer — visual bullet tracer line that fades over 0.1s.
#
# Phase: Gun System (2026-09-14)
# Per user spec: "Tracer line — a thin quad that fades over 0.1s. 30 lines."
#
# Spawns a thin quad mesh from start to end, fades its alpha from 1.0 to 0.0
# over FADE_TIME seconds, then frees itself. Uses StandardMaterial3D with
# transparency enabled.
class_name Tracer
extends MeshInstance3D

const FADE_TIME := 0.1

var _elapsed: float = 0.0
var _material: StandardMaterial3D
var _start: Vector3
var _end: Vector3

# Spawn a tracer in the world. Static method — call Tracer.spawn(...) directly.
static func spawn(parent: Node3D, start: Vector3, end: Vector3, color: Color, width: float) -> Tracer:
        var tracer := Tracer.new()
        tracer._start = start
        tracer._end = end
        var length := start.distance_to(end)
        var mid := (start + end) * 0.5
        var dir := (end - start).normalized()
        var yaw := atan2(dir.x, dir.z)
        var p := PlaneMesh.new()
        p.size = Vector2(width, length)
        tracer.mesh = p
        tracer.position = mid
        tracer.rotation.y = yaw
        tracer._material = StandardMaterial3D.new()
        tracer._material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        tracer._material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        tracer._material.albedo_color = color
        tracer._material.emission_enabled = true
        tracer._material.emission = color
        tracer._material.emission_energy_multiplier = 2.0
        tracer.material_override = tracer._material
        parent.add_child(tracer)
        return tracer

func _process(delta: float) -> void:
        _elapsed += delta
        var alpha: float = 1.0 - (_elapsed / FADE_TIME)
        if alpha <= 0.0:
                queue_free()
                return
        _material.albedo_color.a = alpha
        _material.emission_energy_multiplier = 2.0 * alpha
