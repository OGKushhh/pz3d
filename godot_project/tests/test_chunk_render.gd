extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "TestRoot"
    get_root().add_child(root)

    # Add a camera looking at origin from above
    var cam = Camera3D.new()
    cam.position = Vector3(125, 50, -50)
    cam.look_at(Vector3(125, 0, 125))
    cam.fov = 60
    cam.far = 1000
    root.add_child(cam)
    cam.make_current()

    # Load chunk_0_0 and place at origin
    var packed = load("res://chunks/chunk_0_0.tscn") as PackedScene
    var chunk = packed.instantiate()
    chunk.position = Vector3(0, 0, 0)
    root.add_child(chunk)
    print("chunk placed at:", chunk.position, "children:", chunk.get_child_count())

    # Wait a frame, take screenshot
    await process_frame
    await create_timer(1.0).timeout
    var img = get_root().get_viewport().get_texture().get_image()
    if img:
        img.save_png("user://chunk_test.png")
        print("saved user://chunk_test.png size:", img.get_size())
    else:
        print("image was null")
    quit()
