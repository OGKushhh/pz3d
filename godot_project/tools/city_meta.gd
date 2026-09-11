class_name CityMeta
extends RefCounted

const META_PATH := "res://chunks/city_meta.json"
const LAYOUT_VERSION := 1

const WATCHED_SCRIPTS := [
    "res://tools/city_config.gd",
    "res://tools/chunk_builder.gd",
    "res://tools/road_network.gd",
    "res://tools/city_builder.gd",
    "res://tools/spatial_index.gd",
    "res://tools/plan_grid.gd",
]

var map_seed: int
var manifest_hash: String
var builders_hash: String
var layout_version: int
var built_at: String

static func generate(p_map_seed: int, manifest: Dictionary) -> CityMeta:
    var m := CityMeta.new()
    m.map_seed = p_map_seed
    m.manifest_hash = _hash_manifest(manifest)
    m.builders_hash = _hash_builders()
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
        if not FileAccess.file_exists(p):
            push_warning("[CityMeta] watched script not found: " + p)
            payload += p + ":MISSING;"
            continue
        payload += p + ":" + FileAccess.get_file_as_string(p).sha256_text() + ";"
    return payload.sha256_text()

func save() -> void:
    var f := FileAccess.open(META_PATH, FileAccess.WRITE)
    if f == null:
        push_error("[CityMeta] Cannot write " + META_PATH)
        return
    f.store_string(JSON.stringify({
        "map_seed": map_seed,
        "manifest_hash": manifest_hash,
        "builders_hash": builders_hash,
        "layout_version": layout_version,
        "built_at": built_at,
    }, "  "))

static func load_existing() -> CityMeta:
    if not FileAccess.file_exists(META_PATH):
        return null
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
    if data == null or not (data is Dictionary):
        push_error("[CityMeta] corrupt meta file — treating as stale")
        return null
    var m := CityMeta.new()
    m.map_seed = int(data.get("map_seed", 0))
    m.manifest_hash = String(data.get("manifest_hash", ""))
    m.builders_hash = String(data.get("builders_hash", ""))
    m.layout_version = int(data.get("layout_version", 0))
    m.built_at = String(data.get("built_at", ""))
    return m

func is_valid_for(manifest: Dictionary) -> bool:
    return invalid_reasons(manifest).is_empty()

func invalid_reasons(manifest: Dictionary) -> Array[String]:
    var reasons: Array[String] = []
    if layout_version != LAYOUT_VERSION:
        reasons.append("layout_version %d != %d" % [layout_version, LAYOUT_VERSION])
    if manifest_hash != _hash_manifest(manifest):
        reasons.append("manifest_hash changed")
    if builders_hash != _hash_builders():
        reasons.append("builders_hash changed")
    return reasons
