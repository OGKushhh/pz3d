#!/usr/bin/env python3
"""Push: copy all new GLBs into godot_project/assets/, sync manifest, clear stale chunks."""
import json
import shutil
from pathlib import Path

SRC = Path("/home/z/my-project/assets")
DST = Path("/home/z/my-project/godot_project/assets")
MANIFEST_SRC = Path("/home/z/my-project/mazar_city_builder/data/city_manifest.json")
MANIFEST_DST = Path("/home/z/my-project/godot_project/data/city_manifest.json")
CHUNKS_DIR = Path("/home/z/my-project/godot_project/chunks")

# Categories to sync
CATEGORIES = ["buildings", "props", "foliage", "environment", "characters", "decals"]

copied = 0
skipped = 0
missing_dst_dir = 0

for cat in CATEGORIES:
    src_cat = SRC / cat / "out"
    dst_cat = DST / cat
    if not src_cat.exists():
        print(f"  SKIP {cat}: no source dir")
        continue
    dst_cat.mkdir(parents=True, exist_ok=True)

    # Get all GLBs in source
    src_glbs = sorted(src_cat.glob("*.glb"))
    for src_glb in src_glbs:
        dst_glb = dst_cat / src_glb.name
        # Compare mtime — only copy if newer or different size
        if dst_glb.exists():
            src_size = src_glb.stat().st_size
            dst_size = dst_glb.stat().st_size
            if src_size == dst_size:
                skipped += 1
                continue
        shutil.copy2(src_glb, dst_glb)
        copied += 1

print(f"\nGLBs copied: {copied} (skipped {skipped} already-synced)")

# Sync manifest
shutil.copy2(MANIFEST_SRC, MANIFEST_DST)
print(f"\nManifest synced: {MANIFEST_SRC} → {MANIFEST_DST}")

with open(MANIFEST_DST) as f:
    manifest = json.load(f)
print(f"  Manifest entries: {len(manifest)}")

# Validate manifest paths point to existing files in godot_project
missing = []
for name, entry in manifest.items():
    rel_path = entry["path"].replace("res://", "")
    abs_path = DST.parent / rel_path
    if not abs_path.exists():
        missing.append((name, entry["path"]))

if missing:
    print(f"\n⚠ Manifest references {len(missing)} missing GLBs in godot_project:")
    for name, path in missing[:10]:
        print(f"    {name} → {path}")
else:
    print(f"\n✓ All {len(manifest)} manifest paths valid in godot_project/")

# Clear stale prebuilt chunks (DeepSeek's recommendation: runtime streamer rebuilds on demand)
if CHUNKS_DIR.exists():
    chunk_files = list(CHUNKS_DIR.glob("chunk_*.tscn"))
    meta_files = list(CHUNKS_DIR.glob("city_meta.json"))
    print(f"\nClearing stale chunks: {len(chunk_files)} .tscn + {len(meta_files)} meta")
    for f in chunk_files + meta_files:
        f.unlink()
    print(f"  ✓ Stale chunks cleared (runtime streamer will rebuild on demand)")
else:
    print(f"\n  (no chunks dir to clear)")

# Final count
final_glbs = list(DST.rglob("*.glb"))
print(f"\n=== FINAL STATE in godot_project/assets/ ===")
by_cat = {}
for g in final_glbs:
    cat = g.parent.name
    by_cat[cat] = by_cat.get(cat, 0) + 1
for cat in sorted(by_cat):
    print(f"  {cat:15s}: {by_cat[cat]} GLBs")
print(f"  {'TOTAL':15s}: {len(final_glbs)} GLBs")
