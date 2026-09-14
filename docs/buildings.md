# Buildings — Shells, Furniture, and District Templates

> **Canonical building design document.** Merges: shells_needed.md + furniture_decision.md + district_templates.md.
> Last updated: 2026-09-14.

---

# Part 1: Shells Needed — Which Buildings Need Shell Variants

> **Phase A.4 (2026-09-13)**
> A building needs a shell variant (`<name>_shell.glb` + `<name>_components.json`)
> ONLY IF its doors/windows affect gameplay.

## Rule

A building needs a shell if and only if ALL of the following are true:
1. The player can enter the building (interior is reachable)
2. The entry is gated by a door the player can open/break
3. OR the building has windows the player can smash / climb through

If a building is decorative, sealed, open-air, or accessed by ladder (no
door gameplay), it does NOT need a shell. Its monolithic `.glb` is fine.

## Status Legend
- ✓ **Done** — shell + component manifest exist
- ⏳ **TODO** — needs shell + components

## Residential Buildings (need shells — player enters, loots, sleeps)
- ✓ suburban_house_v2 — shell + components done
- ✓ bungalow — shell done
- ✓ cottage — shell done
- ✓ two_story_colonial — shell done
- ✓ garage_detached — shell done
- ⏳ house_modern, house_ranch, house_cape_cod, house_tudor, house_victorian — TODO
- ⏳ farmhouse, barn — TODO

## Commercial Buildings (need shells — player enters, loots)
- ⏳ corner_store, diner, gas_station, grocery_store, store_pharmacy, salon, barber_shop, laundromat — TODO

## Industrial Buildings (need shells — player enters for loot)
- ⏳ warehouse, warehouse_large, factory_small — TODO

## Downtown Buildings (need shells — player enters)
- ⏳ highrise_office, apartment_tower_high, apartment_small — TODO

## Buildings that DON'T need shells (visual-only or no door gameplay)
- stadium, government_palace, old_royal_palace, fort_sarran — landmarks, sealed
- lighthouse, broadcast_tower, watchtower, deer_stand — accessed by ladder
- shed, garden_shed_wood, utility_shed_metal — too small for interior
- All foliage, environment, props — not buildings

---

# Part 2: Furniture Decision — Static vs Dynamic

> **Status:** Locked design decision. Affects architecture.

## The conflict

| Goal | Implementation | Cost |
|---|---|---|
| **Performance** (60 FPS on 2GB VRAM) | Merge all furniture in a room into 1 mesh → 1 draw call per room | Can't move/destroy individual pieces |
| **PZ-style interactivity** (push bookshelf to block door, scrap chair for wood, loot fridge) | Keep each furniture piece separate + collision body | 30 draw calls per room, 5 rooms = 150 draw calls (25% of budget) |

## The hybrid solution 🔒

**Split furniture into 2 categories:**

### Static Fixtures (merged into building shell)
- Kitchen counters, bathroom sinks, built-in shelving, bathtubs, toilets
- These are part of the building. Player cannot move them.
- Baked into the shell mesh → 0 extra draw calls.

### Dynamic Furniture (separate meshes, PZ-style interactive)
- Chairs, tables, lamps, beds, wardrobes, fridges, TVs, bookshelves
- Player can push, scrap, loot, barricade with these.
- Each is a separate scene with its own collision body.
- Placed procedurally at runtime by `interior_builder.gd`.

## Performance budget (Low preset, 600 draw calls total)
- Buildings (exteriors): 100 draw calls (merged shells)
- Static fixtures: 0 (baked into shells)
- Dynamic furniture: 150 (30 per room × 5 visible rooms)
- Foliage: 50 (MultiMesh batched)
- Zombies: 50 (MultiMesh batched)
- Effects + UI: 50
- Total: 400 draw calls (under 600 budget)

---

# Part 3: District Templates — Hand-Authored Block Layouts

> **Phase A.7 (2026-09-13)**
> Hand-authored district templates bridge "fully procedural" pain to "hand-fixed" intent.

## What is a district template?

A small (~150×150m) hand-authored arrangement of buildings, props, foliage,
and (optional) internal roads. At runtime, `chunk_streamer.gd` stamps a
template at anchor positions with per-run variation.

## The PZ hybrid approach
- **Fixed at template-authoring time**: building footprints, road layout,
  lot sizes, prop positions, structural geometry.
- **Procedural per-run**: asset variant pick (which house variant, which
  fence style), rotation jitter, prop density variation, loot/zombie scatter.

## Decisions (locked 2026-09-13)

### Template size: 150×150m, single-chunk
Each template fits in one chunk (250m × 250m). Leaves 50m margin for
procedural fill around the stamped template.

### Coverage: ~30% (major biomes only)
- Downtown, Commercial, Industrial, Military get templates.
- Suburbia, Parks, Forest, Farmland, Wetlands, Coastal stay procedural.

### Current templates (4)
1. `suburb_block` — 4 houses at corners + corner store + cul-de-sac
2. `commercial_strip` — 4 storefronts + parking lot
3. `downtown_block` — landmark + 2 mid-rises + bollards
4. `industrial_block` — 2 warehouses + factory + loading dock

## Lot System (Phase B.6, 2026-09-14)
District templates stamp at BLOCK scale (150m). Lot recipes stamp at PARCEL
scale (20-30m). Together they form the authored skeleton:
- District template = hand-authored block
- Lot recipe = hand-authored parcel (house + garage + shed + sidewalk + driveway)
- Procedural fill = interior furniture, loot, zombies, decay layer

See `tools/lot.gd` for the 11 lot recipes (suburb, commercial, industrial,
downtown, farmland, military + attached variants).
