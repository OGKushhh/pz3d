# Run: godot --headless --script res://tests/test_district_templates.gd
# Exit 0 = pass, 1 = fail.
# Tests Phase A.7 district templates + stamper.
extends SceneTree

const DistrictTemplates := preload("res://data/district_templates.gd")
const DistrictStamper := preload("res://tools/district_stamper.gd")
const CityConfig := preload("res://tools/city_config.gd")

var failures: int = 0

func _init():
	# === Template definitions tests ===
	# Test 1: 3 templates defined
	_check(DistrictTemplates.template_count() == 3, "3 templates defined (got %d)" % DistrictTemplates.template_count())

	# Test 2: expected template names exist
	_check(DistrictTemplates.has_template("suburb_block"), "has suburb_block")
	_check(DistrictTemplates.has_template("commercial_strip"), "has commercial_strip")
	_check(DistrictTemplates.has_template("downtown_block"), "has downtown_block")
	_check(not DistrictTemplates.has_template("nonexistent"), "no 'nonexistent' template")

	# Test 3: each template has required fields
	for tname in ["suburb_block", "commercial_strip", "downtown_block"]:
		var t: Dictionary = DistrictTemplates.get_template(tname)
		_check(t.has("name"), "%s has name" % tname)
		_check(t.has("size"), "%s has size" % tname)
		_check(t.has("building_slots"), "%s has building_slots" % tname)
		_check(t.has("foliage_slots"), "%s has foliage_slots" % tname)
		_check(t.has("prop_slots"), "%s has prop_slots" % tname)

	# Test 4: suburb_block has 5 building slots (4 houses + 1 corner store)
	var sb: Dictionary = DistrictTemplates.get_template("suburb_block")
	_check(sb["building_slots"].size() == 5, "suburb_block has 5 building slots (got %d)" % sb["building_slots"].size())

	# Test 5: commercial_strip has 4 building slots (storefronts)
	var cs: Dictionary = DistrictTemplates.get_template("commercial_strip")
	_check(cs["building_slots"].size() == 4, "commercial_strip has 4 building slots (got %d)" % cs["building_slots"].size())

	# Test 6: downtown_block has 3 building slots (2 mid-rise + 1 landmark)
	var db: Dictionary = DistrictTemplates.get_template("downtown_block")
	_check(db["building_slots"].size() == 3, "downtown_block has 3 building slots (got %d)" % db["building_slots"].size())

	# === Biome → template mapping tests ===
	# Test 7: COMMERCIAL biome maps to commercial_strip
	var ct: Array = DistrictTemplates.templates_for_biome(CityConfig.Biome.COMMERCIAL)
	_check(ct.size() == 1, "COMMERCIAL has 1 template (got %d)" % ct.size())
	_check(ct.has("commercial_strip"), "COMMERCIAL has commercial_strip")

	# Test 8: DOWNTOWN biome maps to downtown_block
	var dt: Array = DistrictTemplates.templates_for_biome(CityConfig.Biome.DOWNTOWN)
	_check(dt.size() == 1, "DOWNTOWN has 1 template (got %d)" % dt.size())
	_check(dt.has("downtown_block"), "DOWNTOWN has downtown_block")

	# Test 9: SUBURBIA has no templates (procedural fallback for v1)
	var st: Array = DistrictTemplates.templates_for_biome(CityConfig.Biome.SUBURBIA)
	_check(st.size() == 0, "SUBURBIA has 0 templates (procedural fallback)")

	# Test 10: WETLANDS has no templates
	var wt: Array = DistrictTemplates.templates_for_biome(CityConfig.Biome.WETLANDS)
	_check(wt.size() == 0, "WETLANDS has 0 templates")

	# === Stamper tests ===
	var stamper := DistrictStamper.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# Test 11: pick_template_for_biome returns commercial_strip for COMMERCIAL
	var picked: String = stamper.pick_template_for_biome(CityConfig.Biome.COMMERCIAL, rng)
	_check(picked == "commercial_strip", "pick_template_for_biome(COMMERCIAL) = commercial_strip (got '%s')" % picked)

	# Test 12: pick_template_for_biome returns "" for SUBURBIA (no template)
	var picked_su: String = stamper.pick_template_for_biome(CityConfig.Biome.SUBURBIA, rng)
	_check(picked_su == "", "pick_template_for_biome(SUBURBIA) = '' (procedural fallback)")

	# Test 13: pick_template_for_biome returns downtown_block for DOWNTOWN
	var picked_dt: String = stamper.pick_template_for_biome(CityConfig.Biome.DOWNTOWN, rng)
	_check(picked_dt == "downtown_block", "pick_template_for_biome(DOWNTOWN) = downtown_block (got '%s')" % picked_dt)

	# Test 14: stamp_template with unknown name returns 0 (no crash)
	var fake_root := Node3D.new()
	var count := stamper.stamp_template("nonexistent", Vector3.ZERO, 0.0, fake_root, rng, null)
	_check(count == 0, "stamp_template('nonexistent') returns 0 (no crash)")
	fake_root.queue_free()

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("district_templates: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("district_templates: PASS")
		quit(0)
