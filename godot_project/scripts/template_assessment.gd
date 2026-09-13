extends Node3D

# TemplateAssessment — stamps ALL 3 hand-authored district templates side by
# side at fixed positions so the user can walk between them and assess each
# one's layout, asset picks, prop density, and visual feel.
#
# Phase A.7 assessment tool (2026-09-13). Not the main game scene — this is
# a debugging/evaluation scene. Open in Godot editor or run via F5.
#
# Layout (top-down):
#
#   suburb_block        commercial_strip      downtown_block
#   at (-300, 0, 0)     at (0, 0, 0)         at (300, 0, 0)
#
#   ↑ north (z = -300)
#   |
#   |  Player spawns at (0, 5, -200) looking south
#   |
#   ↓ south (z = +300)
#
# Each template stamps with a fixed seed (deterministic) so the user can
# re-run and see the same result. Press F5 to play, walk between templates.
#
# F1 = print template positions to console (for debugging)
# F2 = re-stamp templates with a new random seed
# F3 = toggle already-placed templates' visibility (compare layouts)

const DistrictStamper := preload("res://tools/district_stamper.gd")
const CityConfig := preload("res://tools/city_config.gd")
const DistrictTemplates := preload("res://data/district_templates.gd")

var _stamper: DistrictStamper
var _manifest: Dictionary = {}
var _asset_cache: Dictionary = {}
var _template_roots: Dictionary = {}  # name → Node3D root

# Spacing between templates (300m gap so they don't overlap visually)
const TEMPLATE_SPACING := 300.0
const PLAYER_SPAWN := Vector3(0, 5, -250)

# Fixed seed for deterministic assessment (user can press F2 to re-roll)
const ASSESSMENT_SEED := 42

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_stamper = DistrictStamper.new()
	_load_manifest()
	_stamp_all_templates(ASSESSMENT_SEED)
	print("[TemplateAssessment] ready. Player at %s. Press F1 for positions, F2 to re-stamp, F3 to toggle visibility." % PLAYER_SPAWN)

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_F1:
				_print_template_positions()
			KEY_F2:
				_restamp_with_new_seed()
			KEY_F3:
				_toggle_visibility()
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _load_manifest() -> void:
	var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
	if f:
		_manifest = JSON.parse_string(f.get_as_text())
	print("[TemplateAssessment] manifest: %d assets" % _manifest.size())

# Public method so the stamper can access the asset cache (same API as chunk_streamer)
func _get_asset(p_name: String) -> PackedScene:
	if _asset_cache.has(p_name):
		return _asset_cache[p_name]
	if not _manifest.has(p_name):
		return null
	var s: PackedScene = load(_manifest[p_name]["path"]) as PackedScene
	_asset_cache[p_name] = s
	return s

# Public method so the stamper can attach collision (same as chunk_streamer)
func _attach_building_collision(building_inst: Node3D) -> void:
	var mesh_count := 0
	for child in building_inst.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child
		mi.create_trimesh_collision()
		mesh_count += 1
	if mesh_count > 0:
		building_inst.set_meta("has_collision", true)

func _stamp_all_templates(seed: int) -> void:
	# Clear any existing template roots
	for root in _template_roots.values():
		root.queue_free()
	_template_roots.clear()

	var crng := RandomNumberGenerator.new()
	crng.seed = seed

	# Stamp each template at a fixed position, no rotation
	var positions := {
		"suburb_block": Vector3(-TEMPLATE_SPACING, 0, 0),
		"commercial_strip": Vector3(0, 0, 0),
		"downtown_block": Vector3(TEMPLATE_SPACING, 0, 0),
	}

	for template_name in positions:
		var root := Node3D.new()
		root.name = "Template_%s" % template_name
		root.position = positions[template_name]
		add_child(root)
		_template_roots[template_name] = root

		var placed: int = _stamper.stamp_template(
			template_name,
			positions[template_name],
			0.0,  # no rotation — face north for assessment
			root,
			crng,
			self
		)
		print("[TemplateAssessment] '%s' stamped at %s: %d nodes" % [
			template_name, positions[template_name], placed
		])

	# Also stamp ground planes under each template so the user can see the
	# template footprint clearly
	for template_name in positions:
		var root: Node3D = _template_roots[template_name]
		_add_ground_plane(root, "AssessmentGround", Vector2(160, 160), Color(0.4, 0.35, 0.3))

	# Add a sign post at each template's center showing the template name
	# (just print to console — actual signs would need a font asset)
	for template_name in positions:
		var root: Node3D = _template_roots[template_name]
		print("[TemplateAssessment] %s at world %s (local origin)" % [template_name, root.global_position])

func _add_ground_plane(parent: Node3D, name: String, size: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = name
	var p := PlaneMesh.new()
	p.size = size
	mi.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mi.material_override = mat
	mi.position = Vector3(0, 0.01, 0)  # slightly above y=0 to avoid z-fighting
	parent.add_child(mi)

func _print_template_positions() -> void:
	print("=== Template Positions ===")
	for name in _template_roots:
		var root: Node3D = _template_roots[name]
		var child_count: int = root.get_child_count()
		print("  %s: world pos %s, %d children" % [name, root.global_position, child_count])

func _restamp_with_new_seed() -> void:
	var new_seed := randi() % 100000
	print("[TemplateAssessment] re-stamping with seed %d" % new_seed)
	_stamp_all_templates(new_seed)

func _toggle_visibility() -> void:
	for root in _template_roots.values():
		root.visible = not root.visible
	print("[TemplateAssessment] visibility toggled")
