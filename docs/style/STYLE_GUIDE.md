# Mazar — Visual Style Guide

> **Source:** 3 mood reference images analyzed via VLM (glm-5v-turbo).
> **Purpose:** Define the visual language for Mazar — palette, lighting, HUD, atmosphere.
> **NOT technical specs** — mood + direction only. Real assets built in MoGen.

---

## 1. ART STYLE: Cel-Shaded Comic Book

Every visible surface is a 3D mesh with a cel-shading shader applied:
- **Banded lighting** — 2-3 discrete lighting steps (Midtone, Shadow, Highlight) instead of smooth gradients
- **Inverted-hull outlines** — thick black outlines (1.5-3px) on all models, NPCs, weapons, UI
- **Posterization** — limit colors to ~16-24 values per channel (prevents photorealism)
- **Paper grain overlay** — subtle dot pattern at 5-10% opacity across screen (comic book printing feel)
- **Ramp texture** — 1D lookup texture for all diffuse lighting

**Implementation priority:** Toon shader + outlines = 70% of the identity.

---

## 2. COLOR PALETTE

### Environment (desaturated, warm earth tones)
| Element | Color | Hex |
|---|---|---|
| Sky/Fog dominant | Muted Olive-Grey | `#8B8B7A` |
| Walls/Ceiling (interior) | Warm Gray | `#8C857A` |
| Wood (cabinets/furniture) | Dusty Oak | `#6B5344` |
| Asphalt/Road | Dark Grey-Brown | `#4A4A3D` |
| Grass/Vegetation | Muted Sage Green | `#5C6B4E` |
| House exteriors | Warm Taupe | `#7A7060` |
| Deep shadows | Ink Black | `#1A1A1A` (not pure black) |
| Blood/Violence | Dark Crimson | `#8B1E1E` / `#B91C1C` |
| Lighting cast (warm pools) | Golden Amber | `#D4B896` |

### UI Accent Colors
| Element | Color | Hex |
|---|---|---|
| Health (HP) | Vermilion Red | `#D93829` |
| Stamina (ST) | Steel Blue | `#2980B9` |
| Ammo/Morale (AM) | Olive Green | `#7CB342` |
| Hunger status | Orange | `#E67E22` |
| Thirst status | Cyan | `#5DADE2` |
| Injured status | Bright Medical Red | `#EF4444` |
| Tired status | Yellow-Green | `#CA8A04` |
| UI backgrounds | Near-black blue tint | `#1A1D24` |

**Rule:** Blood/violence uses saturated crimson to POP against the muted palette. Everything else is desaturated -20%.

---

## 3. LIGHTING DIRECTION & MOOD

### Primary mood: Heavy Overcast / Foggy Late Afternoon
- **Time of day:** Late afternoon / golden hour (4:00-5:30 PM)
- **Light source:** Diffuse overhead (cloud cover) + warm directional through windows
- **Shadows:** Soft-edged, high contrast between lit areas and shadowed corners
- **Fog:** Exponential height fog, color `#8B8B7A` (matches sky), visibility 150-200m
- **Interior lights:** Single overhead point light (ceiling fixture) + window light (golden amber `#D4B896`)
- **Atmosphere:** Hazy, dusty — volumetric god rays through windows
- **Post-processing:**
  - Desaturation: -20% globally
  - Vignette: 15% darkening at edges
  - Chromatic aberration: 0.5px red/blue fringing at edges
  - Rim lighting on weapon barrel + zombie edges (separate from background)

### Interior mood: Oppressive claustrophobia
- Dark corners, warm light pools, dust motes in light beams
- Refrigerator hum, wood creaks, wind through cracked windows

### Exterior mood: Suburban decay
- Fog obscures distant houses (20-30m visibility)
- Overgrown grass cracking through asphalt
- Faded road markings
- Parked 1970s sedan at angle on grass verge

---

## 4. HUD LAYOUT

### "Status-Left, Combat-Right, Nav-Bottom" layout

```
┌─────────────────────────────────────────────────────┐
│ [STATUS]                              [WEAPON]     │
│ Hungry  ▓▓▓▓░                       RIFLE — M14    │
│ Thirsty ▓▓░░░                        12 / 30       │
│ Tired   ▓▓▓░░                        ▓▓▓▓▓░        │
│                                                     │
│                                                     │
│                                                     │
│                   ○ (crosshair)                     │
│                                                     │
│                                                     │
│                                                     │
│ [VITALS]                              [CONTEXT]     │
│ HP  ▓▓▓▓▓▓░░░░                                    │
│ ST  ▓▓▓▓▓▓▓▓░░                                    │
│ AM  ▓▓▓▓▓▓▓▓▓░                                    │
│ ┌─────────┐                                        │
│ │ MINIMAP │                                        │
│ │   ▲     │                                        │
│ │ 19:34   │                                        │
│ └─────────┘                                        │
└─────────────────────────────────────────────────────┘
```

### Element Details

| Element | Position | Size | Style |
|---|---|---|---|
| Status effects (Hungry/Thirsty/Tired) | Top-Left | 180px wide | Icon (24px) + Label (white bold 14px) + Segmented bar (120px × 8px, 5 segments) |
| Weapon info | Top-Right | 200px wide | Dark semi-transparent box, weapon name + silhouette icon + ammo count + bullet pips (6 vertical rectangles) |
| Vitals (HP/ST/AM) | Bottom-Left above minimap | 160px wide | Horizontal bars, thick black borders, colors per palette |
| Minimap | Bottom-Left corner | 170×170px | Square, semi-transparent dark bg, green-tinted top-down, red dots (zombies), white lines (walls), compass N/S/E/W, time below |
| Crosshair | Center | 40px diameter | Thin white circle with gap at top. Scales up 10% on NPC hover |
| Context icon | Bottom-Right | 60×80px | Glowing interaction prompt (appears only when interactable is in range) |

### Typography
- **Font:** Bold, slightly condensed sans-serif (Bebas Neue or Roboto Condensed Bold)
- **All caps** for labels
- **Monospace** for ammo count (Courier-style)
- **Thick black outlines (2-3px)** on all UI elements
- **Opaque backgrounds** (not transparent glass) — graphic novel panel look

### Status Bars
- **Segmented** (battery-style), not smooth gradients
- Deplete left-to-right
- **Critical (<25%):** pulse red + flash
- **Filled segments:** solid color (no gradient)

---

## 5. ICON STYLE

### Flat Vector Art
- 2D hand-drawn style illustrations
- 2px solid black strokes (no anti-aliasing on edges)
- Simple recognizable silhouettes:
  - **Hunger:** Chicken drumstick (orange)
  - **Thirst:** Water droplet (cyan)
  - **Tired:** Half-moon / sleeping face (yellow-green)
  - **Cold:** Snowflake (light blue)
  - **Injured:** Red cross / plus sign (bright red)
  - **Weapon:** White silhouette of actual gun model (not generic icon)

---

## 6. NPC APPEARANCE

### Zombies (Walkers)
- **Art style:** Cel-shaded with thick black outlines (3-4px)
- **Clothing:** Muted earth tones — dirty browns, grays, faded blues. Tattered shirts, some missing sleeves. Civilian wear (were ordinary people).
- **Skin:** Pale gray-green, sunken eyes (black dots), open mouths (dark interior)
- **Pose:**
  - Idle: Swaying, arms hanging loose or raised to chest (classic walker)
  - Attack: Hands reaching forward, grasping
- **Variation:** Mix of male/female, different heights, some leaning forward, others shambling
- **Outline:** Thick black (3-4px) to separate from grey background

### Survivors (NPCs)
- Average proportions (not heroic/stylized)
- Plain olive-green t-shirt (`#7A7A5E`), charcoal gray pants (`#4A4A4A`)
- Neutral/slightly concerned expression
- Short brown hair, light stubble
- Neutral T-pose or relaxed idle — arms at sides, feet shoulder-width

---

## 7. HORDE DENSITY

### Barricade defense scenario
| Zone | Distance | Count | Appearance |
|---|---|---|---|
| Front line | 1-2m | 3-4 | Pressed against wood, hands visible, faces detailed |
| Mid-ground | 3-8m | 8-10 | Partially obscured by each other, becoming silhouettes |
| Background | 10-30m | 10+ | Fading into fog, gray shapes moving toward player |

**Total:** 15-20 visible zombies in immediate threat zone (within 10m)
**Spacing:** Tight clustering — wall of bodies, not evenly spaced
**Emergence:** Zombies emerge from fog at draw distance limit

### Street patrol scenario
- Sparse/lone threat: 1 zombie at 25-30m
- Emphasizes isolation
- Enemies spaced far apart

---

## 8. BARRICADE CONSTRUCTION

### Style: Improvised wooden junk
- Upturned tables/desks (visible drawer handles, wood grain)
- Planks nailed at angles (some splintered)
- Doors removed from hinges
- Chair wedged in
- **Materials:** Pine, oak, plywood — all weathered, varying colors (`#6D5D4B` to `#8B4513`)
- **Haphazard, desperate construction** — not professional fortification

### Damage States
- Blood splatters (decals) on front face
- Crack lines (white/black) appearing on planks when hit
- Planks shake/jitter + wood chip particles when shot

---

## 9. ENVIRONMENTAL ATMOSPHERE

### Setting: 1950s-70s American Suburbia in Decay
- Single-story ranch houses with porches, clapboard siding, gabled roofs
- Windows with shutters (some open, some broken)
- Cracked asphalt with faded white dashed center lines
- Overgrown grass tufts cracking through road surface
- Large deciduous trees (oak/maple) with dense canopies rendered as flat green shapes
- 1970s sedan parked at angle on grass verge (faded blue/grey two-tone)
- Wooden utility poles with cross-arms and wires stretching into fog

### Interior Atmosphere
- Suburban kitchen (1950s-70s architecture)
- Tin cans scattered on floor (red/brown/green labels — looting)
- Overturned wooden chair (collision obstacle)
- Dining table with dirty dishes/cans
- White refrigerator (door slightly ajar)
- Gas stove with black grates
- Empty open cabinets (dark interiors)
- Cracked window glass (spiderweb pattern) — golden light streams in
- Slightly dirty painted drywall (no wallpaper)

---

## 10. COMIC-BOOK ELEMENTS (Critical for Mazar)

### Pop-up Text Effects
- "BANG!", "CRACK!" etc. are **0.3-second pop-ups** — 2D screen-space textures that scale up and fade out
- NOT painted into the world
- Triggered on: firing weapon, barricade hit, zombie attack

### Weapon-in-Hand Rule
- Weapons **holster** when player is not shooting
- Gun appears in viewmodel only when:
  - Aiming down sights
  - Firing
  - Reloading
  - Recently fired (3-second cooldown)

### Weapon Viewmodel
- **Position:** Bottom-right of screen, angled slightly left
- **Stock:** Wood grain brown (`#8B4513`), worn smooth
- **Receiver/Barrel:** Matte black metal (`#2D3748`) with subtle specular
- **Hands:** Visible player hands gripping weapon
- **Animations:**
  - Idle: Slight breathing motion (up/down 2px)
  - Fire: Recoil push-back (10-15 units, rotate up 5°), muzzle flash starburst, shell ejection
  - Reload: Hand leaves forend, pump animation, mechanical sound

---

## 11. WHAT NOT TO COPY FROM REFERENCE IMAGES

| Element | Why |
|---|---|
| Duplicate time display | Appears once, inside minimap frame only |
| Orange artifact bottom-right corner | Generation artifact |
| Permanent on-screen text (BANG!, CRACK!) | 0.3s pop-ups, not permanent |
| Weapon-in-hand when not shooting | Weapons holster when idle |
| Painted 3D models in reference images | They communicate mood/color, not topology. Real assets built in MoGen. |

---

## 12. IMPLEMENTATION PRIORITY

1. **Toon shader + inverted-hull outlines** — defines 70% of art style
2. **Fog color matching** (`#8B8B7A`, 150-200m visibility) — creates mood
3. **HUD layout** (Status-Left, Combat-Right, Nav-Bottom) — functional framework
4. **Color restriction** (desaturated palette + red blood pops) — unifies identity
5. **Paper grain overlay** — comic book printing feel
6. **Pop-up text effects** (BANG/CRACK) — 0.3s screen-space textures
7. **Barricade system** — improvised wooden junk with damage states
8. **Horde density** — 15-20 visible, tight clustering, emerge from fog
