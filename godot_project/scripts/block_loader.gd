# BlockLoader — runtime streaming for V2 city blocks.
#
# Replaces V1's chunk_streamer with block-based streaming.
# Blocks are prebaked (no runtime generation); this just loads/unloads them
# based on player position.
#
# Use:
#       - main.tscn has empty `Blocks` Node3D + Player with this script as child
#       - Each frame: check player position, load nearby blocks, unload far ones
#
# Block file path: res://scenes/baked_v2/block_<i>.tscn
# Block index → block_center stored in res://data/block_index.json (built by city_v2_baker.gd)
#
# Streaming radius: STREAM_RADIUS blocks in each direction (default 3 → 7x7=49 blocks loaded max)
# Actually we use distance not index offset, because blocks aren't on a uniform grid.

extends Node
class_name BlockLoader

const BLOCK_DIR := "res://scenes/baked_v2/"
const BLOCK_INDEX_PATH := "res://data/block_index.json"

# Streaming: load all blocks within this distance of player (meters)
const STREAM_RADIUS_M := 500.0
# Unload blocks beyond this distance (meters)
const UNLOAD_RADIUS_M := 700.0
# Max blocks to load per frame (avoids hitches when teleporting)
const MAX_LOADS_PER_FRAME := 3

# Block index: [{index: int, center: Vector3, width: float, depth: float}, ...]
var _block_index: Array = []
# Loaded blocks: index -> Node3D
var _loaded: Dictionary = {}
# Player reference (set by parent)
var _player: Node = null
# Parent container for blocks
var _blocks_root: Node3D = null

func _ready():
	_load_block_index()
	# Find player + blocks container
	await get_tree().process_frame
	_player = get_node_or_null("../Player")
	_blocks_root = get_node_or_null("../Blocks")
	if _player == null:
		printerr("[BlockLoader] Player not found at ../Player")
	if _blocks_root == null:
		printerr("[BlockLoader] Blocks container not found at ../Blocks")
	else:
		print("[BlockLoader] ready — %d blocks indexed, radius %.0fm" % [_block_index.size(), STREAM_RADIUS_M])

func _process(_delta: float):
	if _player == null or _blocks_root == null or _block_index.is_empty():
		return

	var ppos: Vector3 = _player.global_position

	# Find blocks that need loading (within STREAM_RADIUS_M, not yet loaded)
	var to_load: Array = []
	for entry in _block_index:
		var idx: int = entry.index
		if _loaded.has(idx):
			continue
		var center: Vector3 = entry.center
		var d: float = Vector2(ppos.x - center.x, ppos.z - center.z).length()
		if d <= STREAM_RADIUS_M + max(entry.width, entry.depth) * 0.5:
			to_load.append({"index": idx, "distance": d})

	# Sort nearest-first, load only MAX_LOADS_PER_FRAME
	to_load.sort_custom(func(a, b): return a.distance < b.distance)
	var n: int = min(to_load.size(), MAX_LOADS_PER_FRAME)
	for i in range(n):
		_load_block(to_load[i].index)

	# Unload distant blocks
	var to_unload: Array = []
	for idx in _loaded:
		var entry: Dictionary = _block_index[idx]
		var center: Vector3 = entry.center
		var d: float = Vector2(ppos.x - center.x, ppos.z - center.z).length()
		if d > UNLOAD_RADIUS_M:
			to_unload.append(idx)
	for idx in to_unload:
		_unload_block(idx)

func _load_block(idx: int):
	var path := "%sblock_%d.tscn" % [BLOCK_DIR, idx]
	if not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	if scene == null:
		return
	var inst := scene.instantiate()
	inst.name = "Block_%d" % idx
	_blocks_root.add_child(inst)
	_loaded[idx] = inst
	print("[BlockLoader] + loaded block_%d (total: %d)" % [idx, _loaded.size()])

func _unload_block(idx: int):
	var inst: Node = _loaded[idx]
	if inst:
		inst.queue_free()
	_loaded.erase(idx)
	print("[BlockLoader] - unloaded block_%d (total: %d)" % [idx, _loaded.size()])

func _load_block_index():
	var f := FileAccess.open(BLOCK_INDEX_PATH, FileAccess.READ)
	if f == null:
		printerr("[BlockLoader] block_index.json not found at ", BLOCK_INDEX_PATH, " — run city_v2_baker.gd first")
		return
	var json_text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Array:
		printerr("[BlockLoader] block_index.json parse failed")
		return
	# Convert String center "(x, y, z)" back to Vector3
	_block_index.clear()
	for entry in parsed:
		var center_str: String = entry.get("center", "")
		var v := _parse_vector3(center_str)
		_block_index.append({
			"index": int(entry.get("index", 0)),
			"center": v,
			"width": float(entry.get("width", 0.0)),
			"depth": float(entry.get("depth", 0.0)),
		})

func _parse_vector3(s: String) -> Vector3:
	# Format: "(75.0, 0.0, 275.0)"
	var t := s.replace("(", "").replace(")", "")
	var parts := t.split(",")
	if parts.size() < 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))

# Public API for debugging
func get_loaded_count() -> int:
	return _loaded.size()

func get_total_count() -> int:
	return _block_index.size()
