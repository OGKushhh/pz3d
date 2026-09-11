#!/usr/bin/env python3
"""Build contact sheet for batch 008 — 40 new MoGen assets.
6 columns x 7 rows (40 assets + header)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (label, category, asset_name, tris, notes)
ASSETS = [
    # BUILDINGS (5)
    ("warehouse",          "buildings", "warehouse",        1200, "Roll-up door + side door"),
    ("gas_station",        "buildings", "gas_station",      1000, "Canopy + 2 pumps + store"),
    ("school_elementary",  "buildings", "school_elementary", 3600, "2-story brick, many windows"),
    ("diner",              "buildings", "diner",            1000, "Retro stainless + neon sign"),
    ("church_small",       "buildings", "church_small",     1400, "Stone walls + steeple + cross"),
    # PROPS — DYNAMIC FURNITURE (10)
    ("nightstand",         "props", "nightstand",          144,  "1 drawer + lower shelf"),
    ("dresser",            "props", "dresser",              240,  "4 stacked drawers"),
    ("armchair",           "props", "armchair",             2200,  "1-seat, cushions, 4 legs"),
    ("stool",              "props", "stool",               576,   "Round seat + 4 legs + footring"),
    ("rug",                "props", "rug",                 108,   "Flat decorative floor rug"),
    ("picture_frame",      "props", "picture_frame",       120,   "Wall-mounted frame w/ artwork"),
    ("ceiling_lamp",       "props", "ceiling_lamp",        1200,  "Cord + shade + glowing bulb"),
    ("clock_wall",         "props", "clock_wall",          616,   "Analog clock face + 12 markers"),
    ("crate_wood",         "props", "crate_wood",          300,   "Slatted wood, lootable"),
    ("chair_dining",       "props", "chair_dining",        580,   "4 legs + slatted back"),
    # PROPS — STATIC FIXTURES (5)
    ("stove_freestanding", "props", "stove_freestanding",  1000,  "4 burners + oven door + knobs"),
    ("microwave",          "props", "microwave",           648,   "Door + control panel + handle"),
    ("radiator",           "props", "radiator",            356,   "Wall-mounted w/ 12 vertical fins"),
    ("fireplace",          "props", "fireplace",           328,   "Stone surround + mantel + logs"),
    ("stairs_wooden",      "props", "stairs_wooden",       228,   "6-step straight run + stringers"),
    # FOLIAGE (8)
    ("hedge",              "foliage", "hedge",             1600,  "Trimmed rectangular hedge"),
    ("weeds",              "foliage", "weeds",             96,    "Scatter ground cover (MultiMesh)"),
    ("fallen_log",         "foliage", "fallen_log",        544,   "1.5m log + end caps + moss"),
    ("rocks_small",        "foliage", "rocks_small",       560,   "3 rocks + 4 pebbles"),
    ("mushrooms",          "foliage", "mushrooms",          5300,  "3 mushrooms + leaf litter"),
    ("fern",               "foliage", "fern",              296,   "6 fronds from root base"),
    ("cattail",            "foliage", "cattail",           344,   "Wetland plant, 3 stalks + leaves"),
    ("palm_tree",          "foliage", "palm_tree",         5200,  "Coastal — trunk + 8 fronds + coconuts"),
    # ENVIRONMENT (12)
    ("chain_link_fence",   "environment", "chain_link_fence", 348, "2 posts + top rail + mesh"),
    ("wood_fence_post",    "environment", "wood_fence_post", 30,  "Single 4x4 wood post"),
    ("traffic_light",      "environment", "traffic_light",  380,  "3-light head on pole"),
    ("parking_meter",      "environment", "parking_meter",  776,  "Meter head + post + screen"),
    ("bench_park",         "environment", "bench_park",    216,  "Wooden slats + metal frame"),
    ("manhole_cover",      "environment", "manhole_cover", 448,  "Circular iron cover + ring"),
    ("sewer_grate",        "environment", "sewer_grate",   168,  "Rectangular grate w/ 7 bars"),
    ("bollard",            "environment", "bollard",       448,  "Yellow traffic bollard"),
    ("planter_box",        "environment", "planter_box",   452,  "Wood planter + dirt + plant"),
    ("power_pole",         "environment", "power_pole",    1700, "8m pole + 2 crossbeams + insulators"),
    ("barrier_concrete",   "environment", "barrier_concrete", 108, "Jersey barrier w/ reflective stripes"),
    ("sandbag",            "environment", "sandbag",       3800, "Stack of 3 sandbags + ties"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_batch-008_40_assets_contact_sheet.png"

COLS = 6
ROWS = (len(ASSETS) + COLS - 1) // COLS  # 40/6 = 7 rows
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

draw.text((PAD, 8), "Mazar Alpha — Tier 1 Batch 008 (40 NEW Assets)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 32), "5 buildings + 10 dynamic furniture + 5 static fixtures + 8 foliage + 12 environment", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 47), "All 40 built + rendered. VLM spot-check: 9/10 PASS (palm_tree flagged as too stylized).", fill=(160, 160, 160), font=font_sm)
draw.text((PAD, 62), "Categories color-coded: yellow=BUILDING, blue=PROP, green=FOLIAGE, orange=ENVIRONMENT", fill=(140, 140, 140), font=font_sm)

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
    img = Image.open(png_path).convert("RGB")
    img.thumbnail((CELL_W - 12, CELL_H - LABEL_H - 12))
    ix = x + (CELL_W - img.width) // 2
    iy = y + 5
    sheet.paste(img, (ix, iy))

    label_y = iy + img.height + 3
    cat_color = CAT_COLORS.get(cat, (200, 200, 200))
    draw.text((x + 5, label_y), label, fill=cat_color, font=font)
    draw.text((x + 5, label_y + 14), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 5, label_y + 28), notes[:38], fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
print(f"Assets shown: {len(ASSETS)}")
