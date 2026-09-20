# DistrictStamper — runtime template stamper for hand-authored district templates.
#
# Phase A.7 (2026-09-13): Stamps a template (defined in
# data/district_templates.gd) at an anchor position with per-run variation.
# This is the PZ hybrid approach: hand-authored layouts + procedural
# asset-variant pick + rotation jitter per stamp.
#
# See docs/district_templates.md for design rationale + locked decisions.
class_name DistrictStamper
extends RefCounted

const Templates := preload("res://data/district_templates.gd")
const CityConfig := preload("res://tools/city_config.gd")

# Probability that a building slot is left empty (creates "vacant lot" feel).
# 0.0 = every slot gets a building. 0.15 = 15% of building slots are empty.
# Per PZ's Muldraugh style — some lots are just empty grass.
const VACANT_LOT_PROB := 0.15

# Rotation jitter applied to each slot (±5 degrees from the slot's specified rot_y).
# Adds organic variation without breaking the layout. Jitter is in DEGREES.
const ROT_JITTER_DEG := 5.0

# Stamp a template at an anchor position with variation.
#
# Args:
#   template_name: name of the template (must exist in Templates.TEMPLATES)
#   anchor_pos: world position where the template's local origin sits
#   rotation_y: template-level yaw (radians) — rotates the whole template
#   chunk_root: the chunk Node3D to add instantiated nodes to
#   crng: per-chunk RNG for deterministic variation
#   streamer: the chunk_streamer instance (for _get_asset() access)
#
# Returns the count of nodes placed (buildings + foliage + props).
func stamp_template(
                template_name: String,
                anchor_pos: Vector3,
                rotation_y: float,
                chunk_root: Node3D,
                crng: RandomNumberGenerator,
                streamer
) -> int:
        var template: Dictionary = Templates.get_template(template_name)
        if template.is_empty():
                push_warning("[DistrictStamper] template '%s' not found" % template_name)
                return 0

        # Pre-compute the template's yaw basis (forward + perp vectors) so we can
        # transform local slot positions to world positions in one pass.
        # In Godot's right-handed Y-up system, a yaw rotation by angle θ around Y
        # rotates local +Z (forward) to (sin θ, 0, cos θ) and local +X (right)
        # to (cos θ, 0, -sin θ).
        var cos_y: float = cos(rotation_y)
        var sin_y: float = sin(rotation_y)

        var placed_count := 0

        # Stamp building slots
        for slot in template.get("building_slots", []):
                var variants: Array = slot.get("variants", [])
                if variants.is_empty():
                        continue
                # Vacant lot — skip with VACANT_LOT_PROB probability (but only for
                # residential/commercial slots; landmark slots always get filled).
                # We check if any variant is a landmark (government_palace, stadium,
                # old_royal_palace, fort_sarran) — those never go vacant.
                var is_landmark := _is_landmark_slot(variants)
                if not is_landmark and crng.randf() < VACANT_LOT_PROB:
                        continue
                # Pick variant
                var pick_idx: int = crng.randi() % variants.size()
                var asset_name: String = variants[pick_idx]
                # Get the PackedScene from the streamer's manifest + asset cache
                var scene: PackedScene = streamer._get_asset(asset_name)
                if scene == null:
                        push_warning("[DistrictStamper] asset '%s' not in manifest" % asset_name)
                        continue
                # Compute world position: anchor + rotated local pos
                var local_pos_arr: Array = slot.get("pos", [0, 0, 0])
                var local_pos := Vector3(float(local_pos_arr[0]), float(local_pos_arr[1]), float(local_pos_arr[2]))
                var world_pos := _local_to_world(local_pos, anchor_pos, cos_y, sin_y)
                # Apply slot rotation + jitter
                var slot_rot_y: float = deg_to_rad(float(slot.get("rot_y", 0.0)))
                var jitter: float = deg_to_rad(crng.randf_range(-ROT_JITTER_DEG, ROT_JITTER_DEG))
                var final_rot_y: float = rotation_y + slot_rot_y + jitter
                # Instantiate
                var inst: Node3D = scene.instantiate()
                inst.position = world_pos
                inst.rotation.y = final_rot_y
                inst.name = "%s_%s_%d" % [template_name, asset_name, crng.randi() % 100000]
                inst.set_meta("from_template", template_name)
                inst.set_meta("building_name", asset_name)
                chunk_root.add_child(inst)
                # v8.2: attach trimesh collision (same as procedural buildings)
                streamer._attach_building_collision(inst)
                placed_count += 1

        # Stamp foliage slots
        for slot in template.get("foliage_slots", []):
                var variants: Array = slot.get("variants", [])
                if variants.is_empty():
                        continue
                var asset_name: String = variants[crng.randi() % variants.size()]
                var scene: PackedScene = streamer._get_asset(asset_name)
                if scene == null:
                        continue
                var local_pos_arr: Array = slot.get("pos", [0, 0, 0])
                var local_pos := Vector3(float(local_pos_arr[0]), float(local_pos_arr[1]), float(local_pos_arr[2]))
                var world_pos := _local_to_world(local_pos, anchor_pos, cos_y, sin_y)
                var inst: Node3D = scene.instantiate()
                inst.position = world_pos
                inst.rotation.y = rotation_y + crng.randf_range(0, TAU)
                var tree_scale: float = crng.randf_range(0.85, 1.2)
                inst.scale = Vector3(tree_scale, tree_scale, tree_scale)
                inst.name = "%s_%s_%d" % [template_name, asset_name, crng.randi() % 100000]
                # Phase B.7.13: set building_name meta so chunk_states dumper captures foliage
                inst.set_meta("building_name", asset_name)
                inst.set_meta("from_template", template_name)
                chunk_root.add_child(inst)
                placed_count += 1

        # Stamp prop slots
        for slot in template.get("prop_slots", []):
                var variants: Array = slot.get("variants", [])
                if variants.is_empty():
                        continue
                var asset_name: String = variants[crng.randi() % variants.size()]
                var scene: PackedScene = streamer._get_asset(asset_name)
                if scene == null:
                        continue
                var local_pos_arr: Array = slot.get("pos", [0, 0, 0])
                var local_pos := Vector3(float(local_pos_arr[0]), float(local_pos_arr[1]), float(local_pos_arr[2]))
                var world_pos := _local_to_world(local_pos, anchor_pos, cos_y, sin_y)
                var inst: Node3D = scene.instantiate()
                inst.position = world_pos
                inst.rotation.y = rotation_y + crng.randf_range(0, TAU)
                inst.name = "%s_%s_%d" % [template_name, asset_name, crng.randi() % 100000]
                # Phase B.7.13: set building_name meta so chunk_states dumper captures props
                inst.set_meta("building_name", asset_name)
                inst.set_meta("from_template", template_name)
                chunk_root.add_child(inst)
                placed_count += 1

        return placed_count

# Pick a template name for a given biome. Returns "" if no template for
# this biome (procedural fallback). Uses crng for deterministic per-chunk
# variety when multiple templates exist for one biome.
func pick_template_for_biome(biome: int, crng: RandomNumberGenerator) -> String:
        var templates: Array = Templates.templates_for_biome(biome)
        if templates.is_empty():
                return ""
        return templates[crng.randi() % templates.size()]

# Transform a local template-space position to world space.
# Local +X (right) → (cos θ, 0, -sin θ) world.
# Local +Z (forward) → (sin θ, 0, cos θ) world.
# Result: world = anchor + (local.x * right + local.z * forward).
static func _local_to_world(local_pos: Vector3, anchor: Vector3, cos_y: float, sin_y: float) -> Vector3:
        var world_x: float = anchor.x + local_pos.x * cos_y + local_pos.z * sin_y
        var world_z: float = anchor.z - local_pos.x * sin_y + local_pos.z * cos_y
        return Vector3(world_x, anchor.y + local_pos.y, world_z)

# Returns true if any of the variants in this slot is a known landmark.
# Landmark slots always get filled (no vacant-lot skip) because they're
# the hero of the template — an empty lot where the stadium should be
# would break the district identity.
static func _is_landmark_slot(variants: Array) -> bool:
        const LANDMARKS := ["government_palace", "stadium", "old_royal_palace", "fort_sarran", "lighthouse", "grain_silo", "windmill", "broadcast_tower", "railway_station"]
        for v in variants:
                if LANDMARKS.has(v):
                        return true
        return false
