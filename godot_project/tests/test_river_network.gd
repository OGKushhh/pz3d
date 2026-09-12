# Run: godot --headless --script res://tests/test_river_network.gd
# Exit 0 = pass, 1 = fail.
#
# v8.2 Phase A.4: RiverNetwork is now a polyline (control_points array
# loaded from map_data.json). Tests verify:
#   - Control points load correctly
#   - distance_to works for points near the polyline
#   - is_over_river / water_depth_at return correct values
#   - get_river_x_at(z) interpolates correctly
#   - bridges are queryable
extends SceneTree

const RiverNetwork := preload("res://tools/river_network.gd")

var failures: int = 0

func _init():
        var river := RiverNetwork.new()

        # Test 1: control points are loaded (should be 7 from map_data.json)
        var cps: Array = river.get_control_points()
        _check(cps.size() >= 2, "control_points has ≥2 entries (got %d)" % cps.size())

        # Test 2: half_width and depth have expected defaults
        _check(river.get_half_width() == 30.0, "half_width = 30 (got %.1f)" % river.get_half_width())
        _check(river.get_depth() == 4.0, "depth = 4 (got %.1f)" % river.get_depth())

        # Test 3: distance_to at a point ON the polyline = 0
        # The first control point is (2250, 0). distance_to(2250, 0) should be ~0.
        var d_on: float = river.distance_to(2250.0, 0.0)
        _check(d_on < 0.5, "distance to first control point ≈ 0 (got %.2f)" % d_on)

        # Test 4: distance_to far away is large
        var d_far: float = river.distance_to(500.0, 500.0)
        _check(d_far > 500.0, "distance far from river > 500m (got %.2f)" % d_far)

        # Test 5: is_over_river at a point on the polyline = true
        _check(river.is_over_river(2250.0, 0.0), "is_over_river at (2250, 0) = true")

        # Test 6: is_over_river far away = false
        _check(not river.is_over_river(500.0, 500.0), "is_over_river far away = false")

        # Test 7: water_depth_at at centerline > 0 (close to max depth)
        var depth_center: float = river.water_depth_at(2250.0, 0.0)
        _check(depth_center > 3.5, "water_depth at centerline > 3.5 (got %.2f)" % depth_center)

        # Test 8: water_depth_at far away = 0
        var depth_far: float = river.water_depth_at(500.0, 500.0)
        _check(depth_far == 0.0, "water_depth far away = 0 (got %.2f)" % depth_far)

        # Test 9: get_river_x_at returns interpolated X for known Z
        # The polyline goes (2250,0) → (2150,500) → (2300,1000) → (2250,1500) → ...
        # At z=250 (halfway between 0 and 500), x should be midway between 2250 and 2150 = 2200.
        var x_at_250: float = river.get_river_x_at(250.0)
        _check(abs(x_at_250 - 2200.0) < 1.0, "get_river_x_at(250) ≈ 2200 (got %.2f)" % x_at_250)

        # Test 10: bridges exist (at least 2)
        var bridges: Array = river.get_bridges()
        _check(bridges.size() >= 2, "at least 2 bridges (got %d)" % bridges.size())

        # Test 11: bridge_at returns data near a known bridge
        # Sarran Bridge is at row 3 → z = 3*500 + 250 = 1750. Bridge spans x ∈ [1500, 3000].
        var bridge: Variant = river.bridge_at(2000.0, 1750.0)
        _check(bridge != null, "bridge_at at (2000, 1750) returns non-null")
        if bridge != null:
                var bname: String = (bridge as Dictionary).get("name", "")
                _check(bname.length() > 0, "bridge has name: %s" % bname)

        _print_result()

func _check(cond: bool, msg: String) -> void:
        if not cond:
                push_error("FAIL: " + msg)
                failures += 1
        else:
                print("  ✓ " + msg)

func _print_result() -> void:
        if failures > 0:
                print("river_network: FAIL (%d failures)" % failures)
                quit(1)
        else:
                print("river_network: PASS")
                quit(0)
