extends SkeletonModifier3D
class_name CogitoRagdollSkeletonModifier

var skeleton: Skeleton3D
var physical_bone_simulator_3d: PhysicalBoneSimulator3D
var physical_bones = null
var bones_poses = null
var is_bones_poses_loaded: bool = false


func _ready() -> void:
	skeleton = get_skeleton()
	if not skeleton:
		return
	
	if not physical_bone_simulator_3d:
		var physical_bone_simulator_3ds: Array[Node] = skeleton.find_children("", "PhysicalBoneSimulator3D")
		if len(physical_bone_simulator_3ds):
			physical_bone_simulator_3d = physical_bone_simulator_3ds[0]


func _process_modification_with_delta(delta: float) -> void:
	if not skeleton:
		return
	
	if not is_bones_poses_loaded:
		return
		
	is_bones_poses_loaded = false
	
	if bones_poses:
		physical_bone_simulator_3d.physical_bones_stop_simulation()
		physical_bone_simulator_3d.active = false
		
		for index in bones_poses.keys():
			skeleton.set_bone_global_pose(index, bones_poses[index])
		
		physical_bone_simulator_3d.active = true
		physical_bone_simulator_3d.physical_bones_start_simulation()
		
		var bone_map := {}
		
		for bone in physical_bone_simulator_3d.get_children():
			if bone is PhysicalBone3D:
				bone_map[bone.name] = bone
		
		for data in physical_bones:
			var bone: PhysicalBone3D = bone_map.get(data["bone_name"])
			if bone:
				bone.transform = data["transform"]
				bone.linear_velocity = data["linear_velocity"]
				bone.angular_velocity = data["angular_velocity"]
				bone.can_sleep = data["can_sleep"]


func load_bones_data(physical_bones_data, bones_poses_data):
	physical_bones = physical_bones_data
	bones_poses = bones_poses_data
	active = true
	is_bones_poses_loaded = true
