#extends InteractionComponent
## Interaction to use with Dialogue Manager Addon for Godot Engine 4
## Installation Instructions:
## 1. Install Dialogue Manager
## 2. Uncomment everything below the dotted lines (Ctrl + K)
## 3. Add the Dialogue Manager Interaction component to your object and assing the correct dialogue resource.
## ............................................................................
#
#@export var dialogue_resource : DialogueResource
#@export var dialogue_cue : String = "start"
#var player_interaction_component : PlayerInteractionComponent
#
#
#func on_input(event: InputEvent) -> void:
	## Nothing needs to be captured here, since input is handled by Dialogue Manager
	#pass
#
#
#func interact(_player_interaction_component: PlayerInteractionComponent):
	#player_interaction_component = _player_interaction_component
	#start_dialogue()
#
#
#func start_dialogue():
	## Push a blocking input method to the router and unhide the mouse. on_input doesn't do anything
	## but it will keep the player from moving
	#InputRouter.push(on_input)
	#
	#if InputHelper.device_index == -1:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#
	#player_interaction_component.get_parent().toggled_interface.emit(true)
	#if !player_interaction_component.get_parent().menu_pressed.is_connected(abort_dialogue):
		#player_interaction_component.get_parent().menu_pressed.connect(abort_dialogue) #Connecting input action menu to close function.
	#DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_cue)
	#DialogueManager.dialogue_ended.connect(stop_dialogue)
#
#
#func stop_dialogue(dialogue_resource: DialogueResource):
	#player_interaction_component.get_parent().toggled_interface.emit(false)
	#DialogueManager.dialogue_ended.disconnect(stop_dialogue)
	#InputRouter.pop()
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
#
#func abort_dialogue():
	## Way to cancel out of dialogue: DialogueManager.
	#stop_dialogue(dialogue_resource)
