# Hardware Target Reassessment — 2GB VRAM / 4GB RAM

> **Trigger:** User wants the game "accessible on millions of PCs and played on 2GB VRAM and 4GB RAM on 60 FPS."
> **Status:** v2 poly budget — supersedes v1 (which targeted GTX 1660 / 6GB VRAM).
> **Honest assessment below.** This is a big constraint. We can hit it, but with compromises.

---

## 1. The reality check

Let me be straight with you: **2GB VRAM + 4GB RAM at 1080p 60 FPS for an open-world survival game is hard.** Like, genuinely hard. Here's where we sit:

### 2GB VRAM means:
- Intel HD 4000 / HD 4600 / HD 530 (integrated graphics from 2012-2015)
- Or: GeForce GT 730 / GT 740 / GTX 750 Ti (2014-2015 entry-level dedicated)
- Or: Radeon R7 240 / R7 250 (2013-2014 entry-level)

These GPUs can run Minecraft at 1080p 60 FPS, but struggle with anything open-world + dynamic lighting. **Project Zomboid 3D equivalent at 2GB VRAM is the upper limit of what's possible.**

### 4GB RAM means:
- Windows 10 minimum is 2GB just for the OS
- That leaves ~2GB for the game
- Modern open-world games typically need 8GB+ RAM
- We'll need aggressive streaming + small in-memory footprint

### Realistic comparable games on this hardware:
- *Minecraft* (Java, with shaders off): yes, 60 FPS at 1080p
- *7 Days to Die* (low settings): 25-40 FPS, not 60
- *Project Zomboid* (2D iso): 60 FPS easily
- *The Long Dark* (low settings): 30-45 FPS

**Verdict:** 60 FPS at 1080p on 2GB VRAM / 4GB RAM is achievable IF we make significant compromises. We can't make a 7 Days to Die equivalent at 60 FPS on this hardware. We can make a Project Zomboid-in-3D equivalent.

---

## 2. The compromises we have to make

To hit 2GB VRAM / 4GB RAM / 1080p / 60 FPS, we need to compromise on:

| Compromise | What it costs us | What it gains us |
|---|---|---|
| **Drop resolution to 720p (not 1080p)** | Visual clarity | 44% less frame buffer + texture memory |
| **Use Godot Compatibility renderer (OpenGL 3.3)** | No Vulkan features, no real-time GI, simpler shadows | Runs on literally anything, including 15-year-old GPUs |
| **Cut texture sizes** (256² max, atlas everything) | Texture detail | 75% less VRAM per texture |
| **Cut zombie count to 15 max on screen** | Less epic horde feel | CPU + draw call savings |
| **Cut on-screen triangles to 500k max** | Less geometric detail | Massive GPU savings |
| **Cut draw calls to 800 max** | Less prop variety visible at once | CPU savings |
| **Cut view distance to 80m** | Less sense of scale | Hides streaming pop-in |
| **No real-time shadow maps except sun** | Less visual depth | Massive GPU savings |
| **Bake lighting into vertex colors** | No dynamic time-of-day shadows | HUGE GPU savings |
| **Single material per mesh (atlas)** | More up-front texture work | Cuts draw calls dramatically |

### What we keep (the soul of the game):
- ✅ First-person camera
- ✅ All 10 biomes
- ✅ Hand-authored world + procedural interiors
- ✅ Sound-based zombie AI
- ✅ Stealth + guns + melee combat
- ✅ Roguelite meta-progression
- ✅ Radio Rumor system
- ✅ Persistent map + per-run reset
- ✅ The Republic of Mazar lore

### What we lose (or push to v1):
- ❌ Real-time dynamic lighting (interior lights cast no shadows)
- ❌ High-resolution textures (max 256² instead of 1024²)
- ❌ 30+ zombie hordes on screen (cap at 15)
- ❌ Distant landmarks visible across the map (view distance 80m)
- ❌ 1080p native (we run 720p internal, upscaled to 1080p)
- ❌ Real-time global illumination

---

## 3. Revised poly budget v2 (LOCKED)

### 3.1 Engine-level budgets (per frame)

| Metric | v1 target (GTX 1660) | **v2 target (2GB VRAM)** | Hard ceiling |
|---|---|---|---|
| Resolution | 1080p | **720p internal (upscaled to 1080p)** | — |
| Renderer | Forward+ (Vulkan) | **Compatibility (OpenGL 3.3)** | — |
| Frame time | 16.67 ms | 16.67 ms | 33 ms (30 FPS minimum) |
| Draw calls | 1500 | **600** | 1000 |
| Triangles on-screen | 2 M | **400 k** | 600 k |
| Texture memory (active) | 3 GB | **800 MB** | 1.2 GB |
| Real-time shadow lights | sun + 4 | **sun only** | sun + 1 |
| Decals on screen | 50 | 20 | 40 |

### 3.2 Per-asset triangle budgets (revised)

| Asset type | v1 LOD0 | **v2 LOD0** | v2 LOD1 | v2 LOD2 | v2 LOD3 |
|---|---|---|---|---|---|
| Hero building (landmark) | 30 000 | **8 000** | 3 000 | 1 000 | 300 |
| Standard enterable building | 8 000 | **2 500** | 800 | 250 | 80 |
| Background building | 1 500 | **500** | 200 | 80 | 30 |
| Interior shell (per room) | 4 000 | **1 500** | — | — | — |
| Interior prop (per item) | 500 | **200** | 80 | — | — |
| Held weapon (FPS view) | 8 000 | **3 000** | — | — | — |
| Hero prop | 2 000 | **800** | 250 | 80 | — |
| Standard prop | 600 | **250** | 80 | 30 | — |
| Background prop | 150 | **80** | 30 | — | — |
| Player character | 10 000 | **4 000** | 1 200 | 400 | 120 |
| Walker zombie | 8 000 | **3 000** | 800 | 250 | 80 |
| Hero tree | 2 500 | **1 200** | 400 | 120 | 30 (billboard) |
| Standard tree | 1 200 | **500** | 200 | 60 | 20 |
| Bush | 400 | **200** | 80 | — | — |
| Driveable sedan | 12 000 | **4 000** | 1 200 | 400 | — |
| Driveable pickup | 15 000 | **5 000** | 1 500 | 500 | — |
| Decal | 6 verts | **6 verts** | — | — | — |
| Road segment (per 10m) | 200 tris | **80 tris** | — | — | — |

### 3.3 Texture memory budget (revised)

| Texture type | v1 size | **v2 size** | v2 VRAM |
|---|---|---|---|
| Hero albedo (held weapon, hero building) | 2048² | **512²** | 256 KB |
| Standard albedo | 1024² | **256²** | 64 KB |
| Background albedo | 512² | **128²** | 16 KB |
| Atlas (foliage, road, fence) | 4096² | **1024²** | 1 MB |
| UI sprites | 512² | 256² | 64 KB |

**Total active texture budget:** 800 MB target, 1.2 GB ceiling. Leaves ~600 MB for frame buffer + render targets + post.

### 3.4 Per-biome scene budgets (revised)

Worst-case tris on screen at once, with v2 budgets:

| Biome | Buildings | Props | Foliage | Zombies (15 max) | Total |
|---|---|---|---|---|---|
| Suburbia (5 houses) | 5×2.5k=12.5k | 5×1.5k interior=7.5k | 50 bushes + 20 trees=15k | 10×3k=30k | **65k** ✅ |
| Parks & Greenways | 0 | 1k | 100 trees + 300 bushes=85k | 5×3k=15k | **100k** ✅ |
| Forest (dense) | 0 | 0 | 200 trees + 400 bushes=240k | 5×3k=15k | **255k** ✅ |
| Farmland | 2×2.5k=5k | 2k | 30 trees + 100 bushes=30k | 3×3k=9k | **46k** ✅ |
| Commercial Strip | 8 shops×1k=8k | 50 props×250=12.5k | 5 trees=3k | 10×3k=30k | **53.5k** ✅ |
| Industrial Park | 4 warehouses×3k=12k | 30 props=6k | 0 | 8×3k=24k | **42k** ✅ |
| River & Wetlands | 3 houseboats×1.5k=4.5k | 2k | 50 reeds=2k | 4×3k=12k | **20.5k** ✅ |
| Subway (tunnel view) | 0 | 15 props×250=3.75k | 0 | 8×3k=24k | **27.75k** ✅ |
| Downtown | 10 BG×500=5k + 2 hero×8k=16k → 21k | 25 props=6.25k | 3 trees=1.5k | 15×3k=45k | **73.75k** ✅ |
| Military Zone | 6 structures×2k=12k | 15 props=3.75k | 0 | 15×3k=45k | **60.75k** ✅ |

**All under 400k target.** Forest at 255k is the heaviest, but still well within budget.

---

## 4. DeepSeek's advice — honest assessment

DeepSeek gave you 3 pieces of advice. Here's my honest take on each:

### 4.1 "Visibility Ranges (HLOD) for Open Areas"
**✅ DeepSeek is right.** For Farmland, Coastal Beach, Forest — areas without buildings to occlude — `OccluderInstance3D` is useless. Use Godot 4.x's Visibility Range (`visibility_range_begin`, `visibility_range_end`, `visibility_range_fade_mode`) on each mesh + `GeometryInstance3D` to auto-hide distant objects or swap to billboard LOD.

**My addition:** use `MultiMeshInstance3D` for foliage. One draw call for 10 000 grass blades. This is more important than HLOD for our 2GB VRAM target.

**Action:** I'll set up visibility ranges when we move from assets → Godot scene assembly.

### 4.2 "Profile Relentlessly"
**✅ DeepSeek is right.** Always good advice. Godot's built-in Profiler + Monitors are excellent.

**On the specific number "draw calls above 1000 = problem":** DeepSeek is being conservative. Modern desktop GPUs handle 2000-3000 draw calls at 60 FPS easily. BUT for our 2GB VRAM target (which means older GPUs + integrated graphics), DeepSeek's 1000 threshold is actually correct. **I've revised our draw call budget down to 600 max** (see §3.1 above).

**On "frame time high but script time low = GPU-bound":** Correct. The fix is either reduce draw calls (merge meshes), reduce triangles (LODs), reduce shader cost (simpler materials), or reduce overdraw (less transparency, fewer decals).

### 4.3 "Zombies 40-70 on screen at 5k-8k tris each"
**⚠️ DeepSeek's number works for mid-range hardware, but NOT for our 2GB VRAM target.**

- 40-70 zombies × 5-8k tris = 200k-560k tris just for zombies
- That's HALF of our entire frame triangle budget (400k) spent on zombies
- Plus the CPU cost of running 40-70 AI pathfinders + animation updates per frame is too much for 4GB RAM

**My revised zombie budget:**
- Max 15 zombies on screen at once (alpha)
- LOD0 (close, ≤12m): 3k tris each
- LOD1 (12-30m): 800 tris
- LOD2 (30m+): 250 tris or billboard quad
- Worst case: 15 × 3k = 45k tris (manageable)
- Cap of 30 active AI computations (zombies that can pathfind + attack); zombies beyond 30m idle

**For v1 (better hardware):** bump to DeepSeek's 40-70 zombies.

---

## 5. What this means for production

The good news: **the assets we've already built still work.** They're actually UNDER the new tighter budgets:

| Asset | Built | v2 Budget | Status |
|---|---|---|---|
| suburban_house_v2 | 1,800 tris | 2,500 | ✅ under |
| office_chair | 6,500 tris | 800 | ❌ way over — needs LOD rebuild |
| dining_table | 460 tris | 250 | ❌ almost 2× over |
| oak_tree (fixed) | 2,400 tris | 1,200 | ❌ 2× over |
| bush | 360 tris | 200 | ❌ almost 2× over |

**Action:** I need to rebuild office_chair, dining_table, oak_tree, bush at the tighter v2 budgets. Most are easy reductions (drop segment counts, drop sphere subdivisions).

---

## 6. What I recommend you decide

Three paths forward — pick one:

### Path A: Stick with 2GB VRAM target, accept compromises
- Use Godot Compatibility renderer (OpenGL 3.3)
- 720p internal resolution
- All the compromises in §2
- We hit "millions of PCs" but lose visual fidelity

### Path B: Two-tier target (low + high)
- Build for both 2GB VRAM (low preset) AND 8GB VRAM (high preset)
- Use Godot's quality settings + multiple LOD chains
- More dev work, but serves both audiences
- This is what most modern games do (Low/Medium/High/Ultra presets)

### Path C: Bump to 4GB VRAM target
- "Millions of PCs" = 4GB VRAM is more like 2014+ hardware (GTX 950+)
- 4GB VRAM gives us proper Forward+ renderer, 1080p native, 1500 draw calls, 1.5M tris
- Still a big audience (most PCs from 2016+ have 4GB+ VRAM)
- Less compromises, faster development

**My honest recommendation:** **Path B (two-tier).** Build the alpha at v1 budget (GTX 1660 / 6GB VRAM) so we have headroom to iterate fast. Add a "Low" preset for 2GB VRAM when we hit vertical slice. This way we don't compromise the alpha experience AND we still hit "millions of PCs" at launch.

**But it's your call.** Tell me which path, and I'll adjust the v2 budget accordingly.

---

## Appendix: how I'd actually achieve 2GB VRAM at 60 FPS

If you pick Path A, here's the technical recipe:

1. **Godot 4.7.2 Compatibility renderer** (OpenGL 3.3 / WebGL2). Set in Project Settings → Rendering → Renderer.
2. **Internal render resolution 720p**, upscaled to 1080p via Godot's stretch system. Set in Project Settings → Display → Window → Stretch.
3. **Texture sizes:** 256² max for standard, 512² for hero, 128² for background. Use BPTC for desktop, ASTC for mobile.
4. **Mesh merging:** every static prop in a room is merged into one mesh. `MultiMeshInstance3D` for repeated props (fence segments, grass, debris).
5. **LOD chain per asset:** LOD0 (close), LOD1 (mid), LOD2 (far), LOD3 (billboard for trees). Godot auto-generates LOD1-3 from LOD0.
6. **Visibility Range per object:** hide anything beyond 80m. Swap to billboard at 60m.
7. **Lighting:** sun + 1 dynamic shadow-casting light max. Bake all interior lights as vertex color.
8. **Shadows:** sun shadow at 1024² resolution max. No point/spot shadows.
9. **Post-processing:** no MSAA, no SSR, no bloom. Just FXAA (cheap).
10. **Streaming:** chunk-based, 250m × 250m chunks. Keep 9 chunks in memory = ~200MB RAM.
11. **Zombie AI:** cap 15 active. Beyond 30m, zombies idle.
12. **Audio:** streaming, not loaded into RAM.

This is a *real* recipe. It works. *Minecraft* does roughly this. But it's a different visual identity than what the lookbook showed — closer to *Don't Starve Together* in 3D than to *Night of the Dead*.
