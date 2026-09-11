# City Builder — orchestrator. Loops all chunks, saves each as .tscn.
# This file does NOT do placement work — that's chunk_builder.gd.
class_name CityBuilder
extends Node3D

const CFG        := preload("res://tools/city_config.gd")
const SpatialIdx := preload("res://tools/spatial_index.gd")
const ChunkBld   := preload("res://tools/chunk_builder.gd")
const MetaCls    := preload("res://tools/city_meta.gd")
const RoadNet    := preload("res://tools/road_network.gd")

const MANIFEST_PATH := "res://data/city_manifest.json"

signal chunk_built(chunk_x: int, chunk_y: int, biome: int)
signal city_complete(stats: Dictionary)

@export var map_seed: int = 1337
@export var skip_if_valid: bool = true

var manifest: Dictionary = {}
var asset_cache: Dictionary = {}
var spatial: SpatialIndex
var roads: RoadNetwork

func _ready() -> void:
    _load_manifest()

func build_all() -> Dictionary:
    var t0 := Time.get_ticks_msec()

    if skip_if_valid:
        var existing := MetaCls.load_existing()
        if existing and existing.is_valid_for(manifest):
            print("[CityBuilder] Chunks valid, skipping rebuild (seed %d)" % existing.map_seed)
            return {"skipped": true, "seed": existing.map_seed}

    spatial = SpatialIdx.new(CFG.SPATIAL_CELL_M)

    # 1. Road network (before chunks)
    roads = RoadNet.new()
    var map_rng := RandomNumberGenerator.new()
    map_rng.seed = map_seed
    roads.generate(map_rng)
    _mark_roads_in_spatial()

    # 2. Chunks
    _ensure_output_dir()
    var stats := {"chunks": 0, "biomes": {}}
    for cy in range(CFG.CHUNKS_ROWS):
        for cx in range(CFG.CHUNKS_COLS):
            if _build_one_chunk(cx, cy, stats):
                chunk_built.emit(cx, cy, _biome_at_chunk(cx, cy))

    # 3. Save meta
    MetaCls.generate(map_seed, manifest).save()

    stats["ms"] = Time.get_ticks_msec() - t0
    city_complete.emit(stats)
    print("[CityBuilder] Built %d chunks in %d ms" % [stats["chunks"], stats["ms"]])
    return stats

func build_chunk_range(cx0: int, cy0: int, cx1: int, cy1: int) -> void:
    spatial = SpatialIdx.new(CFG.SPATIAL_CELL_M)
    roads = RoadNet.new()
    var map_rng := RandomNumberGenerator.new()
    map_rng.seed = map_seed
    roads.generate(map_rng)
    _mark_roads_in_spatial()
    var stats := {"chunks": 0, "biomes": {}}
    for cy in range(cy0, cy1 + 1):
        for cx in range(cx0, cx1 + 1):
            _build_one_chunk(cx, cy, stats)
    print("[CityBuilder] Rebuilt %d chunks" % stats["chunks"])

func _load_manifest() -> void:
    if not FileAccess.file_exists(MANIFEST_PATH):
        push_error("[CityBuilder] Missing manifest: " + MANIFEST_PATH)
        return
    var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
    manifest = JSON.parse_string(f.get_as_text())
    print("[CityBuilder] Manifest: %d assets" % manifest.size())

func _ensure_output_dir() -> void:
    var abs_dir := ProjectSettings.globalize_path(CFG.CHUNK_OUTPUT_DIR)
    DirAccess.make_dir_recursive_absolute(abs_dir)

func _biome_at_chunk(cx: int, cy: int) -> int:
    var col := clamp(int(cx * CFG.CHUNK_SIZE_M / CFG.CELL_SIZE_M), 0, CFG.GRID_COLS - 1)
    var row := clamp(int(cy * CFG.CHUNK_SIZE_M / CFG.CELL_SIZE_M), 0, CFG.GRID_ROWS - 1)
    return CFG.grid_layout()[row][col]

func _build_one_chunk(cx: int, cy: int, stats: Dictionary) -> bool:
    var biome := _biome_at_chunk(cx, cy)
    if biome == CFG.Biome.RIVER or biome == CFG.Biome.SUBWAY or biome == CFG.Biome.WATER:
        return false
    var origin := Vector3(cx * CFG.CHUNK_SIZE_M, 0, cy * CFG.CHUNK_SIZE_M)
    var chunk_seed := hash(Vector2i(cx, cy)) ^ map_seed
    var builder := ChunkBld.new(spatial, roads, manifest, asset_cache, chunk_seed)
    var chunk_root := builder.build(biome, origin)

    var packed := PackedScene.new()
    packed.pack(chunk_root)
    var path := "%schunk_%d_%d.tscn" % [CFG.CHUNK_OUTPUT_DIR, cx, cy]
    var err := ResourceSaver.save(packed, path)
    chunk_root.free()
    if err != OK:
        push_error("[CityBuilder] Failed to save %s: %d" % [path, err])
        return false

    stats["chunks"] += 1
    var bname: String = CFG.biomes()[biome]["name"]
    stats["biomes"][bname] = stats["biomes"].get(bname, 0) + 1
    return true

func _mark_roads_in_spatial() -> void:
    var half_w := CFG.ROAD_WIDTH * 0.5 + CFG.PROP_ROAD_CLEARANCE
    for s in roads.segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        var dist := a.distance_to(b)
        var steps := int(ceil(dist / CFG.SPATIAL_CELL_M))
        for i in range(steps + 1):
            var t := float(i) / float(max(steps, 1))
            spatial.mark_road(a.lerp(b, t), half_w)
