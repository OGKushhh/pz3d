extends Area3D
class_name ImpactZone

## How much damage to apply to the target on impact
@export var damage_on_impact: int
## Impact sound from the hit
@export var impact_sound: AudioStream
## Allows the damage zone to handle the logic of detecting bodies/areas and applying damage.
## If enabled, would recommend creating a subclass and overriding the _outgoing_body_entered and _outgoing_area_entered functions.
@export var outgoing: bool = false

func _ready() -> void:
	set_collision(false)
	if outgoing:
		monitoring = true
		body_entered.connect(_outgoing_body_entered)
		area_entered.connect(_outgoing_area_entered)

func get_damage() -> int:
	return damage_on_impact
	
func set_collision(enabled: bool):
	self.set_collision_layer_value(1, enabled)

func play_impact_sound():
	Audio.play_sound_3d(impact_sound).global_position = global_position

func _outgoing_body_entered(node: Node3D):
	if node is CogitoPlayer:
		var player = node as CogitoPlayer
		player.decrease_attribute("health", damage_on_impact)
		play_impact_sound()
	
func _outgoing_area_entered(area: Area3D):
	pass
