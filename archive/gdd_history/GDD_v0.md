# Game Design Document — Working Title TBD

> **Format:** Markdown. First-person (the designer = me, the player-facing voice).
> **Status:** v0 — pre-production. Decisions captured here are *proposed*; nothing is locked until the « locked 🔒 » marker appears next to it.
> **Inspiration:** Project Zomboid (gameplay loop, tone, permadeath stakes) — but **not** its isometric pixel art. We are doing real 3D.
> **Engine:** Godot 4.x (glTF 2.0 native).
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot).

---

## 0. Open questions (answer these before v1)

These are the decisions I still need from you before I draft the full GDD:

1. **Map size + tile budget.** How big is the world? One small town? A county? Hand-authored or semi-procedural?
2. **Location variations.** Just one biome (e.g. temperate forest + town)? Or multiple (forest + farmland + suburb + downtown)?
3. **Time horizon.** Day-1 survival sim? Multi-month progression with seasons? Decade-scale base-building?
4. **Player count.** Strictly single-player? Co-op optional? MMO-scale?
5. **Failure state.** True permadeath (Zomboid-like) or roguelite with meta-progression?
6. **Combat focus.** Stealth-first (Zomboid), gun-heavy (7DtD), melee-first (State of Decay)?

Once you answer these, I'll convert this from a "decision log" into a real GDD with feature specs, systems, content scope, and milestone plan.

---

## 1. Visual style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native)

**My take (and the lookbook backs me up):**

I am building this game with MoGen-native stylized low-poly geometry, lit with PBR materials where the albedo is LLM-drawn and the normal/roughness/AO are locally-derived. This is **not** Project Zomboid's pixel art and **not** 7 Days to Die's gritty realism. It sits in the same neighbourhood as *Night of the Dead*, *Breathedge*, or the cleaner scenes from *The Long Dark*.

**Evidence:** I rendered the 11 example `.mog` files that ship with MoGen. You can see them at:

- `/home/z/my-project/download/mogen-lookbook/suburban_house.png` — a two-storey + garage house with gable roof, windows, chimney, AC unit, porch, driveway, lawn. 2.8k tris, 11 materials. Renders in 6 ms.
- `/home/z/my-project/download/mogen-lookbook/humanoid.png` — blocky skinned character. 9.9k tris, 1 skin, 10 joints, 1 idle clip.
- `/home/z/my-project/download/mogen-lookbook/chair.png` — minimal dining chair, 1.1k tris.
- (8 more — broken_window CSG demo, simple_house, modern_skyscraper, windmill, needle_tower, fence, cup, table)

The look is clean, low-poly, painterly when textured. **Approve this art direction** 🔓 and I'll lock the palette.

### Comic-book / outline post-processing

You asked about adding a comic-like shader on top. **Yes, this is a Godot-side decision, not a MoGen-side one.** Three implementation paths I'd consider, in order of effort:

1. **Cheap & cheerful (≈1 day):** Godot's built-in outline via inverted hull — duplicate every mesh, scale 1.03×, render back-faces only in solid black. Looks like *Zelda Wind Waker* / *Sly Cooper*. Pairs beautifully with low-poly.
2. **Screen-space edge detect (≈3 days):** custom post-process shader on the `WorldEnvironment` that does Sobel on depth+normal buffers. Controllable line thickness by object ID. Looks like *Borderlands* / *Hi-Fi Rush*. More flexible but more expensive.
3. **Full cel-shading (≈1 week):** replace the PBR lit shader with a custom cel shader (banded lighting + hard shadows + rim light + outline). This is the most "comic" looking but throws away half the PBR textures we generate, so it fights the MoGen-native pipeline.

**My recommendation:** start with option 1 (inverted hull outline) at the same time we lock the palette. It's cheap, looks great with low-poly geometry, and if we want to upgrade to option 2 later we can. **Approve path 1?** 🔓

---

## 2. Camera — first-person

**Confirmed.** I'm going first-person. This locks a few things downstream:

- **Player eye height:** 1.65 m (so doors must be ≥1.90 m to feel comfortable — 2.10 m standard).
- **Asset density:** needs to hold up at 0.5 m viewing distance. A cereal box on a shelf must read as a cereal box, not a coloured cube.
- **Poly budget per scene:** higher than isometric. A kitchen interior might have 30k+ tris of props in view at once. LODs matter.
- **Asset production time per building:** roughly 3× an isometric equivalent, because interiors need to be modelled, not just exteriors.

First-person also means **vertically interesting level design** — looking up at a tall building, looking down into a basement — which MoGen handles natively (its `cave` and `dungeon` generators exist for exactly this).

---

## 3. Characters — Schedule 1-style modular creator (with external base meshes)

**My take, after building and rendering a test humanoid in MoGen DSL:**

A blocky DSL character *can* be made (see `humanoid.png` — 16 meshes, 10 hinge joints, 1 skin, 1 idle clip). It reads as **Roblox/Minecraft** — fine if we were making a blocky sandbox, wrong for a Zomboid-inspired survival tone.

I am **not** going to do full DSL characters. Instead I propose a **hybrid**:

1. **External base mesh** for the body — head, hands, face, body skeleton.
   - Candidates I'll evaluate: Mixamo (free, rigged), Quaternius (CC0 stylised), Ready Player Me (web avatar creator).
   - We pick **one** base mesh and stick with it for v1.
2. **MoGen for clothing & accessories** layered on top via `bind="<bone_name>"` rigid pinning:
   - Backpacks, hats, glasses, jewelry, bandoliers
   - Belts, scarves, holstered weapons
   - Body armour, jackets (capsule + cylinder primitives, looks fine because they're rigid)
3. **Schedule 1-style character creator** as a v2 feature:
   - Modular: head shape slider, hair, beard, body type, skin tone, top, bottom, footwear, outer layer, accessory
   - Each slot is a swap-able mesh. We author them in MoGen where possible, external where DSL can't deliver (faces, hands).
   - This is the right long-term play — it solves character variety without buying more external assets.

**Cost reality check:** if we tried full DSL characters, expect ~2 weeks per prototype iteration. With the hybrid, a new clothing piece takes ~1 day. **Approve the hybrid?** 🔓

---

## 4. World structure — FIXED, HAND-AUTHORED MAP

**My take: you're right.** I am going with a fixed, hand-authored map.

**Why I agree with your instinct:**

- **Every building is accessible.** You said this. Procedural generation gives you 80% junk buildings with locked doors or empty interiors. Hand-authored means every building has a *reason* — a story, a loot theme, a tactical layout, a memorable landmark. This is the Zomboid appeal: Muldraugh and West Point are *real places* in the fiction.
- **Narrative + landmarks.** A fixed map lets me place "the church where the climax happens", "the hospital where you find the cure", "the farm where you meet the NPC". Procedural can't do this.
- **Performance budgeting.** I know exactly how many draw calls, how many buildings, how much geometry is in view at any point. Tuning LODs is straightforward.
- **Replayability without randomness.** Zomboid doesn't randomise its map. Replayability comes from *playstyle* variation (different builds, different starting scenarios, different NPC factions), not from a new map each run.

**What we lose:**
- No "infinite" playthroughs. A player who clears the map is done.
- More upfront content work. Every building needs to be designed, not generated.

**Mitigation:** after the main map ships, we can add procedural *outskirts* (random forest camps, random highway encounters) as DLC / mod support. The hand-authored core stays canonical.

**Proposed map structure** (subject to your answers to §0):

- One contiguous town + surrounding rural area
- Town divided into districts (each with its own architectural vocabulary + loot tier)
- Hand-placed landmarks (church, hospital, school, supermarket, police station, farm)
- Player base camp(s) — fixed locations the player can fortify
- Outskirts — less hand-detailed, more procedural fill

**Sizes to decide in v1:**
- Map dimensions (km × km)? 🔓
- Number of accessible buildings? 🔓
- Number of districts? 🔓
- Total poly budget for the whole map? 🔓

---

## 5. Asset production pipeline — DESIGN

I've set this up in your environment. Here's the workflow:

**Files I created:**
- `/home/z/my-project/asset-pipeline/README.md` — the contract between us
- `/home/z/my-project/asset-pipeline/prompts/` — saved prompt audit trail
- `/home/z/my-project/asset-pipeline/style-guide/` — locked decisions go here
- `/home/z/my-project/assets/{buildings,props,foliage,characters,environment,vehicles,decals}/{src,out,textures,refs}/` — the asset library structure

**Roles:**
- **You:** describe intent ("a rural barn, half-collapsed"), approve / reject renders, lock style decisions.
- **Me:** write `.mog` DSL, validate, build GLB, render preview PNG, iterate on your feedback, generate PBR textures after geometry approval.

**The loop:**
1. You describe what you want.
2. I draft `.mog`, run `mogen check` (must be 0 errors), `mogen build`, render via Chrome + three.js to a 1024px PNG.
3. You review the PNG → approve / request changes.
4. I iterate by editing the `.mog` in place (never regenerate from scratch).
5. After geometry approval, I run `mogen textures` (needs Gemini API key — we'll need to set that up).
6. Asset moves to the library under its category.

**Every prompt is saved** under `/asset-pipeline/prompts/` so we can re-generate, branch, or fork later. The filename is `YYYY-MM-DD-<slug>.md`.

---

## Next: open decisions (§0)

Before I draft v1 of this GDD, I need your answers on the §0 questions: map size, location variations, time horizon, player count, failure state, combat focus. These determine content scope, art budget, and feature priority.

Once you answer those, the v1 GDD will have:
- Locked art direction + palette
- Locked character pipeline (external base + MoGen clothing)
- Locked map structure with dimensions
- Feature spec for: survival needs, combat, base-building, NPCs, day/night, weather, infection
- Milestone plan (vertical slice → early access → 1.0)
- Asset production queue (first 20 assets to build, in priority order)

---

## Appendix A — what I learned while validating MoGen

A quick honesty log from setting up the toolchain:

- **MoGen compiles fast.** A 440-node skyscraper scene builds in ~10 ms. A 49-node suburban house: 6 ms. This is fast enough to iterate live.
- **No display server needed for build.** `mogen check` + `mogen build` work headless. Only `mogen thumbnail` and `mogen-studio` need GL. We worked around this by writing our own GLB renderer using Chrome + three.js + swiftshader — gives proper PBR output and we control the camera.
- **Textures require a Gemini API key.** `mogen textures` is Gemini-only by design (it uses Gemini 2.5 Flash Image for the albedo; normal/roughness/AO are derived locally). When we're ready to texture, you'll need to `mogen auth antigravity login` or set `GEMINI_API_KEY`. We can also use Z.ai's `glm-image` endpoint via `--zai-api-key`.
- **MoGHub** is a community library we can browse / publish to (`mogen moghub discover --query chair`). Useful for inspiration and forking once we have published-quality assets.
- **DSL is structural, not artistic.** MoGen is a *deterministic geometry engine*. It is exceptional at "house with 4 windows, a chimney, attached garage, gable roof". It is bad at "rotting zombie with torn shirt". This shapes §3.
