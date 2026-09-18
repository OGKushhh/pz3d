@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_StateProcessor.svg")
extends Node
class_name StateProcessor

## Reference to the NPC
@export var npc: CogitoNPC
## Reference to the NPCs state chart
@export var state_chart: StateChart
## Reference to the NPCs barker i.e if they make noises during states, this is the audio player for that
@export var barker: AudioStreamPlayer3D
## Used to track the behaviour state of the NPC. Useful for testing transitions and being used as a guard
@export var behaviour_state: CogitoNPC.BehaviourState = CogitoNPC.BehaviourState.None
## Reference to the enum definition so you don't have to keep typing CogitoNPC.BehaviourState.XXX
var behaviours = CogitoNPC.BehaviourState

## Might be the most unhinged method i've ever written. 
## In theory this should use reflection to automatically connect signals if they haven't already been added in editor.
## Does a check to see if the immediate parent is a StateChartState, if not this is ignored.
func _ready() -> void:
	add_to_group("Persist")
	if get_parent() is StateChartState and behaviour_state != behaviours.None:
		var parent = get_parent() as StateChartState
		for method in get_method_list():
			var method_name: String = method["name"]
			var method_as_callable = Callable(self, method_name)
			if method_name.contains("state_entered"):
				bind_to_signal(parent.state_entered, method_as_callable)
			elif method_name.contains("state_exited"):
				bind_to_signal(parent.state_exited, method_as_callable)
			elif method_name.contains("state_physics_processing"):
				bind_to_signal(parent.state_physics_processing, method_as_callable)


## Make sure to call this from your subclass as super.enter_state() if you want to track npc behaviours in state logic
func enter_state():
	npc.current_behaviour = behaviour_state


## Make sure to call this from your subclass as super.exit_state() if you want to track npc behaviours in state logic
func exit_state():
	npc.previous_behaviour = behaviour_state


## Binds a signal to a callable from a method name
func bind_to_signal(sig: Signal, callable: Callable):
	if not sig.is_connected(callable):
			sig.connect(callable)


## Plays a bark. Passes in a sound that could be null if not configured, so checks a barker exists and sound exists before attempting to play it
func bark(nullable_sound):
	if barker and nullable_sound:
		barker.stream = nullable_sound
		barker.play()
