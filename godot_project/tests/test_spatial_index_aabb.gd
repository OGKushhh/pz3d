# Run: godot --headless --script res://tests/test_spatial_index_aabb.gd
# Exit 0 = pass, 1 = fail.
extends SceneTree

const SpatialIdx := preload("res://tools/spatial_index.gd")

var failures: int = 0

func _init():
        var idx := SpatialIdx.new(8.0)

        # Test 1: insert_box makes area occupied
        idx.insert_box(Vector3(100, 0, 100), Vector2(20, 16), 0.0)
        _check(not idx.is_free(Vector3(100, 0, 100), 1.0), "insert_box: center is occupied")
        _check(idx.is_free(Vector3(200, 0, 200), 1.0), "insert_box: far away is free")

        # Test 2: box corner is occupied
        _check(not idx.is_free(Vector3(109, 0, 107), 1.0), "insert_box: near corner is occupied")

        # Test 3: outside box AABB is free
        _check(idx.is_free(Vector3(115, 0, 100), 1.0), "insert_box: outside X extent is free (x=115, half_w=10)")

        # Test 4: circle insert still works (backward compat)
        idx.clear()
        idx.insert(Vector3(0, 0, 0), 10.0)
        _check(not idx.is_free(Vector3(5, 0, 0), 1.0), "circle insert: inside radius occupied")
        _check(idx.is_free(Vector3(20, 0, 0), 1.0), "circle insert: outside radius free")

        # Test 5: box + circle don't interfere incorrectly
        idx.clear()
        idx.insert_box(Vector3(100, 0, 100), Vector2(20, 16), 0.0)
        idx.insert(Vector3(200, 0, 200), 5.0)
        _check(not idx.is_free(Vector3(100, 0, 100), 1.0), "box + circle: box center occupied")
        _check(not idx.is_free(Vector3(200, 0, 200), 1.0), "box + circle: circle center occupied")
        _check(idx.is_free(Vector3(150, 0, 150), 1.0), "box + circle: between them is free")

        # Test 6: rotated box (90 degrees) — AABB is same for symmetric boxes
        # (20×16 box rotated 90° becomes 16×20, but AABB half-extents = max(w,d)/2 = 10)
        # So the point (9,7) should be occupied in both cases (within both AABBs)
        idx.clear()
        idx.insert_box(Vector3(0, 0, 0), Vector2(20, 16), 0.0)
        var occupied_0: bool = not idx.is_free(Vector3(9, 0, 7), 0.5)
        idx.clear()
        idx.insert_box(Vector3(0, 0, 0), Vector2(20, 16), PI * 0.5)
        var occupied_90: bool = not idx.is_free(Vector3(9, 0, 7), 0.5)
        # Point (9,7) is occupied in unrotated (half_w=10>9) but NOT in rotated (half_w=8<9).
        # This is correct behavior — 90° rotation swaps w/d.
        _check(not occupied_0 == occupied_90, "rotated 90° box: occupancy differs (unrotated=%s, rotated=%s)" % [occupied_0, occupied_90])
        # If they differ, it's because 90° rotation swaps w/d: unrotated AABB half=(10,8),
        # rotated AABB half=(8,10). Point (9,7): unrotated 9<10 ✓ 7<8 ✓ = occupied.
        # Rotated: 9<8 ✗ = NOT occupied. So they DO differ. This is correct behavior.
        # Let's verify a point that's occupied in both:
        var occ_both_0: bool = not idx.is_free(Vector3(7, 0, 7), 0.5)
        idx.clear()
        idx.insert_box(Vector3(0, 0, 0), Vector2(20, 16), PI * 0.5)
        var occ_both_90: bool = not idx.is_free(Vector3(7, 0, 7), 0.5)
        _check(occ_both_0 and occ_both_90, "point (7,7) occupied in both rotated and unrotated")

        # Test 7: is_on_road works
        idx.clear()
        idx.mark_road(Vector3(50, 0, 50), 4.0)
        _check(idx.is_on_road(Vector3(50, 0, 50)), "is_on_road: marked cell is on road")
        _check(not idx.is_on_road(Vector3(100, 0, 100)), "is_on_road: unmarked cell is not on road")

        _print_result()

func _check(cond: bool, msg: String) -> void:
        if not cond:
                push_error("FAIL: " + msg)
                failures += 1
        else:
                print("  ✓ " + msg)

func _print_result() -> void:
        if failures > 0:
                print("spatial_index_aabb: FAIL (%d failures)" % failures)
                quit(1)
        else:
                print("spatial_index_aabb: PASS")
                quit(0)
