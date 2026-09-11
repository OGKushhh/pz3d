# Furniture Merging Decision — Static vs Dynamic

> **Trigger:** User asked: "you mentioned that for optimization you will group interior furniture under 1 mesh. what if we decided to go pz style and scrap 1 prop furniture or move it, would that be an issue?"
> **Status:** Locked design decision. Affects architecture.

---

## The conflict

Two competing goals:

| Goal | Implementation | Cost |
|---|---|---|
| **Performance** (60 FPS on 2GB VRAM) | Merge all furniture in a room into 1 mesh → 1 draw call per room | Can't move/destroy individual pieces |
| **PZ-style interactivity** (push bookshelf to block door, scrap chair for wood, loot fridge) | Keep each furniture piece as a separate mesh + collision body | 30 draw calls per room, 5 rooms visible = 150 draw calls (25% of Low budget) |

If we go full-merge: we lose the survival-game fantasy. Can't barricade doors with furniture. Can't search individual containers.

If we go full-separate: we blow the draw call budget on Low preset. 150 draw calls just for furniture, before we add zombies, buildings, foliage, effects.

---

## The hybrid solution 🔒

**Split furniture into 2 categories:**

### Static furniture (merged into 1 mesh per room)
- **Kitchen counter** (built-in, attached to wall)
- **Bathroom sink + toilet + bathtub** (plumbed in, never moves)
- **Built-in shelving** (wall-mounted, fixed)
- **Staircase** (structural)
- **Fireplace** (structural)
- **Window frames + door frames** (structural)

These merge with the room shell into one mesh. **0 extra draw calls** (already part of the room mesh). Can never be moved or destroyed. Players accept this — you can't move a kitchen counter in real life either.

### Dynamic furniture (separate meshes, physics bodies)
- **Chairs** (movable, throwable, barricade material)
- **Tables** (movable, can hide under)
- **Bookshelves** (can be pushed to block doors)
- **Beds** (movable but heavy)
- **Sofas** (movable but heavy)
- **Refrigerator** (loot container, can be pushed with effort)
- **Lamps** (movable, can be knocked over for noise)
- **TV** (loot container for electronics, throwable)
- **Small props** (cans, bottles, books, debris — throwable for distraction)

Each dynamic piece = 1 draw call + 1 physics body. **Cap at 10 dynamic props visible per room.** 5 rooms visible = 50 draw calls. Manageable on Low preset.

---

## How this maps to MoGen + Godot

### MoGen authoring pattern

```
// Per room in a building .mog file:

solid "kitchen_static" (mat="wood", cleanup="coplanar") {
  // These all merge into 1 mesh at export time
  box "counter_left"  (...)
  box "counter_right" (...)
  box "stove"          (...)
  box "sink"           (...)
  box "wall_cabinet_1" (...)
  box "wall_cabinet_2" (...)
}

// Dynamic furniture — authored separately, exported as separate meshes
group "kitchen_dynamic" {
  // Each of these becomes a separate node in the GLB
  // → Godot imports each as a separate RigidBody3D
  use "chair" ()  // module reference
  use "table_kitchen" ()
  use "fridge" ()
  use "lamp_floor" ()
}
```

### Godot scene structure

```
Room (Node3D)
├── StaticMesh (MeshInstance3D) ← kitchen_static, merged. No physics.
├── DynamicFurniture (Node3D)
│   ├── Chair_001 (RigidBody3D + MeshInstance3D + CollisionShape3D)
│   ├── Chair_002 (RigidBody3D + MeshInstance3D + CollisionShape3D)
│   ├── Table_001 (RigidBody3D + MeshInstance3D + CollisionShape3D)
│   ├── Fridge_001 (RigidBody3D + MeshInstance3D + CollisionShape3D + LootContainer)
│   └── Lamp_001 (RigidBody3D + MeshInstance3D + CollisionShape3D + Light3D)
└── LootContainers (Node3D)  ← procedural spawn points
    ├── Drawer_001 (LootContainer, child of static counter)
    ├── Cabinet_001 (LootContainer, child of static cabinet)
    └── ...
```

### Loot containers (the PZ "search every drawer" fantasy)

Even static furniture can have loot containers — they just don't move. The kitchen counter has 3 drawer LootContainer children, each with its own loot roll. Player walks up, opens drawer, gets loot. Counter doesn't move, but the interaction is there.

This is actually how PZ does it — the kitchen counter is part of the tile, but the drawers are interactive hotspots on it.

---

## Draw call budget breakdown (Low preset, worst case)

For a Suburbia kitchen interior (player standing inside, looking around):

| Item | Draw calls |
|---|---|
| Room shell (walls + floor + ceiling + static kitchen merged) | 1 |
| Dynamic furniture (5 pieces visible: chair, table, fridge, lamp, trash can) | 5 |
| Loot containers (procedural spawns, no extra mesh — they're hotspots on static mesh) | 0 |
| Small clutter props (cans, bottles, books, debris — merged into 1 "clutter" mesh per room) | 1 |
| Decals on floor/walls (blood, grime — max 5 visible) | 5 |
| Player weapon + hands | 2 |
| Lighting (sun, no dynamic interior lights on Low preset) | 0 (lit via baked vertex color) |
| **Total per room** | **14** |

For 5 rooms visible at once (open-plan house): 5 × 14 = 70 draw calls. Well under 600 Low budget.

---

## What this means for asset production

When I author a building (e.g. suburban_house_v2), I include:
- Exterior shell (walls, roof, doors, windows) — merged in `solid` group
- Interior shells per room (floor, ceiling, walls) — merged
- Static furniture per room (counters, sinks, built-ins) — merged with room shell
- **Dynamic furniture is authored separately as standalone .mog files** (chair, table, bed, fridge, etc.) and placed in the Godot scene as separate RigidBody3D nodes during procedural interior generation

So our `props/` category holds the dynamic furniture. Our `buildings/` category holds the exteriors + static interiors. Both are needed.

---

## What we lose vs full PZ-style

- Can't scrap a kitchen counter for wood (it's part of the room mesh)
- Can't move a toilet (it's plumbed in — fair)
- Can't destroy built-in shelving (it's structural)

**What we keep:**
- Push bookshelf to block door ✅
- Throw chair to distract zombie ✅
- Search every drawer in the kitchen counter ✅
- Loot fridge as container ✅
- Scrap dynamic chairs/tables/beds for wood ✅
- Knock over lamp for noise ✅

This is the right tradeoff. PZ itself does roughly this — tile-based static fixtures + dynamic props.

---

## Locked decision 🔒

1. **Static furniture** (kitchen counters, sinks, toilets, built-ins) = merged into room mesh. No physics. No moving. No scrapping.
2. **Dynamic furniture** (chairs, tables, beds, fridges, lamps, bookshelves) = separate meshes + RigidBody3D + CollisionShape3D. Can be moved, thrown, scrapped, used as barricade.
3. **Cap: 10 dynamic props visible per room** on Low preset. 15 on High. 25 on Ultra.
4. **Loot containers** can exist on both static and dynamic furniture — they're interaction hotspots, not separate meshes.
5. **Small clutter** (cans, bottles, books, debris) = merged into 1 "clutter mesh" per room. Visual only, no interaction. Players can't pick up a can lying on a table — they interact with the table's loot container instead.

This is locked. Asset production follows this pattern from now on.
