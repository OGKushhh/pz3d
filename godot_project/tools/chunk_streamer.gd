class_name ChunkStreamer
# Runtime chunk streamer. Attach to player or manager node.
# Threaded loading with hysteresis (load radius 1, unload radius 2).
extends Node3D



@export var player: Node3D
@export var stream_radius: int = CityConfig.STREAM_RADIUS

var _loaded: Dictionary = {}
var _pending: Dictionary = {}

func _process(_delta: float) -> void:
    if player == null:
        return
    var cx := int(floor(player.global_position.x / CityConfig.CHUNK_SIZE_M))
    var cy := int(floor(player.global_position.z / CityConfig.CHUNK_SIZE_M))
    _refresh(cx, cy)

func _refresh(cx: int, cy: int) -> void:
    var unload_r := stream_radius + CityConfig.STREAM_UNLOAD_BUFFER
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
        var status := ResourceLoader.load_threaded_get_status(path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            var scene := ResourceLoader.load_threaded_get(path) as PackedScene
            _place_chunk(key, scene)
            _pending.erase(key)
        elif status == ResourceLoader.THREAD_LOAD_FAILED:
            _pending.erase(key)

func _request_chunk(key: Vector2i) -> void:
    if key.x < 0 or key.y < 0 or key.x >= CityConfig.CHUNKS_COLS or key.y >= CityConfig.CHUNKS_ROWS:
        return
    var path := "%schunk_%d_%d.tscn" % [CityConfig.CHUNK_OUTPUT_DIR, key.x, key.y]
    if not ResourceLoader.exists(path):
        return
    ResourceLoader.load_threaded_request(path, "PackedScene", true)
    _pending[key] = path

func _place_chunk(key: Vector2i, scene: PackedScene) -> void:
    if scene == null:
        return
    var inst := scene.instantiate()
    inst.name = "Chunk_%d_%d" % [key.x, key.y]
    inst.position = Vector3(key.x * CityConfig.CHUNK_SIZE_M, 0, key.y * CityConfig.CHUNK_SIZE_M)
    add_child(inst)
    _loaded[key] = inst

func _unload_chunk(key: Vector2i) -> void:
    var inst: Node3D = _loaded[key]
    inst.queue_free()
    _loaded.erase(key)
