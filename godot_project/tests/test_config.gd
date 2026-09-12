# Run: godot --headless --script res://tests/test_config.gd
# Exit 0 = pass, 1 = fail.
# Tests city_config.gd: biome enum, grid layout, biome profiles, constants.
extends SceneTree

const CityConfig := preload("res://tools/city_config.gd")

var failures: int = 0

func _init():
	# Test 1: Biome enum has expected values (no SUBWAY, has COASTAL_BEACH)
	_check(CityConfig.Biome.SUBURBIA == 0, "Biome.SUBURBIA == 0")
	_check(CityConfig.Biome.COASTAL_BEACH == 9, "Biome.COASTAL_BEACH == 9")
	_check(CityConfig.Biome.WATER == 10, "Biome.WATER == 10")

	# Test 2: SUBWAY is NOT in the enum (removed in Phase A.3)
	_check(not CityConfig.Biome.has("SUBWAY"), "Biome.SUBWAY does not exist (removed Phase A.3)")

	# Test 3: grid_layout is 6 rows × 8 cols
	var grid := CityConfig.grid_layout()
	_check(grid.size() == 6, "grid_layout has 6 rows (got %d)" % grid.size())
	for row in grid:
		_check(row.size() == 8, "grid row has 8 cols (got %d)" % row.size())

	# Test 4: River is 1 column (not 2 — reduced in Phase A.2)
	var ri_count := 0
	for row in grid:
		for cell in row:
			if cell == CityConfig.Biome.RIVER:
				ri_count += 1
	_check(ri_count == 6, "River = 6 cells (1 column × 6 rows), got %d" % ri_count)

	# Test 5: Coastal Beach exists in grid
	var cb_count := 0
	for row in grid:
		for cell in row:
			if cell == CityConfig.Biome.COASTAL_BEACH:
				cb_count += 1
	_check(cb_count == 6, "Coastal Beach = 6 cells, got %d" % cb_count)

	# Test 6: each biome profile has required fields
	var biomes := CityConfig.biomes()
	for biome_key in biomes:
		var profile: Dictionary = biomes[biome_key]
		_check(profile.has("name"), "biome %d has name" % biome_key)
		_check(profile.has("fill"), "biome %d has fill" % biome_key)
		_check(profile.has("buildings"), "biome %d has buildings" % biome_key)
		_check(profile.has("props"), "biome %d has props" % biome_key)
		_check(profile.has("foliage"), "biome %d has foliage" % biome_key)
		_check(profile.has("lights"), "biome %d has lights" % biome_key)

	# Test 7: v3 constants exist and have correct values
	_check(CityConfig.LOT_WIDTH == 20.0, "LOT_WIDTH = 20.0 (got %.0f)" % CityConfig.LOT_WIDTH)
	_check(CityConfig.LOT_DEPTH == 16.0, "LOT_DEPTH = 16.0 (got %.0f)" % CityConfig.LOT_DEPTH)
	_check(CityConfig.GRASS_STRIP_WIDTH == 2.5, "GRASS_STRIP_WIDTH = 2.5 (got %.1f)" % CityConfig.GRASS_STRIP_WIDTH)
	_check(CityConfig.SIDEWALK_WIDTH == 1.5, "SIDEWALK_WIDTH = 1.5 (got %.1f)" % CityConfig.SIDEWALK_WIDTH)
	_check(CityConfig.BUILDING_SETBACK == 1.5, "BUILDING_SETBACK = 1.5 (got %.1f)" % CityConfig.BUILDING_SETBACK)
	_check(CityConfig.STREETLIGHT_SPACING == 25.0, "STREETLIGHT_SPACING = 25.0 (got %.0f)" % CityConfig.STREETLIGHT_SPACING)

	# Test 8: bridges use valid rows (0..5 for GRID_ROWS=6)
	for b in CityConfig.bridges():
		var row: int = b.get("row", -1)
		_check(row >= 0 and row < 6, "bridge row %d in valid range (0..5)" % row)
		var from_col: int = b.get("from_col", -1)
		var to_col: int = b.get("to_col", -1)
		_check(from_col < to_col, "bridge from_col < to_col (%d < %d)" % [from_col, to_col])

	# Test 9: manifest exists and has entries
	var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
	_check(f != null, "city_manifest.json exists")
	if f:
		var manifest: Dictionary = JSON.parse_string(f.get_as_text())
		_check(manifest.size() > 50, "manifest has > 50 entries (got %d)" % manifest.size())

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("config: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("config: PASS")
		quit(0)
