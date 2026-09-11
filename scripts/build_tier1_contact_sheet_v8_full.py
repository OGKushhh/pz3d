#!/usr/bin/env python3
"""Build a big contact sheet showing ALL 84 approved assets (44 previous + 40 new).
6 columns x 14 rows = 84 slots."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# All 84 assets: (label, category, render_name, tris, notes)
ASSETS = [
    # Previous batches (44)
    ("#1  suburban_house_v2", "buildings", "suburban_house_v2_threequarter", 1800, ""),
    ("#2  office_chair", "props", "office_chair", 6500, ""),
    ("#3  dining_table", "props", "dining_table", 460, ""),
    ("#4  oak_tree", "foliage", "oak_tree", 2400, ""),
    ("#5  bush", "foliage", "bush", 360, ""),
    ("#9  asphalt_road", "environment", "asphalt_road_segment", 96, ""),
    ("#10 colonial", "buildings", "two_story_colonial", 2600, ""),
    ("#11 bungalow", "buildings", "bungalow", 2000, ""),
    ("#12 bookshelf", "props", "bookshelf", 264, ""),
    ("#13 bed_single", "props", "bed_single", 1600, ""),
    ("#15 refrigerator", "props", "refrigerator", 412, ""),
    ("#16 pine_tree", "foliage", "pine_tree", 256, ""),
    ("#18 picket_fence", "environment", "picket_fence", 168, ""),
    ("#19 street_light", "environment", "street_light", 504, ""),
    ("#20 kitchen_sink", "props", "kitchen_sink_unit", 172, ""),
    ("#21 kitchen_stove", "props", "kitchen_stove_unit", 416, ""),
    ("#22 kitchen_empty", "props", "kitchen_empty_counter", 120, ""),
    ("#23 wall_cabinet", "props", "kitchen_wall_cabinet", 60, ""),
    ("#24 shed", "buildings", "shed", 1000, ""),
    ("#25 garage", "buildings", "garage_detached", 1300, ""),
    ("#26 sofa", "props", "sofa", 3300, ""),
    ("#27 coffee_table", "props", "coffee_table", 424, ""),
    ("#28 toilet", "props", "toilet", 996, ""),
    ("#29 bathtub", "props", "bathtub", 280, ""),
    ("#30 mailbox", "environment", "mailbox", 1200, ""),
    ("#31 trash_can", "environment", "trash_can", 1200, ""),
    ("#32 birch_tree", "foliage", "birch_tree", 2500, ""),
    ("#33 brick_wall", "environment", "brick_wall_segment", 120, ""),
    ("#34 corner_store", "buildings", "corner_store", 736, ""),
    ("#35 cottage", "buildings", "cottage", 1700, ""),
    ("#36 apartment", "buildings", "apartment_small", 3600, ""),
    ("#37 desk", "props", "desk", 520, ""),
    ("#38 lamp_floor", "props", "lamp_floor", 352, ""),
    ("#39 tv", "props", "tv", 572, ""),
    ("#40 wardrobe", "props", "wardrobe", 192, ""),
    ("#41 sink_bath", "props", "sink_bathroom", 728, ""),
    ("#42 door_interior", "props", "door_interior", 896, ""),
    ("#43 dead_tree", "foliage", "dead_tree", 6600, ""),
    ("#44 flower_patch", "foliage", "flower_patch", 740, ""),
    ("#45 fire_hydrant", "environment", "fire_hydrant", 448, ""),
    ("#46 dumpster", "environment", "dumpster", 240, ""),
    ("#47 traffic_cone", "environment", "traffic_cone", 60, ""),
    ("#48 road_sign", "environment", "road_sign", 36, ""),
    ("#49 dirt_road", "environment", "dirt_road_segment", 60, ""),
    # NEW batch 008 (40)
    ("#50 warehouse", "buildings", "warehouse", 0, "NEW"),
    ("#51 gas_station", "buildings", "gas_station", 0, "NEW"),
    ("#52 school", "buildings", "school_elementary", 0, "NEW"),
    ("#53 diner", "buildings", "diner", 0, "NEW"),
    ("#54 church", "buildings", "church_small", 0, "NEW"),
    ("#55 nightstand", "props", "nightstand", 0, "NEW"),
    ("#56 dresser", "props", "dresser", 0, "NEW"),
    ("#57 armchair", "props", "armchair", 0, "NEW"),
    ("#58 stool", "props", "stool", 0, "NEW"),
    ("#59 rug", "props", "rug", 0, "NEW"),
    ("#60 picture_frame", "props", "picture_frame", 0, "NEW"),
    ("#61 ceiling_lamp", "props", "ceiling_lamp", 0, "NEW"),
    ("#62 clock_wall", "props", "clock_wall", 0, "NEW"),
    ("#63 crate_wood", "props", "crate_wood", 0, "NEW"),
    ("#64 chair_dining", "props", "chair_dining", 0, "NEW"),
    ("#65 stove_free", "props", "stove_freestanding", 0, "NEW"),
    ("#66 microwave", "props", "microwave", 0, "NEW"),
    ("#67 radiator", "props", "radiator", 0, "NEW"),
    ("#68 fireplace", "props", "fireplace", 0, "NEW"),
    ("#69 stairs_wood", "props", "stairs_wooden", 0, "NEW"),
    ("#70 hedge", "foliage", "hedge", 0, "NEW"),
    ("#71 weeds", "foliage", "weeds", 0, "NEW"),
    ("#72 fallen_log", "foliage", "fallen_log", 0, "NEW"),
    ("#73 rocks_small", "foliage", "rocks_small", 0, "NEW"),
    ("#74 mushrooms", "foliage", "mushrooms", 0, "NEW"),
    ("#75 fern", "foliage", "fern", 0, "NEW"),
    ("#76 cattail", "foliage", "cattail", 0, "NEW"),
    ("#77 palm_tree", "foliage", "palm_tree", 0, "NEW"),
    ("#78 chain_link", "environment", "chain_link_fence", 0, "NEW"),
    ("#79 fence_post", "environment", "wood_fence_post", 0, "NEW"),
    ("#80 traffic_light", "environment", "traffic_light", 0, "NEW"),
    ("#81 parking_meter", "environment", "parking_meter", 0, "NEW"),
    ("#82 bench_park", "environment", "bench_park", 0, "NEW"),
    ("#83 manhole", "environment", "manhole_cover", 0, "NEW"),
    ("#84 sewer_grate", "environment", "sewer_grate", 0, "NEW"),
    ("#85 bollard", "environment", "bollard", 0, "NEW"),
    ("#86 planter_box", "environment", "planter_box", 0, "NEW"),
    ("#87 power_pole", "environment", "power_pole", 0, "NEW"),
    ("#88 barrier", "environment", "barrier_concrete", 0, "NEW"),
    ("#89 sandbag", "environment", "sandbag", 0, "NEW"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "2026-09-11_tier1_anchors_batch-008_84_assets_FULL_contact_sheet.png"

COLS = 6
ROWS = (len(ASSETS) + COLS - 1) // COLS  # 84/6 = 14 rows
CELL_W, CELL_H = 280, 260
PAD = 8
LABEL_H = 45

sheet_w = COLS * (CELL_W + PAD) + PAD
sheet_h = ROWS * (CELL_H + PAD) + PAD + 80

sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
draw = ImageDraw.Draw(sheet)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 11)
    font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 8)
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
except Exception:
    font = ImageFont.load_default()
    font_sm = ImageFont.load_default()
    font_title = ImageFont.load_default()

draw.text((PAD, 6), "Mazar Alpha — ALL Tier 1 Assets (Batch 008, 84 total)", fill=(255, 220, 100), font=font_title)
draw.text((PAD, 26), "44 previous + 40 NEW (5 buildings, 15 props, 8 foliage, 12 environment)", fill=(140, 200, 140), font=font_sm)
draw.text((PAD, 40), "fence.mog (upstream, 318 tris) also approved — not shown.", fill=(140, 140, 140), font=font_sm)
draw.text((PAD, 54), "Reply: APPROVE ALL / APPROVE EXCEPT <ids> / REGEN <ids> WITH <note>", fill=(160, 160, 160), font=font_sm)

for i, (label, cat, name, tris, notes) in enumerate(ASSETS):
    col = i % COLS
    row = i // COLS
    x = PAD + col * (CELL_W + PAD)
    y = 65 + PAD + row * (CELL_H + PAD)

    draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

    png_path = f"/home/z/my-project/assets/{cat}/renders/{name}.png"
    try:
        img = Image.open(png_path).convert("RGB")
        img.thumbnail((CELL_W - 10, CELL_H - LABEL_H - 10))
        ix = x + (CELL_W - img.width) // 2
        iy = y + 4
        sheet.paste(img, (ix, iy))
    except:
        draw.text((x + 10, y + 80), "MISSING", fill=(200, 80, 80), font=font)

    label_y = y + CELL_H - LABEL_H + 5
    draw.text((x + 4, label_y), label, fill=(255, 220, 100), font=font)
    if notes == "NEW":
        draw.text((x + 4, label_y + 14), "NEW", fill=(140, 200, 140), font=font_sm)
    else:
        draw.text((x + 4, label_y + 14), f"{tris} tris", fill=(140, 200, 140), font=font_sm)

sheet.save(OUT_PATH, "PNG")
print(f"Contact sheet saved: {OUT_PATH}")
print(f"Size: {sheet_w}x{sheet_h}")
print(f"Bytes: {OUT_PATH.stat().st_size}")
print(f"Assets shown: {len(ASSETS)}")
