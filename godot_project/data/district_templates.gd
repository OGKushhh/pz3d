# DistrictTemplates — data definitions for hand-authored district templates.
#
# Phase A.7 (2026-09-13): Each template is a 150×150m hand-authored
# arrangement of buildings/props/foliage "slots". At stamp time, the
# DistrictStamper picks one variant per slot (using crng for determinism
# per chunk), applies rotation jitter, and instantiates the chosen GLBs.
#
# See docs/district_templates.md for design rationale + locked decisions
# (template size, variation level, authoring approach, coverage strategy).
#
# Adding a new template:
#   1. Define a Dictionary entry in TEMPLATES below (name, size, slots)
#   2. Add the template name to BIOME_TEMPLATES for the matching biome
#   3. (Optional) Author the slot positions in the Godot editor by hand
#      for visual reference, then transcribe to this file
#   4. Verify via tests/test_district_templates.gd
class_name DistrictTemplates
extends RefCounted

# ── TEMPLATE DEFINITIONS ─────────────────────────────────
# Each template: { name, size, building_slots, foliage_slots, prop_slots, internal_roads }
# Each slot: { pos: [x,y,z], rot_y: float (degrees), variants: Array[String] }
#   - pos is RELATIVE to the template's local origin (the anchor position)
#   - rot_y is the slot's yaw in degrees (before template-level rotation is applied)
#   - variants is a list of acceptable asset names — one is picked per stamp
#     (crng.randi() % variants.size() for determinism)

const TEMPLATES := {
        # ── Suburb block (SUBURBIA) ────────────────────────────────────
        # 4 houses at corners + corner_store at entrance + cul-de-sac center
        # Layout (top-down, 150×150m, origin at center):
        #   NW house (-50,-50)   NE house (50,-50)
        #            oak (0,-30)
        #            [cul-de-sac circle]
        #            oak (0,30)
        #   SW house (-50,50)    SE house (50,50)
        #            corner_store (0,-70) at south entrance facing the main road
        #
        # All houses face INWARD toward the cul-de-sac center.
        # Corner store faces SOUTH (toward main road, away from cul-de-sac).
        "suburb_block": {
                "name": "Suburb Block",
                "size": Vector2(150, 150),
                "building_slots": [
                        # NW house — face SE (rotation 135° = facing +X+Z = south-east in Godot)
                        {"pos": [-50, 0, -50], "rot_y": 135.0, "variants": ["suburban_house_v2", "bungalow", "two_story_colonial"]},
                        # NE house — face SW (rotation -135° = 225° = facing -X+Z = south-west)
                        {"pos": [50, 0, -50], "rot_y": 225.0, "variants": ["bungalow", "house_modern", "house_ranch"]},
                        # SW house — face NE (rotation -45° = 315° = facing +X-Z = north-east)
                        {"pos": [-50, 0, 50], "rot_y": 315.0, "variants": ["two_story_colonial", "house_victorian", "house_tudor"]},
                        # SE house — face NW (rotation 45° = facing -X-Z = north-west)
                        {"pos": [50, 0, 50], "rot_y": 45.0, "variants": ["house_modern", "house_cape_cod", "house_split_level"]},
                        # Corner store at south entrance — face south (180°) toward the main road
                        {"pos": [0, 0, -70], "rot_y": 180.0, "variants": ["corner_store"]}
                ],
                "foliage_slots": [
                        # Center tree (in the cul-de-sac circle)
                        {"pos": [0, 0, 0], "variants": ["oak_tree", "maple_tree"]},
                        # Trees between house pairs
                        {"pos": [-30, 0, -30], "variants": ["oak_tree"]},
                        {"pos": [30, 0, -30], "variants": ["oak_tree", "birch_tree"]},
                        {"pos": [-30, 0, 30], "variants": ["oak_tree", "maple_tree"]},
                        {"pos": [30, 0, 30], "variants": ["oak_tree"]}
                ],
                "prop_slots": [
                        # Mailboxes at each house's curb
                        {"pos": [-35, 0, -35], "variants": ["mailbox"]},
                        {"pos": [35, 0, -35], "variants": ["mailbox"]},
                        {"pos": [-35, 0, 35], "variants": ["mailbox"]},
                        {"pos": [35, 0, 35], "variants": ["mailbox"]},
                        # Bird house in a tree (decorative)
                        {"pos": [0, 0, 15], "variants": ["bird_house"]}
                ]
        },

        # ── Commercial strip (COMMERCIAL) ─────────────────────────────
        # 4 storefronts along the SOUTH edge + surface parking lot in the N half
        # Layout (top-down, 150×150m, origin at center):
        #   [Parking lot — 3 cars in a row]
        #            (0,0)
        #            (0,30)  ← big tree in planter
        #   ─── sidewalk with street furniture ───
        #   [store1] [store2] [store3] [store4]  ← 4 storefronts along south edge
        #            (0,-70)  ← main road is south of here
        "commercial_strip": {
                "name": "Commercial Strip",
                "size": Vector2(150, 150),
                "building_slots": [
                        # 4 storefronts along south edge — face south (toward main road)
                        {"pos": [-55, 0, -55], "rot_y": 180.0, "variants": ["corner_store"]},
                        {"pos": [-20, 0, -55], "rot_y": 180.0, "variants": ["diner", "barber_shop", "salon"]},
                        {"pos": [20, 0, -55], "rot_y": 180.0, "variants": ["store_pharmacy", "store_gun"]},
                        {"pos": [55, 0, -55], "rot_y": 180.0, "variants": ["grocery_store", "store_supermarket"]}
                ],
                "foliage_slots": [
                        # Big tree in center planter
                        {"pos": [0, 0, 0], "variants": ["oak_tree"]},
                        # Two small trees in sidewalk planters
                        {"pos": [-40, 0, -40], "variants": ["birch_tree"]},
                        {"pos": [40, 0, -40], "variants": ["birch_tree"]}
                ],
                "prop_slots": [
                        # Sidewalk furniture
                        {"pos": [-30, 0, -45], "variants": ["trash_can"]},
                        {"pos": [0, 0, -45], "variants": ["planter_box"]},
                        {"pos": [30, 0, -45], "variants": ["trash_can"]},
                        # Parking meters along the parking lot edge
                        {"pos": [-50, 0, 0], "variants": ["parking_meter"]},
                        {"pos": [-25, 0, 0], "variants": ["parking_meter"]},
                        {"pos": [0, 0, 0], "variants": ["parking_meter"]},
                        {"pos": [25, 0, 0], "variants": ["parking_meter"]},
                        {"pos": [50, 0, 0], "variants": ["parking_meter"]},
                        # Shopping cart corral
                        {"pos": [-65, 0, 30], "variants": ["shopping_cart"]}
                ]
        },

        # ── Downtown block (DOWNTOWN) ─────────────────────────────────
        # 2 mid-rise buildings E+W + 1 landmark at N + NO front yards (zero setback)
        # Layout (top-down, 150×150m, origin at center):
        #            [LANDMARK at N — government_palace / stadium]
        #   [apt_tower]       [highrise_office]
        #   ←── bollards line the perimeter ──→
        #   traffic_light at SE corner
        "downtown_block": {
                "name": "Downtown Block",
                "size": Vector2(150, 150),
                "building_slots": [
                        # Landmark at north — face south (toward template center)
                        {"pos": [0, 0, -55], "rot_y": 180.0, "variants": ["government_palace", "stadium", "old_royal_palace"]},
                        # Mid-rise buildings E + W — face south
                        {"pos": [-40, 0, 30], "rot_y": 180.0, "variants": ["apartment_tower_high", "highrise_office"]},
                        {"pos": [40, 0, 30], "rot_y": 180.0, "variants": ["highrise_office", "apartment_tower_high"]}
                ],
                "foliage_slots": [
                        # Single oak tree in a small planter (downtown = sparse greenery)
                        {"pos": [0, 0, 0], "variants": ["oak_tree"]}
                ],
                "prop_slots": [
                        # Bollards along perimeter (6 total)
                        {"pos": [-70, 0, -70], "variants": ["bollard"]},
                        {"pos": [-35, 0, -70], "variants": ["bollard"]},
                        {"pos": [0, 0, -70], "variants": ["bollard"]},
                        {"pos": [35, 0, -70], "variants": ["bollard"]},
                        {"pos": [70, 0, -70], "variants": ["bollard"]},
                        {"pos": [-70, 0, 70], "variants": ["bollard"]},
                        {"pos": [70, 0, 70], "variants": ["bollard"]},
                        # Planter boxes flanking the landmark entrance
                        {"pos": [-15, 0, -45], "variants": ["planter_box"]},
                        {"pos": [15, 0, -45], "variants": ["planter_box"]},
                        # Traffic light at SE corner
                        {"pos": [70, 0, 70], "variants": ["traffic_light"]}
                ]
        },

        # ── Industrial block (INDUSTRIAL) ─────────────────────────────
        # 2 warehouses + 1 factory + loading dock + shipping containers
        # Layout (top-down, 150×150m, origin at center):
        #   [warehouse_large]    [factory_small]
        #          [loading_dock]
        #   [shipping_container]  [shipping_container]
        #   ←── guard rails + traffic cones ──→
        "industrial_block": {
                "name": "Industrial Block",
                "size": Vector2(150, 150),
                "building_slots": [
                        # Warehouse at NW — face south
                        {"pos": [-40, 0, -40], "rot_y": 180.0, "variants": ["warehouse_large", "warehouse"]},
                        # Factory at NE — face south
                        {"pos": [40, 0, -40], "rot_y": 180.0, "variants": ["factory_small", "warehouse"]},
                        # Loading dock at center-south
                        {"pos": [0, 0, 20], "rot_y": 0.0, "variants": ["loading_dock"]}
                ],
                "foliage_slots": [
                        # Sparse weeds (industrial = barren)
                        {"pos": [-60, 0, 50], "variants": ["weeds", "dead_tree"]},
                        {"pos": [60, 0, 50], "variants": ["weeds"]}
                ],
                "prop_slots": [
                        # Shipping containers (2)
                        {"pos": [-50, 0, 40], "variants": ["shipping_container"]},
                        {"pos": [50, 0, 40], "variants": ["shipping_container"]},
                        # Dumpster behind buildings
                        {"pos": [-60, 0, -60], "variants": ["dumpster"]},
                        # Traffic cones scattered
                        {"pos": [-20, 0, 10], "variants": ["traffic_cone"]},
                        {"pos": [20, 0, 10], "variants": ["traffic_cone"]},
                        {"pos": [0, 0, 50], "variants": ["traffic_cone"]},
                        # Guard rail at south entrance
                        {"pos": [-30, 0, 65], "variants": ["guard_rail"]},
                        {"pos": [0, 0, 65], "variants": ["guard_rail"]},
                        {"pos": [30, 0, 65], "variants": ["guard_rail"]}
                ]
        }
}

# ── BIOME → TEMPLATE MAPPING ──────────────────────────────
# Maps biome → Array of template names that can stamp in that biome.
# Multiple templates per biome = variety (stamper picks one randomly).
# Empty array = no template for this biome (procedural fallback).
#
# Coverage: ~30% (major biomes only — Downtown, Commercial, Industrial,
# Military). Suburbia / Parks / Forest / Farmland / Wetlands / Coastal
# stay procedural for v1. Expand coverage in Phase A.10+ if needed.
const BIOME_TEMPLATES := {
        # Major biomes — get templates
        0: ["suburb_block"],  # SUBURBIA — Phase B.2: now wired
        1: [],  # PARKS — procedural
        2: [],  # FOREST — procedural
        3: [],  # FARMLAND — procedural
        4: ["commercial_strip"],  # COMMERCIAL
        5: ["industrial_block"],  # INDUSTRIAL — Phase B.2: now wired
        7: ["downtown_block"],  # DOWNTOWN
        8: [],  # MILITARY — TODO: needs military template
        9: [],  # COASTAL_BEACH — procedural
        # 6 = WETLANDS, 10 = WATER, 11 = EMPTY — not buildable
}

# Returns the template Dictionary for a given name, or empty dict if not found.
static func get_template(name: String) -> Dictionary:
        return TEMPLATES.get(name, {})

# Returns true if a template with the given name exists.
static func has_template(name: String) -> bool:
        return TEMPLATES.has(name)

# Returns the list of template names valid for a given biome.
# Empty array = no template (procedural fallback).
static func templates_for_biome(biome: int) -> Array:
        return BIOME_TEMPLATES.get(biome, [])

# Returns the total number of defined templates.
static func template_count() -> int:
        return TEMPLATES.size()
