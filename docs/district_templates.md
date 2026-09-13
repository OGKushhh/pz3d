# District Templates — Design Document

> **Phase A.7 (2026-09-13)**
> Hand-authored district templates — the bridge from "fully procedural" pain
> to "hand-fixed" intent per GDD §4.4 (exterior fixed, interior procedural).

## What is a district template?

A district template is a small (~150×150m) hand-authored arrangement of
buildings, props, foliage, and (optional) internal roads. At runtime,
`chunk_streamer.gd` stamps a template at anchor positions (defined by
`tools/anchor_points.gd`) with per-run variation.

This is the **PZ hybrid approach**:
- **Fixed at template-authoring time**: building footprints, road layout,
  lot sizes, prop positions, structural geometry.
- **Procedural per-run**: asset variant pick (which house variant, which
  fence style), rotation jitter, prop density variation, loot/zombie scatter.

## Decisions (locked 2026-09-13)

### Q2 — Template size

**150×150m per template, single-chunk.**

Each chunk is 250×250m. A 150×150m template fits inside one chunk with
50m of procedural fill around the edges. This keeps:
- Chunk loading simple (one template per chunk max)
- Spatial exclusion easy (template's footprint is well-defined)
- No cross-chunk template seams to worry about

Future option: 2-chunk templates for downtown blocks (500×250m) — deferred
to Phase A.10+ when we have more assets and need denser urban cores.

### Q3 — Variation per template

**Rotation + asset variant pick.**

Three levels of variation were considered:
- (a) Rotation only — every instance of a template looks the same, just
  rotated to face a different direction. Boring but cheapest.
- (b) Rotation + asset variant pick — for each "slot" in the template
  (e.g., "house at NW corner"), pick from a list of acceptable variants
  (suburban_house_v2 OR bungalow OR two_story_colonial). Same layout,
  different building each run. ✓ **CHOSEN**
- (c) Rotation + variant + prop density jitter + color tint — adds per-run
  prop count variation and material color tinting. Polish level. Deferred
  to Phase A.9+.

**Why (b):** PZ's Muldraugh uses the same layout but swaps which house
variant sits at each lot — you recognize the layout but the buildings
differ. That's the sweet spot for "hand-authored feel + procedural
replayability."

### Q4 — Template authoring

**AI authors the 3 starter templates as GDScript functions.**

Templates are NOT .tscn files (hand-authoring .tscn with ExtResource
references to GLBs is error-prone and hard to verify). Instead, each
template is a GDScript method on `DistrictStamper` that builds the
scene tree at runtime by instantiating existing GLB assets at
hand-picked positions.

This gives:
- Programmatic position computation (no transform math by hand)
- Inline variation (variant pick happens in same code)
- Easy verification (`godot --headless` runs cleanly = template loads)
- Easy to refine (edit GDScript, not .tscn)

Future option: export templates to .tscn via Godot editor "Save As
Scene" if visual editing becomes useful. The runtime stamper can load
.tscn OR call the GDScript builder — both paths supported.

## Coverage decision (pending user confirmation)

**Default: 30% coverage (major anchors only).**

Of the 48 anchor cells (8×6 grid), ~21 are "major" (Downtown, Commercial,
Industrial, Military biomes + cells with POI landmarks). Major anchors
get templates. The remaining ~27 (Suburbia, Parks, Forest, Farmland,
Wetlands, Coastal Beach) stay procedural.

Rationale:
- Hand-authoring 48 templates is too much for v1
- Major anchors are where players spend the most time (city centers,
  landmarks) — highest visual payoff per template
- Procedural residential / forest / farmland is acceptable — those
  biomes tolerate randomness better than cities do

Expand coverage in Phase A.10+ if procedural gaps feel jarring.

## Architecture

```
godot_project/
  tools/
    anchor_points.gd          # 48 anchors with metadata (Phase A.6)
    district_stamper.gd       # NEW — stamps templates at anchor positions
    chunk_streamer.gd         # extended — calls district_stamper before procedural placement
  data/
    district_templates.gd     # NEW — template definitions (slot lists, variant pools)
```

### DistrictStamper API

```gdscript
class_name DistrictStamper
extends RefCounted

# Stamp a template at an anchor position with variation.
# Returns count of nodes placed (for chunk_streamer's children count log).
func stamp_template(
    template_name: String,
    anchor_pos: Vector3,
    rotation_y: float,
    chunk_root: Node3D,
    crng: RandomNumberGenerator,
    streamer  # chunk_streamer instance — for _get_asset() access
) -> int

# Pick a template name for a given biome.
# Returns "" if no template defined for this biome (procedural fallback).
func pick_template_for_biome(biome: int, crng: RandomNumberGenerator) -> String
```

### Integration in chunk_streamer.gd

In `_build_chunk`, BEFORE the procedural placement loops:

```gdscript
# Phase A.7: try stamping a hand-authored template at the chunk's anchor
var anchor_pos := origin + Vector3(CHUNK_SIZE_M * 0.5, 0, CHUNK_SIZE_M * 0.5)
var template_name := _stamper.pick_template_for_biome(biome, crng)
if template_name != "":
    var rot := crng.randf_range(0, TAU)
    var placed := _stamper.stamp_template(template_name, anchor_pos, rot, chunk_root, crng, self)
    if placed > 0:
        # Mark the anchor's spatial exclusion zone so procedural placement
        # doesn't spawn buildings on top of the template
        spatial.insert(anchor_pos, 80.0)  # 150×150m template = 75m radius
        b_count += placed
        # Skip procedural placement for this chunk
        # (or only run it for areas outside the template footprint)
```

## The 3 starter templates

| # | Template | Biome | Layout sketch (top-down, 150×150m) |
|---|---|---|---|
| 1 | `suburb_block` | SUBURBIA | 4 houses at corners (variants: suburban_house_v2, bungalow, two_story_colonial, house_modern), cul-de-sac circle in center, corner_store at S entrance, picket_fence perimeter, 4 oak_tree, 4 mailbox |
| 2 | `commercial_strip` | COMMERCIAL | 4 storefronts along S edge (variants: corner_store, diner, store_pharmacy, grocery_store), surface parking lot in N half (asphalt_road_segment + 3 car placeholders), sidewalk furniture (trash_can, planter_box, parking_meter × 3), 2 oak_tree in planters |
| 3 | `downtown_block` | DOWNTOWN | 2 mid-rise buildings E+W (apartment_tower_high + highrise_office), 1 landmark at N (government_palace OR stadium), bollard × 6 along perimeter, planter_box × 4, traffic_light at SE corner, NO front yards (zero setback) |

## Slot + variant pool structure

Each template defines "slots" — positions where buildings/props go.
Each slot has a list of acceptable variants. At stamp time, the
stamper picks one variant per slot (using crng for determinism per chunk).

```gdscript
# Example: suburb_block building slots
{
    "name": "suburb_block",
    "size": Vector2(150, 150),
    "building_slots": [
        {"pos": [-50, 0, -50], "rot_y": 180, "variants": ["suburban_house_v2", "bungalow", "two_story_colonial"]},
        {"pos": [50, 0, -50], "rot_y": 180, "variants": ["bungalow", "house_modern"]},
        {"pos": [-50, 0, 50], "rot_y": 0, "variants": ["two_story_colonial", "house_victorian"]},
        {"pos": [50, 0, 50], "rot_y": 0, "variants": ["house_modern", "house_ranch"]},
        {"pos": [0, 0, -70], "rot_y": 0, "variants": ["corner_store"]}  # entrance store
    ],
    "foliage_slots": [
        {"pos": [0, 0, 0], "variants": ["oak_tree", "maple_tree"]},  # center
        {"pos": [-30, 0, 0], "variants": ["oak_tree"]},
        {"pos": [30, 0, 0], "variants": ["oak_tree", "birch_tree"]}
    ],
    "prop_slots": [
        {"pos": [-35, 0, -35], "variants": ["mailbox"]},
        {"pos": [35, 0, -35], "variants": ["mailbox"]},
        {"pos": [-35, 0, 35], "variants": ["mailbox"]},
        {"pos": [35, 0, 35], "variants": ["mailbox"]}
    ]
}
```

Variation per stamp:
1. Pick variant per slot (crng.randi() % variants.size())
2. Apply rotation_y jitter (±5° from slot's specified rot_y)
3. Skip empty slots with 10% probability (creates "vacant lot" feel)

## Variation level (b) details

For each template instance:
- **Rotation**: template-level yaw applied to whole template (0..TAU)
- **Asset variant pick**: per-slot random pick from variant list
- **Slot jitter**: ±5° rotation, no position jitter (positions stay clean)
- **Vacant lot**: 10% chance per building slot to skip (creates empty lots)

NOT applied at v1:
- Position jitter (keeps layout clean, matches PZ's rigid grid)
- Color tint (no material system support yet)
- Prop density jitter (per-prop count variation)

## TODO after authoring

- [ ] Create `tools/district_stamper.gd`
- [ ] Create `data/district_templates.gd` (template definitions)
- [ ] Wire into `chunk_streamer.gd` `_build_chunk`
- [ ] Headless verify (template stamps + spatial exclusion works)
- [ ] Iterate on layouts based on user feedback
