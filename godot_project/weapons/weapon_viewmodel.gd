# WeaponViewModel — shows the actual weapon model in first person.
#
# Attach as child of camera. Instantiates the correct GLB based on weapon class.
# Position: bottom-right of screen (typical FPS viewmodel position).
#
# Weapon class → model mapping:
#   pistol        → ZC57_Rigged (compact pistol)
#   rifle         → MGP7_Rigged (machine gun / rifle)
#   shotgun       → MGP7_Rigged (no shotgun in PPS pack, reuse rifle)
#   sniper_rifle  → MGP7_Rigged + OpticV1 attachment (scoped rifle)
#
# Attachments (optional, per weapon):
#   pistol: HandleV1, OpticV1, SuppressorV1
#   rifle: HandleV1, OpticV1, SuppressorV1
#
# All PPS models rigged — bones available for future animations (reload, etc.)

extends Node3D

# Weapon model paths
const WEAPON_MODELS := {
	"pistol": "res://assets/weapons/pps/GLB/Guns/ZC57/ZC57_Rigged.glb",
	"rifle": "res://assets/weapons/pps/GLB/Guns/MGP7/MGP7_Rigged.glb",
	"shotgun": "res://assets/weapons/pps/GLB/Guns/MGP7/MGP7_Rigged.glb",
	"sniper_rifle": "res://assets/weapons/pps/GLB/Guns/MGP7/MGP7_Rigged.glb",
}

# Attachment paths (per weapon)
const WEAPON_ATTACHMENTS := {
	"pistol": [
		"res://assets/weapons/pps/GLB/Guns/ZC57/ZC57 Attachments/ZC57_Attachment_OpticV1.glb",
	],
	"rifle": [
		"res://assets/weapons/pps/GLB/Guns/MGP7/MGP7 Attachments/MGP7_Attachment_SuppressorV1.glb",
	],
	"shotgun": [],
	"sniper_rifle": [
		"res://assets/weapons/pps/GLB/Guns/MGP7/MGP7 Attachments/MGP7_Attachment_OpticV1.glb",
		"res://assets/weapons/pps/GLB/Guns/Attachments - Universal/Attachment_OpticV1.glb",
	],
}

# Viewmodel position (bottom-right of screen, typical FPS)
const VIEWMODEL_POS := Vector3(0.35, -0.35, -0.6)
const VIEWMODEL_ROT := Vector3(deg_to_rad(-2), deg_to_rad(5), 0)

var _current_model: Node3D = null
var _current_attachments: Array[Node3D] = []
var _current_weapon: String = ""

func _ready():
	# Position the viewmodel in front of camera
	position = VIEWMODEL_POS
	rotation = VIEWMODEL_ROT
	# Equip default weapon
	equip("pistol")

# Equip a weapon by class name. Loads the model + attachments.
func equip(weapon_class: String) -> void:
	if weapon_class == _current_weapon:
		return
	# Clear current model + attachments
	_clear_current()
	# Load new model
	var path: String = WEAPON_MODELS.get(weapon_class, "")
	if path == "":
		push_warning("[WeaponViewModel] no model for weapon: %s" % weapon_class)
		return
	if not ResourceLoader.exists(path):
		push_warning("[WeaponViewModel] model not found: %s" % path)
		return
	var scene := load(path) as PackedScene
	if scene == null:
		push_warning("[WeaponViewModel] failed to load: %s" % path)
		return
	_current_model = scene.instantiate()
	_current_model.name = "WeaponModel_" + weapon_class
	add_child(_current_model)
	# Load attachments
	var attachments: Array = WEAPON_ATTACHMENTS.get(weapon_class, [])
	for att_path in attachments:
		if ResourceLoader.exists(att_path):
			var att_scene := load(att_path) as PackedScene
			if att_scene:
				var att_inst := att_scene.instantiate()
				att_inst.name = "Attachment_" + att_path.get_file().get_basename()
				_current_model.add_child(att_inst)
				_current_attachments.append(att_inst)
	_current_weapon = weapon_class
	print("[WeaponViewModel] equipped: %s (model + %d attachments)" % [weapon_class, _current_attachments.size()])

func _clear_current() -> void:
	if _current_model:
		_current_model.queue_free()
		_current_model = null
	_current_attachments.clear()
