extends SceneTree

func _init():
    var spatial = SpatialIndex.new(8.0)
    var roads = RoadNetwork.new()
    var rng = RandomNumberGenerator.new()
    rng.seed = 42
    roads.generate(rng)
    var manifest = {}
    var cache = {}
    var cb = ChunkBuilder.new(spatial, roads, manifest, cache, 12345)
    print("PASS: ChunkBuilder created")
    quit()
