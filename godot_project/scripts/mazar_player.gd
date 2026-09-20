# MazarPlayer — extends CogitoPlayerAdvanced for Mazar-specific features.
#
# This is how we extend Cogito: subclass their player, add our city features.
# We do NOT modify CogitoPlayerAdvanced. We inherit everything:
#       - Movement (walk, sprint, crouch, slide, stairs, ladders, swimming)
#       - Interaction system (doors, containers, keypads, carryables)
#       - Inventory (CogitoInventory)
#       - Attributes (health, stamina, sanity, oxygen, lightmeter)
#       - Save/load (CogitoSceneManager)
#       - HUD (PlayerHUD)
#       - Footsteps (DynamicFootstepSystem)
#       - Wieldables (CogitoWieldable -> our WieldableHitscan)
#
# We add:
#       - Fly mode (T key — for map assessment, no collision)
#       - F8 scene dump (for middleware analysis)
#       - Weapon system integration (recoil offset applied to camera)
#       - Starting weapon on _ready()
#
# IMPORTANT: The city is now PREBUILD. No runtime chunk streaming.
# All blocks are baked to scenes/baked_v2/block_N.tscn and instanced
# directly in main.tscn. MazarPlayer just spawns at Downtown and plays.

extends CogitoPlayerAdvanced
class_name MazarPlayer

const FLY_SPEED := 20.0

var _fly_mode: bool = false

func _ready() -> void:
	super._ready()
	# Fix: Cogito defaults INVERT_Y_AXIS=true (inverted mouse). Most FPS players
	# expect non-inverted (push up = look up). Override to false.
	INVERT_Y_AXIS = false
	# Spawn in Downtown (block_5_5 area, 1125, 1125) — dense urban center
	# Just above ground (y=2) to avoid falling through floor on first frame.
	global_position = Vector3(1125, 2, 1125)
	# Give player a starting weapon
	_setup_starting_weapon()
	print("[MazarPlayer] ready — spawn at Downtown (1125, 1125), weapon + fly mode")

func _setup_starting_weapon() -> void:
	# Create a WieldableHitscan node and attach it to the player's Wieldables container.
	# Cogito's player has Body/Neck/Head/Wieldables as the wieldable container.
	var wieldables := get_node_or_null("Body/Neck/Head/Wieldables")
	if wieldables == null:
		print("[MazarPlayer] WARNING: Wieldables node not found — can't equip weapon")
		return
	# Create the hitscan wieldable
	var weapon := WieldableHitscan.new()
	weapon.name = "Pistol_Hitscan"
	weapon.weapon_class = "pistol"
	# Set world root for tracers + muzzle flashes
	weapon.world_root = get_parent()
	# Add to wieldables container
	wieldables.add_child(weapon)
	# Register with PlayerInteractionComponent so action_primary fires
	var pic := get_node_or_null("PlayerInteractionComponent")
	if pic:
		# Add to wieldable_nodes array
		if "wieldable_nodes" in pic:
			pic.wieldable_nodes.append(weapon)
		# Equip it
		if weapon.has_method("equip") and pic.has_method("equip_wieldable"):
			# Can't equip via inventory (no item created yet) — just show the mesh
			weapon.equip(pic)
	# Show the weapon mesh (if any PPS model is set)
	if weapon.wieldable_mesh:
		weapon.wieldable_mesh.show()
	print("[MazarPlayer] equipped: WieldableHitscan (pistol)")

func _unhandled_input(event: InputEvent) -> void:
	# T = toggle fly mode
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_fly_mode = not _fly_mode
		if _fly_mode:
			velocity = Vector3.ZERO
		# Toggle collision shapes
		if standing_collision_shape:
			standing_collision_shape.set_deferred("disabled", _fly_mode)
		if crouching_collision_shape:
			crouching_collision_shape.set_deferred("disabled", _fly_mode)
		print("[MazarPlayer] fly mode %s" % ("ON" if _fly_mode else "OFF"))

	# F8 = dump scene state for middleware
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		_dump_scene_state()

func _physics_process(delta: float) -> void:
	if _fly_mode:
		# Fly mode: free 3D movement, no gravity, no collision
		var i := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dir := (transform.basis * Vector3(i.x, 0, i.y)).normalized()
		velocity = dir * FLY_SPEED
		if Input.is_action_pressed("jump"):
			velocity.y = FLY_SPEED
		elif Input.is_action_pressed("crouch"):
			velocity.y = -FLY_SPEED
		else:
			velocity.y = 0
		if Input.is_action_pressed("sprint"):
			velocity *= 3.0
		global_position += velocity * delta
		return

	# Normal mode: let CogitoPlayerAdvanced handle movement
	super._physics_process(delta)

	# Apply recoil offset to camera (from WieldableHitscan's RecoilController)
	var recoil_node := get_node_or_null("Body/Neck/Head/Eyes/Camera/RecoilController")
	if recoil_node and recoil_node.has_method("get_recoil_offset"):
		var recoil: Vector2 = recoil_node.get_recoil_offset()
		if recoil != Vector2.ZERO:
			# Add recoil to camera rotation (additive, on top of Cogito's look)
			if camera:
				camera.rotation.x += deg_to_rad(recoil.x) * delta * 10.0
				camera.rotation.y += deg_to_rad(recoil.y) * delta * 10.0

func _dump_scene_state() -> void:
	# Dumps a summary of the current scene for middleware analysis
	var root := get_tree().current_scene
	if not root:
		return
	var counts: Dictionary = {}
	var total: int = 0
	for child in root.get_children(true):
		var t: String = child.get_class()
		counts[t] = int(counts.get(t, 0)) + 1
		total += 1
	print("[MazarPlayer] F8 — scene dump:")
	print("  Root: %s" % root.name)
	print("  Total nodes: %d" % total)
	for k in counts:
		print("    %s: %d" % [k, counts[k]])
