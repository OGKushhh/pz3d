extends SceneTree

func _init():
    # Wait for scene to load and render
    await create_timer(3.0).timeout
    
    var viewport = root.get_viewport()
    var img = viewport.get_texture().get_image()
    
    if img:
        var err = img.save_png("res://city_screenshot.png")
        if err == OK:
            print("Screenshot saved!")
        else:
            print("Error saving screenshot: ", err)
    else:
        print("Failed to get viewport image")
    
    quit()
