extends SceneTree

func _init():
    var idx = SpatialIndex.new(8.0)
    idx.insert(Vector3(0, 0, 0), 10.0)
    if not idx.is_free(Vector3(5, 0, 0), 1.0):
        print("PASS: SpatialIndex works")
    else:
        print("FAIL: SpatialIndex broken")
    quit()
