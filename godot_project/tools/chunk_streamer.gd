# ChunkStreamer v8 — data-driven city generation with visible roads,
# gap filler, interior greenery, commercial on corners, parks every N blocks,
# LANDMARK placement (hero assets), ROAD KIND filtering (no buildings on
# highways/bridges), ANTI-CLUSTERING (no two gas stations / stadiums / etc.
# within MIN_DIST), and interactive DOORS/WINDOWS via shell GLBs.
#
# v8 changes (2026-09-13):
#   - profile.landmarks now placed: ONE per biome-chunk, at chunk center,
#     cross-chunk dedup so e.g. only one stadium per downtown district.
#   - Segments tagged kind="highway" or kind="bridge" are skipped for building
#     placement (still rendered as visible road surfaces).
#   - Anti-clustering: "special" assets (gas_station, hospital, stadium, ...)
#     enforce SPECIAL_MIN_DIST_M between instances; landmark assets enforce
#     LANDMARK_MIN_DIST_M. Stops "two gas stations within 500m" duplicates.
#   - Building spawn now checks for a shell variant (`<name>_shell.glb`) and
#     a component manifest (`<name>_components.json`). If present, spawns the
#     shell GLB + interactive door/window children. Unlocks the existing
#     6 shell GLBs (bungalow, cottage, ...) and the new broadcast_tower_shell.
#
# Loads map data from map_data.json (biome grid, roads, POIs, services).
# Builds visible road meshes, places buildings along road segments,
# fills gaps, adds trees inside blocks, places parks, varies scale/rotation.
#
# All placement at Y=0 (flat ground). Terrain3D is disabled for now.

extends Node3D

const CityConfig = preload("res://tools/city_config.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const RoadNetwork = preload("res://tools/road_network.gd")
const PlanGrid = preload("res://tools/plan_grid.gd")
const TerrainHeight = preload("res://tools/terrain_height.gd")
const RiverNetwork = preload("res://tools/river_network.gd")
const DistrictStamper = preload("res://tools/district_stamper.gd")
const AnchorPoints = preload("res://tools/anchor_points.gd")

var player: Node3D
var stream_radius: int = 2
var spatial: SpatialIndex
var roads: RoadNetwork
var manifest: Dictionary = {}
var asset_cache: Dictionary = {}
var rng: RandomNumberGenerator
var plan_grid: PlanGrid
var terrain: TerrainHeight
var river: RiverNetwork
var _stamper: DistrictStamper  # Phase A.7: hand-authored district templates
var _loaded: Dictionary = {}
var _build_queue: Array = []
var _builds_this_frame: int = 0
var _map_data: Dictionary = {}
var _pois_cache: Array = []

# v8: landmark placement tracker.
# Key: landmark asset name (e.g. "stadium").
# Value: Array[Vector3] of every placed instance position (world space).
# Used to keep landmarks spaced apart across chunks.
var _landmark_positions: Dictionary = {}

# v8: anti-clustering tracker.
# Key: building asset name (e.g. "gas_station").
# Value: Array[Vector3] of every placed instance position (world space).
# Used by _is_too_close_to_same_type() to enforce min-distance rules.
var _asset_positions: Dictionary = {}

# v8: component manifest cache. Key: building_name. Value: parsed Dictionary
# (or null if no manifest exists).
var _component_manifest_cache: Dictionary = {}

# v8: shell GLB cache. Key: building_name. Value: PackedScene (or null if no
# shell variant exists for this building).
var _shell_scene_cache: Dictionary = {}

# v8: landmark-asset lookup set. Populated lazily on first call to
# _is_landmark_asset(). Key: asset name. Value: true.
var _landmark_asset_set: Dictionary = {}

# Colors for road/sidewalk/grass meshes
const C_ROAD := Color(0.12, 0.12, 0.14, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_PARK := Color(0.18, 0.38, 0.14, 1)
const C_WATER := Color(0.15, 0.30, 0.45, 0.7)

# Placement constants
const LOT_W := 20.0
const LOT_D := 16.0
const BUILDING_OFFSET := 9.5  # road/2 + sidewalk + grass + setback

# v8: Anti-clustering distances (meters). Two instances of the same asset
# must be at least this far apart. Tuned per asset category.
# - LANDMARK: hero assets like stadium, government_palace, fort_sarran —
#   these should appear ONCE per district, so 800m apart (≈ 2 chunks).
# - SPECIAL: high-value civic/commercial buildings like gas_station, hospital,
#   police_station, school — 500m apart (user-specified).
# - COMMON: everything else (houses, etc.) — 0m (no anti-cluster constraint,
#   the regular spatial.is_free overlap check is enough).
const LANDMARK_MIN_DIST_M := 800.0
const SPECIAL_MIN_DIST_M := 500.0

# v8: Asset names that get the SPECIAL_MIN_DIST_M anti-cluster rule.
# Anything in a biome's `landmarks` array automatically uses LANDMARK_MIN_DIST_M.
const SPECIAL_ANTICLUSTER := [
    "gas_station", "hospital", "police_station", "school_elementary",
    "church_small", "bank_branch", "store_supermarket", "grocery_store",
    "railway_station", "parking_garage", "highrise_office",
    "apartment_tower_high", "broadcast_tower", "helipad",
    "military_checkpoint", "bunker_entrance", "fort_sarran",
    "government_palace", "old_royal_palace", "stadium",
    "lighthouse", "windmill", "grain_silo",
]

# v8: Road kinds that are NOT eligible for building placement.
# "street" is the default — buildings line it. "highway" and "bridge" get
# rendered as road surfaces but skipped during lot assignment.
const NON_LOT_ROAD_KINDS := ["highway", "bridge"]

# v8.1: Y-offset layer cake (see chunk_builder.gd placement-rules header).
# Phase A.6: _create_plane_mesh_rotated takes Y via pos.y (PlaneMesh.size
# is Vector2 so Y must be in position, not size). Layer cake prevents
# z-fighting between road/lane/grass/sidewalk surfaces.
const Y_GROUND := 0.00
const Y_ROAD := 0.02
const Y_LANE := 0.025    # lane line sits 5mm above road surface
const Y_GRASS := 0.03
const Y_SIDEWALK := 0.05
const Y_PARK := 0.04

# v8.1: Spacing rule #7 — minimum 2m clearance between ALL objects.
# Was inconsistent: street lights used 0.5m (below minimum). Now everything
# uses at least MIN_CLEARANCE_M.
const MIN_CLEARANCE_M := 2.0

# v8.2 Phase A.6: HIGHWAY CLEARANCE — limited-access roads.
# Highways (z=1500, x=1500 per map_data.json) are limited-access: no buildings
# spawn within HIGHWAY_CLEARANCE_M of the highway centerline. This matches
# real-city zoning — American-style highways have a clear shoulder + sound
# wall, not storefronts. PZ treats main roads similarly (commercial corridors
# are along arterials, not highways).
#
# Value 15m is conservative — wider than the building offset (9.5m) so even
# corner lots adjacent to a highway get skipped. Adjust to 8m if you want
# buildings right up to the highway shoulder.
const HIGHWAY_CLEARANCE_M := 15.0

# v8.2 Phase A.8: FPS OPTIMIZATION — small props don't cast shadows.
# Shadow rendering is expensive (DirectionalLight3D shadow pass re-renders
# every shadow-casting mesh from the light's POV). For tiny props like
# trash cans, mailboxes, bollards, parking meters — shadows are invisible
# at gameplay distance but still cost a draw call + shadow pass.
# Disabling shadows on these saves ~30% of shadow rendering cost.
# Buildings + trees + zombies KEEP shadows (they're tall enough to matter).
const NO_SHADOW_PROPS := [
        "trash_can", "mailbox", "planter_box", "bollard", "parking_meter",
        "shopping_cart", "bird_house", "traffic_cone", "construction_barrier",
        "sandbag", "barbed_wire_fence", "garden_gnome", "garden_hose_reel",
        "traffic_camera", "park_sign", "water_fountain", "swing_set",
        "seesaw", "playground_slide", "basketball_hoop", "traffic_light",
]

# v8.2 Phase A.8: ZOMBIE COUNT REDUCTION — was 10-15 per chunk, now 5-8.
# 250+ zombies in visible area was the biggest FPS killer (each zombie =
# 4128 tris × 17 meshes = 17 draw calls per zombie × 250 = 4250 draw calls
# just for zombies). Reducing to 5 per chunk cuts zombie draws by 50%+.
# Biome profiles are updated at runtime to scale zombie count.
const ZOMBIE_SCALE_FACTOR := 0.5  # multiply biome profile zombies by this

# v8.2 Phase A.8: ZONING RULES — bias building picks by zone type.
# Each biome has a zoning type that influences which buildings spawn:
#   - residential: houses, small apartment buildings
#   - commercial: storefronts, diners, gas stations, pharmacies
#   - industrial: warehouses, factories, storage tanks
#   - mixed: any of the above (downtown edge, transition zones)
# At intersections, the commercial probability is boosted (PZ-style:
# corner lots get storefronts, mid-block gets houses).
# On arterial roads (wider roads), commercial probability is also boosted.
const ZONE_COMMERCIAL_PROB := 0.7  # at intersections / arterials
const ZONE_RESIDENTIAL_PROB := 0.85  # mid-block on side streets

# v8.2 Phase A.8: SETBACK VARIATION — distance from road to building face.
# Was constant 1.5m (BUILDING_SETBACK) for all buildings. Now varies by
# zoning type:
#   - commercial: 0m setback (storefront flush with sidewalk — downtown feel)
#   - residential: 4m setback (porch + small front yard — suburban feel)
#   - industrial: 2m setback (loading dock access)
# This creates visual variety along a street — storefronts right at the
# sidewalk, then a house set back with a yard, then a warehouse with a
# dock. Matches real-city zoning patterns.
const SETBACK_COMMERCIAL := 0.0
const SETBACK_RESIDENTIAL := 4.0
const SETBACK_INDUSTRIAL := 2.0
const BUILDING_OFFSET_BASE := 9.5  # road/2 + sidewalk + grass strip (was constant BUILDING_OFFSET)

# v8.1: Utility pole placement (rule #2).
# Poles go FAR BEHIND buildings — offset from road centerline is:
#   BUILDING_OFFSET + LOT_DEPTH + UTILITY_POLE_OFFSET
#   = 9.5 + 16 + 2 = 27.5m
# Spacing along the road: 35m.
const UTILITY_POLE_OFFSET_M := BUILDING_OFFSET + LOT_D + CityConfig.UTILITY_POLE_OFFSET
const UTILITY_POLE_SPACING_M := CityConfig.UTILITY_POLE_SPACING

# v8.1: Fire hydrant placement (rule #3).
# At intersection corners — offset from road centerline is:
#   ROAD_WIDTH/2 + SIDEWALK_WIDTH + 1.0 = 4 + 1.5 + 1 = 6.5m
const FIRE_HYDRANT_OFFSET_M := CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH + 1.0

# v8.2: DISTRICT NOISE (gap #1) — Valheim-style biome blending.
# Chunks sample a low-frequency value noise at their position. If the noise
# value exceeds this threshold (0..1), the chunk borrows a neighbor cell's
# biome. Higher threshold = less borrowing = sharper grid edges. Lower
# threshold = more borrowing = more chaotic. 0.62 means roughly 38% of
# chunks (in non-excluded biomes) will borrow — visible noise but not chaos.
const DISTRICT_NOISE_THRESHOLD := 0.62

# Frequency of the value noise. Lower = slower variation (borrowing happens
# in clusters rather than randomly scattered). 0.5 = 1 sample per 2 chunks,
# so borrowing tends to happen in 2-chunk-wide patches along grid borders.
const DISTRICT_NOISE_FREQ := 0.5

# Phase B.1.5: terrain height helper. Returns the terrain Y at (x, z).
# Used by all placement code to put buildings/props/foliage on terrain
# instead of flat Y=0. Road flattening keeps road-adjacent placements
# at Y≈0 (same as before). Block interiors get full biome elevation.
func _terrain_y(x: float, z: float) -> float:
        if terrain == null:
                return 0.0
        return terrain.height_at(x, z)

func _terrain_pos(flat_pos: Vector3) -> Vector3:
        return Vector3(flat_pos.x, _terrain_y(flat_pos.x, flat_pos.z), flat_pos.z)

# Phase B.3: Roll the height class dice for a building slot.
# Uses the biome's height_dist (SHORT/MID/TALL probabilities).
# Returns "SHORT", "MID", or "TALL".
func _roll_height_class(profile: Dictionary, crng: RandomNumberGenerator) -> String:
        var dist: Dictionary = profile.get("height_dist", {"SHORT": 0.5, "MID": 0.4, "TALL": 0.1})
        var roll: float = crng.randf()
        var cumulative: float = 0.0
        for hc in ["SHORT", "MID", "TALL"]:
                cumulative += float(dist.get(hc, 0.0))
                if roll < cumulative:
                        return hc
        return "MID"  # fallback if all probabilities are 0

# Phase B.3: Filter a building name list by height class.
# Returns only buildings whose manifest entry has the matching height_class.
# Falls back to the full list if no buildings match (prevents empty picks).
func _filter_by_height_class(asset_names: Array, height_class: String) -> Array:
        var filtered: Array = []
        for name in asset_names:
                var entry: Dictionary = manifest.get(name, {})
                if entry.get("height_class", "") == height_class:
                        filtered.append(name)
        return filtered

func _ready() -> void:
        await get_tree().process_frame
        var root := get_tree().current_scene
        player = root.get_node_or_null("Player")
        if player == null:
                for child in root.get_children():
                        if child is CharacterBody3D:
                                player = child
                                break
        if player == null:
                push_error("[ChunkStreamer] No player found!")
                return

        # Load manifest
        var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
        if f:
                manifest = JSON.parse_string(f.get_as_text())
        print("[ChunkStreamer] manifest: %d assets" % manifest.size())

        # Load map data
        _load_map_data()

        spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
        roads = RoadNetwork.new()
        rng = RandomNumberGenerator.new()
        rng.seed = 1337

        # Load roads from map_data
        _load_roads_from_data()
        roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)

        plan_grid = PlanGrid.new()
        plan_grid.build(roads, 1337)

        river = RiverNetwork.new()
        terrain = TerrainHeight.new(1337, river)
        _stamper = DistrictStamper.new()

        print("[ChunkStreamer] ready, player at %s" % player.global_position)

func _load_map_data():
        var f := FileAccess.open("res://data/map_data.json", FileAccess.READ)
        if f:
                _map_data = JSON.parse_string(f.get_as_text())
                print("[ChunkStreamer] map_data loaded: %d roads, %d POIs" % [
                        _map_data.get("roads", []).size(),
                        _map_data.get("pois", []).size()
                ])
                _pois_cache = _map_data.get("pois", [])

func _load_roads_from_data():
        roads.segments.clear()
        for road in _map_data.get("roads", []):
                var start_arr: Array = road["start"]
                var end_arr: Array = road["end"]
                roads._add_segment(
                        Vector3(start_arr[0], 0, start_arr[2]),
                        Vector3(end_arr[0], 0, end_arr[2]),
                        float(road.get("width", 8.0)),
                        road.get("kind", "street"),
                        road.get("name", "")
                )
        print("[ChunkStreamer] roads loaded: %d segments" % roads.segments.size())

func _process(_delta: float) -> void:
        if player == null or manifest.is_empty():
                return
        var cx: int = int(floor(player.global_position.x / CityConfig.CHUNK_SIZE_M))
        var cy: int = int(floor(player.global_position.z / CityConfig.CHUNK_SIZE_M))
        _builds_this_frame = 0
        _refresh(cx, cy)
        if not _build_queue.is_empty() and _builds_this_frame == 0:
                var next_key: Vector2i = _build_queue.pop_front()
                _build_chunk(next_key)
                _builds_this_frame += 1
        # v8.2 Phase A.11: auto-dump chunk states after 5s for AI analysis
        _maybe_auto_dump(_delta)

func _refresh(cx: int, cy: int) -> void:
        var unload_r: int = stream_radius + CityConfig.STREAM_UNLOAD_BUFFER
        var wanted: Dictionary = {}
        for dy in range(-stream_radius, stream_radius + 1):
                for dx in range(-stream_radius, stream_radius + 1):
                        var key := Vector2i(cx + dx, cy + dy)
                        wanted[key] = true
                        if not _loaded.has(key) and not _build_queue.has(key):
                                _build_queue.append(key)
        var to_remove: Array = []
        for key in _loaded:
                if abs(key.x - cx) > unload_r or abs(key.y - cy) > unload_r:
                        to_remove.append(key)
        for key in to_remove:
                _unload_chunk(key)

func _build_chunk(key: Vector2i) -> void:
        if key.x < 0 or key.y < 0 or key.x >= CityConfig.CHUNKS_COLS or key.y >= CityConfig.CHUNKS_ROWS:
                return
        var col: int = clamp(int(key.x * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
        var row: int = clamp(int(key.y * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
        var base_biome: int = CityConfig.grid_layout()[row][col]
        # v8.2: DISTRICT NOISE (gap #1) — Valheim-style soft biome edges.
        # Sample a low-frequency value noise at the chunk's normalized position;
        # if noise exceeds a threshold, "borrow" a neighboring cell's biome.
        # This breaks the hard 8×6 grid edges so transitions between biomes
        # look organic instead of checker-boarded.
        #
        # Excluded from borrowing:
        #   - WATER, EMPTY (water bodies need stable banks/geometry)
        #   - COASTAL_BEACH (it's a thin 1-column strip; borrowing would erase it)
        #   - WETLANDS (low-elevation emergent, v1 placement should stay explicit)
        #
        # v8.2 Phase A.4: removed RIVER exclusion — RIVER is no longer a biome.
        #
        # The borrow direction is chosen from the actual 4 grid neighbors
        # (N/S/E/W), so borrowed chunks always sit adjacent to their parent
        # biome cell — no orphans.
        var biome: int = base_biome
        # v8.2 Phase A.4: removed RIVER exclusion — RIVER is no longer a biome.
        # WETLANDS is excluded too for now (low-elevation emergent, will be
        # driven by terrain height in a later phase — for v1 we want it to
        # appear only where explicitly placed, not borrowed from).
        if base_biome != CityConfig.Biome.WATER \
                and base_biome != CityConfig.Biome.EMPTY \
                and base_biome != CityConfig.Biome.COASTAL_BEACH \
                and base_biome != CityConfig.Biome.WETLANDS:
                var nval: float = _biome_noise(key)
                if nval > DISTRICT_NOISE_THRESHOLD:
                        var borrowed := _borrow_neighbor_biome(row, col, key)
                        if borrowed >= 0:
                                biome = borrowed
        var profile: Dictionary = CityConfig.biomes().get(biome, {})
        if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
                return

        var origin: Vector3 = Vector3(key.x * CityConfig.CHUNK_SIZE_M, 0, key.y * CityConfig.CHUNK_SIZE_M)
        var chunk_root := Node3D.new()
        chunk_root.name = "Chunk_%d_%d" % [key.x, key.y]
        var crng := RandomNumberGenerator.new()
        crng.seed = hash(key) ^ 1337

        var b_count := 0
        var p_count := 0
        var f_count := 0
        var s_count := 0
        var l_count := 0

        # === VISIBLE ROADS ===
        _build_visible_roads(chunk_root, origin, CityConfig.CHUNK_SIZE_M)

        # === POI PLACEMENT ===
        var poi_exclusions: Array = []
        var pois := _get_pois_for_chunk(origin, CityConfig.CHUNK_SIZE_M)
        for poi in pois:
                var poi_asset: String = poi.get("type", "")
                var poi_scene: PackedScene = _get_asset(poi_asset)
                if poi_scene == null:
                        continue
                var poi_pos := Vector3(float(poi.pos[0]), 0, float(poi.pos[2]))
                var poi_inst: Node3D = poi_scene.instantiate()
                poi_inst.position = _terrain_pos(poi_pos)
                poi_inst.name = "POI_%s" % poi.get("id", poi_asset)
                chunk_root.add_child(poi_inst)
                spatial.insert(poi_pos, float(poi.get("radius", 30)))
                poi_exclusions.append({"center": poi_pos, "radius": float(poi.get("radius", 30))})
                l_count += 1

        # === v8.1: LANDMARK PLACEMENT (BEFORE buildings) ===
        # Landmarks must go first so they register exclusions (via spatial.insert
        # AND poi_exclusions) that block procedural buildings from spawning on
        # top of them. If landmarks go last, they either overlap existing
        # buildings or fail the is_free() check and silently get skipped.
        var lm_count := _place_landmark(chunk_root, profile, origin, key, crng, poi_exclusions)
        l_count += lm_count

        # === Phase A.7: HAND-AUTHORED DISTRICT TEMPLATE STAMPING ===
        # If this biome has a template defined (see data/district_templates.gd
        # BIOME_TEMPLATES map), stamp it at the chunk's anchor (cell center).
        # The template includes buildings + foliage + props at hand-authored
        # positions with per-run variant pick + rotation jitter.
        # After stamping, mark the anchor's footprint (75m radius) as occupied
        # in the spatial index so procedural placement skips that area.
        # Per docs/district_templates.md: coverage is ~30% (major biomes only).
        var template_name := _stamper.pick_template_for_biome(biome, crng)
        var template_placed := 0
        if template_name != "":
                var anchor_pos := origin + Vector3(
                        CityConfig.CHUNK_SIZE_M * 0.5, 0,
                        CityConfig.CHUNK_SIZE_M * 0.5
                )
                var template_rot := crng.randf_range(0, TAU)
                template_placed = _stamper.stamp_template(
                        template_name, anchor_pos, template_rot, chunk_root, crng, self
                )
                if template_placed > 0:
                        # Mark the template's footprint so procedural placement
                        # skips the area. Template is 150×150m → 75m radius.
                        spatial.insert(anchor_pos, 75.0)
                        poi_exclusions.append({"center": anchor_pos, "radius": 75.0})
                        b_count += template_placed
                        print("[ChunkStreamer] template '%s' stamped at %s (chunk %d_%d): %d nodes" % [
                                template_name, anchor_pos, key.x, key.y, template_placed
                        ])

        # === BUILDINGS ALONG ROAD SEGMENTS ===
        var buildings: Array = profile.get("buildings", [])
        var commercial_buildings: Array = profile.get("commercial_buildings", ["corner_store", "diner", "gas_station", "corner_store"])
        # v8.2 Phase A.8: increased fill from 0.5 base to higher density.
        # Was int(fill * 40) = 20 buildings per chunk at 0.5 fill. Now
        # int(fill * 60) = 30 buildings per chunk — 50% more buildings.
        # Addresses "map mostly empty" feedback. Plus reduced empty-lot
        # probability (was 1-fill, now (1-fill)*0.5 — half as many empty lots).
        var fill: float = profile.get("fill", 0.5)
        var building_radius: float = max(LOT_W, LOT_D) * 0.4

        # v8.2 Phase A.9: DISTRICT HALO — find landmarks near this chunk
        # and collect their halo buildings. These get boosted spawn probability.
        # _halo_buildings is a Dictionary[asset_name → boost_multiplier].
        var _halo_buildings: Dictionary = _collect_halo_buildings(origin, CityConfig.CHUNK_SIZE_M)

        # Get road segments that pass through this chunk
        var chunk_roads: Array = _get_roads_in_chunk(origin, CityConfig.CHUNK_SIZE_M)
        var placed := 0
        var target: int = int(fill * 80)  # Phase B.2: was 60, now 80  # Phase A.8: was 40, now 60

        for seg in chunk_roads:
                if placed >= target:
                        break
                # v8: ROAD KIND FILTER — skip highways & bridges (still rendered,
                # but no buildings spawn on them).
                var seg_kind: String = seg.get("kind", "street")
                if NON_LOT_ROAD_KINDS.has(seg_kind):
                        continue
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                var length: float = a.distance_to(b)
                if length < 1.0:
                        continue
                var dir: Vector3 = (b - a).normalized()
                var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
                var road_half_w: float = float(seg.get("width", 8.0)) * 0.5

                # Walk along segment at LOT_W intervals
                var d: float = LOT_W * 0.5
                while d < length and placed < target:
                        var t: float = d / length
                        var base_pos: Vector3 = a.lerp(b, t)

                        # Check if near intersection (within 15m of a crossing road)
                        var near_intersection := _is_near_intersection(base_pos, 15.0)

                        # v8.2 Phase A.8: ZONING — determine zone for this lot.
                        # At intersections + on wide roads → commercial zone.
                        # Mid-block on side streets → residential zone.
                        # Industrial biome → always industrial zone.
                        var is_arterial: bool = float(seg.get("width", 8.0)) >= 10.0
                        var zone_type: String = "residential"
                        if biome == CityConfig.Biome.INDUSTRIAL:
                                zone_type = "industrial"
                        elif biome == CityConfig.Biome.DOWNTOWN:
                                zone_type = "mixed"
                        elif near_intersection or is_arterial:
                                zone_type = "commercial"
                        # Compute setback based on zone
                        var setback: float = SETBACK_RESIDENTIAL
                        match zone_type:
                                "commercial":
                                        setback = SETBACK_COMMERCIAL
                                "industrial":
                                        setback = SETBACK_INDUSTRIAL
                                "residential":
                                        setback = SETBACK_RESIDENTIAL
                                _:
                                        setback = SETBACK_RESIDENTIAL
                        # Building offset = road/2 + sidewalk + grass strip + setback
                        var building_offset_dyn: float = BUILDING_OFFSET_BASE + setback

                        for side in [-1, 1]:
                                if placed >= target:
                                        break
                                var lot_pos: Vector3 = base_pos + perp * float(side) * building_offset_dyn
                                # Check bounds
                                if lot_pos.x < origin.x or lot_pos.x >= origin.x + CityConfig.CHUNK_SIZE_M:
                                        continue
                                if lot_pos.z < origin.z or lot_pos.z >= origin.z + CityConfig.CHUNK_SIZE_M:
                                        continue
                                if not spatial.is_free(lot_pos, building_radius) or spatial.is_on_road(lot_pos):
                                        continue
                                if _is_in_poi_exclusion(lot_pos, poi_exclusions):
                                        continue
                                # v8.2 Phase A.6: HIGHWAY CLEARANCE — skip if within
                                # HIGHWAY_CLEARANCE_M of any highway-segment centerline.
                                # Prevents buildings spawning on the highway shoulder.
                                if _is_near_highway(lot_pos):
                                        continue
                                # v8.2 Phase A.8: reduced empty-lot probability.
                                # Was: crng.randf() > fill → skip (empty lot).
                                # Now: crng.randf() > fill OR crng.randf() < 0.3 → skip.
                                # Effectively halves the number of empty lots. The gap
                                # filler still runs for some empty space (parking lots,
                                # backyards) but less of the chunk is bare.
                                if crng.randf() > fill:
                                        # 50% chance to still place a smaller prop here
                                        # (backyard shed, planter, etc.) instead of leaving
                                        # the lot completely bare.
                                        if crng.randf() < 0.7:  # Phase B.2: was 0.5, now 0.7 (more backyard fills)
                                                _place_backyard_fill(lot_pos, perp, side, chunk_root, crng, profile)
                                        continue  # Skip the main building placement

                                # v8.2 Phase A.8: pick building based on zone type.
                                # Was: 50% commercial at intersections, else residential.
                                # Now: zone_type determines pick probability.
                                #   - commercial zone: 70% commercial, 30% residential
                                #   - residential zone: 85% residential, 15% commercial (corner store)
                                #   - industrial zone: 100% industrial (from biome.buildings)
                                #   - mixed zone: 50/50 commercial/residential
                                #
                                # v8.2 Phase A.9: DISTRICT HALO — if a halo building
                                # is in the pick list, boost its probability by the halo
                                # multiplier (e.g. stadium nearby → 2x chance of
                                # parking_garage, bank_branch, etc.).
                                #
                                # Phase B.3: HEIGHT CLASS — roll the height dice for this
                                # lot. Filters the pick pool to SHORT/MID/TALL buildings
                                # only. Makes districts read as designed (Downtown = TALL,
                                # Suburbia = SHORT). Falls back to full pool if no buildings
                                # of the rolled class exist.
                                var height_class: String = _roll_height_class(profile, crng)
                                var bname: String
                                var commercial_prob: float = 0.0
                                match zone_type:
                                        "commercial":
                                                commercial_prob = ZONE_COMMERCIAL_PROB
                                        "residential":
                                                commercial_prob = 1.0 - ZONE_RESIDENTIAL_PROB
                                        "industrial":
                                                commercial_prob = 0.0
                                        "mixed":
                                                commercial_prob = 0.5
                                # Phase A.9: check if any halo building is in the pool.
                                # If so, weighted-pick favoring halo buildings.
                                var has_halo: bool = false
                                for hb in _halo_buildings.keys():
                                        if commercial_buildings.has(hb) or buildings.has(hb):
                                                has_halo = true
                                                break
                                if has_halo and crng.randf() < 0.4:
                                        var weighted_pool: Array = []
                                        for hb in _halo_buildings.keys():
                                                if commercial_buildings.has(hb) or buildings.has(hb):
                                                        var mult: float = float(_halo_buildings[hb])
                                                        for _w in range(int(mult * 10)):
                                                                weighted_pool.append(hb)
                                        if not weighted_pool.is_empty():
                                                bname = weighted_pool[crng.randi() % weighted_pool.size()]
                                        elif crng.randf() < commercial_prob and not commercial_buildings.is_empty():
                                                var c_pool := _filter_by_height_class(commercial_buildings, height_class)
                                                var pick_pool: Array = c_pool if not c_pool.is_empty() else commercial_buildings
                                                bname = pick_pool[crng.randi() % pick_pool.size()]
                                        else:
                                                var r_pool := _filter_by_height_class(buildings, height_class)
                                                var pick_pool2: Array = r_pool if not r_pool.is_empty() else buildings
                                                bname = pick_pool2[crng.randi() % pick_pool2.size()]
                                elif crng.randf() < commercial_prob and not commercial_buildings.is_empty():
                                        var c_pool := _filter_by_height_class(commercial_buildings, height_class)
                                        var pick_pool: Array = c_pool if not c_pool.is_empty() else commercial_buildings
                                        bname = pick_pool[crng.randi() % pick_pool.size()]
                                else:
                                        var r_pool := _filter_by_height_class(buildings, height_class)
                                        var pick_pool: Array = r_pool if not r_pool.is_empty() else buildings
                                        bname = pick_pool[crng.randi() % pick_pool.size()]

                                # v8: ANTI-CLUSTERING — skip if too close to another
                                # instance of the same asset (e.g. two gas stations within 500m).
                                if not _anti_cluster_ok(bname, lot_pos):
                                        continue

                                var inst: Node3D = _spawn_building_with_components(bname, lot_pos, perp, side, crng, chunk_root)
                                if inst == null:
                                        continue
                                spatial.insert(lot_pos, building_radius)
                                _register_asset_position(bname, lot_pos)
                                placed += 1
                                b_count += 1

                        d += LOT_W

        # === v8.1: UTILITY POLES (rule #2 — behind buildings) ===
        # Poles run along the back of lots (27.5m from road centerline),
        # spaced 35m apart. Alternates sides per pole so both sides of the
        # street get service. Skips if utility_pole not in manifest.
        s_count += _place_utility_poles(chunk_root, chunk_roads, crng)

        # === v8.1: FIRE HYDRANTS (rule #3 — at intersection corners) ===
        # Hydrants sit at the corner of every road intersection, 6.5m from
        # the nearest road centerline. Skips if fire_hydrant not in manifest.
        s_count += _place_fire_hydrants(chunk_root, chunk_roads, crng)

        # === GAP FILLER — fill empty spaces with small props ===
        # v8.2 Phase A.8: increased gap_count from fill*15 to fill*25.
        # Addresses "map mostly empty" — more props scattered in empty lots.
        var props: Array = profile.get("props", [])
        var gap_fillers: Array = ["shed", "garage_detached", "picket_fence", "planter_box", "garden_gnome", "trash_can", "mailbox"]
        # Filter to assets that exist in manifest
        var valid_fillers: Array = []
        for gf in gap_fillers:
                if manifest.has(gf):
                        valid_fillers.append(gf)

        var gap_count := int(fill * 35)  # Phase B.2: was 25, now 35  # Phase A.8: was 15, now 25
        for i in range(gap_count):
                var pos := Vector3(
                        origin.x + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 15.0),
                        0,
                        origin.z + crng.randf_range(15.0, CityConfig.CHUNK_SIZE_M - 15.0)
                )
                if not spatial.is_free(pos, 2.0) or spatial.is_on_road(pos):
                        continue
                if _is_in_poi_exclusion(pos, poi_exclusions):
                        continue
                # Place a gap filler
                if not valid_fillers.is_empty():
                        var fname: String = valid_fillers[crng.randi() % valid_fillers.size()]
                        var scene: PackedScene = _get_asset(fname)
                        if scene:
                                var inst: Node3D = scene.instantiate()
                                inst.position = _terrain_pos(pos)
                                inst.rotation.y = crng.randf_range(0, TAU)
                                inst.name = "%s_%d" % [fname, crng.randi() % 100000]
                                chunk_root.add_child(inst)
                                # v8.2 Phase A.8: disable shadows on small props (FPS optimization)
                                _disable_shadows_if_small_prop(inst, fname)
                                spatial.insert(pos, 2.0)
                                p_count += 1

        # === INTERIOR GREENERY — trees/bushes inside blocks ===
        # v8.2 Phase A.8: increased green_count from fill*25 to fill*40.
        # Addresses "map mostly empty" + "no land foliage" feedback.
        var foliage: Array = profile.get("foliage", [])
        if not foliage.is_empty():
                var green_count := int(fill * 50)  # Phase B.2: was 40, now 50  # Phase A.8: was 25, now 40
                for i in range(green_count):
                        var pos := Vector3(
                                origin.x + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0),
                                0,
                                origin.z + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0)
                        )
                        if not spatial.is_free(pos, 3.0) or spatial.is_on_road(pos):
                                continue
                        if _is_in_poi_exclusion(pos, poi_exclusions):
                                continue
                        var fname: String = foliage[crng.randi() % foliage.size()]
                        var scene: PackedScene = _get_asset(fname)
                        if scene == null:
                                continue
                        var inst: Node3D = scene.instantiate()
                        inst.position = _terrain_pos(pos)
                        inst.rotation.y = crng.randf_range(0, TAU)
                        # Scale variation for trees
                        var tree_scale: float = crng.randf_range(0.8, 1.3)
                        inst.scale = Vector3(tree_scale, tree_scale, tree_scale)
                        inst.name = "%s_%d" % [fname, crng.randi() % 100000]
                        chunk_root.add_child(inst)
                        # v8.2 Phase A.8: disable shadows on small foliage (bush, hedge, flower_patch, weeds)
                        # Trees keep shadows (tall + visible). Small foliage = no shadow.
                        _disable_shadows_if_small_foliage(inst, fname)
                        spatial.insert(pos, 3.0)
                        f_count += 1

        # === PARKS — every 4th chunk, convert center to a park ===
        # v8: skip if a landmark was placed at the chunk center this pass
        # (otherwise the park would overwrite the landmark).
        # v8.2 Phase A.4: removed RIVER check (RIVER is no longer a biome —
        # it's a polyline overlay. The biome underneath the river is whatever
        # the district grid says. A "park" could in principle spawn under the
        # river's X but the spatial.is_on_road check + river carve in
        # terrain_height handles non-buildable terrain at runtime).
        if (key.x + key.y) % 4 == 0 and biome != CityConfig.Biome.WATER and biome != CityConfig.Biome.WETLANDS and lm_count == 0:
                var park_center := origin + Vector3(CityConfig.CHUNK_SIZE_M * 0.5, 0, CityConfig.CHUNK_SIZE_M * 0.5)
                _place_park(chunk_root, park_center, crng)

        # === Phase B.3: BLOCK INTERIOR FILL ===
        # DeepSeek: "Block interiors are hollow. Even with good roads, a 100m
        # block interior has nothing in it. Real cities fill that with garages,
        # sheds, back fences, dumpsters, courtyards — smaller back-of-house
        # structures that don't front a street. A second placement pass that
        # fills block interiors would kill the 'empty' feel."
        #
        # Places 3-5 biome-appropriate interior fills at the chunk center +
        # offset positions. Each fill is a cluster (parking_lot, backyard,
        # courtyard, alley, or tree_cluster depending on biome). Only places
        # in empty space (spatial.is_free check) — doesn't overlap existing
        # road-adjacent buildings.
        p_count += _fill_block_interiors(chunk_root, profile, origin, biome, crng, poi_exclusions)

        # === STREET LIGHTS ===
        if profile.get("lights", false):
                _place_street_lights(chunk_root, chunk_roads, crng)

        # === Phase A.12: AI FILL PLAN READER ===
        # After procedural placement, read fill_plan.json (if it exists) +
        # place AI-suggested fills at identified gap positions. This is the
        # "DATA → MAP" half of the feedback loop:
        #   procedural → dump chunk_state → AI generates fill_plan → apply fills
        # The AI (Python script) reads chunk_states_auto.json, identifies
        # gaps with suggested_fill types, and writes fill_plan.json with
        # concrete placement decisions. Runtime applies them here.
        var fill_count := _apply_fill_plan(chunk_root, key, crng)
        if fill_count > 0:
                p_count += fill_count
                print("[ChunkStreamer] fill_plan applied: %d nodes (chunk %d_%d)" % [
                        fill_count, key.x, key.y
                ])

        # === v8.2: ZOMBIES (gap #10) ===
        # Biomes declare `zombies: N` (count per chunk). Spawn N zombies at
        # random non-overlapping positions inside the chunk, avoiding roads,
        # POI exclusions, and existing object placements (spatial index).
        # Mix: 70% walker (alternating male/female), 30% crawler. Crawlers
        # are slower but harder to spot — gives biomes like MILITARY (15
        # zombies) a more menacing feel.
        var z_count := _place_zombies(chunk_root, profile, origin, crng, poi_exclusions)

        add_child(chunk_root)
        _loaded[key] = chunk_root

        var bname: String = profile.get("name", "Unknown")
        # v8.2 Phase A.5: include district placeholder name in the chunk log
        # so we can see "Sarran Marshes" / "Junta Quarter" / etc. while walking
        # around. Names are placeholders — see city_config.gd district_names().
        var dname: String = CityConfig.district_name_for(biome)
        print("chunk %d_%d: biome=%s district=%s buildings=%d props=%d foliage=%d lights=%d landmarks=%d zombies=%d children=%d" % [
                key.x, key.y, bname, dname, b_count, p_count, f_count, s_count, l_count, z_count, chunk_root.get_child_count()
        ])
        # Tag the chunk_root with the district name for debug HUD / future GPS.
        chunk_root.set_meta("district_name", dname)

        # v8.2 Phase A.10: DATA-DRIVEN CHUNK STATE — dump the chunk's placement
        # data as a queryable Dictionary. This is the "understand the map as
        # data" approach the user asked for. After placement, we know exactly
        # what's where: building names + positions + zones, prop names, foliage
        # names, zombie positions, gap positions.
        #
        # Phase A.11: EXPANDED to include terrain heights, river geometry, road
        # paths, neighbor biomes, halo activity, gaps, density grid. Now the AI
        # can truly "see" the map — elevation profile, water coverage, what's
        # at each 25m cell, what biomes are nearby, whether a landmark halo is
        # active. This enables holistic analysis ("chunk 8_7 is 60% commercial
        # but has no parking lot + is near the stadium → should add parking").
        #
        # The state is stored on chunk_root as meta "chunk_state" + dumped to
        # JSON at scene ready for offline analysis.
        var chunk_state := _build_chunk_state(chunk_root, key, biome, dname, b_count, p_count, f_count, z_count)
        chunk_state = _enrich_chunk_state(chunk_state, key, biome, origin, poi_exclusions, _halo_buildings)
        chunk_root.set_meta("chunk_state", chunk_state)

func _build_visible_roads(chunk_root: Node3D, origin: Vector3, chunk_size: float) -> void:
        var chunk_roads: Array = _get_roads_in_chunk(origin, chunk_size)
        for seg in chunk_roads:
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                var width: float = float(seg.get("width", 8.0))
                var length: float = a.distance_to(b)
                if length < 1.0:
                        continue
                var mid: Vector3 = (a + b) * 0.5
                var dir: Vector3 = (b - a).normalized()

                # Phase A.6: unified road rendering — works for axis-aligned AND
                # diagonal roads. The old code used is_horizontal = abs(dir.z) >
                # abs(dir.x) to swap X/Z dimensions, which only handled the two
                # axis-aligned cases. Diagonal avenues (Sarran Avenue, Bayview
                # Avenue) need actual yaw rotation.
                #
                # Math: PlaneMesh.size = Vector2(X_dim, Z_dim) in local space.
                # Default forward (local +Z) = (0, 0, 1) world. After yaw rotation
                # around Y by angle θ, local +Z becomes (sin θ, 0, cos θ).
                # To align local +Z with road dir = (dir.x, 0, dir.z):
                #   sin θ = dir.x, cos θ = dir.z  →  θ = atan2(dir.x, dir.z)
                #
                # We always pass size = Vector2(perp_width, dir_length) where
                # perp_width is the road's physical width and dir_length is its
                # physical length. The yaw handles all orientation.
                var yaw: float = atan2(dir.x, dir.z)
                var perp: Vector3 = Vector3(-dir.z, 0, dir.x)

                # Road surface — width along local X (perp), length along local Z (dir)
                _create_plane_mesh_rotated(chunk_root, "Road",
                        Vector3(mid.x, Y_ROAD, mid.z),
                        Vector2(width, length), C_ROAD, yaw)

                # Center lane line (thin strip down the middle)
                _create_plane_mesh_rotated(chunk_root, "Lane",
                        Vector3(mid.x, Y_LANE, mid.z),
                        Vector2(0.15, length), C_LANE, yaw)

                # Sidewalks (both sides — offset perpendicular to road direction)
                var sw_off: float = width * 0.5 + CityConfig.SIDEWALK_WIDTH * 0.5
                var sw1: Vector3 = mid + perp * sw_off
                var sw2: Vector3 = mid - perp * sw_off
                _create_plane_mesh_rotated(chunk_root, "SW1",
                        Vector3(sw1.x, Y_SIDEWALK, sw1.z),
                        Vector2(CityConfig.SIDEWALK_WIDTH, length), C_SIDEWALK, yaw)
                _create_plane_mesh_rotated(chunk_root, "SW2",
                        Vector3(sw2.x, Y_SIDEWALK, sw2.z),
                        Vector2(CityConfig.SIDEWALK_WIDTH, length), C_SIDEWALK, yaw)

                # Grass strips (outside sidewalks)
                var gs_off: float = width * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH * 0.5
                var gs1: Vector3 = mid + perp * gs_off
                var gs2: Vector3 = mid - perp * gs_off
                _create_plane_mesh_rotated(chunk_root, "GS1",
                        Vector3(gs1.x, Y_GRASS, gs1.z),
                        Vector2(CityConfig.GRASS_STRIP_WIDTH, length), C_GRASS, yaw)
                _create_plane_mesh_rotated(chunk_root, "GS2",
                        Vector3(gs2.x, Y_GRASS, gs2.z),
                        Vector2(CityConfig.GRASS_STRIP_WIDTH, length), C_GRASS, yaw)

# Phase A.6: Plane mesh helper that supports yaw rotation around Y.
# Used for ALL road rendering (axis-aligned AND diagonal). Size is Vector2
# (X_dim, Z_dim) in the plane's LOCAL space — after yaw rotation:
#   local X = perp axis (sideways from road direction)
#   local Z = forward axis (along road direction)
# Y is set via pos.y (PlaneMesh.size is Vector2 so Y must be in position, not size).
# Layer cake per chunk_builder.gd placement rules: road=0.02, lane=0.025,
# grass=0.03, sidewalk=0.05, park=0.04.
func _create_plane_mesh_rotated(parent: Node3D, name: String, pos: Vector3, size: Vector2, color: Color, yaw: float) -> void:
        var mi := MeshInstance3D.new()
        mi.name = name + "_" + str(randi() % 10000)
        var p := PlaneMesh.new()
        p.size = size
        mi.mesh = p
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.85
        mi.material_override = mat
        mi.position = Vector3(pos.x, pos.y, pos.z)
        mi.rotation.y = yaw
        parent.add_child(mi)

func _place_park(chunk_root: Node3D, center: Vector3, crng: RandomNumberGenerator) -> void:
        # Park ground (darker green) — Phase A.6: uses _create_plane_mesh_rotated
        # with yaw=0 (axis-aligned). Square plane 60×60m.
        _create_plane_mesh_rotated(chunk_root, "ParkGround",
                Vector3(center.x, Y_PARK, center.z),
                Vector2(60, 60), C_PARK, 0.0)

        # Park furniture
        var park_assets := ["bench_park", "picnic_table", "playground_slide", "swing_set", "water_fountain", "garden_gnome", "planter_box"]
        for asset_name in park_assets:
                if not manifest.has(asset_name):
                        continue
                var scene: PackedScene = _get_asset(asset_name)
                if scene == null:
                        continue
                var offset := Vector3(crng.randf_range(-20, 20), 0, crng.randf_range(-20, 20))
                var inst: Node3D = scene.instantiate()
                inst.position = center + offset
                inst.rotation.y = crng.randf_range(0, TAU)
                inst.name = "%s_park_%d" % [asset_name, crng.randi() % 100000]
                chunk_root.add_child(inst)

        # Trees in circle
        var tree_types := ["oak_tree", "pine_tree", "birch_tree"]
        for i in range(8):
                var angle := float(i) * 45.0
                var r := 20.0
                var tx := center.x + cos(deg_to_rad(angle)) * r
                var tz := center.z + sin(deg_to_rad(angle)) * r
                var tree_name: String = tree_types[i % tree_types.size()]
                var scene: PackedScene = _get_asset(tree_name)
                if scene:
                        var inst: Node3D = scene.instantiate()
                        inst.position = Vector3(tx, 0, tz)
                        inst.rotation.y = float(i * 53)
                        inst.name = "%s_park_%d" % [tree_name, crng.randi() % 100000]
                        chunk_root.add_child(inst)

func _place_street_lights(chunk_root: Node3D, chunk_roads: Array, crng: RandomNumberGenerator) -> void:
        var scene: PackedScene = _get_asset("street_light")
        if scene == null:
                return
        var edge_offset: float = CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH * 0.5
        # v8.1: spacing radius bumped from 0.5m to MIN_CLEARANCE_M (2.0m)
        # per rule #7 (2m minimum between ALL objects).
        var light_radius: float = MIN_CLEARANCE_M
        for seg in chunk_roads:
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                var length: float = a.distance_to(b)
                if length < 25.0:
                        continue
                var dir: Vector3 = (b - a).normalized()
                var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
                var d: float = 12.0
                while d < length - 12.0:
                        var t: float = d / length
                        var base: Vector3 = a.lerp(b, t)
                        for side in [-1, 1]:
                                var pos: Vector3 = base + perp * edge_offset * float(side)
                                if spatial.is_free(pos, light_radius) and not spatial.is_on_road(pos):
                                        var inst: Node3D = scene.instantiate()
                                        inst.position = _terrain_pos(pos)
                                        inst.rotation.y = 0.0 if side < 0 else PI
                                        inst.name = "street_light_%d" % crng.randi()
                                        chunk_root.add_child(inst)
                                        spatial.insert(pos, light_radius)
                        d += 25.0

func _get_roads_in_chunk(origin: Vector3, chunk_size: float) -> Array:
        var result: Array = []
        var min_x: float = origin.x
        var max_x: float = origin.x + chunk_size
        var min_z: float = origin.z
        var max_z: float = origin.z + chunk_size
        for seg in roads.segments:
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                # Phase A.6: use proper segment-AABB intersection (Liang-Barsky)
                # instead of just AABB-AABB overlap. The old AABB-only check
                # treated every chunk as containing the diagonal avenues (since
                # the diagonal's bounding box spans the whole map), which caused
                # every chunk to render the diagonal + place street lights along
                # it. Liang-Barsky correctly tests if the segment line actually
                # passes through the chunk's rectangle.
                if not _segment_intersects_chunk(a, b, min_x, max_x, min_z, max_z):
                        continue
                result.append(seg)
        return result

# Phase A.6: Liang-Barsky line clipping test — does segment [a, b] pass
# through the rectangle [min_x, max_x] × [min_z, max_z]?
# Returns true if the segment intersects the rectangle (including just touching
# an edge). Works for any orientation — axis-aligned, diagonal, anything.
# Algorithm: parametrize the segment as P(t) = a + t·(b-a) for t ∈ [0,1],
# then find the t-range where the segment is inside the rectangle. If the
# t-range is non-empty, the segment intersects.
static func _segment_intersects_chunk(
        a: Vector3, b: Vector3,
        min_x: float, max_x: float,
        min_z: float, max_z: float
) -> bool:
        var dx: float = b.x - a.x
        var dz: float = b.z - a.z
        var t_min: float = 0.0
        var t_max: float = 1.0
        # X slab
        if abs(dx) < 0.0001:
                # Segment parallel to X-axis (perpendicular to X slab) — check if inside
                if a.x < min_x or a.x > max_x:
                        return false
        else:
                var t1: float = (min_x - a.x) / dx
                var t2: float = (max_x - a.x) / dx
                if t1 > t2:
                        var tmp: float = t1; t1 = t2; t2 = tmp
                t_min = max(t_min, t1)
                t_max = min(t_max, t2)
                if t_min > t_max:
                        return false
        # Z slab
        if abs(dz) < 0.0001:
                if a.z < min_z or a.z > max_z:
                        return false
        else:
                var t1: float = (min_z - a.z) / dz
                var t2: float = (max_z - a.z) / dz
                if t1 > t2:
                        var tmp: float = t1; t1 = t2; t2 = tmp
                t_min = max(t_min, t1)
                t_max = min(t_max, t2)
                if t_min > t_max:
                        return false
        return true

func _is_near_intersection(pos: Vector3, threshold: float) -> bool:
        for seg in roads.segments:
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                # Check if pos is near a road that's perpendicular to another road at this point
                var dist := _point_segment_distance(pos, a, b)
                if dist < threshold:
                        # Check if there's another road crossing near here
                        for seg2 in roads.segments:
                                if seg == seg2:
                                        continue
                                var a2: Vector3 = seg2["start"]
                                var b2: Vector3 = seg2["end"]
                                # Check if the two segments cross near pos
                                var d1 := _point_segment_distance(pos, a2, b2)
                                if d1 < threshold:
                                        return true
        return false

# v8.2 Phase A.6: HIGHWAY CLEARANCE check — returns true if pos is within
# HIGHWAY_CLEARANCE_M of any road segment with kind="highway". Used by
# building placement to skip lots adjacent to limited-access highways.
# This enforces the "no storefronts on the highway" zoning rule.
#
# Cheap O(N_highways) per call — typically 2 highway segments in the map,
# so ~2 distance calculations per building candidate. With ~40 buildings per
# chunk × 25 visible chunks = 1000 calls, total = 2000 distance calcs/frame
# during chunk build. Negligible.
func _is_near_highway(pos: Vector3) -> bool:
        for seg in roads.segments:
                if seg.get("kind", "street") != "highway":
                        continue
                var d: float = roads.distance_to_road_centerline(pos, seg)
                if d < HIGHWAY_CLEARANCE_M:
                        return true
        return false

func _unload_chunk(key: Vector2i) -> void:
        var inst: Node3D = _loaded[key]
        inst.queue_free()
        _loaded.erase(key)

func _get_pois_for_chunk(origin: Vector3, chunk_size: float) -> Array:
        var result: Array = []
        for poi in _pois_cache:
                var px: float = float(poi.pos[0])
                var pz: float = float(poi.pos[2])
                if px >= origin.x and px < origin.x + chunk_size and pz >= origin.z and pz < origin.z + chunk_size:
                        result.append(poi)
        return result

static func _is_in_poi_exclusion(pos: Vector3, exclusions: Array) -> bool:
        for exc in exclusions:
                var center: Vector3 = exc["center"]
                var radius: float = exc["radius"]
                if pos.distance_to(center) < radius:
                        return true
        return false

func _get_asset(p_name: String) -> PackedScene:
        if asset_cache.has(p_name):
                return asset_cache[p_name]
        if not manifest.has(p_name):
                return null
        var s: PackedScene = load(manifest[p_name]["path"]) as PackedScene
        asset_cache[p_name] = s
        return s

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
        var ab: Vector3 = b - a
        if ab.length_squared() < 0.001:
                return p.distance_to(a)
        var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
        return p.distance_to(a + ab * t)

# ============================================================
# v8: BUILDING SPAWN WITH SHELL + COMPONENT ATTACHMENT
# ============================================================
# Spawns a building. If `<name>_shell.glb` exists, prefer it (door/windows
# removed from main mesh), then load `<name>_components.json` and spawn
# each listed component (door_front, window_unit, door_garage) as a child
# node at the manifest position. The child node carries metadata flags
# (can_open, can_lock, can_break, can_climb) so the player controller can
# later pick it up via raycast and trigger open/break/climb interactions.
#
# Falls back to the regular building GLB if no shell exists.
# Returns the spawned Node3D, or null on failure.
func _spawn_building_with_components(
        bname: String, lot_pos: Vector3, perp: Vector3, side: int,
        crng: RandomNumberGenerator, chunk_root: Node3D
) -> Node3D:
        # Try shell variant first
        var shell_scene: PackedScene = _get_shell_scene(bname)
        var scene: PackedScene = shell_scene if shell_scene != null else _get_asset(bname)
        if scene == null:
                return null

        var inst: Node3D = scene.instantiate()
        inst.position = _terrain_pos(lot_pos)
        # Face the road + slight rotation variation
        var face_angle: float = atan2(perp.x, perp.z) * float(side)
        inst.rotation.y = face_angle + crng.randf_range(-0.1, 0.1)
        # Scale variation (0.9-1.1)
        var scale_var: float = crng.randf_range(0.9, 1.1)
        inst.scale = Vector3(scale_var, crng.randf_range(0.95, 1.05), scale_var)
        inst.name = "%s_%d" % [bname, crng.randi() % 100000]
        inst.set_meta("building_name", bname)
        inst.set_meta("has_shell", shell_scene != null)
        chunk_root.add_child(inst)

        # v8.2: BUILDING COLLISION (gap #4) — GLB import has no collision by
        # default, so without this the player walks through walls. We walk
        # every MeshInstance3D descendant of the building and call
        # create_trimesh_collision() on it, which generates a sibling
        # StaticBody3D + ConcavePolygonShape3D following the actual mesh
        # triangles. Trimesh (not box) is essential for shell buildings,
        # whose walls have REAL holes for doorways/windows — a box collider
        # would cover those holes and block the player even when the door
        # is open. Trimesh follows the wall geometry so doorway holes stay
        # passable.
        _attach_building_collision(inst)

        # If we used the shell variant AND a component manifest exists,
        # spawn each component as a child of this building instance.
        if shell_scene != null:
                var manifest_data: Dictionary = _get_component_manifest(bname)
                if not manifest_data.is_empty():
                        _attach_components(inst, manifest_data, crng)

        return inst

# v8.2: Walk all MeshInstance3D descendants of `building_inst` and call
# create_trimesh_collision() on each. This generates a sibling StaticBody3D
# with a ConcavePolygonShape3D matching the mesh's triangles. Cheap to call
# (Godot handles the convex hull / triangulation internally) and gives
# per-mesh colliders that follow wall holes, doorway recesses, and window
# openings — critical for shell buildings so the player can walk through
# doorways when the door is open.
#
# v8.2 Phase A.8: For non-shell buildings (no doorway holes — most of the
# 226 assets), use a single Box collider based on the combined AABB instead
# of per-mesh trimesh. This reduces physics body count from ~5 per building
# to 1 per building. Shell buildings keep trimesh (needed for doorway holes).
#
# The created StaticBody3D children are added to the mesh's parent, so they
# inherit the building's transform (position/rotation/scale) automatically.
# No manual bookkeeping needed.
func _attach_building_collision(building_inst: Node3D) -> void:
        # Check if this building has a shell variant (doorway holes need trimesh)
        var bname: String = building_inst.get_meta("building_name", "")
        var has_shell: bool = false
        if bname != "":
                has_shell = _get_shell_scene(bname) != null or building_inst.get_meta("has_shell", false)
        if has_shell:
                # Shell building — use per-mesh trimesh (follows doorway holes)
                var mesh_count := 0
                for child in building_inst.find_children("*", "MeshInstance3D", true, false):
                        var mi: MeshInstance3D = child
                        mi.create_trimesh_collision()
                        mesh_count += 1
                if mesh_count > 0:
                        building_inst.set_meta("has_collision", true)
                        building_inst.set_meta("collision_mesh_count", mesh_count)
                        building_inst.set_meta("collision_type", "trimesh")
        else:
                # Non-shell building — use single box collider from AABB (cheap)
                var aabb := _compute_building_aabb(building_inst)
                if aabb.size != Vector3.ZERO:
                        var static_body := StaticBody3D.new()
                        static_body.name = "BuildingCollider"
                        static_body.position = aabb.position + aabb.size * 0.5
                        var col_shape := CollisionShape3D.new()
                        var box := BoxShape3D.new()
                        box.size = aabb.size
                        col_shape.shape = box
                        static_body.add_child(col_shape)
                        building_inst.add_child(static_body)
                        building_inst.set_meta("has_collision", true)
                        building_inst.set_meta("collision_type", "box")

# Compute the combined AABB of all MeshInstance3D children in building-local
# space. Used to create a single Box collider for non-shell buildings.
# Walks the tree manually with transform accumulation (Godot's get_aabb()
# doesn't always work recursively at runtime).
func _compute_building_aabb(building_inst: Node3D) -> AABB:
        var aabb := AABB()
        var first := true
        var stack: Array = [{node = building_inst, xform = Transform3D.IDENTITY}]
        while not stack.is_empty():
                var entry: Dictionary = stack.pop_back()
                var node: Node = entry.node
                var xform: Transform3D = entry.xform
                if node is MeshInstance3D:
                        var mi: MeshInstance3D = node
                        var mesh_aabb: AABB = mi.get_aabb()
                        if mesh_aabb.size != Vector3.ZERO:
                                var world_aabb: AABB = xform * mi.transform * mesh_aabb
                                if first:
                                        aabb = world_aabb
                                        first = false
                                else:
                                        aabb = aabb.merge(world_aabb)
                if node is Node3D:
                        var parent_xform: Transform3D = xform * (node as Node3D).transform
                        for child in node.get_children():
                                stack.append({node = child, xform = parent_xform})
        return aabb

# v8.2 Phase A.8: disable shadows on all MeshInstance3D descendants of `inst`.
# Called after instantiating small props (trash_can, mailbox, etc.) to skip
# the DirectionalLight3D shadow pass for them. Saves ~30% shadow render cost.
# Trees + buildings + zombies keep shadows (tall enough to matter visually).
func _disable_shadows_if_small_prop(inst: Node3D, asset_name: String) -> void:
        if not NO_SHADOW_PROPS.has(asset_name):
                return
        for mi in inst.find_children("*", "MeshInstance3D", true, false):
                (mi as MeshInstance3D).cast_shadow = 0

# v8.2 Phase A.8: disable shadows on small foliage (bushes, hedges, flowers).
# Trees (oak_tree, pine_tree, birch_tree, etc.) keep shadows — they're tall
# enough to be visible + cast meaningful shadows. Small foliage = no shadow.
const SMALL_FOLIAGE := ["bush", "hedge", "hedge_tall", "flower_patch", "weeds", "fern", "tall_grass", "marsh_grass", "cattail", "ivy_wall", "mushrooms", "rocks_small", "fallen_log"]
func _disable_shadows_if_small_foliage(inst: Node3D, asset_name: String) -> void:
        if not SMALL_FOLIAGE.has(asset_name):
                return
        for mi in inst.find_children("*", "MeshInstance3D", true, false):
                (mi as MeshInstance3D).cast_shadow = 0

# Look up the shell GLB for a building. Returns null if no shell exists.
# Cached so we only do the ResourceLoader.exists() check once per asset.
func _get_shell_scene(bname: String) -> PackedScene:
        if _shell_scene_cache.has(bname):
                return _shell_scene_cache[bname]
        var shell_path := "res://assets/buildings/%s_shell.glb" % bname
        if not ResourceLoader.exists(shell_path, "PackedScene"):
                _shell_scene_cache[bname] = null
                return null
        var s: PackedScene = load(shell_path) as PackedScene
        _shell_scene_cache[bname] = s
        return s

# Load the component manifest JSON for a building. Returns empty Dictionary
# if no manifest exists.
func _get_component_manifest(bname: String) -> Dictionary:
        if _component_manifest_cache.has(bname):
                return _component_manifest_cache[bname]
        var path := "res://data/building_components/%s_components.json" % bname
        if not ResourceLoader.exists(path):
                _component_manifest_cache[bname] = {}
                return {}
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
                _component_manifest_cache[bname] = {}
                return {}
        var parsed = JSON.parse_string(f.get_as_text())
        if parsed == null or not (parsed is Dictionary):
                _component_manifest_cache[bname] = {}
                return {}
        _component_manifest_cache[bname] = parsed
        return parsed

# Spawn each component from the manifest as a child of the building instance.
# Components carry metadata flags so the player controller can identify them
# by raycast and apply the right interaction (open/close, break, climb).
#
# v8.2: DOORS WITH hinge_side now get wrapped in a pivot Node3D placed at the
# hinge edge of the door (rather than at the door's center). The pivot rotates
# instead of the door, so the door swings naturally around its hinge instead
# of spinning around its center like a revolving door.
#
# Math: the manifest's `pos` is the door's CENTER in building-local space.
# The hinge edge sits at door_local_x * (±half_width) where half_width is
# half the collider's X extent (0.55m for door_front, 1.20m for door_garage).
# We compute the hinge position in building-local space, place the pivot there
# (with the door's rot_y), then offset the door by ±half_width along the
# pivot's local +X axis. The door ends up at the same world position as before.
#
# Non-door components (windows) and doors without `hinge_side` keep the old
# behavior: comp_inst is parented directly to the building and rotated in place.
#
# Interaction metadata is set on the PIVOT (not the door) for hinged doors —
# the player's raycast hits the door's collider, walks up the parent chain,
# and finds the pivot's meta. Toggling pivot.rotation.y swings the door.
#
# Also attaches a StaticBody3D + BoxShape3D collider matching the component's
# bounding box — Godot's GLB importer does NOT generate collision by default,
# so without this the player's interaction raycast would pass straight through
# the door mesh.
func _attach_components(building_inst: Node3D, manifest_data: Dictionary, crng: RandomNumberGenerator) -> void:
        var components: Array = manifest_data.get("components", [])
        for comp in components:
                var comp_type: String = comp.get("type", "")
                var comp_scene: PackedScene = _get_asset(comp_type)
                # Components live under assets/components/ — try direct path if not in manifest
                if comp_scene == null:
                        var direct_path := "res://assets/components/%s.glb" % comp_type
                        if ResourceLoader.exists(direct_path, "PackedScene"):
                                comp_scene = load(direct_path) as PackedScene
                if comp_scene == null:
                        push_warning("[ChunkStreamer] component '%s' not found for %s" % [comp_type, building_inst.name])
                        continue
                var comp_inst: Node3D = comp_scene.instantiate()
                # Position is relative to the building origin
                var pos_arr: Array = comp.get("pos", [0, 0, 0])
                var comp_pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
                var comp_rot_y: float = float(comp.get("rot_y", 0.0))
                comp_inst.name = "comp_%s_%s" % [comp.get("id", comp_type), crng.randi() % 10000]

                # v8.2: if this is a hinged door (can_open + hinge_side), wrap it
                # in a pivot Node3D placed at the hinge edge.
                var use_pivot: bool = bool(comp.get("can_open", false)) and comp.has("hinge_side")
                var pivot_inst: Node3D = null
                if use_pivot:
                        var hinge_side: String = String(comp.get("hinge_side", "left"))
                        # Hinge offset in door-local X axis: ±half the collider's X extent.
                        var collider_size: Vector3 = COMPONENT_COLLIDER_SIZES.get(comp_type, Vector3(1.0, 1.0, 0.1))
                        var half_w: float = collider_size.x * 0.5
                        # door_local_X (in building space, after yaw) = (cos θ, 0, sin θ)
                        # Godot's right-hand rule: positive Y rotation moves +X toward +Z.
                        var cos_y: float = cos(deg_to_rad(comp_rot_y))
                        var sin_y: float = sin(deg_to_rad(comp_rot_y))
                        # Hinge edge in building-local space:
                        #   left hinge  → -half_w in door-local X → (-half_w·cos, 0, -half_w·sin)
                        #   right hinge → +half_w in door-local X → (+half_w·cos, 0, +half_w·sin)
                        # See derivation in the doc comment above.
                        var sign: float = -1.0 if hinge_side == "left" else 1.0
                        var hinge_offset := Vector3(sign * half_w * cos_y, 0.0, sign * half_w * sin_y)
                        var pivot_pos := comp_pos + hinge_offset

                        pivot_inst = Node3D.new()
                        pivot_inst.name = "pivot_%s" % comp_inst.name
                        pivot_inst.position = pivot_pos
                        pivot_inst.rotation.y = deg_to_rad(comp_rot_y)
                        building_inst.add_child(pivot_inst)

                        # Door is child of pivot, offset by -hinge_offset along pivot's local +X
                        # (which is the door's local +X since they share rotation).
                        comp_inst.position = Vector3(-sign * half_w, 0.0, 0.0)
                        comp_inst.rotation.y = 0.0  # pivot handles yaw
                        pivot_inst.add_child(comp_inst)
                else:
                        # No pivot — attach directly to building (windows, hingeless doors)
                        comp_inst.position = comp_pos
                        comp_inst.rotation.y = comp_rot_y
                        building_inst.add_child(comp_inst)

                # Tag with interaction metadata — player controller reads these via get_meta().
                # For pivoted doors, meta goes on the PIVOT (so toggling pivot.rotation.y swings door).
                # For non-pivoted components, meta goes on comp_inst directly.
                var meta_target: Node3D = pivot_inst if pivot_inst != null else comp_inst
                meta_target.set_meta("component_type", comp_type)
                meta_target.set_meta("interactive", bool(comp.get("interactive", true)))
                meta_target.set_meta("can_open", bool(comp.get("can_open", false)))
                meta_target.set_meta("can_lock", bool(comp.get("can_lock", false)))
                meta_target.set_meta("can_break", bool(comp.get("can_break", false)))
                meta_target.set_meta("can_climb", bool(comp.get("can_climb", false)))
                if comp.has("hinge_side"):
                        meta_target.set_meta("hinge_side", comp["hinge_side"])
                if comp.has("open_type"):
                        meta_target.set_meta("open_type", comp["open_type"])
                # Initial state
                meta_target.set_meta("is_open", false)
                meta_target.set_meta("is_locked", bool(comp.get("can_lock", false)))
                # For pivoted doors, also remember the pivot's closed rotation so
                # we can restore it on close (matches the existing convention in
                # player_main.gd which saves/restores closed_rotation_y on the
                # interactive node — that node is now the pivot, not the door).
                meta_target.set_meta("closed_rotation_y", meta_target.rotation.y)

                # Attach a collision body so the player's interaction raycast
                # can actually hit this component (GLB import has no collision).
                _attach_component_collider(comp_inst, comp_type)

# Add a StaticBody3D + BoxShape3D as a child of comp_inst, sized to the
# component's bounding box. The collider is centered above the component's
# origin (since door/window origins sit at the bottom of the mesh).
const COMPONENT_COLLIDER_SIZES := {
        "door_front": Vector3(1.10, 2.20, 0.10),
        "door_garage": Vector3(2.40, 2.40, 0.10),
        "window_unit": Vector3(1.20, 1.30, 0.10),
}
func _attach_component_collider(comp_inst: Node3D, comp_type: String) -> void:
        var size: Vector3 = COMPONENT_COLLIDER_SIZES.get(comp_type, Vector3(1.0, 1.0, 0.1))
        var static_body := StaticBody3D.new()
        static_body.name = "Collider"
        # Center the collider above the component's origin (origin is at bottom)
        static_body.position = Vector3(0.0, size.y * 0.5, 0.0)
        var col_shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        col_shape.shape = box
        static_body.add_child(col_shape)
        comp_inst.add_child(static_body)

# ============================================================
# v8: ANTI-CLUSTERING
# ============================================================
# Returns true if it's OK to place another instance of `bname` at `pos`.
# Returns false if another instance of the same asset is too close.
# Distance thresholds:
#   - Landmark assets (in any biome's `landmarks` array): LANDMARK_MIN_DIST_M
#   - Special civic/commercial assets (gas_station, hospital, ...): SPECIAL_MIN_DIST_M
#   - Everything else: 0 (no constraint — overlap check handles adjacency)
func _anti_cluster_ok(bname: String, pos: Vector3) -> bool:
        var min_dist: float = _anti_cluster_distance_for(bname)
        if min_dist <= 0.0:
                return true
        if not _asset_positions.has(bname):
                return true
        var positions: Array = _asset_positions[bname]
        for other_pos in positions:
                if pos.distance_to(other_pos) < min_dist:
                        return false
        return true

# Returns the anti-cluster minimum distance for a given asset name.
# Landmark assets get the largest distance; special civic/commercial assets
# get the medium distance; everything else gets 0.
func _anti_cluster_distance_for(bname: String) -> float:
        if _is_landmark_asset(bname):
                return LANDMARK_MIN_DIST_M
        if SPECIAL_ANTICLUSTER.has(bname):
                return SPECIAL_MIN_DIST_M
        return 0.0

# Returns true if `bname` appears in any biome's `landmarks` array.
# Cached at first call.
func _is_landmark_asset(bname: String) -> bool:
        if _landmark_asset_set.is_empty():
                for biome_profile in CityConfig.biomes().values():
                        for lm in biome_profile.get("landmarks", []):
                                _landmark_asset_set[lm] = true
        return _landmark_asset_set.has(bname)

# Record a placed asset's position so future anti-cluster checks can see it.
func _register_asset_position(bname: String, pos: Vector3) -> void:
        if not _asset_positions.has(bname):
                _asset_positions[bname] = []
        _asset_positions[bname].append(pos)

# ============================================================
# v8: LANDMARK PLACEMENT
# ============================================================
# Places ONE hero asset at the chunk center, chosen from profile.landmarks.
# Skips if:
#   - profile has no landmarks
#   - center is occupied (road, POI exclusion, existing building)
#   - any landmark of the same type is already within LANDMARK_MIN_DIST_M
# Returns 1 if placed, 0 otherwise.
func _place_landmark(
        chunk_root: Node3D, profile: Dictionary, origin: Vector3,
        key: Vector2i, crng: RandomNumberGenerator, poi_exclusions: Array
) -> int:
        var landmarks: Array = profile.get("landmarks", [])
        if landmarks.is_empty():
                return 0

        # Try chunk center first; if blocked, try a few jittered offsets.
        var center := origin + Vector3(
                CityConfig.CHUNK_SIZE_M * 0.5, 0,
                CityConfig.CHUNK_SIZE_M * 0.5
        )
        # Big footprint — stadiums / palaces / forts need ~30m clearance
        var landmark_radius: float = 30.0

        # Check feasibility at center + a few jittered candidates
        var candidates: Array = [center]
        for _i in range(4):
                candidates.append(center + Vector3(
                        crng.randf_range(-60.0, 60.0), 0,
                        crng.randf_range(-60.0, 60.0)
                ))

        var chosen_pos: Vector3 = Vector3.ZERO
        var found_pos: bool = false
        for cand in candidates:
                if cand.x < origin.x + 10 or cand.x > origin.x + CityConfig.CHUNK_SIZE_M - 10:
                        continue
                if cand.z < origin.z + 10 or cand.z > origin.z + CityConfig.CHUNK_SIZE_M - 10:
                        continue
                if not spatial.is_free(cand, landmark_radius):
                        continue
                if spatial.is_on_road(cand):
                        continue
                if _is_in_poi_exclusion(cand, poi_exclusions):
                        continue
                chosen_pos = cand
                found_pos = true
                break
        if not found_pos:
                return 0

        # Pick a landmark whose anti-cluster allows placement here.
        # Try each in random order until one fits.
        var shuffled: Array = landmarks.duplicate()
        shuffled.shuffle()
        for lm_name in shuffled:
                if not _anti_cluster_ok(lm_name, chosen_pos):
                        continue
                var scene: PackedScene = _get_asset(lm_name)
                if scene == null:
                        continue
                var inst: Node3D = scene.instantiate()
                inst.position = _terrain_pos(chosen_pos)
                inst.rotation.y = crng.randf_range(0, TAU)
                inst.name = "LANDMARK_%s_%d" % [lm_name, crng.randi() % 100000]
                inst.set_meta("is_landmark", true)
                inst.set_meta("building_name", lm_name)
                chunk_root.add_child(inst)
                # v8.2: landmarks are also GLB imports without collision —
                # attach trimesh colliders so the player can't walk through
                # the stadium / palace / fort walls.
                _attach_building_collision(inst)
                spatial.insert(chosen_pos, landmark_radius)
                # v8.1: also register as a POI exclusion so the gap filler,
                # foliage, and utility pole loops all steer clear of the
                # landmark's footprint (not just the buildings loop).
                poi_exclusions.append({"center": chosen_pos, "radius": landmark_radius})
                _register_asset_position(lm_name, chosen_pos)
                # If this landmark has a shell variant (e.g. broadcast_tower_shell),
                # also attach its interactive components (door, windows).
                if _get_shell_scene(lm_name) != null:
                        var lm_manifest: Dictionary = _get_component_manifest(lm_name)
                        if not lm_manifest.is_empty():
                                _attach_components(inst, lm_manifest, crng)
                print("[ChunkStreamer] LANDMARK placed: %s at %s (chunk %d_%d)" % [
                        lm_name, chosen_pos, key.x, key.y
                ])
                return 1
        return 0

# ============================================================
# v8.1: UTILITY POLE PLACEMENT (rule #2 — behind buildings)
# ============================================================
# Walks each road segment at UTILITY_POLE_SPACING_M (35m) intervals and
# places a utility pole at the BACK of the lot (27.5m from road centerline),
# alternating sides per pole so both sides of the street get service.
#
# Poles only spawn on "street" kind segments (no highways/bridges) and only
# if utility_pole is registered in the manifest.
#
# Returns the count of poles placed (added to s_count by caller).
func _place_utility_poles(chunk_root: Node3D, chunk_roads: Array, crng: RandomNumberGenerator) -> int:
        if not manifest.has("utility_pole"):
                return 0
        var scene: PackedScene = _get_asset("utility_pole")
        if scene == null:
                return 0
        var count := 0
        var pole_radius: float = MIN_CLEARANCE_M  # 2m clearance per rule #7
        var pole_index := 0  # alternates sides per pole
        for seg in chunk_roads:
                if NON_LOT_ROAD_KINDS.has(seg.get("kind", "street")):
                        continue
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                var length: float = a.distance_to(b)
                if length < UTILITY_POLE_SPACING_M:
                        continue
                var dir: Vector3 = (b - a).normalized()
                var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
                var d: float = UTILITY_POLE_SPACING_M * 0.5
                while d < length:
                        var t: float = d / length
                        var base: Vector3 = a.lerp(b, t)
                        # Alternate sides: even index → +perp, odd index → -perp
                        var side: int = 1 if (pole_index % 2) == 0 else -1
                        var pole_pos: Vector3 = base + perp * float(side) * UTILITY_POLE_OFFSET_M
                        if spatial.is_free(pole_pos, pole_radius) and not spatial.is_on_road(pole_pos):
                                var inst: Node3D = scene.instantiate()
                                inst.position = _terrain_pos(pole_pos)
                                # Pole faces along the road (crossbar perpendicular to road)
                                inst.rotation.y = atan2(dir.x, dir.z) + crng.randf_range(-0.05, 0.05)
                                inst.name = "utility_pole_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                spatial.insert(pole_pos, pole_radius)
                                count += 1
                        pole_index += 1
                        d += UTILITY_POLE_SPACING_M
        return count

# ============================================================
# v8.1: FIRE HYDRANT PLACEMENT (rule #3 — at intersection corners)
# ============================================================
# Walks each road segment at LOT_W intervals. At each position where
# _is_near_intersection() returns true, places a fire hydrant at the corner
# offset (6.5m from road centerline, just past the sidewalk).
#
# Uses spatial.insert(2m) for dedup so we don't stack multiple hydrants at
# the same intersection when two road segments cross there.
#
# Only spawns on "street" kind segments. Skips if fire_hydrant not in manifest.
#
# Returns the count of hydrants placed (added to s_count by caller).
func _place_fire_hydrants(chunk_root: Node3D, chunk_roads: Array, crng: RandomNumberGenerator) -> int:
        if not manifest.has("fire_hydrant"):
                return 0
        var scene: PackedScene = _get_asset("fire_hydrant")
        if scene == null:
                return 0
        var count := 0
        var hydrant_radius: float = MIN_CLEARANCE_M  # 2m clearance per rule #7
        for seg in chunk_roads:
                if NON_LOT_ROAD_KINDS.has(seg.get("kind", "street")):
                        continue
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                var length: float = a.distance_to(b)
                if length < LOT_W:
                        continue
                var dir: Vector3 = (b - a).normalized()
                var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
                # Walk the segment looking for intersection zones.
                # _is_near_intersection checks both roads at each candidate
                # point, so we sample every LOT_W (20m) to catch all crossings.
                var d: float = LOT_W * 0.5
                while d < length:
                        var t: float = d / length
                        var base: Vector3 = a.lerp(b, t)
                        if not _is_near_intersection(base, 10.0):
                                d += LOT_W
                                continue
                        # We're near a crossing — place a hydrant on the +perp side
                        # (the corner of the lot facing the intersection).
                        # Try both sides; the spatial dedupe will skip the second
                        # if the corner is already taken.
                        for side in [-1, 1]:
                                var hydrant_pos: Vector3 = base + perp * float(side) * FIRE_HYDRANT_OFFSET_M
                                # Nudge along the road a bit so the hydrant sits
                                # at the corner of the intersection, not the middle.
                                hydrant_pos += dir * float(side) * 2.0
                                if not spatial.is_free(hydrant_pos, hydrant_radius):
                                        continue
                                if spatial.is_on_road(hydrant_pos):
                                        continue
                                var inst: Node3D = scene.instantiate()
                                inst.position = _terrain_pos(hydrant_pos)
                                inst.rotation.y = crng.randf_range(0, TAU)
                                inst.name = "fire_hydrant_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                spatial.insert(hydrant_pos, hydrant_radius)
                                count += 1
                                break  # one hydrant per intersection corner is enough
                        d += LOT_W
        return count

# ============================================================
# v8.2: ZOMBIE PLACEMENT (gap #10)
# ============================================================
# Biome profiles declare `zombies: N` (integer count per chunk). This walks
# N candidates and tries to place each at a random non-overlapping position
# inside the chunk. Skips:
#   - chunks with 0 zombies (River, Water, Empty)
#   - positions on roads (spatial.is_on_road)
#   - positions inside POI exclusions (landmarks, services)
#   - positions where spatial.is_free(1m) fails (something already there)
#
# Mix: 70% walker (alternating male/female), 30% crawler. Crawlers are
# harder to see (low silhouette) — makes high-density biomes scarier.
#
# Zombies are tagged with meta "is_zombie"=true + "zombie_kind"="walker"/"crawler"
# so a future AI controller can find them via find_children() and drive
# pathfinding / attack behavior. For now they're static poses — they spawn
# standing/crawling and don't move. That's enough for visual density.
#
# Returns the count of zombies actually placed (added to z_count by caller).
const ZOMBIE_RADIUS := 1.0  # 1m clearance so zombies don't overlap each other
func _place_zombies(
        chunk_root: Node3D, profile: Dictionary, origin: Vector3,
        crng: RandomNumberGenerator, poi_exclusions: Array
) -> int:
        var base_target: int = int(profile.get("zombies", 0))
        # v8.2 Phase A.8: apply zombie count scale factor (FPS optimization).
        # Was 10-15 per chunk × 25 chunks = 250+ zombies × 17 meshes each =
        # ~4250 draw calls just for zombies. Scaling to 0.5 = 5-8 per chunk.
        var target: int = int(base_target * ZOMBIE_SCALE_FACTOR)
        if target <= 0:
                return 0
        # Verify zombie assets are in the manifest before attempting spawns.
        # All three types should already be registered (manifest has 92+ assets).
        var walker_male: PackedScene = _get_asset("walker_zombie_male")
        var walker_female: PackedScene = _get_asset("walker_zombie_female")
        var crawler: PackedScene = _get_asset("crawler_zombie")
        if walker_male == null and walker_female == null and crawler == null:
                push_warning("[ChunkStreamer] no zombie assets in manifest — skipping zombie spawn")
                return 0
        var count := 0
        var walker_toggle := 0  # alternates male/female
        # Cap attempts at 3x target so we don't spin forever in dense chunks.
        var max_attempts := target * 3
        var attempts := 0
        while count < target and attempts < max_attempts:
                attempts += 1
                var pos := Vector3(
                        origin.x + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0),
                        0.0,
                        origin.z + crng.randf_range(5.0, CityConfig.CHUNK_SIZE_M - 5.0)
                )
                if spatial.is_on_road(pos):
                        continue
                if not spatial.is_free(pos, ZOMBIE_RADIUS):
                        continue
                if _is_in_poi_exclusion(pos, poi_exclusions):
                        continue
                # Pick zombie kind: 70% walker, 30% crawler.
                var scene: PackedScene = null
                var kind: String = ""
                if crng.randf() < 0.7:
                        kind = "walker"
                        if walker_male == null:
                                scene = walker_female
                        elif walker_female == null:
                                scene = walker_male
                        else:
                                scene = walker_male if (walker_toggle % 2) == 0 else walker_female
                                walker_toggle += 1
                else:
                        kind = "crawler"
                        scene = crawler
                if scene == null:
                        # Fallback: if crawler missing, use walker; if walker missing, use crawler.
                        kind = "walker" if kind == "crawler" else "crawler"
                        scene = walker_male if walker_male != null else walker_female
                        if scene == null:
                                scene = crawler
                if scene == null:
                        continue
                var inst: Node3D = scene.instantiate()
                inst.position = _terrain_pos(pos)
                inst.rotation.y = crng.randf_range(0, TAU)
                # Slight scale variation so the herd doesn't look cloned.
                var scale_var: float = crng.randf_range(0.95, 1.05)
                inst.scale = Vector3(scale_var, scale_var, scale_var)
                inst.name = "zombie_%s_%d" % [kind, crng.randi() % 100000]
                inst.set_meta("is_zombie", true)
                inst.set_meta("zombie_kind", kind)
                chunk_root.add_child(inst)
                spatial.insert(pos, ZOMBIE_RADIUS)
                count += 1
        return count

# v8.2 Phase A.9: DISTRICT HALO — collect halo buildings from landmarks
# near the given chunk. Returns Dictionary[asset_name → boost_multiplier].
# A stadium nearby → parking_garage, bank_branch, etc. get 2x boost.
# A hospital nearby → store_pharmacy, bank_branch, etc. get 2.5x boost.
# Used by building placement to weighted-pick halo buildings 40% of the time.
#
# Walks _asset_positions (the anti-cluster tracker) to find landmarks
# within HALO_RADIUS_M of the chunk center. For each, looks up its halo
# profile in CityConfig.LANDMARK_HALOS and merges into the result dict.
# If multiple landmarks are near, their boosts multiply (e.g. stadium +
# hospital both near → parking_garage gets 2x × 2.5x = 5x boost).
func _collect_halo_buildings(origin: Vector3, chunk_size: float) -> Dictionary:
        var result: Dictionary = {}
        var chunk_center := origin + Vector3(chunk_size * 0.5, 0, chunk_size * 0.5)
        for bname in _asset_positions.keys():
                var halo: Dictionary = CityConfig.halo_for(bname)
                if halo.is_empty():
                        continue
                var positions: Array = _asset_positions[bname]
                for pos in positions:
                        if pos.distance_to(chunk_center) <= CityConfig.HALO_RADIUS_M:
                                var halo_buildings: Array = halo.get("halo_buildings", [])
                                var mult: float = float(halo.get("halo_prob_mult", 1.5))
                                for hb in halo_buildings:
                                        if result.has(hb):
                                                result[hb] = float(result[hb]) * mult
                                        else:
                                                result[hb] = mult
                                break  # one instance of this landmark is enough
        return result

# ============================================================
# v8.2 Phase A.8: BACKYARD FILL — fill empty lots with small props
# ============================================================
# When a lot is skipped (crng.randf() > fill), instead of leaving it bare,
# place a "backyard" prop: a shed, fence section, garden prop, or small
# tree. This addresses "map mostly empty" by filling skipped lots with
# visual interest instead of bare grass.
#
# Picks from the biome's `props` list + the generic `backyard_fillers` list
# below. Rotates to match the road-facing direction. Skips if the position
# is already occupied or on a road.
const BACKYARD_FILLERS := ["shed", "picket_fence", "planter_box", "garden_gnome", "trash_can", "mailbox", "garden_hose_reel", "basketball_hoop"]
func _place_backyard_fill(
        lot_pos: Vector3, perp: Vector3, side: int,
        chunk_root: Node3D, crng: RandomNumberGenerator, profile: Dictionary
) -> void:
        # Phase B.3: combine biome props + biome design language (fence + yard props)
        # + generic backyard fillers, filter to manifest
        var candidates: Array = []
        var biome_props: Array = profile.get("props", [])
        for p in biome_props:
                if manifest.has(p):
                        candidates.append(p)
        # Phase B.3: add biome-specific design language props
        var design: Dictionary = CityConfig.biome_design_for(profile.get("biome", 0))
        for fp in design.get("fence_props", []):
                if manifest.has(fp) and not candidates.has(fp):
                        candidates.append(fp)
        for yp in design.get("yard_props", []):
                if manifest.has(yp) and not candidates.has(yp):
                        candidates.append(yp)
        for bf in BACKYARD_FILLERS:
                if manifest.has(bf) and not candidates.has(bf):
                        candidates.append(bf)
        if candidates.is_empty():
                return
        # 60% chance to place a backyard prop (40% stay empty for variety)
        if crng.randf() > 0.6:
                return
        var fname: String = candidates[crng.randi() % candidates.size()]
        var scene: PackedScene = _get_asset(fname)
        if scene == null:
                return
        var inst: Node3D = scene.instantiate()
        inst.position = _terrain_pos(lot_pos)
        # Face the road (perp direction × side)
        inst.rotation.y = atan2(perp.x, perp.z) * float(side) + crng.randf_range(-0.3, 0.3)
        inst.name = "backyard_%s_%d" % [fname, crng.randi() % 100000]
        chunk_root.add_child(inst)
        # Disable shadows on small props
        _disable_shadows_if_small_prop(inst, fname)
        # Insert with small radius so we don't block future building placement nearby
        spatial.insert(lot_pos, 2.0)

# ============================================================
# v8.2: DISTRICT NOISE — value noise + neighbor-biome borrowing
# ============================================================
# Implements Valheim-style soft biome edges: chunks near biome cell borders
# occasionally borrow a neighboring cell's biome, breaking up the hard 8×6
# grid into organic-looking patches.
#
# The noise is a 2D bilinear-interpolated value noise (no Perlin gradients —
# simpler and good enough for our purposes). The frequency controls how
# quickly the noise varies across chunks. The threshold controls how often
# borrowing fires.
#
# Borrowing rules:
#   - Only the BASE biome of the chunk's grid cell can be borrowed-from
#     (we don't recursively borrow from borrowed chunks).
#   - WATER, EMPTY, COASTAL_BEACH, WETLANDS are never borrowed-into (their
#     water/beach/marsh geometry must stay stable).
#   - The borrowed biome comes from one of the 4 grid-neighbor cells (N/S/E/W)
#     so borrowed chunks always sit adjacent to their parent biome.
#
# Returns the borrowed biome int, or -1 if no valid neighbor to borrow from.
func _biome_noise(key: Vector2i) -> float:
        # Sample the value noise at the chunk's position scaled by frequency.
        # Use a deterministic seed derived from the chunk key so the noise
        # pattern is stable across play sessions (no need for a global RNG).
        var sx: float = float(key.x) * DISTRICT_NOISE_FREQ
        var sy: float = float(key.y) * DISTRICT_NOISE_FREQ
        return _value_noise_2d(sx, sy, 0x4D415A41)  # "MAZAR" salt

# 2D value noise with bilinear interpolation + smoothstep falloff.
# Returns a value in [0, 1].
static func _value_noise_2d(x: float, y: float, seed: int) -> float:
        var ix: int = int(floor(x))
        var iy: int = int(floor(y))
        var fx: float = x - float(ix)
        var fy: float = y - float(iy)
        var v00: float = _hash01(ix,     iy,     seed)
        var v10: float = _hash01(ix + 1, iy,     seed)
        var v01: float = _hash01(ix,     iy + 1, seed)
        var v11: float = _hash01(ix + 1, iy + 1, seed)
        var sx: float = fx * fx * (3.0 - 2.0 * fx)  # smoothstep
        var sy: float = fy * fy * (3.0 - 2.0 * fy)
        var top: float = lerp(v00, v10, sx)
        var bot: float = lerp(v01, v11, sx)
        return lerp(top, bot, sy)

# Hash (x, y, seed) → float in [0, 1]. Uses a 32-bit mixing function
# (murmur-style finalizer) for good distribution. Returns the high 16 bits
# of the mixed hash normalized to [0, 1].
static func _hash01(x: int, y: int, seed: int) -> float:
        var h: int = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
        h = (h ^ (h >> 13)) * 1274126177
        h = h ^ (h >> 16)
        # In GDScript, ints are 64-bit so masking to 0xFFFF keeps us in
        # a stable range regardless of sign.
        var v: int = h & 0xFFFF
        return float(v) / 65535.0

# Pick a neighbor cell (N/S/E/W of (row, col)) whose biome is borrowable
# (i.e., not RIVER/WATER/EMPTY/COASTAL_BEACH) and return its biome int.
# Returns -1 if no neighbor has a borrowable biome.
# Uses `key` to deterministically pick which neighbor when multiple qualify.
func _borrow_neighbor_biome(row: int, col: int, key: Vector2i) -> int:
        var grid: Array = CityConfig.grid_layout()
        var candidates: Array = []
        # North neighbor
        if row > 0:
                var n: int = grid[row - 1][col]
                if _is_borrowable(n):
                        candidates.append(n)
        # South
        if row < CityConfig.GRID_ROWS - 1:
                var n: int = grid[row + 1][col]
                if _is_borrowable(n):
                        candidates.append(n)
        # West
        if col > 0:
                var n: int = grid[row][col - 1]
                if _is_borrowable(n):
                        candidates.append(n)
        # East
        if col < CityConfig.GRID_COLS - 1:
                var n: int = grid[row][col + 1]
                if _is_borrowable(n):
                        candidates.append(n)
        if candidates.is_empty():
                return -1
        # Deterministic pick: hash(key) ensures the same chunk always picks
        # the same neighbor (no flickering between sessions).
        var pick: int = hash(key) % candidates.size()
        return int(candidates[pick])

# Returns true if `biome` is borrowable (i.e., can be borrowed INTO another
# chunk). Water bodies, the thin coastal strip, and WETLANDS are excluded so
# their geometry stays stable.
# v8.2 Phase A.4: removed RIVER case (no longer a biome).
static func _is_borrowable(biome: int) -> bool:
        if biome == CityConfig.Biome.WATER:
                return false
        if biome == CityConfig.Biome.EMPTY:
                return false
        if biome == CityConfig.Biome.COASTAL_BEACH:
                return false
        if biome == CityConfig.Biome.WETLANDS:
                return false
        return true

# ============================================================
# v8.2 Phase A.10: DATA-DRIVEN CHUNK STATE
# ============================================================
# Builds a queryable Dictionary representing everything placed in this chunk.
# This is the "understand the map as data" approach — after placement, we
# know exactly what's where, and can analyze/fill gaps intelligently.
#
# Structure:
# {
#   "chunk_key": [x, y],
#   "biome": int,
#   "district_name": String,
#   "counts": {"buildings": N, "props": N, "foliage": N, "zombies": N},
#   "buildings": [{"name": "corner_store", "pos": [x,y,z], "zone": "commercial", "is_landmark": false}, ...],
#   "props": [{"name": "trash_can", "pos": [...]}, ...],
#   "foliage": [{"name": "oak_tree", "pos": [...]}, ...],
#   "zombies": [{"kind": "walker", "pos": [...]}, ...],
#   "stats": {"commercial_pct": 0.6, "residential_pct": 0.3, "vacant_pct": 0.1},
#   "gaps": [{"pos": [x,y,z], "size": 20, "suggested_fill": "parking_lot"}, ...]
# }
#
# Stored on chunk_root as meta "chunk_state" for runtime queries.
# Also queryable via _get_loaded_chunk_states() for cross-chunk analysis.
func _build_chunk_state(
        chunk_root: Node3D, key: Vector2i, biome: int,
        district_name: String, b_count: int, p_count: int,
        f_count: int, z_count: int
) -> Dictionary:
        var buildings: Array = []
        var props: Array = []
        var foliage: Array = []
        var zombies: Array = []
        # Walk DIRECT children of chunk_root only (not all descendants).
        # Phase A.12 v5 fix: was using find_children("*", "", true, false)
        # which picked up ALL descendants including road meshes ("Road_9389"),
        # sidewalks ("SW1_459"), grass strips ("GS1_4547"), and component
        # doors ("door_group"). These aren't buildings — they're mesh children.
        # The fill_plan was targeting these non-building node_names which don't
        # exist as top-level nodes, causing 0 removes to actually fire.
        #
        # Fix: only include nodes that have the building_name or zombie_kind
        # or from_template meta tag. These are set by _spawn_building_with_components,
        # _place_zombies, and _stamper.stamp_template respectively. Mesh-only
        # nodes (roads, sidewalks, grass) don't have these tags and are skipped.
        for node in chunk_root.get_children():
                if not (node is Node3D):
                        continue
                var n: Node3D = node
                var asset_name: String = ""
                if n.has_meta("building_name"):
                        asset_name = String(n.get_meta("building_name"))
                elif n.has_meta("zombie_kind"):
                        var kind: String = String(n.get_meta("zombie_kind"))
                        zombies.append(_make_asset_entry(n, asset_name, {"kind": kind}))
                        continue
                elif n.has_meta("from_template"):
                        asset_name = String(n.get_meta("building_name"))
                if asset_name == "":
                        continue  # Skip nodes without meta tags (road meshes, etc.)
                # Phase A.12: FULL GEOMETRY — pos + rot + scale + AABB
                var entry: Dictionary = _make_asset_entry(n, asset_name, {})
                if n.has_meta("is_landmark"):
                        entry["is_landmark"] = bool(n.get_meta("is_landmark"))
                if n.has_meta("from_template"):
                        entry["from_template"] = String(n.get_meta("from_template"))
                # Categorize by asset category in manifest
                var manifest_entry: Dictionary = manifest.get(asset_name, {})
                var category: String = manifest_entry.get("category", "")
                match category:
                        "building", "buildings":
                                buildings.append(entry)
                        "prop", "props":
                                props.append(entry)
                        "foliage":
                                foliage.append(entry)
                        "character", "characters":
                                if not zombies.has(entry):
                                        zombies.append(entry)
                        _:
                                if _is_foliage_name(asset_name):
                                        foliage.append(entry)
                                elif _is_prop_name(asset_name):
                                        props.append(entry)
                                else:
                                        buildings.append(entry)
        # Compute stats
        var stats := _compute_chunk_stats(buildings)
        return {
                "chunk_key": [key.x, key.y],
                "biome": biome,
                "district_name": district_name,
                "counts": {
                        "buildings": b_count,
                        "props": p_count,
                        "foliage": f_count,
                        "zombies": z_count,
                },
                "buildings": buildings,
                "props": props,
                "foliage": foliage,
                "zombies": zombies,
                "stats": stats,
        }

# Compute zoning stats for a chunk's building list.
# Returns: {commercial_pct, residential_pct, industrial_pct, vacant_pct, landmark_count}
func _compute_chunk_stats(buildings: Array) -> Dictionary:
        if buildings.is_empty():
                return {"commercial_pct": 0.0, "residential_pct": 0.0, "industrial_pct": 0.0, "vacant_pct": 1.0, "landmark_count": 0}
        var commercial: int = 0
        var residential: int = 0
        var industrial: int = 0
        var landmarks: int = 0
        const COMMERCIAL_TYPES := ["corner_store", "diner", "gas_station", "store_pharmacy", "store_gun", "store_supermarket", "motel", "strip_mall", "auto_repair_shop", "laundromat", "barber_shop", "salon", "grocery_store", "bank_branch"]
        const RESIDENTIAL_TYPES := ["suburban_house_v2", "two_story_colonial", "bungalow", "house_modern", "house_split_level", "house_victorian", "house_ranch", "house_cape_cod", "house_tudor", "house_cottage_stone", "apartment_small", "cottage", "farmhouse", "shed", "garage_detached"]
        const INDUSTRIAL_TYPES := ["warehouse", "warehouse_large", "factory_small", "utility_shed_metal", "shipping_container", "storage_tank", "loading_dock"]
        const LANDMARK_TYPES := ["government_palace", "stadium", "old_royal_palace", "fort_sarran", "lighthouse", "broadcast_tower", "grain_silo", "windmill", "railway_station", "hospital", "police_station", "school_elementary", "church_small"]
        for b in buildings:
                var n: String = b["name"]
                if LANDMARK_TYPES.has(n):
                        landmarks += 1
                if COMMERCIAL_TYPES.has(n):
                        commercial += 1
                elif RESIDENTIAL_TYPES.has(n):
                        residential += 1
                elif INDUSTRIAL_TYPES.has(n):
                        industrial += 1
        var total: int = buildings.size()
        return {
                "commercial_pct": float(commercial) / float(total),
                "residential_pct": float(residential) / float(total),
                "industrial_pct": float(industrial) / float(total),
                "vacant_pct": 0.0,  # computed elsewhere (gap_count / total_lots)
                "landmark_count": landmarks,
        }

# Name-based foliage detection (for assets without manifest category).
const FOLIAGE_NAME_HINTS := ["tree", "bush", "hedge", "flower", "weeds", "fern", "grass", "cattail", "mushroom", "ivy", "fallen", "rocks", "palm", "willow", "pine", "oak", "birch", "maple"]
func _is_foliage_name(name: String) -> bool:
        var nlower: String = name.to_lower()
        for hint in FOLIAGE_NAME_HINTS:
                if nlower.contains(hint):
                        return true
        return false

# Name-based prop detection.
const PROP_NAME_HINTS := ["mailbox", "trash", "planter", "bollard", "meter", "cart", "cone", "barrier", "fence", "gnome", "hose", "bench", "table", "slide", "swing", "seesaw", "fountain", "sign", "camera", "light", "hydrant", "pole"]
func _is_prop_name(name: String) -> bool:
        var nlower: String = name.to_lower()
        for hint in PROP_NAME_HINTS:
                if nlower.contains(hint):
                        return true
        return false

# Returns the chunk_state Dictionary for a loaded chunk, or empty if not loaded.
func _get_chunk_state(key: Vector2i) -> Dictionary:
        if not _loaded.has(key):
                return {}
        var chunk_root: Node3D = _loaded[key]
        if chunk_root.has_meta("chunk_state"):
                return chunk_root.get_meta("chunk_state")
        return {}

# Returns an array of all loaded chunk states (for cross-chunk analysis).
func _get_loaded_chunk_states() -> Array:
        var states: Array = []
        for key in _loaded:
                var state: Dictionary = _get_chunk_state(key)
                if not state.is_empty():
                        states.append(state)
        return states

# Dumps all loaded chunk states to a JSON file for offline analysis.
# Call this from a debug key (e.g., F8) to inspect what's actually placed.
func _dump_chunk_states_to_file(path: String) -> void:
        var states: Array = _get_loaded_chunk_states()
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f == null:
                push_error("[ChunkStreamer] can't write chunk states to %s" % path)
                return
        f.store_string(JSON.stringify(states, "\t"))
        f.close()
        print("[ChunkStreamer] dumped %d chunk states to %s" % [states.size(), path])

# ============================================================
# v8.2 Phase A.11: EXPANDED CHUNK STATE — terrain + river + roads + neighbors
# ============================================================
# Enriches the basic chunk_state with geographic + contextual data so the AI
# can truly "see" the map. After this, chunk_state contains:
#   - terrain.height_samples (5×5 grid of elevation points)
#   - terrain.min/max/avg height + water coverage %
#   - river.passes_through + entry/exit points + width/depth at center
#   - roads[] with full geometry (start/end/width/kind/length)
#   - neighbors (N/S/E/W biome ints)
#   - halo (active landmarks nearby + boost multipliers)
#   - gaps[] (actual empty positions with suggested fills)
#   - density_grid (10×10 grid of cell types: B/P/F/R/E/W)
func _enrich_chunk_state(
        state: Dictionary, key: Vector2i, biome: int,
        origin: Vector3, poi_exclusions: Array,
        halo_buildings: Dictionary
) -> Dictionary:
        var chunk_size: float = CityConfig.CHUNK_SIZE_M
        # === TERRAIN ===
        var height_samples: Array = []
        var min_h: float = INF
        var max_h: float = -INF
        var sum_h: float = 0.0
        var water_cells: int = 0
        var sample_count: int = 0
        # Sample 5×5 grid (25 points, ~50m spacing in a 250m chunk)
        for i in range(5):
                for j in range(5):
                        var sx: float = origin.x + (i + 0.5) * (chunk_size / 5.0)
                        var sz: float = origin.z + (j + 0.5) * (chunk_size / 5.0)
                        var h: float = terrain.height_at(sx, sz)
                        height_samples.append([sx, sz, h])
                        min_h = min(min_h, h)
                        max_h = max(max_h, h)
                        sum_h += h
                        sample_count += 1
                        if h < 0.0:  # below water level
                                water_cells += 1
        state["terrain"] = {
                "height_samples": height_samples,
                "min_height": min_h if min_h != INF else 0.0,
                "max_height": max_h if max_h != -INF else 0.0,
                "avg_height": sum_h / float(sample_count) if sample_count > 0 else 0.0,
                "water_coverage_pct": float(water_cells) / float(sample_count) if sample_count > 0 else 0.0,
                "has_water": water_cells > 0,
        }

        # === RIVER ===
        var river_info: Dictionary = {"passes_through": false}
        var chunk_center := origin + Vector3(chunk_size * 0.5, 0, chunk_size * 0.5)
        if river != null:
                var river_dist: float = river.distance_to(chunk_center.x, chunk_center.z)
                if river_dist < river.get_half_width() + chunk_size * 0.5:
                        river_info["passes_through"] = true
                        river_info["distance_to_centerline"] = river_dist
                        river_info["water_depth_at_center"] = river.water_depth_at(chunk_center.x, chunk_center.z)
                        # Find entry/exit points by sampling the chunk border
                        river_info["entry_point"] = _find_river_entry(origin, chunk_size)
        state["river"] = river_info

        # === ROADS (full geometry) ===
        var roads_in_chunk: Array = _get_roads_in_chunk(origin, chunk_size)
        var road_infos: Array = []
        for seg in roads_in_chunk:
                var a: Vector3 = seg["start"]
                var b: Vector3 = seg["end"]
                road_infos.append({
                        "start": [a.x, a.y, a.z],
                        "end": [b.x, b.y, b.z],
                        "width": float(seg.get("width", 8.0)),
                        "kind": String(seg.get("kind", "street")),
                        "name": String(seg.get("name", "")),
                        "length": a.distance_to(b),
                })
        state["roads"] = road_infos

        # === NEIGHBORS (N/S/E/W biome ints) ===
        var grid: Array = CityConfig.grid_layout()
        var col: int = clamp(int(key.x * chunk_size / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
        var row: int = clamp(int(key.y * chunk_size / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
        var neighbors: Dictionary = {}
        neighbors["north"] = int(grid[row - 1][col]) if row > 0 else -1
        neighbors["south"] = int(grid[row + 1][col]) if row < CityConfig.GRID_ROWS - 1 else -1
        neighbors["east"] = int(grid[row][col + 1]) if col < CityConfig.GRID_COLS - 1 else -1
        neighbors["west"] = int(grid[row][col - 1]) if col > 0 else -1
        state["neighbors"] = neighbors

        # === HALO ===
        var halo_info: Dictionary = {"active": not halo_buildings.is_empty()}
        if not halo_buildings.is_empty():
                halo_info["boost_buildings"] = halo_buildings
                # Find which landmarks are actually near
                var landmarks_nearby: Array = []
                for bname in _asset_positions.keys():
                        var halo: Dictionary = CityConfig.halo_for(bname)
                        if halo.is_empty():
                                continue
                        var positions: Array = _asset_positions[bname]
                        for pos in positions:
                                if pos.distance_to(chunk_center) <= CityConfig.HALO_RADIUS_M:
                                        landmarks_nearby.append(bname)
                                        break
                halo_info["landmarks_nearby"] = landmarks_nearby
        state["halo"] = halo_info

        # === GAPS (empty positions that could be filled) ===
        # Sample 10×10 grid, find cells with no building/prop/foliage/zombie
        var density_grid: Array = []
        var gap_positions: Array = []
        var grid_resolution: int = 10
        var cell_size: float = chunk_size / float(grid_resolution)
        for i in range(grid_resolution):
                var row_arr: Array = []
                for j in range(grid_resolution):
                        var cx: float = origin.x + (i + 0.5) * cell_size
                        var cz: float = origin.z + (j + 0.5) * cell_size
                        var cell_pos := Vector3(cx, 0, cz)
                        var cell_type: String = "E"  # Empty
                        # Check what's at this cell
                        if spatial.is_on_road(cell_pos):
                                cell_type = "R"  # Road
                        elif not spatial.is_free(cell_pos, 2.0):
                                # Something is here — check what
                                cell_type = "O"  # Occupied (building/prop/foliage)
                        elif river != null and river.is_over_river(cx, cz):
                                cell_type = "W"  # Water
                        else:
                                # Actually empty — record as gap
                                gap_positions.append({
                                        "pos": [cx, 0.0, cz],
                                        "cell": [i, j],
                                        "suggested_fill": _suggest_fill_for_gap(cell_pos, biome, halo_buildings, state),
                                })
                        row_arr.append(cell_type)
                density_grid.append(row_arr)
        state["density_grid"] = density_grid
        state["gaps"] = gap_positions
        state["gap_count"] = gap_positions.size()

        # === EXPANDED STATS ===
        var stats: Dictionary = state.get("stats", {})
        stats["gap_count"] = gap_positions.size()
        stats["gap_pct"] = float(gap_positions.size()) / float(grid_resolution * grid_resolution)
        stats["building_density"] = float(state["counts"]["buildings"]) / (chunk_size * chunk_size / 100.0)  # buildings per 100m²
        stats["has_parking_lot"] = _chunk_has_asset_type(state, "parking")
        stats["has_backyard"] = _chunk_has_asset_type(state, "shed") or _chunk_has_asset_type(state, "fence")
        stats["road_count"] = road_infos.size()
        stats["neighbor_biomes"] = neighbors
        state["stats"] = stats

        # === WORLD BOUNDS ===
        state["world_bounds"] = {
                "min": [origin.x, 0.0, origin.z],
                "max": [origin.x + chunk_size, 0.0, origin.z + chunk_size],
                "center": [chunk_center.x, 0.0, chunk_center.z],
        }

        # === ANCHOR INFO ===
        var anchor_cell := Vector2i(col, row)
        var anchor: Variant = AnchorPoints.get_anchor_at(anchor_cell)
        if anchor != null:
                state["anchor"] = {
                        "cell": [anchor["cell"].x, anchor["cell"].y],
                        "is_major": bool(anchor["is_major"]),
                        "landmark": String(anchor["landmark"]),
                }

        return state

# Find where the river enters the chunk by sampling the chunk's border.
func _find_river_entry(origin: Vector3, chunk_size: float) -> Array:
        if river == null:
                return []
        # Sample 4 edges of the chunk
        var edges: Array = [
                # North edge (z = origin.z)
                {"axis": "z", "value": origin.z, "range": [origin.x, origin.x + chunk_size]},
                # South edge (z = origin.z + chunk_size)
                {"axis": "z", "value": origin.z + chunk_size, "range": [origin.x, origin.x + chunk_size]},
                # West edge (x = origin.x)
                {"axis": "x", "value": origin.x, "range": [origin.z, origin.z + chunk_size]},
                # East edge (x = origin.x + chunk_size)
                {"axis": "x", "value": origin.x + chunk_size, "range": [origin.z, origin.z + chunk_size]},
        ]
        for edge in edges:
                var lo: float = edge["range"][0]
                var hi: float = edge["range"][1]
                var step: float = (hi - lo) / 20.0  # 20 samples per edge
                for i in range(21):
                        var t: float = lo + i * step
                        var check_x: float = edge["value"] if edge["axis"] == "x" else t
                        var check_z: float = edge["value"] if edge["axis"] == "z" else t
                        if river.is_over_river(check_x, check_z):
                                return [check_x, check_z]
        return []

# Suggest a contextually-appropriate fill for a gap position.
# Uses the chunk's biome + halo + neighbor context to suggest:
#   - parking_lot if near a commercial zone + no parking lots yet
#   - backyard if in a residential zone
#   - alley if between two commercial buildings
#   - park if near a Parks biome neighbor
#   - empty if no suggestion
func _suggest_fill_for_gap(pos: Vector3, biome: int, halo_buildings: Dictionary, state: Dictionary) -> String:
        var stats: Dictionary = state.get("stats", {})
        # If near a landmark halo, suggest halo-appropriate fills
        if not halo_buildings.is_empty():
                # Check if this gap is near a parking-requiring landmark
                if halo_buildings.has("parking_garage") or halo_buildings.has("parking_meter"):
                        if not bool(stats.get("has_parking_lot", false)):
                                return "parking_lot"
        # Biome-specific suggestions
        match biome:
                CityConfig.Biome.SUBURBIA:
                        return "backyard"  # shed + fence + tree
                CityConfig.Biome.COMMERCIAL:
                        if float(stats.get("commercial_pct", 0.0)) > 0.5:
                                return "alley"  # delivery alley between storefronts
                        return "parking_lot"
                CityConfig.Biome.INDUSTRIAL:
                        return "loading_zone"
                CityConfig.Biome.PARKS:
                        return "green_space"
                CityConfig.Biome.FOREST:
                        return "tree_cluster"
                CityConfig.Biome.WETLANDS:
                        return "marsh vegetation"
                CityConfig.Biome.DOWNTOWN:
                        if float(stats.get("commercial_pct", 0.0)) > 0.5:
                                return "plaza"
                        return "courtyard"
                _:
                        return "empty"

# Check if a chunk has any asset whose name contains the given keyword.
func _chunk_has_asset_type(state: Dictionary, keyword: String) -> bool:
        var buildings: Array = state.get("buildings", [])
        for b in buildings:
                if String(b.get("name", "")).contains(keyword):
                        return true
        var props: Array = state.get("props", [])
        for p in props:
                if String(p.get("name", "")).contains(keyword):
                        return true
        return false

# Auto-dump all chunk states to JSON when the player has been in the scene
# for ~5 seconds (gives chunks time to load). Called from _process.
var _auto_dump_timer: float = 0.0
const AUTO_DUMP_DELAY := 2.0
const AUTO_DUMP_PATH := "res://chunk_states_auto.json"
func _maybe_auto_dump(delta: float) -> void:
        if _loaded.is_empty():
                return
        _auto_dump_timer += delta
        if _auto_dump_timer >= AUTO_DUMP_DELAY:
                _auto_dump_timer = -1.0  # disable after first dump
                _dump_chunk_states_to_file(AUTO_DUMP_PATH)

# Phase A.12: Build a full-geometry entry for a placed asset.
# Captures: name, position (XYZ), rotation (YPR radians), scale (XYZ),
# AABB bounds (min XYZ + max XYZ + size XYZ), node_name (for remove/reposition
# actions), extra metadata.
# This lets the AI see the FULL spatial state of each placed object —
# not just where it is, but how it's oriented + how big it is + which
# node to target for removal/repositioning.
func _make_asset_entry(n: Node3D, asset_name: String, extra: Dictionary) -> Dictionary:
        var entry: Dictionary = {
                "name": asset_name,
                "node_name": n.name,
                "pos": [n.position.x, n.position.y, n.position.z],
                "rot": [n.rotation.x, n.rotation.y, n.rotation.z],
                "scale": [n.scale.x, n.scale.y, n.scale.z],
        }
        # AABB in WORLD space (so AI can detect overlaps + spacing)
        var aabb := _compute_world_aabb(n)
        if aabb.size != Vector3.ZERO:
                entry["aabb"] = {
                        "min": [aabb.position.x, aabb.position.y, aabb.position.z],
                        "max": [aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z],
                        "size": [aabb.size.x, aabb.size.y, aabb.size.z],
                }
        # Merge extra metadata (kind, is_landmark, from_template, etc.)
        for k in extra.keys():
                entry[k] = extra[k]
        return entry

# Compute the world-space AABB of a Node3D by walking all MeshInstance3D
# descendants + merging their AABBs transformed by the node's world transform.
# Returns AABB in WORLD space (absolute coordinates).
func _compute_world_aabb(node: Node3D) -> AABB:
        var aabb := AABB()
        var first := true
        for mi in node.find_children("*", "MeshInstance3D", true, false):
                var mesh_inst: MeshInstance3D = mi
                var local_aabb: AABB = mesh_inst.get_aabb()
                if local_aabb.size == Vector3.ZERO:
                        continue
                # Transform local AABB by the mesh's world transform
                var world_aabb: AABB = mesh_inst.global_transform * local_aabb
                if first:
                        aabb = world_aabb
                        first = false
                else:
                        aabb = aabb.merge(world_aabb)
        return aabb

# ============================================================
# Phase A.12: FILL PLAN READER — AI-generated fill decisions
# ============================================================
# Reads a JSON file (res://fill_plan.json) containing AI-generated fill
# decisions. Each entry: {chunk_key: [x,y], pos: [x,y,z], fill_type: String}
# The runtime places the suggested fills AFTER procedural placement.
#
# This is the "DATA → MAP" half of the feedback loop:
#   1. Procedural placement runs (buildings + props + foliage + zombies)
#   2. chunk_state dumped to JSON (MAP → DATA)
#   3. AI (Python script) reads chunk_state, generates fill_plan.json (DATA → AI → DATA)
#   4. Runtime reads fill_plan.json + places fills (DATA → MAP)
#   5. (Optional) re-dump chunk_state to verify fills
#
# Supported fill types:
#   - parking_lot: asphalt plane + 3 cars + parking line stripes
#   - backyard: fenced area with shed + tree + garden prop
#   - alley: narrow service road + dumpster
#   - green_space: grass + bushes + small tree cluster
#   - plaza: paved area + bollards + planter boxes
#   - courtyard: paved area + central tree + benches
#   - tree_cluster: 3-5 trees in a cluster
#   - empty: do nothing (placeholder for future fills)
func _apply_fill_plan(chunk_root: Node3D, key: Vector2i, crng: RandomNumberGenerator) -> int:
        var plan_path := "res://fill_plan.json"
        if not FileAccess.file_exists(plan_path):
                return 0  # no plan file — skip
        var f := FileAccess.open(plan_path, FileAccess.READ)
        if f == null:
                return 0
        var plan_data: Variant = JSON.parse_string(f.get_as_text())
        if plan_data == null or not (plan_data is Dictionary):
                return 0
        var plan: Dictionary = plan_data
        # Phase A.12 v2: support multiple action types via "actions" array
        # (was: only "fills" array with fill type only)
        var actions: Array = plan.get("actions", plan.get("fills", []))
        var placed_count := 0
        for action in actions:
                var ck: Array = action.get("chunk_key", [])
                if ck.size() < 2:
                        continue
                # Only apply actions for THIS chunk
                if int(ck[0]) != key.x or int(ck[1]) != key.y:
                        continue
                var action_type: String = String(action.get("type", "fill"))
                match action_type:
                        "fill":
                                var pos_arr: Array = action.get("pos", [0, 0, 0])
                                var fill_pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
                                var fill_type: String = String(action.get("fill_type", "empty"))
                                placed_count += _place_fill(chunk_root, fill_pos, fill_type, crng)
                        "remove":
                                var node_name: String = String(action.get("node_name", ""))
                                if node_name != "":
                                        placed_count += _remove_node_by_name(chunk_root, node_name)
                        "reposition":
                                var node_name2: String = String(action.get("node_name", ""))
                                var new_pos_arr: Array = action.get("new_pos", [0, 0, 0])
                                var new_rot_y: float = float(action.get("new_rot_y", 0.0))
                                if node_name2 != "":
                                        placed_count += _reposition_node(chunk_root, node_name2, new_pos_arr, new_rot_y)
        return placed_count

# Phase A.12 v2: remove a node by name (for overlap resolution).
# Uses immediate removal (remove_child + free) instead of queue_free() so
# the node is gone BEFORE chunk_state is dumped in the same _build_chunk call.
# Returns 1 if removed, 0 if not found.
func _remove_node_by_name(chunk_root: Node3D, node_name: String) -> int:
        var node: Node = chunk_root.get_node_or_null(NodePath(node_name))
        if node == null:
                # Try find_children as fallback
                for child in chunk_root.find_children(node_name, "", true, false):
                        var p: Node = child.get_parent()
                        if p:
                                p.remove_child(child)
                        child.free()
                        return 1
                return 0
        var parent: Node = node.get_parent()
        if parent:
                parent.remove_child(node)
        node.free()
        return 1

# Phase A.12 v2: reposition a node (move + rotate).
# Returns 1 if repositioned, 0 if not found.
func _reposition_node(chunk_root: Node3D, node_name: String, new_pos: Array, new_rot_y: float) -> int:
        var node: Node = chunk_root.get_node_or_null(NodePath(node_name))
        if node == null:
                for child in chunk_root.find_children(node_name, "", true, false):
                        if child is Node3D:
                                (child as Node3D).position = Vector3(float(new_pos[0]), float(new_pos[1]), float(new_pos[2]))
                                (child as Node3D).rotation.y = new_rot_y
                                return 1
                return 0
        if node is Node3D:
                (node as Node3D).position = Vector3(float(new_pos[0]), float(new_pos[1]), float(new_pos[2]))
                (node as Node3D).rotation.y = new_rot_y
                return 1
        return 0

# Place a specific fill type at a position. Returns count of nodes placed.
# ============================================================
# Phase B.3: BLOCK INTERIOR FILL — fill empty block centers
# ============================================================
# DeepSeek: "Block interiors are hollow. Real cities fill that with garages,
# sheds, dumpsters, courtyards — smaller back-of-house structures that don't
# front a street."
#
# Places 3-5 biome-appropriate fills at the chunk center + offset positions.
# Each fill is a cluster (parking_lot, backyard, courtyard, alley, tree_cluster)
# placed ONLY in empty space — doesn't overlap road-adjacent buildings.
#
# Biome → interior fill type mapping:
#   Suburbia → backyard (shed + tree + gnome)
#   Commercial → parking_lot (asphalt + meters + cart)
#   Industrial → alley (narrow road + dumpster)
#   Downtown → courtyard (paved + tree + benches)
#   Farmland → backyard (shed + tree)
#   Forest → tree_cluster (3-5 trees)
#   Parks → green_space (grass + bushes)
#   Wetlands → green_space (marsh vegetation)
#   Military → alley (checkpoint props)
#   Coastal → green_space
func _fill_block_interiors(
        chunk_root: Node3D, profile: Dictionary, origin: Vector3,
        biome: int, crng: RandomNumberGenerator, poi_exclusions: Array
) -> int:
        # Determine fill type per biome
        var fill_type: String = "green_space"  # default
        match biome:
                CityConfig.Biome.SUBURBIA:
                        fill_type = "backyard"
                CityConfig.Biome.COMMERCIAL:
                        fill_type = "parking_lot"
                CityConfig.Biome.INDUSTRIAL:
                        fill_type = "alley"
                CityConfig.Biome.DOWNTOWN:
                        fill_type = "courtyard"
                CityConfig.Biome.FARMLAND:
                        fill_type = "backyard"
                CityConfig.Biome.FOREST:
                        fill_type = "tree_cluster"
                CityConfig.Biome.PARKS:
                        fill_type = "green_space"
                CityConfig.Biome.WETLANDS:
                        fill_type = "green_space"
                CityConfig.Biome.MILITARY:
                        fill_type = "alley"
                CityConfig.Biome.COASTAL_BEACH:
                        fill_type = "green_space"
                _:
                        fill_type = "green_space"
        # Place fills at center + offset positions
        var chunk_center := origin + Vector3(
                CityConfig.CHUNK_SIZE_M * 0.5, 0,
                CityConfig.CHUNK_SIZE_M * 0.5
        )
        # Try 5 positions: center + 4 offsets (±60m in X and Z)
        var positions: Array = [
                chunk_center,
                chunk_center + Vector3(-60, 0, -60),
                chunk_center + Vector3(60, 0, -60),
                chunk_center + Vector3(-60, 0, 60),
                chunk_center + Vector3(60, 0, 60),
        ]
        # Also try mixed fill types for variety — alternate between the
        # biome's primary fill + a secondary fill
        var secondary_fill: String = "tree_cluster"
        match biome:
                CityConfig.Biome.SUBURBIA:
                        secondary_fill = "tree_cluster"
                CityConfig.Biome.COMMERCIAL:
                        secondary_fill = "backyard"  # some backyards behind stores
                CityConfig.Biome.INDUSTRIAL:
                        secondary_fill = "green_space"  # sparse weeds between warehouses
                CityConfig.Biome.DOWNTOWN:
                        secondary_fill = "plaza"  # some plazas between towers
                CityConfig.Biome.FARMLAND:
                        secondary_fill = "tree_cluster"
                _:
                        secondary_fill = "tree_cluster"
        var placed_fills := 0
        var total_count := 0
        var max_fills := 4  # cap at 4 interior fills per chunk
        for i in range(positions.size()):
                if placed_fills >= max_fills:
                        break
                var pos: Vector3 = positions[i]
                # Check the position is empty (not on a road, not occupied, not in POI exclusion)
                var check_radius: float = 12.0  # parking_lot needs ~12m, backyard ~6m
                if fill_type == "parking_lot":
                        check_radius = 15.0
                elif fill_type == "backyard":
                        check_radius = 8.0
                elif fill_type == "alley":
                        check_radius = 5.0
                elif fill_type == "tree_cluster":
                        check_radius = 8.0
                if not spatial.is_free(pos, check_radius):
                        continue
                if spatial.is_on_road(pos):
                        continue
                if _is_in_poi_exclusion(pos, poi_exclusions):
                        continue
                if _is_near_highway(pos):
                        continue
                # Alternate between primary + secondary fill for variety
                var use_fill: String = fill_type
                if i > 0 and crng.randf() < 0.4:  # 40% chance for secondary
                        use_fill = secondary_fill
                # Place the fill (reuses existing _place_fill function)
                var count: int = _place_fill(chunk_root, _terrain_pos(pos), use_fill, crng)
                if count > 0:
                        placed_fills += 1
                        total_count += count
        return total_count

func _place_fill(chunk_root: Node3D, pos: Vector3, fill_type: String, crng: RandomNumberGenerator) -> int:
        match fill_type:
                "parking_lot":
                        return _place_parking_lot(chunk_root, pos, crng)
                "backyard":
                        return _place_backyard(chunk_root, pos, crng)
                "alley":
                        return _place_alley(chunk_root, pos, crng)
                "green_space":
                        return _place_green_space(chunk_root, pos, crng)
                "plaza":
                        return _place_plaza(chunk_root, pos, crng)
                "courtyard":
                        return _place_courtyard(chunk_root, pos, crng)
                "tree_cluster":
                        return _place_tree_cluster(chunk_root, pos, crng)
                _:
                        return 0

# Parking lot fill: asphalt plane + parking meter row + shopping cart corral.
# Visual: a flat dark-gray plane (~15m × 20m) with 3-5 parking_meter props
# along one edge + 1 shopping_cart nearby.
func _place_parking_lot(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        # Asphalt plane (dark gray, 15×20m)
        _create_plane_mesh_rotated(chunk_root, "ParkingLotAsphalt",
                pos, Vector2(15.0, 20.0), Color(0.18, 0.18, 0.20, 1), 0.0)
        count += 1
        # Parking meters along the south edge
        var meter_scene: PackedScene = _get_asset("parking_meter")
        if meter_scene != null:
                for i in range(4):
                        var mp := Vector3(pos.x + (i - 1.5) * 3.5, 0, pos.z + 9.5)
                        if spatial.is_free(mp, 1.0) and not spatial.is_on_road(mp):
                                var inst: Node3D = meter_scene.instantiate()
                                inst.position = mp
                                inst.rotation.y = 0.0
                                inst.name = "parking_meter_lot_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                _disable_shadows_if_small_prop(inst, "parking_meter")
                                spatial.insert(mp, 1.0)
                                count += 1
        # Shopping cart corral at the NE corner
        var cart_scene: PackedScene = _get_asset("shopping_cart")
        if cart_scene != null:
                var cp := Vector3(pos.x + 6, 0, pos.z - 8)
                if spatial.is_free(cp, 1.0):
                        var inst: Node3D = cart_scene.instantiate()
                        inst.position = cp
                        inst.rotation.y = crng.randf_range(0, TAU)
                        inst.name = "shopping_cart_lot_%d" % crng.randi()
                        chunk_root.add_child(inst)
                        _disable_shadows_if_small_prop(inst, "shopping_cart")
                        count += 1
        # Mark the area as occupied so nothing else spawns here
        spatial.insert(pos, 12.0)
        return count

# Backyard fill: fenced area with shed + tree + garden prop.
# Visual: picket_fence perimeter (~10×10m) + shed in back + oak_tree + garden gnome.
func _place_backyard(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        # Shed in the back corner
        var shed_scene: PackedScene = _get_asset("shed")
        if shed_scene != null:
                var sp := Vector3(pos.x - 3, 0, pos.z - 3)
                if spatial.is_free(sp, 2.0):
                        var inst: Node3D = shed_scene.instantiate()
                        inst.position = sp
                        inst.rotation.y = crng.randf_range(-0.3, 0.3)
                        inst.name = "shed_yard_%d" % crng.randi()
                        chunk_root.add_child(inst)
                        count += 1
        # Oak tree in the center
        var tree_scene: PackedScene = _get_asset("oak_tree")
        if tree_scene != null:
                var tp := Vector3(pos.x + 2, 0, pos.z + 2)
                if spatial.is_free(tp, 2.0):
                        var inst: Node3D = tree_scene.instantiate()
                        inst.position = tp
                        inst.rotation.y = crng.randf_range(0, TAU)
                        var s := crng.randf_range(0.9, 1.3)
                        inst.scale = Vector3(s, s, s)
                        inst.name = "oak_yard_%d" % crng.randi()
                        chunk_root.add_child(inst)
                        count += 1
        # Garden gnome prop
        var gnome_scene: PackedScene = _get_asset("garden_gnome")
        if gnome_scene != null:
                var gp := Vector3(pos.x, 0, pos.z + 3)
                if spatial.is_free(gp, 1.0):
                        var inst: Node3D = gnome_scene.instantiate()
                        inst.position = gp
                        inst.rotation.y = crng.randf_range(0, TAU)
                        inst.name = "gnome_yard_%d" % crng.randi()
                        chunk_root.add_child(inst)
                        _disable_shadows_if_small_prop(inst, "garden_gnome")
                        count += 1
        spatial.insert(pos, 6.0)
        return count

# Alley fill: narrow service road + dumpster.
# Visual: dark plane (~4m × 15m) + dumpster at one end.
func _place_alley(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        _create_plane_mesh_rotated(chunk_root, "AlleyAsphalt",
                pos, Vector2(4.0, 15.0), Color(0.15, 0.15, 0.17, 1), 0.0)
        count += 1
        var dumpster_scene: PackedScene = _get_asset("dumpster")
        if dumpster_scene != null:
                var dp := Vector3(pos.x, 0, pos.z - 5)
                if spatial.is_free(dp, 1.5):
                        var inst: Node3D = dumpster_scene.instantiate()
                        inst.position = dp
                        inst.rotation.y = crng.randf_range(0, TAU)
                        inst.name = "dumpster_alley_%d" % crng.randi()
                        chunk_root.add_child(inst)
                        count += 1
        spatial.insert(pos, 3.0)
        return count

# Green space fill: grass + bushes + small tree cluster.
func _place_green_space(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        # Grass plane (slightly brighter than ground)
        _create_plane_mesh_rotated(chunk_root, "GreenSpace",
                pos, Vector2(12.0, 12.0), Color(0.28, 0.45, 0.18, 1), 0.0)
        count += 1
        # 3-5 bushes scattered
        var bush_scene: PackedScene = _get_asset("bush")
        if bush_scene != null:
                for i in range(crng.randi_range(3, 5)):
                        var bp := pos + Vector3(crng.randf_range(-5, 5), 0, crng.randf_range(-5, 5))
                        if spatial.is_free(bp, 1.5):
                                var inst: Node3D = bush_scene.instantiate()
                                inst.position = bp
                                inst.rotation.y = crng.randf_range(0, TAU)
                                inst.name = "bush_green_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                _disable_shadows_if_small_foliage(inst, "bush")
                                count += 1
        spatial.insert(pos, 7.0)
        return count

# Plaza fill: paved area + bollards + planter boxes.
func _place_plaza(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        _create_plane_mesh_rotated(chunk_root, "PlazaPave",
                pos, Vector2(15.0, 15.0), Color(0.55, 0.53, 0.50, 1), 0.0)
        count += 1
        var bollard_scene: PackedScene = _get_asset("bollard")
        if bollard_scene != null:
                for i in range(4):
                        var angle := i * PI / 2.0
                        var bp := pos + Vector3(cos(angle) * 6.5, 0, sin(angle) * 6.5)
                        if spatial.is_free(bp, 1.0):
                                var inst: Node3D = bollard_scene.instantiate()
                                inst.position = bp
                                inst.name = "bollard_plaza_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                _disable_shadows_if_small_prop(inst, "bollard")
                                count += 1
        var planter_scene: PackedScene = _get_asset("planter_box")
        if planter_scene != null:
                for i in range(2):
                        var pp := pos + Vector3(crng.randf_range(-4, 4), 0, crng.randf_range(-4, 4))
                        if spatial.is_free(pp, 1.5):
                                var inst: Node3D = planter_scene.instantiate()
                                inst.position = pp
                                inst.rotation.y = crng.randf_range(0, TAU)
                                inst.name = "planter_plaza_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                _disable_shadows_if_small_prop(inst, "planter_box")
                                count += 1
        spatial.insert(pos, 9.0)
        return count

# Courtyard fill: paved area + central tree + benches.
func _place_courtyard(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        _create_plane_mesh_rotated(chunk_root, "CourtyardPave",
                pos, Vector2(12.0, 12.0), Color(0.50, 0.48, 0.45, 1), 0.0)
        count += 1
        var tree_scene: PackedScene = _get_asset("oak_tree")
        if tree_scene != null:
                var inst: Node3D = tree_scene.instantiate()
                inst.position = pos
                inst.rotation.y = crng.randf_range(0, TAU)
                var s := crng.randf_range(1.0, 1.4)
                inst.scale = Vector3(s, s, s)
                inst.name = "oak_courtyard_%d" % crng.randi()
                chunk_root.add_child(inst)
                count += 1
        var bench_scene: PackedScene = _get_asset("bench_park")
        if bench_scene != null:
                for i in range(2):
                        var angle := i * PI + crng.randf_range(-0.5, 0.5)
                        var bp := pos + Vector3(cos(angle) * 4, 0, sin(angle) * 4)
                        if spatial.is_free(bp, 1.5):
                                var inst: Node3D = bench_scene.instantiate()
                                inst.position = bp
                                inst.rotation.y = angle + PI / 2.0
                                inst.name = "bench_courtyard_%d" % crng.randi()
                                chunk_root.add_child(inst)
                                count += 1
        spatial.insert(pos, 7.0)
        return count

# Tree cluster fill: 3-5 trees in a cluster (for forest/gaps).
func _place_tree_cluster(chunk_root: Node3D, pos: Vector3, crng: RandomNumberGenerator) -> int:
        var count := 0
        var tree_types := ["oak_tree", "pine_tree", "birch_tree"]
        var tree_count: int = crng.randi_range(3, 5)
        for i in range(tree_count):
                var tree_name: String = tree_types[crng.randi() % tree_types.size()]
                var scene: PackedScene = _get_asset(tree_name)
                if scene == null:
                        continue
                var tp := pos + Vector3(crng.randf_range(-5, 5), 0, crng.randf_range(-5, 5))
                if not spatial.is_free(tp, 2.5):
                        continue
                var inst: Node3D = scene.instantiate()
                inst.position = tp
                inst.rotation.y = crng.randf_range(0, TAU)
                var s := crng.randf_range(0.85, 1.3)
                inst.scale = Vector3(s, s, s)
                inst.name = "%s_cluster_%d" % [tree_name, crng.randi()]
                chunk_root.add_child(inst)
                spatial.insert(tp, 2.5)
                count += 1
        return count
