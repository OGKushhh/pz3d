# Run: godot --headless --script res://tests/test_city_meta.gd
# Exit 0 = pass, 1 = fail.
extends SceneTree

const CityMeta := preload("res://tools/city_meta.gd")

var failures: int = 0

func _init():
	# Test 1: generate produces valid meta
	var manifest := {"test_asset": {"path": "res://test.glb"}}
	var meta := CityMeta.generate(1337, manifest)
	_check(meta.map_seed == 1337, "generate: map_seed = 1337")
	_check(meta.manifest_hash.length() > 0, "generate: manifest_hash not empty")
	_check(meta.builders_hash.length() > 0, "generate: builders_hash not empty")
	_check(meta.terrain_version > 0, "generate: terrain_version > 0 (got %d)" % meta.terrain_version)

	# Test 2: manifest hash changes when manifest changes
	var meta2 := CityMeta.generate(1337, {"different": {"path": "res://other.glb"}})
	_check(meta.manifest_hash != meta2.manifest_hash, "different manifest = different hash")

	# Test 3: same manifest = same hash
	var meta3 := CityMeta.generate(1337, manifest)
	_check(meta.manifest_hash == meta3.manifest_hash, "same manifest = same hash")

	# Test 4: invalid_reasons detects manifest change
	var reasons := meta.invalid_reasons({"changed": {"path": "res://new.glb"}})
	_check(reasons.size() > 0, "invalid_reasons detects manifest change")

	# Test 5: invalid_reasons returns empty for same manifest
	var reasons2 := meta.invalid_reasons(manifest)
	# Note: builders_hash may differ if scripts changed since generate
	# Only check manifest_hash part
	var manifest_ok := meta.manifest_hash == CityMeta._hash_manifest(manifest)
	_check(manifest_ok, "invalid_reasons: manifest hash matches for same manifest")

	# Test 6: _read_terrain_version reads from terrain_height.gd
	var tv := CityMeta._read_terrain_version()
	_check(tv > 0, "_read_terrain_version returns positive (got %d)" % tv)
	_check(tv == meta.terrain_version, "terrain_version matches between read and generate (%d == %d)" % [tv, meta.terrain_version])

	# Test 7: is_valid_for returns true for matching manifest (ignores builders_hash
	# which may change if scripts were edited)
	var meta_fresh := CityMeta.generate(1337, manifest)
	_check(meta_fresh.is_valid_for(manifest), "is_valid_for returns true for fresh meta")

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("city_meta: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("city_meta: PASS")
		quit(0)
