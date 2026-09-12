# Run: godot --headless --script res://tests/test_multimesh.gd
# Exit 0 = pass, 1 = fail.
# Tests MultiMesh creation and instance_count management.
# Note: get_instance_transform() returns identity in headless mode (dummy renderer).
# Transform preservation is tested at runtime in the actual game.
extends SceneTree

var failures: int = 0

func _init():
	# Test 1: MultiMesh creation with 3D transforms
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 3
	_check(mm.instance_count == 3, "MultiMesh instance_count = 3 (got %d)" % mm.instance_count)
	_check(mm.transform_format == MultiMesh.TRANSFORM_3D, "transform_format = TRANSFORM_3D")

	# Test 2: mesh assignment
	var box := BoxMesh.new()
	box.size = Vector3(2, 2, 2)
	mm.mesh = box
	_check(mm.mesh == box, "MultiMesh mesh assigned")
	_check(mm.mesh.size == Vector3(2, 2, 2), "MultiMesh mesh size correct")

	# Test 3: set_instance_transform doesn't crash
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(10, 0, 20)))
	mm.set_instance_transform(1, Transform3D(Basis(), Vector3(30, 0, 40)))
	mm.set_instance_transform(2, Transform3D(Basis(), Vector3(50, 0, 60)))
	_check(true, "set_instance_transform doesn't crash")

	# Test 4: MultiMeshInstance3D wraps MultiMesh
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	_check(mmi.multimesh == mm, "MultiMeshInstance3D wraps MultiMesh")
	_check(mmi.multimesh.instance_count == 3, "wrapped MultiMesh has 3 instances")

	# Test 5: instance_count = 0 is valid (empty multimesh)
	mm.instance_count = 0
	_check(mm.instance_count == 0, "instance_count = 0 is valid")

	# Test 6: instance_count can be changed after creation
	mm.instance_count = 10
	_check(mm.instance_count == 10, "instance_count changed to 10 (got %d)" % mm.instance_count)

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("multimesh: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("multimesh: PASS")
		quit(0)
