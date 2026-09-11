#!/usr/bin/env python3
"""Build contact sheet for batch 007 — 46 approved assets (18 new + 28 previous).
5 columns x 10 rows."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    # Previous batches (28)
    ("#1  suburban_house_v2",     "buildings", "suburban_house_v2_threequarter", 1800, "Door bug fixed"),
    ("#2  office_chair",           "props",     "office_chair", 6500, "5-star base"),
    ("#3  dining_table",          "props",     "dining_table", 460, "4 legs + apron"),
    ("#4  oak_tree",               "foliage",   "oak_tree", 2400, "7-sphere canopy"),
    ("#5  bush",                    "foliage",   "bush", 360, "3 leaf clusters"),
    ("#9  asphalt_road_segment",  "environment","asphalt_road_segment", 96, "10m road"),
    ("#10 two_story_colonial",    "buildings", "two_story_colonial", 2600, "3 rooms upstairs"),
    ("#11 bungalow",               "buildings", "bungalow", 2000, "Wide front porch"),
    ("#12 bookshelf",              "props",     "bookshelf", 264, "Books face camera"),
    ("#13 bed_single",             "props",     "bed_single", 1600, "Frame + mattress"),
    ("#15 refrigerator",           "props",     "refrigerator", 412, "2-door simplified"),
    ("#16 pine_tree",              "foliage",   "pine_tree", 256, "3 cone layers"),
    ("#18 picket_fence",           "environment","picket_fence", 168, "6 pickets"),
    ("#19 street_light",           "environment","street_light", 504, "Pole + arm + lamp"),
    ("#20 kitchen_sink_unit",     "props",     "kitchen_sink_unit", 172, "Modular #1"),
    ("#21 kitchen_stove_unit",    "props",     "kitchen_stove_unit", 416, "Modular #2"),
    ("#22 kitchen_empty_counter","props",     "kitchen_empty_counter", 120, "Modular #3"),
    ("#23 kitchen_wall_cabinet", "props",     "kitchen_wall_cabinet", 60, "Modular #4"),
    ("#24 shed",                    "buildings", "shed", 1000, "Storage, gable roof"),
    ("#25 garage_detached",        "buildings", "garage_detached", 1300, "1-car garage"),
    ("#26 sofa",                    "props",     "sofa", 3300, "3-seat, dynamic"),
    ("#27 coffee_table",           "props",     "coffee_table", 424, "Low + shelf"),
    ("#28 toilet",                  "props",     "toilet", 996, "Bathroom static"),
    ("#29 bathtub",                "props",     "bathtub", 280, "Bathroom static"),
    ("#30 mailbox",                "environment","mailbox", 1200, "Curbside, red flag"),
    ("#31 trash_can",              "environment","trash_can", 1200, "Cylindrical"),
    ("#32 birch_tree",             "foliage",   "birch_tree", 2500, "FIXED: random canopy"),
    ("#33 brick_wall_segment",    "environment","brick_wall_segment", 120, "Property boundary"),
    # NEW batch 007 (18)
    ("#34 corner_store",          "buildings", "corner_store", 736, "NEW: storefront + awning"),
    ("#35 cottage",                "buildings", "cottage", 1700, "NEW: stone walls, rural"),
    ("#36 apartment_small",       "buildings", "apartment_small", 3600, "NEW: 2-story, balcony"),
    ("#37 desk",                    "props",     "desk", 520, "NEW: writing desk + drawers"),
    ("#38 lamp_floor",             "props",     "lamp_floor", 352, "NEW: floor lamp + light"),
    ("#39 tv",                      "props",     "tv", 572, "NEW: CRT TV, lootable"),
    ("#40 wardrobe",                "props",     "wardrobe", 192, "NEW: 2 doors + mirror"),
    ("#41 sink_bathroom",          "props",     "sink_bathroom", 728, "NEW: pedestal sink"),
    ("#42 door_interior",          "props",     "door_interior", 896, "NEW: closed interior door"),
    ("#43 dead_tree",              "foliage",   "dead_tree", 336, "NEW: bare branches"),
    ("#44 flower_patch",           "foliage",   "flower_patch", 740, "NEW: 5 colored flowers"),
    ("#45 fire_hydrant",           "environment","fire_hydrant", 448, "NEW: red, 2 side outlets"),
    ("#46 dumpster",                "environment","dumpster", 240, "NEW: green, open lid"),
    ("#47 traffic_cone",           "environment","traffic_cone", 140, "NEW: orange + stripe"),
    ("#48 road_sign",              "environment","road_sign", 84, "NEW: diamond panel"),
    ("#49 dirt_road_segment",     "environment","dirt_road_segment", 60, "NEW: rural dirt path"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-007_45_assets_contact_sheet.png"

COLS = 5
ROWS = (len(ASSETS) + COLS - 1) // COLS  # 45/5 = 9 rows
CELL_W, CELL_H = 340, 310
PAD = 10
LABEL_H = 55

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 90

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 9)
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 17)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()
    font_title = ImageFont.load_default()

draw.text((PAD, 8), "Mazar Alpha — Tier 1 Style Anchors (Batch 007, 45 assets)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 30), "17 NEW: 3 buildings + 6 props + 2 foliage + 5 environment + birch tree FIX (atom → natural)", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 45), "Reply: APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note>", fill=(160, 160, 160), font=font_sm)
draw.text((PAD, 60), "fence.mog (upstream, 318 tris) also approved — not shown.", fill=(140, 140, 140), font=font_sm)

for i, (label, cat, name, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 75 + PAD + row * (CELL_H + PAD)

    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    png_path = f"/home/z/my-project/assets/{cat}/renders/{name}.png"
    img = Image.open(png_path).convert("RGB")
    img.thumbnail((CELL_W - 12, CELL_H - LABEL_H - 12))
    ix = x + (CELL_W - img.width) // 2
    iy = y + 5
    sheet.paste(img, (ix, iy))

    label_y = iy + img.height + 3
    draw.text((x + 5, label_y), label, fill=(255, 220, 100), font=font)
    draw.text((x + 5, label_y + 16), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 5, label_y + 30), notes, fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
print(f"Assets shown: {len(ASSETS)}")
