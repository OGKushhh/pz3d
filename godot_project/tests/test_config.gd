# Run: godot --headless --script res://tests/test_config.gd
# Exit 0 = pass, 1 = fail.
# Tests city_config.gd: biome enum, grid layout, biome profiles, constants.
extends SceneTree

const CityConfig := preload("res://tools/city_config.gd")

var failures: int = 0

func _init():
        # Test 1: Biome enum has expected values (no SUBWAY, no RIVER, has COASTAL_BEACH, has WETLANDS)
        _check(CityConfig.Biome.SUBURBIA == 0, "Biome.SUBURBIA == 0")
        _check(CityConfig.Biome.COASTAL_BEACH == 9, "Biome.COASTAL_BEACH == 9")
        _check(CityConfig.Biome.WATER == 10, "Biome.WATER == 10")
        _check(CityConfig.Biome.WETLANDS == 6, "Biome.WETLANDS == 6 (got %d)" % CityConfig.Biome.WETLANDS)

        # Test 2: SUBWAY is NOT in the enum (removed in Phase A.3)
        _check(not CityConfig.Biome.has("SUBWAY"), "Biome.SUBWAY does not exist (removed Phase A.3)")

        # Test 2b: RIVER is NOT in the enum (removed in Phase A.4)
        _check(not CityConfig.Biome.has("RIVER"), "Biome.RIVER does not exist (removed Phase A.4 — river is now a polyline overlay)")

        # Test 3: grid_layout is 6 rows × 8 cols
        var grid := CityConfig.grid_layout()
        _check(grid.size() == 6, "grid_layout has 6 rows (got %d)" % grid.size())
        for row in grid:
                _check(row.size() == 8, "grid row has 8 cols (got %d)" % row.size())

        # Test 4 (Phase A.4): NO RIVER cells in the grid (RIVER removed)
        # The old test asserted 6 RIVER cells; now we assert 0.
        var ri_count := 0
        for row in grid:
                for cell in row:
                        # RIVER is no longer in the enum, so any old "6" value
                        # would resolve to whatever replaced it (WETLANDS).
                        # Just check no cell == 6 with name "RIVER" — since enum
                        # value 6 is now WETLANDS, this test is mostly defensive.
                        if CityConfig.Biome.find_key(cell) == "RIVER":
                                ri_count += 1
        _check(ri_count == 0, "no RIVER cells in grid (RIVER removed Phase A.4), got %d" % ri_count)

        # Test 4b: Column 4 (was RIVER) is now redistributed to row-dominant biomes
        # row 0 col 4 = FOREST (2), row 4 col 4 = COMMERCIAL (4)
        # Phase A.5: row 5 cols 3-4 = WETLANDS (12) — river mouth placement
        _check(grid[0][4] == CityConfig.Biome.FOREST, "grid[0][4] == FOREST (got %d)" % grid[0][4])
        _check(grid[4][4] == CityConfig.Biome.COMMERCIAL, "grid[4][4] == COMMERCIAL (got %d)" % grid[4][4])
        _check(grid[5][3] == CityConfig.Biome.WETLANDS, "grid[5][3] == WETLANDS (river mouth, got %d)" % grid[5][3])
        _check(grid[5][4] == CityConfig.Biome.WETLANDS, "grid[5][4] == WETLANDS (river mouth, got %d)" % grid[5][4])

        # Test 4c (Phase A.5): WETLANDS appears exactly 2 times (river mouth only)
        var we_count := 0
        for row in grid:
                for cell in row:
                        if cell == CityConfig.Biome.WETLANDS:
                                we_count += 1
        _check(we_count == 2, "WETLANDS = 2 cells (river mouth only), got %d" % we_count)

        # Test 5: Coastal Beach exists in grid (column 5, all 6 rows)
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

        # Test 6b (Phase A.4): WETLANDS biome profile exists and has expected content
        _check(biomes.has(CityConfig.Biome.WETLANDS), "WETLANDS profile exists in biomes() dict")
        if biomes.has(CityConfig.Biome.WETLANDS):
                var wl: Dictionary = biomes[CityConfig.Biome.WETLANDS]
                _check(wl.get("name", "") == "Wetlands & Marshes", "WETLANDS name = 'Wetlands & Marshes' (got '%s')" % wl.get("name", ""))
                var wl_foliage: Array = wl.get("foliage", [])
                _check(wl_foliage.has("cattail"), "WETLANDS foliage includes cattail")
                _check(wl_foliage.has("marsh_grass"), "WETLANDS foliage includes marsh_grass")

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

        # Test 8b (Phase A.4): bridges at rows 3 and 4 (was 4 and 5)
        # The grid_layout comment says bridges cross at z=1750 (row 3) and z=2250 (row 4).
        var bridge_rows: Array = []
        for b in CityConfig.bridges():
                bridge_rows.append(b.get("row", -1))
        _check(bridge_rows.has(3), "bridge at row 3 (Sarran Bridge) — got rows %s" % str(bridge_rows))
        _check(bridge_rows.has(4), "bridge at row 4 (Old Town Bridge) — got rows %s" % str(bridge_rows))

        # Test 9: manifest exists and has entries
        var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
        _check(f != null, "city_manifest.json exists")
        if f:
                var manifest: Dictionary = JSON.parse_string(f.get_as_text())
                _check(manifest.size() > 50, "manifest has > 50 entries (got %d)" % manifest.size())

        # Test 10 (Phase A.4): map_data.json has river.control_points array (not center_x)
        var mf := FileAccess.open("res://data/map_data.json", FileAccess.READ)
        _check(mf != null, "map_data.json exists")
        if mf:
                var md: Dictionary = JSON.parse_string(mf.get_as_text())
                var river: Dictionary = md.get("river", {})
                _check(river.has("control_points"), "river has control_points array (Phase A.4)")
                _check(not river.has("center_x"), "river does NOT have center_x (removed Phase A.4)")
                var cps: Array = river.get("control_points", [])
                _check(cps.size() >= 2, "control_points has ≥2 entries (got %d)" % cps.size())

        # Test 11 (Phase A.5): district_names() returns placeholder names per biome
        var dnames: Dictionary = CityConfig.district_names()
        _check(dnames.has(CityConfig.Biome.SUBURBIA), "district_names has SUBURBIA entry")
        _check(dnames.has(CityConfig.Biome.WETLANDS), "district_names has WETLANDS entry")
        _check(dnames.has(CityConfig.Biome.DOWNTOWN), "district_names has DOWNTOWN entry")
        # Spot-check a few specific placeholder names (per docs/shells_needed-style lore sourcing)
        _check(dnames[CityConfig.Biome.SUBURBIA] == "Long Peace Heights", "SUBURBIA district = 'Long Peace Heights' (got '%s')" % dnames.get(CityConfig.Biome.SUBURBIA))
        _check(dnames[CityConfig.Biome.WETLANDS] == "Sarran Marshes", "WETLANDS district = 'Sarran Marshes' (got '%s')" % dnames.get(CityConfig.Biome.WETLANDS))
        _check(dnames[CityConfig.Biome.DOWNTOWN] == "Junta Quarter", "DOWNTOWN district = 'Junta Quarter' (got '%s')" % dnames.get(CityConfig.Biome.DOWNTOWN))

        # Test 12 (Phase A.5): district_name_for(biome) returns same as direct lookup
        _check(CityConfig.district_name_for(CityConfig.Biome.WETLANDS) == "Sarran Marshes", "district_name_for(WETLANDS) = 'Sarran Marshes'")
        _check(CityConfig.district_name_for(999) == "Unknown District", "district_name_for(999) returns 'Unknown District' (defensive fallback)")

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
