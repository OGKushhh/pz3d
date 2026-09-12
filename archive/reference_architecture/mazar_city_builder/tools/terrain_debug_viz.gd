# TerrainDebugViz — builds a heightmap-colored plane to visualize TerrainHeight.
#
# Creates a MeshInstance3D with a PlaneMesh subdivided into a grid.
# Each vertex is displaced to terrain Y and colored by height (blue=low, green=mid, red=high).
# Water areas (below Y=0) are colored dark blue.
#
# Add as autoload "TerrainDebugViz" in project.godot to see the heightmap at runtime.
# Toggle visibility with F3.
extends Node3D

const TerrainHeight := preload("res://tools/terrain_height.gd")
const RiverNetwork := preload("res://tools/river_network.gd")

var _mesh_inst: MeshInstance3D
var _terrain: TerrainHeight
var _visible: bool = false

func _ready() -> void:
	_terrain = TerrainHeight.new(1337, RiverNetwork.new())
	_build_mesh()
	_mesh_inst.visible = _visible
	print("[TerrainDebugViz] ready (toggle with F3, currently %s)" % ("visible" if _visible else "hidden"))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_visible = not _visible
		if _mesh_inst:
			_mesh_inst.visible = _visible
		print("[TerrainDebugViz] %s" % ("visible" if _visible else "hidden"))

func _build_mesh() -> void:
	# Build an ArrayMesh with vertex colors + displaced Y
	var grid_size := 100.0       # meters between samples
	var half_map_x := 2000.0     # half of MAP_SIZE_M.x (4000)
	var half_map_z := 1500.0     # half of MAP_SIZE_M.y (3000)
	var cols := int(half_map_x * 2 / grid_size) + 1
	var rows := int(half_map_z * 2 / grid_size) + 1

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for r in range(rows - 1):
		for c in range(cols - 1):
			var x0: float = -half_map_x + c * grid_size
			var x1: float = -half_map_x + (c + 1) * grid_size
			var z0: float = -half_map_z + r * grid_size
			var z1: float = -half_map_z + (r + 1) * grid_size

			# 4 corners of the quad
			var p00 := Vector3(x0, _terrain.height_at(x0, z0), z0)
			var p10 := Vector3(x1, _terrain.height_at(x1, z0), z0)
			var p11 := Vector3(x1, _terrain.height_at(x1, z1), z1)
			var p01 := Vector3(x0, _terrain.height_at(x0, z1), z1)

			# Colors based on height
			var c00 := _height_color(p00.y)
			var c10 := _height_color(p10.y)
			var c11 := _height_color(p11.y)
			var c01 := _height_color(p01.y)

			# Triangle 1: p00, p10, p11
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_color(c10)
			st.add_vertex(p10)
			st.set_color(c11)
			st.add_vertex(p11)

			# Triangle 2: p00, p11, p01
			st.set_color(c00)
			st.add_vertex(p00)
			st.set_color(c11)
			st.add_vertex(p11)
			st.set_color(c01)
			st.add_vertex(p01)

	st.index()
	st.generate_normals()

	var mesh := st.commit()
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "TerrainDebugMesh"
	_mesh_inst.mesh = mesh

	# Use a material that shows vertex colors
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # flat colors
	_mesh_inst.material_override = mat

	add_child(_mesh_inst)
	print("[TerrainDebugViz] mesh built: %d cols × %d rows" % [cols, rows])

func _height_color(y: float) -> Color:
	# Color gradient: deep blue (underwater) → blue (water) → green (low) → yellow (mid) → red (high)
	if y < -2.0:
		return Color(0.05, 0.05, 0.25)  # deep water (dark blue)
	elif y < 0.0:
		return Color(0.10, 0.30, 0.60)  # water (blue)
	elif y < 1.0:
		return Color(0.20, 0.50, 0.20)  # low land (dark green)
	elif y < 3.0:
		return Color(0.40, 0.65, 0.25)  # mid land (green)
	elif y < 5.0:
		return Color(0.70, 0.70, 0.30)  # hills (yellow-green)
	elif y < 8.0:
		return Color(0.80, 0.60, 0.25)  # high hills (orange)
	else:
		return Color(0.90, 0.50, 0.30)  # peaks (red-orange)
