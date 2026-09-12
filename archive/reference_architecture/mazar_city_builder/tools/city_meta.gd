# Mazar City Meta — deterministic seed + stale-build detection.
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
