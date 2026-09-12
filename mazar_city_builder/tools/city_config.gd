class_name CityConfig
# Mazar City Config — single source of truth for all tunable values.
# GLM: edit this file to change biomes, dimensions, or rules.
# DO NOT restructure — data only, no logic beyond the static helpers.
extends RefCounted

enum Biome {
    SUBURBIA, PARKS, FOREST, FARMLAND, COMMERCIAL,
    INDUSTRIAL, RIVER, SUBWAY, DOWNTOWN, MILITARY, WATER, EMPTY
}

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

# ── PLACEMENT RULES ───────────────────────────────────────
const ROAD_WIDTH          := 8.0
const SIDEWALK_WIDTH      := 2.0
const BUILDING_SETBACK    := 4.0
const STREETLIGHT_SPACING := 25.0
const PROP_ROAD_CLEARANCE := 2.0
const SPATIAL_CELL_M      := 8.0

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
        Biome.RIVER: {
            "name": "River & Wetlands",
            "fill": 0.15,
            "buildings": [
                "fishing_hut", "pier_dock", "houseboat", "marsh_pier"
            ],
            "landmarks": ["lighthouse", "bridge_section"],
            "props": [],
            "foliage": [
                "cattail", "marsh_grass", "willow_tree", "palm_tree",
                "tall_grass"
            ],
            "lights": false,
            "zombies": 4
        },
        Biome.SUBWAY: {
            "name": "Subway",
            "fill": 0.00,
            "buildings": [
                "subway_platform", "subway_tunnel", "subway_train_car",
                "ticket_booth", "turnstile", "maintenance_tunnel_junction",
                "emergency_exit_stairs", "subway_pipe_cluster"
            ],
            "landmarks": [],
            "props": [],
            "foliage": [],
            "lights": false,
            "zombies": 8
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
static func grid_layout() -> Array:
    var F  := Biome.FOREST
    var FA := Biome.FARMLAND
    var IN := Biome.INDUSTRIAL
    var MI := Biome.MILITARY
    var RI := Biome.RIVER
    var SU := Biome.SUBURBIA
    var PA := Biome.PARKS
    var CO := Biome.COMMERCIAL
    var DT := Biome.DOWNTOWN
    return [
        [F,  F,  FA, FA, RI, RI, IN, IN],
        [F,  FA, FA, FA, RI, RI, IN, MI],
        [SU, SU, FA, PA, RI, RI, DT, MI],
        [SU, SU, CO, PA, RI, RI, DT, IN],
        [SU, PA, CO, CO, RI, RI, DT, IN],
        [PA, SU, SU, CO, RI, RI, IN, IN],
    ]

static func bridges() -> Array:
    return [
        {"row":4, "from_col":4, "to_col":7, "name":"Sarran Bridge"},
        {"row":5, "from_col":4, "to_col":7, "name":"Old Town Bridge"},  # was row=6 (off-by-one, GRID_ROWS=6 means rows 0..5)
    ]

static func sky_colors() -> Dictionary:
    return {
        "top":     Color(0.35, 0.55, 0.85),
        "horizon": Color(0.85, 0.80, 0.70),
        "ground":  Color(0.20, 0.20, 0.22),
        "fog":     Color(0.72, 0.72, 0.75),
        "sun_rot": Vector3(-45, 30, 0),
    }
