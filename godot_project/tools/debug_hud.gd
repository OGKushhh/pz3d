# Debug HUD — prints FPS + draw call count every 60 frames to console.
# Add as autoload "DebugHUD" in project.godot.
# Visible in headless mode (stdout) and in editor (Output panel).
extends Node

var _frames: int = 0

func _ready() -> void:
	print("[HUD] DebugHUD autoload ready")

func _process(_delta: float) -> void:
	_frames += 1
	if _frames >= 60:
		_frames = 0
		var fps: int = Engine.get_frames_per_second()
		var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var mem: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1024
		print("[HUD] fps=%d draws=%d prims=%d texmem=%dKB" % [fps, draws, prims, mem])
