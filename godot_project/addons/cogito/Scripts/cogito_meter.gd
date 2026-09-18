## Non-interactive object. Only displays a value that can get saved, manipulated and send signals.
class_name CogitoMeter
extends Node3D

signal value_changed
signal value_changed_normalized(val_normalized:float)
signal maximum_reached
signal minimum_reached

@export_group("Display Settings")
@export var display_label : Label3D

@export_group("Value Settings")
@export var start_value : float = 0
@export var val_min : float = 0
@export var val_max : float = 100
@export var prefix : String
@export var suffix : String
@export var change_increment : float = 1.0

enum MeterEvent {
  None,
  MaxValReached,
  MinValReached,
}

@export_group("Event Settings")
@export var meter_event : MeterEvent = MeterEvent.None
@export var destroy_on_event : Array[Node3D]
@export var sound_on_event : AudioStream


var current_value : float:
	set(value):
		current_value = value
		if current_value > val_max:
			current_value = val_max
		elif current_value < val_min:
			current_value = val_min

var previous_value : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("save_object_state")
	current_value = start_value
	previous_value = current_value
	update_display_label()


func change_value(change:float) -> void:
	previous_value = current_value
	current_value = current_value + change
	
	# Only update if value has actually changed.
	if current_value == previous_value:
		return
	
	value_changed.emit()
	
	var normalized_value : float = (current_value - val_min) / (val_max - val_min)
	value_changed_normalized.emit(normalized_value)
	
	if current_value == val_min:
		minimum_reached.emit()
		if meter_event == MeterEvent.MinValReached:
			trigger_event_actions()
	elif current_value == val_max:
		maximum_reached.emit()
		if meter_event == MeterEvent.MaxValReached:
			trigger_event_actions()
	
	update_display_label()


func increase_value() -> void:
	change_value(change_increment)

func decrease_value() -> void:
	change_value(change_increment * -1)


func update_display_label() -> void:
	if !display_label:
		return
	
	display_label.text = prefix + str(current_value) + suffix


func trigger_event_actions() -> void:
	if sound_on_event:
		Audio.play_sound_3d(sound_on_event).position = self.position
	if destroy_on_event:
		for node in destroy_on_event:
			node.queue_free()


func set_state():
	update_display_label()


func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"current_value" : current_value,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
