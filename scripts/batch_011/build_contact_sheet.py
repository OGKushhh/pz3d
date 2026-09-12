#!/usr/bin/env python3
"""Build contact sheet for batch 011 — 40 FINAL assets across all biomes.
Layout: 6 columns x 7 rows (40 + header)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (label, category, asset_name, tris, notes)
ASSETS = [
    # DOWNTOWN (6)
    ("hospital",            "buildings", "hospital",            4500, "3-story + red cross sign"),
    ("police_station",      "buildings", "police_station",      1200, "Brick + stone + flagpole"),
    ("highrise_office",     "buildings", "highrise_office",    500,  "12-story glass curtain wall"),
    ("parking_garage",      "buildings", "parking_garage",      600, "4-story concrete + ramps"),
    ("broadcast_tower",     "buildings", "broadcast_tower",    400, "40m lattice + aviation lights"),
    ("railway_station",     "buildings", "railway_station",    2800, "Brick + clock tower + canopy"),
    # FARMLAND (4)
    ("grain_silo",          "buildings", "grain_silo",         600, "4 silos + top platform"),
    ("windmill",            "buildings", "windmill",            768, "Dutch-style + 4 sails"),
    ("tractor_shed",        "buildings", "tractor_shed",       200, "Open-front metal shed"),
    ("farmhouse",           "buildings", "farmhouse",          2100, "2-story + wraparound porch"),
    # FOREST (4)
    ("hunting_cabin",       "buildings", "hunting_cabin",      700, "Log cabin + porch"),
    ("ranger_station",      "buildings", "ranger_station",     1200, "Wood + flagpole"),
    ("camping_tent",        "buildings", "camping_tent",       300, "Orange dome + rain fly"),
    ("deer_stand",          "buildings", "deer_stand",          400, "Elevated platform + ladder"),
    # RIVER / COASTAL (5)
    ("lighthouse",          "buildings", "lighthouse",         900, "Tapered tower + keeper's house"),
    ("fishing_hut",         "buildings", "fishing_hut",        500, "Stilts + dock + ladder"),
    ("pier_dock",           "buildings", "pier_dock",          400, "Pilings + railings + planks"),
    ("houseboat",           "buildings", "houseboat",          600, "Pontoon hull + cabin + deck"),
    ("bridge_section",      "buildings", "bridge_section",     500, "20m span + girders + piers"),
    # MILITARY (5)
    ("military_checkpoint", "buildings", "military_checkpoint", 1200, "Gate + jersey barriers + booths"),
    ("watchtower",          "buildings", "watchtower",         500, "5m tower + cabin + searchlight"),
    ("bunker_entrance",     "buildings", "bunker_entrance",    600, "Hillside + steel vault door"),
    ("helipad",             "buildings", "helipad",            300, "Circular pad + H + perim lights"),
    ("field_hospital_tent", "buildings", "field_hospital_tent", 700, "White medical + red cross"),
    # SUBWAY (4)
    ("subway_platform",     "buildings", "subway_platform",    1200, "Tile walls + yellow edge + rails"),
    ("subway_tunnel",       "buildings", "subway_tunnel",      600, "Curved tunnel + pipes + rails"),
    ("subway_train_car",    "buildings", "subway_train_car",   900, "Derelict + open doors + seats"),
    ("ticket_booth",        "buildings", "ticket_booth",      400, "Wood + service window + sign"),
    # COMMERCIAL (4)
    ("strip_mall",          "buildings", "strip_mall",        1800, "4 storefronts + 4 awnings"),
    ("auto_repair_shop",    "buildings", "auto_repair_shop",  1400, "3 roll-up bays + roof sign"),
    ("laundromat",          "buildings", "laundromat",        1200, "Storefront + washers visible"),
    ("barber_shop",         "buildings", "barber_shop",       1200, "Striped barber pole + awning"),
    # BACKYARD (1)
    ("treehouse",           "buildings", "treehouse",          900, "Platform around trunk + rope swing"),
    # ENVIRONMENT (5)
    ("campfire_ring",       "environment", "campfire_ring",     600, "8 stones + logs + embers"),
    ("barbed_wire_fence",   "environment", "barbed_wire_fence", 800, "5 posts + 3 wires + concertina"),
    ("turnstile",           "environment", "turnstile",         300, "3 arms + status lamps"),
    ("crop_field_corn",     "environment", "crop_field_corn",  2500, "5 rows of corn + cobs"),
    ("seesaw",              "environment", "seesaw",           300, "Beam + pivot + 2 seats"),
    # PROPS (2)
    ("basketball_hoop",     "props", "basketball_hoop",        400, "Pole + backboard + rim + net"),
    ("traffic_camera",      "props", "traffic_camera",          500, "Pole + housing + solar panel"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-12_tier1_batch-011_40_assets_FINAL_contact_sheet.png"

COLS = 6
ROWS = (len(ASSETS) + COLS - 1) // COLS  # 7 rows for 40 assets
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

draw.text((PAD, 8), "Mazar Alpha — Tier 1 Batch 011 (40 FINAL Assets)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 32), "33 buildings + 5 environment + 2 props. All biomes covered: Downtown, Farmland, Forest, River, Military, Subway, Commercial.", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 47), "Total library now: 182 GLBs (63 buildings + 50 props + 19 foliage + 50 environment).", fill=(160, 160, 160), font=font_sm)
draw.text((PAD, 62), "Categories: yellow=BUILDING, blue=PROP, green=FOLIAGE, orange=ENVIRONMENT", fill=(140, 140, 140), font=font_sm)

CAT_COLORS = {
    "buildings":   (255, 220, 100),
    "props":       (100, 180, 255),
    "foliage":     (140, 200, 140),
    "environment": (255, 180, 100),
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
    except Exception as e:
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
