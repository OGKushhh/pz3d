# Poly Budget — Mazar Alpha

> **Target:** PC, 1080p, 60 FPS, first-person 3D open-world survival craft
> **Engine:** Godot 4.7.2, Forward+ renderer (Vulkan, cluster-based lighting)
> **Baseline GPU:** GTX 1660 / RX 5600 XT (mid-range)
> **Status:** v1 — locked. Adjust only if profiling shows we're over/under budget.

---

## 1. Engine-level budgets (per frame)

| Metric | Target | Hard ceiling | Notes |
|---|---|---|---|
| Frame time | 16.67 ms (60 FPS) | 33 ms (30 FPS minimum) | If we hit 33ms, drop to 30 FPS rather than stutter |
| Draw calls | ~1500 | 2000 | Godot's biggest perf lever — each mesh = 1 call unless merged |
| Triangles on-screen | ~2 M | 3 M | LODs are critical — see §4 |
| Texture memory (active) | ~3 GB | 4 GB | Low-end 4GB VRAM target |
| Real-time lights | ~8 (incl. sun) | 16 | Forward+ cluster handles this well; shadow-casting lights cost 6× |
| Shadow maps | sun + 4 spot/point | sun + 8 | Each shadow-casting light = extra render pass |
| Decals on screen | ~50 | 100 | Blood splatter, posters, grime |

---

## 2. Per-asset triangle budgets

### 2.1 Buildings

| Asset type | LOD0 (≤10 m) | LOD1 (10–30 m) | LOD2 (30–80 m) | LOD3 (80 m+ / billboard) | Notes |
|---|---|---|---|---|---|
| Hero building (landmark) | 30 000 | 12 000 | 4 000 | 800 | Hospital, Palace, Stadium — player walks up to these |
| Standard building (enterable) | 8 000 | 3 000 | 1 000 | 300 | Suburban house, shop, warehouse — player enters |
| Background building (non-enterable, decorative) | 1 500 | 600 | 200 | 50 | Skyscrapers seen from afar, decorative blocks |
| Interior shell (per room) | 4 000 | — | — | — | Walls, floor, ceiling, built-in counters. Player walks inside, no LOD needed. |
| Interior prop (per item) | 500 | — | — | — | Furniture, loot containers, decoration |

**Why these numbers:** a single standard enterable building (Suburbia house) at LOD0 = 8k tris. With 30 props inside averaging 500 tris = 15k. Total per building at close range = ~23k tris. With 5 buildings in view at once = ~115k tris. Well within budget.

### 2.2 Props (interior + handheld)

| Asset type | LOD0 | LOD1 | LOD2 | Notes |
|---|---|---|---|---|
| Held weapon (FPS view) | 8 000 | — | — | Always LOD0 — camera is 0.5 m away |
| Hero prop (loot container, important furniture) | 2 000 | 600 | 150 | Player inspects closely |
| Standard prop (chair, table, lamp) | 600 | 200 | 60 | Most furniture |
| Background prop (books, clutter, debris) | 150 | 50 | — | Scatter pieces |
| Small clutter (cans, bottles, paper) | 80 | — | — | Usually merged into prop cluster mesh |

### 2.3 Characters

| Asset type | LOD0 | LOD1 | LOD2 | LOD3 | Notes |
|---|---|---|---|---|---|
| Player character (DSL alpha) | 10 000 | 4 000 | 1 500 | 400 | Only 1 ever on screen (single-player) |
| Walker zombie | 8 000 | 3 000 | 1 000 | 300 | Crowds of 10–30 common |
| Crawler zombie | 6 000 | 2 000 | 700 | 200 | Less geometry (no legs) |
| NPC (Mazar Republic, Junta, Survivor) | 10 000 | 4 000 | 1 500 | 400 | Few on screen at once |

**Walker budget math:** 30 walkers at LOD0 = 240k tris. 30 walkers at LOD1 (15 m away) = 90k. Manageable.

### 2.4 Foliage

| Asset type | LOD0 | LOD1 | LOD2 | LOD3 (billboard) | Notes |
|---|---|---|---|---|---|
| Hero tree (oak, pine) | 2 500 | 800 | 250 | 50 (billboard) | Player walks under these |
| Standard tree | 1 200 | 400 | 120 | 30 | Forest density |
| Bush | 400 | 150 | 50 | — | Undergrowth |
| Grass tuft | 80 | — | — | — | Merged into ground cover cluster |
| Grass field (cluster mesh) | 5 000 | 1 500 | 400 | — | 1 draw call for 100+ blades |

**Forest scene math:** 50 trees at LOD1 (15 m away) = 20k tris. 100 bushes at LOD1 = 15k. Grass cluster = 5k. Total forest scene = ~40k. Trivial.

### 2.5 Vehicles

| Asset type | LOD0 | LOD1 | LOD2 | Notes |
|---|---|---|---|---|
| Sedan (driveable) | 12 000 | 4 000 | 1 200 | Player walks around + enters |
| Pickup truck (driveable) | 15 000 | 5 000 | 1 500 | Bigger, more detail |
| Bicycle (driveable) | 3 000 | 1 000 | 300 | Simple geometry |
| Abandoned car (decoration, non-driveable) | 4 000 | 1 200 | 400 | Lower detail than driveable |

### 2.6 Decals + environment

| Asset type | Budget | Notes |
|---|---|---|
| Blood splatter decal | 6 verts (quad) | Pure texture, no geometry |
| Bullet hole decal | 6 verts | Same |
| Poster/graffiti decal | 6 verts | Same |
| Road segment (per 10m) | 200 tris | Including curbs, sidewalk |
| Fence segment (per 2m) | 300 tris | Pickets + rails |
| Sidewalk segment | 100 tris | Flat slab with curbs |
| Terrain patch (per 100m²) | 2 000 tris | Heightmap, low-poly base |

---

## 3. Per-biome scene budgets

When a player stands in the middle of a biome, what's on screen at once?

| Biome | Buildings | Props | Foliage | Characters | Total tris target |
|---|---|---|---|---|---|
| Suburbia (5 houses in view) | 5 × 8k = 40k | 5 × 15k interior = 75k | 50 bushes + 20 trees = 28k | 5 zombies = 40k | **~180k** |
| Parks & Greenways (open) | 0 | 5k | 200 trees + 500 bushes = 320k | 3 zombies = 24k | **~350k** |
| Forest (dense) | 0 | 0 (interior) | 500 trees + 1000 bushes = 1M | 2 zombies = 16k | **~1M** ⚠️ highest |
| Farmland (open) | 2 farms = 16k | 5k interiors | 50 trees + 200 bushes = 106k | 2 zombies = 16k | **~140k** |
| Commercial Strip (street) | 8 shops × 4k = 32k | 100 props × 500 = 50k | 10 trees = 12k | 10 zombies = 80k | **~175k** |
| Industrial Park | 4 warehouses × 12k = 48k | 30 props = 15k | 0 | 8 zombies = 64k | **~130k** |
| River & Wetlands | 3 houseboats × 4k = 12k | 5k | 100 reeds = 5k | 4 zombies = 32k | **~55k** |
| Subway (tunnel view) | 0 | 20 props = 10k | 0 | 8 zombies = 64k | **~75k** |
| Downtown (street view) | 10 high-rises × 1500 BG = 15k + 2 hero × 30k = 60k → 75k | 50 props = 25k | 5 trees = 6k | 20 zombies = 160k | **~270k** |
| Military Zone (compound) | 6 structures × 5k = 30k | 30 props = 15k | 0 | 15 zombies = 120k | **~165k** |

**All under 3M target.** Forest is the heaviest at ~1M due to foliage density — that's where LOD discipline matters most.

---

## 4. LOD strategy (mandatory for alpha)

Every asset that can be seen at >10m distance MUST have an LOD chain.

| Asset type | LOD0 → LOD1 swap | LOD1 → LOD2 swap | LOD2 → LOD3 swap |
|---|---|---|---|
| Buildings | 10 m | 30 m | 80 m |
| Trees | 10 m | 25 m | 60 m → billboard |
| Vehicles | 15 m | 40 m | 100 m |
| Characters | 12 m | 30 m | 80 m |
| Props (interior) | n/a (always LOD0 — player is inside) | | |

**Godot implementation:** use `LOD_MULTIPLIER` project setting or per-mesh `lod_bias`. Set up auto-LOD generation in Godot's import settings — Godot 4.x can generate LODs automatically from a single mesh.

**MoGen implication:** I can author a single LOD0 mesh. Godot generates LOD1-3 at import time. Saves me from authoring 4 versions per asset.

---

## 5. Draw call budget strategy

Draw calls are Godot's biggest perf lever — bigger than triangle count.

**Strategies:**
1. **Merge static meshes** — Godot's `MeshLibrary` + `GridMap` for repeated props (fence segments, road segments). One draw call for 100 segments.
2. **Instanced rendering** — `MultiMeshInstance3D` for foliage (grass, trees). One draw call for 10 000 instances.
3. **Merge building interiors** — combine all furniture in a room into one merged mesh. Reduces 30 draw calls to 1.
4. **Atlas textures** — pack all prop textures into a single 4K atlas. One material per category → fewer shader binds.
5. **Cull aggressively** — Godot's occlusion culling (`OccluderInstance3D`) for buildings. Don't render what's behind walls.

**Draw call estimate per scene:**
- Suburbia (5 houses + interiors): 5 buildings × 1 merged = 5 + 5 interiors × 1 merged = 5 + 5 × 30 props = 150 + 5 zombies = 5 + foliage (3 multimeshes) = 3 + player + weapon + UI = ~165 draw calls. ✅ Well under 2000.

- Downtown (10 high-rises + 2 hero + 50 props + 20 zombies): 12 buildings + 50 props (merged to 5 clusters) + 20 zombies + 5 foliage + player = ~45 draw calls. ✅ Even better.

---

## 6. Texture memory budget

**Per-texture targets (after texture compression):**

| Texture type | Resolution | Format | VRAM |
|---|---|---|---|
| Hero albedo (held weapon, hero building) | 2048² | BPTC (desktop) / ASTC (mobile) | 4 MB |
| Standard albedo (most props/buildings) | 1024² | BPTC | 1 MB |
| Background albedo | 512² | BPTC | 256 KB |
| Normal map (matches albedo size) | matches | BPTC | same as albedo |
| Metallic-roughness (matches) | matches | BPTC | same |
| AO (matches) | matches | BPTC | same |
| Atlas (foliage, road, fence) | 4096² | BPTC | 16 MB |
| UI sprites | 512² | uncompressed | 1 MB |

**Total texture memory budget:** 4 GB VRAM target.
- ~1 GB for hero assets (player weapon, character, near props)
- ~1 GB for nearby buildings (5-10 in view)
- ~1 GB for foliage + ground cover (atlased)
- ~500 MB for effects (post-processing, decals, particles)
- ~500 MB headroom

**MoGen implication:** `mogen textures --texture-size 512` is the default — perfect for our standard albedo budget. Use `--texture-size 1024` only for hero assets.

---

## 7. Lighting budget

Godot 4.x Forward+ uses cluster-based lighting — handles many lights well, but each shadow-casting light costs ~6× a non-shadow light.

| Light type | Count | Shadow? | Cost |
|---|---|---|---|
| Sun (directional) | 1 | Yes | Fixed cost — always on |
| Sky light (fill) | 1 (env) | No | Cheap |
| Street lamps (point) | up to 4 visible | Yes (player needs to see pools of light) | 4 × 6 = 24 cost units |
| Interior lights (point/spot) | up to 8 in interiors | Yes (gameplay — light = safety) | 8 × 6 = 48 cost units |
| Muzzle flash (spot, transient) | 1 per shot | No | Brief, ignorable |
| Flashlight (spot, attached to camera) | 1 | Yes | Always on when active |
| Fire/glow effects (point) | up to 4 | No | Decoration |

**Total: ~16 shadow-casting lights worst case.** Forward+ handles this; older Mobile renderer would choke.

---

## 8. Streaming budget

For a 4 km × 3 km open world, we need streaming (not loading the whole map at once).

**Godot's recommended pattern:**
- Use `ResourceLoader.load_threaded_request` for async chunk loading
- Chunk size: 250m × 250m (16 chunks per 1km², 192 chunks total for our 12km² map)
- Each chunk = ~50 MB on disk (buildings + interiors + foliage + terrain)
- Keep 9 chunks in memory at once (player + 8 neighbors) = ~450 MB RAM
- Fog at ~150-200m hides chunk pop-in

**MoGen implication:** each chunk's buildings can be authored as separate `.mog` files. Godot imports them as separate GLBs and streams them.

---

## 9. CPU-side budget (gameplay thread)

| Task | Budget (ms) | Notes |
|---|---|---|
| Zombie AI (pathfinding + state) | 4 ms | Cap at 30 active zombies. Use RVO avoidance. |
| Player input + camera | 0.5 ms | Cheap |
| Physics (player + zombies + props) | 3 ms | Use Godot's Jolt physics for big perf boost |
| Inventory + UI | 0.5 ms | Event-driven |
| Sound propagation grid update | 1 ms | Custom system, can be slow path |
| Save game checkpoint | 0.1 ms | Async to disk |
| **Total CPU** | **9 ms** | Leaves 7 ms for renderer |

---

## 10. Profiling plan (post-alpha vertical slice)

Once we have the Suburbia vertical slice running:
1. Run Godot's built-in profiler (Debugger → Profiler)
2. Capture a frame in RenderDoc
3. Identify top 5 draw calls by cost
4. Identify top 5 scripts by CPU time
5. Adjust budgets based on actual measurements, not estimates

**Rule:** if we're under budget on triangles but over budget on draw calls, merge more meshes. If we're under on draw calls but over on triangles, tighten LODs. If both are fine but FPS is bad, the bottleneck is shaders or post-processing — fix the post chain.

---

## 11. Summary — locked budgets for Tier 1 production

For Tier 1 style anchors, I'll target these LOD0 numbers (no LOD1-3 yet, those come at Godot import):

| Tier 1 asset | LOD0 budget | Notes |
|---|---|---|
| Suburban house v2 (exterior shell) | 8 000 tris | Standard enterable building |
| Office chair | 600 tris | Standard prop |
| Dining table | 800 tris | Standard prop (bigger than chair) |
| Oak tree | 2 500 tris | Hero tree |
| Bush | 400 tris | Standard bush |
| Sedan | 12 000 tris | Driveable vehicle |
| Pickup truck | 15 000 tris | Driveable vehicle |
| Blood splatter decal | 6 verts | Quad decal |
| Asphalt road segment (10 m) | 200 tris | Environment |

I'll author to these budgets. If an asset comes in over, I either reduce segments or split it.

---

## Appendix — Godot 4.7.2 specific notes

- **Forward+ is the default renderer for desktop.** Use it.
- **Jolt physics plugin** (via Godot Jolt addon) is significantly faster than the default bullet integration. Use it for survival games with many dynamic objects.
- **Occlusion culling** was added in Godot 4.3. Use `OccluderInstance3D` on hero buildings.
- **Vulkan ray-tracing** is supported in 4.3+ but only on RTX cards — don't depend on it.
- **Mesh LOD auto-generation** is built into Godot 4.x import settings. Author LOD0, let Godot generate LOD1-3.
- ** decals** via `Decal` node — single quad, projects onto surfaces. Cheap.

For full Godot 4.x performance guidance, see the official docs: <https://docs.godotengine.org/en/stable/tutorials/performance/using_large_worlds.html>
