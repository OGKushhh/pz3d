class_name CityBuilder
# City Builder — orchestrator. Loops all chunks, saves each as .tscn.
# This file does NOT do placement work — that's chunk_builder.gd.
extends Node3D







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
        var existing: CityMeta = CityMeta.load_existing()
        if existing != null and existing.is_valid_for(manifest):
            print("[CityBuilder] Chunks valid, skipping rebuild (seed %d)" % existing.map_seed)
            return {"skipped": true, "seed": existing.map_seed}
        elif existing != null:
            for reason in existing.invalid_reasons(manifest):
                print("[CityBuilder] stale: %s" % reason)

    spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)

    # 1. Road network (before chunks)
    roads = RoadNetwork.new()
    var map_rng := RandomNumberGenerator.new()
    map_rng.seed = map_seed
    roads.generate(map_rng)
    roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)

    # 2. Chunks
    _ensure_output_dir()
    var stats: Dictionary = {"chunks": 0, "biomes": {}}
    for cy in range(CityConfig.CHUNKS_ROWS):
        for cx in range(CityConfig.CHUNKS_COLS):
            if _build_one_chunk(cx, cy, stats):
                chunk_built.emit(cx, cy, _biome_at_chunk(cx, cy))

    # 3. Save meta
    CityMeta.generate(map_seed, manifest).save()

    stats["ms"] = Time.get_ticks_msec() - t0
    city_complete.emit(stats)
    print("[CityBuilder] Built %d chunks in %d ms" % [stats["chunks"], stats["ms"]])
    return stats

func build_chunk_range(cx0: int, cy0: int, cx1: int, cy1: int) -> void:
    spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
    roads = RoadNetwork.new()
    var map_rng := RandomNumberGenerator.new()
    map_rng.seed = map_seed
    roads.generate(map_rng)
    roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)
    var stats: Dictionary = {"chunks": 0, "biomes": {}}
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
    var abs_dir := ProjectSettings.globalize_path(CityConfig.CHUNK_OUTPUT_DIR)
    DirAccess.make_dir_recursive_absolute(abs_dir)

func _biome_at_chunk(cx: int, cy: int) -> int:
    var col: int = clamp(int(cx * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
    var row: int = clamp(int(cy * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
    return CityConfig.grid_layout()[row][col]

func _build_one_chunk(cx: int, cy: int, stats: Dictionary) -> bool:
    var biome := _biome_at_chunk(cx, cy)
    if biome == CityConfig.Biome.RIVER or biome == CityConfig.Biome.WATER:
        return false
    var origin := Vector3(cx * CityConfig.CHUNK_SIZE_M, 0, cy * CityConfig.CHUNK_SIZE_M)
    var chunk_seed := hash(Vector2i(cx, cy)) ^ map_seed
    var builder: ChunkBuilder = ChunkBuilder.new(spatial, roads, manifest, asset_cache, chunk_seed, Vector2i(cx, cy))
    var chunk_root := builder.build(biome, origin)

    # Add to scene tree so owner can be set on children
    add_child(chunk_root)
    # Set owner on all children recursively
    _set_owner_recursive(chunk_root, chunk_root)
    # Pack
    var packed := PackedScene.new()
    packed.pack(chunk_root)
    var path := "%schunk_%d_%d.tscn" % [CityConfig.CHUNK_OUTPUT_DIR, cx, cy]
    var err := ResourceSaver.save(packed, path)
    # Remove from tree
    remove_child(chunk_root)
    chunk_root.free()
    if err != OK:
        push_error("[CityBuilder] Failed to save %s: %d" % [path, err])
        return false

    stats["chunks"] += 1
    var bname: String = String(CityConfig.biomes()[biome]["name"])
    stats["biomes"][bname] = stats["biomes"].get(bname, 0) + 1
    return true

func _set_owner_recursive(node: Node, owner: Node) -> void:
    for child in node.get_children():
        child.owner = owner
        _set_owner_recursive(child, owner)
