class_name CityConfig
# Mazar City Config — single source of truth for all tunable values.
# GLM: edit this file to change biomes, dimensions, or rules.
# DO NOT restructure — data only, no logic beyond the static helpers.
extends RefCounted

enum Biome {
    SUBURBIA, PARKS, FOREST, FARMLAND, COMMERCIAL,
    INDUSTRIAL, WETLANDS, DOWNTOWN, MILITARY, COASTAL_BEACH, WATER, EMPTY
}
# NOTE: Biome.SUBWAY removed 2026-09-12 (Phase A.3).
# Subway is now a parallel underground layer, not a surface biome.
# See GDD §12 "Subway-as-layer, not biome" for rationale.
# Subway assets (subway_platform, subway_tunnel, subway_train_car, etc.)
# are placed by tools/subway_network.gd when player enters a station.
#
# NOTE: Biome.RIVER removed 2026-09-13 (Phase A.4 — "River-as-feature").
# Same precedent as the Subway removal: a river is a linear geographic
# feature that can run THROUGH any surface biome, not a tileable cell.
# The river is now a polyline (control_points array) stored in
# map_data.json and queried via RiverNetwork. Bridges cross the polyline
# at declared anchor rows. The biome underneath any given river point is
# whatever the district grid says at that location (FOREST in the north,
# FARMLAND in the middle, COMMERCIAL/SUBURBIA in the south).
#
# NOTE: Biome.WETLANDS added 2026-09-13 (Phase A.4).
# Split out from old biome row #7 ("River & Wetlands / Coastal Beach"
# was a three-way conflation). Wetlands = low-elevation biome with
# cattails, marsh_grass, willow_tree, fishing_hut, marsh_pier. Kept as
# a survival source (clean water, herbs, fish) — fishing mechanics are
# future-work but the biome type needs to exist now so terrain/elevation
# can drive its placement (emergent where height < 0.5m and not in river
# channel — to be wired in a later phase).

# ── MAP DIMENSIONS ────────────────────────────────────────
# 12 km² alpha  →  Vector2(4000, 3000), GRID 8×6
# 30 km² beta   →  Vector2(6000, 5000), GRID 12×10
# 100 km² v1    →  Vector2(10000, 10000), GRID 20×20
const MAP_SIZE_M   := Vector2(4000.0, 3000.0)
const GRID_COLS    := 8
const GRID_ROWS    := 6
const CELL_SIZE_M  := MAP_SIZE_M.x / GRID_COLS
const CHUNK_SIZE_M := 250.0
const CHUNKS_COLS  := int(MAP_SIZE_M.x / CHUNK_SIZE_M)
const CHUNKS_ROWS  := int(MAP_SIZE_M.y / CHUNK_SIZE_M)

# ── PLACEMENT RULES (v3 extraction 2026-09-12) ───────────
# Tuned from retired city_builder.gd v3 prototype (user-screenshot iterations).
# See docs/retired_city_builder_v3_extraction.md §1 for provenance.
const ROAD_WIDTH          := 8.0
const SIDEWALK_WIDTH      := 1.5     # v3: was 2.0; narrower sidewalk + wider grass strip
const GRASS_STRIP_WIDTH   := 2.5     # v3 NEW: prevents tree/building clipping
const BUILDING_SETBACK     := 1.5     # v3: was 4.0; with wider lots, setback can be smaller
const LOT_WIDTH            := 20.0   # v3 NEW: wider lots = no collision between houses
const LOT_DEPTH            := 16.0   # v3 NEW: deeper lots = front/back spacing
const ROAD_LENGTH          := 160.0  # v3 NEW: length of generated road segments
const ROAD_SPACING         := 60.0   # v3 NEW: distance between parallel road centerlines
const STREETLIGHT_SPACING := 25.0    # v3: was 20m; 25m is less cluttered
const PROP_ROAD_CLEARANCE := 2.0
const SPATIAL_CELL_M      := 8.0

# Computed: building_offset = ROAD_WIDTH/2 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH + BUILDING_SETBACK
#          = 4.0 + 1.5 + 2.5 + 1.5 = 9.5m from road centerline to building face

# ── STREET FURNITURE SPACING (v3 extraction) ──────────────
const MAILBOX_SPACING       := 36.0
const TRASHCAN_SPACING      := 42.0
const UTILITY_POLE_SPACING  := 35.0
const UTILITY_POLE_OFFSET   := 2.0    # behind building (building_offset + LOT_DEPTH + 2.0)
const TREE_SPACING          := 12.0   # along grass strip
const HEDGE_SPACING         := 10.0   # along front property line
const FLOWER_PATCH_SPACING  := 25.0

# ── COLORS (v3 extraction — primitive mesh roads/sidewalks/grass) ──
const COLOR_ROAD           := Color(0.12, 0.12, 0.14, 1)
const COLOR_SIDEWALK       := Color(0.70, 0.68, 0.64, 1)
const COLOR_GRASS_STRIP    := Color(0.30, 0.50, 0.22, 1)
const COLOR_GROUND         := Color(0.22, 0.40, 0.16, 1)

# ── LIGHTING + FOG (v3 extraction — tuned for Low preset) ──
const SKY_TOP_COLOR        := Color(0.15, 0.35, 0.70, 1)
const SKY_HORIZON_COLOR    := Color(0.70, 0.78, 0.88, 1)
const GROUND_BOTTOM_COLOR  := Color(0.25, 0.22, 0.18, 1)
const GROUND_HORIZON_COLOR := Color(0.50, 0.48, 0.42, 1)
const SUN_COLOR            := Color(1.0,  0.95, 0.80, 1)
const SUN_ENERGY           := 2.0
const SUN_SHADOW_MAX_DIST  := 80.0     # v3: was 300 in main.tscn; 80 for Low preset perf
const SUN_SHADOW_SIZE      := 2048
const AMBIENT_LIGHT_COLOR  := Color(0.55, 0.60, 0.65, 1)
const AMBIENT_LIGHT_ENERGY := 0.6
const FOG_COLOR            := Color(0.50, 0.55, 0.60, 1)
const FOG_DENSITY          := 0.005    # v3: was 0.002 in main.tscn; thicker fog
const FOG_AERIAL_PERSPECTIVE := 0.4
const TONEMAP_WHITE        := 1.0
const SSAO_RADIUS          := 1.0
const SSAO_INTENSITY       := 1.2
const SUN_ANGLE_MAX        := 30.0     # ProceduralSkyMaterial
const SUN_CURVE             := 0.12    # ProceduralSkyMaterial

# ── PLAYER (v3 extraction) ───────────────────────────────
const PLAYER_EYE_HEIGHT      := 1.65
const PLAYER_RADIUS          := 0.4
const PLAYER_HEIGHT          := 1.8
const PLAYER_FOV             := 75.0
const PLAYER_CAM_NEAR        := 0.05
const PLAYER_CAM_FAR         := 200.0   # v3: was 500; 200 for fog to mask pop-in

# ── MOVEMENT (v3 extraction) ──────────────────────────────
const WALK_SPEED             := 5.0
const SPRINT_SPEED           := 8.0
const MOUSE_SENSITIVITY      := 0.002
const GRAVITY                := 9.8
const JUMP_VELOCITY           := 4.5

# ── STREAMING ─────────────────────────────────────────────
const STREAM_RADIUS      := 1
const STREAM_UNLOAD_BUFFER := 1
const CHUNK_OUTPUT_DIR   := "res://chunks/"

# ── OWNERSHIP RULES ───────────────────────────────────────
# CENTROID RULE: an object belongs to the chunk containing its center.
# ROAD OWNERSHIP: a road segment belongs to the chunk where its perpendicular
#   axis falls in [chunk_min, chunk_max). Horizontal roads → Z-chunk.
#   Vertical roads → X-chunk. Non-owner chunks still QUERY for setback math
#   but do not render or place lights on non-owned segments.

# ── BIOME PROFILES ────────────────────────────────────────
# Each biome lists buildings/props/foliage by asset name (must match
# keys in city_manifest.json). Buildings in the `landmarks` array are
# hero assets that should be placed ONE per biome — currently the
# runtime streamer treats them like regular buildings (random pick),
# but the field exists for future landmark-aware placement.
static func biomes() -> Dictionary:
    return {
        Biome.SUBURBIA: {
            "name": "Suburbia",
            "fill": 0.75,
            "buildings": [
                "suburban_house_v2", "two_story_colonial", "bungalow",
                "house_modern", "house_split_level", "house_victorian",
                "house_ranch", "house_cape_cod", "house_tudor",
                "house_cottage_stone", "treehouse"
            ],
            "landmarks": [],
            "props": [
                "mailbox", "trash_can", "picket_fence", "basketball_hoop",
                "bird_house", "garden_pergola", "traffic_camera"
            ],
            "foliage": [
                "oak_tree", "bush", "hedge", "hedge_tall",
                "maple_tree", "willow_tree", "flower_patch",
                "fallen_log", "ivy_wall"
            ],
            "lights": true,
            "zombies": 10
        },
        Biome.PARKS: {
            "name": "Parks & Greenways",
            "fill": 0.05,
            "buildings": ["gazebo"],
            "landmarks": [],
            "props": [
                "bench_park", "picnic_table", "playground_slide",
                "swing_set", "seesaw", "water_fountain", "park_sign"
            ],
            "foliage": [
                "oak_tree", "bush", "pine_tree", "birch_tree",
                "dead_tree", "flower_patch", "fern", "weeds",
                "mushrooms", "rocks_small", "fallen_log"
            ],
            "lights": false,
            "zombies": 5
        },
        Biome.FOREST: {
            "name": "Forest",
            "fill": 0.95,
            "buildings": [
                "hunting_cabin", "ranger_station", "camping_tent",
                "deer_stand", "cave_entrance", "logging_camp_shed",
                "ranger_lean_to"
            ],
            "landmarks": [],
            "props": ["campfire_ring"],
            "foliage": [
                "pine_tree", "birch_tree", "oak_tree", "dead_tree",
                "fallen_log", "rocks_small", "mushrooms", "fern",
                "weeds", "tall_grass"
            ],
            "lights": false,
            "zombies": 5
        },
        Biome.FARMLAND: {
            "name": "Farmland",
            "fill": 0.25,
            "buildings": [
                "farmhouse", "barn", "cottage", "shed",
                "garage_detached", "tractor_shed", "grain_storage_shed"
            ],
            "landmarks": ["grain_silo", "windmill"],
            "props": [
                "picket_fence", "wood_fence_post", "garden_gnome",
                "garden_hose_reel"
            ],
            "foliage": ["oak_tree", "bush", "weeds", "tall_grass"],
            "lights": false,
            "zombies": 3
        },
        Biome.COMMERCIAL: {
            "name": "Commercial Strip",
            "fill": 0.90,
            "buildings": [
                "corner_store", "diner", "gas_station", "store_pharmacy",
                "store_gun", "store_supermarket", "motel", "strip_mall",
                "auto_repair_shop", "laundromat", "barber_shop", "salon",
                "grocery_store", "bank_branch"
            ],
            "landmarks": [],
            "props": [
                "trash_can", "mailbox", "shopping_cart", "parking_meter",
                "traffic_light", "bollard", "planter_box"
            ],
            "foliage": ["hedge"],
            "lights": true,
            "zombies": 10
        },
        Biome.INDUSTRIAL: {
            "name": "Industrial Park",
            "fill": 0.60,
            "buildings": [
                "warehouse", "warehouse_large", "factory_small",
                "utility_shed_metal", "shipping_container", "storage_tank",
                "loading_dock"
            ],
            "landmarks": [],
            "props": [
                "dumpster", "traffic_cone", "construction_barrier",
                "barrier_concrete", "guard_rail", "sandbag"
            ],
            "foliage": ["weeds", "dead_tree"],
            "lights": true,
            "zombies": 8
        },
        Biome.WETLANDS: {
            "name": "Wetlands & Marshes",
            "fill": 0.10,
            "buildings": [
                "fishing_hut", "marsh_pier", "houseboat"
            ],
            "landmarks": [],
            "props": [],
            "foliage": [
                "cattail", "marsh_grass", "willow_tree", "tall_grass",
                "fern", "weeds", "rocks_small"
            ],
            "lights": false,
            "zombies": 4
        },
        Biome.COASTAL_BEACH: {
            "name": "Coastal Beach",
            "fill": 0.20,
            "buildings": [
                "fishing_hut", "pier_dock", "houseboat", "marsh_pier",
                "lighthouse"
            ],
            "landmarks": ["lighthouse"],
            "props": ["boardwalk_section"],
            "foliage": [
                "palm_tree", "marsh_grass", "cattail", "tall_grass"
            ],
            "lights": false,
            "zombies": 4
        },
        Biome.DOWNTOWN: {
            "name": "Downtown",
            "fill": 0.95,
            "buildings": [
                "apartment_small", "apartment_tower_high", "highrise_office",
                "hospital", "police_station", "parking_garage",
                "broadcast_tower", "railway_station", "school_elementary",
                "church_small"
            ],
            "landmarks": [
                "government_palace", "stadium", "old_royal_palace"
            ],
            "props": [
                "trash_can", "mailbox", "traffic_light", "parking_meter",
                "bollard", "planter_box", "street_light"
            ],
            "foliage": ["oak_tree"],
            "lights": true,
            "zombies": 15
        },
        Biome.MILITARY: {
            "name": "Military Zone",
            "fill": 0.40,
            "buildings": [
                "military_checkpoint", "watchtower", "bunker_entrance",
                "helipad", "field_hospital_tent", "helipad_control_room"
            ],
            "landmarks": ["fort_sarran"],
            "props": [
                "barbed_wire_fence", "sandbag", "traffic_cone"
            ],
            "foliage": ["weeds", "dead_tree"],
            "lights": false,
            "zombies": 15
        },
        Biome.WATER: {
            "name": "Water",
            "fill": 0.00,
            "buildings": [],
            "landmarks": [],
            "props": [],
            "foliage": [],
            "lights": false,
            "zombies": 0
        },
        Biome.EMPTY: {
            "name": "Empty",
            "fill": 0.00,
            "buildings": [],
            "landmarks": [],
            "props": [],
            "foliage": [],
            "lights": false,
            "zombies": 0
        },
    }

# ── GRID LAYOUT (8×6 for 12 km²) ──────────────────────────
# Phase A.4 (2026-09-13): RIVER removed from grid (now a polyline overlay).
# Column 4 (was RIVER) redistributed — each row's col 4 now matches the
# dominant biome of that row's col 3 / col 5 context, so the river polyline
# (which still runs roughly through x≈2250) crosses biomes organically:
#   row 0 (north forest):     col 4 = FOREST
#   row 1 (north farmland):    col 4 = FARMLAND
#   row 2 (transition):        col 4 = FARMLAND
#   row 3 (commercial edge):   col 4 = COMMERCIAL
#   row 4 (commercial south):  col 4 = COMMERCIAL
#   row 5 (suburbia south):    col 4 = SUBURBIA
# This matches GDD §2.12 lore: "Sarran River flows from the northern forest
# through the farmland and into Sarran Bay." The bay is at column 5
# (COASTAL_BEACH) — the river exits the south edge of the map into the bay.
static func grid_layout() -> Array:
    var F  := Biome.FOREST
    var FA := Biome.FARMLAND
    var IN := Biome.INDUSTRIAL
    var MI := Biome.MILITARY
    var SU := Biome.SUBURBIA
    var PA := Biome.PARKS
    var CO := Biome.COMMERCIAL
    var DT := Biome.DOWNTOWN
    var CB := Biome.COASTAL_BEACH
    return [
        [F,  F,  FA, FA, F,  CB, IN, IN],
        [F,  FA, FA, FA, FA, CB, IN, MI],
        [SU, SU, FA, PA, FA, CB, DT, MI],
        [SU, SU, CO, PA, CO, CB, DT, IN],
        [SU, PA, CO, CO, CO, CB, DT, IN],
        [PA, SU, SU, CO, SU, CB, IN, IN],
    ]

static func bridges() -> Array:
    # Phase A.4: bridges still declared in row/col format because they're
    # grid-aligned horizontal segments. They cross the river polyline
    # wherever the polyline happens to be at that row's Z.
    # The polyline is designed so its X at z=1750 (row 3 anchor) and z=2250
    # (row 4 anchor) falls within [from_col*500, (to_col+1)*500).
    # See map_data.json `river.control_points` for the polyline geometry.
    return [
        {"row":3, "from_col":3, "to_col":5, "name":"Sarran Bridge"},
        {"row":4, "from_col":3, "to_col":5, "name":"Old Town Bridge"},
    ]

static func sky_colors() -> Dictionary:
    return {
        "top":     Color(0.35, 0.55, 0.85),
        "horizon": Color(0.85, 0.80, 0.70),
        "ground":  Color(0.20, 0.20, 0.22),
        "fog":     Color(0.72, 0.72, 0.75),
        "sun_rot": Vector3(-45, 30, 0),
    }
