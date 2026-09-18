extends DetectionIndicator

@export var indicator: Sprite3D
@export var value: Label3D

var is_investigating: bool = false

func _ready() -> void:
	visible = false

func update(current_value: float, threshold_value: float):
	if not indicator:
		return
	var ratio: float = clamp(current_value / threshold_value, 0, 1)
	visible = (ratio >= 0)
	if not is_investigating:
		indicator.modulate = Color(1, 1, 1-ratio)
		value.text = "%d" % (ratio*50)
	else:
		indicator.modulate = Color(1, 1-ratio, 0)
		value.text = "%d" % (ratio*100)
