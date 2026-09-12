# Run: godot --headless --script res://tests/test_river_network.gd
# Exit 0 = pass, 1 = fail.
extends SceneTree

const RiverNetwork := preload("res://tools/river_network.gd")

var failures: int = 0

func _init():
        var river := RiverNetwork.new()

        # Test 1: River center is at X=2250
        _check(river.get_center_x() == 2250.0, "river center X = 2250 (got %.0f)" % river.get_center_x())

        # Test 2: Distance to river at center = 0
        var d_center := river.distance_to(2250.0, 1000.0)
        _check(d_center == 0.0, "distance at center = 0 (got %.2f)" % d_center)

        # Test 3: Distance to river increases with X offset
        var d_100 := river.distance_to(2350.0, 1000.0)
        var d_200 := river.distance_to(2450.0, 1000.0)
        _check(d_200 > d_100, "distance increases with offset (%.2f > %.2f)" % [d_200, d_100])

        # Test 4: is_over_river at center
        _check(river.is_over_river(2250.0, 1000.0), "is_over_river at center = true")

        # Test 5: is_over_river far away = false
        _check(not river.is_over_river(500.0, 500.0), "is_over_river far away = false")

        # Test 6: water_depth_at center > 0
        var depth := river.water_depth_at(2250.0, 1000.0)
        _check(depth > 0.0, "water_depth_at center > 0 (got %.2f)" % depth)

        # Test 7: water_depth_at far away = 0
        var depth_far := river.water_depth_at(500.0, 500.0)
        _check(depth_far == 0.0, "water_depth_at far = 0 (got %.2f)" % depth_far)

        # Test 8: water_depth_at at river edge = 0 (exactly at 30m)
        var depth_edge := river.water_depth_at(2250.0 + 30.0, 1000.0)
        _check(depth_edge == 0.0, "water_depth_at at 30m edge = 0 (got %.4f)" % depth_edge)

        # Test 9: bridges exist
        var bridges := river.get_bridges()
        _check(bridges.size() >= 2, "at least 2 bridges (got %d)" % bridges.size())

        # Test 10: bridge_at returns data near a bridge location
        var bridge: Variant = river.bridge_at(2000.0, 1750.0)  # near row 3 bridge (Z=3*500+250=1750)
        if bridge != null:
                var bname: String = (bridge as Dictionary).get("name", "")
                _check(bname.length() > 0, "bridge has name: %s" % bname)
        else:
                # Try other bridge positions
                var b2: Variant = river.bridge_at(1500.0, 2250.0)  # row 4: Z=4*500+250=2250
                _check(b2 != null, "bridge_at returns data near bridge position")
                if b2 != null:
                        var bname: String = (b2 as Dictionary).get("name", "")
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
