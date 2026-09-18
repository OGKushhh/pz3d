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
# Phase v1-locked (2026-09-14): MAP IS FIXED AT 12 km².
# User decision: "lock down 12km2 and delete the 30km2 plan, if i keep
# failing at city gen i might lower it more than 12."
#
# 12 km² alpha  →  Vector2(4000, 3000), GRID 8×6  ← LOCKED FOR v1
# (30 km² beta + 100 km² v1 plans DELETED — if city gen keeps struggling,
#  we may LOWER below 12 km², not expand. Density over area.)
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

# ── PER-BIOME GROUND COLORS (Phase B.4) ──────────────────
# Each biome gets a distinct ground color so the map reads as designed
# from above. Combined with per-vertex noise, the ground feels alive
# instead of painted.
const BIOME_GROUND_COLORS := {
    Biome.SUBURBIA:       Color(0.35, 0.52, 0.20),  # mowed green
    Biome.PARKS:          Color(0.40, 0.60, 0.25),  # bright green
    Biome.FOREST:         Color(0.20, 0.35, 0.15),  # dark mossy
    Biome.FARMLAND:       Color(0.55, 0.48, 0.22),  # dry yellow-green + dirt patches
    Biome.COMMERCIAL:     Color(0.45, 0.43, 0.40),  # grey concrete
    Biome.INDUSTRIAL:     Color(0.35, 0.33, 0.30),  # stained concrete
    Biome.WETLANDS:       Color(0.30, 0.35, 0.18),  # marsh brown-green
    Biome.DOWNTOWN:       Color(0.40, 0.38, 0.35),  # pavement grey
    Biome.MILITARY:       Color(0.50, 0.45, 0.35),  # dusty tan
    Biome.COASTAL_BEACH:  Color(0.72, 0.67, 0.47),  # sand
    Biome.WATER:          Color(0.10, 0.20, 0.35),  # dark blue
    Biome.EMPTY:          Color(0.22, 0.40, 0.16),  # default green
}

# Returns the ground color for a biome.
static func ground_color_for(biome: int) -> Color:
    return BIOME_GROUND_COLORS.get(biome, COLOR_GROUND)

# ── DISTRICT IDENTITY (Phase A.9, updated XIII-style per-biome palette) ───
# Each biome has its own distinct palette, but within that biome colors stay
# limited. This is the XIII approach — each scene has its own palette, but
# the palette varies between scenes. The world has color variety, but each
# scene is coherent.
#
# User spec for per-biome palette:
#   Suburbia: muted browns, faded yellows, dull greens
#   Parks: vibrant greens, warm afternoon golds
#   Farmland: golden wheat, deep ochre, sky blue
#   Forest: cold pines, dark teals, misty blues
#   Commercial: neon signs, saturated reds and blues, wet asphalt
#   Industrial: rust oranges, steel grays, sulfur yellows
#   Wetlands: deep teals, artificial yellows (merged with Subway palette)
#   Downtown: neon purples and pinks, sodium orange streetlights, deep blue night
#   Military: toxic green fog, warning reds, sterile whites
#   Coastal: bright sky blue, turquoise water, warm sand
#
# Each biome has:
#   - sky_tint: overrides sky horizon color when player is in this biome
#   - fog_tint: fog color shifts to match biome mood
#   - ambient_tint: ambient light color shift
#   - sun_energy_mult: brightness multiplier (Military = darker, Parks = brighter)
#   - fog_density_mult: fog density multiplier per biome
#   - palette_primary: dominant color of the biome (for cel-shading ramp)
#   - palette_accent: accent color for UI/HUD when in this biome
#   - palette_name: human-readable palette description
const DISTRICT_IDENTITY := {
    Biome.SUBURBIA: {
        "sky_tint": Color(1.08, 1.02, 0.85),  # warm faded yellow sky
        "fog_tint": Color(0.82, 0.75, 0.60),  # muted brown-beige fog
        "ambient_tint": Color(1.05, 0.98, 0.88),
        "sun_energy_mult": 1.0,
        "fog_density_mult": 1.0,
        "palette_primary": Color(0.60, 0.50, 0.35),  # muted brown
        "palette_accent": Color(0.65, 0.55, 0.25),  # faded yellow
        "palette_name": "muted browns, faded yellows, dull greens",
    },
    Biome.PARKS: {
        "sky_tint": Color(0.95, 1.00, 0.85),  # warm afternoon gold sky
        "fog_tint": Color(0.78, 0.88, 0.70),  # green-gold fog
        "ambient_tint": Color(1.02, 1.08, 0.95),
        "sun_energy_mult": 1.2,  # brighter (warm afternoon)
        "fog_density_mult": 0.6,  # less fog (clear afternoon)
        "palette_primary": Color(0.30, 0.55, 0.25),  # vibrant green
        "palette_accent": Color(0.75, 0.65, 0.30),  # warm gold
        "palette_name": "vibrant greens, warm afternoon golds",
    },
    Biome.FOREST: {
        "sky_tint": Color(0.65, 0.75, 0.80),  # cold misty blue sky
        "fog_tint": Color(0.50, 0.60, 0.70),  # misty blue-gray
        "ambient_tint": Color(0.80, 0.88, 0.95),
        "sun_energy_mult": 0.65,  # darker (dense canopy)
        "fog_density_mult": 1.8,  # thick mist (mysterious)
        "palette_primary": Color(0.15, 0.35, 0.30),  # cold pine teal
        "palette_accent": Color(0.20, 0.45, 0.55),  # misty blue
        "palette_name": "cold pines, dark teals, misty blues",
    },
    Biome.FARMLAND: {
        "sky_tint": Color(0.90, 0.95, 1.05),  # sky blue
        "fog_tint": Color(0.85, 0.72, 0.45),  # golden wheat dust
        "ambient_tint": Color(1.08, 0.95, 0.75),
        "sun_energy_mult": 1.15,
        "fog_density_mult": 0.8,
        "palette_primary": Color(0.65, 0.50, 0.20),  # golden wheat
        "palette_accent": Color(0.55, 0.35, 0.10),  # deep ochre
        "palette_name": "golden wheat, deep ochre, sky blue",
    },
    Biome.COMMERCIAL: {
        "sky_tint": Color(0.85, 0.88, 0.95),  # wet asphalt overcast
        "fog_tint": Color(0.65, 0.65, 0.72),  # urban haze
        "ambient_tint": Color(0.95, 0.95, 1.00),
        "sun_energy_mult": 0.9,
        "fog_density_mult": 1.3,  # urban haze
        "palette_primary": Color(0.35, 0.35, 0.40),  # wet asphalt gray
        "palette_accent": Color(0.80, 0.25, 0.25),  # saturated neon red
        "palette_name": "neon signs, saturated reds and blues, wet asphalt",
    },
    Biome.INDUSTRIAL: {
        "sky_tint": Color(0.82, 0.75, 0.65),  # smoggy sulfur sky
        "fog_tint": Color(0.55, 0.50, 0.45),  # steel gray smog
        "ambient_tint": Color(0.92, 0.85, 0.75),
        "sun_energy_mult": 0.75,  # darker (industrial smog)
        "fog_density_mult": 1.6,  # thick smog
        "palette_primary": Color(0.45, 0.38, 0.32),  # steel gray
        "palette_accent": Color(0.65, 0.40, 0.15),  # rust orange
        "palette_name": "rust oranges, steel grays, sulfur yellows",
    },
    Biome.WETLANDS: {
        "sky_tint": Color(0.80, 0.85, 0.88),  # cold overcast
        "fog_tint": Color(0.60, 0.70, 0.72),  # deep teal mist
        "ambient_tint": Color(0.88, 0.95, 0.95),
        "sun_energy_mult": 0.8,
        "fog_density_mult": 2.0,  # thickest mist (marsh)
        "palette_primary": Color(0.20, 0.40, 0.38),  # deep teal
        "palette_accent": Color(0.75, 0.70, 0.35),  # artificial yellow
        "palette_name": "deep teals, artificial yellows, cold concrete grays",
    },
    Biome.DOWNTOWN: {
        "sky_tint": Color(0.45, 0.35, 0.65),  # deep blue night + purple
        "fog_tint": Color(0.35, 0.25, 0.50),  # purple-blue rain fog
        "ambient_tint": Color(0.65, 0.55, 0.85),
        "sun_energy_mult": 0.5,  # darkest (night neon)
        "fog_density_mult": 1.4,
        "palette_primary": Color(0.25, 0.15, 0.40),  # deep blue night
        "palette_accent": Color(0.80, 0.30, 0.60),  # neon purple/pink
        "palette_name": "neon purples and pinks, sodium orange streetlights, deep blue night",
    },
    Biome.MILITARY: {
        "sky_tint": Color(0.55, 0.62, 0.45),  # toxic green-gray sky
        "fog_tint": Color(0.40, 0.48, 0.35),  # toxic green fog
        "ambient_tint": Color(0.80, 0.88, 0.72),
        "sun_energy_mult": 0.45,  # very dark (unnatural silence)
        "fog_density_mult": 2.2,  # thickest (toxic fog + ashfall)
        "palette_primary": Color(0.35, 0.42, 0.30),  # toxic green
        "palette_accent": Color(0.70, 0.25, 0.20),  # warning red
        "palette_name": "toxic green fog, warning reds, sterile whites",
    },
    Biome.COASTAL_BEACH: {
        "sky_tint": Color(0.80, 0.90, 1.05),  # bright sky blue
        "fog_tint": Color(0.70, 0.85, 0.90),  # sea spray mist
        "ambient_tint": Color(1.00, 1.05, 1.05),
        "sun_energy_mult": 1.25,  # brightest (beach sun)
        "fog_density_mult": 0.4,  # least fog (sea breeze clears it)
        "palette_primary": Color(0.50, 0.75, 0.85),  # turquoise water
        "palette_accent": Color(0.85, 0.78, 0.55),  # warm sand
        "palette_name": "bright sky blue, turquoise water, warm sand",
    },
}

# Returns the district identity Dictionary for a biome, or empty if none.
static func district_identity_for(biome: int) -> Dictionary:
    return DISTRICT_IDENTITY.get(biome, {})

# ── DISTRICT HALO (Phase A.9) ─────────────────────────────
# Landmarks bias neighboring chunks' building picks. A stadium's nearby
# chunks get sports bars, parking garages, hotels. A hospital's nearby
# chunks get pharmacies, medical offices. A government_palace's nearby
# chunks get office buildings, security checkpoints.
#
# Each landmark declares a HALO_PROFILE — a list of "halo buildings" that
# get boosted spawn probability in chunks within HALO_RADIUS_M of the
# landmark. The boost is a multiplier on the normal pick probability.
#
# Halo radius: 500m (covers ~2 chunks around the landmark).
const HALO_RADIUS_M := 500.0

const LANDMARK_HALOS := {
    "stadium": {
        "halo_buildings": ["barber_shop", "salon", "bank_branch", "parking_garage", "apartment_small"],
        "halo_prob_mult": 2.0,  # 2x normal probability for these buildings
        "halo_props": ["parking_meter", "traffic_light", "bollard"],
    },
    "hospital": {
        "halo_buildings": ["store_pharmacy", "bank_branch", "parking_garage", "highrise_office"],
        "halo_prob_mult": 2.5,
        "halo_props": ["parking_meter", "bollard", "planter_box"],
    },
    "government_palace": {
        "halo_buildings": ["highrise_office", "bank_branch", "apartment_tower_high", "police_station"],
        "halo_prob_mult": 2.0,
        "halo_props": ["bollard", "planter_box", "traffic_camera"],
    },
    "old_royal_palace": {
        "halo_buildings": ["church_small", "apartment_small", "highrise_office"],
        "halo_prob_mult": 1.5,
        "halo_props": ["planter_box", "bollard"],
    },
    "fort_sarran": {
        "halo_buildings": ["military_checkpoint", "watchtower", "bunker_entrance", "field_hospital_tent"],
        "halo_prob_mult": 3.0,  # heavy military presence near the fort
        "halo_props": ["barbed_wire_fence", "sandbag", "traffic_cone"],
    },
    "lighthouse": {
        "halo_buildings": ["fishing_hut", "pier_dock", "houseboat"],
        "halo_prob_mult": 2.0,
        "halo_props": ["planter_box"],
    },
    "grain_silo": {
        "halo_buildings": ["barn", "shed", "tractor_shed", "grain_storage_shed"],
        "halo_prob_mult": 2.0,
        "halo_props": [],
    },
    "windmill": {
        "halo_buildings": ["farmhouse", "barn", "cottage"],
        "halo_prob_mult": 1.5,
        "halo_props": [],
    },
    "broadcast_tower": {
        "halo_buildings": ["highrise_office", "apartment_tower_high", "police_station"],
        "halo_prob_mult": 2.0,
        "halo_props": ["traffic_camera", "bollard"],
    },
    "railway_station": {
        "halo_buildings": ["parking_garage", "corner_store", "diner", "bank_branch"],
        "halo_prob_mult": 2.0,
        "halo_props": ["parking_meter", "traffic_light", "bollard"],
    },
}

# Returns the halo profile for a landmark, or empty if no halo defined.
static func halo_for(landmark: String) -> Dictionary:
    return LANDMARK_HALOS.get(landmark, {})

# ── PER-BIOME DESIGN LANGUAGE (Phase B.3) ──────────────────
# DeepSeek: "Each biome gets setback rules, roof style, fence rules, yard
# content. Same assets, different placement = different feel."
#
# Phase B.3: fence + yard content rules per biome. The chunk_streamer
# uses these to bias prop picks — Suburbia gets picket_fence + garden_gnome,
# Industrial gets guard_rail + dumpster, Downtown gets bollards only.
const BIOME_DESIGN := {
    Biome.SUBURBIA: {
        "fence_props": ["picket_fence", "wood_fence_post"],
        "yard_props": ["garden_gnome", "garden_hose_reel", "bird_house", "basketball_hoop"],
        "yard_foliage": ["hedge", "hedge_tall", "flower_patch"],
    },
    Biome.PARKS: {
        "fence_props": [],
        "yard_props": ["bench_park", "picnic_table", "water_fountain", "park_sign"],
        "yard_foliage": ["fern", "weeds", "mushrooms", "flower_patch"],
    },
    Biome.FOREST: {
        "fence_props": [],
        "yard_props": ["campfire_ring"],
        "yard_foliage": ["pine_tree", "birch_tree", "dead_tree", "fallen_log", "rocks_small"],
    },
    Biome.FARMLAND: {
        "fence_props": ["picket_fence", "wood_fence_post"],
        "yard_props": ["garden_gnome", "garden_hose_reel"],
        "yard_foliage": ["oak_tree", "bush", "weeds", "tall_grass"],
    },
    Biome.COMMERCIAL: {
        "fence_props": ["bollard"],
        "yard_props": ["trash_can", "planter_box", "parking_meter", "shopping_cart"],
        "yard_foliage": ["hedge"],
    },
    Biome.INDUSTRIAL: {
        "fence_props": ["guard_rail", "barbed_wire_fence"],
        "yard_props": ["dumpster", "traffic_cone", "construction_barrier"],
        "yard_foliage": ["weeds", "dead_tree"],
    },
    Biome.WETLANDS: {
        "fence_props": [],
        "yard_props": [],
        "yard_foliage": ["cattail", "marsh_grass", "willow_tree", "tall_grass"],
    },
    Biome.DOWNTOWN: {
        "fence_props": ["bollard"],
        "yard_props": ["planter_box", "traffic_light", "parking_meter"],
        "yard_foliage": ["oak_tree"],
    },
    Biome.MILITARY: {
        "fence_props": ["barbed_wire_fence", "sandbag"],
        "yard_props": ["traffic_cone", "construction_barrier"],
        "yard_foliage": ["weeds", "dead_tree"],
    },
    Biome.COASTAL_BEACH: {
        "fence_props": [],
        "yard_props": ["boardwalk_section"],
        "yard_foliage": ["palm_tree", "marsh_grass", "cattail"],
    },
}

# Returns the design language Dictionary for a biome.
static func biome_design_for(biome: int) -> Dictionary:
    return BIOME_DESIGN.get(biome, {})

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
#
# Phase B.3: HEIGHT DISTRIBUTION — each biome declares the probability
# of picking SHORT / MID / TALL buildings. The building picker filters
# the biome's building list by height_class first, then picks randomly
# within the class. This makes cities READ AS DESIGNED:
#   - Downtown: 70% TALL, 30% MID, 0% SHORT (towers dominate)
#   - Suburbia: 80% SHORT, 20% MID, 0% TALL (houses, not towers)
#   - Commercial: 20% SHORT, 60% MID, 20% TALL (storefronts + occasional office)
#   - Industrial: 40% SHORT (sheds), 60% MID (warehouses), 0% TALL
#   - Forest/Farmland: 90% SHORT, 10% MID (cabins + farmhouses)
static func biomes() -> Dictionary:
    return {
        Biome.SUBURBIA: {
            "name": "Suburbia",
            "height_dist": {"SHORT": 0.8, "MID": 0.2, "TALL": 0.0},
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
            "height_dist": {"SHORT": 1.0, "MID": 0.0, "TALL": 0.0},
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
            "height_dist": {"SHORT": 0.9, "MID": 0.1, "TALL": 0.0},
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
            "height_dist": {"SHORT": 0.9, "MID": 0.1, "TALL": 0.0},
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
            "height_dist": {"SHORT": 0.2, "MID": 0.6, "TALL": 0.2},
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
            "height_dist": {"SHORT": 0.4, "MID": 0.6, "TALL": 0.0},
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
            "height_dist": {"SHORT": 0.8, "MID": 0.2, "TALL": 0.0},
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
            "height_dist": {"SHORT": 0.7, "MID": 0.3, "TALL": 0.0},
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
            "height_dist": {"SHORT": 0.0, "MID": 0.3, "TALL": 0.7},
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
            "height_dist": {"SHORT": 0.5, "MID": 0.3, "TALL": 0.2},
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
#   row 5 (river mouth):       cols 3-4 = WETLANDS (Sarran Marshes)
# This matches GDD §2.12 lore: "Sarran River flows from the northern forest
# through the farmland and into Sarran Bay." The bay is at column 5
# (COASTAL_BEACH) — the river exits the south edge of the map into the bay,
# and the marshlands form at the river's mouth (cols 3-4, row 5).
#
# Phase A.5 (2026-09-13): WETLANDS placed at the river mouth (row 5, cols 3-4).
# This is the "emergent" placement for v1 — actual elevation-driven placement
# (WETLANDS = where terrain_height < 0.5m AND near river) is a future phase.
# For now, the river mouth is hand-placed as wetlands to match lore.
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
    var WE := Biome.WETLANDS
    # v4 (2026-09-15): GTA-SA-inspired hand-authored layout.
    # 3 cities at 3 corners + countryside between, matching GTA SA structure:
    #   - San Fierro analog (NW peninsula): Downtown 2x2 block, dense core
    #   - Las Venturas analog (NE strip): Commercial 4x2 block, long horizontal
    #   - Los Santos analog (SE coast): Suburbia + Industrial along south coast
    #   - Bone County desert (N-center): Military 2x2 block (Area 69 analog)
    #   - Mt Chiliad (SW): Forest 2x2 block (mountain + trees)
    #   - Red County (W-center): Farmland strip
    #   - Flint County (dead center): Parks (green heart, Flint Water analog)
    #   - Wetlands: Sarran River delta at south-center (LS inlet analog)
    #   - Coastal Beach: west column (Sarran Bay) + south LS beach
    return [
        [DT, DT, MI, MI, CO, CO, CO, CO],
        [DT, DT, MI, MI, CO, CO, CO, CO],
        [F,  F,  FA, PA, FA, CO, CO, CO],
        [F,  FA, FA, PA, FA, SU, SU, IN],
        [CB, FA, WE, PA, WE, SU, SU, IN],
        [CB, CB, WE, WE, WE, SU, IN, IN],
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

# ── DISTRICT NAMES (Phase A.5, 2026-09-13) ───────────────
# Placeholder names per biome, drawn from GDD lore (§2.2 Long Peace,
# §2.3 Quiet Coup, §2.12 geography, §2.14 civic landmarks).
#
# ALL NAMES ARE PLACEHOLDERS — the user is still deciding on lore expansion
# and missions/content. These give us strings to print on district signs
# and a `district_name` field per chunk for the debug HUD + future GPS.
# Expect renames once the lore is locked.
#
# Sources:
#   Long Peace Heights ← §2.2 The Long Peace (300 years of monarchy)
#   Founders' Gardens  ← §2.2 civic landmarks, no religious
#   Sarran Headwaters  ← §2.12 river flows from northern forest
#   Mazar Breadbasket  ← §2.13 row #4 "Mazar's food basket"
#   Old Bazaar         ← §2.14 "The Grand Bazaar / Souq"
#   Railside Quarter   ← §2.13 row #6 "Manufacturing and rail"
#   Sarran Marshes     ← §2.12 river mouth geography
#   Bay Shore          ← §2.12 "Sarran Bay"
#   Junta Quarter      ← §2.3 The Quiet Coup — junta HQ is Government Palace
#   Fort Sarran Approach ← §2.14 Fort Sarran is eastern edge
#   The Sarran         ← §2.12 Sarran River (overlay, not a cell biome)
#   Sarran Bay         ← §2.12 (overlay, not a cell biome)
static func district_names() -> Dictionary:
    return {
        Biome.SUBURBIA: "Long Peace Heights",
        Biome.PARKS: "Founders' Gardens",
        Biome.FOREST: "Sarran Headwaters",
        Biome.FARMLAND: "Mazar Breadbasket",
        Biome.COMMERCIAL: "Old Bazaar",
        Biome.INDUSTRIAL: "Railside Quarter",
        Biome.WETLANDS: "Sarran Marshes",
        Biome.DOWNTOWN: "Junta Quarter",
        Biome.MILITARY: "Fort Sarran Approach",
        Biome.COASTAL_BEACH: "Bay Shore",
        Biome.WATER: "Open Water",
        Biome.EMPTY: "Out of Bounds",
    }

# Returns the placeholder district name for a given biome int.
# Falls back to "Unknown District" if biome isn't in the map (defensive).
static func district_name_for(biome: int) -> String:
    return district_names().get(biome, "Unknown District")
