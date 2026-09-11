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
static func biomes() -> Dictionary:
    return {
        Biome.SUBURBIA:   {"name":"Suburbia",         "fill":0.55, "buildings":["suburban_house_v2","two_story_colonial","bungalow","house_modern","house_split_level"], "props":["mailbox","trash_can","picket_fence"], "foliage":["oak_tree","bush"],       "lights":true,  "zombies":10},
        Biome.PARKS:      {"name":"Parks & Greenways", "fill":0.20, "buildings":[], "props":[], "foliage":["oak_tree","bush"],                                          "lights":false, "zombies":5},
        Biome.FOREST:     {"name":"Forest",            "fill":0.85, "buildings":["shed"], "props":[], "foliage":["pine_tree","birch_tree","bush"],                 "lights":false, "zombies":5},
        Biome.FARMLAND:   {"name":"Farmland",          "fill":0.35, "buildings":["shed","garage_detached"], "props":["picket_fence"], "foliage":["oak_tree","bush"],   "lights":false, "zombies":3},
        Biome.COMMERCIAL: {"name":"Commercial Strip",  "fill":0.75, "buildings":["two_story_colonial"], "props":["trash_can","mailbox"], "foliage":["oak_tree"],           "lights":true,  "zombies":10},
        Biome.INDUSTRIAL: {"name":"Industrial Park",   "fill":0.60, "buildings":["garage_detached"], "props":["trash_can"], "foliage":[],                             "lights":true,  "zombies":8},
        Biome.RIVER:      {"name":"River & Wetlands",  "fill":0.15, "buildings":["shed"], "props":["picket_fence"], "foliage":["bush"],                            "lights":false, "zombies":4},
        Biome.SUBWAY:     {"name":"Subway",            "fill":0.00, "buildings":[], "props":[], "foliage":[],                                                     "lights":false, "zombies":8},
        Biome.DOWNTOWN:   {"name":"Downtown",          "fill":0.90, "buildings":["two_story_colonial"], "props":["trash_can","mailbox"], "foliage":["oak_tree"],           "lights":true,  "zombies":15},
        Biome.MILITARY:   {"name":"Military Zone",     "fill":0.40, "buildings":["garage_detached"], "props":["trash_can"], "foliage":[],                             "lights":false, "zombies":15},
        Biome.WATER:      {"name":"Water",             "fill":0.00, "buildings":[], "props":[], "foliage":[],                                                     "lights":false, "zombies":0},
        Biome.EMPTY:      {"name":"Empty",             "fill":0.00, "buildings":[], "props":[], "foliage":[],                                                     "lights":false, "zombies":0},
    }

# ── GRID LAYOUT (12×10 for 30 km²) ────────────────────────
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
        {"row":6, "from_col":4, "to_col":7, "name":"Old Town Bridge"},
    ]

static func sky_colors() -> Dictionary:
    return {
        "top":     Color(0.35, 0.55, 0.85),
        "horizon": Color(0.85, 0.80, 0.70),
        "ground":  Color(0.20, 0.20, 0.22),
        "fog":     Color(0.72, 0.72, 0.75),
        "sun_rot": Vector3(-45, 30, 0),
    }
