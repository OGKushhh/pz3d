# MAZAR — UNIFIED GAME DESIGN DOCUMENT

> **Version:** 1.8 (merged — supersedes GDD v8, lore_mazar_v1.2, poly_budget_v3_path_b, furniture_merging_decision)
> **Status:** Pre-production → vertical slice. Lore semi-locked. Path B locked. Tier 1 production: 28 approved + 5 retired.
> **Working title:** *Mazar*
> **Engine:** Godot 4.7.2 (glTF 2.0 native, Compatibility renderer default for Low preset)
> **Asset toolchain:** MoGen v0.1.12 (`.mog` DSL → `.glb` → Godot)
> **MoGen reference:** `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB)
> **Backups:** `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` (2.2MB) + `mazar_design_backup_2026-09-11.zip` (4.4MB)

**Version history:**
- v1.0 — initial vision draft
- v1.1 — lore locked (Republic of Mazar)
- v1.2 — Path B locked (two-tier Low/High presets)
- v1.3 — Tier 1 production started
- v1.4 — furniture merging decision locked
- v1.5 — cars + blood + grass retired (external assets)
- v1.6 — kitchen counter split into 4 modular pieces
- v1.7 — batch 006 (10 new assets, 28 total)
- **v1.8 — UNIFIED: lore + GDD + poly budget + furniture decision merged into this single document**

---

# PART 1: VISION & PILLARS

## 1.1 Vision

I am building a first-person survival game with the soul of Project Zomboid but in real 3D. The world is the National City of Mazar — a fictional coastal city divided by the Sarran River, where a 300-year monarchy ended in a quiet coup 70 years ago, where a military junta sold the nation to a foreign Border Enemy, where Operation Living Troop created a supersoldier serum that killed its subjects and raised them as the undead.

The city is fixed, persistent, hand-crafted. Every building enterable. Every run, the city persists but the loot, zombie spawns, and locked doors reset. You die, you lose your consumables, but your weapons, your base upgrades, your story progress, and your meta-upgrades carry forward. Sandbox first; story mode later.

Travel is exploration, not optimization. The map uses draw-distance fog, non-trivial road networks, the Sarran River as a real obstacle, bridges as chokepoints, landmarks far apart. The fastest path on the GPS is rarely the safest path.

No place is safe.

## 1.2 Pillars

1. **Hand-authored world.** Every building has a reason. Procedural interiors provide replayability; the exterior shell is fixed.
2. **Sound is gameplay.** Zombies hear you. Gunshots draw them. Stealth matters. Generators hum. Footsteps echo.
3. **Roguelite progression.** Permadeath in sandbox; meta-upgrades persist. Find your old body, loot your old loot.
4. **Biome identity.** Each of the 10 biomes has loot focus, difficulty, vibe, weather, time-cycle identity.
5. **Travel as exploration.** Not optimization. Sarran River blocks. Forest hides. Bridges force chokepoints.
6. **All three combat modes.** Stealth, guns, melee — all viable, all situational. Shooting is the addictive hook (Valorant-feel).
7. **Civic, not sacred.** Mazar's landmarks are civic (lighthouse, water tower, grain silo, hospital, government palace). No religious buildings. Faith lives in the people, not the skyline.
8. **Runs on millions of PCs.** Low preset baseline: 2GB VRAM / 4GB RAM / 1080p / 60 FPS. High preset scales up.
9. **Furniture is interactive + modular.** Static fixtures merge for performance. Dynamic furniture is separate RigidBody3D. Kitchen counter is split into modular pieces (PZ-style).

---

# PART 2: LORE — THE REPUBLIC OF MAZAR

> **Status:** Semi-locked for alpha. Overall structure is locked. Specific names (streets, factions, characters, radio stations) can shift during alpha playtesting.

## 2.1 The Nation

The Republic of Mazar is a coastal nation on the edge of a forgotten sea. Its capital, the National City of Mazar, sits on a wide bay where the Sarran River meets the ocean. The nation is small — you can drive across it in a day — but it was once one of the most prosperous places in the region. People came from around the world to live here, to work, to study, to find shelter. It was a nation of trade, of education, of faith, of stability. That was a long time ago.

The Mazarani people are conservative and religious. Their faith shaped their culture, their laws, and their daily rhythms. But religion in Mazar was never a spectacle — there were no grand monuments to it. It was quiet, personal, woven into the fabric of ordinary life. The nation's landmarks were civic, not sacred: the lighthouse, the water tower, the grain silo, the hospital, the government palace, the stadium, the railway station, the grand bazaar. Those were the places that defined Mazar. The faith lived in the people, not in the skyline.

**Sarran** is an old Mazarani name, preserved in the city's streets and districts:
- **Sarran Street** — the main road through Old Town
- **Sarran District** — the historic quarter, once the heart of the monarchy
- **Sarran Bay** — the water west of the city, where the old fishing fleet moored
- **Sarran Bridge** — the main crossing between the east and west banks of the river

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

The experiment ended in an explosion. The lab at Fort Sarran — a naval fort on the eastern edge of the city — breached containment. The liquid leaked into the facility's drainage system. It entered the city's sewer network. It contaminated the drinking water supply and the river. People drank it. They bathed in it. They cooked with it. They watered their crops with it.

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
| **Free Bay FM** | Survivors | Distress calls, supply tips, safe route warnings |
| **The Border Signal** | Border Enemy | Foreign language, jamming, encrypted transmissions |

## 2.12 The City — Geography

The city is divided by the Sarran River, which flows from the northern forest through the farmland and into Sarran Bay. The bay splits the city into east and west. Bridges are chokepoints. Water is a barrier.

**West Side:**
- **Suburbia** — middle-class homes from the Long Peace, now empty
- **Parks & Greenways** — old public gardens, walking trails, playgrounds
- **Commercial Strip** — once-bustling bazaars and shops, now looted
- **Farmland** — Mazar's food basket: olive groves, wheat, irrigation canals
- **Forest** — the border region, enemy infiltration routes, hidden bunkers

**East Side:**
- **Industrial Park** — manufacturing and rail, outposts here
- **River & Wetlands / Coastal Beach** — fishing villages, smuggling routes, the bay, the lighthouse
- **Downtown** — the capital district: hospital, police HQ, government buildings
- **Military Zone / Quarantine** — ground zero, the lab, Fort Sarran

**Underground:**
- **Subway** — public transit + secret military transport tunnels

## 2.13 The 10 Biomes

| # | Biome | Lore Role | Loot Focus | Difficulty | Zombie Density | Weather | POIs | Base Potential |
|---|---|---|---|---|---|---|---|---|
| **1** | Suburbia | Middle-class homes from the Long Peace. Now empty. | Food, clothes, tools, batteries, basic meds, family cars | Low | Low–Medium | Mild autumn, overcast, light rain | Houses, school, corner store, gas station, cul-de-sacs | **High** — starter base |
| **2** | Parks & Greenways | Old public gardens, walking trails, playgrounds. | Water, snacks, gardening tools, seeds, meds | Low | Low | Sunny, breezy, morning mist | Playground, botanical garden, picnic area, pond, trailhead | Low–Medium |
| **3** | Forest | Border region. Enemy infiltration routes. Hidden bunkers. | Wood, herbs, hunting gear, camp supplies | Medium | Low | Fog, cold rain, early dusk | Ranger station, hunting cabins, campsite, cave, logging camp | Medium–High |
| **4** | Farmland | Mazar's food basket. Olive groves, wheat, irrigation canals. | Crops, seeds, canned goods, fuel, animals | Low–Medium | Low | Heat waves, dust, thunderstorms | Farms, orchards, barns, grain silos, windmill | **High** |
| **5** | Commercial Strip | Once-bustling bazaars and shops. Now looted. | Meds, food, fuel, weapons, electronics, clothing | Medium–High | Medium–High | Overcast, rain, blackouts | Diner, motel, pharmacy, supermarket, gun store, bazaar | Medium |
| **6** | Industrial Park | Manufacturing and rail. Outposts here. | Metal, tools, generators, fuel, chemicals | Medium | Medium | Industrial smog, acid rain, cold drizzle | Warehouses, factories, rail depot, water tower, outposts | **High** |
| **7** | River & Wetlands / Coastal Beach | Fishing villages, smuggling routes, the bay, the lighthouse. | Fish, clean water, boat fuel, herbs, fishing gear | Medium | Low–Medium | Mist, heavy rain, flooding, fog | Bridges, houseboats, fishing huts, pier, lighthouse | Low–Medium |
| **8** | Subway | Public transit + secret military transport tunnels. | Electronics, non-perishable food, batteries, rare lore | Medium–High | Medium–High (clustered) | Damp, dripping, stale air | Stations, platforms, maintenance tunnels, secret cargo rooms | Low–Medium |
| **9** | Downtown | Capital district. Hospital, police HQ, government buildings. | Best meds, guns, ammo, armor, electronics, intel | High–Very High | Very High | Neon night, rain, smog, blackouts | Hospital, police HQ, government palace, stadium, apartments | **Low** — death trap |
| **10** | Military Zone / Quarantine | Ground zero. Operation Living Troop lab. Fort Sarran. | Military gear, MREs, hazmat suits, radios, advanced meds, weapons | Extreme | Extreme | Toxic fog, ashfall, cold wind, unnatural silence | Naval fort, field hospital, hazmat tents, convoy wrecks, bunker entrance | None — endgame raid only |

**Military Zone placement:** eastern edge of the city (Fort Sarran is on the eastern edge per lore). Gated by keycard/quest/radio rumor. One road in, one road out. 1-2 city blocks or one fenced compound. High risk/reward side exploration.

## 2.14 Civic Landmarks

No religious buildings. The nation's landmarks are civic:

1. The Lighthouse (River & Wetlands / Coastal Beach)
2. The Water Tower (Industrial Park)
3. The Grain Silo (Farmland)
4. The Hospital (Downtown)
5. The Police HQ (Downtown)
6. The Government Palace — now junta HQ (Downtown)
7. The Stadium (Downtown)
8. The Old Royal Palace — abandoned, sealed (Downtown or Suburbia edge)
9. The Naval Fort — Fort Sarran (Military Zone)
10. The Broadcast Tower (Downtown or Industrial)
11. The Railway Station (Industrial Park)
12. The Grand Bazaar / Souq (Commercial Strip)

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
- Al-Salam (Peace), Al-Nour (Light), Al-Minar (Lighthouse), Old Town, New Town, New Mazar, Fort Quarter, Sarran District

**Radio:**
- Voice of Mazar, Radio Junta, Free Bay FM, The Border Signal

**Key figures:**
- King Amir of House Mazar (last monarch, exiled, fate unknown)
- General Karim (first junta leader, principled, died under house arrest)

**Key locations:**
- Fort Sarran (the lab, outbreak origin, Military Zone)
- Sarran Bay (west of city)
- Sarran River (divides city east/west)
- Sarran Bridge (main crossing)
- The Old Royal Palace (abandoned, sealed — lore fragment location)

## 2.17 Timeline

- **300 years ago → 70 years ago:** The Long Peace. House of Mazar monarchy. Tolerant, stable, prosperous.
- **70 years ago:** The Quiet Coup. King Amir abdicated to avoid civil war. Military took power.
- **68-60 years ago:** General Karim's principled regime, then rot. He was placed under house arrest by his own officers.
- **13 years ago:** The Border Enemy (northern neighbor) bought the latest junta leader. Mazar became a staging ground.
- **10 years ago:** Operation Living Troop began. Secret military experiment to create supersoldiers. The liquid worked — but it killed subjects and raised them as undead.
- **2 weeks ago:** The lab at Fort Sarran exploded. Liquid leaked into drainage, sewer, drinking water, river. The fog rolled in. The rain fell. The water was poison.
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

One run modifier per run. Overrides a specific biome's rules. Sources: the 4 locked radio stations (Voice of Mazar, Radio Junta, Free Bay FM, The Border Signal).

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

### All 10 biome tables:

| District | Common (60%) | Uncommon (30%) | Rare (10%) |
|---|---|---|---|
| Hospital (Downtown) | Bandage, Bottled Water | Medkit, Syringe | Stimulant (temp speed boost) |
| Police HQ (Downtown) | Pistol Ammo | Shotgun Ammo | Tier 2 Armor |
| Industrial Park | Scrap Metal, Canned Food | Noise Grenade Parts | Rare Crafting Component |
| Subway | Flashlight Battery, Clean Water | Electronics | Lore Fragment (story item) |
| River & Wetlands | Fish, Driftwood | Boat Fuel | Hermetic Container (rare storage) |
| Suburbia | Canned Food, Batteries | Household Tools | Car Keys (random vehicle) |
| Parks & Greenways | Snacks, Water | Seeds | Fishing Rod |
| Forest | Wood, Herbs | Hunting Gear | Animal Trap |
| Farmland | Crops, Eggs | Fuel Canister | Tractor Parts |
| Commercial Strip | Cash, Snacks | Electronics | Weapon Magazine |
| Military Zone | MRE, Battery | Hazmat Suit | Military Keycard |

---

# PART 4: WORLD STRUCTURE

## 4.1 Map Dimensions 🔒

**4.0 km × 3.0 km = 12 km² of playable area** (~40% of GTA San Andreas total map).

- GTA SA full map ≈ 5.5 km × 5.5 km ≈ 30 km²
- Los Santos + Red County + Flint County ≈ 42% of total ≈ 12.7 km²
- Rounded to 4 × 3 km

**Grid:** 8 × 6 cells of 500m × 500m. Each cell = 0.25 km². Total 48 cells.

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
4. **Sarran River as obstacle** — water creates real barriers. Bridges are chokepoints.
5. **Landmarks far apart** — placed in opposite corners to sell scale.
6. **Every town has a reason to stop** — no filler towns.
7. **Unique color/weather/time per biome** — each biome has its own identity.
8. **Free-roam interiors** — every building enterable.
9. **Technical limits as creative constraints** — fog, draw distance, streaming budget all become gameplay.
10. **Travel = exploration, not optimization.**

## 4.3 Persistent Map + Per-run Reset 🔒

- **Persistent (carries across runs):** map layout, story keys, lore fragments, base upgrades, unlocked areas, meta-progression resources.
- **Per-run reset:** loot containers, zombie spawns, barricades, locked doors, NPC positions, radio rumor modifier.

## 4.4 Procedural Interiors 🔒

- **Fixed:** building exterior shell, room layout (walls), doors, windows, structural props (kitchen counters, bathroom fixtures, built-in shelving).
- **Procedural:** small furniture placement (chairs, tables, lamps, decoration props), loot container positions, prop scatter (books, debris, blood decals), zombie patrol routes.
- **Modular kitchen:** assembled from 4 modular pieces (sink_unit, stove_unit, empty_counter, wall_cabinet) placed side-by-side. Layout is procedural — different kitchens have different arrangements.

## 4.5 Alpha Build Order 🔒

1. Suburbia → 2. Parks & Greenways → 3. Farmland → 4. Forest → 5. Commercial Strip → 6. Industrial Park → 7. River & Wetlands → 8. Subway → 9. Downtown → 10. Military Zone.

**Logic:** safe rural → risky commercial → industrial → underground → urban endgame → military endgame.

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
| River & Wetlands | 3 houseboats×1.5k=4.5k | 2k | 50 reeds multimesh=2k | 4×3k=12k | **20.5k** ✅ |
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

```
/home/z/my-project/
├── assets/                       # the curated asset library
│   ├── buildings/                # houses, shops, warehouses, etc.
│   │   ├── src/                  # *.mog source (editable, version-controlled)
│   │   ├── out/                  # *.glb compiled (Godot imports these)
│   │   ├── renders/              # PNG previews
│   │   ├── textures/             # PNG PBR maps per material
│   │   ├── refs/                # reference images, dimensions, photos
│   │   └── retired/              # retired assets (preserved for history)
│   ├── props/                    # furniture, loot, decorations
│   ├── foliage/                  # trees, bushes, grass, crops
│   ├── characters/               # NPC + player rigs
│   ├── environment/              # terrain patches, roads, fences, lights
│   ├── vehicles/                 # retired (external assets)
│   └── decals/                   # retired (external assets)
│
├── asset-pipeline/
│   ├── README.md
│   └── worklog/worklog.md        # append-only worklog
│
├── scripts/                      # generation + render scripts
│   ├── render_with_chrome.js     # the PBR renderer (three.js + Chrome)
│   ├── render_glb.html           # the page that loads + renders a GLB
│   ├── render_tier1_batch*.js    # batch renderers
│   ├── build_tier1_contact_sheet*.py  # contact sheet builders
│   └── ...
│
├── mogen-examples/               # the upstream example .mog files
├── mogen-docs/compiled.md        # compiled MoGen DSL reference
└── download/                     # user-facing deliverables
    ├── GDD_v1.8_unified.md       # THIS document
    ├── asset-batches/            # contact sheets for review
    └── mogen-lookbook/           # initial 11 PNG renders
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

# PART 9: TIER 1 PRODUCTION STATUS

## 9.1 Approved Assets (28 active + 1 upstream = 29 total) ✅

| # | Asset | Category | Tris | Type | Status |
|---|---|---|---|---|---|
| 1 | suburban_house_v2 | buildings | 1,800 | static shell | ✅ approved |
| 2 | office_chair | props | 6,500 | dynamic | ✅ approved |
| 3 | dining_table | props | 460 | dynamic | ✅ approved |
| 4 | oak_tree | foliage | 2,400 | hero tree | ✅ approved |
| 5 | bush | foliage | 360 | bush | ✅ approved |
| 6 | sedan | vehicles | — | — | ❌ RETIRED (external) |
| 7 | pickup_truck | vehicles | — | — | ❌ RETIRED (external) |
| 8 | blood_splatter_decal | decals | — | — | ❌ RETIRED (external) |
| 9 | asphalt_road_segment | environment | 96 | road | ✅ approved |
| 10 | two_story_colonial | buildings | 2,600 | static shell | ✅ approved |
| 11 | bungalow | buildings | 2,000 | static shell | ✅ approved |
| 12 | bookshelf | props | 264 | dynamic | ✅ approved |
| 13 | bed_single | props | 1,600 | dynamic | ✅ approved |
| 14 | kitchen_counter | props | — | — | ❌ RETIRED (split into 4 modular) |
| 15 | refrigerator | props | 412 | dynamic + loot | ✅ approved |
| 16 | pine_tree | foliage | 256 | standard tree | ✅ approved |
| 17 | grass_tuft | foliage | — | — | ❌ RETIRED (external) |
| 18 | picket_fence | environment | 168 | fence | ✅ approved |
| 19 | street_light | environment | 504 | light source | ✅ approved |
| 20 | kitchen_sink_unit | props | 172 | static modular | ✅ approved |
| 21 | kitchen_stove_unit | props | 416 | static modular | ✅ approved |
| 22 | kitchen_empty_counter | props | 120 | static modular | ✅ approved |
| 23 | kitchen_wall_cabinet | props | 60 | static modular | ✅ approved |
| 24 | shed | buildings | 1,000 | static shell | ✅ approved |
| 25 | garage_detached | buildings | 1,300 | static shell | ✅ approved |
| 26 | sofa | props | 3,300 | dynamic | ✅ approved |
| 27 | coffee_table | props | 424 | dynamic | ✅ approved |
| 28 | toilet | props | 996 | static fixture | ✅ approved |
| 29 | bathtub | props | 280 | static fixture | ✅ approved |
| 30 | mailbox | environment | 1,200 | exterior | ✅ approved |
| 31 | trash_can | environment | 1,200 | exterior | ✅ approved |
| 32 | birch_tree | foliage | 1,800 | standard tree | ✅ approved (needs canopy randomization fix) |
| 33 | brick_wall_segment | environment | 120 | boundary | ✅ approved |
| — | fence.mog (upstream) | environment | 318 | fence | ✅ approved |

## 9.2 Known Issues Queue 🔒

| # | Asset | Issue | Fix | Status |
|---|---|---|---|---|
| 1 | suburban_house.mog (upstream) | Doors flush with wall | Author v2 with `wall` holes | ✅ FIXED |
| 2 | humanoid.mog (DSL test) | Reads "Roblox/blocky" | Accept for alpha; hybrid for v1 | Accepted |
| 3 | oak_tree.mog (v1) | Bare twigs from `branch` primitive | Replace with `cylinder` trunk | ✅ FIXED |
| 4 | sedan + pickup_truck | Wrong dimensions, wrong wheel angle | Retire — external assets | ✅ RETIRED |
| 5 | blood_splatter_decal | Just a red square | Retire — external assets | ✅ RETIRED |
| 6 | texture workflow | Gemini free tier = 0 image quota | Need paid key | 🔓 PAUSED |
| 7 | grass_tuft | Low quality | Retire — external assets | ✅ RETIRED |
| 8 | house side windows | Windows on rotated walls not aligned | Add `rot=[0, 90, 0]` to side window groups | ✅ FIXED |
| 9 | bookshelf showing back | Back panel at +Z, camera at +Z | Flip: back at -Z, books at +Z | ✅ FIXED |
| 10 | bed sheets disconnected | `tags="floating"` made them disconnected | Remove `tags`, overlap with mattress | ✅ FIXED (user accepted minor residual) |
| 11 | refrigerator middle upside down | Divider/handles area looked wrong | Simplify: remove divider + handles + magnets | ✅ FIXED |
| 12 | kitchen counter reversed | L-turn going wrong direction | Split into 4 modular pieces (PZ-style) | ✅ FIXED |
| 13 | birch_tree canopy | "Looks like an atom" — spheres too uniform, no randomization | Add `noise=` or `jitter=` to canopy spheres; vary radii + positions | ⏳ TODO (next batch) |

---

# PART 10: OPEN QUESTIONS 🔓

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

# PART 11: MILESTONES 🔒

| # | Milestone | Exit criteria | Status |
|---|---|---|---|
| 0 | Pre-production | All open questions answered | ⏳ in progress |
| 1 | Vertical slice — Suburbia | 5 buildings enterable, 1 weapon, 5 loot items, basic Walker AI, day/night | Next |
| 2 | Alpha — full map | All 10 biomes present, all systems functional | — |
| 3 | Alpha+ — content polish | All buildings enterable, all loot tables populated, meta-progression balanced | — |
| 4 | Story mode | Day-1 sim, missions, NPCs, lore fragments, endings | — |
| 5 | Co-op technical pass | Online architecture validated | — |
| 6 | v1 release | Hybrid characters, full visual polish, comic shader, all known issues fixed | — |

---

# APPENDIX A: MOGEN LESSONS LEARNED (cumulative, 11 sessions)

- MoGen compiles fast. suburban_house_v2 (1.8k tris): 12 ms.
- `mogen check` + `mogen build` work headless. `mogen thumbnail` broken — replaced with Chrome + three.js + swiftshader.
- `mogen textures` requires **paid Gemini API key** (free tier = 0 image quota).
- DSL is structural, not artistic. Excellent at buildings/props. Bad at organic characters + vehicles + grass.
- **The DSL reference is compiled at `/home/z/my-project/mogen-docs/compiled.md` (1559 lines, 106KB).**
- **The `wall` primitive** with `holes=[cx, cy, w, h]` is the right tool for walls with door/window cutouts.
- **The `solid` group** with `cleanup="coplanar"` merges same-material primitives. Use for building/vehicle shells.
- **Floating cluster errors (`E1101`)** — fix by overlapping meshes in ALL 3 axes (X, Y, Z). OR use `tags="floating"` for intentionally disconnected decorative elements.
- **`slab` uses `anchor=bottom`** by default. When placing a foundation on a lawn, set pos y to overlap.
- **`icosphere` uses `subdivisions=`** not `detail=`. 1=low-poly, 2=default.
- **`branch` primitive** is hard to control. Use plain cylinders for stylized trees.
- **`plane` uses `size=[x, _, z]`** (XZ-aligned). `quad` uses `w=` and `h=` (XY-aligned).
- **`cone` primitive** with `sides=8` is good for stylized conifer foliage.
- **Camera yaw convention:** yaw=0 = +Z face (back). yaw=180 = -Z face (front with door).
- **`alpha_mode="blend"`** for transparency. `alpha_mode="mask"` + `alpha_cutoff=0.5` for 1-bit cutout.
- **Wrap complex bodies in `solid (cleanup="coplanar")`** to merge same-material parts.
- **`tags="floating"`** is the escape hatch for intentionally disconnected parts.
- **`light` node** embedded in .mog — exported as glTF KHR_lights_punctual, Godot reads as Light3D.
- **Vehicles + blood decals + grass are better as external assets.**
- **Static vs dynamic furniture split** is the key architecture decision (Part 7).
- **CRITICAL: window groups on rotated walls must also be rotated.** Wall `rot=[0, 90, 0]` → window group also `rot=[0, 90, 0]`.
- **Bookshelf orientation:** open side (with books) faces +Z (default camera direction). Back panel at -Z.
- **Bedding overlap:** sheets/blanket/pillow must overlap with mattress by 0.02-0.03m in Y. Don't use `tags="floating"` for bedding.
- **Refrigerator simplification:** when in doubt, remove decorative details.
- **Modular kitchen pattern (PZ-style):** split complex multi-part furniture into separate modular pieces. Each piece is its own .mog file. Place side-by-side in Godot to form any layout.
- **Two-story colonial window count = 3 upstairs = 3 rooms.** Classic colonial layout: master bedroom (left), bathroom (center), second bedroom (right).
- **Birch tree canopy needs randomization.** Spheres too uniform → "looks like an atom." Use `noise=` or `jitter=` deformers, vary radii + positions. (TODO next batch)

---

# APPENDIX B: FILE MAP

| Path | Purpose |
|---|---|
| `/home/z/my-project/download/GDD_v1.8_unified.md` | **this document** |
| `/home/z/my-project/download/asset-batches/2026-09-11_tier1_anchors_batch-006_28_assets_contact_sheet.png` | **latest contact sheet (28 assets)** |
| `/home/z/my-project/download/mazar_alpha_backup_2026-09-11.zip` | **alpha backup (2.2MB)** |
| `/home/z/my-project/download/mazar_design_backup_2026-09-11.zip` | **design backup (4.4MB)** |
| `/home/z/my-project/asset-pipeline/worklog/worklog.md` | append-only worklog |
| `/home/z/my-project/mogen-docs/compiled.md` | **compiled MoGen DSL reference** |
| `/home/z/my-project/upload/large-detailed-map-of-gta-san-andreas.jpg` | GTA SA map reference |
