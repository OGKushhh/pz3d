# Extraction from retired `godot_project/scripts/city_builder.gd` (v3 prototype)

> **Source:** the 579-line `extends SceneTree` prototype the user pasted (deleted from repo in commit `57fc789`).
> **Captured:** 2026-09-12 by user request — copy exact values, don't summarize.
> **Destination:** constants → `city_config.gd`; sky/sun → `environment_setup.gd`; placement rules → top of `chunk_builder.gd`; helpers → review for inclusion.

---

## 1. Constants block — paste into `city_config.gd`

These are the tuned numeric constants from the retired v3 prototype. Names preserved where possible. Where the current `city_config.gd` already has the constant, the comment notes the difference.

```gdscript
# ── TUNED PLACEMENT CONSTANTS (extracted from retired city_builder.gd v3) ─────
# Captured 2026-09-12 from the deleted extends SceneTree prototype.
# These values were tuned over user-screenshot iterations and represent
# "what looked right" for Suburbia in the v3 prototype. Port to chunk_builder.gd
# when refactoring placement (Phase B).

# Road grid (current city_config.gd has ROAD_WIDTH=8.0 already — keep)
const ROAD_WIDTH           := 8.0     # v3: same
const SIDEWALK_WIDTH       := 1.5    # v3: was 2.0 in current city_config.gd; v3 found 1.5 looked better
const GRASS_STRIP_WIDTH    := 2.5    # NEW — wider grass strip prevents tree/building clipping
const BUILDING_SETBACK     := 1.5    # v3: was 4.0 in current city_config.gd; v3 found 1.5 was enough with wider lots
const LOT_WIDTH            := 20.0   # NEW — wider lots = no collision between houses
const LOT_DEPTH            := 16.0   # NEW — deeper lots = front/back spacing
const ROAD_LENGTH          := 160.0  # NEW — length of generated road segments (matches 1 chunk width × 0.64)
const ROAD_SPACING         := 60.0   # NEW — distance between parallel road centerlines

# Building offset (computed at runtime in v3, but capture formula):
#   building_offset = ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH + BUILDING_SETBACK
#                  = 4.0 + 1.5 + 2.5 + 1.5 = 9.5m from road centerline to building face

# Color palette (v3 used these for primitive mesh roads/sidewalks/grass before we had GLB assets)
const COLOR_ROAD           := Color(0.12, 0.12, 0.14, 1)
const COLOR_SIDEWALK       := Color(0.70, 0.68, 0.64, 1)
const COLOR_GRASS_STRIP    := Color(0.30, 0.50, 0.22, 1)   # darker than grass_tan in current config
const COLOR_GROUND         := Color(0.22, 0.40, 0.16, 1)   # main ground plane

# Lighting + fog (v3 tuned these; main.tscn currently uses different values — port if v3 looked better)
const SKY_TOP_COLOR        := Color(0.15, 0.35, 0.70, 1)
const SKY_HORIZON_COLOR    := Color(0.70, 0.78, 0.88, 1)
const GROUND_BOTTOM_COLOR  := Color(0.25, 0.22, 0.18, 1)
const GROUND_HORIZON_COLOR := Color(0.50, 0.48, 0.42, 1)
const SUN_COLOR            := Color(1.0,  0.95, 0.80, 1)
const SUN_ENERGY           := 2.0
const SUN_SHADOW_MAX_DIST  := 80.0    # v3: was 300 in main.tscn — v3 chose 80 for perf on Low preset
const SUN_SHADOW_SIZE      := 2048
const AMBIENT_LIGHT_COLOR  := Color(0.55, 0.60, 0.65, 1)
const AMBIENT_LIGHT_ENERGY := 0.6
const FOG_COLOR            := Color(0.50, 0.55, 0.60, 1)
const FOG_DENSITY          := 0.005   # v3: was 0.002 in main.tscn — v3 wanted thicker fog
const FOG_AERIAL_PERSPECTIVE := 0.4
const TONEMAP_WHITE        := 1.0
const SSAO_RADIUS          := 1.0
const SSAO_INTENSITY       := 1.2

# Sun angle (v3 used 45° around Y, then -30° around X)
const SUN_POSITION          := Vector3(-40, 60, -40)
const SUN_YAW_DEG           := 45.0    # rotate around UP
const SUN_PITCH_DEG         := -30.0   # rotate around RIGHT
const SUN_ANGLE_MAX         := 30.0    # ProceduralSkyMaterial
const SUN_CURVE             := 0.12    # ProceduralSkyMaterial

# Street furniture spacing (v3 tuned these for less clutter)
const STREETLIGHT_SPACING_V3 := 25.0   # v3: was 20 in earlier prototypes; 25 is less cluttered
const MAILBOX_SPACING         := 36.0
const TRASHCAN_SPACING        := 42.0
const UTILITY_POLE_SPACING    := 35.0
const UTILITY_POLE_OFFSET     := 2.0   # behind building (building_offset + LOT_DEPTH + 2.0)
const TREE_SPACING            := 12.0  # along grass strip
const HEDGE_SPACING           := 10.0  # along front property line
const FLOWER_PATCH_SPACING    := 25.0

# Player
const PLAYER_EYE_HEIGHT      := 1.65
const PLAYER_RADIUS          := 0.4
const PLAYER_HEIGHT          := 1.8
const PLAYER_FOV             := 75.0
const PLAYER_CAM_NEAR        := 0.05
const PLAYER_CAM_FAR         := 200.0  # v3: was 500 in main.tscn — v3 chose 200 for fog to mask pop-in

# Movement
const WALK_SPEED             := 5.0
const SPRINT_SPEED           := 8.0
const MOUSE_SENSITIVITY      := 0.002
const GRAVITY                := 9.8
const JUMP_VELOCITY           := 4.5
```

**Notes on differences vs current `city_config.gd`:**
- `SIDEWALK_WIDTH`: v3 used 1.5 (current uses 2.0). v3 rationale: narrower sidewalk + wider grass strip = more room for trees.
- `BUILDING_SETBACK`: v3 used 1.5 (current uses 4.0). v3 rationale: with wider lots (LOT_WIDTH=20), setback can be smaller.
- `ROAD_SPACING`, `ROAD_LENGTH`: new — v3 used explicit road geometry. Current `road_network.gd` uses procedural generation, may not need these.
- `GRASS_STRIP_WIDTH`, `LOT_WIDTH`, `LOT_DEPTH`: new — v3 introduced these for explicit lot-based placement. Current `chunk_builder.gd` uses block-based 4×4 grid (different approach).

---

## 2. Environment setup functions — paste into `environment_setup.gd`

Current `environment_setup.gd` is a 7-line stub. These are the v3 functions verbatim. Replace the stub.

```gdscript
# ============================================================
# SKY
# ============================================================
func _setup_sky():
	var env = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.35, 0.70, 1)
	sky_mat.sky_horizon_color = Color(0.70, 0.78, 0.88, 1)
	sky_mat.ground_bottom_color = Color(0.25, 0.22, 0.18, 1)
	sky_mat.ground_horizon_color = Color(0.50, 0.48, 0.42, 1)
	sky_mat.sun_angle_max = 30.0
	sky_mat.sun_curve = 0.12
	sky_mat.use_debanding = true
	var sky = Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.55, 0.60, 0.65, 1)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.50, 0.55, 0.60, 1)
	env.fog_density = 0.005
	env.fog_aerial_perspective = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.2
	var we = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	city_root.add_child(we)
	we.owner = city_root
	print("  ✓ Sky")

func _setup_sun():
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform.origin = Vector3(-40, 60, -40)
	sun.transform = sun.transform.rotated(Vector3.UP, deg_to_rad(45))
	sun.transform = sun.transform.rotated(Vector3.RIGHT, deg_to_rad(-30))
	sun.light_color = Color(1.0, 0.95, 0.80, 1)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	sun.directional_shadow_size = 2048
	city_root.add_child(sun)
	sun.owner = city_root
	print("  ✓ Sun")
```

**Adaptation notes for current architecture:**
- v3 attached these to a `city_root` Node3D built at runtime. Current `main.tscn` already has `WorldEnvironment` + `Sun` as scene nodes with similar settings. **Compare values** — if v3's fog_density=0.005 + shadow_max_distance=80 look better than current main.tscn (fog_density=0.002, shadow_max_distance=300), port them.
- v3's `sun.transform.rotated(...)` calls apply yaw then pitch. Order matters.
- The current `main.tscn` has `directional_shadow_max_distance = 300.0` which is 3.7× v3's 80.0. v3's lower value is a deliberate Low-preset perf choice.

---

## 3. Placement rules comment block — paste at top of `chunk_builder.gd`

From the numbered "Fixes from v2" list + inline comments throughout the v3 prototype. Captured verbatim where possible; inline comments noted.

```gdscript
# ============================================================
# PLACEMENT RULES — extracted from retired city_builder.gd v3
# Captured 2026-09-12. These rules were tuned over user-screenshot
# iterations. Enforce them when refactoring placement in Phase B.
# ============================================================
#
# 1. STREET LIGHTS: place on grass strip center, NOT on road edge
#    (was clipping into road shoulder in v2).
#    Offset from road center = ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH/2.
#    Alternate sides every STREETLIGHT_SPACING_V3 (=25m). Was 20m in v2 —
#    25m is less cluttered.
#
# 2. UTILITY POLES: place FAR BEHIND buildings, not clipping into houses
#    (was inside front yards in v2).
#    Offset from road center = building_offset + LOT_DEPTH + UTILITY_POLE_OFFSET
#    (i.e. 9.5 + 16 + 2 = 27.5m behind road centerline).
#
# 3. FIRE HYDRANTS: place at intersection corners with extra clearance
#    (was inside sidewalk in v2, blocking pedestrians).
#    corner_off = ROAD_WIDTH/2 + SIDEWALK_WIDTH + 1.0
#
# 4. BUILDINGS: use LOT_WIDTH=20m × LOT_DEPTH=16m lots.
#    Was too tight in v2 — buildings clipped into each other.
#    Collider size = LOT_WIDTH * 0.75 × LOT_DEPTH * 0.75 (visual mesh is
#    smaller than collider so player can't clip through walls but can
#    approach closely).
#    Orientation:
#      South side of E-W road → rot=0° (faces -Z, toward road)
#      North side of E-W road → rot=180° (faces +Z, toward road)
#      East side of N-S road  → rot=-90° (faces -X, toward road)
#      West side of N-S road  → rot=90°  (faces +X, toward road)
#
# 5. TREES: place in grass strip CENTER (not on building side, not on road side).
#    tree_offset = ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH/2.
#    Add jitter: px ± 1.5m, pz ± 0.3m. Was clipping into buildings in v2.
#
# 6. FLOATING OBJECTS: ground all Y positions explicitly. v2 had subtle
#    Y offsets that made objects float by 0.05-0.1m. Use Y=0.0 for ground-
#    placed objects, Y=0.05 for sidewalks (raised 5cm), Y=0.03 for grass
#    strips (raised 3cm). Roads at Y=0.02.
#
# 7. GARAGE/HOUSE WALL: this was a MODEL issue, not placement. The
#    house_split_level.mog had no interior wall between garage and house.
#    Fixed in the .mog file, not in placement code. (Documented as a
#    reminder that placement rules can't fix all visual bugs.)
#
# 8. SPACING: minimum 2m clearance between ALL objects (buildings, props,
#    foliage). Use overlap check before placing.
#
# 9. STREET LIGHTS ALTERNATE SIDES: every 25m (was 20m in v2 — 25m is less
#    cluttered). Don't place 2 lights back-to-back on opposite sides at the
#    same X — stagger by 12.5m so one side lights at X=0, X=25, X=50 and
#    the other side lights at X=12.5, X=37.5, X=62.5. (Note: v3 did NOT
#    actually implement this staggering — it placed both sides at the same
#    X. Mark as TODO.)
#
# 10. FENCES ONLY ALONG FRONT PROPERTY LINE: don't run picket_fence through
#     the middle of lots. Place along the line between grass strip and
#     building setback, parallel to road.
#
# INLINE COMMENTS (from function bodies, captured verbatim):
#  - "South side — faces -Z (toward road). Rotation = 0°"
#  - "North side — faces +Z (toward road). Rotation = 180°"
#  - "East side — faces -X (toward road). Rotation = -90°"
#  - "West side — faces +X (toward road). Rotation = 90°"
#  - "Street lights: on grass strip center (NOT on road, NOT clipping buildings)"
#  - "Fire hydrants: at corner of intersection, with clearance"
#  - "Mailboxes: on sidewalk, offset from houses"
#  - "Trash cans: near houses, on sidewalk"
#  - "Utility poles: FAR behind buildings (not clipping into houses)"
#  - "Trees: center of grass strip (safe from both road and building)"
#  - "Hedges along front property lines (between grass strip and building)"
#  - "Dead trees scattered (away from roads)"
#  - "School bus: in pull-off area (far from buildings)"
#  - "Garden gnomes: in front yard, near building"
#  - "Planter boxes: on sidewalk near building entrance"
#  - "Bollards at intersection corners"
#
# Y-offset layer cake (from _setup_sidewalks in v3):
#  Y = 0.00  — ground plane
#  Y = 0.02  — road surface (2cm above ground)
#  Y = 0.03  — grass strip (3cm above ground)
#  Y = 0.05  — sidewalk (5cm above ground)
#  Y = 0.00  — buildings, props, foliage (sit on ground, sink into grass)
#
# ============================================================
```

---

## 4. Anything else worth keeping

Review for inclusion in current `chunk_builder.gd` / `city_builder.gd`:

- **`_is_occupied(pos, radius)`** — simple AABB overlap check using `Array[Rect2]` of occupied 2D regions (XZ). O(n) per query, but for ~100 buildings per chunk it's fine. Current `SpatialIndex` is more sophisticated (hash grid, O(1) amortized) — keep current, but the v3 pattern is a useful reference for "did this position already get something?" checks.

- **`_mark_occupied(pos, w, d)`** — paired with above. Stores `Rect2(x - w/2, z - d/2, w, d)` in the array. Useful pattern: track occupied as 2D rectangles, not points, when placing rectangular buildings.

- **`_place_building(asset_name, pos, rot_y, collider_size)`** — instantiates a GLB + adds a separate StaticBody3D collider sized to the building's footprint. **Current `chunk_builder.gd` does NOT add colliders per-building** — it relies on the GLB's own internal collision (if any). Port this pattern if buildings need player collision.

- **`_create_mesh(name, pos, size, color)`** — helper that creates a `BoxMesh` + `StandardMaterial3D` + `MeshInstance3D` in one call. Useful for procedural road/sidewalk/grass strips without needing GLB assets. Current `chunk_builder.gd` doesn't generate primitive geometry — it only places GLB instances. Keep in mind for road rendering (§11 TODO item: "Road rendering per chunk").

- **`_place_asset(category, asset_name, pos, rot_y)`** — generic GLB placer. Looks up path in ASSETS dict, instantiates, sets transform, adds to scene tree, increments `placed_count`. Current `chunk_builder.gd::_spawn()` is similar but uses `asset_cache` dict instead of a static ASSETS constant. Pattern equivalent.

- **`_setup_player()`** — builds player at runtime as `CharacterBody3D` + `Camera3D` + `CollisionShape3D` + embeds the movement script as `GDScript.new()`. **Current architecture uses `main.tscn` for the player node** (declared in scene file, not built in code). v3's approach is more flexible but less inspectable. Don't port — but the embedded GDScript source (the `script.source_code = """..."""` pattern) is useful if you ever need to dynamically generate scripts at runtime.

- **`PackedScene.pack(city_root)` + `ResourceSaver.save()`** — saves the entire built scene as a `.tscn` file. This is the same pattern `city_builder.gd::_build_one_chunk()` uses (line 109-112 of current city_builder.gd). Equivalent.

- **Manual road grid generation in `_setup_roads()`** — v3 explicitly creates 6 road segments at fixed positions (z=[0, 60, -60] × 3 axes). Current `road_network.gd::generate()` is procedural. **The v3 approach gives precise control over road layout** — useful if we ever want hand-authored road networks for POIs.

- **Hedges along front property lines** (rule #10) — v3 places `hedge` GLB at `tree_offset + 1.5m` (just inside the building side of the grass strip). Current `chunk_builder.gd` doesn't have a "front property line" concept — it places foliage randomly in the chunk. **Port this pattern** if hedges should line suburban lots.

- **Playground cluster placement in `_place_playground()`** — places 5 props (slide, swing_set, picnic_table, 2 benches) + 8 oak trees in a circle around a fixed park position. **Current `chunk_builder.gd` places props randomly** — no clustering. Port this pattern for POI-style "park" placement in Phase F.

- **School bus placement** — single instance in a "pull-off area" at fixed coordinates. Useful pattern for unique vehicle POIs (not procedural).

- **Occupied-region tracking via Rect2 array** — alternative to the current SpatialIndex hash grid. Simpler, slower (O(n) vs O(1)), but easier to debug (you can print the array and see all occupied rectangles). Could be a debug-only fallback for `SpatialIndex`.

---

**End of extraction.**
