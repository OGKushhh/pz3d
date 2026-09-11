# Asset Production Pipeline

This document defines **who does what** in the MoGen → Godot asset pipeline for our Project Zomboid-inspired 3D game. It is the contract between me (the AI) and you (the human).

---

## TL;DR — the loop

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. YOU      describe intent    ("a rural barn, half-collapsed") │
│       │                                                          │
│  2. ME (AI)  draft a .mog       (modules, primitives, materials) │
│       │                                                          │
│  3. ME       validate + build    (mogen check → mogen build → glb)│
│       │                                                          │
│  4. ME       render preview      (chrome + three.js + swiftshader)│
│       │                                                          │
│  5. YOU      review the PNG      → approve / request changes      │
│       │                                                          │
│  6. ME       (optional) texture  (mogen textures, needs API key) │
│       │                                                          │
│  7. ME       publish to library   (commit .mog + .glb + .png)     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Roles

### You (the human)
- **Intent.** Describe what you want the asset to be, where it lives in the world, what gameplay role it serves.
- **Style direction.** Approve or reject the visual style of each preview. "Yes / no / try again with X changed."
- **World knowledge.** You know what a Project Zomboid game feels like; you call the tone.
- **Final say on texturing.** After you approve geometry, I texture it; you approve the texture pass too.

### Me (the AI)
- **DSL authorship.** Write valid `.mog` source that compiles.
- **Validation.** Run `mogen check` and fix every diagnostic before showing you anything.
- **Rendering.** Run `mogen build` then `render_with_chrome.js` to produce PNG previews.
- **Iteration.** When you say "make the roof steeper" or "shorter legs", I edit the `.mog` in place and re-render.
- **Texture generation.** Once geometry is approved, run `mogen textures` with a Gemini key to add PBR albedo + normal + roughness + AO.
- **Library curation.** Organise every approved asset under `/home/z/my-project/assets/<category>/`.

### What neither of us does alone
- **External assets** (characters, special items): we decide together. See "Characters" below.

---

## Directory layout

```
/home/z/my-project/
├── assets/                       # the curated asset library
│   ├── buildings/                # houses, shops, warehouses, etc.
│   │   ├── src/                  # *.mog source (editable, version-controlled)
│   │   ├── out/                  # *.glb compiled (Godot imports these)
│   │   ├── textures/             # PNG PBR maps per material
│   │   └── refs/                 # reference images, dimensions, photos
│   ├── props/                    # furniture, loot, decorations
│   ├── foliage/                  # trees, bushes, grass, dead crops
│   ├── characters/               # NPC + player rigs (mostly external; see below)
│   ├── environment/              # terrain patches, roads, fences, lights
│   ├── vehicles/                 # cars, bikes (abandoned)
│   └── decals/                   # blood, grime, damage, posters
│
├── asset-pipeline/
│   ├── README.md                 # this file
│   ├── prompts/                  # saved natural-language prompts (audit trail)
│   │   ├── 2026-09-11-rural-barn.md
│   │   └── ...
│   └── style-guide/              # locked visual decisions
│       ├── palette.md            # the canonical colour palette
│       ├── proportions.md         # human scale, door heights, road widths
│       └── reference-renders/     # the approved lookbook PNGs
│
├── scripts/                      # generation + render scripts
│   ├── render_with_chrome.js      # the PBR renderer (three.js + chrome)
│   ├── render_glb.html            # the page that loads + renders a GLB
│   └── render_mogen_lookbook.py  # fallback matplotlib renderer (no GL)
│
├── mogen-examples/               # the upstream example .mog files
│
└── download/                      # user-facing deliverables (GDD, lookbook)
    ├── GDD_v0.md
    └── mogen-lookbook/            # 11 PNG previews of MoGen-native output
```

---

## The prompt audit trail

Every asset starts with a written prompt. We save them so we can re-generate, branch, or fork them later.

**Prompt file naming:** `YYYY-MM-DD-<slug>.md`

**Prompt file format:**
```markdown
# <slug>

**Date:** 2026-09-11
**Author:** <you>  | **DSL:** <me>
**Asset slot:** buildings/rural-barn
**Status:** draft → review → approved → textured → published

## Intent
A collapsed rural barn, half the roof caved in, weathered red paint,
set in a Midwest abandoned farmstead. Player can walk inside, loot
hay bales, find a dead tractor.

## Style notes
- Aged, not destroyed — still recognisably a barn
- Board gaps let light through (CSG difference)
- Asymmetric roof collapse (one side higher)
- Doorway tall enough for the player (~2.0m)

## Gameplay hooks
- Loot containers: 2 hay bales, 1 tool chest
- Light enters through roof gap — gameplay cue for time of day
- Hiding spot: zombie pathing ignores interior

## MoGen approach
- main volume: solid() of box primitives, cleanup="coplanar"
- roof: prism with subdivide for the collapsed section
- boards: thin boxes with array + small jitter (noise=)
- CSG: difference() to cut window/door holes and board gaps

## Variants
- v1: pristine (lore accurate, pre-outbreak)
- v2: collapsed (default in-game)
- v3: burned-out (post-quest state)
```

---

## Style guide (locked decisions)

Locked decisions live in `/home/z/my-project/asset-pipeline/style-guide/`. Once we agree on a value, we don't re-debate it on every asset.

| Decision | Value | Locked? |
|---|---|---|
| Coordinate system | glTF (right-handed, +Y up, -Z forward) | ✅ MoGen default |
| Length unit | 1 metre | ✅ MoGen default |
| Player eye height | 1.65 m | 🔓 to decide |
| Standard door width | 0.90 m | 🔓 to decide |
| Standard ceiling | 2.40 m | 🔓 to decide |
| Road width (2-lane) | 6.0 m | 🔓 to decide |
| City block size | 80 m × 120 m | 🔓 to decide |
| Default PBR texture size | 512² (albedo + 3 derived) | ✅ mogen default |
| Poly budget (hero prop) | ≤ 5k tris | 🔓 to decide |
| Poly budget (background building) | ≤ 10k tris | 🔓 to decide |
| Poly budget (player character) | ≤ 12k tris | 🔓 to decide |
| Material palette | TBD | 🔓 to decide |

---

## Characters — special case

We agreed (pending your confirmation) that the MoGen DSL is good for **environments and props** but **not good enough for organic characters**. The humanoid.mog render proves this: it reads as Roblox/Minecraft, not as a Project Zomboid survivor.

### Recommended hybrid
1. **External base meshes** for the body (head, hands, face). Sources to evaluate:
   - Mixamo (free, Adobe) — has rigged low-poly humans
   - Quaternius (CC0) — stylised low-poly characters
   - Kenney (CC0) — blocky but cleaner than DSL
   - Ready Player Me — stylised avatar creator (web-based)
2. **MoGen for clothing & accessories** layered on top via `bind="<bone>"` rigid pinning:
   - Backpacks, hats, glasses, jewelry
   - Belts, scarves, bandoliers
   - Weapons (holstered, slung)
3. **Schedule 1-style modular character creator** is the end goal — but we build it later, once we have 5+ clothing pieces that fit a single base mesh.

### Why not full DSL characters
- Limb joints look mechanical even with envelope skinning
- Facial features are limited to sphere/box approximations
- Hand detail (fingers) is impractical
- Iteration cost is 3–5× higher than environments

### What we'd lose if we tried
- ~2 weeks of iteration per character prototype vs ~2 days with external base + MoGen clothing

---

## Workflow commands

These are the commands I run when you give me an asset request:

```bash
# 1. validate the DSL source (no errors allowed before showing you)
mogen check <file>.mog

# 2. build the GLB
mogen build <file>.mog --out <file>.glb

# 3. render a 1024px preview (chrome + three.js PBR)
node /home/z/my-project/scripts/render_with_chrome.js

# 4. (later, after your approval) generate PBR textures
mogen textures <file>.mog --style "stylized low-poly PBR-lite, painterly, restrained palette"

# 5. publish to the library
mv <file>.mog /home/z/my-project/assets/<cat>/src/
mv <file>.glb /home/z/my-project/assets/<cat>/out/
```

If you want me to make changes, I edit the `.mog` in place and re-run steps 1–3. No regeneration from scratch — we iterate.

---

## MoGHub — the community library

We can browse and publish to MoGHub (`mogen moghub discover --query chair`). Useful for:
- **Inspiration** — see what other `.mog` authors have done
- **Forking** — grab a base and modify it
- **Publishing** — share our best pieces once the game ships

Authentication:
```bash
mogen auth moghub login   # opens browser flow
mogen moghub publish <file>.mog --thumbnail <file>.png
```

We will not publish anything to MoGHub without your explicit approval.

---

## Quality bar

Before an asset ships to the library, it must:
- [ ] `mogen check` exits 0 with zero diagnostics
- [ ] `.glb` builds in <10 ms and opens cleanly in Godot 4.x
- [ ] Preview PNG passes VLM sanity check ("can you identify this as a X?")
- [ ] Material colours match the locked palette (when palette exists)
- [ ] Scale matches the locked dimensions (when dimensions exist)
- [ ] PBR textures generated and reviewed (when applicable)
- [ ] `refs/` contains at least one reference image for future forks
