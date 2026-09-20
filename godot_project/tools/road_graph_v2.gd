# RoadGraphV2 — builds a graph structure from the flat road array.
#
# The original vision said:
#   "Define major roads (highways, arterials) as a graph — nodes at
#    intersections, edges as segments"
#
# We had a flat array of road segments with no intersection awareness.
# This module converts it to a proper graph and detects intersections.
#
# Graph structure:
#   nodes: Dictionary[Vector2i(x,z) -> {pos: Vector3, edges: Array[int], kind: String}]
#     - kind = "intersection" (3+ edges meet) | "endpoint" (1 edge) | "bend" (2 edges)
#     - Vector2i key used as hashable lookup (rounded to nearest meter)
#   edges: Array of {from: Vector2i, to: Vector2i, road_index: int, length: float, kind: String}
#
# Intersection detection:
#   - When 3+ road segments share an endpoint, it's an intersection
#   - Place traffic lights at major intersections (arterial x arterial)
#   - Place stop signs at minor intersections (local x local)
#   - Place traffic cones at highway off-ramps

class_name RoadGraphV2
extends RefCounted

# Node tolerance: endpoints within this distance are considered the same node
const NODE_TOLERANCE := 2.0  # meters

# Build graph from road array
# Each road: {start: Vector3, end: Vector3, width: float, kind: String, name: String}
#
# IMPORTANT: Roads in CityGenV2 are full-length lines that cross each other
# mid-segment (no shared endpoints). To detect intersections, we also need to
# find segment-segment crossings and split edges at those points.
static func build(roads: Array) -> Dictionary:
	var nodes: Dictionary = {}  # Vector2i(x,z) -> {pos: Vector3, edges: Array, kinds: Array}
	var edges: Array = []      # [{from, to, road_index, length, kind}]

	# First pass: add endpoints as nodes
	for i in range(roads.size()):
		var road: Dictionary = roads[i]
		var start: Vector3 = road.start
		var end: Vector3 = road.end
		var kind: String = road.get("kind", "local")

		var key_start := _key(start)
		var key_end := _key(end)

		if not nodes.has(key_start):
			nodes[key_start] = {"pos": start, "edges": [], "kinds": []}
		if not nodes.has(key_end):
			nodes[key_end] = {"pos": end, "edges": [], "kinds": []}

	# Second pass: find all segment-segment intersections (where roads cross)
	# Add those points as nodes too.
	for i in range(roads.size()):
		for j in range(i + 1, roads.size()):
			var r1: Dictionary = roads[i]
			var r2: Dictionary = roads[j]
			var cross_point = _segment_crossing(r1, r2)
			if cross_point != null:
				var key := _key(cross_point)
				if not nodes.has(key):
					nodes[key] = {"pos": cross_point, "edges": [], "kinds": [], "is_crossing": true}
				# Mark this intersection as involving both road kinds
				var kinds_at_node: Array = nodes[key].kinds
				if not kinds_at_node.has(r1.kind):
					kinds_at_node.append(r1.kind)
				if not kinds_at_node.has(r2.kind):
					kinds_at_node.append(r2.kind)

	# Third pass: create edges (one per road segment, connecting its endpoints)
	# Note: We don't split edges at intermediate crossings — the graph treats
	# each road as a single edge. Crossings are tracked separately as nodes.
	for i in range(roads.size()):
		var road: Dictionary = roads[i]
		var start: Vector3 = road.start
		var end: Vector3 = road.end
		var kind: String = road.get("kind", "local")

		var key_start := _key(start)
		var key_end := _key(end)

		var edge := {
			"from": key_start,
			"to": key_end,
			"road_index": i,
			"length": start.distance_to(end),
			"kind": kind,
		}
		edges.append(edge)

		var edge_idx: int = edges.size() - 1
		nodes[key_start].edges.append(edge_idx)
		nodes[key_end].edges.append(edge_idx)
		# Don't add kinds again here (already added in first/second pass)

	# Classify nodes:
	# - "intersection" if 3+ edges OR is_crossing flag set
	# - "endpoint" if 1 edge
	# - "bend" if 2 edges
	var intersections: Array = []
	var endpoints: Array = []
	var bends: Array = []
	for key in nodes:
		var n: Dictionary = nodes[key]
		var edge_count: int = n.edges.size()
		var is_crossing: bool = n.get("is_crossing", false)
		# A node is an intersection if: 3+ edges OR it's a known crossing point
		if edge_count >= 3 or is_crossing:
			n.kind = "intersection"
			intersections.append(key)
		elif edge_count == 1:
			n.kind = "endpoint"
			endpoints.append(key)
		else:
			n.kind = "bend"
			bends.append(key)

	# Classify intersections: major (highway/arterial involved) or minor (locals only)
	var major_intersections: Array = []
	var minor_intersections: Array = []
	for key in intersections:
		var n: Dictionary = nodes[key]
		var kinds: Array = n.kinds
		var has_highway: bool = kinds.has("highway")
		var has_arterial: bool = kinds.has("arterial")
		var has_local: bool = kinds.has("local")
		if has_highway or has_arterial:
			n.intersection_class = "major"
			major_intersections.append(key)
		elif has_local:
			n.intersection_class = "minor"
			minor_intersections.append(key)
		else:
			n.intersection_class = "unknown"

	return {
		"nodes": nodes,
		"edges": edges,
		"intersections": intersections,
		"major_intersections": major_intersections,
		"minor_intersections": minor_intersections,
		"endpoints": endpoints,
		"bends": bends,
		"stats": {
			"nodes": nodes.size(),
			"edges": edges.size(),
			"intersections": intersections.size(),
			"major_intersections": major_intersections.size(),
			"minor_intersections": minor_intersections.size(),
			"endpoints": endpoints.size(),
			"bends": bends.size(),
		},
	}

# Find where two road segments cross (mid-segment intersection)
# Roads are aligned to grid (vertical = constant x, horizontal = constant z)
# So we can detect crossings by: vertical road x in [horizontal z range] AND
# horizontal road z in [vertical z range].
# Returns Vector3 if crossing found, or null if no crossing.
static func _segment_crossing(r1: Dictionary, r2: Dictionary):
	var s1: Vector3 = r1.start
	var e1: Vector3 = r1.end
	var s2: Vector3 = r2.start
	var e2: Vector3 = r2.end

	# Check if r1 is vertical (constant x) and r2 is horizontal (constant z)
	var r1_vertical: bool = abs(s1.x - e1.x) < 1.0
	var r2_horizontal: bool = abs(s2.z - e2.z) < 1.0
	if r1_vertical and r2_horizontal:
		var x: float = s1.x  # vertical road's x
		var z: float = s2.z  # horizontal road's z
		# Check if x is within r2's x range and z is within r1's z range
		var r2_x_min: float = min(s2.x, e2.x)
		var r2_x_max: float = max(s2.x, e2.x)
		var r1_z_min: float = min(s1.z, e1.z)
		var r1_z_max: float = max(s1.z, e1.z)
		if x >= r2_x_min - 1.0 and x <= r2_x_max + 1.0 and z >= r1_z_min - 1.0 and z <= r1_z_max + 1.0:
			return Vector3(x, 0, z)

	# Try the other way: r1 horizontal, r2 vertical
	var r1_horizontal: bool = abs(s1.z - e1.z) < 1.0
	var r2_vertical: bool = abs(s2.x - e2.x) < 1.0
	if r1_horizontal and r2_vertical:
		var x: float = s2.x
		var z: float = s1.z
		var r1_x_min: float = min(s1.x, e1.x)
		var r1_x_max: float = max(s1.x, e1.x)
		var r2_z_min: float = min(s2.z, e2.z)
		var r2_z_max: float = max(s2.z, e2.z)
		if x >= r1_x_min - 1.0 and x <= r1_x_max + 1.0 and z >= r2_z_min - 1.0 and z <= r2_z_max + 1.0:
			return Vector3(x, 0, z)

	# Parallel or non-grid-aligned: no crossing
	return null

# Place intersection props (traffic lights at major, stop signs at minor)
# Returns array of {pos, rot_y, asset_name} for placement
static func place_intersection_props(graph: Dictionary) -> Array:
	var placements: Array = []
	var nodes: Dictionary = graph.nodes

	# Major intersections: traffic lights
	for key in graph.major_intersections:
		var n: Dictionary = nodes[key]
		var pos: Vector3 = n.pos
		# Place traffic light at intersection center
		placements.append({"pos": pos, "rot_y": 0.0, "asset_name": "traffic_light"})
		# Place 4 bollards around intersection (corner markers)
		for i in range(4):
			var angle: float = i * TAU / 4.0
			var offset: float = 8.0  # 8m from center
			var px: float = pos.x + cos(angle) * offset
			var pz: float = pos.z + sin(angle) * offset
			placements.append({"pos": Vector3(px, 0, pz), "rot_y": rad_to_deg(angle), "asset_name": "bollard"})

	# Minor intersections: stop signs (we don't have a stop_sign asset, use traffic cone)
	for key in graph.minor_intersections:
		var n: Dictionary = nodes[key]
		var pos: Vector3 = n.pos
		# Place 2 traffic cones (one on each approaching lane)
		placements.append({"pos": Vector3(pos.x + 4, 0, pos.z), "rot_y": 0.0, "asset_name": "traffic_cone"})
		placements.append({"pos": Vector3(pos.x - 4, 0, pos.z), "rot_y": 180.0, "asset_name": "traffic_cone"})

	return placements

# Quantize a Vector3 position to a Vector2i key (rounded to nearest NODE_TOLERANCE)
static func _key(v: Vector3) -> Vector2i:
	var x: int = int(round(v.x / NODE_TOLERANCE))
	var z: int = int(round(v.z / NODE_TOLERANCE))
	return Vector2i(x, z)

# Pretty-print graph stats
static func print_stats(graph: Dictionary) -> void:
	var s: Dictionary = graph.stats
	print("[RoadGraphV2] Stats:")
	print("  Nodes: %d (%d intersections, %d endpoints, %d bends)" % [
		s.nodes, s.intersections, s.endpoints, s.bends
	])
	print("  Edges: %d" % s.edges)
	print("  Intersections: %d total (%d major, %d minor)" % [
		s.intersections, s.major_intersections, s.minor_intersections
	])
