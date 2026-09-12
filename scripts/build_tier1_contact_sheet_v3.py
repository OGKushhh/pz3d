#!/usr/bin/env python3
"""Build a 4x3 contact sheet of all 16 approved Tier 1 assets (batch 003).
Shows: 6 original approved + 10 new = 16 total. (Cars + blood splatter retired.)
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ASSETS = [
    # Original approved (batch 001 + 002)
    ("#1  suburban_house_v2",   "/home/z/my-project/assets/buildings/renders/suburban_house_v2_threequarter.png", 1800, "Door bug fixed"),
    ("#2  office_chair",         "/home/z/my-project/assets/props/renders/office_chair.png", 6500, "5-star base"),
    ("#3  dining_table",        "/home/z/my-project/assets/props/renders/dining_table.png", 460, "4 legs + apron"),
    ("#4  oak_tree",             "/home/z/my-project/assets/foliage/renders/oak_tree.png", 2400, "Cylinder trunk + 7-sphere canopy"),
    ("#5  bush",                  "/home/z/my-project/assets/foliage/renders/bush.png", 360, "3 leaf clusters"),
    ("#9  asphalt_road_segment","/home/z/my-project/assets/environment/renders/asphalt_road_segment.png", 96, "10m road + curbs + sidewalks"),
    # New (batch 003)
    ("#10 two_story_colonial",  "/home/z/my-project/assets/buildings/renders/two_story_colonial.png", 2600, "Colonial — 2 stories, shutters, chimney"),
    ("#11 bungalow",             "/home/z/my-project/assets/buildings/renders/bungalow.png", 2000, "Single-story, wide front porch"),
    ("#12 bookshelf",            "/home/z/my-project/assets/props/renders/bookshelf.png", 264, "Tall — 5 shelves + books (dynamic)"),
    ("#13 bed_single",           "/home/z/my-project/assets/props/renders/bed_single.png", 1600, "Frame + mattress + sheet + pillow (dynamic)"),
    ("#14 kitchen_counter",     "/home/z/my-project/assets/props/renders/kitchen_counter.png", 580, "L-shaped — stove + sink + cabinets (static)"),
    ("#15 refrigerator",         "/home/z/my-project/assets/props/renders/refrigerator.png", 496, "2-door — freezer + fridge (dynamic)"),
    ("#16 pine_tree",            "/home/z/my-project/assets/foliage/renders/pine_tree.png", 256, "Conifer — 3 cone layers"),
    ("#17 grass_tuft",           "/home/z/my-project/assets/foliage/renders/grass_tuft.png", 44, "6 blade quads — MultiMesh scatter"),
    ("#18 picket_fence",         "/home/z/my-project/assets/environment/renders/picket_fence.png", 168, "Suburban — 2 posts + 6 pickets"),
    ("#19 street_light",         "/home/z/my-project/assets/environment/renders/street_light.png", 504, "Pole + arm + lamp + point light"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-003_all_16_contact_sheet.png"

COLS, ROWS = 4, 4
CELL_W, CELL_H = 420, 420
PAD = 15
LABEL_H = 65

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 90

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

draw.text((PAD, 10), "Mazar Alpha — Tier 1 Style Anchors (Batch 003, ALL 16)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 38), "Cars + blood splatter RETIRED (external assets instead). 10 new assets added.", fill=(180, 180, 180), font=font_sm)
draw.text((PAD, 55), "Static = merged into room mesh. Dynamic = separate RigidBody3D (movable/throwable).", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 70), "Reply: APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note>", fill=(160, 160, 160), font=font_sm)

for i, (label, png_path, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 90 + PAD + row * (CELL_H + PAD)

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
