class_name InteriorBuilder
extends RefCounted

const CACHE_DIR := "user://interiors/"

static func derive_seed(map_seed: int, chunk: Vector2i, building_id: int) -> int:
    return hash(Vector3i(chunk.x, chunk.y, building_id)) ^ map_seed

static func cache_path(chunk: Vector2i, building_id: int, bseed: int) -> String:
    return "%sinterior_%d_%d_%d_%d.tscn" % [
        CACHE_DIR, chunk.x, chunk.y, building_id, bseed & 0x7FFFFFFF,
    ]

func get_or_generate(chunk: Vector2i, building_id: int, building_type: String, map_seed: int) -> Node3D:
    var bseed := derive_seed(map_seed, chunk, building_id)
    var path := cache_path(chunk, building_id, bseed)

    if ResourceLoader.exists(path):
        var cached := load(path) as PackedScene
        if cached != null:
            return cached.instantiate()
        push_warning("[InteriorBuilder] corrupt cache entry, regenerating: " + path)

    var interior := _generate(building_type, bseed)
    interior.name = "Interior_%d_%d_%d" % [chunk.x, chunk.y, building_id]
    _save(interior, path)
    return interior

func _generate(building_type: String, bseed: int) -> Node3D:
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

static func purge_cache() -> void:
    var dir := DirAccess.open(CACHE_DIR)
    if dir == null:
        return
    for fname in dir.get_files():
        dir.remove(fname)
