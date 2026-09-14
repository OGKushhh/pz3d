extends StaticBody3D

# Simple test target for shooting range. Changes color when hit.
# Has take_damage() so WeaponSystem can call it on raycast hit.

var _hit_count: int = 0
var _mesh: MeshInstance3D
var _original_color: Color

func _ready() -> void:
	# Create a simple box mesh if no mesh exists
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 2, 0.3)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.3, 0.3, 1)  # red
	_original_color = mat.albedo_color
	_mesh.material_override = mat
	add_child(_mesh)
	# Add collision shape
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2, 0.3)
	col.shape = shape
	add_child(col)
	set_meta("shootable", true)

func take_damage(amount: int) -> void:
	_hit_count += amount
	var mat := _mesh.material_override as StandardMaterial3D
	if mat:
		# Flash white on hit, then return to red
		mat.albedo_color = Color(1, 1, 1, 1)
		# Reset color after 0.1s via a one-shot timer
		var timer := Timer.new()
		timer.wait_time = 0.1
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func(): mat.albedo_color = _original_color; timer.queue_free())
		timer.start()
	print("[Target] hit! damage=%d, total=%d" % [amount, _hit_count])
