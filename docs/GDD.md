# MAZAR — UNIFIED GAME DESIGN DOCUMENT

> **Version:** 2.0
> **Status:** Pre-production → vertical slice. Lore semi-locked. Path B locked. Tier 1 production: 216 active GLBs. City gen V2 (recipe-driven, road-first, block-based) with hand-crafted believable reference profiles. 9 biomes (no river, no wetlands — coastal beach retained on S+SE edge per user hand-authored map, 2026-09-21). Map dimensions locked from hand-authored top-down map: 4.6 km × 3.0 km ≈ 13.8 km².
> **Repo location:** `/home/z/my-project/docs/GDD.md` (canonical — see `STATUS.md` for what's current vs archived)
> **Working title:** *Mazar*
> **Engine:** Godot 4.7.2 (glTF 2.0 native, Compatibility renderer default for Low preset)
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot)
> **MoGen reference:** `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB)
> **Terrain plugin:** Terrain3D v1.0.2-stable (GDExtension, multi-region 4×2048m)
>
> ## Version History
>
> | Version | Date | Changes |
> |---|---|---|
> | 2.0 | 2026-09-13 | Shell split architecture: buildings separated into shell GLB (walls with holes) + interactive component GLBs (doors, windows, garage doors). 6 buildings processed. Component manifests define positions, rotations, and gameplay flags (can_open, can_lock, can_break, can_climb). mogen reinstalled (v0.1.12). Forward+ renderer. City gen v7 (data-driven map, visible roads, gap filler, interior greenery, parks). |
> | 1.9 | 2026-09-12 | Terrain3D plugin + multi-region bake, unified Y via get_height(), road flattening (B.4), bridge placement (B.5), water surface (Phase D), NavMesh hooks (Phase E), POI system with 6 landmarks (Phase F), O(1) road-facing (G.1), MultiMesh batching stub (G.2), SpatialIndex AABB (G.3), city gen pipeline fine-tune (lot-based placement, per-biome density, v3 rules applied), §4.6 World Layering Model locked (3-layer: Baked/Per-run/Delta), CityMeta terrain hash, test suite (9 tests, all PASS), frame budget (1 chunk/frame), repo restructure (docs/archive/STATUS/README), v3 extraction applied, 216 GLBs across all biomes, River 25%→12.5% + Coastal Beach, Subway-as-layer *(Note: River + Coastal Beach later REMOVED 2026-09-21 — see §10.5)* |
> | 1.8 | 2026-09-11 | Merged GDD v8 + lore v1.2 + poly_budget v3 + furniture_decision. 28 approved assets + 5 retired. Kitchen modular (4 pieces). Biome profiles wired. |
> | 1.7 | 2026-09-11 | Batch 006 (10 new assets, 28 total). |
> | 1.6 | 2026-09-11 | Kitchen counter split into 4 modular pieces. |
> | 1.5 | 2026-09-11 | Cars + blood + grass retired (external assets). |
> | 1.4 | 2026-09-11 | Furniture merging decision locked. |
> | 1.3 | 2026-09-11 | Tier 1 production started. |
> | 1.2 | 2026-09-11 | Path B locked (two-tier Low/High presets). |
> | 1.1 | 2026-09-11 | Lore locked (Republic of Mazar). |
> | 1.0 | 2026-09-10 | Initial vision draft. |

---

# PART 1: VISION & PILLARS

## 1.1 Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is the National City of Mazar — a fictional city where a 300-year monarchy ended in a quiet coup 70 years ago, where a military junta sold the nation to a foreign Border Enemy, where Operation Living Troop created a supersoldier serum that killed its subjects and raised them as the undead.

The city is fixed, persistent, hand-crafted. Every building enterable. Every run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

Travel is exploration, not optimization. The map uses draw-distance fog, non-trivial road networks, landmarks far apart. The fastest path on the GPS is rarely the safest path.

No place is safe.

## 1.2 Pillars

1. **Authored skeleton, procedural flesh.** Landmarks, roads, and POIs are hand-placed. Buildings and props fill the authored skeleton procedurally. Procedural interiors provide replayability; the exterior shell is fixed. 🧪 *(under testing — see §10.1 + §10.6)*
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters. Generators hum. Footsteps echo.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist. Find your old body, loot your old loot.
4. **Biome identity.** Each of the 9 biomes has loot focus, difficulty, vibe, weather, time-cycle identity.
5. **Travel as exploration.** Not optimization. Sea blocks south + east edges. Forest hides north. Coast is a hard boundary.
6. **All three combat modes.** Stealth, guns, melee — all viable, all situational. Shooting is the addictive hook (Valorant-feel).
7. **Civic, not sacred.** Mazar's landmarks are civic (water tower, grain silo, hospital, government palace). No religious buildings. Faith lives in the people, not the skyline.
8. **Runs on millions of PCs.** Low preset baseline: 2GB VRAM / 4GB RAM / 1080p / 60 FPS. High preset scales up.
9. **Furniture is interactive + modular.** Static fixtures merge for performance. Dynamic furniture is separate RigidBody3D. Kitchen counter is split into modular pieces (PZ-style).

---

# PART 2: LORE — THE REPUBLIC OF MAZAR

> **Status:** Semi-locked for alpha. Overall structure is locked. Specific names (streets, factions, characters, radio stations) can shift during alpha playtesting.

## 2.1 The Nation

The Republic of Mazar is a coastal nation on the edge of a forgotten sea. Its capital, the National City of Mazar, sits on a wide bay where the sea meets the eastern forest. The nation is small — you can drive across it in a day — but it was once one of the most prosperous places in the region. People came from around the world to live here, to work, to study, to find shelter. It was a nation of trade, of education, of faith, of stability. That was a long time ago.

The Mazarani people are conservative and religious. Their faith shaped their culture, their laws, and their daily rhythms. But religion in Mazar was never a spectacle — there were no grand monuments to it. It was quiet, personal, woven into the fabric of ordinary life. The nation's landmarks were civic, not sacred: the lighthouse, the water tower, the grain silo, the hospital, the government palace, the stadium, the railway station, the grand bazaar. Those were the places that defined Mazar. The faith lived in the people, not in the skyline.

**Sarran** is an old Mazarani name, preserved in the city's streets and districts:
- **Sarran Street** — the main road through Old Town
- **Sarran District** — the historic quarter, once the heart of the monarchy
- **Sarran Bridge** — main overpass connecting districts (historical name, no river)

## 2.2 The Long Peace — 300 Years of Monarchy

For nearly three hundred years, Mazar was ruled by a monarchy — the House of Mazar. The monarchy was not perfect. Wealth inequality existed. Some families held more land, more influence, more opportunity than others. But the system was stable, and it was fair enough that hard work could lift you. A farmer's son could become a merchant. A merchant's daughter could become a teacher. A teacher could become an advisor to the crown. That was the promise of the Long Peace.

The Mazarani monarchy was tolerant. It allowed dissent. It allowed faith. It allowed foreigners to settle, work, and build lives. The nation prospered. The ports were busy. The markets were full. The schools were open to anyone who could reach them. The hospitals treated the poor. The military was small — a ceremonial force, more loyal to the crown than to any foreign power.

The last monarch, **King Amir of House Mazar**, was a quiet man. He was not a warrior. He was not a tyrant. He was a caretaker. He believed the monarchy existed to serve the people, not the other way around. He was, by all accounts, a good king in an era that was already ending.

## 2.3 The Quiet Coup — 70 Years Ago

Seventy years ago, the military took power. It was not a violent coup. There were no tanks in the streets. There was no massacre. The military leadership — a group of senior officers who had grown frustrated with the monarchy's slow pace of reform — presented the king with a choice: abdicate, or face a civil war. King Amir chose abdication. He believed that a peaceful transition was better than a bloody one, even if it meant the end of his family's rule.

He left quietly. He took only what he could carry: some clothes, some documents, a few family heirlooms. He did not loot the palace. He did not empty the treasury. He did not ask his loyalists to fight. He simply left, with his wife and his children, into exile. No one knows where they went. No one knows if they are still alive.

The military took power the same day. They promised order, progress, and reform. They promised to hold elections once the nation was stable. They promised to serve Mazar, not themselves.

## 2.4 The Military Regime — 68-60 Years Ago: The Rot Begins

The first leader of the military regime was **General Karim**. He was a man of principle. He believed in order, in discipline, in the nation. He was not corrupt. He was not cruel. He was, in his own way, a patriot.

But General Karim was surrounded by men who did not share his principles. His officers — colonels, majors, captains — were ambitious. They saw the coup as an opportunity. They began taking things for themselves: land, businesses, contracts. They passed rules that benefited only them. They built a system where loyalty to the regime mattered more than loyalty to the nation.

General Karim noticed. He objected. He tried to discipline his officers, to reverse their decrees, to restore some measure of fairness. He was ignored. He was overruled. And then, two years into his rule, he was placed under house arrest by his own officers. They stripped him of his rank, his title, and his voice. He spent the rest of his life in a small house on the edge of the city, watching the nation he had tried to serve rot from the inside.

After General Karim, the regime became a revolving door of military juntas. One leader after another. Each promised reform. Each failed. Each was more corrupt than the last. The nation became a puppet — of its own military, and of foreign powers who saw Mazar as a useful asset.

## 2.5 The Border Enemy — 13 Years Ago

Thirteen years ago, the nation's northern neighbor — a larger, wealthier, more aggressive power — began secretly controlling the latest military leader. They did not invade. They did not declare war. They simply bought the man. They funded his lifestyle. They gave him orders. They used Mazar as a staging ground for their own ambitions.

The Border Enemy had one goal: to develop a weapon that would make their soldiers unstoppable. They needed a place to do it — a place far from their own borders, a place where an accident could be contained, a place where no one would ask questions. Mazar was perfect.

## 2.6 The Subway

The subway was built during the Military Regime, not during the Long Peace. The junta needed a way to move troops, materials, and secrets without being seen. The public subway — the stations, the platforms, the commuter lines — was a cover. Used for public civilian transport. Below it, in sealed maintenance tunnels and unmarked cargo rooms, the regime moved things it did not want anyone to see. After the outbreak, those secret tunnels became the most valuable real estate in the city. They are dark, tight, and full of zombies — but they also contain lore fragments, military supplies, and the truth about what happened.

## 2.7 Operation Living Troop — 10 Years Ago

Operation Living Troop was a secret military experiment. Its official name and its internal codename were the same — there was no public name, because the public was never supposed to know it existed.

The goal was simple: create a substance that would make soldiers stronger, faster, and harder to kill. The liquid was designed to boost stamina, accelerate tissue repair, and increase muscle density. It was tested on animals first. Then on prisoners. Then on volunteers.

It worked. That was the problem.

The liquid did everything it was designed to do. It made subjects stronger. It healed their wounds faster. It gave them stamina that seemed almost supernatural. But it also overloaded their nervous systems. The heart would stop. The brain would die. And then — this was the part no one expected — the body would rise.

The undead were not fast. They were not smart. They were not coordinated. But they consumed energy at a fraction of a human rate. They could go weeks without feeding. They could keep going long after a normal body would have collapsed. They were, in a terrible way, the perfect soldiers — except they could not be controlled.

The Border Enemy knew. The junta knew. The public did not.

## 2.8 The Leak — 2 Weeks Ago

The experiment ended in an explosion. The lab at Fort Sarran — a military fort on the eastern edge of the city — breached containment. The liquid leaked into the facility's drainage system. It entered the city's sewer network. It contaminated the drinking water supply. People drank it. They bathed in it. They cooked with it. They watered their crops with it.

The fog that rolled in that week was just fog. The rain that fell was just rain. But the water was poison. And the poison killed.

The first deaths were attributed to a plague. Then to a curse. Then to a foreign attack. The truth — that the military had been experimenting with a weapon that turned people into the undead — was buried under layers of propaganda and denial. The junta sealed the records. The Border Enemy cut off contact. The world moved on.

But the dead did not.

## 2.9 Day 0: The Outbreak

The city of Mazar is silent. The streets are empty. The shops are looted. The hospitals are overrun. The dead walk. They are not fast. They are not smart. But they are everywhere, and they are hungry.

Some people survived. Some were immune — their bodies simply rejected the liquid, or fought it off, or never encountered it in the first place. No one knows why. No one knows how many there are. The immune are not a faction. They are individuals — scattered, unorganized, unaware of each other. Some of them are heroes. Some of them are monsters. Most of them are just trying to stay alive.

The military has collapsed into outposts — small fortified positions held by soldiers who are no longer following orders. They are not searching people. They are not enforcing curfews. They are hiding. Some of them will help you. Some of them will rob you. Some of them will shoot you on sight. They are survivors, just like you.

The Border Enemy is still out there, somewhere beyond the northern border. They want the liquid. They want the weapon. They want to finish what they started.

The Mazar Republic — the democratic resistance — is still fighting. They broadcast from hidden radio stations. They distribute pamphlets. They argue for elections, for peace, for the restoration of civilian rule. They are outnumbered. They are outgunned. But they are not gone.

And somewhere in the city, buried in the ruins of the old royal palace, or hidden in the secret tunnels of the subway, or locked in the files of the military regime, is the truth about what happened — and maybe, just maybe, a way to fix it.

## 2.10 Factions

| Faction | Goal | Relationship |
|---|---|---|
| **Mazar Republic** | Hold real elections. Restore political peace. End military rule. | Enemy of Junta, enemy of Border Enemy |
| **Junta Remnants** | Hold power. Cover up Operation Living Troop. | Allied with Border Enemy, suspicious of Survivors |
| **Border Enemy** | Recover the liquid. Weaponize it. | Allied with Junta, enemy of Survivors and Mazar Republic |
| **Survivors** | Stay alive. Help each other. | Neutral |
| **The Immune** | Not a faction. Random individuals with natural or partial resistance. | Scattered, unorganized — **the player is one of these** |

## 2.11 Radio Voices

| Station | Faction | Broadcast Style |
|---|---|---|
| **Voice of Mazar** | Mazar Republic | Coded messages, election plans, anti-junta propaganda |
| **Radio Junta** | Junta Remnants | Curfews, false safety, martial law announcements |
| **Free Mazar FM** | Survivors | Distress calls, supply tips, safe route warnings |
| **The Border Signal** | Border Enemy | Foreign language, jamming, encrypted transmissions |

## 2.12 The City — Geography

The National City of Mazar sits on a wide bay. The sea forms the **southern + eastern** edges of the map (hard boundaries — player cannot walk on water). The northern edge is dense forest. The western edge opens to farmland + suburbs.

**Map layout (per hand-authored top-down map, 2026-09-21):**

```
            N (forest edge — dense trees, hunting cabins, logging camps)
            ↑
   ┌─────────────────────────────────────────────────────────────────┐
   │                                                                 │
W  │  Suburbia       Parks &       Farmland      Industrial Park    │  E
   │  (power         Greenways    (grain silo,  (power plant,       │
   │  substation)    (old royal   fields)        water tower,       │
   │                 palace)                     railway station)  │
   │                                                                 │
   │  ─────────  Main Highway (East-West)  ─────────                │
   │                                                                 │
   │              Commercial Strip  ──→  Downtown                  │
   │              (Grand Bazaar,         (Hospital, Police HQ,      │
   │               Broadcast Tower)       Govt Palace, Fire          │
   │                                    Station, Stadium)          │
   │                                                                 │
   │                       Coastal Beach                            │
   │                       (Lighthouse, Harbor,                    │
   │                        Pier)                                  │
   │                                                                 │
   │                                            Fort Sarran         │
   │                                            (peninsula,         │
   │                                             bridge access)     │
   └─────────────────────────────────────────────────────────────────┘
            ↓
            S (SEA — hard boundary, beach + lighthouse)
```

**Districts (West → East, top to bottom):**

- **Suburbia** — far west, residential grid, power substation, subway entrance
- **Parks & Greenways** — west-central, organic green, Old Royal Palace
- **Farmland** — central-north, fields, Grain Silo, irrigation
- **Industrial Park** — northeast corner, power plant, water tower, railway
- **Forest** — entire northern edge (above all districts), logging camps + hunting cabins
- **Commercial Strip** — diagonal band SW→NE, Grand Bazaar + Broadcast Tower
- **Downtown** — east-central urban core, Hospital + Police HQ + Government Palace + Fire Station + Stadium
- **Coastal Beach** — south + southeast edge, Lighthouse + Harbor + Pier
- **Military Zone / Fort Sarran** — eastern peninsula, bridge access only, endgame raid

**Underground:**
- **Subway** — public transit + secret military transport tunnels (entries in Suburbia, Parks, Downtown)

**Sea access (hard boundaries):**
- South edge: beach + lighthouse (Coastal Beach biome)
- East edge: bay + Fort Sarran peninsula (Military Zone + Coastal overlap)

## 2.13 The 9 Biomes

> **UPDATED 2026-09-21.** Coastal Beach added back (per hand-authored top-down map). Removed River + Wetlands (no river — different concept from coast). Subway moved out of biome list (kept as underground layer). 9 surface biomes total.

| # | Biome | Lore Role | Loot Focus | Difficulty | Zombie Density | Weather | POIs | Base Potential |
|---|---|---|---|---|---|---|---|---|
| **1** | Suburbia | Middle-class homes from the Long Peace. Now empty. | Food, clothes, tools, batteries, basic meds, family cars | Low | Low–Medium | Mild autumn, overcast, light rain | Houses, school, corner store, gas station, cul-de-sacs, power substation | **High** — starter base |
| **2** | Commercial Strip | Once-bustling bazaars and shops. Now looted. | Meds, food, fuel, weapons, electronics, clothing | Medium–High | Medium–High | Overcast, rain, blackouts | Diner, motel, pharmacy, supermarket, gun store, bazaar, broadcast tower | Medium |
| **3** | Industrial Park | Manufacturing and rail. Outposts here. | Metal, tools, generators, fuel, chemicals | Medium | Medium | Industrial smog, acid rain, cold drizzle | Warehouses, factories, rail depot, water tower, power plant, outposts | **High** |
| **4** | Farmland | Mazar's food basket. Olive groves, wheat, irrigation canals. | Crops, seeds, canned goods, fuel, animals | Low–Medium | Low | Heat waves, dust, thunderstorms | Farms, orchards, barns, grain silos, windmill | **High** |
| **5** | Forest | Border region. Enemy infiltration routes. Hidden bunkers. | Wood, herbs, hunting gear, camp supplies | Medium | Low | Fog, cold rain, early dusk | Ranger station, hunting cabins, campsite, cave, logging camp | Medium–High |
| **6** | Parks & Greenways | Old public gardens, walking trails, playgrounds. | Water, snacks, gardening tools, seeds, meds | Low | Low | Sunny, breezy, morning mist | Playground, botanical garden, picnic area, pond, trailhead, old royal palace | Low–Medium |
| **7** | Coastal Beach | Southern shoreline. Lighthouse, fishing. Once-busy tourist + fisher area. | Fish, clean water, boat fuel, herbs, fishing gear, driftwood | Medium | Low–Medium | Sea mist, heavy rain, flooding, fog | Lighthouse, harbor office, fishing huts, pier, houseboats | Low–Medium |
| **8** | Downtown | Capital district. Hospital, police HQ, government buildings. | Best meds, guns, ammo, armor, electronics, intel | High–Very High | Very High | Neon night, rain, smog, blackouts | Hospital, police HQ, government palace, stadium, fire station | **Low** — death trap |
| **9** | Military Zone / Quarantine | Fort Sarran — ground zero. Operation Living Troop lab. | Military gear, MREs, hazmat suits, radios, advanced meds, weapons | Extreme | Extreme | Toxic fog, ashfall, cold wind, unnatural silence | Military fort (peninsula), field hospital, hazmat tents, convoy wrecks, bunker entrance | None — endgame raid only |

**Subway (underground layer):** Public transit + secret military transport tunnels. Electronics, non-perishable food, batteries, rare lore. Medium–High difficulty, clustered zombies. Stations, platforms, maintenance tunnels, secret cargo rooms. Low–Medium base potential.

**Military Zone placement:** eastern peninsula (Fort Sarran juts into the bay). Connected to mainland by a single bridge — chokepoint + gated access. One road in, one road out. High risk/reward side exploration.

## 2.14 Civic Landmarks

No religious buildings. The nation's landmarks are civic:

1. The Lighthouse (Coastal Beach — southwestern point)
2. The Harbor Office (Coastal Beach — south pier)
3. The Water Tower (Industrial Park)
4. The Grain Silo (Farmland)
5. The Hospital (Downtown)
6. The Police HQ (Downtown)
7. The Government Palace — now junta HQ (Downtown)
8. The Fire Station (Downtown)
9. The Stadium (Downtown — southeastern edge, near coast)
10. The Old Royal Palace — abandoned, sealed (Parks & Greenways)
11. The Fort — Fort Sarran (Military Zone — eastern peninsula)
12. The Broadcast Tower (Commercial Strip)
13. The Railway Station (Industrial Park)
14. The Grand Bazaar / Souq (Commercial Strip)
15. Suburbia Power Substation (Suburbia)
16. Industrial Power Plant (Industrial Park — NE corner)

## 2.15 Zombies

| Type | Behavior |
|---|---|
| **Walker** | Slow shamble. Sight cone, hearing radius, short memory (~10 sec). The default. |
| **Crawlers** | Legs destroyed. Slow, quiet, easy to miss. Bite from the ground. |
| **Groups** | Noise pulls nearby zombies. Hordes form slowly. No coordination. |
| **Memory** | ~10 seconds. Investigate, then forget. |

**Lore justification:** the Living Troop liquid overloaded nervous systems — hearts stopped, brains died, bodies rose. The undead consume energy at a fraction of human rate, can go weeks without feeding. They are not fast, not smart, not coordinated. They are relentless.

## 2.16 Naming Conventions

**Streets:**
- King's Way, Coup Avenue, Martyrs' Road, Unity Boulevard, Harbor Street, Olive Lane, Bunker Road, Sarran Street

**Districts:**
- Al-Salam (Peace), Al-Nour (Light), Old Town, New Town, New Mazar, Fort Quarter, Sarran District

**Radio:**
- Voice of Mazar, Radio Junta, Free Mazar FM, The Border Signal

**Key figures:**
- King Amir of House Mazar (last monarch, exiled, fate unknown)
- General Karim (first junta leader, principled, died under house arrest)

**Key locations:**
- Fort Sarran (the lab, outbreak origin, Military Zone)
- Sarran Bridge (main overpass — historical name, no river)
- The Old Royal Palace (abandoned, sealed — lore fragment location)

## 2.17 Timeline

- **300 years ago → 70 years ago:** The Long Peace. House of Mazar monarchy. Tolerant, stable, prosperous.
- **70 years ago:** The Quiet Coup. King Amir abdicated to avoid civil war. Military took power.
- **68-60 years ago:** General Karim's principled regime, then rot. He was placed under house arrest by his own officers.
- **13 years ago:** The Border Enemy (northern neighbor) bought the latest junta leader. Mazar became a staging ground.
- **10 years ago:** Operation Living Troop began. Secret military experiment to create supersoldiers. The liquid worked — but it killed subjects and raised them as undead.
- **2 weeks ago:** The lab at Fort Sarran exploded. Liquid leaked into drainage, sewer, drinking water. The fog rolled in. The rain fell. The water was poison.
- **Day 0 = now:** The city is silent. The dead walk. The immune (including the player) are alive for reasons no one understands.

## 2.18 Lore Fragments

Scattered across biomes and the Subway. Persistent across runs. They reveal:
- The truth about Operation Living Troop
- The Border Enemy's involvement
- The junta's cover-up
- The fate of the last monarch (King Amir)
- The identity of the immune
- The location of the lab (Fort Sarran)
- The secret Subway transport routes

---

# PART 3: GAMEPLAY SYSTEMS

## 3.1 Survival Needs 🔓

Likely subset of PZ's: hunger, thirst, fatigue, panic, sickness, infection. To spec in detail.

## 3.2 Combat — STEALTH + GUNS + MELEE 🔒

**Locked.** All three combat modes viable. Situational.

### Shooting = the addictive hook (Valorant-feel):
- Tight, responsive, low-TTK
- Headshots matter (zombie headshot = instant kill)
- Recoil patterns (learnable, like Valorant spray patterns)
- Movement penalty while aiming
- Audio feedback (each gun has a distinct sound profile — also gameplay-relevant via hearing AI)

### Stealth — primary survival tool:
- Crouch walk = silent
- Standing walk = audible at 5m
- Running = audible at 20m
- Distract with thrown objects (rocks, bottles)
- Backstab = instant kill on lone zombie
- Line-of-sight breaks = zombie loses you (after investigation)

### Melee — last resort / silent takedown / door defense:
- Stab weapons (knife, screwdriver) = silent, low durability, low range
- Blunt weapons (bat, pipe, hammer) = audible at 5m, medium durability
- Heavy weapons (axe, sledgehammer) = audible at 10m, high durability, slow
- Door barricade breaking = melee combat meta (defend the door)

## 3.3 Hearing-based Zombie AI 🔒

3D sound propagation, occlusion, noise events. Zombies investigate:
- Gunshots (loud, far carry — 50m+)
- Footsteps (medium, surface-dependent — 5-20m)
- Alarms (loud, sustained)
- Generators (sustained hum — 30m)
- Broken glass (sharp, short — 15m)
- Door barricades being broken (medium, sustained)
- Vehicle engines (loud, mobile source)

## 3.4 Death Penalty + Meta-progression 🔒

**Roguelite.** Story mode: keep equipped weapons. Lose consumables and materials. Spend resources on permanent upgrades.

**Sandbox mode:** lose everything. Spawn as a new character. Can find your old body with old loot.

**Meta-progression upgrades:**

| Upgrade | Per-level bonus | Max levels |
|---|---|---|
| Movement Speed | +5% | 5 |
| Max Health | +10 HP | 5 |
| Carrying Capacity | +2 slots | 5 |
| Flashlight Battery | +15% duration | 5 |
| Stamina / Noise Reduction | -10% footstep noise | 5 |

Resources to spend: scrap, blood, electronics.

## 3.5 Radio Rumor System 🔒

One run modifier per run. Overrides a specific biome's rules. Sources: the 4 locked radio stations (Voice of Mazar, Radio Junta, Free Mazar FM, The Border Signal).

Example: "Quarantine lifted in Industrial Park — zombie density doubled, rare loot doubled." One per run. Huge replay value for low dev cost.

## 3.6 Lore Fragments + Persistent Keys 🔒

Story items persistent across runs. Unlock new areas, endings, base rooms. Long-term goals.

## 3.7 Base / Safehouse Hub 🔒

Apartment → Base progression. Storage, crafting, medical, radio, specialist ammo station.

**No place is safe.** Bases can be overrun. Player must defend or relocate.

## 3.8 Dynamic Spawns + Permanent Kills 🔒

Killed zombies stay dead (alpha). Cleared areas become safer.

## 3.9 Co-op (optional, future) 🔓

Alpha: just make it technically possible (no actual co-op gameplay).
Future: revive downed players, hold-the-gate / vehicle extraction mechanics.

## 3.10 Loot Tables 🔒

Per-district fixed loot table. Within the table, rarity is random:
- Common — 60%
- Uncommon — 30%
- Rare — 10%

### All 9 biome tables:

| District | Common (60%) | Uncommon (30%) | Rare (10%) |
|---|---|---|---|
| Hospital (Downtown) | Bandage, Bottled Water | Medkit, Syringe | Stimulant (temp speed boost) |
| Police HQ (Downtown) | Pistol Ammo | Shotgun Ammo | Tier 2 Armor |
| Industrial Park | Scrap Metal, Canned Food | Noise Grenade Parts | Rare Crafting Component |
| Subway | Flashlight Battery, Clean Water | Electronics | Lore Fragment (story item) |
| Coastal Beach | Fish, Driftwood | Boat Fuel | Hermetic Container (rare storage) |
| Suburbia | Canned Food, Batteries | Household Tools | Car Keys (random vehicle) |
| Parks & Greenways | Snacks, Water | Seeds | Fishing Rod |
| Forest | Wood, Herbs | Hunting Gear | Animal Trap |
| Farmland | Crops, Eggs | Fuel Canister | Tractor Parts |
| Commercial Strip | Cash, Snacks | Electronics | Weapon Magazine |
| Military Zone | MRE, Battery | Hazmat Suit | Military Keycard |

---

# PART 4: WORLD STRUCTURE

## 4.1 Map Dimensions 🔒

> **LOCKED 2026-09-14, UPDATED 2026-09-21.** Map area is fixed at 12 km² for v1. Dimensions Y×Y are a placeholder — exact width × depth (4×3 vs 3×4 vs 6×2 vs square ~3.46×3.46) will be decided when district placement is locked.

**12 km² of playable area** (locked for v1).

- Reference: GTA San Andreas ≈ 30 km² (we're ~40% of that)
- Los Santos + Red County + Flint County ≈ 42% of GTA SA ≈ 12.7 km²
- Rounded to 12 km²

**Grid:** Placeholder — current working assumption is 8 × 6 cells of 500m × 500m (48 cells, 12 km²). May change to a more square aspect (e.g. 7 × 7 = 12.25 km²) when district placement is finalized. Y×Y = TBD.

**Player traversal times** (corner-to-corner, ~5 km diagonal):
- Walking (5 km/h): ~60 min (too long — hence vehicles)
- Sprinting (8 km/h): ~37 min
- Bicycle (20 km/h): ~15 min
- Car at 60 km/h: ~5 min
- Car at 120 km/h on highway: ~2.5 min

## 4.2 Map Design Principles 🔒

1. **Draw distance fog** — lore-justified (fog rolled in after the leak). Hides streaming.
2. **Non-trivial road network** — highways connect regions but require merges, turns, detours. No trivial ring road.
3. **GPS not always fastest** — GPS picks a "safe" path; player knows faster dangerous routes.
4. **Landmarks far apart** — placed in opposite corners to sell scale.
5. **Every town has a reason to stop** — no filler towns.
6. **Unique color/weather/time per biome** — each biome has its own identity.
7. **Free-roam interiors** — every building enterable.
8. **Technical limits as creative constraints** — fog, draw distance, streaming budget all become gameplay.
9. **Travel = exploration, not optimization.**

## 4.3 Persistent Map + Per-run Reset 🔒

- **Persistent (carries across runs):** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

## 4.4 Procedural Interiors 🧪

> **Status: under testing.** The hybrid split below is the design intent. The runtime `chunk_streamer.gd` generator that exists today is a **TESTING SCAFFOLD for validating the asset pipeline** — it is not the shipping map. The shipping map is hand-authored (see §4.7). Interior furniture/loot/zombies remain procedural per-run.

- **Fixed (when shipping):** building exterior shell, room layout (walls), doors, windows, structural props (kitchen counters, bathroom fixtures, built-in shelving), **lot composition** (which buildings sit on a lot, their relative offsets, sidewalks, driveways).
- **Procedural:** small furniture placement (chairs, tables, lamps, decoration props), loot container positions, prop scatter (books, debris, blood decals), zombie patrol routes.
- **Modular kitchen:** assembled from 4 modular pieces (sink_unit, stove_unit, empty_counter, wall_cabinet) placed side-by-side. Layout is procedural — different kitchens have different arrangements.
- **Current implementation gap:** the runtime generator places buildings at parcel fronts but has **no Lot concept** that owns companion structures (garage, shed) + sidewalk + driveway as a unit. Result: garages scatter at random positions with random rotation, paths don't connect to road sidewalks. Fix is the **Lot System** (§4.7 Phase B.6) — hand-authored Lot recipes that stamp at parcel positions, mirroring how `district_templates.gd` stamps at chunk anchors.

## 4.7 Authoring Approach 🔒

> **Locked 2026-09-14.** Clarifies Pillar 1 in concrete terms so future chat sessions don't misread the project as "infinite streaming procedural".

### 4.7.1 The map is FIXED, not streaming

The National City of Mazar is a **fixed 4 km × 3 km hand-authored map**. It is NOT a streaming/infinite world. Pillar 1 ("authored skeleton, procedural flesh") means:

- **Skeleton (hand-authored, fixed):** roads, landmarks, POIs, building exteriors, **lot compositions** (which buildings sit together on one lot, their relative offsets, the sidewalk + driveway that connects them to the road).
- **Flesh (procedural, per-run):** interior furniture placement, loot contents, zombie spawns, locked door states, ambient scatter (blood, debris).

### 4.7.2 What the runtime generator is for

`tools/chunk_streamer.gd` currently generates the map procedurally at runtime. **This is a testing scaffold**, not the shipping map. Its purpose is to:

1. Validate the asset pipeline (does every GLB in `city_manifest.json` load + place + collide correctly?)
2. Validate biome profiles + district templates + parcel layout math
3. Give the player something to walk around in while interiors + gameplay are built

When the asset pipeline is stable and the **Lot System** (§4.7.3) is implemented, the runtime generator is **frozen** and the canonical map is baked to `.tscn` files via `tools/city_builder.gd` + `tools/terrain_baker.gd`. The runtime generator stays in the repo as a debug tool / regen path, but the shipping build loads baked scenes.

### 4.7.3 The Lot System

A **Lot** is the smallest authored unit of the map. Each Lot owns:

1. **1 primary building** (house / store / warehouse / etc.)
2. **0..N companion structures** with relative offsets to the primary — e.g. `{asset: "garage_detached", offset: [8, 0, 3], rot_y: 0, face_primary: true}`. Companions always sit at a fixed offset from their primary and face the same direction (or a fixed relative angle).
3. **1 sidewalk polyline** from road-edge to building front door (1.5m wide grey strip)
4. **1 driveway polyline** from road-edge to garage door (3m wide darker strip) — only if a garage companion exists
5. **A setback** = distance from road to building front (varies per zoning: 0m commercial, 4m residential, 8m suburban)

Hand-authored **Lot recipes** live in `tools/lot.gd`. Recipes stamp at parcel positions via a `LotStamper` (mirroring how `DistrictStamper` stamps district templates at chunk anchors). This is the same architecture pattern as district templates, scaled down one level: templates = block scale, lots = parcel scale.

### 4.7.4 The shipping map is PERSISTENT (baked), not runtime-generated

The National City of Mazar ships as a **persistent map** — a fixed, hand-curated arrangement of roads, landmarks, building exteriors, lot compositions, sidewalks, and driveways. It is **NOT** regenerated on each playthrough. The runtime procedural generator in `tools/chunk_streamer.gd` exists to **validate the asset pipeline + recipe math during development**; it is not what the player sees in the shipping build.

**The persistent map is produced in two phases:**

1. **Design-time (offline):** The runtime generator + `LotStamper` + `DistrictStamper` produce a candidate layout. A constraint validator (§4.7.5) ensures every placement respects road distance, path conflicts, setback range, and neighbor compatibility. The validated layout is **baked** to `.tscn` chunk files via `tools/map_baker.gd` (Phase B.8). The baked chunks are the shipping map.

2. **Runtime (player-facing):** The game loads the baked `.tscn` chunks directly. No procedural generation of exteriors. Interiors (furniture, loot, zombies) are generated per-run from `(map_seed + run_seed)` as the "procedural flesh" layer — this is the only procedural layer the player sees.

**Why this approach (and not alternatives):**

| Alternative | Why not |
|---|---|
| Hand-author the entire 12 km² as one `.tscn` in the Godot editor | One of the largest Godot scenes ever built; any asset re-export breaks it; months of manual placement for no validation payoff over the baker. |
| Pure runtime procedural (no baker) | Rejects the user's stated goal of a persistent map. Player would see a different layout each playthrough, breaking Pillar 1 ("authored skeleton"). |
| L-system road generation (Parish & Müller 2001) | Overkill — we have hand-authored roads (34 segments in `map_data.json`). The L-system is for generating road networks from scratch. We need placement validation, not road generation. |

**The right scope for hand-authoring is recipes** (district templates + lot recipes), validated by a constraint pass, then baked. Recipes are small, testable, and stamp deterministically — they get the curatorial intent of hand-authored + the validation benefit of procedural. The baker freezes the recipe-driven output into the persistent map.

### 4.7.5 The Constraint Validator

The Lot System (§4.7.3) provides the **propose** half: Lot recipes propose primary + companion + sidewalk + driveway placements. The Constraint Validator provides the **validate** half — the `localConstraints` function that every procedural-city algorithm converges on.

**Architecture (propose → validate → commit):**

```
LotStamper.stamp_lot()
  ├── propose: primary building at parcel.building_pos
  ├── validate: PlacementValidator.validate(pos, asset, biome)
  │     ├── is_on_path(pos, margin=2m)?        → reject or nudge
  │     ├── nearest_road_distance(pos)         → reject if outside [min, max] setback
  │     ├── is_on_road(pos)?                   → reject
  │     ├── neighbor_compatibility(pos, asset) → reject if incompatible
  │     └── return {ok: bool, nudge: Vector3?}
  ├── if ok:     stamp + insert into spatial index
  ├── if nudge:  retry at pos + nudge (max 3 retries)
  └── if reject: skip this lot, fall through to procedural fallback
```

**Penalty scoring:**

| Condition | Penalty |
|---|---|
| Position is on a path | -100 (hard reject) |
| Position is on a road | -100 (hard reject) |
| Position is inside a POI exclusion zone | -100 (hard reject) |
| Nearest road distance < biome.min_setback | -50 (reject for this asset type) |
| Nearest road distance > biome.max_setback | -30 (reject for primary, allow for backyard) |
| Asset is incompatible with nearest neighbor | -40 |
| Asset repeats >5 times in this chunk | -20 |
| Position is within 2m of another asset | -100 (hard reject, overlap) |

**Visual contract:**
- No prop, tree, or companion lands on a path
- Every building sits at a consistent setback from its nearest road
- Every house has a sidewalk that reaches the actual road
- Every garage has a driveway that reaches the actual road
- Incompatible assets don't cluster
- Asset repetition is capped

### 4.7.6 The Persistent Map Baker

After baking, the middleware moves to the BAKE STEP, not runtime. `map_baker.gd` runs the full pipeline: gen → validate → middleware multi-pass → bake. The runtime game loads baked chunks and does NOT run middleware. `chunk_states_auto.json` + `fill_plan.json` become bake-time artifacts, removed from the runtime path.

**Bake version stamp:** Same pattern as `CityMeta`. Hash of generator file contents + manifest hash + seed. Stored in `baked_chunks/meta.json`. On load, compare. If mismatch, warn + force re-bake.

## 4.5 Alpha Build Order 🔒

1. Suburbia → 2. Commercial Strip → 3. Parks & Greenways → 4. Farmland → 5. Forest → 6. Industrial Park → 7. Downtown → 8. Military Zone.

**Logic:** safe rural → risky commercial → industrial → urban endgame → military endgame. (Subway is parallel content, not in the build order — it's an underground layer accessible from any district.)

## 4.6 World Layering Model 🔒

> **Locked 2026-09-12.** This is the architectural backbone for chunk loading, save/load, and prebuilt vs runtime generation.

The world is composed of three layers, each with a different lifecycle:

### Layer 1 — Baked (permanent)
Terrain mesh, roads, building shells, static furniture (kitchen counters, sinks, built-ins), foliage, landmarks, POIs. Generated once by the offline builder (`city_builder.gd` + `terrain_baker.gd`). Saved as `.tscn` (or a custom binary format later). Never changes at runtime.

- **Source of truth:** `map_seed` + `city_config.gd` + `terrain_height.gd` + `pois.json`
- **When generated:** At design time (offline) or at "New Game" start
- **Where stored:** `res://chunks/chunk_X_Y.tscn` (prebuilt) or regenerated at game start
- **Invalidated when:** `TERRAIN_HEIGHT_VERSION` bumps, manifest changes, or `city_config.gd` changes (tracked by `CityMeta`)

### Layer 2 — Generated per run
Loot contents, zombie spawns, locked door states, radio rumor modifier, ambient props (blood decals, debris, scattered furniture). Deterministic from `(map_seed + run_seed)`. Rebuilds every new game; identical within a single run.

- **Source of truth:** `map_seed` + `run_seed` (per-save RNG)
- **When generated:** At game start, applied as overlay on Layer 1 chunks when they load
- **Where stored:** In-memory only (regenerated from seed on load)
- **Invalidated when:** New game (new run_seed)

### Layer 3 — Delta (modified during play)
Opened doors, dead zombies, moved furniture, looted containers, barricades, base upgrades, story keys collected. Saved as a delta file per session. Applied on top of Layer 1 + Layer 2 when a chunk loads.

- **Source of truth:** Player actions during the current run
- **When generated:** Continuously during play
- **Where stored:** `user://save_<run_id>/chunk_X_Y.delta.json`
- **Invalidated when:** Death (meta-progression resources extracted, delta discarded)

### Load order when a chunk enters stream radius:
1. Load Layer 1 `.tscn` (or build from seed if not prebuilt)
2. Apply Layer 2 overlay (deterministic from run_seed)
3. Apply Layer 3 delta (from save file, if exists)
4. Add to scene tree

### Why this matters
This layering answers the prebuilt vs runtime question definitively:
- Layer 1 = prebuilt (compute once, save as .tscn)
- Layer 2 = generated at game start (fast, deterministic, in-memory)
- Layer 3 = loaded from save (small delta, fast to apply)

The current runtime-only `chunk_streamer.gd` is a prototype that conflates Layer 1 + Layer 2. The final architecture separates them.

---

# PART 5: VISUAL STYLE & CAMERA

## 5.1 Visual Style — STYLIZED LOW-POLY + PBR-LITE (MoGen-native) 🔒

**Locked.** Stylized low-poly geometry with PBR materials. Albedo LLM-drawn via Gemini 2.5 Flash Image; normal/roughness/AO locally-derived (Sobel-from-luminance, variance, cavity). Not pixel art. Not gritty realism. Same neighbourhood as *Night of the Dead* or the cleaner scenes from *The Long Dark*.

## 5.2 Comic-book / Outline Post-processing 🔓

Godot-side decision. Three options:
1. **Inverted hull outline** — duplicate mesh, scale 1.03×, render back-faces solid black. ~1 day. *Wind Waker* look. **Recommended.**
2. **Screen-space Sobel** — post-process shader, edge-detect depth + normal. ~3 days. *Borderlands* look.
3. **Full cel-shading** — banded lighting + hard shadows. ~1 week. Throws away PBR textures.

**Plan:** implement option 1 when we lock the palette.

## 5.3 Texture Workflow 🔓 PAUSED

`mogen textures` requires paid Gemini API key (free tier = 0 image quota). Paused for alpha — flat-color materials are acceptable. Textures become v1 polish step.

## 5.4 Vehicles + Blood Decals + Grass Tufts = EXTERNAL ASSETS 🔒

Cars (sedan, pickup_truck), blood splatter decals, and grass tufts are retired from MoGen production. External assets are better quality for these.

## 5.5 Camera — FIRST-PERSON 🔒

- Player eye height: 1.65 m
- Standard door: 0.90 m wide × 2.10 m tall
- Standard ceiling: 2.40 m
- Assets must hold up at 0.5 m viewing distance
- Vertically interesting level design (look up at skyscrapers, down into basements)
- LODs matter — kitchens with 30k+ tris of props in view (on High preset)

## 5.6 Characters — DSL HUMANOID FOR ALPHA 🔒

DSL-authored humanoid via `humanoid.mog`. Blocky, Roblox-adjacent, accepted for alpha. Hybrid (external base + MoGen clothing) for v1.

**Lore justification:** player is one of "The Immune" — body rejected the Living Troop liquid.

---

# PART 6: POLY BUDGET — PATH B (TWO-TIER PRESETS)

## 6.1 Engine-level Budgets (per frame) 🔒

| Metric | Low (alpha default) | High | Ultra (v1) |
|---|---|---|---|
| Resolution | 1080p (720p internal on Intel iGPU) | 1080p native | 1440p |
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

## 6.2 Per-asset Triangle Budgets (Low preset LOD0) 🔒

| Asset type | Low LOD0 | Low LOD1 | Low LOD2 | Low LOD3 |
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

## 6.3 Texture Memory Budget (Low preset) 🔒

| Texture type | Low preset size | VRAM |
|---|---|---|
| Hero albedo (held weapon, hero building) | 512² | 256 KB |
| Standard albedo | 256² | 64 KB |
| Background albedo | 128² | 16 KB |
| Atlas (foliage, road, fence) | 1024² | 1 MB |
| UI sprites | 256² | 64 KB |
| Blob shadow | 64² | 4 KB |

**Atlas strategy:** one 1024² atlas per biome = 16 sub-textures. Reused across hundreds of props.

## 6.4 Per-biome Scene Budgets (Low preset, worst case) 🔒

Worst-case tris on screen at once, with v3 Low budgets + 30 zombie cap:

| Biome | Buildings | Props | Foliage | Zombies (max 30) | Total |
|---|---|---|---|---|---|
| Suburbia (5 houses) | 5×2.5k=12.5k | 5×1.5k interior=7.5k | 50 bushes + 20 trees=18k | 10×3k=30k | **68k** ✅ |
| Parks & Greenways | 0 | 1k | 100 trees + 300 bushes (multimesh)=10k | 5×3k=15k | **26k** ✅ |
| Forest (dense) | 0 | 0 | 200 trees (50 visible + 150 billboard) + 400 bushes multimesh=70k | 5×3k=15k | **85k** ✅ |
| Farmland | 2×2.5k=5k | 2k | 30 trees + 100 bushes=25k | 3×3k=9k | **41k** ✅ |
| Commercial Strip | 8 shops×1k=8k | 50 props×250=12.5k | 5 trees=3k | 10×3k=30k | **53.5k** ✅ |
| Industrial Park | 4 warehouses×3k=12k | 30 props=6k | 0 | 8×3k=24k | **42k** ✅ |
| Subway (tunnel view) | 0 | 15 props×250=3.75k | 0 | 8×3k=24k | **27.75k** ✅ |
| Downtown | 10 BG×500=5k + 2 hero×8k=16k → 21k | 25 props=6.25k | 3 trees=1.5k | 15×3k=45k | **73.75k** ✅ |
| Military Zone | 6 structures×2k=12k | 15 props=3.75k | 0 | 15×3k=45k | **60.75k** ✅ |

**All under 500k.** Largest scene is Downtown at 74k — well under budget.

## 6.5 Zombie Dynamic Count System 🔒

Zombies scale based on hardware + FPS.

| Preset | Max on-screen | Max active AI | Tick rate (close/mid/far) |
|---|---|---|---|
| Low | 30 | 30 | 60 Hz / 12 Hz / last-known-position steering |
| High | 60 | 60 | 60 Hz / 20 Hz / 4 Hz pathfinding |
| Ultra | 100 | 100 | 60 Hz / 30 Hz / 8 Hz pathfinding |

**Adaptive:** if FPS drops below 50 for 2 sec, reduce max zombies by 5 (floor 10). If FPS above 65 for 5 sec, increase by 5 (up to preset ceiling).

## 6.6 Adaptive Systems (improvements on Gemini's profile) 🔒

1. **Adaptive zombie spawning** — auto-scale count based on FPS
2. **Adaptive texture streaming** via Godot's `texture_streaming_budget`
3. **Adaptive LOD bias** — auto-adjust 0.7-1.5 based on FPS
4. **Adaptive resolution auto-scale** — 1080p→972p→864p→720p if FPS drops
5. **Particle quality tiers** — low/med/high

## 6.7 LOD Strategy (mandatory for alpha) 🔒

Every asset that can be seen at >10m distance MUST have an LOD chain.

| Asset type | LOD0 → LOD1 swap | LOD1 → LOD2 swap | LOD2 → LOD3 swap |
|---|---|---|---|
| Buildings | 10 m | 30 m | 80 m |
| Trees | 10 m | 25 m | 60 m → billboard |
| Vehicles | 15 m | 40 m | 100 m |
| Characters | 12 m | 30 m | 80 m |
| Props (interior) | n/a (always LOD0 — player is inside) | | |

**Godot implementation:** author LOD0, let Godot auto-generate LOD1-3 at import time.

## 6.8 Draw Call Budget Strategy 🔒

1. **Merge static meshes** — `MeshLibrary` + `GridMap` for repeated props
2. **Instanced rendering** — `MultiMeshInstance3D` for foliage (one draw call for 10 000 instances)
3. **Merge building interiors** — combine all furniture in a room into one merged mesh (per the furniture merging decision in Part 7)
4. **Atlas textures** — pack all prop textures into a single 4K atlas
5. **Cull aggressively** — Godot's `OccluderInstance3D` for buildings

## 6.9 Lighting Budget 🔒

| Light type | Count | Shadow? | Cost |
|---|---|---|---|
| Sun (directional) | 1 | Yes (1024² hard on Low) | Fixed cost — always on |
| Sky light (fill) | 1 (env) | No | Cheap |
| Street lamps (point) | up to 4 visible | Yes on High+ (player needs to see pools of light) | 4 × 6 = 24 cost units (High only) |
| Interior lights (point/spot) | up to 8 in interiors | Yes on High+ (gameplay — light = safety) | 8 × 6 = 48 cost units (High only) |
| Muzzle flash (spot, transient) | 1 per shot | No | Brief, ignorable |
| Flashlight (spot, attached to camera) | 1 | Yes | Always on when active |
| Fire/glow effects (point) | up to 4 | No | Decoration |

## 6.10 Streaming Budget 🔒

For a 4 km × 3 km open world, we need streaming.

- Use `ResourceLoader.load_threaded_request` for async chunk loading
- Chunk size: 250m × 250m (16 chunks per 1km², 192 chunks total for our 12km² map)
- Each chunk = ~50 MB on disk (buildings + interiors + foliage + terrain)
- Keep 9 chunks in memory at once (player + 8 neighbors) = ~450 MB RAM
- Fog at ~60-100m hides chunk pop-in

## 6.11 CPU-side Budget 🔒

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

# PART 7: FURNITURE MERGING DECISION

## 7.1 The Conflict

Two competing goals:

| Goal | Implementation | Cost |
|---|---|---|
| **Performance** (60 FPS on 2GB VRAM) | Merge all furniture in a room into 1 mesh → 1 draw call per room | Can't move/destroy individual pieces |
| **PZ-style interactivity** (push bookshelf to block door, scrap chair for wood, loot fridge) | Keep each furniture piece as a separate mesh + collision body | 30 draw calls per room, 5 rooms visible = 150 draw calls (25% of Low budget) |

## 7.2 The Hybrid Solution 🔒

**Split furniture into 2 categories:**

### Static furniture (merged into 1 mesh per room):
- **Kitchen counter** (built-in, attached to wall) — but modular (see §7.3)
- **Bathroom sink + toilet + bathtub** (plumbed in, never moves)
- **Built-in shelving** (wall-mounted, fixed)
- **Staircase** (structural)
- **Fireplace** (structural)
- **Window frames + door frames** (structural)

These merge with the room shell into one mesh. **0 extra draw calls** (already part of the room mesh). Can never be moved or destroyed. Players accept this — you can't move a kitchen counter in real life either.

### Dynamic furniture (separate meshes, physics bodies):
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

## 7.3 Modular Kitchen (PZ-style) 🔒

The kitchen counter is split into 4 modular pieces. Each is its own .mog file. Place side-by-side in Godot to form any kitchen layout.

| Piece | Tris | Description |
|---|---|---|
| kitchen_sink_unit | 172 | Counter + sink + faucet + cabinet door |
| kitchen_stove_unit | 416 | 4 burners + oven + control knobs |
| kitchen_empty_counter | 120 | Plain counter + 2 cabinet doors |
| kitchen_wall_cabinet | 60 | Wall-mounted cabinet (above counter) |

**All pieces share 1.0m width** (except wall cabinet at 0.8m) so they align perfectly side-by-side. Counter height 0.90m across all. Wall cabinet at 1.50m.

**Total modular kitchen = 768 tris** (vs 580 for unified). Slightly more, but 4× the layout flexibility. Procedural interior generator picks the arrangement:
- Small kitchen: stove + sink (2 pieces, 2m wide)
- Standard: empty + stove + empty + sink (4 pieces, 4m wide)
- Large: empty + stove + empty + sink + empty + 2 wall cabinets (7 pieces, 5m wide)

## 7.4 Loot Containers

Even static furniture can have loot containers — they just don't move. The kitchen counter has 3 drawer LootContainer children, each with its own loot roll. Player walks up, opens drawer, gets loot. Counter doesn't move, but the interaction is there.

This is actually how PZ does it — the kitchen counter is part of the tile, but the drawers are interactive hotspots on it.

## 7.5 Draw Call Budget per Room (Low preset) 🔒

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

## 7.6 What We Lose vs Full PZ-style

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

# PART 8: ASSET PRODUCTION PIPELINE

## 8.1 Directory Structure 🔒

> **See `STATUS.md` at repo root for the canonical current-vs-archived inventory.**
> Tree below shows the active working layout.

```
/home/z/my-project/
├── README.md                     # minimal entry point
├── STATUS.md                     # what's current vs archived
├── worklog.md                    # main worklog (append-only)
│
├── docs/                         # canonical documentation (no version suffixes)
│   ├── GDD.md                    # THIS document
│   ├── lore.md                   # lore (v1.2, semi-locked)
│   ├── poly_budget.md            # poly budget (v3 Path B, locked)
│   ├── assets.md                 # asset count + review strategy (merged)
│   ├── buildings.md              # shells + furniture + district templates (merged)
│   └── retired_city_builder_v3_extraction.md  # Phase B reference
│
├── assets/                       # the curated asset library
│   ├── buildings/                # houses, shops, warehouses, etc.
│   │   ├── src/                  # *.mog source (editable, version-controlled)
│   │   ├── out/                  # *.glb compiled (Godot imports these)
│   │   ├── renders/              # PNG previews
│   │   ├── textures/             # PNG PBR maps per material
│   │   ├── refs/                 # reference images, dimensions, photos
│   │   └── retired/              # retired assets (preserved for history)
│   ├── props/                    # furniture, loot, decorations
│   ├── foliage/                  # trees, bushes, grass, crops
│   ├── characters/               # NPC + player rigs
│   ├── environment/              # terrain patches, roads, fences, lights
│   ├── vehicles/                 # retired (external assets)
│   └── decals/                   # blood, grime, damage
│
├── godot_project/                # runtime Godot project (the game)
├── asset-pipeline/               # pipeline docs + worklog
├── scripts/                      # generation + render scripts
│   ├── render_with_chrome.js     # PBR renderer (three.js + Chrome)
│   ├── render_glb.html           # the page that loads + renders a GLB
│   ├── render_tier1_batch*.js   # batch renderers
│   ├── build_tier1_contact_sheet*.py  # contact sheet builders
│   └── batch_011/, batch_012/   # recent batch scripts
│
├── mogen-examples/               # upstream example .mog files
├── mogen-docs/compiled.md        # compiled MoGen DSL reference
├── download/                     # user-facing deliverables
│   └── asset-batches/            # contact sheets for review (recent 2 only)
│
├── screenshots/                  # recent in-game screenshots (3 kept)
└── archive/                      # historical (do not edit)
    ├── gdd_history/              # GDD v0 through v8 (17 versions)
    ├── poly_budgets/             # v1, v2 (v3 is canonical)
    ├── reference_architecture/   # frozen .gd reference copies
    ├── lookbook/                 # early-batch lookbook
    ├── contact_sheets/           # old batch contact sheets
    ├── screenshots/              # old screenshots
    ├── mazar_city_builder.py      # original Python generator
    └── city_lore_options.md      # old lore options
```

## 8.2 Tiered Review Strategy 🔒

| Tier | What you see | Cadence | Time per session |
|---|---|---|---|
| 1 — Style anchors | Individual 1024px PNG | Once per anchor (~10 total) | 1 min each |
| 2 — Variant packs | Contact sheets (4-16 thumbs) | Once per category (~5 total) | 3 min each |
| 3 — Mass production | Spot checks only | You ask, I show | 0 unless you ask |
| 4 — Biome milestone | Full biome overview render | Once per biome (10 total, per build order) | 10 min each |

**Total time investment:** ~3 hours of review across the entire alpha build.

## 8.3 Auto-validation 🔒

Every asset goes through:
1. `mogen check` — zero diagnostics (mandatory)
2. `mogen build` — must succeed in <100ms
3. VLM sanity check — "is this recognisable as X?"
4. Scale check — bounding box vs target dimensions
5. Palette check — material colors vs locked swatch (once palette locked)
6. LOD sanity — valid LOD chain or explicit "no LOD needed"

Failed checks → regenerate queue. User never sees broken assets.

## 8.4 Communication Protocol 🔒

When reviewing a batch, reply with one of:
- `APPROVE ALL` — ship it
- `APPROVE EXCEPT <ids>` — list asset IDs to reject
- `REGEN <ids> WITH <note>` — list asset IDs and what to change
- `REJECT BATCH — <reason>` — nuke the whole batch

## 8.5 Batch Zip Exports 🔒

Every batch is bundled into:
```
/home/z/my-project/download/asset-batches/<date>_<batch>_<description>.png  # contact sheet
```

Final assets committed to `/home/z/my-project/assets/<category>/` and backed up to:
- `mazar_alpha_backup_<date>.zip` — assets + scripts + mogen-examples
- `mazar_design_backup_<date>.zip` — GDDs + lore + poly budgets + furniture decision + worklogs + compiled MoGen docs

---


# PART 9: OPEN QUESTIONS 🔓

1. Survival needs list (subset of PZ's)
2. Combat focus balance (ratios of stealth/guns/melee encounters)
3. Loot richness multipliers per biome
4. Visual palette per biome (locked color swatches)
5. FOV angle (likely 90°, lock it)
6. Number of buildings / POIs per biome
7. Day-1 sim feasibility
8. Co-op technical architecture
9. Sandbox vs story mode launch order
10. Texture API key resolution
11. External vehicle + blood decal + grass asset sources (Mixamo? Quaternius? Kenney? Sketchfab?)
12. Tier 2 production start — variant packs

---

# PART 10: TERRAIN ARCHITECTURE 🧪

> **Status: v1 FLAT — elevation deferred. Updated 2026-09-14.**
> User decision: "go flat for v1 while keeping the subway." All buildings,
> roads, props, and foliage sit at Y=0. The `terrain_height.gd` module is kept
> intact for future re-enable (post-v1), but `_terrain_y()` in chunk_streamer.gd
> now always returns 0.0 via the `FLAT_TERRAIN_V1` constant. The subway system
> (`subway_network.gd`) operates underground and is unaffected — it never
> depended on surface terrain height.

## 10.0 v1 Flat Terrain (2026-09-14)

**What's flat:** All surface placement (buildings, roads, props, foliage, sidewalks, driveways, landmarks, decay layer). Everything sits at Y=0.

**What's NOT flat:** Subway tunnels are underground (their own Y coordinate system, independent of surface terrain).

**Why flat for v1:**
- Simplifies placement math — no height queries, no terrain following
- Eliminates z-fighting between ground mesh and placed objects
- Faster iteration — no heightmap generation or baking step
- The city gen pipeline (Lot System, road hierarchy, decay layer) is the priority; terrain elevation is a polish item

**How it's implemented:**
- `chunk_streamer.gd`: `FLAT_TERRAIN_V1 := true` constant. `_terrain_y()` returns 0.0 when enabled.
- `terrain_height.gd`: kept intact (ELEVATIONS table, height_at() function) — not deleted, just not called.
- `terrain_baker.gd`: heightmap mesh generation was already disabled in Phase B.4. Only bridges + water are placed.
- `terrain_debug_viz.gd`: autoload already disabled (caused z-fighting with flat ground).

**Re-enabling elevation (post-v1):**
1. Set `FLAT_TERRAIN_V1 := false` in chunk_streamer.gd
2. Re-enable the heightmap mesh generation in terrain_baker.gd `_build_terrain()`
3. Re-enable TerrainDebugViz autoload (optional, for debugging)
4. Bump `TERRAIN_HEIGHT_VERSION` in terrain_height.gd
5. Re-bake terrain mesh

## 10.1 Core principle (design — for post-v1 reference)

Two layers, cleanly separated:

| Layer | Owner | What it does |
|---|---|---|
| **Terrain mesh + collision** | `Terrain3D` plugin | Renders the visible terrain with LOD. Handles heightmap collision via `HeightMapShape3D`. Texture splatting for grass/dirt/rock per biome. We do NOT write custom LOD — Terrain3D gives us 300m+ view distance without 3.75M tris. |
| **Deterministic height function** | `tools/terrain_height.gd` (custom) | Pure function `height_at(x, z) → float`. Used by gameplay code (building placement, AI path queries, POI placement, bridge pier depth). No dependency on Terrain3D at runtime — only the build step writes to Terrain3D's heightmap. |
| **Build step** | `tools/terrain_baker.gd` (one-shot) | Reads `terrain_height.gd`, writes to Terrain3D's heightmap asset. Run once at design time, re-run when height function changes (bump `TERRAIN_HEIGHT_VERSION`). |
| **Everything else** | `ChunkStreamer` + `chunk_builder.gd` | Buildings, props, foliage, streetlights, roads, water surface (separate from terrain), POIs. All sample `terrain_height.height_at()` for their Y position. |

## 10.2 TERRAIN_HEIGHT_VERSION constant

```gdscript
# tools/terrain_height.gd
const TERRAIN_HEIGHT_VERSION := 1   # BUMP THIS when height function changes
```

When `TERRAIN_HEIGHT_VERSION` is bumped:
1. `tools/terrain_baker.gd` re-runs (writes new heightmap to Terrain3D asset)
2. `CityMeta` includes the version in its hash → `skip_if_valid` correctly invalidates cached chunks
3. All `.tscn` chunk files regenerate on next `city_builder.gd` run
4. Player spawn Y auto-recalculates from `terrain_height.height_at(spawn_x, spawn_z) + 2.0`

**Current version: 1** (initial — function not yet written, but version tracking is in place)

## 10.3 Subway-as-layer, not biome

**Decision (2026-09-12):** `Biome.SUBWAY` removed from the enum. Subway is a parallel underground layer, not a surface biome.

Rationale:
- A subway tunnel can run under any surface biome (Downtown station under Downtown, Industrial depot under Industrial, etc.). Treating subway as a surface biome forced every subway cell to also be surface-only.
- Surface cells where station entrances sit keep their surface biome (Downtown, Industrial, etc.). The entrance is a POI on the surface.
- Tunnels are a `SubwayNetwork` class (like `RoadNetwork` but for tunnels at Y ≈ -8m). Stations are nodes in this network; tunnels connect them.
- Player descends via station stairs → loads subway tunnel chunk. Same lazy-interior pattern as buildings — only loads when player enters.

Implementation status: `Biome.SUBWAY` value removed from `city_config.gd` enum. `tools/subway_network.gd` is a stub (constants only: TUNNEL_CEILING_Y=-6, TUNNEL_FLOOR_Y=-10, TUNNEL_RADIUS=2.5). Subway assets (subway_platform, subway_tunnel, subway_train_car, ticket_booth, turnstile, maintenance_tunnel_junction, emergency_exit_stairs, subway_pipe_cluster) are still in the manifest but won't be placed by surface chunk_builder — they'll be placed by `subway_builder.gd` when the player enters a station.

## 10.4 Per-biome elevation signatures

| Biome | Base Y | Amplitude | Frequency | Result |
|---|---:|---:|---:|---|
| SUBURBIA | +0.5 | 1.0m | 0.008 | gentle rolling — suburban feel |
| PARKS | +1.0 | 2.0m | 0.012 | parkland hills |
| FOREST | +2.0 | 5.0m | 0.018 | rolling hills — fog collects in valleys |
| FARMLAND | +0.2 | 0.3m | 0.005 | flat — tractors need level ground |
| COMMERCIAL | +0.5 | 0.5m | 0.005 | nearly flat — urban grid |
| INDUSTRIAL | +0.5 | 0.5m | 0.005 | flat |
| RIVER | -4.0 | 0.0 | — | carved valley — water at Y=0, riverbed at -4m |
| DOWNTOWN | +0.5 | 0.5m | 0.005 | flat (urban) but raised above river for visibility |
| MILITARY | +3.0 | 0.0 | — | plateau — fort sits on a bluff |
| COASTAL_BEACH | -1.0 | 8.0m | 0.020 | rolling cliff coastline — lighthouse territory |
| WATER | -2.0 | 0.0 | — | ocean/lake (sea level) |

## 10.5 River redesign (Phase A.2 — done 2026-09-12) — SUPERSEDED

> **UPDATED 2026-09-21:** River + Wetlands + Coastal Beach are REMOVED for v1. The entire water system (river, bay, beaches, houseboats, piers, lighthouse) is cut. City is now a single contiguous landmass. Section below preserved as historical reference only.

**Was:** River = 2 columns × 6 rows = 12 cells = 25% of map = 3km² water. Player walks endless water.

**Then:** River = 1 column × 6 rows = 6 cells = 12.5% of map. Freed column (col 5) became `COASTAL_BEACH` (12.5%). Player walks along coast with fishing huts, piers, lighthouse.

**Now (2026-09-21):** No river, no coast, no wetlands. 8 biomes total (Suburbia, Commercial, Industrial, Farmland, Forest, Parks, Downtown, Military). Subway kept as underground layer, not a surface biome. Lore updated: city is no longer coastal, no Sarran River, no Sarran Bay. "Sarran" survives as a historical name in streets + districts only.

Grid layout evolution:
```
v0 (2026-09-11):                    v1 (2026-09-12):                    v2 (2026-09-21):
[F, F, FA,FA, RI, RI, IN, IN]      [F, F, FA,FA, RI, CB, IN, IN]      (no water column)
[F, FA, FA,FA, RI, RI, IN, MI]     [F, FA, FA,FA, RI, CB, IN, MI]     (no coastal beach)
[SU,SU,FA,PA, RI, RI, DT, MI]      [SU,SU,FA,PA, RI, CB, DT, MI]      (8 surface biomes only)
[SU,SU,CO,PA, RI, RI, DT, IN]      [SU,SU,CO,PA, RI, CB, DT, IN]      (subway = underground layer)
[SU,PA,CO,CO, RI, RI, DT, IN]      [SU,PA,CO,CO, RI, CB, DT, IN]
[PA,SU,SU,CO, RI, RI, IN, IN]      [PA,SU,SU,CO, RI, CB, IN, IN]
```

**Why cut:** river/wetlands added complexity (bridges, water shaders, swimming, naval assets) for low gameplay value. Project Zomboid reference map (user-provided) doesn't have a major river — it's all land with towns separated by forest. Removing water also simplifies pathfinding, collision, and streaming.

## 10.6 Landmark system (Phase F — not yet implemented)

`city_config.gd` has a `landmarks` field per biome (added during Phase A). The runtime streamer does NOT yet read it. Hero landmarks (fort_sarran, government_palace, stadium, old_royal_palace, lighthouse, bridge_section, grain_silo, windmill) will NOT spawn in-game until Phase F is done.

Planned design: `res://data/pois.json` — hand-placed POIs. `chunk_builder.gd` queries POIs in chunk bounds. Places 1 per POI exactly. Suppresses procedural placement in POI radius. Landmark visibility check — raycast from 1km away, verify not occluded by terrain. Adjust POI Y if needed.

# APPENDIX B: FILE MAP

> **See `STATUS.md` at repo root for the full canonical-vs-archived inventory.**
> This appendix captures only paths referenced within this GDD.

| Path | Purpose |
|---|---|
| `/home/z/my-project/docs/GDD.md` | **this document** (canonical) |
| `/home/z/my-project/docs/lore.md` | lore (v1.2, semi-locked) |
| `/home/z/my-project/docs/poly_budget.md` | poly budget (v3 Path B, locked) |
| `/home/z/my-project/docs/assets.md` | asset count + review strategy (merged) |
| `/home/z/my-project/docs/buildings.md` | shells + furniture + district templates (merged) |
| `/home/z/my-project/worklog.md` | main worklog (append-only) |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | asset pipeline worklog |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference** |
| `/home/z/my-project/godot_project/` | runtime Godot project |
| `/home/z/my-project/assets/` | source asset library (.mog + .glb + renders, by category) |
| `/home/z/my-project/scripts/` | build/render scripts |
| `/home/z/my-project/archive/` | historical (GDD v0-v8, old poly budgets, retired code, etc.) — do not edit |
