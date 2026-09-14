# SignalBus — global signal hub for decoupled fire/switch/reload input.
#
# Phase #3 (2026-09-14): Adopted from GodotFPS-Template pattern.
# Instead of weapon_system.gd directly reading Input, the player controller
# emits these signals. Tests can emit them too — no Input simulation needed.
#
# Usage in player controller:
#   SignalBus.fire_input.emit()
#   SignalBus.weapon_switch.emit("pistol")
#
# Usage in weapon_system.gd:
#   SignalBus.fire_input.connect(_on_fire_input)
#   SignalBus.weapon_switch.connect(_on_weapon_switch)
extends Node

# Emitted when the player presses fire (left click). No args — weapon system
# calls its own fire() method which handles rate limiting + pellets.
signal fire_input

# Emitted when the player switches weapons. Arg = weapon class name
# ("pistol", "rifle", "shotgun", "sniper_rifle").
signal weapon_switch(weapon_class: String)

# Emitted when the player releases fire (for future semi-auto mode).
signal fire_release

# Emitted when the player presses reload (future).
signal reload_input

# Emitted when a shot is actually fired (after rate limit + pellet loop).
# Arg = weapon_class. Tests can connect to count shots fired.
signal shot_fired(weapon_class: String)
