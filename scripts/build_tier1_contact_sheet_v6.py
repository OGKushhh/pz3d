#!/usr/bin/env python3
"""Build contact sheet for batch 006 — 28 approved assets (10 new + 18 previous).
4 columns x 7 rows."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    # Original + batch 003-005 (18)
    ("#1  suburban_house_v2",     "/home/z/my-project/assets/buildings/renders/suburban_house_v2_threequarter.png", 1800, "Door bug fixed"),
    ("#2  office_chair",           "/home/z/my-project/assets/props/renders/office_chair.png", 6500, "5-star base"),
    ("#3  dining_table",          "/home/z/my-project/assets/props/renders/dining_table.png", 460, "4 legs + apron"),
    ("#4  oak_tree",               "/home/z/my-project/assets/foliage/renders/oak_tree.png", 2400, "7-sphere canopy"),
    ("#5  bush",                    "/home/z/my-project/assets/foliage/renders/bush.png", 360, "3 leaf clusters"),
    ("#9  asphalt_road_segment",  "/home/z/my-project/assets/environment/renders/asphalt_road_segment.png", 96, "10m road + curbs"),
    ("#10 two_story_colonial",    "/home/z/my-project/assets/buildings/renders/two_story_colonial.png", 2600, "3 rooms upstairs"),
    ("#11 bungalow",               "/home/z/my-project/assets/buildings/renders/bungalow.png", 2000, "Wide front porch"),
    ("#12 bookshelf",              "/home/z/my-project/assets/props/renders/bookshelf.png", 264, "Books face camera"),
    ("#13 bed_single",             "/home/z/my-project/assets/props/renders/bed_single.png", 1600, "Frame + mattress"),
    ("#15 refrigerator",           "/home/z/my-project/assets/props/renders/refrigerator.png", 412, "2-door simplified"),
    ("#16 pine_tree",              "/home/z/my-project/assets/foliage/renders/pine_tree.png", 256, "3 cone layers"),
    ("#18 picket_fence",           "/home/z/my-project/assets/environment/renders/picket_fence.png", 168, "6 pickets + caps"),
    ("#19 street_light",           "/home/z/my-project/assets/environment/renders/street_light.png", 504, "Pole + arm + lamp"),
    ("#20 kitchen_sink_unit",     "/home/z/my-project/assets/props/renders/kitchen_sink_unit.png", 172, "Modular kitchen #1"),
    ("#21 kitchen_stove_unit",    "/home/z/my-project/assets/props/renders/kitchen_stove_unit.png", 416, "Modular kitchen #2"),
    ("#22 kitchen_empty_counter","/home/z/my-project/assets/props/renders/kitchen_empty_counter.png", 120, "Modular kitchen #3"),
    ("#23 kitchen_wall_cabinet", "/home/z/my-project/assets/props/renders/kitchen_wall_cabinet.png", 60, "Modular kitchen #4"),
    # NEW batch 006 (10)
    ("#24 shed",                    "/home/z/my-project/assets/buildings/renders/shed.png", 1000, "NEW: storage shed, gable roof"),
    ("#25 garage_detached",        "/home/z/my-project/assets/buildings/renders/garage_detached.png", 1300, "NEW: 1-car garage, roll-up door"),
    ("#26 sofa",                    "/home/z/my-project/assets/props/renders/sofa.png", 3300, "NEW: 3-seat, dynamic"),
    ("#27 coffee_table",           "/home/z/my-project/assets/props/renders/coffee_table.png", 424, "NEW: low table + shelf"),
    ("#28 toilet",                  "/home/z/my-project/assets/props/renders/toilet.png", 996, "NEW: bathroom fixture (static)"),
    ("#29 bathtub",                "/home/z/my-project/assets/props/renders/bathtub.png", 280, "NEW: bathroom fixture (static)"),
    ("#30 mailbox",                "/home/z/my-project/assets/environment/renders/mailbox.png", 1200, "NEW: curbside, red flag"),
    ("#31 trash_can",              "/home/z/my-project/assets/environment/renders/trash_can.png", 1200, "NEW: outdoor, cylindrical"),
    ("#32 birch_tree",             "/home/z/my-project/assets/foliage/renders/birch_tree.png", 1800, "NEW: white bark, narrow"),
    ("#33 brick_wall_segment",    "/home/z/my-project/assets/environment/renders/brick_wall_segment.png", 120, "NEW: property boundary"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-006_28_assets_contact_sheet.png"

COLS, ROWS = 4, 8  # 28 assets → 7 rows full + 0 extra = 7 rows. Use 8 to leave room.
# Actually 28 / 4 = 7 rows exactly. Use 7.
ROWS = 7
CELL_W, CELL_H = 380, 340
PAD = 12
LABEL_H = 60

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 100

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 10)
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()
    font_title = ImageFont.load_default()

draw.text((PAD, 8), "Mazar Alpha — Tier 1 Style Anchors (Batch 006, 28 assets)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 32), "10 NEW: shed, garage, sofa, coffee_table, toilet, bathtub, mailbox, trash_can, birch_tree, brick_wall", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 48), "Reply: APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note>", fill=(160, 160, 160), font=font_sm)
draw.text((PAD, 64), "fence.mog (upstream, 318 tris) also approved — not shown.", fill=(140, 140, 140), font=font_sm)

for i, (label, png_path, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 80 + PAD + row * (CELL_H + PAD)

    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    img = Image.open(png_path).convert("RGB")
    img.thumbnail((CELL_W - 14, CELL_H - LABEL_H - 14))
    ix = x + (CELL_W - img.width) // 2
    iy = y + 6
    sheet.paste(img, (ix, iy))

    label_y = iy + img.height + 4
    draw.text((x + 6, label_y), label, fill=(255, 220, 100), font=font)
    draw.text((x + 6, label_y + 18), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 6, label_y + 32), notes, fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
