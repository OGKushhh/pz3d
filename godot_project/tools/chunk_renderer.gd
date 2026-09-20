# ChunkRenderer — consumes a plan Dictionary and creates actual scene nodes.
#
# Phase F.0 Refactor 3: Separates rendering from planning.
# ChunkPlanner decides WHAT goes WHERE. ChunkRenderer creates the nodes.
#
# Usage:
#	var plan = ChunkPlanner.plan_chunk(col, row, config, roads, spatial, ...)
#	var chunk_node = ChunkRenderer.render_plan(plan, parent, streamer)
#
# The "streamer" is an object that implements:
#	_get_asset(name) -> PackedScene
#	_attach_building_collision(inst)
#	_create_plane_mesh_rotated(parent, name, pos, size, color, yaw)
#	_get_road_edge_near(pos) -> Vector3
#	_path_query (PathQuery instance)
#	spatial (SpatialIndex instance)
#	roads (RoadNetwork instance)
#	_asset_positions (Dictionary)
#	_get_district_type_count(biome, name) -> int
#	_increment_district_type_count(biome, name)
#	_register_asset_position(name, pos)
#
# In practice, map_baker.gd IS the streamer (it implements all these methods).

class_name ChunkRenderer
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")
const CityGenConfig = preload("res://tools/city_gen_config.gd")
const BlockLayout = preload("res://tools/block_layout.gd")

# Render a plan into actual scene nodes.
# Args:
#	plan: Dictionary from ChunkPlanner.plan_chunk()
#	parent: Node3D to add children to (chunk_root)
#	streamer: object with _get_asset, _attach_building_collision, etc.
#	crng: RandomNumberGenerator for this chunk
#	stamper: DistrictStamper instance
#	lot_stamper: LotStamper instance
# Returns: Node3D (the chunk_root with all children added)
static func render_plan(
		plan: Dictionary,
		parent: Node3D,
		streamer,
		crng: RandomNumberGenerator,
		stamper,
		lot_stamper
) -> Node3D:
		var biome: int = plan.get("biome", 0)
		var origin: Vector3 = plan.get("origin", Vector3.ZERO)

		# === Biome ground plane ===
		var biome_color: Color = CityConfig.ground_color_for(biome)
		_create_plane_in_parent(parent, "BiomeGround",
				origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5),
				CityConfig.CHUNK_SIZE_M, CityConfig.CHUNK_SIZE_M, biome_color, 0.001, streamer)

		# === POIs ===
		for poi in plan.get("pois", []):
				var poi_asset: String = poi.get("asset_name", "")
				var poi_pos: Vector3 = poi.get("pos", Vector3.ZERO)
				var poi_radius: float = float(poi.get("radius", 30))
				var poi_scene: PackedScene = streamer._get_asset(poi_asset)
				if poi_scene:
						var poi_inst: Node3D = poi_scene.instantiate()
						poi_inst.position = poi_pos
						poi_inst.name = "POI_" + poi_asset
						parent.add_child(poi_inst)
						poi_inst.owner = parent
						streamer.spatial.insert(poi_pos, poi_radius)

		# === District template ===
		var template_anchor: Vector3 = plan.get("template_anchor", Vector3.ZERO)
		var template_rot: float = plan.get("template_rot", 0.0)
		if stamper:
				var template_name: String = stamper.pick_template_for_biome(biome, crng)
				if template_name != "":
						stamper.stamp_template(template_name, template_anchor, template_rot, parent, crng, streamer)
						streamer.spatial.insert(template_anchor, 75.0)

		# === Interior paths ===
		for path in plan.get("paths", []):
				var center: Vector3 = path.get("center", Vector3.ZERO)
				var width: float = float(path.get("width", 3.0))
				var length: float = float(path.get("length", 1.0))
				var yaw: float = float(path.get("yaw", 0.0))
				streamer._create_plane_mesh_rotated(parent, "Path", center, Vector2(width, length), Color(0.25, 0.25, 0.27, 1), yaw)

		# === Buildings ===
		for building in plan.get("buildings", []):
				var pos: Vector3 = building.get("pos", Vector3.ZERO)
				var asset_name: String = building.get("asset_name", "")
				var is_lot: bool = building.get("is_lot", false)
				var parcel_id: String = building.get("parcel_id", "")

				if is_lot:
						# Lot recipe — needs parcel object (reconstruct from plan)
						# The lot_stamper needs a Parcel object with building_pos, front_dir, road_edge_pos, etc.
						# Find the matching lot in the plan
						var lot_data: Dictionary = {}
						for lot in plan.get("lots", []):
								if lot.get("parcel_id", "") == parcel_id:
										lot_data = lot
										break
						if lot_data.is_empty():
								continue
						# Create a minimal parcel-like object for the stamper
						var parcel: BlockLayout.Parcel = _create_parcel_from_plan(lot_data, origin)
						var lot_name: String = lot_stamper.pick_lot_for_biome(biome, crng)
						if lot_name != "":
								var lot_placed: int = lot_stamper.stamp_lot(lot_name, parcel, parent, crng, streamer, biome)
								if lot_placed > 0:
										streamer.spatial.insert(pos, CityGenConfig.LOT_W * 0.4)
				else:
						# Procedural building
						var scene: PackedScene = streamer._get_asset(asset_name)
						if scene == null:
								continue
						var inst: Node3D = scene.instantiate()
						inst.position = pos
						# Face the road (use front_dir from lot data if available)
						var front_dir: Vector3 = Vector3.FORWARD
						for lot in plan.get("lots", []):
								if lot.get("parcel_id", "") == parcel_id:
										front_dir = lot.get("front_dir", Vector3.FORWARD)
										break
						var perp := Vector3(-front_dir.z, 0, front_dir.x)
						var rot_yaw := atan2(perp.x, perp.z)
						inst.rotation.y = rot_yaw + deg_to_rad(crng.randf_range(-3.0, 3.0))
						inst.name = "%s_%d" % [asset_name, crng.randi() % 100000]
						inst.set_meta("building_name", asset_name)
						parent.add_child(inst)
						inst.owner = parent
						streamer._attach_building_collision(inst)

		# === Foliage ===
		for f in plan.get("foliage", []):
				var pos: Vector3 = f.get("pos", Vector3.ZERO)
				var asset_name: String = f.get("asset_name", "")
				var rot_y: float = float(f.get("rot_y", 0.0))
				var scale: float = float(f.get("scale", 1.0))
				var scene: PackedScene = streamer._get_asset(asset_name)
				if scene == null:
						continue
				var inst: Node3D = scene.instantiate()
				inst.position = pos
				inst.rotation.y = rot_y
				inst.scale = Vector3(scale, scale, scale)
				inst.name = "%s_%d" % [asset_name, crng.randi() % 100000]
				inst.set_meta("building_name", asset_name)
				parent.add_child(inst)
				inst.owner = parent

		# === Props ===
		for p in plan.get("props", []):
				var pos: Vector3 = p.get("pos", Vector3.ZERO)
				var asset_name: String = p.get("asset_name", "")
				var rot_y: float = float(p.get("rot_y", 0.0))
				var scene: PackedScene = streamer._get_asset(asset_name)
				if scene == null:
						continue
				var inst: Node3D = scene.instantiate()
				inst.position = pos
				inst.rotation.y = rot_y
				inst.name = "%s_%d" % [asset_name, crng.randi() % 100000]
				parent.add_child(inst)
				inst.owner = parent

		return parent

# Create a minimal parcel-like object from plan data for lot_stamper
# LotStamper needs: building_pos, front_dir, parcel_id, road_edge_pos, road_distance, road_dir
static func _create_parcel_from_plan(lot_data: Dictionary, origin: Vector3):
		var parcel := BlockLayout.Parcel.new(
				Vector2(lot_data["center"].x - 10, lot_data["center"].z - 15),
				Vector2(lot_data["center"].x + 10, lot_data["center"].z + 15),
				"S", origin, CityConfig.CHUNK_SIZE_M
		)
		parcel.front_dir = lot_data.get("front_dir", Vector3.FORWARD)
		parcel.parcel_id = lot_data.get("parcel_id", "")
		parcel.road_edge_pos = lot_data.get("road_edge_pos", Vector3.ZERO)
		parcel.road_distance = float(lot_data.get("road_distance", 0.0))
		return parcel

# Create a plane mesh in a specific parent (for biome ground, paths, etc.)
static func _create_plane_in_parent(parent: Node3D, name_prefix: String, center: Vector3, size_x: float, size_z: float, color: Color, y_offset: float, streamer) -> void:
		# Use streamer's _create_plane_mesh_rotated for consistency
		# But that adds to parent and registers path segments — we don't want that for ground planes
		# So we create a simple MeshInstance3D directly
		var mi := MeshInstance3D.new()
		mi.name = name_prefix + "_" + str(crng_randi())
		var p := PlaneMesh.new()
		p.size = Vector2(size_x, size_z)
		mi.mesh = p
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.85
		mi.material_override = mat
		mi.position = Vector3(center.x, y_offset, center.z)
		parent.add_child(mi)
		mi.owner = parent

# Simple random int for naming (static, no RNG instance needed)
static func crng_randi() -> int:
		return randi() % 100000
