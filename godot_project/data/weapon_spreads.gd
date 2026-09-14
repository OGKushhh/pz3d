# WeaponSpreads — per-gun spread pattern data (DATA, not code).
#
# Phase: Gun System (2026-09-14)
# Per user spec: "Spread pattern — a per-gun array of (x, y) offsets. Data, not code."
#
# Each weapon class has:
#   - spread_deg: max cone half-angle (degrees). Random within this.
#   - spread_pattern: Array of Vector2 (x, y) offsets in DEGREES for cyclic pattern.
#       When pattern is non-empty, shots cycle through these offsets instead of random.
#       This gives each gun a "signature" spread (pistol = tight, shotgun = wide).
#   - recoil_pitch_deg: camera pitch up per shot (degrees)
#   - recoil_yaw_deg: camera yaw jitter per shot (degrees, random ±)
#   - recovery_rate_deg: recoil decays toward 0 at this rate (degrees/second)
#   - fire_rate: shots per second
#   - damage: per-hit damage
#   - range_m: max raycast distance
#   - tracer_color: Color of the tracer line
#   - tracer_width: width of tracer in meters
#   - muzzle_flash_scale: scale multiplier for muzzle flash sprite
#   - pellets_per_shot: number of raycasts per trigger pull (shotgun = 8, others = 1)
class_name WeaponSpreads
extends RefCounted

const WEAPON_DATA := {
        "pistol": {
                "spread_deg": 0.8,
                "spread_pattern": [Vector2(0, 0), Vector2(0.3, -0.2), Vector2(-0.2, 0.15)],
                "recoil_pitch_deg": 1.5,
                "recoil_yaw_deg": 0.3,
                "recovery_rate_deg": 12.0,
                "fire_rate": 5.0,  # 5 shots/sec — snappy semi-auto feel
                "damage": 35,
                "range_m": 120.0,
                "tracer_color": Color(1.0, 0.9, 0.4, 1),
                "tracer_width": 0.04,
                "muzzle_flash_scale": 0.6,
                "pellets_per_shot": 1,
        },
        "rifle": {
                "spread_deg": 0.5,
                "spread_pattern": [Vector2(0, 0), Vector2(0.15, 0.08), Vector2(-0.12, -0.06), Vector2(0.08, -0.15), Vector2(-0.1, 0.1)],
                "recoil_pitch_deg": 1.0,
                "recoil_yaw_deg": 0.2,
                "recovery_rate_deg": 14.0,
                "fire_rate": 10.0,  # 10 shots/sec — fast automatic
                "damage": 28,
                "range_m": 250.0,
                "tracer_color": Color(1.0, 0.75, 0.25, 1),
                "tracer_width": 0.05,
                "muzzle_flash_scale": 0.8,
                "pellets_per_shot": 1,
        },
        "shotgun": {
                "spread_deg": 5.0,
                "spread_pattern": [],
                "recoil_pitch_deg": 4.0,
                "recoil_yaw_deg": 0.8,
                "recovery_rate_deg": 8.0,
                "fire_rate": 1.8,  # pump action — deliberate
                "damage": 15,  # per pellet (×8 = 120 total at point-blank)
                "range_m": 60.0,
                "tracer_color": Color(1.0, 0.6, 0.2, 1),
                "tracer_width": 0.06,
                "muzzle_flash_scale": 1.5,
                "pellets_per_shot": 8,
        },
        "sniper_rifle": {
                "spread_deg": 0.05,
                "spread_pattern": [Vector2(0, 0)],
                "recoil_pitch_deg": 3.5,
                "recoil_yaw_deg": 0.0,
                "recovery_rate_deg": 5.0,  # heavy recoil, slow recovery — punishes spam
                "fire_rate": 0.9,  # bolt action — deliberate
                "damage": 120,
                "range_m": 600.0,
                "tracer_color": Color(0.6, 1.0, 0.6, 1),
                "tracer_width": 0.03,
                "muzzle_flash_scale": 1.0,
                "pellets_per_shot": 1,
        },
}

# Get the weapon data dictionary for a weapon class name.
static func get_weapon_data(weapon_class: String) -> Dictionary:
        return WEAPON_DATA.get(weapon_class, {})

# Get the list of all weapon class names.
static func get_all_weapons() -> Array:
        return WEAPON_DATA.keys()

# Get the spread offset for shot number `shot_index` (cyclic pattern).
# Returns Vector2.ZERO if pattern is empty (use random spread instead).
static func get_pattern_offset(weapon_class: String, shot_index: int) -> Vector2:
        var data: Dictionary = WEAPON_DATA.get(weapon_class, {})
        var pattern: Array = data.get("spread_pattern", [])
        if pattern.is_empty():
                return Vector2.ZERO
        return pattern[shot_index % pattern.size()]
