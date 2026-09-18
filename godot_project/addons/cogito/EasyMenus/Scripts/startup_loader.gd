extends Node
#Loads options like volume and graphic options on game startup

func _ready():
	CogitoGameConfig.load_options()
