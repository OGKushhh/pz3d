# Interior Builder — generates one building's interior lazily on door-open.
# Caches merged shell to disk. Cache path INCLUDES seed so map_seed changes
# auto-invalidate. Runtime cache lives in user:// (writable in exported builds).
#
# GDD Part 7: static fixtures merged into shell mesh, dynamic furniture separate.
# STATIC (merged): kitchen counter pieces, toilet, bathtub, built-in shelving.
# DYNAMIC (separate): chairs, tables, bookshelves, beds, sofas, fridge, lamps.
class_name InteriorBuilder
extends RefCounted

const CACHE_DIR := "user://interiors/"

static func derive_seed(map_seed: int, chunk: Vector2i, building_id: int) -> int:
    return hash(Vector3i(chunk.x, chunk.y, building_id)) ^ map_seed

func get_or_generate(chunk: Vector2i, building_id: int, building_type: String, map_seed: int) -> Node3D:
    var bseed := derive_seed(map_seed, chunk, building_id)
    var path := "%sinterior_%d_%d_%d_%d.tscn" % [CACHE_DIR, chunk.x, chunk.y, building_id, bseed]

    if ResourceLoader.exists(path):
        var cached := load(path) as PackedScene
        if cached:
            return cached.instantiate()

    var interior := _generate(building_type, bseed)
    interior.name = "Interior_%d_%d_%d" % [chunk.x, chunk.y, building_id]
    _save(interior, path)
    return interior

func _generate(building_type: String, bseed: int) -> Node3D:
    # TODO GLM: implement per GDD Part 7.
    #   1. rng := RandomNumberGenerator.new(); rng.seed = bseed
    #   2. Build room graph from building_type + rng
    #   3. Place modular kitchen pieces (sink/stove/empty/wall_cabinet)
    #   4. Merge static fixtures into single ArrayMesh (room shell)
    #   5. Spawn dynamic furniture as StaticBody3D (promote later on proximity)
    #   6. Scatter loot containers, decals, clutter
    var root := Node3D.new()
    root.set_meta("building_type", building_type)
    root.set_meta("seed", bseed)
    return root

func _save(node: Node3D, path: String) -> void:
    var abs_dir := ProjectSettings.globalize_path(CACHE_DIR)
    DirAccess.make_dir_recursive_absolute(abs_dir)
    var packed := PackedScene.new()
    packed.pack(node)
    var err := ResourceSaver.save(packed, path)
    if err != OK:
        push_error("[InteriorBuilder] Failed to save %s: %d" % [path, err])
