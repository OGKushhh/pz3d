extends SceneTree

const CityGenV2 = preload("res://tools/city_gen_v2.gd")

func _init():
	print("=== Saving City Plan ===")
	var map = CityGenV2.generate_map(1337)
	
	# Save as JSON
	var f = FileAccess.open("res://data/city_plan_v2.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(map, "\t"))
		f.close()
		print("✅ Saved plan: res://data/city_plan_v2.json")
		print("   %d roads, %d blocks, %d buildings, %d foliage, %d props" % [
			map.stats.roads, map.stats.blocks, map.stats.buildings,
			map.stats.foliage, map.stats.props
		])
	else:
		print("❌ Failed to save plan")
	quit()
