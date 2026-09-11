extends Node

func _ready():
    await get_tree().create_timer(3.0).timeout
    var vp = get_viewport()
    var tex = vp.get_texture()
    if tex:
        var img = tex.get_image()
        if img:
            var path = "user://city_screenshot.png"
            var err = img.save_png(path)
            print("Screenshot: ", path, " err=", err)
    get_tree().quit()
