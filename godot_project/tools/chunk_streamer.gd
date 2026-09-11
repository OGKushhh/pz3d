class_name ChunkStreamer
extends Node3D

const CityConfig = preload("res://tools/city_config.gd")

var player: Node3D
var stream_radius: int = 2

var _loaded: Dictionary = {}
var _pending: Dictionary = {}

func _ready() -> void:
    # Find player in scene tree
    await get_tree().process_frame
    var root := get_tree().current_scene
    player = root.get_node_or_null("Player")
    if player == null:
        # Try finding by type
        for child in root.get_children():
            if child is CharacterBody3D:
                player = child
                break
    if player == null:
        push_error("[ChunkStreamer] No player found!")
        return
    print("[ChunkStreamer] player found: %s at %s" % [player.name, player.global_position])

func _process(_delta: float) -> void:
    if player == null:
        return
    var cx: int = int(floor(player.global_position.x / CityConfig.CHUNK_SIZE_M))
    var cy: int = int(floor(player.global_position.z / CityConfig.CHUNK_SIZE_M))
    _refresh(cx, cy)

func _refresh(cx: int, cy: int) -> void:
    var unload_r: int = stream_radius + CityConfig.STREAM_UNLOAD_BUFFER
    var wanted: Dictionary = {}
    for dy in range(-stream_radius, stream_radius + 1):
        for dx in range(-stream_radius, stream_radius + 1):
            var key := Vector2i(cx + dx, cy + dy)
            wanted[key] = true
            if not _loaded.has(key) and not _pending.has(key):
                _request_chunk(key)
    for key in _pending.keys():
        if not wanted.has(key):
            _pending.erase(key)
    var to_remove: Array = []
    for key in _loaded:
        if abs(key.x - cx) > unload_r or abs(key.y - cy) > unload_r:
            to_remove.append(key)
    for key in to_remove:
        _unload_chunk(key)
    for key in _pending.keys():
        var path: String = _pending[key]
        var status: int = ResourceLoader.load_threaded_get_status(path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            var scene: PackedScene = ResourceLoader.load_threaded_get(path) as PackedScene
            if scene:
                _place_chunk(key, scene)
            _pending.erase(key)
        elif status == ResourceLoader.THREAD_LOAD_FAILED:
            _pending.erase(key)

func _request_chunk(key: Vector2i) -> void:
    if key.x < 0 or key.y < 0 or key.x >= CityConfig.CHUNKS_COLS or key.y >= CityConfig.CHUNKS_ROWS:
        return
    var path: String = "%schunk_%d_%d.tscn" % [CityConfig.CHUNK_OUTPUT_DIR, key.x, key.y]
    if not ResourceLoader.exists(path):
        return
    ResourceLoader.load_threaded_request(path, "PackedScene", true)
    _pending[key] = path

func _place_chunk(key: Vector2i, scene: PackedScene) -> void:
    if scene == null:
        return
    var inst: Node3D = scene.instantiate()
    inst.name = "Chunk_%d_%d" % [key.x, key.y]
    inst.position = Vector3.ZERO
    add_child(inst)
    _loaded[key] = inst
    print("[ChunkStreamer] placed chunk (%d,%d) children=%d" % [key.x, key.y, inst.get_child_count()])

func _unload_chunk(key: Vector2i) -> void:
    var inst: Node3D = _loaded[key]
    inst.queue_free()
    _loaded.erase(key)
