extends SceneTree

func _init():
    var layout = CityConfig.grid_layout()
    print("Grid rows: ", layout.size())
    print("Grid cols: ", layout[0].size())
    var biomes = CityConfig.biomes()
    print("Biomes: ", biomes.size())
    print("PASS")
    quit()
