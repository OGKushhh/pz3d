#Here's a single Python script that writes every file into `./mazar_city_builder/`. Run it, then point the other AI at the folder.
#!/usr/bin/env python3
"""
Generates the full Mazar city builder architecture as GDScript files.
Run: python3 generate_mazar.py
Output: ./mazar_city_builder/ containing all .gd + .json + README.md
"""

import os, json, textwrap

ROOT = "mazar_city_builder"

FILES = {}

# ─────────────────────────────────────────────────────────
FILES["tools/city_config.gd"] = r'''# Mazar City Config — single source of truth for all tunable values.
# GLM: edit this file to change biomes, dimensions, or rules.
# DO NOT restructure — data only, no logic beyond the static helpers.
class_name CityConfig
extends RefCounted

enum Biome {
    SUBURBIA, PARKS, FOREST, FARMLAND, COMMERCIAL,
    INDUSTRIAL, RIVER, SUBWAY, DOWNTOWN, MILITARY, WATER, EMPTY
}

# ── MAP DIMENSIONS ────────────────────────────────────────
# 12 km² alpha  →  Vector2(4000, 3000), GRID 8×6
# 30 km² beta   →  Vector2(6000, 5000), GRID 12×10
# 100 km² v1    →  Vector2(10000, 10000), GRID 20×20
const MAP_SIZE_M   := Vector2(6000.0, 5000.0)
const GRID_COLS    := 12
const GRID_ROWS    := 10
const CELL_SIZE_M  := MAP_SIZE_M.x / GRID_COLS
const CHUNK_SIZE_M := 250.0
const CHUNKS_COLS  := int(MAP_SIZE_M.x / CHUNK_SIZE_M)
const CHUNKS_ROWS  := int(MAP_SIZE_M.y / CHUNK_SIZE_M)

# ── PLACEMENT RULES ───────────────────────────────────────
const ROAD_WIDTH          := 8.0
const SIDEWALK_WIDTH      := 2.0
const BUILDING_SETBACK    := 4.0
const STREETLIGHT_SPACING := 25.0
const PROP_ROAD_CLEARANCE := 2.0
const SPATIAL_CELL_M      := 8.0

# ── STREAMING ─────────────────────────────────────────────
const STREAM_RADIUS      := 1
const STREAM_UNLOAD_BUFFER := 1
const CHUNK_OUTPUT_DIR   := "res://chunks/"

# ── OWNERSHIP RULES ───────────────────────────────────────
# CENTROID RULE: an object belongs to the chunk containing its center.
# ROAD OWNERSHIP: a road segment belongs to the chunk where its perpendicular
#   axis falls in [chunk_min, chunk_max). Horizontal roads → Z-chunk.
#   Vertical roads → X-chunk. Non-owner chunks still QUERY for setback math
#   but do not render or place lights on non-owned segments.

# ── BIOME PROFILES ────────────────────────────────────────
static func biomes() -> Dictionary:
    return {
        Biome.SUBURBIA:   {"name":"Suburbia",         "fill":0.55, "buildings":["suburban_house_v2","two_story_colonial","bungalow"], "props":["mailbox","trash_can","picket_fence"], "foliage":["oak_tree","bush"],       "lights":true,  "zombies":10},
        Biome.PARKS:      {"name":"Parks & Greenways", "fill":0.20, "buildings":[], "props":[], "foliage":["oak_tree","bush"],                                          "lights":false, "zombies":5},
        Biome.FOREST:     {"name":"Forest",            "fill":0.85, "buildings":["shed"], "props":[], "foliage":["pine_tree","birch_tree","bush"],                 "lights":false, "zombies":5},
        Biome.FARMLAND:   {"name":"Farmland",          "fill":0.35, "buildings":["shed","garage_detached"], "props":["picket_fence"], "foliage":["oak_tree","bush"],   "lights":false, "zombies":3},
        Biome.COMMERCIAL: {"name":"Commercial Strip",  "fill":0.75, "buildings":["two_story_colonial"], "props":["trash_can","mailbox"], "foliage":["oak_tree"],           "lights":true,  "zombies":10},
        Biome.INDUSTRIAL: {"name":"Industrial Park",   "fill":0.60, "buildings":["garage_detached"], "props":["trash_can"], "foliage":[],                             "lights":true,  "zombies":8},
        Biome.RIVER:      {"name":"River & Wetlands",  "fill":0.15, "buildings":["shed"], "props":["picket_fence"], "foliage":["bush"],                            "lights":false, "zombies":4},
        Biome.SUBWAY:     {"name":"Subway",            "fill":0.00, "buildings":[], "props":[], "foliage":[],                                                     "lights":false, "zombies":8},
        Biome.DOWNTOWN:   {"name":"Downtown",          "fill":0.90, "buildings":["two_story_colonial"], "props":["trash_can","mailbox"], "foliage":["oak_tree"],           "lights":true,  "zombies":15},
        Biome.MILITARY:   {"name":"Military Zone",     "fill":0.40, "buildings":["garage_detached"], "props":["trash_can"], "foliage":[],                             "lights":false, "zombies":15},
        Biome.WATER:      {"name":"Water",             "fill":0.00, "buildings":[], "props":[], "foliage":[],                                                     "lights":false, "zombies":0},
        Biome.EMPTY:      {"name":"Empty",             "fill":0.00, "buildings":[], "props":[], "foliage":[],                                                     "lights":false, "zombies":0},
    }

# ── GRID LAYOUT (12×10 for 30 km²) ────────────────────────
static func grid_layout() -> Array:
    var F  := Biome.FOREST
    var FA := Biome.FARMLAND
    var IN := Biome.INDUSTRIAL
    var MI := Biome.MILITARY
    var RI := Biome.RIVER
    var SU := Biome.SUBURBIA
    var PA := Biome.PARKS
    var CO := Biome.COMMERCIAL
    var DT := Biome.DOWNTOWN
    return [
        [F,F,F,FA,FA,RI,RI,IN,IN,MI,MI,MI],
        [F,F,FA,FA,FA,RI,RI,IN,IN,MI,MI,MI],
        [F,FA,FA,FA,PA,RI,RI,IN,IN,MI,MI,MI],
        [SU,SU,FA,FA,PA,RI,RI,IN,IN,DT,DT,MI],
        [SU,SU,CO,CO,PA,RI,RI,DT,DT,DT,DT,IN],
        [SU,SU,CO,CO,CO,RI,RI,DT,DT,DT,DT,IN],
        [SU,PA,CO,CO,CO,RI,RI,DT,DT,DT,IN,IN],
        [SU,SU,CO,CO,IN,RI,RI,DT,DT,IN,IN,IN],
        [PA,SU,SU,CO,IN,RI,RI,IN,IN,IN,IN,IN],
        [PA,SU,SU,SU,IN,RI,RI,RI,IN,IN,IN,IN],
    ]

static func bridges() -> Array:
    return [
        {"row":4, "from_col":4, "to_col":7, "name":"Sarran Bridge"},
        {"row":6, "from_col":4, "to_col":7, "name":"Old Town Bridge"},
    ]

static func sky_colors() -> Dictionary:
    return {
        "top":     Color(0.35, 0.55, 0.85),
        "horizon": Color(0.85, 0.80, 0.70),
        "ground":  Color(0.20, 0.20, 0.22),
        "fog":     Color(0.72, 0.72, 0.75),
        "sun_rot": Vector3(-45, 30, 0),
    }
'''

# ─────────────────────────────────────────────────────────
FILES["tools/spatial_index.gd"] = r'''# O(1) spatial occupancy grid. Replaces linear arrays that break past 5k placements.
# Correctness: insert marks every cell the disc overlaps; query scans the matching
# window. Verified by res://tests/spatial_index_test.gd.
class_name SpatialIndex
extends RefCounted

var _occupied: Dictionary = {}
var _road: Dictionary = {}
var cell_size: float

func _init(cell_m: float = 8.0) -> void:
    cell_size = cell_m

func _key(pos: Vector3) -> Vector2i:
    return Vector2i(int(floor(pos.x / cell_size)), int(floor(pos.z / cell_size)))

func is_free(pos: Vector3, radius: float) -> bool:
    var r := int(ceil(radius / cell_size))
    var c := _key(pos)
    for dx in range(-r, r + 1):
        for dz in range(-r, r + 1):
            var k := c + Vector2i(dx, dz)
            if not _occupied.has(k):
                continue
            for o in _occupied[k]:
                if pos.distance_to(o["pos"]) < radius + o["radius"]:
                    return false
    return true

func insert(pos: Vector3, radius: float) -> void:
    var r := int(ceil(radius / cell_size))
    var c := _key(pos)
    for dx in range(-r, r + 1):
        for dz in range(-r, r + 1):
            var k := c + Vector2i(dx, dz)
            if not _occupied.has(k):
                _occupied[k] = []
            _occupied[k].append({"pos": pos, "radius": radius})

func mark_road(pos: Vector3, half_width: float) -> void:
    var r := int(ceil(half_width / cell_size))
    var c := _key(pos)
    for dx in range(-r, r + 1):
        for dz in range(-r, r + 1):
            _road[c + Vector2i(dx, dz)] = true

func is_road_clear(pos: Vector3) -> bool:
    return not _road.has(_key(pos))

func clear() -> void:
    _occupied.clear()
    _road.clear()
'''

# ─────────────────────────────────────────────────────────
FILES["tools/city_meta.gd"] = r'''# Mazar City Meta — deterministic seed + stale-build detection.
# Hashes the asset manifest AND the builder scripts, so any edit to
# chunk_builder.gd or city_config.gd auto-invalidates existing chunks.
class_name CityMeta
extends RefCounted

const META_PATH := "res://chunks/city_meta.json"
const LAYOUT_VERSION := 1

const WATCHED_SCRIPTS := [
    "res://tools/chunk_builder.gd",
    "res://tools/city_config.gd",
]

var map_seed: int
var manifest_hash: String
var builder_hash: String
var layout_version: int
var built_at: String

static func generate(p_map_seed: int, manifest: Dictionary) -> CityMeta:
    var m := CityMeta.new()
    m.map_seed = p_map_seed
    m.manifest_hash = _hash_manifest(manifest)
    m.builder_hash = _hash_builders()
    m.layout_version = LAYOUT_VERSION
    m.built_at = Time.get_datetime_string_from_system()
    return m

static func _hash_manifest(manifest: Dictionary) -> String:
    var keys: Array = manifest.keys()
    keys.sort()
    var payload := ""
    for k in keys:
        payload += "%s:%s;" % [k, manifest[k].get("path", "")]
    return payload.sha256_text()

static func _hash_builders() -> String:
    var payload := ""
    for p in WATCHED_SCRIPTS:
        if FileAccess.file_exists(p):
            payload += FileAccess.get_file_as_string(p)
    return payload.sha256_text()

func save() -> void:
    var f := FileAccess.open(META_PATH, FileAccess.WRITE)
    if f == null:
        push_error("[CityMeta] Cannot write " + META_PATH)
        return
    f.store_string(JSON.stringify({
        "map_seed": map_seed,
        "manifest_hash": manifest_hash,
        "builder_hash": builder_hash,
        "layout_version": layout_version,
        "built_at": built_at,
    }, "  "))

static func load_existing() -> CityMeta:
    if not FileAccess.file_exists(META_PATH):
        return null
    var f := FileAccess.open(META_PATH, FileAccess.READ)
    if f == null:
        return null
    var data = JSON.parse_string(f.get_as_text())
    if typeof(data) != TYPE_DICTIONARY:
        push_warning("[CityMeta] Corrupt meta file — treating as missing")
        return null
    var m := CityMeta.new()
    m.map_seed       = int(data.get("map_seed", 0))
    m.manifest_hash  = String(data.get("manifest_hash", ""))
    m.builder_hash   = String(data.get("builder_hash", ""))
    m.layout_version = int(data.get("layout_version", 0))
    m.built_at       = String(data.get("built_at", ""))
    return m

func is_valid_for(manifest: Dictionary) -> bool:
    return layout_version == LAYOUT_VERSION \
        and manifest_hash == _hash_manifest(manifest) \
        and builder_hash == _hash_builders()
'''

# ─────────────────────────────────────────────────────────
FILES["tools/road_network.gd"] = r'''# Road Network — generated ONCE from map seed, BEFORE any chunk builds.
# Chunks query this for setback math and clipped road rendering.
# Ownership rule: a segment belongs to the chunk where its perpendicular
# axis falls in [chunk_min, chunk_max). Non-owner chunks still query for
# setback math but do not render or place lights on non-owned segments.
class_name RoadNetwork
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

var segments: Array = []

func generate(rng: RandomNumberGenerator) -> void:
    segments.clear()
    _build_grid_roads(rng)
    _build_bridges(rng)
    _build_highway(rng)

func _build_grid_roads(_rng: RandomNumberGenerator) -> void:
    for row in range(CFG.GRID_ROWS + 1):
        if (row % 2) != 0:
            continue
        var z := row * CFG.CELL_SIZE_M
        for col in range(CFG.GRID_COLS):
            segments.append({
                "start": Vector3(col * CFG.CELL_SIZE_M, 0, z),
                "end":   Vector3((col + 1) * CFG.CELL_SIZE_M, 0, z),
                "width": CFG.ROAD_WIDTH,
                "kind":  "street",
            })
    for col in range(CFG.GRID_COLS + 1):
        if (col % 2) != 0:
            continue
        var x := col * CFG.CELL_SIZE_M
        for row in range(CFG.GRID_ROWS):
            segments.append({
                "start": Vector3(x, 0, row * CFG.CELL_SIZE_M),
                "end":   Vector3(x, 0, (row + 1) * CFG.CELL_SIZE_M),
                "width": CFG.ROAD_WIDTH,
                "kind":  "street",
            })

func _build_bridges(_rng: RandomNumberGenerator) -> void:
    for b in CFG.bridges():
        var z := b["row"] * CFG.CELL_SIZE_M + CFG.CELL_SIZE_M * 0.5
        segments.append({
            "start": Vector3(b["from_col"] * CFG.CELL_SIZE_M, 0, z),
            "end":   Vector3(b["to_col"]   * CFG.CELL_SIZE_M, 0, z),
            "width": CFG.ROAD_WIDTH * 1.5,
            "kind":  "bridge",
            "name":  b["name"],
        })

func _build_highway(_rng: RandomNumberGenerator) -> void:
    # TODO GLM: add coastal highway + river-crossing avenue per GDD 4.2.
    pass

# ── QUERIES ───────────────────────────────────────────────

# Segments whose bbox overlaps the chunk AND which this chunk OWNS.
# Ownership: perpendicular axis falls in [chunk_min, chunk_max).
func owned_segments_in_chunk(chunk_origin: Vector3, chunk_size: float) -> Array:
    var min_x := chunk_origin.x
    var max_x := chunk_origin.x + chunk_size
    var min_z := chunk_origin.z
    var max_z := chunk_origin.z + chunk_size
    var out: Array = []
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        if a.z == b.z:
            # horizontal → owned by Z
            if a.z >= min_z and a.z < max_z:
                out.append(s)
        elif a.x == b.x:
            # vertical → owned by X
            if a.x >= min_x and a.x < max_x:
                out.append(s)
        else:
            # diagonal (future) → owned by centroid
            var mid := (a + b) * 0.5
            if mid.x >= min_x and mid.x < max_x and mid.z >= min_z and mid.z < max_z:
                out.append(s)
    return out

# All segments overlapping the chunk bbox, regardless of ownership.
# Use for setback math only — do NOT render or place lights from this list.
func overlapping_segments(chunk_origin: Vector3, chunk_size: float) -> Array:
    var min_x := chunk_origin.x
    var max_x := chunk_origin.x + chunk_size
    var min_z := chunk_origin.z
    var max_z := chunk_origin.z + chunk_size
    var out: Array = []
    for s in segments:
        var a: Vector3 = s["start"]
        var b: Vector3 = s["end"]
        if max(a.x, b.x) < min_x or min(a.x, b.x) > max_x:
            continue
        if max(a.z, b.z) < min_z or min(a.z, b.z) > max_z:
            continue
        out.append(s)
    return out

func distance_to_nearest_road(pos: Vector3) -> float:
    var best := INF
    for s in segments:
        var d := _point_segment_distance(pos, s["start"], s["end"])
        if d < best:
            best = d
    return best

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
    var ab := b - a
    if ab.length_squared() < 0.001:
        return p.distance_to(a)
    var t := clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(a + ab * t)
'''

# ─────────────────────────────────────────────────────────
FILES["tools/chunk_builder.gd"] = r'''# Chunk Builder — builds ONE 250m × 250m chunk of the city.
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
'''

# ─────────────────────────────────────────────────────────
FILES["tools/city_builder.gd"] = r'''# City Builder — orchestrator. Loops all chunks, saves each as .tscn.
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
'''

# ─────────────────────────────────────────────────────────
FILES["tools/chunk_streamer.gd"] = r'''# Runtime chunk streamer. Attach to player or manager node.
# Threaded loading with hysteresis (load radius 1, unload radius 2).
class_name ChunkStreamer
extends Node3D

const CFG := preload("res://tools/city_config.gd")

@export var player: Node3D
@export var stream_radius: int = CFG.STREAM_RADIUS

var _loaded: Dictionary = {}
var _pending: Dictionary = {}

func _process(_delta: float) -> void:
    if player == null:
        return
    var cx := int(floor(player.global_position.x / CFG.CHUNK_SIZE_M))
    var cy := int(floor(player.global_position.z / CFG.CHUNK_SIZE_M))
    _refresh(cx, cy)

func _refresh(cx: int, cy: int) -> void:
    var unload_r := stream_radius + CFG.STREAM_UNLOAD_BUFFER
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
    if key.x < 0 or key.y < 0 or key.x >= CFG.CHUNKS_COLS or key.y >= CFG.CHUNKS_ROWS:
        return
    var path := "%schunk_%d_%d.tscn" % [CFG.CHUNK_OUTPUT_DIR, key.x, key.y]
    if not ResourceLoader.exists(path):
        return
    ResourceLoader.load_threaded_request(path, "PackedScene", true)
    _pending[key] = path

func _place_chunk(key: Vector2i, scene: PackedScene) -> void:
    if scene == null:
        return
    var inst := scene.instantiate()
    inst.name = "Chunk_%d_%d" % [key.x, key.y]
    inst.position = Vector3(key.x * CFG.CHUNK_SIZE_M, 0, key.y * CFG.CHUNK_SIZE_M)
    add_child(inst)
    _loaded[key] = inst

func _unload_chunk(key: Vector2i) -> void:
    var inst: Node3D = _loaded[key]
    inst.queue_free()
    _loaded.erase(key)
'''

# ─────────────────────────────────────────────────────────
FILES["tools/interior_builder.gd"] = r'''# Interior Builder — generates one building's interior lazily on door-open.
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
'''

# ─────────────────────────────────────────────────────────
FILES["tests/spatial_index_test.gd"] = r'''# Run: godot --headless --script res://tests/spatial_index_test.gd
# Exit code 0 = pass, 1 = fail. Machine-checkable gate.
extends SceneTree

const SpatialIdx := preload("res://tools/spatial_index.gd")

var failures: int = 0

func _initialize() -> void:
    var idx := SpatialIdx.new(8.0)

    # 30m-radius object at origin.
    idx.insert(Vector3(0, 0, 0), 30.0)
    _check(not idx.is_free(Vector3(30, 0, 0), 1.0),  "+X edge not blocked")
    _check(not idx.is_free(Vector3(-30, 0, 0), 1.0), "-X edge not blocked")
    _check(not idx.is_free(Vector3(0, 0, 30), 1.0),  "+Z edge not blocked")
    _check(not idx.is_free(Vector3(0, 0, -30), 1.0), "-Z edge not blocked")
    _check(idx.is_free(Vector3(100, 0, 0), 1.0),     "false positive at 100m")

    # Small-object tracking — in CLEAN coordinates, far from origin.
    idx.insert(Vector3(1000, 0, 1000), 0.5)
    idx.insert(Vector3(1001, 0, 1001), 0.5)
    _check(not idx.is_free(Vector3(1000.5, 0, 1000.5), 1.0), "small objects not tracked")

    # Road marking.
    idx.mark_road(Vector3(200, 0, 200), 5.0)
    _check(not idx.is_road_clear(Vector3(200, 0, 200)), "road not marked")
    _check(idx.is_road_clear(Vector3(500, 0, 500)),     "false road positive")

    if failures > 0:
        print("spatial_index symmetry: FAIL (%d)" % failures)
        quit(1)
    else:
        print("spatial_index symmetry: PASS")
        quit(0)

func _check(cond: bool, msg: String) -> void:
    if not cond:
        push_error("FAIL: " + msg)
        failures += 1
'''

# ─────────────────────────────────────────────────────────
FILES["data/city_manifest.json"] = json.dumps({
    "suburban_house_v2":    {"path": "res://assets/buildings/out/suburban_house_v2.glb",    "category": "building"},
    "two_story_colonial":   {"path": "res://assets/buildings/out/two_story_colonial.glb",   "category": "building"},
    "bungalow":             {"path": "res://assets/buildings/out/bungalow.glb",             "category": "building"},
    "shed":                 {"path": "res://assets/buildings/out/shed.glb",                 "category": "building"},
    "garage_detached":      {"path": "res://assets/buildings/out/garage_detached.glb",      "category": "building"},
    "oak_tree":             {"path": "res://assets/foliage/out/oak_tree.glb",               "category": "foliage"},
    "pine_tree":            {"path": "res://assets/foliage/out/pine_tree.glb",              "category": "foliage"},
    "birch_tree":           {"path": "res://assets/foliage/out/birch_tree.glb",             "category": "foliage"},
    "bush":                 {"path": "res://assets/foliage/out/bush.glb",                   "category": "foliage"},
    "mailbox":              {"path": "res://assets/environment/out/mailbox.glb",            "category": "prop"},
    "trash_can":            {"path": "res://assets/environment/out/trash_can.glb",          "category": "prop"},
    "picket_fence":         {"path": "res://assets/environment/out/picket_fence.glb",       "category": "prop"},
    "street_light":         {"path": "res://assets/environment/out/street_light.glb",       "category": "prop"},
    "asphalt_road_segment": {"path": "res://assets/environment/out/asphalt_road_segment.glb","category": "prop"},
}, indent=2)

# ─────────────────────────────────────────────────────────
FILES["README.md"] = r'''# Mazar City Builder — Architecture Reference

Generated by `generate_mazar.py`. This folder is the reference implementation.
An agent must adapt, test, and iterate on these files — not blindly paste.

## File Map

| File | Role | Runs when |
|---|---|---|
| `tools/city_config.gd` | Pure data — biomes, dimensions, rules | Read-only |
| `tools/spatial_index.gd` | O(1) hash grid for overlap + road checks | During build |
| `tools/road_network.gd` | Global road graph | Once per city, before chunks |
| `tools/chunk_builder.gd` | **Builds ONE 250m chunk** | Once per chunk |
| `tools/city_builder.gd` | Orchestrator — loops chunks, saves .tscn | Once per city |
| `tools/chunk_streamer.gd` | Threaded load/unload at runtime | Every frame |
| `tools/interior_builder.gd` | Lazy per-building interior | On door open |
| `tools/city_meta.gd` | Seed + hashes for stale-build detection | Start/end |
| `tests/spatial_index_test.gd` | Correctness test for the hash grid | Once, before build |
| `data/city_manifest.json` | Asset name → .glb path | Loaded once |

## ABOUT chunk_builder.gd — READ THIS

`chunk_builder.gd` is the most important file in the architecture. It is
where actual asset placement happens. `city_builder.gd` just loops over
chunk coordinates and delegates to `chunk_builder` for each one.

### Current state (Priority 2)
- Buildings placed with setback math
- Props placed with `is_free` + `is_road_clear` checks
- Foliage scattered (currently `instantiate()` per tree — WILL be replaced)
- Streetlights placed on owned road segments only
- Deterministic per-chunk RNG seeded `hash(Vector2i(cx, cy)) ^ map_seed`

### Refactor targets for chunk_builder (GLM, post-Priority-2)

1. **MultiMeshInstance3D for foliage and homogeneous props.**
   Current code calls `_spawn()` per tree → one draw call per tree.
   A Forest chunk with 200 trees = 200 draw calls. This must become:
   - Group placements by asset name
   - Create one `MultiMeshInstance3D` per asset with N instances
   - Set per-instance transforms via `MultiMesh.set_instance_transform()`
   Target: 200 tree draw calls → 3 (oak/pine/bush). Biggest perf win in the project.

2. **Bake NavigationRegion3D per chunk.**
   Zombies need navmesh. Retrofit after 30 km² is miserable. Add it now
   with a trivial bake; the hooks must exist before more content lands.

3. **Physics policy for dynamic furniture.**
   `StaticBody3D` by default; promote to `RigidBody3D` when player is
   within N meters. Thousands of awake RigidBody3D = FPS death on target hardware.

4. **Merge building shells.**
   Static fixtures (kitchen counter, toilet, bathtub, built-in shelving)
   merge into a single room-shell mesh. Per GDD Part 7. Buildings become
   1 draw call for shell instead of N fixtures.

5. **Road rendering per chunk.**
   Currently roads are only marked in spatial_index, not rendered as geometry.
   When road mesh lands: chunk queries `road_network.owned_segments_in_chunk()`
   and clips asphalt tiles to its bounds. Non-owner chunks do not render.

6. **Verify chunk file size.**
   The GDD estimated ~50MB per chunk. That number is almost certainly wrong
   (instanced GLB scenes should be 100–500KB). Run `inspect_chunk.gd` on
   three chunks (Suburbia, Forest, Downtown). If embedded `ArrayMesh`
   sub-resources exist in the .tscn, meshes are being duplicated — fix
   before any further work.

### Ownership rules (document in code)
- **Centroid rule:** object belongs to the chunk containing its center.
- **Road ownership:** segment belongs to the chunk where its perpendicular
  axis falls in `[chunk_min, chunk_max)`. Horizontal → Z-chunk, vertical → X-chunk.
  Non-owner chunks still *query* for setback math but do not render.
- **Long linear structures (fences):** owned by start point; may place a few
  meters across boundary as an owned exception. Pick one rule, document it.

## Determinism Rules (load-bearing — lazy interiors depend on this)

- One `RandomNumberGenerator` per chunk, seeded `hash(Vector2i(cx, cy)) ^ map_seed`.
- Never call global `randf()` / `randi()` in the builder.
- Sort Dictionary keys before iterating when iteration feeds randomness.
- `PackedScene` saves emit a fresh random `uid://` per save. When diffing:
  `sed 's/uid="[^"]*"/uid="X"/'`. Leave `ext_resource` uids alone.

## Running

```
godot --headless --script res://tests/spatial_index_test.gd; echo "exit: $?"
godot --headless --path . res://Main.tscn --quit-after 200 2>&1 | tee run.log
```

Exit code 0 from the test = pass. Any other value = gate is closed.
'''

# ─────────────────────────────────────────────────────────
def write_all():
    for rel_path, content in FILES.items():
        full = os.path.join(ROOT, rel_path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  wrote {full}")

    # Count summary
    total_bytes = sum(len(c.encode("utf-8")) for c in FILES.values())
    print(f"\nDone. {len(FILES)} files, {total_bytes / 1024:.1f} KB total.")
    print(f"Point your reviewer AI at: ./{ROOT}/")
    print(f"Key file to review first: ./{ROOT}/tools/chunk_builder.gd")

if __name__ == "__main__":
    write_all()