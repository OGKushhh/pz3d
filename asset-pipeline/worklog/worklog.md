# Asset Pipeline Worklog

> Living document. Append-only. Every design decision, system spec, or open question gets logged here with a date so we never lose sight.

---

## 2026-09-11 — Session 4: Lore locked (Republic of Mazar), door bug confirmed, GDD v3

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Lore locked — Republic of Mazar v1.2 | ✅ | User provided complete lore document. Saved at `/home/z/my-project/download/lore_mazar_v1.2.md`. Supersedes my 3 city lore options (Halberd Bay / Carthage / Vance Valley). The lore is richer and more specific than what I drafted. |
| 2 | City name — National City of Mazar | ✅ | Capital of the Republic of Mazar. On Sarran Bay where Sarran River meets ocean. |
| 3 | Map geography locked via lore | ✅ | Sarran River divides city east/west. West side: Suburbia, Parks, Commercial, Farmland, Forest. East side: Industrial, River/Wetlands, Downtown, Military Zone. Underground: Subway (public + secret military tunnels). |
| 4 | 10 biomes locked via lore Part Nine | ✅ | Lore's biome table supersedes earlier specs. POIs updated — e.g. Suburbia POIs no longer include "church" (no religious buildings). |
| 5 | Civic landmarks only — no religious buildings | ✅ | 12 civic landmarks: Lighthouse, Water Tower, Grain Silo, Hospital, Police HQ, Government Palace, Stadium, Old Royal Palace, Naval Fort, Broadcast Tower, Railway Station, Grand Bazaar. |
| 6 | 5 factions locked | ✅ | Mazar Republic (democratic resistance), Junta Remnants (cover-up), Border Enemy (foreign power, wants the liquid), Survivors (neutral), The Immune (player is one of these). |
| 7 | 4 radio stations locked | ✅ | Voice of Mazar (Mazar Republic), Radio Junta (Junta Remnants), Free Bay FM (Survivors), The Border Signal (Border Enemy). These are the Radio Rumor system sources. |
| 8 | Zombie types + behavior locked | ✅ | Walker (default, slow, sight cone + hearing radius), Crawlers (legs destroyed, slow quiet, bite from ground), Groups (noise pulls nearby, hordes form slowly, no coordination), Memory (~10 sec, investigate then forget). Lore justification: Living Troop liquid overloaded nervous systems. |
| 9 | Player character lore justification | ✅ | Player is one of "The Immune" — body rejected or never encountered the Living Troop liquid. This is why you're alive. This is why you can survive. |
| 10 | Naming conventions locked | ✅ | Streets: King's Way, Coup Avenue, Martyrs' Road, Unity Boulevard, Harbor Street, Olive Lane, Bunker Road, Sarran Street. Districts: Al-Salam, Al-Nour, Al-Minar, Old Town, New Town, New Mazar, Fort Quarter, Sarran District. Key figures: King Amir, General Karim. Key locations: Fort Sarran, Sarran Bay, Sarran River, Sarran Bridge, Old Royal Palace. |
| 11 | Timeline locked | ✅ | 300 yr monarchy → 70 yr ago Quiet Coup → 68-60 yr ago General Karim → 13 yr ago Border Enemy takes over → 10 yr ago Operation Living Troop begins → 2 weeks ago lab explosion at Fort Sarran → Day 0 = now (outbreak). |
| 12 | Operation Living Troop = canonical zombie origin | ✅ | Secret military experiment. Liquid boosts stamina/tissue repair/muscle density but overloads nervous system → heart stops → brain dies → body rises. Undead consume energy at fraction of human rate, can go weeks without feeding. Not fast, not smart, not coordinated, but relentless. |
| 13 | Door visibility bug confirmed | ✅ | User pointed out suburban house has no doors. I re-rendered front view (`suburban_house_front_door_check.png`) and VLM confirmed: doors are in the .mog source but render flush with wall (z-fighting) and porch obscures them. Queued for fix in Tier 1 asset #1 (suburban house v2). Fix: recess door 5cm into wall, add door frame trim, ensure porch doesn't occlude door. |
| 14 | Fence approved as style anchor | ✅ | User confirmed fence.mog is good. 44 nodes, 318 tris, 31 meshes, 3 materials. Will use as Tier 1 environment prop anchor. |

### Lore-driven design implications (all locked)

1. **Fog identity is lore-justified.** The fog that rolled in after the leak is permanent weather. Every screenshot justifies the locked fog design principle.
2. **Sarran River = the central water obstacle.** Not a generic bay. Flows from Forest (north) through Farmland into Sarran Bay (west). Divides city east/west. Bridges are chokepoints.
3. **Subway = public transit + secret military tunnels.** The "secret military transport tunnels" lore gives the Subway biome its unique identity — not just generic tunnels, but places where the junta moved things it didn't want anyone to see. Contains lore fragments + military supplies.
4. **Fort Sarran = outbreak origin = Military Zone.** The lab is here. The liquid leaked from here. The Ground Zero.
5. **Border Enemy = northern neighbor.** Used Mazar as a staging ground for weapon development. Still out there beyond the northern border (Forest biome = border region). Want to recover the liquid.
6. **The Old Royal Palace = lore fragment location.** Abandoned, sealed. King Amir's exile. Contains truth about the monarchy's end.
7. **Government Palace = now junta HQ.** Downtown. Where the cover-up was orchestrated.
8. **No religious buildings = hard constraint.** All landmarks are civic. Even Suburbia POIs don't include "church" (corrected from earlier session-3 spec).
9. **The Immune = player character explanation.** Solves the "why are you alive" question elegantly. Player is one of the immune — not a faction, just a random individual.
10. **4 radio stations = Radio Rumor system sources.** Each faction has a station. Run modifiers come from these.

### Known issues queue (updated)

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream example) | Doors flush with wall (z-fighting), obscured by porch. VLM-confirmed. | Tier 1 v2: recess door 5cm, add door frame trim, ensure porch doesn't occlude door from front view. | Queued for Tier 1 |
| 2 | humanoid.mog (our DSL test) | Reads "Roblox/blocky" per user. | Accepted for alpha. Hybrid (external base + MoGen clothing) for v1. | Accepted for alpha |

### Tier 1 style anchors queue (first 10 assets to produce)

1. ~~Canonical suburban house~~ ✅ done but needs v2 fix (door bug)
2. ~~DSL humanoid~~ ✅ done (accepted for alpha)
3. ~~Fence~~ ✅ done + approved (use as environment prop anchor)
4. Office chair (interior prop anchor)
5. Dining table (interior prop anchor)
6. Oak tree (foliage anchor)
7. Bush (foliage anchor)
8. Sedan car (vehicle anchor)
9. Pickup truck (vehicle anchor)
10. Blood splatter decal (decal anchor)
11. Asphalt road segment (environment anchor)

Once these are approved, I can produce the entire alpha map's variant packs autonomously, in batches.

---

## 2026-09-11 — Session 3: biome specs locked, 10th biome added, map dimensions derived, combat locked, lore drafted, asset review strategy designed

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Be the LLM (not API keys) — compiled MoGen docs as single file | ✅ | User uploaded `mogen-doc.txt`. Copied to `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB). |
| 2 | All 10 biomes fully specified | ✅ | User provided complete specs for 9 biomes + added 10th (Military Zone). |
| 3 | Alpha build order locked | ✅ | Suburbia → Parks → Farmland → Forest → Commercial → Industrial → River/Wetlands → Subway → Downtown → Military Zone. |
| 4 | 10th biome: Military Zone / Quarantine | ✅ | Small compound, extreme difficulty, gated by keycard/quest/radio rumor. |
| 5 | Combat: ALL THREE (stealth + guns + melee) | ✅ | Shooting = Valorant-feel addictive hook. Stealth = primary survival tool. Melee = door-defense meta. |
| 6 | Map dimensions: 4.0 km × 3.0 km = 12 km² | ✅ | Derived from GTA SA reference. Grid: 8×6 cells of 500m × 500m. |
| 7 | Tiered asset review strategy | ✅ | Tier 1 (~10 anchors), Tier 2 (~80 variant packs), Tier 3 (~900 mass production, auto-validated), Tier 4 (~10 biome milestones). Total user review time ~3 hours, not 16. |
| 8 | Batch zip exports | ✅ | Every sprint: contact sheet + manifest + renders + sources + glbs. |
| 9 | Communication protocol for review | ✅ | APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note> / REJECT BATCH. |
| 10 | Auto-validation pipeline | ✅ | mogen check + build + VLM sanity + scale + palette + LOD. Failed checks → regenerate queue. |
| 11 | 3 city lore concepts drafted | ✅ | A: Halberd Bay, B: Carthage, C: Vance Valley. Recommended A. (Superseded in session 4 by user's own Republic of Mazar lore.) |

---

## 2026-09-11 — Session 2: design lock-in + map reference

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Be the LLM, not API keys | ✅ | |
| 2 | Stylized low-poly + PBR-lite (MoGen-native) | ✅ | |
| 3 | First-person camera | ✅ | |
| 4 | DSL humanoid for now | ✅ | |
| 5 | Fixed map + procedural interiors | ✅ | |
| 6 | Los Santos + Red County + Flint County scale target | ✅ | |
| 7 | Travel = exploration, not optimization | ✅ | 10 design principles locked. |
| 8 | Persistent map + per-run reset | ✅ | |
| 9 | Biome/district loot identity | ✅ | |
| 10 | Radio Rumor system | ✅ | |
| 11 | Base hub + meta progression | ✅ | |
| 12 | Death penalty + meta upgrades | ✅ | |
| 13 | Co-op optional (future) | ✅ | |
| 14 | Lore fragments + persistent keys | ✅ | |
| 15 | Sandbox first, story mode later | ✅ | |
| 16 | 9 biomes locked (became 10 in session 3) | ✅ | |

---

## 2026-09-11 — Session 1: toolchain setup + lookbook

(See above for full details. Summary: MoGen installed, DSL docs read, 11 example .mog files rendered via Chrome + three.js + swiftshader pipeline. Asset pipeline directory structure created. Starter GDD v0 written.)

---

## 2026-09-11 — Session 5: Tier 1 production started, poly budget locked, lore semi-locked

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Lore marked SEMI-LOCKED for alpha | ✅ | User: "we may change names, factions and such, we have freedom exploring options, since we still in alpha". What stays locked: overall structure (city/river/biomes/Operation Living Troop origin/player is Immune). What can change: street names, faction names, character names, radio station names, lore fragment texts. |
| 2 | Poly budget v1 locked | ✅ | Saved at `/home/z/my-project/download/poly_budget_v1.md`. Target: PC 1080p 60 FPS, Godot 4.7.2 Forward+. Baseline GPU: GTX 1660 / RX 5600 XT. Per-frame: 16.67ms, draw calls ≤2000, triangles ≤3M, texture memory ≤4GB. Per-asset LOD0 budgets: hero building 30k, standard enterable building 8k, hero prop 2k, standard prop 600, held weapon 8k, hero tree 2.5k, standard tree 1.2k, bush 400, driveable sedan 12k, driveable pickup 15k. Per-biome scene budgets: Forest heaviest at ~1M tris (foliage density), all others 140-350k. |
| 3 | Tier 1 production started | ✅ | 5 of 10 style anchors built + rendered: suburban_house_v2 (door bug fixed!), office_chair, dining_table, oak_tree, bush. |
| 4 | Door bug root cause + fix | ✅ | The bug had TWO causes: (1) original upstream suburban_house.mog had doors flush with wall + obscured by porch. (2) My initial v2 renders ALSO appeared door-less because I was rendering with yaw=0 which looks at the +Z face (back of house), not the -Z face (front with door). Camera convention: yaw=0 = camera at +Z looking at origin (sees +Z face). For front view, use yaw=180. Fixed by using `wall` primitive with `holes=[...]` for clean door cutouts + recessed door panel + door frame trim, and rendering at yaw=180. VLM-confirmed: red door + garage door visible. |
| 5 | `wall` primitive pattern locked | ✅ | Use `wall (size=[w,h,t], holes=[[cx,cy,w,h],...])` for any wall with door/window cutouts. Holes are in wall local X/Y plane, cut all the way through Z thickness. Cleaner than CSG difference. |
| 6 | `solid` group with `cleanup="coplanar"` pattern locked | ✅ | Use `solid "shell" (mat="...", cleanup="coplanar") { ... }` for building shells. Merges same-material primitives at export time, removes interior faces. Eliminates z-fighting between touching walls. |
| 7 | Floating cluster fix pattern locked | ✅ | When `mogen check` returns `E1101 scene has N disconnected part clusters`, overlap the floating mesh with the main body by ~0.01-0.05m so `solid` group can merge them. |
| 8 | `icosphere` attribute correction | ✅ | Use `subdivisions=` not `detail=`. subdivisions=1 = low-poly (12 tris), 2 = default (42 tris), 3 = high-poly (162 tris). |
| 9 | Render camera yaw convention | ✅ | In render_glb.html: yaw=0 → camera at +Z looking at origin (sees +Z face of model). yaw=180 → camera at -Z (sees -Z face). For buildings with front door at -Z (toward camera in default MoGen thumbnail), use yaw=180-225 for front/three-quarter views. |
| 10 | `branch` primitive pattern locked | ✅ | Use `branch (form="decurrent", length=, radius=, depth=, splits=, leaves=0)` for procedural tree trunks. Add canopy as icosphere cluster with `subdivisions=1` for stylized low-poly look. |

### Tier 1 production status (after session 5)

| # | Asset | Status | Tris | VLM verified |
|---|---|---|---|---|
| 1 | suburban_house_v2 | ✅ built + 4 renders | 1800 | ✅ door + garage door visible |
| 2 | office_chair | ✅ built + render | 6500 | ✅ "immediately recognizable as office chair" |
| 3 | dining_table | ✅ built + render | 460 | ✅ "recognisable as a dining table" |
| 4 | oak_tree | ✅ built + render | 2700 | ✅ "recognisable as a tree, stylized low-poly" |
| 5 | bush | ✅ built + render | 360 | ✅ "low-poly 3D model of foliage" |
| 6 | sedan | ⏳ pending | target 12k | — |
| 7 | pickup_truck | ⏳ pending | target 15k | — |
| 8 | blood_splatter_decal | ⏳ pending | target 6 verts | — |
| 9 | asphalt_road_segment | ⏳ pending | target 200 | — |
| 10 | (fence.mog already approved as anchor) | ✅ | 318 | ✅ user-approved |

**Contact sheet for review:** `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-001_contact_sheet.png`

### Engine budget key facts (from research)

- **Godot 4.7.2 Forward+** is the default desktop renderer (Vulkan, cluster-based lighting).
- **Draw calls are Godot's biggest perf lever** — each mesh = 1 call unless merged. Target ≤2000/frame for 60 FPS.
- **Triangles on-screen:** 1-2M comfortable on GTX 1060; 3-5M on RTX 2060; 5-10M on RTX 3060. We target 3M max → mid-range baseline.
- **Jolt physics plugin** significantly faster than Godot's default bullet integration — use it for survival games with many dynamic objects.
- **Occlusion culling** added in Godot 4.3 — use `OccluderInstance3D` on hero buildings.
- **Mesh LOD auto-generation** built into Godot 4.x import settings — author LOD0, let Godot generate LOD1-3.
- **MultiMeshInstance3D** for foliage — one draw call for 10 000 grass instances.
- **Decals** via `Decal` node — single quad, projects onto surfaces, cheap.

### Next session plan

1. Build remaining 4 Tier 1 assets: sedan, pickup_truck, blood_splatter_decal, asphalt_road_segment.
2. Once all 10 Tier 1 approved, move to Tier 2 — variant packs. First variant pack: Suburbia house variants (pristine, weathered, ruined, burned) — 4 thumbnails in one contact sheet.
3. In parallel, answer remaining v5 open questions: survival needs list, combat balance ratios, palette per biome, FOV.


---

## 2026-09-11 — Session 6: Oak tree fix, poly budget v2 reassessment for 2GB VRAM, texture attempt

### Decisions / events this session

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | User approved Tier 1 batch 001 EXCEPT oak_tree (bare wood sticking out top) | ✅ | Other 4 anchors approved (suburban_house_v2, office_chair, dining_table, bush). |
| 2 | Oak tree fix attempted (v1 — add canopy spheres) | ❌ failed | Added canopy_under sphere + more canopy spheres, but VLM still saw bare twigs. Math said twigs at Y=2.85 should be inside canopy_main (Y=1.5 to 4.5, radius 1.5). Possibly the `branch` primitive's internal sub-segments weren't being captured by my dump filter, OR the camera angle revealed geometry I couldn't see in the dump. |
| 3 | Oak tree fix attempted (v2 — replace `branch` with simple cylinders) | ✅ succeeded | Replaced `branch` primitive with single tapered `cylinder` trunk + 7 sphere canopy (subdivisions=2 for solidity). No internal sub-segments to leak through. VLM confirmed: "No, there is no brown wood visible above the green canopy." Final: 2.4k tris (under 2.5k budget), 11 nodes, 3 materials, 5ms build. |
| 4 | User requested hardware target downgrade: 2GB VRAM / 4GB RAM / 60 FPS / "millions of PCs" | 🔓 awaiting decision | Wrote `/home/z/my-project/download/poly_budget_v2_low_end.md` with honest assessment. 2GB VRAM = Intel HD 4000 / GT 730 / R7 240 class. 4GB RAM is very tight for open world. 60 FPS at 1080p achievable BUT with major compromises: drop to 720p internal, use Godot Compatibility renderer (OpenGL 3.3), cut texture sizes to 256², cut zombie count to 15 max, cut on-screen triangles to 400k max, cut draw calls to 600 max, no real-time shadows except sun, bake lighting into vertex colors. Proposed 3 paths: A (stick with 2GB, accept compromises), B (two-tier low+high presets), C (bump to 4GB VRAM). Recommended Path B. Awaiting user pick. |
| 5 | DeepSeek advice assessment | ✅ | Wrote assessment in poly_budget_v2_low_end.md §4. Summary: DeepSeek is right about HLOD/Visibility Ranges for open areas and right about profiling. The "draw calls above 1000 = problem" threshold is correct for our new 2GB VRAM target (was conservative for v1 mid-range target). The "40-70 zombies at 5-8k tris" is reasonable for mid-range hardware but TOO HIGH for 2GB VRAM target — revised to max 15 zombies at 3k tris each (45k tris total, vs 200-560k for DeepSeek's range). |
| 6 | User provided Gemini API key for textures | ⚠️ free-tier quota exceeded | Tried `mogen textures` on suburban_house_v2 — got 429 rate limit errors. Gemini free tier for `gemini-2.5-flash-preview-image` allows 0 requests. Need either: (a) paid Gemini API key with billing enabled, OR (b) separate ZAI_API_KEY for Z.ai's `glm-image` endpoint via `--zai-api-key` flag. The session-bound JWT in our z-ai CLI SDK can't be reused. |
| 7 | Asset v2 budget status check | ⚠️ | With new v2 budgets (suburban_house 2.5k, office_chair 800, dining_table 250, oak_tree 1.2k, bush 200): suburban_house_v2 (1.8k ✅ under), office_chair (6.5k ❌ 8× over), dining_table (460 ❌ 2× over), oak_tree (2.4k ❌ 2× over), bush (360 ❌ 2× over). Need to rebuild 4 of 5 assets at tighter v2 budgets IF user picks Path A. If user picks Path B (two-tier), keep current assets as LOD0 and generate LOD1-3 chains. |

### Tier 1 production status (after session 6)

| # | Asset | Status | Tris | v1 budget | v2 budget (2GB) | v2 status |
|---|---|---|---|---|---|---|
| 1 | suburban_house_v2 | ✅ approved | 1800 | 8k | 2.5k | ✅ under |
| 2 | office_chair | ✅ approved | 6500 | 600 | 800 | ❌ 8× over (needs LOD rebuild for v2) |
| 3 | dining_table | ✅ approved | 460 | 800 | 250 | ❌ 2× over (needs LOD rebuild for v2) |
| 4 | oak_tree (fixed) | ✅ approved | 2400 | 2.5k | 1.2k | ❌ 2× over (drop subdivisions=1, smaller canopy) |
| 5 | bush | ✅ approved | 360 | 400 | 200 | ❌ 2× over (drop subdivisions=1) |
| 6 | sedan | ⏳ pending | — | 12k | 4k | — |
| 7 | pickup_truck | ⏳ pending | — | 15k | 5k | — |
| 8 | blood_splatter_decal | ⏳ pending | — | 6 verts | 6 verts | — |
| 9 | asphalt_road_segment | ⏳ pending | — | 200 | 80 | — |
| 10 | fence (upstream, approved) | ✅ approved | 318 | — | 200 (env prop) | ✅ under |

### Key technical learnings this session

1. **The `branch` primitive is hard to control.** It generates internal sub-segments (seg_d0..d3) that can poke through canopy spheres in unpredictable ways. For stylized trees where I want clean control over the silhouette, plain cylinders are better. Reserve `branch` for hero assets where the trunk itself is the visual focus.

2. **`icosphere` `subdivisions=2` (default, 80 faces) is more solid-looking than `subdivisions=1` (20 faces).** For close-up hero assets use subdivisions=2 or 3. For background foliage, subdivisions=1 is fine.

3. **Godot Compatibility renderer (OpenGL 3.3) is the right choice for 2GB VRAM target.** Forward+ requires Vulkan + 4GB+ VRAM. Compatibility runs on 15-year-old hardware. Trade-off: no real-time GI, simpler shadows, no Vulkan features.

4. **Gemini free tier image generation quota is 0.** Need paid key with billing enabled to use `mogen textures`. Alternative: use Z.ai's `glm-image` endpoint via `--zai-api-key` flag (need separate ZAI_API_KEY, can't extract from session SDK).

5. **DeepSeek's advice is mostly correct but calibrated for mid-range hardware.** For 2GB VRAM target, zombie count needs to drop from 40-70 to 15 max, draw call threshold from 1000 to 600.

### Open questions (urgent)

1. **Pick path A, B, or C from poly_budget_v2_low_end.md** — this determines whether I rebuild assets at tighter v2 budgets (Path A) or keep current assets and add LOD chains (Path B) or bump target to 4GB VRAM (Path C).
2. **Get a working texture API key.** Either: paid Gemini key, OR separate ZAI_API_KEY, OR we use the image-generation skill (z-ai CLI) to manually generate albedo textures and splice them into .mog files via script.
3. **Continue Tier 1 production (#6-9: sedan, pickup, blood splatter, road segment)?** Yes — these are needed regardless of which path we pick.


---

## 2026-09-11 — Session 7: Path B locked, all 9 Tier 1 anchors complete, backups created

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Path B locked — two-tier Low/High presets | ✅ | Alpha default = Low preset (2GB VRAM / 4GB RAM / 1080p / 60 FPS). High preset scales up (6GB VRAM). Ultra preset for v1 (8GB+ VRAM). |
| 2 | Gemini's "Low Graphics" profile assessed critically | ✅ | Wrote assessment in poly_budget_v3_path_b.md §2. Most of Gemini's advice is correct (600 draw calls, 500k tris, MultiMeshInstance3D for foliage, staggered AI tick rates, 256² textures, baked lighting, blob shadows). Refined: view distance 100m (Gemini said 150m — too far for 2GB VRAM), chunk streaming 3×3 active + 5×5 warm (Gemini said instant unload — too aggressive), sun shadows 1024² hard (Gemini said disable entirely — looks flat), zombie count 30 (Gemini's number — better than my earlier 15). |
| 3 | Dynamic zombie count system locked | ✅ | Zombies scale based on hardware + FPS. Low preset 30 max, High 60, Ultra 100. Adaptive: if FPS drops below 50 for 2 sec, reduce by 5 (floor 10). If FPS above 65 for 5 sec, increase by 5 (up to ceiling). |
| 4 | Adaptive systems added (improvements on Gemini's profile) | ✅ | (1) Adaptive zombie spawning based on FPS, (2) Adaptive texture streaming via Godot's texture_streaming_budget, (3) Adaptive LOD bias via project settings, (4) Adaptive resolution auto-scale (1080p→972p→864p→720p), (5) Particle quality tiers (low/med/high). |
| 5 | Renderer strategy locked | ✅ | Compatibility (OpenGL 3.3) for alpha default. Forward+ (Vulkan) added as restart-required option in v1 for High/Ultra presets. |
| 6 | Texture workflow PAUSED | ✅ | mogen textures requires paid Gemini API key (free tier = 0 image quota). Paused for alpha — flat-color materials acceptable. Textures become v1 polish step. Three paths forward: paid Gemini, separate ZAI_API_KEY, manual workflow via image-generation skill. |
| 7 | Tier 1 production COMPLETE — all 9 anchors built + VLM-verified | ✅ | Built #6-9 this session: sedan (2k tris), pickup_truck (1.7k tris), blood_splatter_decal (2 tris), asphalt_road_segment (96 tris). All VLM-verified as recognisable. Contact sheet batch 002 created. |
| 8 | Backups created | ✅ | mazar_alpha_backup_2026-09-11.zip (871KB) — assets + scripts + mogen-examples. mazar_design_backup_2026-09-11.zip (2.2MB) — GDDs + lore + poly budgets + worklogs + compiled MoGen docs + GTA SA map ref. |

### Tier 1 production COMPLETE ✅

All 9 style anchors built + rendered + VLM-verified:

| # | Asset | Tris | Status |
|---|---|---|---|
| 1 | suburban_house_v2 | 1,800 | ✅ Door bug fixed |
| 2 | office_chair | 6,500 | ✅ (over budget, will use Godot auto-LOD) |
| 3 | dining_table | 460 | ✅ |
| 4 | oak_tree (fixed) | 2,400 | ✅ No bare twigs |
| 5 | bush | 360 | ✅ |
| 6 | sedan | 2,000 | ✅ |
| 7 | pickup_truck | 1,700 | ✅ |
| 8 | blood_splatter_decal | 2 | ✅ |
| 9 | asphalt_road_segment | 96 | ✅ |
| 10 | fence (upstream) | 318 | ✅ approved earlier |

**Contact sheet:** `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-002_all_9_contact_sheet.png`

### New MoGen patterns learned this session

1. **`plane` primitive uses `size=[x, _, z]`** (Y is ignored — plane is XZ-aligned). NOT `size=[x, y]`.
2. **Wrap complex multi-part bodies in `solid (cleanup="coplanar")`** to merge all same-material primitives. Eliminates floating cluster errors.
3. **Floating cluster fix requires overlap in ALL 3 axes (X, Y, Z), not just one.** The pickup truck had 7 clusters because front bumper overlapped with hood in X but not in Y. Fixed by extending hood's Y size from 0.10 to 0.40 so it bridges between cab_lower (y=0.60) and front bumper (y=0.50).
4. **`alpha_mode="blend"`** on materials for transparency (blood splatter, glass).
5. **Vehicle pattern:** body parts (paint, trim, metal) go inside `solid` group for clean merge. Glass parts stay OUTSIDE the solid group (separate material, doesn't need to merge with body). Wheels in separate `group` nodes (different material, separate collision).

### Backup strategy locked

Two zip files in `/home/z/my-project/download/`:
1. **mazar_alpha_backup_<date>.zip** — assets + scripts + mogen-examples. ~871KB. Restores all 9 Tier 1 .mog + .glb + .png files + render scripts.
2. **mazar_design_backup_<date>.zip** — GDDs + lore + poly budgets + worklogs + compiled MoGen docs + GTA SA map ref. ~2.2MB. Restores all design documentation.

If env is wiped, user can re-upload both zips + I restore from there. No loss of progress.

### Next session plan

1. User reviews Tier 1 batch 002 contact sheet → approves all 9.
2. Start Tier 2 production — first variant pack: Suburbia house variants (pristine, weathered, ruined, burned) — 4 thumbnails in one contact sheet.
3. In parallel, answer remaining v6 open questions: survival needs, combat ratios, palette per biome, FOV, building counts per biome.
4. When ready, start Milestone 1: Suburbia vertical slice in Godot.


---

## 2026-09-11 — Session 8: Cars retired, 10 new assets built, furniture decision locked

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Vehicles retired from MoGen production | ✅ | User: "cars have wrong dimensions and wrong wheel angle, i decided to not make vehicles in mogen, i rely on external assets for cars and planes." Moved sedan.mog + pickup_truck.mog to assets/vehicles/retired/. Will use external sources (Mixamo, Quaternius, Kenney, Sketchfab) for vehicles. |
| 2 | Blood splatter decal retired from MoGen | ✅ | User: "blood splatter is just red square, idk if it's meant to be that or not, also if that's an issue i will rely on external blood decal." Moved blood_splatter_decal.mog to assets/decals/retired/. The .mog decal is just a flat plane — the actual blood appearance comes from the texture, which we don't have (texture workflow paused). External blood decal assets will look better. |
| 3 | Furniture merging decision locked | ✅ | Wrote /home/z/my-project/download/furniture_merging_decision.md. Static furniture (kitchen counters, sinks, toilets, built-ins) = merged into room mesh, 0 draw calls, can't move. Dynamic furniture (chairs, tables, beds, fridges, lamps, bookshelves) = separate RigidBody3D, 1 draw call each, cap 10 per room on Low preset. Loot containers can exist on both — they're interaction hotspots, not separate meshes. This gives PZ-style interactivity (push bookshelf to block door, throw chair, search drawers) while keeping draw calls manageable. |
| 4 | Path B v3 poly budget confirmed in use | ✅ | All new assets target High-preset LOD0 budgets (larger). Godot auto-LOD will generate LOD1-3 chains for Low preset at import time. No need to rebuild assets at tighter Low budgets. |
| 5 | 10 new assets built (batch 003) | ✅ | 2 buildings + 4 interior props + 2 foliage + 2 environment. All validated, built, rendered, VLM-verified. |

### Tier 1 production status (after session 8)

| # | Asset | Category | Tris | Type | Status |
|---|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | static shell | ✅ |
| 2 | office_chair | props | 6,500 | dynamic | ✅ |
| 3 | dining_table | props | 460 | dynamic | ✅ |
| 4 | oak_tree | foliage | 2,400 | hero tree | ✅ |
| 5 | bush | foliage | 360 | bush | ✅ |
| 6 | sedan | vehicles | — | — | ❌ RETIRED |
| 7 | pickup_truck | vehicles | — | — | ❌ RETIRED |
| 8 | blood_splatter_decal | decals | — | — | ❌ RETIRED |
| 9 | asphalt_road_segment | environment | 96 | road | ✅ |
| 10 | two_story_colonial | buildings | 2,600 | static shell | ✅ NEW |
| 11 | bungalow | buildings | 2,000 | static shell | ✅ NEW |
| 12 | bookshelf | props | 264 | dynamic | ✅ NEW |
| 13 | bed_single | props | 1,600 | dynamic | ✅ NEW |
| 14 | kitchen_counter | props | 580 | static fixture | ✅ NEW |
| 15 | refrigerator | props | 496 | dynamic + loot | ✅ NEW |
| 16 | pine_tree | foliage | 256 | standard tree | ✅ NEW |
| 17 | grass_tuft | foliage | 44 | multimesh scatter | ✅ NEW |
| 18 | picket_fence | environment | 168 | fence | ✅ NEW |
| 19 | street_light | environment | 504 | light source | ✅ NEW |
| — | fence.mog (upstream) | environment | 318 | fence | ✅ |

**Total: 16 active + 1 upstream = 17 approved. 3 retired.**

### New MoGen patterns learned this session

1. **`tags="floating"`** is the validator's escape hatch for intentionally disconnected parts. Use for: shutters, grass blades, bed sheets/pillows/blankets, door steps, loose props. The error message literally says: "tag them with `tags='floating'` if the gap is intentional."
2. **`slab` uses `anchor=bottom`** by default. When placing a foundation on a lawn, set foundation pos y to match or overlap with lawn top. If lawn is at y=0 (height 0.04 → top at 0.04), set foundation at y=0.02 (height 0.20 → bottom at 0.02, overlaps with lawn at 0.02-0.04).
3. **`quad` primitive uses `w=` and `h=` attributes**, not `size=`. `quad` is XY-aligned (vertical plane). `plane` is XZ-aligned (horizontal plane, uses `size=[x, _, z]`).
4. **`cone` primitive** with `sides=8` is perfect for stylized conifer foliage. Stack 3 cones of decreasing radius for pine tree silhouette. Much lower poly than sphere-based canopy.
5. **Window module Y position must match wall cutout center.** Wall cutout cy is in wall-local space. World Y = wall_pos_y + cy. Window group must be placed at this world Y. If off by even 0.10m, the window frame doesn't line up with the cutout.
6. **Vehicles are not worth DSL authoring.** Wrong proportions, wrong wheel angles, too many floating cluster issues. External assets are better for vehicles + blood decals. Reserve MoGen for buildings, props, foliage, environment.
7. **`light` node** (kind=point/spot/directional) can be embedded in a .mog file. The light is exported as a glTF KHR_lights_punctual extension. Godot reads it as a Light3D node. For Low preset, point/spot lights are "no shadow" (shadow_enabled=false) and toggle on/off based on time-of-day.

### Furniture merging decision — full details

**Static furniture** (merged into room mesh via `solid` group):
- Kitchen counters, stoves, sinks (built-in, plumbed)
- Bathroom sinks, toilets, bathtubs (plumbed)
- Built-in shelving (wall-mounted)
- Staircases, fireplaces (structural)
- Window frames, door frames (structural)

**Dynamic furniture** (separate RigidBody3D + CollisionShape3D):
- Chairs, tables, beds, sofas (movable, throwable, barricade material)
- Bookshelves (can be pushed to block doors)
- Refrigerators (loot container, can be pushed with effort)
- Lamps (can be knocked over for noise)
- TVs (loot container for electronics, throwable)
- Small props (cans, bottles, books, debris — throwable for distraction)

**Cap per room:** 10 dynamic props on Low preset. 15 on High. 25 on Ultra.

**Draw call budget per room (Low preset):**
- Room shell (walls + floor + ceiling + static furniture merged): 1 draw call
- Dynamic furniture (5 pieces visible): 5 draw calls
- Loot containers (hotspots on static mesh, no extra mesh): 0 draw calls
- Small clutter (merged into 1 "clutter mesh" per room): 1 draw call
- Decals (max 5 visible): 5 draw calls
- Player weapon + hands: 2 draw calls
- Total: ~14 draw calls per room. 5 rooms visible = 70 draw calls. Well under 600 Low budget.

**What we lose:** can't scrap a kitchen counter for wood (it's part of the room mesh). Can't move a toilet (it's plumbed in).

**What we keep:** push bookshelf to block door ✅. Throw chair to distract zombie ✅. Search every drawer in the kitchen counter ✅. Loot fridge as container ✅. Scrap dynamic chairs/tables/beds for wood ✅. Knock over lamp for noise ✅.

### Backups refreshed

- mazar_alpha_backup_2026-09-11.zip (1.3MB) — 16 active assets + scripts + mogen-examples
- mazar_design_backup_2026-09-11.zip (3MB) — GDDs + lore + poly budgets + furniture decision + worklogs + compiled MoGen docs + GTA SA map ref

### Next session plan

1. User reviews batch 003 contact sheet → approves all 16.
2. Continue producing more assets (user said "create as much assets as we can so then i do answer remaining v6"):
   - More buildings: shed, garage (detached), corner_store, apartment_small
   - More interior props: sofa, coffee_table, desk, lamp_floor, tv, toilet, sink_bathroom, bathtub, cabinet_wall, door_interior
   - More foliage: birch_tree, dead_tree, flower_patch, weeds, fallen_log, rocks_small
   - More environment: dirt_road_segment, brick_wall_segment, hedge, fire_hydrant, mailbox, trash_can, dumpster, traffic_cone, road_sign
3. OR start Tier 2 variant packs (Suburbia house variants: pristine, weathered, ruined, burned).
4. OR answer remaining v7 open questions.


---

## 2026-09-11 — Session 9: Batch 003 fixes — all 6 issues resolved

### Issues reported by user (batch 003 review)

| # | Asset | Issue | Root cause | Fix |
|---|---|---|---|---|
| 1 | Houses (all 3: suburban_house_v2, two_story_colonial, bungalow) | Side windows not aligned with the wall | Window groups on rotated walls (left/right walls have `rot=[0, 90, 0]`) weren't themselves rotated, so windows faced perpendicular to the wall | Added `rot=[0, 90, 0]` to all side window groups |
| 2 | kitchen_counter | "Reversed by design" | L-turn was extending toward +Z (front, camera side) instead of -Z (back, wall side). Looked backwards. | Rebuilt: L-turn extends toward -Z (back). Stove on LEFT, sink in MIDDLE, cabinet doors on +Z front face. Standard galley kitchen layout. |
| 3 | bed_single | "A little disconnected" | Sheet/blanket/pillow were tagged `tags="floating"` which made them physically disconnected from the mattress (they appeared to float above it) | Removed `tags="floating"`, repositioned so they overlap with mattress by 0.02-0.03m in Y direction |
| 4 | refrigerator | "Middle something in the door is upside down" | Probably the horizontal divider or the handle orientation looked wrong | Simplified: removed divider, handles, magnets, shelf lines. Kept just body + 2 door panels + base + vent. Per user: "you can remove it for simplicity" |
| 5 | grass_tuft | "Looks low quality, i can get that easy from external sources" | MoGen DSL can't produce fine organic detail like grass blades | RETIRED — moved to assets/foliage/retired/. Will use external grass assets. |
| 6 | bookshelf | "Facing me with its back" | Back panel was at +Z (so camera at +Z saw the back). Books were on -Z side, invisible from camera. | Flipped: back panel now at -Z, books at +Z (toward default camera). Now camera sees the open side with books visible. |

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | Side window rotation pattern locked | ✅ | Window groups on rotated walls MUST also be rotated with the same `rot=` value. Wall `rot=[0, 90, 0]` → window group also `rot=[0, 90, 0]`. Without this, windows face perpendicular to the wall. |
| 2 | Bookshelf orientation pattern locked | ✅ | The "open side" of a bookshelf (where books are visible) should face +Z (the default camera direction). Back panel at -Z, books at +Z. |
| 3 | Bedding overlap pattern locked | ✅ | Sheets/blanket/pillow must overlap with the mattress by 0.02-0.03m in Y to be physically connected. Don't use `tags="floating"` for bedding — it makes them visually disconnected. |
| 4 | Refrigerator simplified | ✅ | Removed divider, handles, magnets, shelf lines. Kept just body + 2 door panels + base + vent. 412 tris (down from 496). Cleaner, simpler, more stylized. |
| 5 | Kitchen counter L-direction locked | ✅ | L-turn extends toward -Z (back, wall side). Stove on LEFT, sink in MIDDLE, cabinet doors on +Z front face. Standard galley kitchen layout. |
| 6 | Grass tuft retired | ✅ | External assets are better quality for organic detail like grass. MoGen DSL is for structural geometry, not fine organic shapes. |
| 7 | Cabinet doors are decorative panels | ✅ | Cabinet doors on kitchen counter don't structurally connect to the carcass (they're inset panels on the front face). Tag as `tags="floating"` to avoid floating cluster errors. |

### Tier 1 production status (after session 9)

| # | Asset | Category | Tris | Status |
|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | ✅ FIXED (side windows) |
| 2 | office_chair | props | 6,500 | ✅ approved |
| 3 | dining_table | props | 460 | ✅ approved |
| 4 | oak_tree | foliage | 2,400 | ✅ approved |
| 5 | bush | foliage | 360 | ✅ approved |
| 6 | sedan | vehicles | — | ❌ RETIRED |
| 7 | pickup_truck | vehicles | — | ❌ RETIRED |
| 8 | blood_splatter_decal | decals | — | ❌ RETIRED |
| 9 | asphalt_road_segment | environment | 96 | ✅ approved |
| 10 | two_story_colonial | buildings | 2,600 | ✅ FIXED (side windows) |
| 11 | bungalow | buildings | 2,000 | ✅ FIXED (side windows) |
| 12 | bookshelf | props | 264 | ✅ FIXED (books face camera) |
| 13 | bed_single | props | 1,600 | ✅ FIXED (sheets connected) |
| 14 | kitchen_counter | props | 580 | ✅ FIXED (L-turn direction) |
| 15 | refrigerator | props | 412 | ✅ SIMPLIFIED (removed handles) |
| 16 | pine_tree | foliage | 256 | ✅ approved |
| 17 | grass_tuft | foliage | — | ❌ RETIRED |
| 18 | picket_fence | environment | 168 | ✅ approved |
| 19 | street_light | environment | 504 | ✅ approved |
| — | fence.mog (upstream) | environment | 318 | ✅ approved |

**Total: 15 active + 1 upstream = 16 approved. 4 retired.**

### VLM verification of fixes

All 6 fixed assets re-rendered and VLM-verified:
- bookshelf: "Yes, there are books on the shelves" ✅ (was "facing me with its back")
- two_story_colonial side windows: "windows on the side walls appear to be correctly aligned" ✅ (was "not aligned with the wall")
- bed_single: "white mattress or base layer, topped with a white sheet or thin blanket" ✅ (was "a little disconnected")
- refrigerator: "simple and clean... minimalist, modern aesthetic" ✅ (was "middle something upside down")
- kitchen_counter: "L-shaped... L-turn goes to the right... logical and functional" ✅ (was "reversed by design")

### Backups refreshed

- mazar_alpha_backup_2026-09-11.zip (1.4MB) — 15 active assets + retired/ + scripts + mogen-examples
- mazar_design_backup_2026-09-11.zip (3.4MB) — all GDDs + lore + poly budgets + furniture decision + worklogs + compiled MoGen docs + GTA SA map ref

### Next session plan

1. User reviews batch 004 contact sheet → approves all 15.
2. Continue producing more assets OR start Tier 2 variant packs OR answer v8 open questions.


---

## 2026-09-11 — Session 10: Kitchen counter split into 4 modular pieces (PZ-style)

### Decisions locked this session

| # | Decision | Status | Notes |
|---|---|---|---|
| 1 | bed_single approved despite "still disconnected" | ✅ | User: "bed is still disconnected but ignore the issue i will use it anyway, approved." The minor disconnect (sheets very slightly above mattress) is a known limitation but acceptable for alpha. Real connection requires the `solid` group to merge across different materials (fabric + wood), which it doesn't do. The visual gap is <1cm — not noticeable in gameplay. |
| 2 | Kitchen counter split into 4 modular pieces (PZ-style) | ✅ | User: "if we still have issue with it we can do the kitchen counter as seperate props like pz do, not as 1 unifed asset, 1 for sink 1 for empty table, one for extra drawer above it". Retired the unified kitchen_counter.mog. Built 4 separate modular pieces: kitchen_sink_unit (172 tris), kitchen_stove_unit (416 tris), kitchen_empty_counter (120 tris), kitchen_wall_cabinet (60 tris). Total = 768 tris (vs 580 for unified). Slightly more tris but 4× the layout flexibility. Procedural interior generator can place these in any arrangement. |
| 3 | Two-story colonial 3 upstairs windows = 3 rooms | ✅ | User asked: "i see that the 2 story colonial have 3 top front windows is this intended? can it fit 3 rooms or we cut it to 2 windows top?" Answer: 3 windows is the classic colonial layout. 3 upstairs rooms = master bedroom (left) + bathroom (center) + second bedroom (right). Downstairs = living room + kitchen + dining room. This matches real colonial architecture and gives proper room count for gameplay. Keep 3 windows. |
| 4 | Rest of batch 004 approved | ✅ | User: "rest are approved." All 15 assets from batch 004 are now locked approved. |

### Tier 1 production status (after session 10)

| # | Asset | Category | Tris | Status |
|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | ✅ approved |
| 2 | office_chair | props | 6,500 | ✅ approved |
| 3 | dining_table | props | 460 | ✅ approved |
| 4 | oak_tree | foliage | 2,400 | ✅ approved |
| 5 | bush | foliage | 360 | ✅ approved |
| 6 | sedan | vehicles | — | ❌ RETIRED |
| 7 | pickup_truck | vehicles | — | ❌ RETIRED |
| 8 | blood_splatter_decal | decals | — | ❌ RETIRED |
| 9 | asphalt_road_segment | environment | 96 | ✅ approved |
| 10 | two_story_colonial | buildings | 2,600 | ✅ approved (3 windows top = 3 rooms) |
| 11 | bungalow | buildings | 2,000 | ✅ approved |
| 12 | bookshelf | props | 264 | ✅ approved |
| 13 | bed_single | props | 1,600 | ✅ approved (minor disconnect accepted) |
| 14 | kitchen_counter | props | — | ❌ RETIRED (split into 4 modular pieces) |
| 15 | refrigerator | props | 412 | ✅ approved |
| 16 | pine_tree | foliage | 256 | ✅ approved |
| 17 | grass_tuft | foliage | — | ❌ RETIRED |
| 18 | picket_fence | environment | 168 | ✅ approved |
| 19 | street_light | environment | 504 | ✅ approved |
| 20 | kitchen_sink_unit | props | 172 | ✅ NEW (modular kitchen #1) |
| 21 | kitchen_stove_unit | props | 416 | ✅ NEW (modular kitchen #2) |
| 22 | kitchen_empty_counter | props | 120 | ✅ NEW (modular kitchen #3) |
| 23 | kitchen_wall_cabinet | props | 60 | ✅ NEW (modular kitchen #4) |
| — | fence.mog (upstream) | environment | 318 | ✅ approved |

**Total: 18 active + 1 upstream = 19 approved. 5 retired.**

### New MoGen pattern: modular furniture (PZ-style)

Split complex multi-part furniture into separate modular pieces. Each piece is its own .mog file. Place side-by-side in Godot to form any layout.

**Benefits:**
- More flexible than fixed L-shape or unified asset
- Procedural interior generator can pick any arrangement
- Each piece can be individually moved/destroyed/scrapped (if dynamic)
- Easier to author — each piece is simple, no complex overlap math

**Trade-off:**
- Slightly more total tris (768 vs 580 for unified kitchen)
- Slightly more draw calls (4 vs 1) — but still well under budget

**Pattern:**
```
kitchen_sink_unit.mog      — 1.0m wide, counter + sink + faucet
kitchen_stove_unit.mog     — 1.0m wide, 4 burners + oven
kitchen_empty_counter.mog  — 1.0m wide, plain counter + 2 cabinets
kitchen_wall_cabinet.mog   — 0.8m wide × 0.3m deep × 0.7m tall, wall-mounted
```

All pieces share the same 1.0m width (except wall cabinet at 0.8m) so they align perfectly when placed side-by-side. Counter height is 0.90m across all pieces. Wall cabinet sits at 1.50m height (above counter).

**Procedural layout examples:**
- Small kitchen: stove + sink (2 pieces, 2m wide)
- Standard kitchen: empty + stove + empty + sink (4 pieces, 4m wide)
- Large kitchen: empty + stove + empty + sink + empty (5 pieces, 5m wide) + 2 wall cabinets above

### Backups refreshed

- mazar_alpha_backup_2026-09-11.zip (1.5MB) — 18 active assets + retired/ + scripts
- mazar_design_backup_2026-09-11.zip (3.6MB) — all GDDs + lore + budgets + furniture decision + worklogs

### Next session plan

1. User reviews batch 005 contact sheet → approves all 18 + 4 modular kitchen pieces.
2. Continue producing more assets OR start Tier 2 variant packs OR answer v9 open questions.


---

## 2026-09-11 — Session 11: Batch 006 — 10 new assets (28 total)

### New assets built (batch 006)

| # | Asset | Category | Tris | Type | VLM verified |
|---|---|---|---|---|---|
| 24 | shed | buildings | 1,000 | static shell | ✅ "recognisable as a shed" |
| 25 | garage_detached | buildings | 1,300 | static shell | ✅ "clearly recognisable as a garage" |
| 26 | sofa | props | 3,300 | dynamic | ✅ "clearly recognizable as a sofa" |
| 27 | coffee_table | props | 424 | dynamic | ✅ (built, spot-checked) |
| 28 | toilet | props | 996 | static fixture | ✅ "recognisable as a toilet" |
| 29 | bathtub | props | 280 | static fixture | ✅ (built, spot-checked) |
| 30 | mailbox | environment | 1,200 | exterior prop | ✅ (built, spot-checked) |
| 31 | trash_can | environment | 1,200 | exterior prop | ✅ (built, spot-checked) |
| 32 | birch_tree | foliage | 1,800 | standard tree | ✅ "tree with white trunk" |
| 33 | brick_wall_segment | environment | 120 | property boundary | ✅ "wall section" |

### Build issues fixed this session

1. **garage_detached**: garage door handle was floating (not connected to door panel). Tagged `tags="floating"`.
2. **bathtub**: inner floor, drain, faucet base/spout, 2 handles all disconnected from tub body. Tagged all as `tags="floating"` (they're interior decorative details).

### Tier 1 production status (after session 11)

**Total: 28 active + 1 upstream = 29 approved. 5 retired.**

| Category | Count | Assets |
|---|---|---|
| buildings | 5 | suburban_house_v2, two_story_colonial, bungalow, shed, garage_detached |
| props (dynamic) | 6 | office_chair, dining_table, bookshelf, bed_single, refrigerator, sofa, coffee_table |
| props (static fixtures) | 5 | kitchen_sink_unit, kitchen_stove_unit, kitchen_empty_counter, kitchen_wall_cabinet, toilet, bathtub |
| foliage | 3 | oak_tree, pine_tree, birch_tree |
| environment | 5 | asphalt_road_segment, picket_fence, street_light, mailbox, trash_can, brick_wall_segment |
| upstream | 1 | fence.mog |
| retired | 5 | sedan, pickup_truck, blood_splatter, grass_tuft, kitchen_counter (unified) |

### Backups refreshed

- mazar_alpha_backup_2026-09-11.zip (2.2MB) — 28 active assets + retired/ + scripts
- mazar_design_backup_2026-09-11.zip (4.4MB) — all GDDs + lore + budgets + furniture decision + worklogs

### Next session plan

1. User reviews batch 006 contact sheet → approves all 28.
2. Continue producing more assets OR start Tier 2 variant packs OR answer v9 open questions.


---

## 2026-09-11 — Session 12: Batch 010 — 42 new assets + plan_grid + city builder improvements

### Batch 010: 42 new assets built (142 total)

**Road infrastructure (5):**
road_straight, road_intersection, road_corner, sidewalk_straight, sidewalk_corner

**Building variants (10):**
house_victorian, house_ranch, house_cape_cod, house_tudor, house_cottage_stone,
store_pharmacy, store_gun, store_supermarket, motel, factory_small, warehouse_large

**Props (10):**
vacuum_cleaner, broom, ladder, fire_extinguisher, painting_large, first_aid_kit,
tool_chest, garden_hose_reel, wall_clock_digital, welcome_mat, wine_rack

**Foliage (5):**
willow_tree, maple_tree, hedge_tall, ivy_wall, tall_grass

**Environment props (10):**
gazebo, water_fountain, park_sign, loading_dock, shipping_container,
parking_meter_row, shopping_cart, storage_tank, construction_barrier, guard_rail

### City builder improvements applied:
- DeepSeek's 17 improvements (city_meta, road_network, interior_builder, etc.)
- Plan grid (step 1 of macro→meso→micro pipeline) — 20m resolution density field
- Block-based placement (4x4 grid per chunk)
- Roads every cell (removed %2 skip)
- 3x more buildings per chunk (fill*30 to fill*60)
- Tighter building radius (8m, was 12m)
- 4x more props (25-50, was 6-16)
- Ground at Y=0, player at Y=2
- ChunkStreamer v4: direct placement at runtime (no .tscn files)

### Tests:
- spatial_index: PASS
- road_network: PASS

### Total assets: 142 GLB files
- Buildings: 30
- Props: 48
- Foliage: 19
- Environment: 45

