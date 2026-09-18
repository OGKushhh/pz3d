# Audio autoload — wrapper for quick_audio.
# Godot 4.7 doesn't resolve autoload identifiers from addon scripts.
# This script sits at res:// level where autoload resolution works.
extends Node

func play_sound(sound, parent = null):
	var player = AudioStreamPlayer.new()
	if sound:
		player.stream = sound
	if parent:
		parent.add_child(player)
	else:
		add_child(player)
	player.play()
	# Auto-free when done
	player.finished.connect(player.queue_free)
	return player

func play_sound_3d(sound, parent = null):
	var player = AudioStreamPlayer3D.new()
	if sound:
		player.stream = sound
	if parent:
		parent.add_child(player)
	else:
		add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player
