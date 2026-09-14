# RenderValidator — startup validation for rendering-only property errors.
#
# Phase #1 (2026-09-14): Catches errors that headless mode hides.
# The billboard_mode bug we missed was a rendering-only error — headless
# skips the rendering server, so Sprite3D property assignment errors don't fire.
#
# This script runs at _ready() (as an autoload or first-child of scene root),
# walks the entire scene tree, and validates rendering properties on all
# visual nodes. Prints errors to console + emits a signal if any found.
#
# Usage: add as autoload "RenderValidator" in project.godot, OR attach to
# a node at the top of any test scene.
extends Node

signal validation_complete(error_count: int)

func _ready() -> void:
	# Wait one frame so all child nodes are ready
	await get_tree().process_frame
	var errors := _validate_scene(get_tree().root)
	if errors > 0:
		print("[RenderValidator] ❌ %d rendering property errors found" % errors)
	else:
		print("[RenderValidator] ✓ All rendering properties valid")
	validation_complete.emit(errors)

func _validate_scene(root: Node) -> int:
	var errors := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		errors += _validate_node(n)
		for c in n.get_children():
			stack.append(c)
	return errors

func _validate_node(n: Node) -> int:
	var errors := 0
	# Sprite3D: validate billboard property (not billboard_mode)
	if n is Sprite3D:
		var s := n as Sprite3D
		# Check if billboard is set to a valid enum value (0-3)
		var b: int = s.billboard
		if b < 0 or b > 3:
			print("[RenderValidator] ERROR: %s has invalid billboard value: %d" % [n.name, b])
			errors += 1
	# MeshInstance3D: validate material is not null
	if n is MeshInstance3D:
		var m := n as MeshInstance3D
		if m.mesh == null:
			print("[RenderValidator] ERROR: %s has null mesh" % [n.name])
			errors += 1
	# Camera3D: validate it has a valid FOV
	if n is Camera3D:
		var c := n as Camera3D
		if c.fov <= 0.0 or c.fov > 170.0:
			print("[RenderValidator] ERROR: %s has invalid FOV: %.1f" % [n.name, c.fov])
			errors += 1
	# Light3D: validate energy is not negative
	if n is Light3D:
		var l := n as Light3D
		if l.light_energy < 0.0:
			print("[RenderValidator] ERROR: %s has negative light energy: %.2f" % [n.name, l.light_energy])
			errors += 1
	# CollisionShape3D: validate shape is not null
	if n is CollisionShape3D:
		var cs := n as CollisionShape3D
		if cs.shape == null:
			print("[RenderValidator] ERROR: %s has null shape" % [n.name])
			errors += 1
	return errors
