# Crosshair — dynamic spread visualization (4 lines that expand/contract).
#
# Phase #4 (2026-09-14): Adopted from GodotFPS-Template crosshair.gd pattern.
# Four line segments (top/bottom/left/right) positioned around screen center.
# Gap = current spread × distance_to_target. Expands on fire, contracts on idle.
#
# Also renders the cyclic spread_pattern as small dots (one per pattern entry)
# so you can SEE the pistol's 3-shot pattern, rifle's 5-shot, sniper's 1-shot.
extends Control

const WeaponSpreads := preload("res://data/weapon_spreads.gd")

var _top: ColorRect
var _bottom: ColorRect
var _left: ColorRect
var _right: ColorRect
var _center_dot: ColorRect
var _pattern_dots: Array[ColorRect] = []
var _current_spread: float = 5.0  # pixels from center, lerped
var _target_spread: float = 5.0
var _current_weapon: String = "pistol"

func _ready() -> void:
	# Connect to SignalBus to track weapon switches + shots
	var sb := get_node_or_null("/root/SignalBus")
	if sb:
		sb.weapon_switch.connect(_on_weapon_switch)
		sb.shot_fired.connect(_on_shot_fired)
	_build_crosshair()
	_update_weapon_data("pistol")

func _build_crosshair() -> void:
	# Center dot (1 pixel)
	_center_dot = _make_rect(Color(1, 1, 1, 0.9), 2, 2)
	add_child(_center_dot)
	# 4 lines (top, bottom, left, right)
	_top = _make_rect(Color(1, 1, 1, 0.7), 2, 8)
	_bottom = _make_rect(Color(1, 1, 1, 0.7), 2, 8)
	_left = _make_rect(Color(1, 1, 1, 0.7), 8, 2)
	_right = _make_rect(Color(1, 1, 1, 0.7), 8, 2)
	add_child(_top)
	add_child(_bottom)
	add_child(_left)
	add_child(_right)

func _make_rect(color: Color, w: float, h: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = Vector2(w, h)
	return r

func _on_weapon_switch(weapon_class: String) -> void:
	_update_weapon_data(weapon_class)

func _on_shot_fired(_weapon_class: String) -> void:
	# Expand crosshair on shot (visual feedback)
	_target_spread = _current_spread + 15.0

func _update_weapon_data(weapon_class: String) -> void:
	_current_weapon = weapon_class
	# Build pattern dots (one per spread_pattern entry)
	for dot in _pattern_dots:
		dot.queue_free()
	_pattern_dots.clear()
	var data := WeaponSpreads.get_weapon_data(weapon_class)
	var pattern: Array = data.get("spread_pattern", [])
	for i in range(pattern.size()):
		var dot := _make_rect(Color(1, 0.8, 0.2, 0.6), 3, 3)
		add_child(dot)
		_pattern_dots.append(dot)

func _process(delta: float) -> void:
	# Lerp current spread toward target
	_current_spread = lerp(_current_spread, _target_spread, delta * 10.0)
	# Decay target back to base (5px)
	_target_spread = lerp(_target_spread, 5.0, delta * 3.0)
	# Position crosshair at screen center
	var center := size * 0.5
	_center_dot.position = center - Vector2(1, 1)
	# Lines at gap distance from center
	var gap := _current_spread
	var line_len := 8.0
	_top.position = center + Vector2(-1, -gap - line_len)
	_bottom.position = center + Vector2(-1, gap)
	_left.position = center + Vector2(-gap - line_len, -1)
	_right.position = center + Vector2(gap, -1)
	# Position pattern dots in a small circle around center (visualizes cyclic pattern)
	var data := WeaponSpreads.get_weapon_data(_current_weapon)
	var pattern: Array = data.get("spread_pattern", [])
	for i in range(pattern.size()):
		if i >= _pattern_dots.size():
			break
		var offset: Vector2 = pattern[i]
		# Scale pattern offset (degrees) to pixels (1° ≈ 10px at this scale)
		var px := offset * 10.0
		_pattern_dots[i].position = center + px - Vector2(1.5, 1.5)
