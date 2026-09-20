# BlockLoader — runtime streaming for V2 city blocks.
#
# Replaces V1's chunk_streamer with block-based streaming.
# Blocks are prebaked (no runtime generation); this just loads/unloads them
# based on player position.
#
# Tuning philosophy:
#   - stream_radius_m: how far you can SEE blocks (m). Lower = fewer blocks.
#   - unload_radius_m: cleanup threshold (m). Tight buffer = faster cleanup.
#   - max_loaded_blocks: hard cap. If exceeded, furthest block gets unloaded
#     even if within stream radius (overflow protection).
#   - max_loads_per_frame: per-frame loading budget (avoids hitches).
#   - FPS-aware throttling: if FPS drops, slow loading to avoid death spiral.

extends Node
class_name BlockLoader

const BLOCK_DIR := "res://scenes/baked_v2/"
const BLOCK_INDEX_PATH := "res://data/block_index.json"

# === TUNING (editable at runtime for debug; defaults conservative) ===
# Load all blocks whose CENTER is within this distance of player (meters).
# Default 300m = ~3 block radius around player (blocks are 150-250m wide).
@export var stream_radius_m: float = 300.0
# Unload blocks beyond this distance (meters). Hysteresis prevents flicker.
# Buffer = unload_radius_m - stream_radius_m = 100m (~1 block).
@export var unload_radius_m: float = 400.0
# Hard cap on simultaneously loaded blocks. If exceeded, unload furthest
# even if within stream radius. Overflow protection for fast travel.
@export var max_loaded_blocks: int = 15
# Max blocks to load per frame. 3 = balanced (no hitch).
# Lowered automatically to 1 when FPS < 30, frozen when FPS < 20.
@export var max_loads_per_frame: int = 3
# FPS thresholds for throttling.
const FPS_THROTTLE_THRESHOLD: float = 30.0
const FPS_FREEZE_THRESHOLD: float = 20.0
# How often to recompute FPS (frames between samples).
const FPS_SAMPLE_INTERVAL: int = 30
# Stats print interval (seconds)
const STATS_PRINT_INTERVAL: float = 5.0

# Block index: [{index: int, center: Vector3, width: float, depth: float}, ...]
var _block_index: Array = []
# Loaded blocks: index -> Node3D
var _loaded: Dictionary = {}
# Player reference (set by parent)
var _player: Node = null
# Parent container for blocks
var _blocks_root: Node3D = null
# FPS tracking
var _frame_count: int = 0
var _current_fps: float = 60.0
var _fps_accumulator: float = 0.0
# Stats print timer
var _stats_timer: float = 0.0

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
		print("[BlockLoader] ready — %d blocks indexed, stream %.0fm, unload %.0fm, max %d" % [
			_block_index.size(), stream_radius_m, unload_radius_m, max_loaded_blocks
		])

func _process(delta: float):
	if _player == null or _blocks_root == null or _block_index.is_empty():
		return

	# Track FPS (smoothed over FPS_SAMPLE_INTERVAL frames)
	_frame_count += 1
	_fps_accumulator += 1.0 / maxf(delta, 0.001)
	if _frame_count >= FPS_SAMPLE_INTERVAL:
		_current_fps = _fps_accumulator / float(_frame_count)
		_frame_count = 0
		_fps_accumulator = 0.0

	# Stats print every STATS_PRINT_INTERVAL seconds
	_stats_timer += delta
	if _stats_timer >= STATS_PRINT_INTERVAL:
		_stats_timer = 0.0
		print("[BlockLoader] stats: loaded=%d/%d, fps=%.0f, pos=%s" % [
			_loaded.size(), _block_index.size(), _current_fps, _player.global_position
		])

	var ppos: Vector3 = _player.global_position

	# Find blocks that need loading (within stream_radius_m, not yet loaded)
	var to_load: Array = []
	for entry in _block_index:
		var idx: int = entry.index
		if _loaded.has(idx):
			continue
		var center: Vector3 = entry.center
		var d: float = Vector2(ppos.x - center.x, ppos.z - center.z).length()
		# Use block center distance (no half-width padding — that was too generous)
		if d <= stream_radius_m:
			to_load.append({"index": idx, "distance": d})

	# Sort nearest-first
	to_load.sort_custom(func(a, b): return a.distance < b.distance)

	# FPS-aware load budget
	var load_budget: int = max_loads_per_frame
	if _current_fps < FPS_FREEZE_THRESHOLD:
		load_budget = 0  # freeze loading entirely
	elif _current_fps < FPS_THROTTLE_THRESHOLD:
		load_budget = 1   # slow down

	# Overflow protection: if we'd exceed max_loaded_blocks, unload furthest first
	while _loaded.size() + min(load_budget, to_load.size()) > max_loaded_blocks and not _loaded.is_empty():
		_evict_furthest_loaded(ppos)

	# Load up to budget (may be 0 if FPS is critical)
	var n: int = min(to_load.size(), load_budget)
	for i in range(n):
		_load_block(to_load[i].index, to_load[i].distance)

	# Unload distant blocks (beyond unload_radius_m)
	var to_unload: Array = []
	for idx in _loaded:
		var entry: Dictionary = _block_index[idx]
		var center: Vector3 = entry.center
		var d: float = Vector2(ppos.x - center.x, ppos.z - center.z).length()
		if d > unload_radius_m:
			to_unload.append(idx)
	for idx in to_unload:
		_unload_block(idx)

# Evict the furthest loaded block (used for overflow protection)
func _evict_furthest_loaded(ppos: Vector3):
	var furthest_idx: int = -1
	var furthest_dist: float = -1.0
	for idx in _loaded:
		var entry: Dictionary = _block_index[idx]
		var center: Vector3 = entry.center
		var d: float = Vector2(ppos.x - center.x, ppos.z - center.z).length()
		if d > furthest_dist:
			furthest_dist = d
			furthest_idx = idx
	if furthest_idx >= 0:
		print("[BlockLoader] ! evicting furthest block_%d (%.0fm) for overflow" % [furthest_idx, furthest_dist])
		_unload_block(furthest_idx)

func _load_block(idx: int, distance: float = 0.0):
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

func _unload_block(idx: int):
	var inst: Node = _loaded[idx]
	if inst:
		inst.queue_free()
	_loaded.erase(idx)

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

# === Public API ===
func get_loaded_count() -> int:
	return _loaded.size()

func get_total_count() -> int:
	return _block_index.size()

func get_current_fps() -> float:
	return _current_fps
