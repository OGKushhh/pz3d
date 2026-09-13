# Shells Needed — Buildings Whose Doors/Windows Affect Gameplay

> **Phase A.4 (2026-09-13)**
> Corrects the earlier handoff-doc claim of "80 buildings still need shells".
> The actual rule is narrower: a building needs a shell ONLY IF it has doors
> or windows that affect gameplay (player can open/break/climb them, or walk
> through them). Buildings whose doors/windows are visual-only, or which the
> player never enters, do NOT need shells.

## Rule

A building needs a shell variant (`<name>_shell.glb` + `<name>_components.json`)
if and only if ALL of the following are true:

1. The player can enter the building (interior is reachable)
2. The entry is gated by a door the player can open/break
3. OR the building has windows the player can smash / climb through

If a building is decorative, sealed, open-air, or accessed by ladder (no
door gameplay), it does NOT need a shell. Its monolithic `.glb` is fine.

## Status Legend

- ✓ **Done** — shell + component manifest exist
- ⏳ **TODO** — needs shell + components
- ⛔ **No shell needed** — visual / sealed / open / ladder-only

---

## ✓ Already has shell (7)

| Building | Biome | Why |
|---|---|---|
| `apartment_small` | Downtown | Residential, door + windows |
| `broadcast_tower` | Downtown (landmark) | Heavy door, player enters |
| `bungalow` | Suburbia | Front door + 3 windows |
| `cottage` | Farmland | Door + multiple windows |
| `garage_detached` | Farmland | Garage door (can_open) |
| `suburban_house_v2` | Suburbia | Door + windows |
| `two_story_colonial` | Suburbia | Door + multiple windows |

---

## ⏳ Needs shell — TODO (41 buildings)

### Suburbia residential variants (7)

| Building | Why |
|---|---|
| `house_modern` | Front door + windows |
| `house_split_level` | Front door + windows |
| `house_victorian` | Front door + multiple windows |
| `house_ranch` | Front door + windows |
| `house_cape_cod` | Front door + windows |
| `house_tudor` | Front door + windows |
| `house_cottage_stone` | Front door + windows |

### Forest enterable (3)

| Building | Why |
|---|---|
| `hunting_cabin` | Door, player loots inside |
| `ranger_station` | Multi-room, multiple doors |
| `logging_camp_shed` | Storage shed with door |

### Farmland enterable (3)

| Building | Why |
|---|---|
| `farmhouse` | Main residence, door + windows |
| `barn` | Big sliding door (can_open, can_climb) |
| `shed` | Small storage with door |

### Commercial — all enterable (14)

| Building | Why |
|---|---|
| `corner_store` | Storefront door + display windows |
| `diner` | Door + large windows (can_break) |
| `gas_station` | Store door + garage-style service door |
| `store_pharmacy` | Door + counter window |
| `store_gun` | Heavy door (can_lock), reinforced windows |
| `store_supermarket` | Automatic-style door + large windows |
| `motel` | Room doors (multiple, can_lock) + windows |
| `strip_mall` | Multiple storefront doors |
| `auto_repair_shop` | Garage door (can_open) + office door |
| `laundromat` | Glass storefront door + windows |
| `barber_shop` | Door + storefront window |
| `salon` | Door + storefront window |
| `grocery_store` | Automatic door + large windows |
| `bank_branch` | Heavy door (can_lock), vault door, teller windows |

### Industrial enterable (3)

| Building | Why |
|---|---|
| `warehouse` | Big rolling door + loading windows |
| `warehouse_large` | Multiple big doors |
| `factory_small` | Door + industrial windows |

### Wetlands / Coastal enterable (3 unique)

| Building | Why |
|---|---|
| `fishing_hut` | Small door, player loots |
| `houseboat` | Cabin door + small windows |
| `lighthouse` | Heavy door (can_lock), climbing interior |

### Downtown enterable (7)

| Building | Why |
|---|---|
| `apartment_tower_high` | Lobby door + many unit doors |
| `highrise_office` | Lobby door + office doors + windows |
| `hospital` | Multiple doors (rooms, surgery, morgue), windows |
| `police_station` | Door + jail cell doors (can_lock) |
| `railway_station` | Multiple doors + waiting-area windows |
| `school_elementary` | Classroom doors (can_lock) + windows |
| `church_small` | Big doors + stained-glass windows |

### Military enterable (4)

| Building | Why |
|---|---|
| `military_checkpoint` | Guard post door (can_lock) |
| `bunker_entrance` | Heavy blast door (can_lock, can_break=false) |
| `field_hospital_tent` | Tent flap (can_open, can_break) |
| `helipad_control_room` | Control room door |

### Civic landmarks (5 enterable)

| Building | Why |
|---|---|
| `government_palace` | Multiple grand doors, windows |
| `stadium` | Big entry doors + ticket windows |
| `old_royal_palace` | Lore says sealed — heavy doors, broken windows |
| `fort_sarran` | Endgame raid location — multiple military doors |
| `lighthouse` | (Same as Wetlands entry above) |

---

## ⛔ Does NOT need shell (19 buildings)

These are visual, sealed, open-air, or ladder-accessed. Player either can't
enter or doesn't need to interact with doors/windows on them.

### Decorative / open-air / ladder-only

| Building | Biome | Why no shell |
|---|---|---|
| `gazebo` | Parks | Open-air, no doors |
| `treehouse` | Suburbia | Ladder access, no door |
| `camping_tent` | Forest | Tent flap (not gameplay door) |
| `deer_stand` | Forest | Ladder, open platform |
| `cave_entrance` | Forest | Portal, not a door |
| `ranger_lean_to` | Forest | Open shelter |
| `tractor_shed` | Farmland | Open carport |
| `grain_storage_shed` | Farmland | Sealed, player doesn't enter |
| `utility_shed_metal` | Industrial | Small utility box, sealed |
| `shipping_container` | Industrial | Sealed |
| `storage_tank` | Industrial | Sealed |
| `loading_dock` | Industrial | Open structure |
| `marsh_pier` | Wetlands | Deck, no doors |
| `pier_dock` | Coastal | Deck, no doors |
| `parking_garage` | Downtown | Open structure, drive-through |
| `watchtower` | Military | Ladder, open top |
| `helipad` | Military | Open pad |

### Sealed / mostly-decorative landmarks

| Building | Why no shell |
|---|---|
| `grain_silo` | Sealed tower |
| `windmill` | Mostly decorative, player doesn't enter |
| `bridge_section` | Bridge segment, not enterable |

---

## Summary

| Category | Count |
|---|---|
| ✓ Already has shell | 7 |
| ⏳ Needs shell (TODO) | 41 |
| ⛔ No shell needed | 19 |
| **Total buildings** | **67** |

**Corrected claim:** "80 buildings still need shells" was wrong. Actual
TODO is **41 buildings** (after subtracting the 7 already done). All other
buildings either already have shells or don't need them.

## Recommended TODO order

Priority for shell authoring should follow gameplay-critical paths:

1. **High-traffic commercial (5)**: `corner_store`, `diner`, `gas_station`,
   `store_pharmacy`, `grocery_store` — players visit these constantly
   for food/meds/fuel.
2. **Hospital + police station (2)**: `hospital`, `police_station` —
   high-value loot, core PZ-style exploration.
3. **Suburbia variants (7)**: `house_modern`, `house_split_level`, etc. —
   player base locations, most common entry points.
4. **Barn + farmhouse (2)**: `barn`, `farmhouse` — large interiors, good
   starter bases.
5. **Military + landmark (5)**: `bunker_entrance`, `fort_sarran`,
   `government_palace`, `stadium`, `old_royal_palace` — endgame content.
6. **Everything else (20)**: the rest of the commercial/industrial/downtown
   shells, done in batches as art bandwidth allows.

## Pattern for authoring a new shell

Each TODO building follows the same workflow used for the original 7:

1. Copy `<name>.mog` to `<name>_shell.mog`
2. Edit the shell: in each `wall "..."` declaration, add `holes=[...]`
   entries for doors/windows based on the building's intended layout
3. Add `<name>_components.json` under `godot_project/data/building_components/`
   listing each door/window with `pos`, `rot_y`, `can_open`, `can_lock`,
   `can_break`, `can_climb`, `hinge_side` (for doors)
4. Compile: `mogen build <name>_shell.mog --out godot_project/assets/buildings/<name>_shell.glb`
5. Validate: `mogen check <name>_shell.mog`
6. Headless verify: `godot --headless --path godot_project --quit-after 80`
7. Commit + push

See `assets/buildings/src/bungalow_shell.mog` and
`godot_project/data/building_components/bungalow_components.json` as
reference templates.
