extends CharacterBody3D

# First-person controller for Mazar Alpha — main scene.
# v2 (2026-09-13): added door/window interaction via raycast + E key.
# Raycasts forward ~3m from camera each physics frame; if the hit node
# (or any ancestor) carries meta "interactive"=true, the player can press
# the "interact" action (default: E) to toggle its state.
#
# For doors: toggles rotation.y by 90° around its center (visual "swing").
#   A proper hinge-edge pivot would require wrapping the door in a pivot
#   node at spawn time — TODO for a future pass.
#
# For windows: future work (break / climb) — not yet wired here.
#
# Look target name is printed to console when interaction fires, so you can
# verify the runtime component spawn is working (e.g. "Opened comp_shed_door_42").

const WALK := 5.0
const SPRINT := 8.0
const SENS := 0.002
const INTERACT_REACH := 3.0   # meters — how far the player can reach to touch a door
const SWING_DEG := 90.0       # door open angle

var spd := WALK
var look_target: Node3D = null  # current interactive node under crosshair

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(e: InputEvent) -> void:
    if e is InputEventMouseMotion:
        rotate_y(-e.relative.x * SENS)
        $Cam.rotate_x(-e.relative.y * SENS)
        $Cam.rotation.x = clamp($Cam.rotation.x, -1.5, 1.5)
    if e.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if e.is_action_pressed("interact"):
        _try_interact()

func _physics_process(d: float) -> void:
    if not is_on_floor():
        velocity.y -= 9.8 * d
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
                print("[Interact] looking at %s" % node.name)
            return
        node = node.get_parent()
    if look_target != null:
        look_target = null

# Pressed E — toggle open/close on the door under the crosshair.
func _try_interact() -> void:
    if look_target == null:
        return
    if not look_target.has_meta("can_open") or not bool(look_target.get_meta("can_open")):
        return
    var is_open := bool(look_target.get_meta("is_open"))
    if is_open:
        # Close — restore saved rotation.
        if look_target.has_meta("closed_rotation_y"):
            look_target.rotation.y = float(look_target.get_meta("closed_rotation_y"))
        look_target.set_meta("is_open", false)
        print("[Interact] Closed %s" % look_target.name)
    else:
        # Open — save current rotation, then swing.
        look_target.set_meta("closed_rotation_y", look_target.rotation.y)
        var hinge_side: String = "left"
        if look_target.has_meta("hinge_side"):
            hinge_side = String(look_target.get_meta("hinge_side"))
        var swing_dir: float = -1.0 if hinge_side == "left" else 1.0
        look_target.rotation.y += deg_to_rad(SWING_DEG) * swing_dir
        look_target.set_meta("is_open", true)
        print("[Interact] Opened %s" % look_target.name)
