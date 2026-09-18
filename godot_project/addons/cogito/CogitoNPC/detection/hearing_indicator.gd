extends DetectionIndicator

@export var indicator: Sprite3D

func update(current_value: float, threshold_value: float):
	var ratio: float = clamp(current_value / threshold_value, 0, 1)
	visible = (ratio >= 0.1)
	indicator.modulate = Color(1, 1, 1-ratio)
	pass
