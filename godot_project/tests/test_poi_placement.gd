# Run: godot --headless --script res://tests/test_poi_placement.gd
# Exit 0 = pass, 1 = fail.
extends SceneTree

const CityConfig := preload("res://tools/city_config.gd")

var failures: int = 0

func _init():
	# Test 1: pois.json exists and is valid JSON
	var f := FileAccess.open("res://data/pois.json", FileAccess.READ)
	_check(f != null, "pois.json file exists")
	if f == null:
		_print_result()
		return

	var data: Variant = JSON.parse_string(f.get_as_text())
	_check(data is Dictionary, "pois.json is valid JSON dictionary")
	if not (data is Dictionary):
		_print_result()
		return

	var pois: Array = data.get("pois", [])
	_check(pois.size() > 0, "pois.json has at least 1 POI (got %d)" % pois.size())

	# Test 2: each POI has required fields
	for poi in pois:
		var id: String = poi.get("id", "")
		var ptype: String = poi.get("type", "")
		var pos: Array = poi.get("pos", [])
		var radius: float = float(poi.get("radius", 0))
		_check(id.length() > 0, "POI has id: %s" % id)
		_check(ptype.length() > 0, "POI %s has type: %s" % [id, ptype])
		_check(pos.size() == 3, "POI %s has pos[3] (got %d elements)" % [id, pos.size()])
		_check(radius > 0, "POI %s has radius > 0 (got %.0f)" % [id, radius])

	# Test 3: no two POIs overlap (their radii don't intersect)
	for i in range(pois.size()):
		for j in range(i + 1, pois.size()):
			var p1: Array = pois[i].get("pos", [0,0,0])
			var p2: Array = pois[j].get("pos", [0,0,0])
			var r1: float = float(pois[i].get("radius", 0))
			var r2: float = float(pois[j].get("radius", 0))
			var dx: float = float(p1[0]) - float(p2[0])
			var dz: float = float(p1[2]) - float(p2[2])
			var dist: float = sqrt(dx*dx + dz*dz)
			_check(dist > r1 + r2, "POIs %s + %s don't overlap (dist=%.0f, r1+r2=%.0f)" % [pois[i].get("id",""), pois[j].get("id",""), dist, r1+r2])

	# Test 4: each POI's type exists in the manifest
	var mf := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
	if mf:
		var manifest: Dictionary = JSON.parse_string(mf.get_as_text())
		for poi in pois:
			var ptype: String = poi.get("type", "")
			_check(manifest.has(ptype), "POI type '%s' exists in manifest" % ptype)

	# Test 5: POIs are within map bounds (0..4000, 0..3000)
	for poi in pois:
		var pos: Array = poi.get("pos", [0,0,0])
		var px: float = float(pos[0])
		var pz: float = float(pos[2])
		_check(px >= 0 and px <= 4000, "POI %s X in bounds (0..4000), got %.0f" % [poi.get("id",""), px])
		_check(pz >= 0 and pz <= 3000, "POI %s Z in bounds (0..3000), got %.0f" % [poi.get("id",""), pz])

	_print_result()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		push_error("FAIL: " + msg)
		failures += 1
	else:
		print("  ✓ " + msg)

func _print_result() -> void:
	if failures > 0:
		print("poi_placement: FAIL (%d failures)" % failures)
		quit(1)
	else:
		print("poi_placement: PASS")
		quit(0)
