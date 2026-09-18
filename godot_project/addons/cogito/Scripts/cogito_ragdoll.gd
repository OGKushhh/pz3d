extends Node3D
class_name CogitoRagdoll

## If you want ragdolls to be saved / loaded, set this to on.
@export var make_persistent : bool = true

var skeleton: Skeleton3D
var physical_bone_simulator_3d: PhysicalBoneSimulator3D
var cogito_ragdoll_skeleton_modifier: CogitoRagdollSkeletonModifier

var ragdoll_physical_bones: Array
var skeleton_bones_poses: Dictionary
var bones_poses_updated_data: Dictionary


func _ready() -> void:
	if make_persistent:
		self.add_to_group("Persist") #Adding object to group for persistence
	
	var skeletons: Array[Node] = find_children("", "Skeleton3D")
	if len(skeletons):
		skeleton = skeletons[0]
	
	skeleton.skeleton_updated.connect(_on_skeleton_ragdoll_skeleton_updated)
	
	var physical_bone_simulator_3ds: Array[Node] = find_children("", "PhysicalBoneSimulator3D")
	if len(physical_bone_simulator_3ds):
		physical_bone_simulator_3d = physical_bone_simulator_3ds[0]
	
	var cogito_ragdoll_skeleton_modifiers: Array[Node] = skeleton.find_children("", "CogitoRagdollSkeletonModifier")
	if len(cogito_ragdoll_skeleton_modifiers):
		cogito_ragdoll_skeleton_modifier = cogito_ragdoll_skeleton_modifiers[0]
		
	await get_tree().create_timer(0.05, false).timeout
	physical_bone_simulator_3d.active = true
	physical_bone_simulator_3d.physical_bones_start_simulation()


func _create_snapshot():
	ragdoll_physical_bones = []
	
	for bone in physical_bone_simulator_3d.get_children():
		if bone is PhysicalBone3D:
			ragdoll_physical_bones.append({
				"bone_name": bone.name,
				"transform": bone.transform,
				"linear_velocity": bone.linear_velocity,
				"angular_velocity": bone.angular_velocity,
				"can_sleep": bone.can_sleep,
			})
	
	skeleton_bones_poses = bones_poses_updated_data


func _load_snapshot() -> void:
	cogito_ragdoll_skeleton_modifier.load_bones_data(ragdoll_physical_bones, skeleton_bones_poses)


func set_state():
	_load_snapshot()


func save():
	_create_snapshot()
	
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		"ragdoll_physical_bones" : ragdoll_physical_bones,
		"skeleton_bones_poses" : skeleton_bones_poses,
	}
	return node_data


func _on_skeleton_ragdoll_skeleton_updated() -> void:
	if not skeleton:
		return
	
	for index in skeleton.get_bone_count():
		bones_poses_updated_data[index] = skeleton.get_bone_global_pose(index)
