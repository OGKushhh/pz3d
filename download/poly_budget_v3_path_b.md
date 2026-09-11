# Path B Locked — Two-Tier Preset + Gemini Profile Assessment

> **Trigger:** User picked Path B (two-tier: Low preset baseline + High preset for stronger PCs). Wants Gemini's "Low Graphics" profile assessed critically before locking, with possibility of dynamic improvements.
> **Status:** v3 poly budget — supersedes v1 (mid-range) and v2 (low-end). This is the **locked final budget for alpha**.

---

## 1. Decision: Path B locked 🔒

Two-tier graphics presets. Same game, two profiles:

| Preset | Target hardware | Goal |
|---|---|---|
| **Low** | 2GB VRAM / 4GB RAM (Intel HD 4000, GT 730, 2012-2015 PCs) | Stable 60 FPS at 1080p |
| **High** | 6GB+ VRAM / 8GB+ RAM (GTX 1660+, 2018+ PCs) | 60 FPS at 1080p with eye-candy |
| **Ultra** (v1 stretch) | 8GB+ VRAM / 16GB+ RAM (RTX 3060+, 2020+ PCs) | 60 FPS at 1440p |

**Alpha default = Low preset.** We develop and test against the Low preset. High preset is a settings toggle for playtesting on better hardware.

---

## 2. Gemini's profile — point-by-point assessment

I went through Gemini's checklist line by line. Some is correct, some needs refinement, some is wrong. Honest assessment below.

### 2.1 Display & Engine Settings

| Gemini says | My assessment | Verdict |
|---|---|---|
| Resolution: Native 1080p (drop to 720p internal if Intel iGPU, UI stays 1080p) | ✅ **Correct.** UI at 1080p is critical for readability. Internal render scale is the right lever. Godot's `Stretch` mode handles this elegantly. | ✅ LOCK |
| Renderer: Compatibility Mode (OpenGL 3.3). Switch to Forward+ for "High Graphics" preset. | ⚠️ **Partially correct, with caveat.** Switching renderers at runtime in Godot 4.x is **not officially supported** — you'd have to restart the game. Two options: (a) require restart when switching presets, (b) keep Compatibility renderer always and tune settings within it. **My recommendation:** keep Compatibility as the alpha default. Add Forward+ as a "Beta Vulkan renderer" option in v1 that requires restart. | 🔓 REFINED: keep Compatibility for alpha, add Forward+ as restart-required option in v1 |
| "or just keep it opengl if it's more stable" | ✅ **Agree.** OpenGL Compatibility is more stable on more hardware. Vulkan Forward+ has nice features but adds crash risk on older drivers. | ✅ LOCK: Compatibility for alpha |
| Max Draw Calls: 600 (strict cap) | ✅ **Correct.** For 2GB VRAM target, 600 is the right ceiling. | ✅ LOCK |
| View/Draw Distance: 150 meters maximum | ⚠️ **I'd go lower.** 150m is too far for 2GB VRAM — that's 7 hectares of visible terrain, buildings, foliage. I'd set view distance to **100m** for Low preset, with fog starting at 60m to hide pop-in. 150m for High preset. | 🔓 REFINED: 100m Low / 150m High / 250m Ultra |

### 2.2 Environment & Geometry Budgets

| Gemini says | My assessment | Verdict |
|---|---|---|
| Max On-Screen Triangles: 500,000 | ✅ **Correct.** This is the right ceiling for 2GB VRAM. I had 400k in v2 — 500k is fine, gives a small margin. | ✅ LOCK: 500k Low / 1.5M High / 3M Ultra |
| Distant Foliage / Trees: 2D Billboards past 60 meters (2 tris per tree) | ✅ **Correct and important.** Billboards are the only way to render a forest on 2GB VRAM. Godot 4.x supports this via `MultiMeshInstance3D` with billboard materials. Swap LOD3 → billboard at 60m. | ✅ LOCK: 60m → billboard |
| Close Foliage (Grass/Bushes): MultiMeshInstance3D, 1-2 draw calls | ✅ **Correct.** Already in my plan. One MultiMesh = thousands of instances in one draw call. | ✅ LOCK |
| Terrain Loading: 3×3 grid chunking, instant unload | ⚠️ **Partially correct.** 3×3 grid is fine for 4GB RAM. But "instant unload" is too aggressive — causes hitching. Should be: 5×5 grid loaded (player + 2 rings), inner 3×3 fully active, outer ring is "warm" (loaded but culled). Unload chunks 2.5 rings away. | 🔓 REFINED: 5×5 loaded, 3×3 active, unload at 2.5 rings |

### 2.3 AI & Gameplay Systems

| Gemini says | My assessment | Verdict |
|---|---|---|
| Max Active On-Screen Zombies: 30 Max | ✅ **Correct.** 30 is the right ceiling for Low preset on 4GB RAM. Earlier I said 15 — that was too conservative. 30 × 3k tris = 90k tris (under our 500k triangle budget), 30 AI ticks is manageable on a single thread. | ✅ LOCK: 30 Low / 60 High / 100 Ultra |
| Zombie AI Optimization: Staggered Tick Rates | ✅ **Correct and excellent advice.** This is the key optimization most survival games miss. Tiered tick rates based on distance are exactly right. | ✅ LOCK |
| Close zombies (<15m): Update pathfinding every frame | ✅ **Correct.** When a zombie is in your face, you need it to react instantly. | ✅ LOCK |
| Mid-distance zombies (15m-40m): Update every 5 frames (~12 Hz) | ✅ **Correct.** At 15m+ you don't notice 12 Hz pathfinding updates. | ✅ LOCK |
| Distant zombies (>40m): Update every 15 frames (~4 Hz) | ⚠️ **Partially correct.** 4 Hz is fine for idle zombies, but if they're chasing the player from 40m, they'll look stuttery. Better: distant zombies don't pathfind at all — they walk directly toward player's last known position, updated every 5 seconds. | 🔓 REFINED: distant zombies use last-known-position steering, not pathfinding |

### 2.4 Textures, Lighting, & Materials

| Gemini says | My assessment | Verdict |
|---|---|---|
| Texture Resolution: Max 256×256 per texture map | ✅ **Correct.** 256² is the right ceiling for Low preset. With BPTC compression that's ~64KB per texture. We can fit ~5000 textures in 800MB VRAM. Atlas for repeated materials. | ✅ LOCK: 256² Low / 1024² High / 2048² Ultra |
| "Heavily utilize unified color palettes where hundreds of low-poly models share one tiny image" | ✅ **Excellent advice.** This is atlasing done right. One 256² atlas with 16 sub-textures = 16 unique materials in 64KB. | ✅ LOCK |
| Dynamic Shadows: Disabled entirely. Turn off sun shadows. | ⚠️ **I'd refine this.** No shadows at all looks flat and breaks immersion. Better: sun shadows ON but at 1024² resolution with hard edges (no PCF filtering). Costs ~2ms per frame on 2GB VRAM. Worth it for the visual cohesion. | 🔓 REFINED: 1024² hard sun shadows Low / 2048² PCF High / 4096² PCF Ultra |
| Fake Contact Shadows: Blob shadow sprites beneath feet | ✅ **Correct.** This is the standard technique. Single radial gradient texture projected as a decal beneath characters/vehicles. Cheap (1 draw call per actor). | ✅ LOCK |
| World Lighting: Baked Vertex Colors or baked lightmaps only | ✅ **Correct for Low preset.** Bake everything. Use Godot's `BakedLightmap` for interiors + vertex color AO on exteriors. | ✅ LOCK: baked Low / mixed (baked GI + 1 dynamic sun) High / fully dynamic Ultra |
| "Time-of-day changes should be simulated using simple ambient color shifting, not moving dynamic lights" | ✅ **Correct.** Sun "moves" by changing sky color + ambient color + fog color, not by actually rotating the DirectionalLight3D. Light direction stays fixed (overhead at noon, low at dusk). | ✅ LOCK |

### 2.5 The GDScript implementation example

Gemini's `apply_low_graphics_preset()` snippet is correct — it does what it claims. But it's incomplete. The full preset should also:
- Set `RenderingServer.texture_streaming_budget` (memory pool)
- Toggle `GeometryInstance3D.visibility_range_end` per asset
- Switch `Material` resources to their low-res variants (use Godot's `Resource` system)
- Cap `MultiMeshInstance3D.instance_count` per foliage type
- Adjust zombie AI tick rates (Gemini got this in §2.3)

I'll write the full preset implementation when we hit Godot scene assembly (Milestone 1).

---

## 3. Locked v3 budget — alpha Low preset

### 3.1 Engine-level budgets (per frame, Low preset)

| Metric | Low preset (alpha default) | High preset | Ultra (v1) |
|---|---|---|---|
| Internal resolution | 1080p (drop to 720p on Intel iGPU detected) | 1080p native | 1440p |
| Renderer | Compatibility (OpenGL 3.3) | Compatibility (alpha) / Forward+ (v1) | Forward+ |
| Frame time | 16.67 ms (60 FPS) | 16.67 ms | 11.1 ms (90 FPS) or 16.67 ms with eye candy |
| Draw calls | 600 max | 1500 max | 2500 max |
| On-screen triangles | 500k max | 1.5M max | 3M max |
| Texture memory (active) | 800 MB | 2 GB | 4 GB |
| View distance | 100m | 200m | 300m+ |
| Fog start | 60m | 150m | 250m |
| Foliage billboard swap | 60m | 100m | 150m |
| Real-time shadow lights | sun only (1024² hard) | sun + 4 spot (2048² PCF) | sun + 8 (4096² PCF) |
| Decals on screen | 30 | 80 | 200 |
| Time-of-day | ambient color shift only (bake everything) | mixed bake + 1 dynamic sun | fully dynamic |
| Active chunks in memory | 3×3 active + 5×5 warm | 5×5 active + 7×7 warm | 7×7 active + 9×9 warm |

### 3.2 Per-asset triangle budgets (Low preset LOD0)

Updated to reflect Gemini's 500k on-screen ceiling. Slightly more generous than my v2 (which targeted 400k).

| Asset type | Low LOD0 | Low LOD1 | Low LOD2 | Low LOD3 (billboard) |
|---|---|---|---|---|
| Hero building (landmark) | 8 000 | 3 000 | 1 000 | 300 |
| Standard enterable building | 2 500 | 800 | 250 | 80 |
| Background building | 500 | 200 | 80 | 30 |
| Interior shell (per room) | 1 500 | — | — | — |
| Interior prop (per item) | 200 | 80 | — | — |
| Held weapon (FPS view) | 3 000 | — | — | — |
| Hero prop | 800 | 250 | 80 | — |
| Standard prop | 250 | 80 | 30 | — |
| Background prop | 80 | 30 | — | — |
| Player character | 4 000 | 1 200 | 400 | 120 |
| Walker zombie | 3 000 | 800 | 250 | 80 |
| Crawler zombie | 2 000 | 600 | 200 | 60 |
| Hero tree | 1 200 | 400 | 120 | 30 (billboard) |
| Standard tree | 500 | 200 | 60 | 20 (billboard) |
| Bush | 200 | 80 | — | — |
| Driveable sedan | 4 000 | 1 200 | 400 | — |
| Driveable pickup | 5 000 | 1 500 | 500 | — |
| Decal | 6 verts | — | — | — |
| Road segment (per 10m) | 80 tris | — | — | — |

### 3.3 Zombie dynamic count system 🔒

**Key improvement on Gemini's profile:** zombies scale based on hardware.

| Preset | Max on-screen | Max active AI | Tick rate (close/mid/far) |
|---|---|---|---|
| Low | 30 | 30 | 60 Hz / 12 Hz / last-known-position steering |
| High | 60 | 60 | 60 Hz / 20 Hz / 4 Hz pathfinding |
| Ultra | 100 | 100 | 60 Hz / 30 Hz / 8 Hz pathfinding |

**Implementation:** `Settings.zombie_quality` enum (LOW/HIGH/ULTRA). Game reads it at scene load + on settings change. Caps the zombie spawner + adjusts tick rates.

### 3.4 Texture budgets (Low preset)

| Texture type | Low preset size | VRAM |
|---|---|---|
| Hero albedo (held weapon) | 512² | 256 KB |
| Standard albedo | 256² | 64 KB |
| Background albedo | 128² | 16 KB |
| Atlas (foliage, road, fence) | 1024² | 1 MB |
| UI sprites | 256² | 64 KB |
| Blob shadow | 64² | 4 KB |

**Atlas strategy:** one 1024² atlas per biome = 16 sub-textures. Reused across hundreds of props. This is Gemini's "unified color palette" point and it's exactly right.

### 3.5 Per-biome scene budgets (Low preset, worst case)

Worst-case tris on screen at once, with v3 Low budgets + 30 zombie cap:

| Biome | Buildings | Props | Foliage | Zombies (max 30) | Total | Under 500k? |
|---|---|---|---|---|---|---|
| Suburbia (5 houses) | 5×2.5k=12.5k | 5×1.5k interior=7.5k | 50 bushes + 20 trees=18k | 10×3k=30k | **68k** | ✅ |
| Parks & Greenways | 0 | 1k | 100 trees + 300 bushes (multimesh)=10k | 5×3k=15k | **26k** | ✅ |
| Forest (dense) | 0 | 0 | 200 trees (50 visible + 150 billboard) + 400 bushes multimesh=70k | 5×3k=15k | **85k** | ✅ |
| Farmland | 2×2.5k=5k | 2k | 30 trees + 100 bushes=25k | 3×3k=9k | **41k** | ✅ |
| Commercial Strip | 8 shops×1k=8k | 50 props×250=12.5k | 5 trees=3k | 10×3k=30k | **53.5k** | ✅ |
| Industrial Park | 4 warehouses×3k=12k | 30 props=6k | 0 | 8×3k=24k | **42k** | ✅ |
| River & Wetlands | 3 houseboats×1.5k=4.5k | 2k | 50 reeds multimesh=2k | 4×3k=12k | **20.5k** | ✅ |
| Subway (tunnel view) | 0 | 15 props×250=3.75k | 0 | 8×3k=24k | **27.75k** | ✅ |
| Downtown | 10 BG×500=5k + 2 hero×8k=16k → 21k | 25 props=6.25k | 3 trees=1.5k | 15×3k=45k | **73.75k** | ✅ |
| Military Zone | 6 structures×2k=12k | 15 props=3.75k | 0 | 15×3k=45k | **60.75k** | ✅ |

**All under 500k.** Largest scene is Downtown at 74k — well under budget. We have ~7× headroom on the triangle budget.

### 3.6 Tier 1 asset v3 status

With Low preset LOD0 budgets:

| # | Asset | Built tris | Low LOD0 budget | Status |
|---|---|---|---|---|
| 1 | suburban_house_v2 | 1,800 | 2,500 | ✅ under |
| 2 | office_chair | 6,500 | 250 | ❌ 26× over |
| 3 | dining_table | 460 | 250 | ❌ 1.8× over |
| 4 | oak_tree (fixed) | 2,400 | 1,200 | ❌ 2× over |
| 5 | bush | 360 | 200 | ❌ 1.8× over |

**Note:** these are LOD0 budgets. The current assets are perfectly fine as LOD0 for the **High preset** (where standard prop budget is 600). For Low preset, I'll rebuild them with `subdivisions=1` instead of `2`, fewer segments, smaller canopies.

**Plan:** keep current assets as the High-preset LOD0. Generate Low-preset LOD1 chain via Godot's auto-LOD at import time. No rebuild needed if we use auto-LOD generation.

---

## 4. Improvements on Gemini's profile (dynamic, my additions)

These weren't in Gemini's profile but I think we should add them:

### 4.1 Adaptive zombie spawning
Not just a fixed cap. Spawn rate scales with current FPS:
- If FPS drops below 50 for 2 seconds: reduce max zombies by 5 (down to floor of 10)
- If FPS stays above 65 for 5 seconds: increase max zombies by 5 (up to preset ceiling)

This means even on Low preset, a beefy PC can push past 30 if it's handling the load.

### 4.2 Adaptive texture streaming
Godot's `texture_streaming_budget` setting. If VRAM is exhausted, engine automatically drops texture mips. Set this to 512MB on Low preset — engine manages the rest.

### 4.3 Adaptive LOD bias
Godot's `lod_bias` project setting. If FPS drops, increase `lod_bias` (objects swap to lower LOD sooner). If FPS is high, decrease `lod_bias` (objects stay at LOD0 longer).

Implementation: every 2 seconds, check FPS. Adjust `lod_bias` between 0.7 (high quality) and 1.5 (low quality) automatically.

### 4.4 Resolution auto-scale
If FPS drops below 45 for 3 seconds, drop internal resolution by 10% (1080p → 972p → 864p → 720p). If FPS recovers above 60, bump back up.

### 4.5 Particle quality tiers
Three tiers of particle effects (low/med/high). Low preset uses 50% fewer particles + no soft particles. High preset uses 100% + soft particles. Ultra uses 200% + soft + sub-emitters.

---

## 5. What this means for Tier 1 production

**No rebuilds needed.** Current 5 Tier 1 assets are valid as High-preset LOD0. For Low preset, we'll use Godot's auto-LOD generation at import time.

**Tier 1 #6-9 still needed:** sedan, pickup_truck, blood_splatter_decal, asphalt_road_segment. These should target the High-preset LOD0 budgets (the larger ones), since we'll auto-generate LOD1-3.

**Texture workflow paused** until we get a working image API. The Low preset can ship with flat-color materials (which is what we have now). Textures become a v1 polish step.

---

## 6. Summary: what's locked

| Item | Value | Status |
|---|---|---|
| Hardware target | Two-tier: Low (2GB VRAM) + High (6GB VRAM) | ✅ LOCKED |
| Alpha default preset | Low | ✅ LOCKED |
| Low preset renderer | Compatibility (OpenGL 3.3) | ✅ LOCKED |
| Low preset resolution | 1080p native (720p internal on Intel iGPU) | ✅ LOCKED |
| Low preset draw calls | 600 max | ✅ LOCKED |
| Low preset on-screen tris | 500k max | ✅ LOCKED (Gemini's number) |
| Low preset texture memory | 800 MB | ✅ LOCKED |
| Low preset view distance | 100m (Gemini said 150m, I locked lower) | ✅ LOCKED |
| Low preset fog start | 60m | ✅ LOCKED |
| Foliage billboard swap | 60m | ✅ LOCKED |
| Max zombies on Low | 30 (Gemini's number, was 15 in my v2) | ✅ LOCKED |
| Max zombies on High | 60 (dynamic to FPS) | ✅ LOCKED |
| Zombie AI tick rates | 60Hz close / 12Hz mid / LKP steering far | ✅ LOCKED |
| Sun shadows on Low | 1024² hard (Gemini said disable, I locked minimal shadows) | ✅ LOCKED |
| Time-of-day | Ambient color shift only on Low | ✅ LOCKED |
| Chunk streaming | 3×3 active + 5×5 warm (Gemini said 3×3 with instant unload — too aggressive) | ✅ LOCKED |
| Texture size Low | 256² max, atlased | ✅ LOCKED |
| Blob contact shadows | Yes, on Low | ✅ LOCKED |
| Adaptive systems | zombie count, texture streaming, LOD bias, resolution scale, particle quality | ✅ LOCKED (my additions) |
| Tier 1 production | Continue with #6-9, no rebuilds needed | ✅ LOCKED |
| Texture workflow | Paused until working API key | 🔓 PAUSED |
