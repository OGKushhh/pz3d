extends Area3D
class_name ObjectNoise

## What type of noise has been made, affects NPC AI
enum NoiseType {
	## Will alert the NPC to the impact location but not draw suspicion
	Impact,
	## Builds up suspicion in the NPCs hearing indicator
	Footstep
}

## Determines if a debug shape should appear on noise spawn
var spawn_debug_shape: bool
## The size of the noise sphere in metres
var magnitude: float
## The duration of the noise, allowing a passing npc to walk into it if long enough
var noise_duration: float
## The type of noise (Footstep or Impact)
var noise_type: NoiseType

var collider: CollisionShape3D
var debug_mesh: MeshInstance3D

func _init(spawn_debug_shape: bool):
	self.spawn_debug_shape = spawn_debug_shape


func _ready() -> void:
	collider = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = magnitude
	collider.shape = sphere
	self.set_collision_layer_value(1, false)
	self.set_collision_layer_value(10, true)
	add_child(collider)
	
	if spawn_debug_shape:
		debug_mesh = MeshInstance3D.new()
		debug_mesh.mesh = SphereMesh.new()
		debug_mesh.mesh.radius = magnitude
		debug_mesh.mesh.height = magnitude*2
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1,0,0,0.5)
		debug_mesh.material_override = mat
		add_child(debug_mesh)
		
	fire_off_noise()


## Sets the parameters of the noise like type, size, duration and audio layer.
func set_parameters(noise_type: NoiseType, noise_size: float, noise_duration: float, noise_layer: int):
	self.noise_type = noise_type
	self.magnitude = noise_size
	self.noise_duration = noise_duration
	self.set_collision_layer(noise_layer)


## Creates a one-shot tween that creates an expanding sphere. If spawn_debug_shape is enabled, it will appear to the player.
func fire_off_noise():
	var tween = create_tween()
	if debug_mesh:
		tween.tween_property(debug_mesh, "material_override:albedo_color", Color(1,0,0,0), noise_duration)
		
	tween.tween_callback(func(): self.queue_free())
	pass
