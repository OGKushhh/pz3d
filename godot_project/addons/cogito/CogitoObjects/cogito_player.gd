@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPlayer.svg")
## The player class controls movement from input from the mouse, keyboard, and gamepad, as well as behavior parameters like stair and ladder handling.
@abstract class_name CogitoPlayer
extends CharacterBody3D

@abstract func create_new_state() -> CogitoPlayerState
