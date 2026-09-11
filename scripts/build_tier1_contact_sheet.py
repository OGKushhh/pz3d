#!/usr/bin/env python3
"""Build a 2x3 contact sheet of all 5 approved Tier 1 assets so far.
Saves to /home/z/my-project/download/asset-batches/
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (label, png_path, tris, notes)
ASSETS = [
    ("#1  suburban_house_v2",  "/home/z/my-project/assets/buildings/renders/suburban_house_v2_threequarter.png", 1800, "DOOR BUG FIXED — red door + garage door visible"),
    ("#2  office_chair",         "/home/z/my-project/assets/props/renders/office_chair.png", 6500, "5-star base, gas cylinder, armrests"),
    ("#3  dining_table",        "/home/z/my-project/assets/props/renders/dining_table.png", 460, "Rectangular top + 4 legs + apron"),
    ("#4  oak_tree",             "/home/z/my-project/assets/foliage/renders/oak_tree.png", 2700, "Branch-primitive trunk + 4-sphere canopy"),
    ("#5  bush",                  "/home/z/my-project/assets/foliage/renders/bush.png", 360, "3 leaf clusters + 2 twigs"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-001_contact_sheet.png"

# Layout: 2 columns x 3 rows (last cell empty / notes)
COLS, ROWS = 2, 3
CELL_W, CELL_H = 600, 600  # each cell holds a 512x512 image + label area
PAD = 20
LABEL_H = 60

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

# Try to load a font
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()

# Title
title = "Mazar Alpha — Tier 1 Style Anchors (Batch 001)"
draw.text((PAD, 8), title, fill=(230, 230, 230), font=font)
subtitle = "5 of 10 style anchors produced. Reply: APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note>"
draw.text((PAD, 32), subtitle, fill=(160, 160, 160), font=font_sm)

for i, (label, png_path, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = PAD + 60 + row * (CELL_H + PAD)

    # Cell background
    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    # Image
    img = Image.open(png_path).convert("RGB")
    img.thumbnail((CELL_W - 20, CELL_H - LABEL_H - 20))
    ix = x + (CELL_W - img.width) // 2
    iy = y + 10
    sheet.paste(img, (ix, iy))

    # Label
    label_y = iy + img.height + 8
    draw.text((x + 10, label_y), label, fill=(255, 220, 100), font=font)
    draw.text((x + 10, label_y + 22), f"{tris} tris", fill=(140, 200, 140), font=font_sm)
    draw.text((x + 10, label_y + 40), notes, fill=(180, 180, 180), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
