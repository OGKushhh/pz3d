# Run: godot --headless --script res://tests/spatial_index_test.gd
# Exit code 0 = pass, 1 = fail. Machine-checkable gate.
extends SceneTree

const SpatialIdx := preload("res://tools/spatial_index.gd")

var failures: int = 0

func _initialize() -> void:
    var idx := SpatialIdx.new(8.0)

    # 30m-radius object at origin.
    idx.insert(Vector3(0, 0, 0), 30.0)
    _check(not idx.is_free(Vector3(30, 0, 0), 1.0),  "+X edge not blocked")
    _check(not idx.is_free(Vector3(-30, 0, 0), 1.0), "-X edge not blocked")
    _check(not idx.is_free(Vector3(0, 0, 30), 1.0),  "+Z edge not blocked")
    _check(not idx.is_free(Vector3(0, 0, -30), 1.0), "-Z edge not blocked")
    _check(idx.is_free(Vector3(100, 0, 0), 1.0),     "false positive at 100m")

    # Small-object tracking — in CLEAN coordinates, far from origin.
    idx.insert(Vector3(1000, 0, 1000), 0.5)
    idx.insert(Vector3(1001, 0, 1001), 0.5)
    _check(not idx.is_free(Vector3(1000.5, 0, 1000.5), 1.0), "small objects not tracked")

    # Road marking.
    idx.mark_road(Vector3(200, 0, 200), 5.0)
    _check(not idx.is_road_clear(Vector3(200, 0, 200)), "road not marked")
    _check(idx.is_road_clear(Vector3(500, 0, 500)),     "false road positive")

    if failures > 0:
        print("spatial_index symmetry: FAIL (%d)" % failures)
        quit(1)
    else:
        print("spatial_index symmetry: PASS")
        quit(0)

func _check(cond: bool, msg: String) -> void:
    if not cond:
        push_error("FAIL: " + msg)
        failures += 1
