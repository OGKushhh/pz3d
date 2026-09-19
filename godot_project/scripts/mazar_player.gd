# MazarPlayer — extends CogitoPlayerAdvanced for Mazar-specific features.
#
# This is how we extend Cogito: subclass their player, add our city features.
# We do NOT modify CogitoPlayerAdvanced. We inherit everything:
#   - Movement (walk, sprint, crouch, slide, stairs, ladders, swimming)
#   - Interaction system (doors, containers, keypads, carryables)
#   - Inventory (CogitoInventory)
#   - Attributes (health, stamina, sanity, oxygen, lightmeter)
#   - Save/load (CogitoSceneManager)
#   - HUD (PlayerHUD)
#   - Footsteps (DynamicFootstepSystem)
#   - Wieldables (CogitoWieldable → our WieldableHitscan)
#
# We add:
#   - ChunkLoader (baked city streaming — loads .tscn chunks near player)
#   - Fly mode (T key — for map assessment, no collision)
#   - F8 chunk state dump (for middleware analysis)
#   - Weapon system integration (recoil offset applied to camera)
#
# Usage in scene:
#   - Instance cogito_player_advanced.tscn
#   - Change script to mazar_player.gd
#   - Add ChunkLoader as child node

extends CogitoPlayerAdvanced
class_name MazarPlayer

const CHUNK_SIZE := 250.0
const CHUNKS_COLS := 16
const CHUNKS_ROWS := 12
const CHUNK_DIR := "res://scenes/baked_chunks/"
const FLY_SPEED := 20.0
const STREAM_RADIUS := 2

var _fly_mode: bool = false
var _chunk_loader: Node3D
var _loaded_chunks: Dictionary = {}  # Vector2i -> Node3D
var _last_chunk: Vector2i = Vector2i(-999, -999)

func _ready() -> void:
        super._ready()
        # Fix: Cogito defaults INVERT_Y_AXIS=true (inverted mouse). Most FPS players
        # expect non-inverted (push up = look up). Override to false.
        INVERT_Y_AXIS = false
        # Add ChunkLoader as child
        _setup_chunk_loader()
        print("[MazarPlayer] ready — CogitoPlayerAdvanced + chunk streaming + fly mode")

func _setup_chunk_loader() -> void:
        # Create ChunkLoader as a child of the player
        _chunk_loader = Node3D.new()
        _chunk_loader.name = "ChunkLoader"
        add_child(_chunk_loader)
        # Force initial chunk load at player position
        _refresh_chunks()

func _process(_delta: float) -> void:
        pass # CogitoPlayerAdvanced has no _process
        # Check if player moved to a new chunk
        var cx := int(global_position.x / CHUNK_SIZE)
        var cz := int(global_position.z / CHUNK_SIZE)
        var current_chunk := Vector2i(cx, cz)
        if current_chunk != _last_chunk:
                _last_chunk = current_chunk
                _refresh_chunks(current_chunk)

func on_input(event: InputEvent) -> void:
        # Let Cogito handle its input first (movement, interaction, etc.)
        super.on_input(event)

        # Our additions:
        # T = toggle fly mode
        if event is InputEventKey and event.pressed and event.keycode == KEY_T:
                _fly_mode = not _fly_mode
                if _fly_mode:
                        velocity = Vector3.ZERO
                # Toggle collision shapes
                standing_collision_shape.set_deferred("disabled", _fly_mode)
                crouching_collision_shape.set_deferred("disabled", _fly_mode)
                print("[MazarPlayer] fly mode %s" % ("ON" if _fly_mode else "OFF"))

        # F8 = dump chunk states for middleware
        if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
                var streamer := get_tree().current_scene.get_node_or_null("ChunkStreamer")
                if streamer and streamer.has_method("_dump_chunk_states_to_file"):
                        streamer._dump_chunk_states_to_file("res://chunk_states_dump.json")
                        print("[MazarPlayer] F8 — dumped chunk states")

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
        var pic := get_node_or_null("Body/Neck/Head/Eyes/Camera/RecoilController")
        if pic and pic.has_method("get_recoil_offset"):
                var recoil: Vector2 = pic.get_recoil_offset()
                if recoil != Vector2.ZERO:
                        # Add recoil to camera rotation (additive, on top of Cogito's look)
                        camera.rotation.x += deg_to_rad(recoil.x) * delta * 10.0
                        camera.rotation.y += deg_to_rad(recoil.y) * delta * 10.0

# === Chunk streaming ===
func _refresh_chunks(center: Vector2i = Vector2i(-999, -999)) -> void:
        if center == Vector2i(-999, -999):
                var cx := int(global_position.x / CHUNK_SIZE)
                var cz := int(global_position.z / CHUNK_SIZE)
                center = Vector2i(cx, cz)

        # Load chunks in radius
        for dy in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
                for dx in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
                        var key := Vector2i(center.x + dx, center.y + dy)
                        if key.x < 0 or key.y < 0 or key.x >= CHUNKS_COLS or key.y >= CHUNKS_ROWS:
                                continue
                        if not _loaded_chunks.has(key):
                                _load_chunk(key)

        # Unload distant chunks
        var unload_r := STREAM_RADIUS + 1
        var to_unload: Array = []
        for key in _loaded_chunks:
                var dx: int = abs(key.x - center.x)
                var dy: int = abs(key.y - center.y)
                if dx > unload_r or dy > unload_r:
                        to_unload.append(key)
        for key in to_unload:
                _unload_chunk(key)

func _load_chunk(key: Vector2i) -> void:
        var path := "%schunk_%d_%d.tscn" % [CHUNK_DIR, key.x, key.y]
        if not ResourceLoader.exists(path):
                return  # water/empty chunk — no file
        var scene := load(path) as PackedScene
        if scene == null:
                return
        var inst := scene.instantiate()
        inst.name = "Chunk_%d_%d" % [key.x, key.y]
        get_parent().add_child(inst)
        _loaded_chunks[key] = inst

func _unload_chunk(key: Vector2i) -> void:
        var inst: Node = _loaded_chunks[key]
        inst.queue_free()
        _loaded_chunks.erase(key)
