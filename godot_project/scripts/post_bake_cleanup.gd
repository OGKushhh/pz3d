# PostBakeCleanup — reads baked_city.tscn, finds overlapping buildings,
# removes the smaller one of each pair, saves cleaned .tscn.
#
# Run: godot --headless --path godot_project --script res://scripts/post_bake_cleanup.gd

extends SceneTree

const CityConfig = preload("res://tools/city_config.gd")
const INPUT_PATH := "res://scenes/baked_city.tscn"
const OUTPUT_PATH := "res://scenes/baked_city_clean.tscn"

func _init():
	print("=== PostBakeCleanup ===")
	var scene := load(INPUT_PATH)
	if scene == null:
		print("FAIL: couldn't load ", INPUT_PATH)
		quit(1)
	var root: Node3D = scene.instantiate()
	root.add_child.call_deferred(root)  # no-op, just to silence warnings
	
	# Collect all building nodes with their world-space AABBs
	var buildings: Array = []  # {node, aabb, name, chunk_key}
	var stack := [root]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		if node is Node3D:
			var n3d: Node3D = node
			var bname: String = n3d.get_meta("building_name", "")
			if bname != "":
				var aabb := _compute_world_aabb(n3d)
				if aabb.size != Vector3.ZERO:
					var col: int = int(n3d.position.x / CityConfig.CHUNK_SIZE_M)
					var row: int = int(n3d.position.z / CityConfig.CHUNK_SIZE_M)
					buildings.append({
						"node": n3d,
						"aabb": aabb,
						"name": bname,
						"chunk": Vector2i(col, row),
						"volume": aabb.size.x * aabb.size.y * aabb.size.z,
					})
		for c in node.get_children():
			stack.append(c)
	
	print("  Found %d buildings" % buildings.size())
	
	# Find overlapping pairs and mark smaller ones for removal
	var to_remove: Dictionary = {}  # node → true
	var overlap_count: int = 0
	for i in range(buildings.size()):
		for j in range(i + 1, buildings.size()):
			var a = buildings[i]
			var b = buildings[j]
			# Skip if same chunk is too far apart (quick reject)
			if a["chunk"].x != b["chunk"].x or a["chunk"].y != b["chunk"].y:
				# Check adjacent chunks too
				var dx: int = abs(a["chunk"].x - b["chunk"].x)
				var dz: int = abs(a["chunk"].y - b["chunk"].y)
				if dx > 1 or dz > 1:
					continue
			# AABB overlap check (XZ only)
			var aa: AABB = a["aabb"]
			var ba: AABB = b["aabb"]
			if aa.position.x < ba.position.x + ba.size.x and \
			   aa.position.x + aa.size.x > ba.position.x and \
			   aa.position.z < ba.position.z + ba.size.z and \
			   aa.position.z + aa.size.z > ba.position.z:
				overlap_count += 1
				# Mark the smaller one for removal
				var smaller = a if a["volume"] < b["volume"] else b
				to_remove[smaller["node"]] = true
	
	print("  Found %d overlapping pairs" % overlap_count)
	print("  Removing %d buildings (smaller of each pair)" % to_remove.size())
	
	# Remove marked buildings
	var removed: int = 0
	for key in to_remove:
		var node: Node = key
		var parent: Node = node.get_parent()
		if parent:
			parent.remove_child(node)
			node.free()
			removed += 1
	
	print("  Removed: %d" % removed)
	
	# Set owner recursively (in case removal changed ownership)
	_set_owner_recursive(root, root)
	
	# Save cleaned scene
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, OUTPUT_PATH)
	if err == OK:
		print("✅ Saved: ", OUTPUT_PATH)
		print("   Remaining buildings: %d" % (buildings.size() - removed))
	else:
		print("❌ Save failed: ", err)
	quit()

func _compute_world_aabb(node: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = child
		var mesh_aabb := mi.get_aabb()
		if mesh_aabb.size == Vector3.ZERO:
			continue
		mesh_aabb.position += mi.position
		if first:
			aabb = mesh_aabb
			first = false
		else:
			aabb = aabb.merge(mesh_aabb)
	# Transform to world space
	aabb.position += node.position
	return aabb

func _set_owner_recursive(root: Node, owner_node: Node):
	for child in root.get_children():
		if child.owner != owner_node:
			child.owner = owner_node
		_set_owner_recursive(child, owner_node)
