extends SceneTree

const RoadNet := preload("res://tools/road_network.gd")
const CityConfig := preload("res://tools/city_config.gd")

var failures: int = 0

func _initialize() -> void:
    var rng1 := RandomNumberGenerator.new()
    rng1.seed = 42
    var net1 := RoadNet.new()
    net1.generate(rng1)

    var rng2 := RandomNumberGenerator.new()
    rng2.seed = 42
    var net2 := RoadNet.new()
    net2.generate(rng2)

    # Determinism: same seed → same segments
    _check(net1.segments.size() == net2.segments.size(), "determinism: segment count %d != %d" % [net1.segments.size(), net2.segments.size()])
    _check(net1.segments.size() > 0, "no segments generated")

    # Verify segment data matches
    var match := true
    for i in range(net1.segments.size()):
        var a: Vector3 = net1.segments[i]["start"]
        var b: Vector3 = net2.segments[i]["start"]
        if a != b:
            match = false
            break
    _check(match, "determinism: segment positions differ")

    # Bridge count
    var bridge_count := 0
    for s in net1.segments:
        if s.get("kind", "") == "bridge":
            bridge_count += 1
    _check(bridge_count == CityConfig.bridges().size(), "bridge count: %d != %d" % [bridge_count, CityConfig.bridges().size()])

    # No NaN
    for s in net1.segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        _check(not is_nan(a.x) and not is_nan(b.x), "NaN in segment")
        _check(not is_nan(a.z) and not is_nan(b.z), "NaN in segment")

    # Every segment has an ID
    var has_ids := true
    for s in net1.segments:
        if not s.has("id"):
            has_ids = false
            break
    _check(has_ids, "segments missing 'id' field")

    if failures > 0:
        print("road_network_test: FAIL (%d)" % failures)
        quit(1)
    else:
        print("road_network_test: PASS")
        quit(0)

func _check(cond: bool, msg: String) -> void:
    if not cond:
        push_error("FAIL: " + msg)
        failures += 1
