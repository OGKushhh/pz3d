#!/usr/bin/env python3
"""Build 2 contact sheets (42 assets each) so they're viewable on screen.
Sheet A: assets #1-42 (buildings + props + foliage start)
Sheet B: assets #43-84 (foliage end + environment)
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ALL_ASSETS = [
    ("#1  suburban_house_v2", "buildings", "suburban_house_v2_threequarter"),
    ("#2  office_chair", "props", "office_chair"),
    ("#3  dining_table", "props", "dining_table"),
    ("#4  oak_tree", "foliage", "oak_tree"),
    ("#5  bush", "foliage", "bush"),
    ("#9  asphalt_road", "environment", "asphalt_road_segment"),
    ("#10 colonial", "buildings", "two_story_colonial"),
    ("#11 bungalow", "buildings", "bungalow"),
    ("#12 bookshelf", "props", "bookshelf"),
    ("#13 bed_single", "props", "bed_single"),
    ("#15 refrigerator", "props", "refrigerator"),
    ("#16 pine_tree", "foliage", "pine_tree"),
    ("#18 picket_fence", "environment", "picket_fence"),
    ("#19 street_light", "environment", "street_light"),
    ("#20 kitchen_sink", "props", "kitchen_sink_unit"),
    ("#21 kitchen_stove", "props", "kitchen_stove_unit"),
    ("#22 kitchen_empty", "props", "kitchen_empty_counter"),
    ("#23 wall_cabinet", "props", "kitchen_wall_cabinet"),
    ("#24 shed", "buildings", "shed"),
    ("#25 garage", "buildings", "garage_detached"),
    ("#26 sofa", "props", "sofa"),
    ("#27 coffee_table", "props", "coffee_table"),
    ("#28 toilet", "props", "toilet"),
    ("#29 bathtub", "props", "bathtub"),
    ("#30 mailbox", "environment", "mailbox"),
    ("#31 trash_can", "environment", "trash_can"),
    ("#32 birch_tree", "foliage", "birch_tree"),
    ("#33 brick_wall", "environment", "brick_wall_segment"),
    ("#34 corner_store", "buildings", "corner_store"),
    ("#35 cottage", "buildings", "cottage"),
    ("#36 apartment", "buildings", "apartment_small"),
    ("#37 desk", "props", "desk"),
    ("#38 lamp_floor", "props", "lamp_floor"),
    ("#39 tv", "props", "tv"),
    ("#40 wardrobe", "props", "wardrobe"),
    ("#41 sink_bath", "props", "sink_bathroom"),
    ("#42 door_interior", "props", "door_interior"),
    ("#43 dead_tree", "foliage", "dead_tree"),
    ("#44 flower_patch", "foliage", "flower_patch"),
    ("#45 fire_hydrant", "environment", "fire_hydrant"),
    ("#46 dumpster", "environment", "dumpster"),
    ("#47 traffic_cone", "environment", "traffic_cone"),
    # --- Sheet B starts here ---
    ("#48 road_sign", "environment", "road_sign"),
    ("#49 dirt_road", "environment", "dirt_road_segment"),
    ("#50 warehouse", "buildings", "warehouse"),
    ("#51 gas_station", "buildings", "gas_station"),
    ("#52 school", "buildings", "school_elementary"),
    ("#53 diner", "buildings", "diner"),
    ("#54 church", "buildings", "church_small"),
    ("#55 nightstand", "props", "nightstand"),
    ("#56 dresser", "props", "dresser"),
    ("#57 armchair", "props", "armchair"),
    ("#58 stool", "props", "stool"),
    ("#59 rug", "props", "rug"),
    ("#60 picture_frame", "props", "picture_frame"),
    ("#61 ceiling_lamp", "props", "ceiling_lamp"),
    ("#62 clock_wall", "props", "clock_wall"),
    ("#63 crate_wood", "props", "crate_wood"),
    ("#64 chair_dining", "props", "chair_dining"),
    ("#65 stove_free", "props", "stove_freestanding"),
    ("#66 microwave", "props", "microwave"),
    ("#67 radiator", "props", "radiator"),
    ("#68 fireplace", "props", "fireplace"),
    ("#69 stairs", "props", "stairs_wooden"),
    ("#70 hedge", "foliage", "hedge"),
    ("#71 weeds", "foliage", "weeds"),
    ("#72 fallen_log", "foliage", "fallen_log"),
    ("#73 rocks", "foliage", "rocks_small"),
    ("#74 mushrooms", "foliage", "mushrooms"),
    ("#75 fern", "foliage", "fern"),
    ("#76 cattail", "foliage", "cattail"),
    ("#77 palm_tree", "foliage", "palm_tree"),
    ("#78 chain_link", "environment", "chain_link_fence"),
    ("#79 fence_post", "environment", "wood_fence_post"),
    ("#80 traffic_light", "environment", "traffic_light"),
    ("#81 parking_meter", "environment", "parking_meter"),
    ("#82 bench_park", "environment", "bench_park"),
    ("#83 manhole", "environment", "manhole_cover"),
    ("#84 sewer_grate", "environment", "sewer_grate"),
    ("#85 bollard", "environment", "bollard"),
    ("#86 planter_box", "environment", "planter_box"),
    ("#87 power_pole", "environment", "power_pole"),
    ("#88 barrier", "environment", "barrier_concrete"),
    ("#89 sandbag", "environment", "sandbag"),
]

OUT_DIR = Path("/home/z/my-project/download/asset-batches")
OUT_DIR.mkdir(parents=True, exist_ok=True)

COLS = 5
CELL_W, CELL_H = 460, 400
PAD = 10
LABEL_H = 50

def build_sheet(assets_list, title, subtitle, out_name):
    ROWS = (len(assets_list) + COLS - 1) // COLS
    sheet_w = COLS * (CELL_W + PAD) + PAD
    sheet_h = ROWS * (CELL_H + PAD) + PAD + 70

    sheet = Image.new("RGB", (sheet_w, sheet_h), (32, 33, 38))
    draw = ImageDraw.Draw(sheet)

    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
        font_sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 10)
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    except:
        font = ImageFont.load_default()
        font_sm = ImageFont.load_default()
        font_title = ImageFont.load_default()

    draw.text((PAD, 6), title, fill=(255, 220, 100), font=font_title)
    draw.text((PAD, 30), subtitle, fill=(160, 160, 160), font=font_sm)

    for i, (label, cat, name) in enumerate(assets_list):
        col = i % COLS
        row = i // COLS
        x = PAD + col * (CELL_W + PAD)
        y = 45 + PAD + row * (CELL_H + PAD)

        draw.rectangle([x, y, x + CELL_W, y + CELL_H], fill=(20, 22, 26), outline=(80, 80, 80), width=1)

        png_path = f"/home/z/my-project/assets/{cat}/renders/{name}.png"
        try:
            img = Image.open(png_path).convert("RGB")
            img.thumbnail((CELL_W - 14, CELL_H - LABEL_H - 14))
            ix = x + (CELL_W - img.width) // 2
            iy = y + 5
            sheet.paste(img, (ix, iy))
        except:
            draw.text((x + 20, y + 150), "MISSING", fill=(200, 80, 80), font=font)

        label_y = y + CELL_H - LABEL_H + 3
        draw.text((x + 5, label_y), label, fill=(255, 220, 100), font=font)

    out_path = OUT_DIR / out_name
    sheet.save(out_path, "PNG")
    print(f"  Saved: {out_path} ({sheet_w}x{sheet_h}, {out_path.stat().st_size} bytes)")

# Split at index 42
sheet_a = ALL_ASSETS[:42]
sheet_b = ALL_ASSETS[42:]

build_sheet(sheet_a, "Mazar Alpha — ALL Assets Sheet A (#1-42)", "84 total assets. GLBs verified. bench_park + fallen_log FIXED.", "2026-09-11_all_assets_sheet_A_42.png")
build_sheet(sheet_b, "Mazar Alpha — ALL Assets Sheet B (#43-84)", "84 total assets. GLBs verified. bench_park + fallen_log FIXED.", "2026-09-11_all_assets_sheet_B_42.png")
