# pz3d — MAZAR

Godot 4.7 first-person survival game. Project Zomboid in real 3D.

## Quick Start
1. Open `godot_project/project.godot` in Godot 4.7.2
2. Wait for import (1-2 min — 214 Cogito scripts + PPS assets)
3. Run `scenes/baked_world.tscn` (F6) — drop into the city
4. Or run `addons/cogito/DemoScenes/COGITO_3_Lobby.tscn` — test Cogito features

## Controls
| Key | Action |
|---|---|
| WASD | Move |
| Mouse | Look |
| Space | Jump |
| Shift | Sprint |
| C | Crouch |
| Left Click | Fire weapon |
| 1/2/3/4 | Switch weapons |
| T | Toggle fly mode |
| Esc | Release mouse |

## Docs
- `docs/GDD.md` — game design document (canonical)
- `docs/style/STYLE_GUIDE.md` — visual style guide (12 sections, palette, HUD, atmosphere)
- `roadmap.md` — phase tracker + priorities + design decisions
- `worklog.md` — session log (append-only)
- `STATUS.md` — what's current vs archived

## Architecture
- **City gen**: `scripts/map_baker.gd` bakes 192 chunk `.tscn` files headless
- **Runtime**: `scripts/chunk_loader.gd` streams 25 chunks near player
- **Weapons**: `weapons/wieldable_hitscan.gd` (extends CogitoWieldable)
- **Cogito**: immersive sim framework (inventory, NPC AI, save/load, interaction)
- **Principle**: extend Cogito, don't fork it

## Layout
```
godot_project/          — runtime game
  scenes/baked_world.tscn    — main scene (sky + player + ChunkLoader)
  scenes/baked_chunks/       — 192 chunk .tscn files
  weapons/                   — our weapon extensions (WieldableHitscan, Tracer, etc.)
  scripts/                   — baker, chunk_loader, player controllers
  tools/                     — city gen tools (chunk_streamer, block_layout, etc.)
  addons/cogito/             — Cogito framework (DO NOT MODIFY)
  addons/fpc/                — Quality FPS Controller (available)
  addons/terrain_3d/         — terrain plugin (deferred)
  addons/M.A.V.S/            — vehicle system
docs/                   — canonical docs + style guide
docs/style/             — mood references + STYLE_GUIDE.md
archive/                — historical (do not edit)
```
