# Run: godot --headless --script res://tests/test_terrain_height.gd
# Exit 0 = pass, 1 = fail.
extends SceneTree

const TerrainHeight := preload("res://tools/terrain_height.gd")
const RiverNetwork := preload("res://tools/river_network.gd")

var failures: int = 0

func _init():
	var river := RiverNetwork.new()
	var terrain := TerrainHeight.new(1337, river)

	# Test 1: Determinism — same seed, same position = same height
	var h1 := terrain.height_at(1000.0, 500.0)
	var h2 := terrain.height_at(1000.0, 500.0)
	_check(h1 == h2, "determinism: same pos returns same height (%.4f == %.4f)" % [h1, h2])

	# Test 2: Different seed = different height
	var terrain2 := TerrainHeight.new(9999, river)
	var h3 := terrain2.height_at(1000.0, 500.0)
	_check(h1 != h3, "different seed = different height (%.4f != %.4f)" % [h1, h3])

	# Test 3: River center is below water level
	var river_h := terrain.height_at(2250.0, 1000.0)
	_check(river_h < 0.0, "river center below water level (got %.2f, expected < 0.0)" % river_h)

	# Test 4: Land away from river is above water level
	var land_h := terrain.height_at(500.0, 500.0)
	_check(land_h > -1.0, "land above water level (got %.2f, expected > -1.0)" % land_h)

	# Test 5: water_depth_at returns 0 on land
	var depth_land := terrain.water_depth_at(500.0, 500.0)
	_check(depth_land == 0.0, "water_depth_at on land = 0 (got %.2f)" % depth_land)

	# Test 6: water_depth_at returns > 0 at river center
	var depth_river := terrain.water_depth_at(2250.0, 1000.0)
	_check(depth_river > 0.0, "water_depth_at at river > 0 (got %.2f)" % depth_river)

	# Test 7: is_underwater at river center
	_check(terrain.is_underwater(2250.0, 1000.0), "is_underwater at river center = true")

	# Test 8: is_underwater on land
	_check(not terrain.is_underwater(500.0, 500.0), "is_underwater on land = false")

	# Test 9: TERRAIN_HEIGHT_VERSION is positive integer
	_check(TerrainHeight.TERRAIN_HEIGHT_VERSION > 0, "TERRAIN_HEIGHT_VERSION > 0 (got %d)" % TerrainHeight.TERRAIN_HEIGHT_VERSION)

	# Test 10: Forest biome has higher elevation than Farmland (base 2.0 vs 0.2)
	# Forest is at grid cells where biome=FOREST (col 0-1, row 0-1)
	var forest_h := terrain.height_at(100.0, 100.0)
	var farm_h := terrain.height_at(1100.0, 100.0)
	_check(forest_h > farm_h, "forest elevation > farmland (%.2f > %.2f)" % [forest_h, farm_h])

	# Test 11: Road flattening — height near road grid line is closer to 0
	var near_road_h := terrain.height_at(502.0, 500.0)  # 2m from road at X=500
	var far_from_road_h := terrain.height_at(250.0, 250.0)  # 250m from nearest road
	# Near road should be flatter (closer to 0) than far from road
	_check(abs(near_road_h) < abs(far_from_road_h) + 5.0, "road flatten: near road flatter (%.2f vs %.2f)" % [near_road_h, far_from_road_h])

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("terrain_height: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("terrain_height: PASS")
		quit(0)
