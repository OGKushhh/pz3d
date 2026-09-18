extends InteractionComponent
# Interaction to use with Dialogic Addon for Godot Engine 4
# Installation Instructions:
# 1. Install Dialogic
# 2. Uncomment everything below the dotted lines (Ctrl + K)
# 3. Add the DialogicInteraction component to your object and assing the correct dialogic timeline.
# ............................................................................

#@export var dialogic_timeline : DialogicTimeline
##@onready var dialogue_bubble: DialogueBubble = $DialogueBubble
#
#var player_interaction_component : PlayerInteractionComponent
#
#
#func _ready() -> void:
	##dialogue_bubble.data = dialogue_data
	#pass
#
#
#func on_input(event: InputEvent) -> void:
	## Nothing needs to be captured here, since input is handled by Dialogic
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
	
	#if InputHelper.device_index == -1:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#player_interaction_component.get_parent().toggled_interface.emit(true)
	#if !player_interaction_component.get_parent().menu_pressed.is_connected(abort_dialogue):
		#player_interaction_component.get_parent().menu_pressed.connect(abort_dialogue) #Connecting input action menu to close function.
	#Dialogic.timeline_ended.connect(stop_dialogue)
	#Dialogic.start(dialogic_timeline)
#
#
#func stop_dialogue():
	#player_interaction_component.get_parent().toggled_interface.emit(false)
	#Dialogic.timeline_ended.disconnect(stop_dialogue)
	# Capture the mouse again and then pop the blocking input method so the player can regain control again. Do this
	# at the end so the player doesn't move around while the dialogic transition is ongoing
	#InputRouter.pop()
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
#
#func abort_dialogue():
	#Dialogic.end_timeline()
	#stop_dialogue()
