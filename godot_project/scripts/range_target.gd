extends StaticBody3D

# Arcade-style pop-up target. Color-coded by distance:
#   Red = 15m (close, easy) — 10 points
#   Yellow = 25m (medium) — 25 points
#   Blue = 30m (far, harder) — 50 points
#
# On hit: flashes white, plays a "pop" animation (scale down + back up),
# increments score, then resets after 0.5s so you can shoot it again.
# Different materials assigned per target based on its name.

var _hit_count: int = 0
var _score: int = 0
var _mesh: MeshInstance3D
var _original_color: Color
var _base_scale: Vector3 = Vector3(1, 1, 1)
var _pop_timer: float = 0.0
var _is_popping: bool = false

func _ready() -> void:
	# Determine target type by name → color + score
	var mat := StandardMaterial3D.new()
	if name.begins_with("TargetRed"):
		mat.albedo_color = Color(0.95, 0.2, 0.2, 1)
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.2, 0.2, 1)
		mat.emission_energy_multiplier = 0.4
		_score = 10
	elif name.begins_with("TargetYellow"):
		mat.albedo_color = Color(0.95, 0.85, 0.1, 1)
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.85, 0.1, 1)
		mat.emission_energy_multiplier = 0.4
		_score = 25
	elif name.begins_with("TargetBlue"):
		mat.albedo_color = Color(0.1, 0.5, 0.95, 1)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.5, 0.95, 1)
		mat.emission_energy_multiplier = 0.4
		_score = 50
	else:
		mat.albedo_color = Color(0.8, 0.8, 0.8, 1)
		_score = 5
	mat.roughness = 0.4
	mat.metallic = 0.2
	_original_color = mat.albedo_color
	# Create box mesh (arcade target shape — 1.5m × 1.5m)
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 1.5, 0.25)
	_mesh.mesh = box
	_mesh.material_override = mat
	add_child(_mesh)
	# Add collision
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 0.25)
	col.shape = shape
	add_child(col)
	# Center ring (smaller box, white) — bullseye visual
	var ring := MeshInstance3D.new()
	var ring_box := BoxMesh.new()
	ring_box.size = Vector3(0.5, 0.5, 0.26)
	ring.mesh = ring_box
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1, 1, 1, 1)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1, 1, 1, 1)
	ring_mat.emission_energy_multiplier = 0.5
	ring_mat.roughness = 0.3
	ring.material_override = ring_mat
	add_child(ring)
	set_meta("shootable", true)
	set_meta("target_score", _score)

func take_damage(amount: int) -> void:
	_hit_count += 1
	_score += 1
	# Flash white + pop animation
	var mat := _mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(1, 1, 1, 1)
		mat.emission_energy_multiplier = 2.0
	# Start pop animation
	_is_popping = true
	_pop_timer = 0.0
	print("[Target] %s HIT! damage=%d, hits=%d" % [name, amount, _hit_count])

func _process(delta: float) -> void:
	if _is_popping:
		_pop_timer += delta
		var t := _pop_timer / 0.3  # 0.3s pop duration
		if t >= 1.0:
			_is_popping = false
			scale = _base_scale
			var mat := _mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = _original_color
				mat.emission_energy_multiplier = 0.4
		else:
			# Pop: scale up quickly then back down (bouncy)
			var s := 1.0 + sin(t * PI) * 0.3
			scale = Vector3(s, s, s)
