extends SceneTree

func _init():
    print("=== Mazar City Builder ===")
    var builder = CityBuilder.new()
    builder.map_seed = 1337
    builder.skip_if_valid = false
    builder._ready()
    var stats = builder.build_all()
    print("Stats: ", stats)
    quit()
