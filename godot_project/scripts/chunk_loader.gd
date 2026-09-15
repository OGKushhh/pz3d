extends Node3D

const CHUNK_SIZE := 250.0
const CHUNKS_COLS := 16
const CHUNKS_ROWS := 12
const STREAM_RADIUS := 2  # load 5x5 = 25 chunks around player
const CHUNK_DIR := "res://scenes/baked_chunks/"

var player: CharacterBody3D
var loaded_chunks: Dictionary = {}  # Vector2i -> Node3D
var last_chunk: Vector2i = Vector2i(-999, -999)

func _ready():
	# Find player (wait a frame so it's added)
	await get_tree().process_frame
	player = get_parent().get_node_or_null("Player")
	if player == null:
		for c in get_parent().get_children():
			if c is CharacterBody3D:
				player = c
				break
	print("[ChunkLoader] ready, player at ", player.global_position if player else "null")
	# Force initial chunk load
	if player:
		var cx := int(player.global_position.x / CHUNK_SIZE)
		var cz := int(player.global_position.z / CHUNK_SIZE)
		_refresh(Vector2i(cx, cz))

func _process(_delta):
	if player == null:
		return
	var cx := int(player.global_position.x / CHUNK_SIZE)
	var cz := int(player.global_position.z / CHUNK_SIZE)
	var current_chunk := Vector2i(cx, cz)
	if current_chunk == last_chunk:
		return
	last_chunk = current_chunk
	_refresh(current_chunk)

func _refresh(center: Vector2i):
	# Load chunks in radius
	for dy in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
		for dx in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
			var key := Vector2i(center.x + dx, center.y + dy)
			if key.x < 0 or key.y < 0 or key.x >= CHUNKS_COLS or key.y >= CHUNKS_ROWS:
				continue
			if not loaded_chunks.has(key):
				_load_chunk(key)
	# Unload distant chunks
	var unload_r := STREAM_RADIUS + 1
	var to_unload: Array = []
	for key in loaded_chunks:
		var dx: int = abs(key.x - center.x)
		var dy: int = abs(key.y - center.y)
		if dx > unload_r or dy > unload_r:
			to_unload.append(key)
	for key in to_unload:
		_unload_chunk(key)

func _load_chunk(key: Vector2i):
	var path := "%schunk_%d_%d.tscn" % [CHUNK_DIR, key.x, key.y]
	if not ResourceLoader.exists(path):
		return  # no file (water/empty chunk)
	var scene := load(path) as PackedScene
	if scene == null:
		return
	var inst := scene.instantiate()
	inst.name = "Chunk_%d_%d" % [key.x, key.y]
	get_parent().add_child(inst)
	loaded_chunks[key] = inst

func _unload_chunk(key: Vector2i):
	var inst: Node = loaded_chunks[key]
	inst.queue_free()
	loaded_chunks.erase(key)
