extends CharacterBody3D

# First-person controller for Mazar Alpha — main scene.
# v8.2 (2026-09-13): full component interaction matrix:
#   E (interact)    → open/close doors (pivot swings on hinge edge)
#                   → open/close windows (mesh hides, collider disables)
#   Q (break)       → smash windows (hide mesh + disable collider + is_broken)
#   Jump + look at climbable+passable window → vault over (teleport fwd+up)
#
# Raycasts forward ~3m from camera each physics frame; if the hit node
# (or any ancestor) carries meta "interactive"=true, the player can interact.
# The meta tags are set by ChunkStreamer._attach_components:
#   - hinged doors: meta on the pivot Node3D (parent of the door mesh)
#   - windows + hingeless doors: meta on the comp_inst Node3D itself
#
# Component state flags (read via get_meta):
#   is_open      — door/window open (toggleable via E)
#   is_broken   — window smashed (one-way; via Q)
#   is_locked    — door/window locked (TODO: unlock via inventory item)
#
# Collider toggling: when a door/window opens, we disable its child
# CollisionShape3D (via set_deferred("disabled", true)) so the player can
# walk through. When closed, re-enabled. This is physics-thread-safe.
#
# Visual feedback:
#   - Door open  : mesh visible (swung out of doorway), collider disabled
#   - Window open: mesh hidden (slid up), collider disabled
#   - Window broken: mesh hidden, collider disabled, is_broken=true
#
# Climb only fires if the window is currently passable (open OR broken).
# Vault distance: 1.5m forward + 1.2m up. Cooldown: 0.5s to avoid spamming.

const WALK := 5.0
const SPRINT := 8.0
const FLY_SPEED := 20.0       # fly mode speed (fast — for assessment)
const SENS := 0.002
const INTERACT_REACH := 3.0   # meters — how far the player can reach
const SWING_DEG := 90.0       # door open angle
const VAULT_FORWARD := 1.5    # meters forward teleport on vault
const VAULT_UP := 1.2         # meters upward teleport on vault
const VAULT_COOLDOWN := 0.5   # seconds between vaults
const VAULT_MAX_DIST := 2.5   # max distance to window for vault

# Weapon system
const WeaponSystem := preload("res://weapons/weapon_system.gd")
const WeaponViewModel := preload("res://weapons/weapon_viewmodel.gd")
var _weapon_system: Node
var _weapon_viewmodel: Node
var _crosshair: Control

var spd := WALK
var look_target: Node3D = null  # current interactive node under crosshair
var _vault_timer: float = 0.0  # cooldown timer
var _fly_mode: bool = false    # Phase B.4: toggle fly mode for map assessment

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    # Setup weapon system — attach to camera (Cam)
    var cam := $Cam
    _weapon_system = WeaponSystem.new()
    _weapon_system.name = "WeaponSystem"
    cam.add_child(_weapon_system)
    _weapon_system.equip("pistol")
    _weapon_system.set_world_root(get_parent())
    # Setup weapon viewmodel (visible gun in first person)
    _weapon_viewmodel = WeaponViewModel.new()
    _weapon_viewmodel.name = "WeaponViewModel"
    cam.add_child(_weapon_viewmodel)
    # Add crosshair UI
    _setup_crosshair()

func _setup_crosshair() -> void:
    # Simple crosshair: 4 small colored rectangles around screen center
    var layer := CanvasLayer.new()
    layer.name = "CrosshairLayer"
    get_parent().add_child(layer)
    _crosshair = Control.new()
    _crosshair.name = "Crosshair"
    _crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(_crosshair)
    # Center dot
    var dot := ColorRect.new()
    dot.color = Color(1, 0, 0, 0.8)
    dot.size = Vector2(4, 4)
    dot.position = Vector2(-2, -2)
    _crosshair.add_child(dot)
    # 4 lines
    for dir in ["top", "bottom", "left", "right"]:
        var line := ColorRect.new()
        line.color = Color(1, 0, 0, 0.6)
        line.size = Vector2(2, 8) if dir in ["top", "bottom"] else Vector2(8, 2)
        match dir:
            "top": line.position = Vector2(-1, -15)
            "bottom": line.position = Vector2(-1, 7)
            "left": line.position = Vector2(-15, -1)
            "right": line.position = Vector2(7, -1)
        _crosshair.add_child(line)

# Switch weapon: updates both weapon_system (gameplay) + weapon_viewmodel (visual)
func _switch_weapon(weapon_class: String) -> void:
    if _weapon_system:
        _weapon_system.equip(weapon_class)
    if _weapon_viewmodel:
        _weapon_viewmodel.equip(weapon_class)

func _input(e: InputEvent) -> void:
    if e is InputEventMouseMotion:
        rotate_y(-e.relative.x * SENS)
        $Cam.rotate_x(-e.relative.y * SENS)
        $Cam.rotation.x = clamp($Cam.rotation.x, -1.5, 1.5)
    if e.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if e.is_action_pressed("interact"):
        _try_interact()
    if e.is_action_pressed("break"):
        _try_break()
    # Fire weapon on left click
    if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        if _weapon_system:
            _weapon_system.fire()
    # Weapon switch: 1=pistol, 2=rifle, 3=shotgun, 4=sniper
    if e is InputEventKey and e.pressed:
        match e.keycode:
            KEY_1: _switch_weapon("pistol")
            KEY_2: _switch_weapon("rifle")
            KEY_3: _switch_weapon("shotgun")
            KEY_4: _switch_weapon("sniper_rifle")
    # Phase B.4: T toggles fly mode for map assessment
    if e is InputEventKey and e.pressed and e.keycode == KEY_T:
        _fly_mode = not _fly_mode
        if _fly_mode:
            velocity = Vector3.ZERO
        print("[Player] fly mode %s" % ("ON — WASD move, Space=up, Ctrl=down, fast" if _fly_mode else "OFF — walking"))
    # v8.2 Phase A.10: F8 dumps all loaded chunk states to JSON for analysis
    if e is InputEventKey and e.pressed and e.keycode == KEY_F8:
        var streamer := get_tree().current_scene.get_node_or_null("ChunkStreamer")
        if streamer and streamer.has_method("_dump_chunk_states_to_file"):
            streamer._dump_chunk_states_to_file("res://chunk_states_dump.json")
            print("[Player] F8 — dumped chunk states to res://chunk_states_dump.json")

func _physics_process(d: float) -> void:
    _vault_timer = max(0.0, _vault_timer - d)

    if _fly_mode:
        # Phase B.4: FLY MODE — free 3D movement for map assessment.
        # No gravity, no collision (pass through everything), fast movement.
        # WASD = horizontal, Space = up, Ctrl = down.
        var fly_spd = FLY_SPEED
        var i := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        var dir := (transform.basis * Vector3(i.x, 0, i.y)).normalized()
        velocity = dir * fly_spd
        # Up/down
        if Input.is_action_pressed("jump"):
            velocity.y = fly_spd
        elif Input.is_action_pressed("crouch"):
            velocity.y = -fly_spd
        else:
            velocity.y = 0
        # Sprint = even faster in fly mode
        if Input.is_action_pressed("sprint"):
            velocity *= 3.0
        global_position += velocity * d  # fly = no collision, direct position update
        _update_look_target()
        return

    # Normal walking mode
    if not is_on_floor():
        velocity.y -= 9.8 * d
    # v8.2: vault overrides jump when looking at a climbable+passable window.
    if Input.is_action_just_pressed("jump") and _try_vault():
        return  # vaulted — skip regular jump this frame
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = 4.5
    spd = SPRINT if Input.is_action_pressed("sprint") else WALK
    var i := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := (transform.basis * Vector3(i.x, 0, i.y)).normalized()
    if dir:
        velocity.x = dir.x * spd
        velocity.z = dir.z * spd
    else:
        velocity.x = move_toward(velocity.x, 0, spd * d * 10)
        velocity.z = move_toward(velocity.z, 0, spd * d * 10)
    move_and_slide()
    _update_look_target()

# Cast a ray forward from camera, find the nearest interactive node within reach.
# Walks up the parent chain from the ray hit collider to find a node tagged
# with meta "interactive"=true (set by ChunkStreamer._attach_components).
func _update_look_target() -> void:
    var cam: Camera3D = $Cam
    var from: Vector3 = cam.global_position
    var to: Vector3 = from - cam.global_transform.basis.z * INTERACT_REACH
    var space := get_world_3d().direct_space_state
    var params := PhysicsRayQueryParameters3D.create(from, to)
    params.collide_with_areas = false
    params.collide_with_bodies = true
    var hit: Dictionary = space.intersect_ray(params)
    if hit.is_empty():
        if look_target != null:
            look_target = null
        return
    var collider = hit.collider
    var node: Node = collider
    while node != null:
        if node is Node3D and node.has_meta("interactive") and bool(node.get_meta("interactive")):
            if look_target != node:
                look_target = node
                var comp_type := String(node.get_meta("component_type", "?"))
                print("[Interact] looking at %s (%s)" % [node.name, comp_type])
            return
        node = node.get_parent()
    if look_target != null:
        look_target = null

# Pressed E — toggle open/close on the door/window under the crosshair.
# For hinged doors (with pivot parent): rotates the pivot (which swings the door).
# For windows: hides the mesh and disables the collider (visually "slid open").
# For doors without pivot: same as windows (rotate in place + disable collider).
func _try_interact() -> void:
    if look_target == null:
        return
    if not look_target.has_meta("can_open") or not bool(look_target.get_meta("can_open")):
        return
    var is_open := bool(look_target.get_meta("is_open"))
    if is_open:
        # Close — restore saved rotation, re-enable collider, show mesh.
        if look_target.has_meta("closed_rotation_y"):
            look_target.rotation.y = float(look_target.get_meta("closed_rotation_y"))
        look_target.set_meta("is_open", false)
        _set_component_collider_enabled(look_target, true)
        _set_component_visible(look_target, true)
        print("[Interact] Closed %s" % look_target.name)
    else:
        # Open — save current rotation, swing, disable collider, hide mesh
        # (windows: hide; doors: keep visible since they swung out of the way
        # but disable collider so player can walk through the doorway).
        look_target.set_meta("closed_rotation_y", look_target.rotation.y)
        var hinge_side: String = "left"
        if look_target.has_meta("hinge_side"):
            hinge_side = String(look_target.get_meta("hinge_side"))
        var swing_dir: float = -1.0 if hinge_side == "left" else 1.0
        look_target.rotation.y += deg_to_rad(SWING_DEG) * swing_dir
        look_target.set_meta("is_open", true)
        _set_component_collider_enabled(look_target, false)
        # Hide window meshes so the opening is clear (door meshes stay visible
        # since they're now rotated out of the doorway).
        var comp_type := String(look_target.get_meta("component_type", ""))
        if comp_type == "window_unit":
            _set_component_visible(look_target, false)
        print("[Interact] Opened %s" % look_target.name)

# Pressed Q — break the window under the crosshair (smash).
# Hides the mesh, disables the collider, sets is_broken=true. One-way:
# once broken, can't be unbroken via Q (would need a "repair" interaction).
func _try_break() -> void:
    if look_target == null:
        return
    if not look_target.has_meta("can_break") or not bool(look_target.get_meta("can_break")):
        return
    if look_target.has_meta("is_broken") and bool(look_target.get_meta("is_broken")):
        return  # already broken
    _set_component_visible(look_target, false)
    _set_component_collider_enabled(look_target, false)
    look_target.set_meta("is_broken", true)
    look_target.set_meta("is_open", true)  # broken = passable
    print("[Break] smashed %s" % look_target.name)

# Pressed Jump while looking at a climbable+passable window → vault over.
# Returns true if vault fired (so caller can skip regular jump this frame).
# Vault teleports the player VAULT_FORWARD meters forward and VAULT_UP meters up.
# Cooldown VAULT_COOLDOWN seconds to avoid spam.
func _try_vault() -> bool:
    if _vault_timer > 0.0:
        return false
    if look_target == null:
        return false
    if not look_target.has_meta("can_climb") or not bool(look_target.get_meta("can_climb")):
        return false
    # Window must be passable (open or broken) — can't vault through solid glass.
    var is_open := look_target.has_meta("is_open") and bool(look_target.get_meta("is_open"))
    var is_broken := look_target.has_meta("is_broken") and bool(look_target.get_meta("is_broken"))
    if not (is_open or is_broken):
        return false
    var dist := global_position.distance_to(look_target.global_position)
    if dist > VAULT_MAX_DIST:
        return false
    var forward := -global_transform.basis.z
    global_position += forward * VAULT_FORWARD
    global_position.y += VAULT_UP
    velocity.y = 2.0  # small upward boost to clear the sill
    _vault_timer = VAULT_COOLDOWN
    print("[Vault] climbed over %s" % look_target.name)
    return true

# Toggle a component's collider on/off. Walks all StaticBody3D descendants of
# `node` (the interactive node — pivot for doors, comp_inst for windows) and
# sets `disabled` on each CollisionShape3D found. Uses set_deferred because
# the physics thread reads this property — setting it directly during a frame
# can crash or be silently dropped.
func _set_component_collider_enabled(node: Node3D, enabled: bool) -> void:
    for body in node.find_children("*", "StaticBody3D", true, false):
        for col in body.find_children("*", "CollisionShape3D", true, false):
            col.set_deferred("disabled", not enabled)

# Toggle a component's mesh visibility. Walks all MeshInstance3D descendants
# of `node` and sets their `.visible`. For windows: hides the glass mesh so
# the opening is clear. For doors: caller decides whether to hide.
func _set_component_visible(node: Node3D, vis: bool) -> void:
    for mi in node.find_children("*", "MeshInstance3D", true, false):
        mi.visible = vis
