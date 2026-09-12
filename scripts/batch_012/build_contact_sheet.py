#!/usr/bin/env python3
"""Build contact sheet for batch 012 — 36 assets (2 fixes + 34 new).
Layout: 6 cols x 6 rows = 36 cells."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    # FIXES (2)
    ("broadcast_tower [FIXED]",  "buildings", "broadcast_tower",   8000, "Stairs + top cab added"),
    ("parking_garage [FIXED]",   "buildings", "parking_garage",    2500, "Real ramps + stair tower"),
    # HEROES (4)
    ("government_palace",        "buildings", "government_palace", 4500, "Dome + colonnade + 3 wings"),
    ("stadium",                  "buildings", "stadium",           1500, "Oval bowl + 4 light pylons"),
    ("old_royal_palace",         "buildings", "old_royal_palace",  3200, "4 towers + courtyard + fountain"),
    ("fort_sarran",              "buildings", "fort_sarran",       2500, "Star fortress + keep + moat"),
    # CHARACTERS (5)
    ("walker_zombie_male",       "characters", "walker_zombie_male", 7100, "Hunched, red eyes, outstretched"),
    ("walker_zombie_female",     "characters", "walker_zombie_female", 7200, "Long hair, torn dress"),
    ("crawler_zombie",           "characters", "crawler_zombie",   5700, "Legless, dragging torso"),
    ("npc_survivor",             "characters", "npc_survivor",     7900, "Backpack + bat, alert pose"),
    ("npc_soldier",              "characters", "npc_soldier",      8000, "Tactical vest + rifle"),
    # DECALS (4)
    ("blood_splatter",           "decals", "blood_splatter",       500, "Surface stain + droplets"),
    ("poster_torn",              "decals", "poster_torn",         300, "Missing person, torn"),
    ("grime_dirt",               "decals", "grime_dirt",          800, "Wall/floor grime"),
    ("crack_road",               "decals", "crack_road",          600, "Road cracks + potholes"),
    # FOREST (3)
    ("cave_entrance",            "buildings", "cave_entrance",     800, "Rocky maw + boulders"),
    ("logging_camp_shed",        "buildings", "logging_camp_shed", 600, "Open shed + log piles"),
    ("ranger_lean_to",           "buildings", "ranger_lean_to",   700, "Lean-to + fire ring"),
    # FARMLAND (3)
    ("irrigation_canal",         "environment", "irrigation_canal", 400, "Concrete banks + sluice"),
    ("hay_bale",                 "environment", "hay_bale",        300, "Round bale + net wrap"),
    ("grain_storage_shed",       "buildings", "grain_storage_shed", 1200, "Open shed + 2 silos"),
    # COASTAL (3)
    ("boardwalk_section",        "environment", "boardwalk_section", 800, "Elevated planks + lamps"),
    ("marsh_grass",              "foliage", "marsh_grass",         1200, "Reeds + cattails"),
    ("marsh_pier",               "buildings", "marsh_pier",        500, "Small platform + bench"),
    # SUBWAY (3)
    ("maintenance_tunnel_junction", "buildings", "maintenance_tunnel_junction", 1000, "T-junction + pipes"),
    ("emergency_exit_stairs",    "buildings", "emergency_exit_stairs", 1500, "2-flight stair + sign"),
    ("subway_pipe_cluster",      "buildings", "subway_pipe_cluster", 1500, "Pipes + valves + junction"),
    # MILITARY (2)
    ("mass_grave",               "environment", "mass_grave",      800, "Mounds + crosses + wire"),
    ("helipad_control_room",     "buildings", "helipad_control_room", 1200, "Tower + radar + landing pad"),
    # COMMERCIAL (3)
    ("salon",                    "buildings", "salon",             1500, "Storefront + chairs"),
    ("grocery_store",            "buildings", "grocery_store",    2500, "Storefront + shelves + carts"),
    ("bank_branch",              "buildings", "bank_branch",      2200, "Columns + ATM + pediment"),
    # SUBURBAN/MISC (4)
    ("bird_house",               "props", "bird_house",            200, "Pole + small house"),
    ("garden_pergola",           "props", "garden_pergola",        1500, "4 posts + lattice + vines"),
    ("apartment_tower_high",     "buildings", "apartment_tower_high", 3000, "8-story + balconies"),
    ("train_boxcar_derelict",    "buildings", "train_boxcar_derelict", 1800, "Rusted + open door + bogies"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-12_tier1_batch-012_36_assets_FINAL_contact_sheet.png"

COLS = 6
ROWS = (len(ASSETS) + COLS - 1) // COLS  # 6 rows
CELL_W, CELL_H = 280, 260
PAD = 8
LABEL_H = 55

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 110

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 12)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 9)
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()
    font_title = ImageFont.load_default()

draw.text((PAD, 8), "Mazar Alpha — Tier 1 Batch 012 (36 ASSETS — 2 fixes + 34 new)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 32), "2 fixes (broadcast_tower + parking_garage) + 4 huge heroes + 5 characters + 4 decals + 21 buildings/props", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 47), "VLM confirmed: broadcast_tower now has visible zig-zag stairs + enclosed top cab under antenna.", fill=(160, 220, 160), font=font_sm)
draw.text((PAD, 62), "Categories: yellow=BUILDING, blue=PROP, green=FOLIAGE, orange=ENVIRONMENT, red=CHARACTER, purple=DECAL", fill=(140, 140, 140), font=font_sm)

CAT_COLORS = {
    "buildings":   (255, 220, 100),
    "props":       (100, 180, 255),
    "foliage":     (140, 200, 140),
    "environment": (255, 180, 100),
    "characters":  (255, 130, 130),
    "decals":      (200, 140, 220),
}

for i, (label, cat, name, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 80 + PAD + row * (CELL_H + PAD)

    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    png_path = f"/home/z/my-project/assets/{cat}/renders/{name}.png"
    try:
        img = Image.open(png_path).convert("RGB")
        img.thumbnail((CELL_W - 12, CELL_H - LABEL_H - 12))
        ix = x + (CELL_W - img.width) // 2
        iy = y + 5
        sheet.paste(img, (ix, iy))
        label_y = iy + img.height + 3
    except Exception:
        label_y = y + 5
        draw.text((x + 5, label_y), f"NO PNG: {name}", fill=(255, 100, 100), font=font)

    cat_color = CAT_COLORS.get(cat, (200, 200, 200))
    draw.text((x + 5, label_y), label, fill=cat_color, font=font)
    draw.text((x + 5, label_y + 14), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 5, label_y + 28), notes[:38], fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
print(f"Assets shown: {len(ASSETS)}")
