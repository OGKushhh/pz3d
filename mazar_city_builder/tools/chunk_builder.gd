# Chunk Builder — builds ONE 250m × 250m chunk of the city.
# THIS IS THE MOST IMPORTANT FILE. It does the actual placement work.
# city_builder.gd calls build() once per chunk; this file fills it.
#
# REFACTOR TARGETS (post-Priority-2, GLM to implement):
#   1. MultiMeshInstance3D per asset per chunk for foliage + homogeneous props.
#      Currently: instantiate() per tree/prop → 1 draw call each. Must become:
#        - group by asset name
#        - create one MultiMeshInstance3D per asset
#        - set instance transforms
#      This is the biggest performance win. Forest chunks with 200 trees go
#      from 200 draw calls → 3 draw calls (oak/pine/bush).
#   2. Bake NavigationRegion3D per chunk using road_network as backbone.
#      Retrofit after 30 km² is miserable. Add it now, even with a trivial
#      navmesh, so the hooks exist.
#   3. Physics policy for dynamic furniture: StaticBody3D by default,
#      promoted to RigidBody3D when player is within N meters.
#   4. Centroid ownership: objects belong to the chunk containing their center.
#      Use road_network.owned_segments_in_chunk() for roads.
#
# DETERMINISM: every randf()/pick_random() MUST go through the per-chunk rng.
# Never use global randi()/randf(). Never iterate unsorted Dictionary keys.
class_name ChunkBuilder
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

var spatial: SpatialIndex
var roads: RoadNetwork
var manifest: Dictionary
var asset_cache: Dictionary
var rng: RandomNumberGenerator

func _init(idx: SpatialIndex, net: RoadNetwork, man: Dictionary, cache: Dictionary, p_seed: int) -> void:
    spatial = idx
    roads = net
    manifest = man
    asset_cache = cache
    rng = RandomNumberGenerator.new()
    rng.seed = p_seed

# Returns the chunk's root Node3D (unparented — caller adds + saves + frees).
func build(biome: int, chunk_origin: Vector3) -> Node3D:
    var profile: Dictionary = CFG.biomes().get(biome, {})
    var root := Node3D.new()
    root.name = "Chunk"
    root.set_meta("biome", biome)
    root.set_meta("origin", chunk_origin)

    if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
        return root

    _place_buildings(root, profile, chunk_origin)
    _place_props(root, profile, chunk_origin)
    _place_foliage(root, profile, chunk_origin)
    if profile.get("lights", false):
        _place_streetlights(root, chunk_origin)

    # TODO GLM: bake navmesh here (Priority 6).
    return root

func _place_buildings(root: Node3D, profile: Dictionary, origin: Vector3) -> void:
    if profile["buildings"].is_empty():
        return
    if rng.randf() > profile["fill"] * 0.85:
        return
    var buildings: Array = profile["buildings"].duplicate()
    buildings.sort()  # determinism
    var bname: String = buildings[rng.randi() % buildings.size()]
    var scene := _get(bname)
    if scene == null:
        return
    var inset := CFG.BUILDING_SETBACK + CFG.SIDEWALK_WIDTH + CFG.ROAD_WIDTH * 0.5
    var pos := origin + Vector3(
        rng.randf_range(inset, CFG.CHUNK_SIZE_M - inset),
        0,
        rng.randf_range(inset, CFG.CHUNK_SIZE_M - inset)
    )
    if not spatial.is_free(pos, 30.0) or not spatial.is_road_clear(pos):
        return
    _spawn(scene, root, pos, bname, false)
    spatial.insert(pos, 30.0)

func _place_props(root: Node3D, profile: Dictionary, origin: Vector3) -> void:
    if profile["props"].is_empty():
        return
    var props: Array = profile["props"].duplicate()
    props.sort()
    var count := int(rng.randf_range(0, 4))
    for i in range(count):
        var pname: String = props[rng.randi() % props.size()]
        var scene := _get(pname)
        if scene == null:
            continue
        var pos := origin + Vector3(
            rng.randf_range(CFG.PROP_ROAD_CLEARANCE, CFG.CHUNK_SIZE_M - CFG.PROP_ROAD_CLEARANCE),
            0,
            rng.randf_range(CFG.PROP_ROAD_CLEARANCE, CFG.CHUNK_SIZE_M - CFG.PROP_ROAD_CLEARANCE)
        )
        if not spatial.is_free(pos, 1.5) or not spatial.is_road_clear(pos):
            continue
        _spawn(scene, root, pos, pname, true)
        spatial.insert(pos, 1.5)

func _place_foliage(root: Node3D, profile: Dictionary, origin: Vector3) -> void:
    if profile["foliage"].is_empty():
        return
    # TODO GLM: replace this loop with MultiMeshInstance3D per foliage asset.
    var foliage: Array = profile["foliage"].duplicate()
    foliage.sort()
    var count := int(rng.randf_range(0, 8))
    for i in range(count):
        var fname: String = foliage[rng.randi() % foliage.size()]
        var scene := _get(fname)
        if scene == null:
            continue
        var pos := origin + Vector3(
            rng.randf_range(0, CFG.CHUNK_SIZE_M),
            0,
            rng.randf_range(0, CFG.CHUNK_SIZE_M)
        )
        if not spatial.is_free(pos, 2.0) or not spatial.is_road_clear(pos):
            continue
        _spawn(scene, root, pos, fname, true)
        spatial.insert(pos, 2.0)

func _place_streetlights(root: Node3D, origin: Vector3) -> void:
    var scene := _get("street_light")
    if scene == null:
        return
    # Only place on segments this chunk OWNS.
    var owned := roads.owned_segments_in_chunk(origin, CFG.CHUNK_SIZE_M)
    var edge_offset := CFG.ROAD_WIDTH * 0.5 + CFG.SIDEWALK_WIDTH * 0.5
    for seg in owned:
        var a: Vector3 = seg["start"]
        var b: Vector3 = seg["end"]
        var length := a.distance_to(b)
        var d := 0.0
        while d < length:
            var t := d / length
            var base := a.lerp(b, t)
            # Offset perpendicular to segment on the south/west side
            var perp := Vector3(0, 0, 1) if a.z == b.z else Vector3(1, 0, 0)
            var pos := base + perp * edge_offset
            if spatial.is_road_clear(pos) and spatial.is_free(pos, 0.5):
                var inst := _spawn(scene, root, pos, "street_light", false)
                inst.rotation.y = 0.0 if a.z == b.z else PI * 0.5
                spatial.insert(pos, 0.5)
            d += CFG.STREETLIGHT_SPACING

func _spawn(scene: PackedScene, parent: Node3D, pos: Vector3, hint: String, rand_yaw: bool) -> Node3D:
    var inst := scene.instantiate()
    inst.position = pos
    if rand_yaw:
        inst.rotation.y = rng.randf_range(0.0, TAU)
    inst.name = "%s_%d" % [hint, rng.randi() % 100000]
    parent.add_child(inst)
    return inst

func _get(name: String) -> PackedScene:
    if asset_cache.has(name):
        return asset_cache[name]
    if not manifest.has(name):
        return null
    var s := load(manifest[name]["path"]) as PackedScene
    asset_cache[name] = s
    return s
