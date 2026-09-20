# WieldableShotgun — extends WieldableHitscan with multi-pellet spread.
#
# Shotgun fires 8 hitscan raycasts per shot with wide spread.
# The base WieldableHitscan already handles pellets_per_shot from weapon_spreads.gd,
# so this class just sets the weapon_class and overrides spread behavior.
#
# Each pellet gets:
#	- Random spread within a 5° cone (from weapon_spreads.gd)
#	- Individual raycast + tracer
#	- Individual damage on hit
#	- Single muzzle flash (not 8)
#
# This extends Cogito, not forks it — subclasses WieldableHitscan which subclasses CogitoWieldable.

extends WieldableHitscan
class_name WieldableShotgun

func _ready() -> void:
	# Set weapon class before parent _ready loads weapon data
	weapon_class = "shotgun"
	super._ready()
	print("[WieldableShotgun] ready: 8 pellets, %.1f° spread" % float(_weapon_data.get("spread_deg", 5.0)))
