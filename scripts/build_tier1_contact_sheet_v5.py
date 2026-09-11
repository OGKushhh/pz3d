#!/usr/bin/env python3
"""Build a 4x5 contact sheet of all 18 approved Tier 1 assets (batch 005).
Includes 4 new modular kitchen pieces. Retired: cars, blood splatter, grass tuft, unified kitchen_counter.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    ("#1  suburban_house_v2",     "/home/z/my-project/assets/buildings/renders/suburban_house_v2_threequarter.png", 1800, "Door bug fixed"),
    ("#2  office_chair",           "/home/z/my-project/assets/props/renders/office_chair.png", 6500, "5-star base"),
    ("#3  dining_table",          "/home/z/my-project/assets/props/renders/dining_table.png", 460, "4 legs + apron"),
    ("#4  oak_tree",               "/home/z/my-project/assets/foliage/renders/oak_tree.png", 2400, "Cylinder trunk + 7-sphere canopy"),
    ("#5  bush",                    "/home/z/my-project/assets/foliage/renders/bush.png", 360, "3 leaf clusters"),
    ("#9  asphalt_road_segment",  "/home/z/my-project/assets/environment/renders/asphalt_road_segment.png", 96, "10m road + curbs + sidewalks"),
    ("#10 two_story_colonial",    "/home/z/my-project/assets/buildings/renders/two_story_colonial.png", 2600, "3 windows top = 3 rooms (2 bed + 1 bath)"),
    ("#11 bungalow",               "/home/z/my-project/assets/buildings/renders/bungalow.png", 2000, "Wide front porch"),
    ("#12 bookshelf",              "/home/z/my-project/assets/props/renders/bookshelf.png", 264, "Books face camera"),
    ("#13 bed_single",             "/home/z/my-project/assets/props/renders/bed_single.png", 1600, "Approved (minor disconnect, accepted)"),
    ("#15 refrigerator",           "/home/z/my-project/assets/props/renders/refrigerator.png", 412, "Simplified — body + 2 doors"),
    ("#16 pine_tree",              "/home/z/my-project/assets/foliage/renders/pine_tree.png", 256, "3 cone layers"),
    ("#18 picket_fence",           "/home/z/my-project/assets/environment/renders/picket_fence.png", 168, "2 posts + 6 pickets"),
    ("#19 street_light",           "/home/z/my-project/assets/environment/renders/street_light.png", 504, "Pole + arm + lamp + light"),
    # NEW: 4 modular kitchen pieces
    ("#20 kitchen_sink_unit",     "/home/z/my-project/assets/props/renders/kitchen_sink_unit.png", 172, "NEW: counter + sink + faucet (modular)"),
    ("#21 kitchen_stove_unit",    "/home/z/my-project/assets/props/renders/kitchen_stove_unit.png", 416, "NEW: 4 burners + oven (modular)"),
    ("#22 kitchen_empty_counter", "/home/z/my-project/assets/props/renders/kitchen_empty_counter.png", 120, "NEW: plain counter + 2 cabinets (modular)"),
    ("#23 kitchen_wall_cabinet",  "/home/z/my-project/assets/props/renders/kitchen_wall_cabinet.png", 60, "NEW: wall-mounted cabinet above counter"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-005_modular_kitchen_contact_sheet.png"

COLS, ROWS = 4, 5  # 19 assets → 5 rows (last row has 3)
CELL_W, CELL_H = 420, 360
PAD = 15
LABEL_H = 65

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 110

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()
    font_title = ImageFont.load_default()

draw.text((PAD, 10), "Mazar Alpha — Tier 1 Style Anchors (Batch 005 — Modular Kitchen)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 38), "Kitchen counter SPLIT into 4 modular pieces (PZ-style): sink_unit + stove_unit + empty_counter + wall_cabinet.", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 55), "Place side-by-side to form any kitchen layout. More flexible than fixed L-shape.", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 72), "RETIRED: unified kitchen_counter (#14). Cars, blood splatter, grass tuft still retired.", fill=(200, 140, 140), font=font_sm)
draw.text((PAD, 89), "18 active assets + 1 upstream fence. Reply: APPROVE ALL / APPROVE EXCEPT <ids>", fill=(160, 160, 160), font=font_sm)

for i, (label, png_path, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 105 + PAD + row * (CELL_H + PAD)

    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    img = Image.open(png_path).convert("RGB")
    img.thumbnail((CELL_W - 16, CELL_H - LABEL_H - 16))
    ix = x + (CELL_W - img.width) // 2
    iy = y + 8
    sheet.paste(img, (ix, iy))

    label_y = iy + img.height + 6
    draw.text((x + 8, label_y), label, fill=(255, 220, 100), font=font)
    draw.text((x + 8, label_y + 20), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 8, label_y + 36), notes, fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
