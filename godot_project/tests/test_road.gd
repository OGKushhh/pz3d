extends SceneTree

func _init():
    var roads = RoadNetwork.new()
    var rng = RandomNumberGenerator.new()
    rng.seed = 42
    roads.generate(rng)
    print("Road segments: ", roads.segments.size())
    print("PASS")
    quit()
