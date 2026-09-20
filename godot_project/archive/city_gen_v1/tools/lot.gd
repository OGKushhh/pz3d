# Lot — data definitions for hand-authored Lot recipes.
#
# Phase B.6.1 (2026-09-14): Each Lot is a complete parcel composition:
#   - 1 primary building (house, storefront, warehouse, etc.)
#   - N companion structures (garage, shed, barn, etc.) with RELATIVE offsets
#   - Sidewalk: grey strip from road edge to building front door
#   - Driveway: darker strip from road edge to garage door
#   - setback_m: how far the building origin sits from the road
#
# Lot-local convention (mirrors DistrictTemplates — see tools/district_stamper.gd):
#   - Origin = parcel.building_pos (where the primary building sits)
#   - +X = right (perpendicular to road, to the right when standing at the
#          building and looking AT the road)
#   - +Z = TOWARD the road (i.e., parcel.front_dir direction)
#   - +Y = up
#   - Building rot_y=0 → Godot default (mesh-front at -Z = AWAY from road)
#   - Building rot_y=180 → mesh-front at +Z = TOWARD road (typical for primary)
#
# Mesh-front reference (verified via mogen inspect on the .mog source):
#   - suburban_house_v2: front_door_group at Z=-3.0, porch_slab at Z=-3.5
#   - garage_detached: garage_door_group at Z=-2.0, driveway slab at Z=-3.0
#   - All current building GLBs have their mesh-front at -Z by MoGen convention.
#
# The LotStamper (tools/lot_stamper.gd) applies
#   lot_yaw = atan2(parcel.front_dir.x, parcel.front_dir.z)
# to rotate the recipe so lot-local +Z aligns with parcel.front_dir in world.
#
# See GDD §4.7.3 (Authoring Approach → Lot System) for design rationale.
class_name Lot
extends RefCounted

# ── LOT DEFINITIONS ───────────────────────────────────────
# Each lot: { name, primary, companions[], sidewalk?, driveway?, setback_m }
# Each building/companion slot: { variants[], offset:[x,y,z], rot_y:float, chance?:float, role?:String }
# Each sidewalk/driveway: { start:[x,y,z], end:[x,y,z], width:float, color:Color }
#   - start/end are in lot-local space (will be rotated by lot_yaw)
#   - Y is ignored (stamper draws at Y=0.01 to avoid z-fighting with ground)

const LOTS := {
        # ── SUBURBIA: house + east garage + optional shed ────────────
        # Layout (lot-local, +Z = toward road):
        #              road (at +Z)
        #   ─────────────────────────────
        #   shed (-X,-Z)         garage (+X, +Z)
        #            house (0,0,0)
        #              yard (at -Z)
        "suburb_house_east_garage": {
                "name": "Suburb House + East Garage",
                "primary": {
                        "variants": ["suburban_house_v2", "bungalow", "two_story_colonial", "house_modern", "house_ranch", "house_cape_cod"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,  # face road
                },
                "companions": [
                        # Garage to the east (right of house when facing road), set 2m forward
                        {"variants": ["garage_detached"], "offset": [10, 0, 2], "rot_y": 180.0, "role": "garage"},
                        # Optional shed in back-left yard (40% chance)
                        {"variants": ["shed", "garden_shed_wood"], "offset": [-8, 0, -10], "rot_y": 90.0, "chance": 0.4, "role": "shed"},
                ],
                "sidewalk": {
                        "start": [0, 0, 6.0],    # road edge (6m forward of building origin)
                        "end":   [0, 0, 3.5],    # porch_slab (door step)
                        "width": 1.5,
                        "color": Color(0.55, 0.55, 0.58, 1),  # light grey (concrete)
                },
                "driveway": {
                        "start": [10.0, 0, 6.0],  # road edge, aligned with garage X
                        "end":   [10.0, 0, 2.0],  # garage front wall (door)
                        "width": 3.0,
                        "color": Color(0.18, 0.18, 0.20, 1),  # dark grey (asphalt)
                },
                "setback_m": 6.0,
        },

        # ── SUBURBIA variant: house + west garage (mirror of above) ──
        "suburb_house_west_garage": {
                "name": "Suburb House + West Garage",
                "primary": {
                        "variants": ["suburban_house_v2", "bungalow", "two_story_colonial", "house_modern", "house_ranch", "house_cape_cod"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Garage to the west (left of house when facing road)
                        {"variants": ["garage_detached"], "offset": [-10, 0, 2], "rot_y": 180.0, "role": "garage"},
                        {"variants": ["shed", "garden_shed_wood"], "offset": [8, 0, -10], "rot_y": 270.0, "chance": 0.4, "role": "shed"},
                ],
                "sidewalk": {
                        "start": [0, 0, 6.0],
                        "end":   [0, 0, 3.5],
                        "width": 1.5,
                        "color": Color(0.55, 0.55, 0.58, 1),
                },
                "driveway": {
                        "start": [-10.0, 0, 6.0],
                        "end":   [-10.0, 0, 2.0],
                        "width": 3.0,
                        "color": Color(0.18, 0.18, 0.20, 1),
                },
                "setback_m": 6.0,
        },

        # ── SUBURBIA variant: house only, no garage (for variety / smaller lots) ──
        "suburb_house_only": {
                "name": "Suburb House (no garage)",
                "primary": {
                        "variants": ["suburban_house_v2", "bungalow", "house_cape_cod", "house_tudor", "cottage"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Shed in backyard
                        {"variants": ["shed", "garden_shed_wood"], "offset": [0, 0, -12], "rot_y": 90.0, "chance": 0.6, "role": "shed"},
                ],
                "sidewalk": {
                        "start": [0, 0, 6.0],
                        "end":   [0, 0, 3.5],
                        "width": 1.5,
                        "color": Color(0.55, 0.55, 0.58, 1),
                },
                "setback_m": 6.0,
        },

        # ── COMMERCIAL: storefront + sidewalk (no garage, no driveway) ──
        # Storefronts sit close to the road (small setback) with a wide sidewalk.
        "commercial_storefront": {
                "name": "Commercial Storefront",
                "primary": {
                        "variants": ["corner_store", "diner", "gas_station", "grocery_store", "store_supermarket", "salon", "barber_shop", "laundromat", "auto_repair_shop"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Trash can out front (near road)
                        {"variants": ["trash_can"], "offset": [4, 0, 5], "rot_y": 0.0, "chance": 0.7, "role": "prop"},
                        # Mailbox / parking meter near road
                        {"variants": ["parking_meter"], "offset": [-4, 0, 5], "rot_y": 0.0, "chance": 0.5, "role": "prop"},
                ],
                "sidewalk": {
                        "start": [0, 0, 5.0],
                        "end":   [0, 0, 0.0],
                        "width": 2.0,
                        "color": Color(0.55, 0.55, 0.58, 1),
                },
                "setback_m": 5.0,
        },

        # ── INDUSTRIAL: warehouse + loading dock + shipping containers ──
        # Industrial lots have a large footprint, no sidewalk, asphalt pad in front.
        "industrial_warehouse": {
                "name": "Industrial Warehouse Lot",
                "primary": {
                        "variants": ["warehouse_large", "warehouse", "factory_small"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Loading dock to the east
                        {"variants": ["loading_dock"], "offset": [15, 0, 5], "rot_y": 180.0, "role": "loading"},
                        # Shipping containers flanking
                        {"variants": ["shipping_container"], "offset": [-12, 0, -8], "rot_y": 0.0, "chance": 0.8, "role": "container"},
                        {"variants": ["shipping_container"], "offset": [-18, 0, -8], "rot_y": 0.0, "chance": 0.5, "role": "container"},
                        # Dumpster behind building
                        {"variants": ["dumpster"], "offset": [12, 0, -12], "rot_y": 0.0, "chance": 0.7, "role": "prop"},
                ],
                # Industrial "driveway" = wide asphalt pad in front of warehouse (for trucks)
                "driveway": {
                        "start": [0, 0, 12.0],
                        "end":   [0, 0, 0.0],
                        "width": 8.0,
                        "color": Color(0.15, 0.15, 0.17, 1),  # very dark asphalt
                },
                "setback_m": 12.0,
        },

        # ── DOWNTOWN: highrise + bollards + wide sidewalk ─────────────
        # Downtown lots have zero setback (buildings flush with sidewalk).
        "downtown_highrise": {
                "name": "Downtown Highrise Lot",
                "primary": {
                        "variants": ["highrise_office", "apartment_tower_high", "government_palace", "stadium"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Bollards flanking the entrance
                        {"variants": ["bollard"], "offset": [-5, 0, 4], "rot_y": 0.0, "role": "prop"},
                        {"variants": ["bollard"], "offset": [5, 0, 4], "rot_y": 0.0, "role": "prop"},
                        # Planter boxes
                        {"variants": ["planter_box"], "offset": [-3, 0, 4], "rot_y": 0.0, "chance": 0.6, "role": "prop"},
                        {"variants": ["planter_box"], "offset": [3, 0, 4], "rot_y": 0.0, "chance": 0.6, "role": "prop"},
                ],
                "sidewalk": {
                        "start": [0, 0, 4.0],
                        "end":   [0, 0, 0.0],
                        "width": 3.0,  # wide downtown sidewalk
                        "color": Color(0.50, 0.50, 0.53, 1),
                },
                "setback_m": 4.0,
        },

        # ── FARMLAND: farmhouse + barn + shed (no sidewalk — dirt path) ──
        # Farm lots are large, with barn behind farmhouse.
        "farm_house_barn": {
                "name": "Farmhouse + Barn Lot",
                "primary": {
                        "variants": ["farmhouse"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Barn behind house, offset to one side
                        {"variants": ["barn"], "offset": [10, 0, -20], "rot_y": 90.0, "role": "barn"},
                        # Shed next to barn
                        {"variants": ["shed", "tractor_shed"], "offset": [-8, 0, -18], "rot_y": 90.0, "chance": 0.7, "role": "shed"},
                        # Garden gnome or scarecrow
                        {"variants": ["garden_gnome"], "offset": [5, 0, 4], "rot_y": 0.0, "chance": 0.3, "role": "prop"},
                ],
                # Farm "driveway" = dirt path (use brown color instead of asphalt)
                "driveway": {
                        "start": [0, 0, 8.0],
                        "end":   [0, 0, 0.0],
                        "width": 4.0,
                        "color": Color(0.35, 0.28, 0.18, 1),  # dirt brown
                },
                "setback_m": 8.0,
        },

        # ── MILITARY: checkpoint + bunker + sandbags ──────────────────
        # Military lots have concrete barriers, no sidewalk.
        "military_checkpoint": {
                "name": "Military Checkpoint Lot",
                "primary": {
                        "variants": ["military_checkpoint", "bunker_entrance"],
                        "offset": [0, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Watchtower behind checkpoint
                        {"variants": ["watchtower"], "offset": [0, 0, -15], "rot_y": 0.0, "role": "tower"},
                        # Sandbag barriers flanking
                        {"variants": ["sandbag"], "offset": [-8, 0, 3], "rot_y": 0.0, "role": "barrier"},
                        {"variants": ["sandbag"], "offset": [8, 0, 3], "rot_y": 0.0, "role": "barrier"},
                        # Concrete barrier at road edge
                        {"variants": ["barrier_concrete"], "offset": [-6, 0, 8], "rot_y": 0.0, "chance": 0.7, "role": "barrier"},
                        {"variants": ["barrier_concrete"], "offset": [6, 0, 8], "rot_y": 0.0, "chance": 0.7, "role": "barrier"},
                ],
                "driveway": {
                        "start": [0, 0, 10.0],
                        "end":   [0, 0, 0.0],
                        "width": 6.0,
                        "color": Color(0.20, 0.20, 0.22, 1),  # dark asphalt
                },
                "setback_m": 10.0,
        },

        # ── Phase C.3: ATTACHED BUILDINGS — Row Houses ───────────────
        # 3 houses side by side at 7m spacing — attached, shared walls.
        # Replaces standalone house lots in dense suburban areas (core zone).
        "suburb_row_houses": {
                "name": "Suburb Row Houses (3 attached)",
                "primary": {
                        "variants": ["suburban_house_v2", "bungalow", "house_cape_cod"],
                        "offset": [-7, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        # Middle house
                        {"variants": ["suburban_house_v2", "bungalow", "house_modern"], "offset": [0, 0, 0], "rot_y": 180.0, "role": "attached"},
                        # Right house
                        {"variants": ["house_ranch", "house_cape_cod", "bungalow"], "offset": [7, 0, 0], "rot_y": 180.0, "role": "attached"},
                ],
                "sidewalk": {
                        "start": [0, 0, 6.0],
                        "end":   [0, 0, 3.5],
                        "width": 1.5,
                        "color": Color(0.55, 0.55, 0.58, 1),
                },
                "setback_m": 6.0,
        },

        # ── Phase C.3: ATTACHED BUILDINGS — Strip Mall ────────────────
        # 3 storefronts side by side at 10m spacing — one long commercial building.
        "commercial_strip_mall_attached": {
                "name": "Commercial Strip Mall (3 attached storefronts)",
                "primary": {
                        "variants": ["corner_store", "diner"],
                        "offset": [-10, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        {"variants": ["store_pharmacy", "salon", "barber_shop"], "offset": [0, 0, 0], "rot_y": 180.0, "role": "attached"},
                        {"variants": ["grocery_store", "laundromat", "auto_repair_shop"], "offset": [10, 0, 0], "rot_y": 180.0, "role": "attached"},
                ],
                "sidewalk": {
                        "start": [0, 0, 5.0],
                        "end":   [0, 0, 0.0],
                        "width": 2.0,
                        "color": Color(0.55, 0.55, 0.58, 1),
                },
                "setback_m": 5.0,
        },

        # ── Phase C.3: ATTACHED BUILDINGS — Downtown Attached ─────────
        # 2 highrises flush together (zero gap between them).
        "downtown_attached_highrises": {
                "name": "Downtown Attached Highrises (2 buildings, zero gap)",
                "primary": {
                        "variants": ["highrise_office", "apartment_tower_high"],
                        "offset": [-8, 0, 0],
                        "rot_y": 180.0,
                },
                "companions": [
                        {"variants": ["highrise_office", "apartment_tower_high"], "offset": [8, 0, 0], "rot_y": 180.0, "role": "attached"},
                ],
                "sidewalk": {
                        "start": [0, 0, 4.0],
                        "end":   [0, 0, 0.0],
                        "width": 3.0,
                        "color": Color(0.50, 0.50, 0.53, 1),
                },
                "setback_m": 4.0,
        },
}

# ── BIOME → LOT MAPPING ───────────────────────────────────
# Maps biome enum → Array of lot recipe names that can stamp in that biome.
# The LotStamper picks one randomly per parcel (via crng for determinism).
#
# Coverage strategy: start with 1-3 recipes per major biome. Expand later.
# Biomes not listed here fall back to the existing parcel-by-parcel loop
# in chunk_streamer.gd (which will be deprecated as more recipes are added).
#
# Biome enum values (see tools/city_config.gd):
#   0=SUBURBIA, 1=PARKS, 2=FOREST, 3=FARMLAND, 4=COMMERCIAL,
#   5=INDUSTRIAL, 6=WETLANDS, 7=DOWNTOWN, 8=MILITARY, 9=COASTAL_BEACH
const BIOME_LOTS := {
        0: ["suburb_house_east_garage", "suburb_house_west_garage", "suburb_house_only", "suburb_row_houses"],  # SUBURBIA + C.3 row houses
        3: ["farm_house_barn"],  # FARMLAND
        4: ["commercial_storefront", "commercial_strip_mall_attached"],  # COMMERCIAL + C.3 strip mall
        5: ["industrial_warehouse"],  # INDUSTRIAL
        7: ["downtown_highrise", "downtown_attached_highrises"],  # DOWNTOWN + C.3 attached
        8: ["military_checkpoint"],  # MILITARY
        # 1=PARKS, 2=FOREST, 6=WETLANDS, 9=COASTAL_BEACH: no lots yet — keep procedural
}

# Returns the lot Dictionary for a given name, or empty dict if not found.
static func get_lot(name: String) -> Dictionary:
        return LOTS.get(name, {})

# Returns true if a lot with the given name exists.
static func has_lot(name: String) -> bool:
        return LOTS.has(name)

# Returns the list of lot recipe names valid for a given biome.
# Empty array = no lot recipe (procedural fallback in chunk_streamer).
static func lots_for_biome(biome: int) -> Array:
        return BIOME_LOTS.get(biome, [])

# Pick a random lot recipe name for a biome using the given RNG.
# Returns "" if no lot recipe for this biome.
static func pick_lot_for_biome(biome: int, crng: RandomNumberGenerator) -> String:
        var lots: Array = BIOME_LOTS.get(biome, [])
        if lots.is_empty():
                return ""
        return lots[crng.randi() % lots.size()]

# Returns the total number of defined lot recipes.
static func lot_count() -> int:
        return LOTS.size()
