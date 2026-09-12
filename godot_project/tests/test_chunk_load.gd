extends SceneTree

func _init():
    var packed = load("res://chunks/chunk_0_0.tscn") as PackedScene
    print("loaded: ", packed)
    if packed:
        var inst = packed.instantiate()
        print("instantiated: ", inst)
        print("child count: ", inst.get_child_count())
        var i = 0
        for child in inst.get_children():
            print("  child[%d]: name=%s type=%s visible=%s" % [i, child.name, child.get_class(), child.visible if "visible" in child else "N/A"])
            i += 1
            if i > 5: break
    quit()
