#!/usr/bin/env python3
"""Build a 3x3 contact sheet of all 9 approved Tier 1 assets (batch 002)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    ("#1  suburban_house_v2",  "/home/z/my-project/assets/buildings/renders/suburban_house_v2_threequarter.png", 1800, "Door bug fixed — red door + garage door"),
    ("#2  office_chair",        "/home/z/my-project/assets/props/renders/office_chair.png", 6500, "5-star base + armrests"),
    ("#3  dining_table",       "/home/z/my-project/assets/props/renders/dining_table.png", 460, "4 legs + apron"),
    ("#4  oak_tree (fixed)",   "/home/z/my-project/assets/foliage/renders/oak_tree.png", 2400, "Cylinder trunk + 7-sphere canopy"),
    ("#5  bush",                "/home/z/my-project/assets/foliage/renders/bush.png", 360, "3 leaf clusters"),
    ("#6  sedan",               "/home/z/my-project/assets/vehicles/renders/sedan.png", 2000, "4-door + 4 wheels + lights"),
    ("#7  pickup_truck",        "/home/z/my-project/assets/vehicles/renders/pickup_truck.png", 1700, "Cab + open bed + 4 wheels"),
    ("#8  blood_splatter_decal","/home/z/my-project/assets/decals/renders/blood_splatter_decal.png", 2, "Flat plane for Godot Decal"),
    ("#9  asphalt_road_segment","/home/z/my-project/assets/environment/renders/asphalt_road_segment.png", 96, "10m road + curbs + sidewalks"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-002_all_9_contact_sheet.png"

COLS, ROWS = 3, 3
CELL_W, CELL_H = 500, 500
PAD = 20
LABEL_H = 70

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 80  # extra for title

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()
    font_title = ImageFont.load_default()

# Title
draw.text((PAD, 12), "Mazar Alpha — Tier 1 Style Anchors (Batch 002, ALL 9)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 42), "All built + VLM-verified. Reply: APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note>", fill=(160, 160, 160), font=font_sm)
draw.text((PAD, 60), "Note: 'fence' is also approved (asset #10, upstream example, 318 tris) — not shown here.", fill=(140, 140, 140), font=font_sm)

for i, (label, png_path, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 80 + PAD + row * (CELL_H + PAD)

    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    img = Image.open(png_path).convert("RGB")
    img.thumbnail((CELL_W - 20, CELL_H - LABEL_H - 20))
    ix = x + (CELL_W - img.width) // 2
    iy = y + 10
    sheet.paste(img, (ix, iy))

    label_y = iy + img.height + 8
    draw.text((x + 10, label_y), label, fill=(255, 220, 100), font=font)
    draw.text((x + 10, label_y + 22), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 10, label_y + 40), notes, fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
