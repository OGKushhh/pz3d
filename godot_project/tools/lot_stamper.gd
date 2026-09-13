# LotStamper — runtime stamper for hand-authored Lot recipes.
#
# Phase B.6.2 (2026-09-14): Stamps a Lot recipe (defined in tools/lot.gd) at a
# parcel position. Mirrors the DistrictStamper pattern (see tools/district_stamper.gd):
#   - Walks primary + companions + sidewalk + driveway
#   - Picks one variant per slot via crng for determinism
#   - Applies lot_yaw so lot-local +Z aligns with parcel.front_dir
#   - Calls streamer._get_asset(name) + streamer._attach_building_collision(inst)
#   - Calls streamer._create_plane_mesh_rotated(...) for sidewalk/driveway strips
#
# Visual contract after stamp (per HANDOFF.md + GDD §4.7.3):
#   - House + garage always sit on the same lot, garage door aligned with house front
#   - Grey sidewalk strip from each house's front door to the nearest road
#   - Darker driveway strip from each garage to the nearest road
#   - No more random garages in fields (gap filler is patched separately in B.6.3)
class_name LotStamper
extends RefCounted

const LotRecipes := preload("res://tools/lot.gd")
const CityConfig := preload("res://tools/city_config.gd")

# Rotation jitter applied to each building (±3 degrees, less than DistrictStamper's
# ±5 because Lots are smaller and tighter — too much jitter breaks the garage-door-
# aligned-with-house-front contract).
const ROT_JITTER_DEG := 3.0

# Probability that the primary building is left empty (vacant lot).
# Lower than DistrictStamper's 0.15 because Lots are the primary unit of place —
# a vacant Lot defeats the purpose. Set to 0.05 for occasional ruined lots.
const VACANT_LOT_PROB := 0.05

# Stamp a lot recipe at a parcel position.
#
# Args:
#   lot_name: name of the lot recipe (must exist in LotRecipes.LOTS)
#   parcel: a BlockLayout.Parcel (has building_pos, front_dir, parcel_id, road_edge)
#   chunk_root: the chunk Node3D to add instantiated nodes to
#   crng: per-chunk RNG for deterministic variation
#   streamer: the chunk_streamer instance (for _get_asset / _attach_building_collision
#             / _create_plane_mesh_rotated access)
#
# Returns the count of buildings placed (primary + companions). Sidewalk and
# driveway planes are not counted (they're visual, not gameplay objects).
func stamp_lot(
                lot_name: String,
                parcel,
                chunk_root: Node3D,
                crng: RandomNumberGenerator,
                streamer
) -> int:
        var lot: Dictionary = LotRecipes.get_lot(lot_name)
        if lot.is_empty():
                push_warning("[LotStamper] lot '%s' not found" % lot_name)
                return 0

        # Compute lot_yaw: align lot-local +Z with parcel.front_dir.
        # lot-local (0, 0, 1) rotated by θ → world (sin(θ), 0, cos(θ))
        # Want this to equal parcel.front_dir → θ = atan2(front_dir.x, front_dir.z)
        var front_dir: Vector3 = parcel.front_dir
        var lot_yaw: float = atan2(front_dir.x, front_dir.z)
        var cos_y: float = cos(lot_yaw)
        var sin_y: float = sin(lot_yaw)

        var anchor: Vector3 = parcel.building_pos
        var placed_count := 0

        # 1. Stamp primary building (with vacant-lot probability)
        var primary: Dictionary = lot.get("primary", {})
        if not primary.is_empty() and crng.randf() >= VACANT_LOT_PROB:
                var inst: Node3D = _stamp_building_slot(
                        primary, anchor, lot_yaw, cos_y, sin_y,
                        chunk_root, crng, streamer, lot_name + "_primary"
                )
                if inst != null:
                        inst.set_meta("lot_id", parcel.parcel_id)
                        inst.set_meta("lot_role", "primary")
                        inst.set_meta("lot_name", lot_name)
                        placed_count += 1

        # 2. Stamp companions (each with its own chance gate)
        for companion in lot.get("companions", []):
                var chance: float = float(companion.get("chance", 1.0))
                if crng.randf() > chance:
                        continue
                var comp_inst: Node3D = _stamp_building_slot(
                        companion, anchor, lot_yaw, cos_y, sin_y,
                        chunk_root, crng, streamer,
                        lot_name + "_" + String(companion.get("role", "companion"))
                )
                if comp_inst != null:
                        comp_inst.set_meta("lot_id", parcel.parcel_id)
                        comp_inst.set_meta("lot_role", String(companion.get("role", "companion")))
                        comp_inst.set_meta("lot_name", lot_name)
                        placed_count += 1

        # 3. Draw sidewalk strip (from ACTUAL road edge to building front door)
        # Phase B.7.4: use parcel.road_edge_pos (queried from road_network) instead of
        # the recipe's hardcoded [0, 0, 6.0] offset. The door is at lot-local [0, 0, 3.5]
        # (porch_slab offset from suburban_house_v2.mog).
        if lot.has("sidewalk") and not primary.is_empty():
                var sidewalk: Dictionary = lot["sidewalk"]
                # Door position in lot-local: 3.5m forward of building origin (porch slab)
                var door_local := Vector3(0, 0, 3.5)
                var door_world := _local_to_world(door_local, anchor, cos_y, sin_y)
                # Road edge: use parcel.road_edge_pos (actual nearest road point)
                var road_edge: Vector3
                if parcel.road_distance > 0.1:
                        road_edge = parcel.road_edge_pos
                else:
                        road_edge = _local_to_world(Vector3(0, 0, 6.0), anchor, cos_y, sin_y)
                _draw_strip_world(sidewalk, road_edge, door_world, chunk_root, streamer, "Sidewalk")

        # 4. Draw driveway strip (from ACTUAL road edge nearest garage to garage door)
        # Phase B.7.4: query road_network for the garage's nearest road point (not the
        # house's). The garage door is at lot-local [garage_offset.x, 0, garage_offset.z + 2.0]
        # (garage_detached.mog has door at Z=-2.0; with rot_y=180 the door faces +Z = forward).
        if lot.has("driveway"):
                var driveway: Dictionary = lot["driveway"]
                # Find the garage companion to get its position
                var garage_offset: Vector3 = Vector3(10, 0, 2)  # default from suburb recipes
                for companion in lot.get("companions", []):
                        if companion.get("role", "") == "garage":
                                var off_arr: Array = companion.get("offset", [10, 0, 2])
                                garage_offset = Vector3(float(off_arr[0]), float(off_arr[1]), float(off_arr[2]))
                                break
                # Garage door is 2m forward of garage origin (garage_detached.mog door at Z=-2.0, rot_y=180 flips to +Z)
                var garage_door_local := Vector3(garage_offset.x, 0, garage_offset.z + 2.0)
                var garage_door_world := _local_to_world(garage_door_local, anchor, cos_y, sin_y)
                # Garage world position (to query road_network for nearest road to garage)
                var garage_world := _local_to_world(garage_offset, anchor, cos_y, sin_y)
                # Query road_network for garage's nearest road edge (via streamer.roads)
                var garage_road_edge: Vector3 = parcel.road_edge_pos  # fallback to house road edge
                if streamer.has_method("_get_road_edge_near"):
                        garage_road_edge = streamer._get_road_edge_near(garage_world)
                elif parcel.road_distance > 0.1:
                        garage_road_edge = parcel.road_edge_pos
                else:
                        garage_road_edge = _local_to_world(Vector3(garage_offset.x, 0, 6.0), anchor, cos_y, sin_y)
                _draw_strip_world(driveway, garage_road_edge, garage_door_world, chunk_root, streamer, "Driveway")

        return placed_count

# Pick a lot recipe name for a biome using the given RNG. Returns "" if no lot
# for this biome (procedural fallback in chunk_streamer).
func pick_lot_for_biome(biome: int, crng: RandomNumberGenerator) -> String:
        return LotRecipes.pick_lot_for_biome(biome, crng)

# Helper: stamp a single building slot (primary or companion).
# Mirrors DistrictStamper's slot loop body, with the difference that the
# rotation is lot_yaw + slot.rot_y (no separate template-level yaw).
func _stamp_building_slot(
                slot: Dictionary,
                anchor: Vector3,
                lot_yaw: float,
                cos_y: float, sin_y: float,
                chunk_root: Node3D,
                crng: RandomNumberGenerator,
                streamer,
                name_prefix: String
) -> Node3D:
        var variants: Array = slot.get("variants", [])
        if variants.is_empty():
                return null
        var asset_name: String = variants[crng.randi() % variants.size()]
        var scene: PackedScene = streamer._get_asset(asset_name)
        if scene == null:
                push_warning("[LotStamper] asset '%s' not in manifest" % asset_name)
                return null
        # Compute world position: anchor + rotated lot-local offset
        var local_pos_arr: Array = slot.get("offset", [0, 0, 0])
        var local_pos := Vector3(float(local_pos_arr[0]), float(local_pos_arr[1]), float(local_pos_arr[2]))
        var world_pos := _local_to_world(local_pos, anchor, cos_y, sin_y)
        # Apply slot rotation + small jitter
        var slot_rot_y: float = deg_to_rad(float(slot.get("rot_y", 0.0)))
        var jitter: float = deg_to_rad(crng.randf_range(-ROT_JITTER_DEG, ROT_JITTER_DEG))
        var final_rot_y: float = lot_yaw + slot_rot_y + jitter
        # Instantiate
        var inst: Node3D = scene.instantiate()
        inst.position = world_pos
        inst.rotation.y = final_rot_y
        inst.name = "%s_%s_%d" % [name_prefix, asset_name, crng.randi() % 100000]
        inst.set_meta("building_name", asset_name)
        chunk_root.add_child(inst)
        # Attach trimesh/box collision (same path as DistrictStamper + procedural buildings)
        streamer._attach_building_collision(inst)
        return inst

# Helper: draw a strip (sidewalk or driveway) from start to end in WORLD space.
# Phase B.7.4: replaced the old lot-local _draw_strip with this world-space version.
# The start/end points are computed from parcel.road_edge_pos + building geometry,
# NOT from hardcoded recipe offsets. This is THE fix for "paths don't connect to roads".
func _draw_strip_world(
                strip: Dictionary,
                start_world: Vector3,
                end_world: Vector3,
                chunk_root: Node3D,
                streamer,
                strip_type: String
) -> void:
        var center := (start_world + end_world) * 0.5
        # Y is slightly above 0 to avoid z-fighting with the ground mesh.
        center.y = 0.02
        var length := start_world.distance_to(end_world)
        if length < 0.5:
                return  # too short to bother drawing (road is very close to door)
        var width: float = float(strip.get("width", 1.5))
        var color: Color = strip.get("color", Color(0.5, 0.5, 0.5, 1))
        var yaw: float = atan2(end_world.x - start_world.x, end_world.z - start_world.z)
        # Delegate to chunk_streamer's plane mesh helper (keeps material + naming consistent)
        streamer._create_plane_mesh_rotated(chunk_root, strip_type, center, Vector2(width, length), color, yaw)

# Helper: draw a strip (sidewalk or driveway) from start to end in lot-local space.
# Mirrors the existing _create_plane_mesh_rotated call pattern in chunk_streamer.gd:678
# (used for interior paths).
func _draw_strip(
                strip: Dictionary,
                anchor: Vector3,
                cos_y: float, sin_y: float,
                chunk_root: Node3D,
                streamer,
                strip_type: String
) -> void:
        var start_arr: Array = strip.get("start", [0, 0, 0])
        var end_arr: Array = strip.get("end", [0, 0, 0])
        var start_local := Vector3(float(start_arr[0]), float(start_arr[1]), float(start_arr[2]))
        var end_local := Vector3(float(end_arr[0]), float(end_arr[1]), float(end_arr[2]))
        var start_world := _local_to_world(start_local, anchor, cos_y, sin_y)
        var end_world := _local_to_world(end_local, anchor, cos_y, sin_y)
        _draw_strip_world(strip, start_world, end_world, chunk_root, streamer, strip_type)

# Transform lot-local position to world.
# Same formula as district_stamper.gd:153 (kept in sync deliberately).
# Local +X (right) → (cos θ, 0, -sin θ) world.
# Local +Z (forward = toward road) → (sin θ, 0, cos θ) world.
# Result: world = anchor + (local.x * right + local.z * forward).
static func _local_to_world(local_pos: Vector3, anchor: Vector3, cos_y: float, sin_y: float) -> Vector3:
        var world_x: float = anchor.x + local_pos.x * cos_y + local_pos.z * sin_y
        var world_z: float = anchor.z - local_pos.x * sin_y + local_pos.z * cos_y
        return Vector3(world_x, anchor.y + local_pos.y, world_z)
