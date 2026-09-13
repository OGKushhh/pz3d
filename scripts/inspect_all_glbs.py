#!/usr/bin/env python3
"""Sweep all .glb assets and report their triangle counts.
Identifies high-poly assets that should be re-authored at lower tri counts.

Usage: python3 /home/z/my-project/pz3d/scripts/inspect_all_glbs.py
"""
import struct
import json
import os
from pathlib import Path

ASSETS_DIR = Path("/home/z/my-project/pz3d/godot_project/assets")

def get_glb_tri_count(glb_path: Path) -> tuple:
    """Returns (tri_count, mesh_count, file_size_bytes) for a GLB file."""
    try:
        with open(glb_path, 'rb') as f:
            magic = f.read(4)
            if magic != b'glTF':
                return (0, 0, 0)
            version = struct.unpack('<I', f.read(4))[0]
            length = struct.unpack('<I', f.read(4))[0]
            chunk_length = struct.unpack('<I', f.read(4))[0]
            chunk_type = f.read(4)
            json_data = json.loads(f.read(chunk_length).decode('utf-8'))
            
            total_indices = 0
            mesh_count = len(json_data.get('meshes', []))
            for acc in json_data.get('accessors', []):
                ct = acc.get('componentType', 0)
                if ct in (5123, 5125) and acc.get('type') == 'SCALAR':
                    total_indices += acc.get('count', 0)
            tris = total_indices // 3
            return (tris, mesh_count, os.path.getsize(glb_path))
    except Exception as e:
        return (0, 0, 0)

def main():
    results = []
    for root, dirs, files in os.walk(ASSETS_DIR):
        for fname in files:
            if not fname.endswith('.glb'):
                continue
            # Skip shell variants (they're separate from the main asset)
            if '_shell' in fname:
                continue
            glb_path = Path(root) / fname
            asset_name = fname[:-4]
            tris, mesh_count, file_size = get_glb_tri_count(glb_path)
            category = Path(root).relative_to(ASSETS_DIR).parts[0]
            results.append({
                'name': asset_name,
                'category': category,
                'tris': tris,
                'meshes': mesh_count,
                'file_size': file_size,
                'path': str(glb_path.relative_to(ASSETS_DIR)),
            })
    
    # Sort by tri count descending
    results.sort(key=lambda r: r['tris'], reverse=True)
    
    print(f"\n{'='*80}")
    print(f"GLB TRI COUNT SWEEP — {len(results)} assets")
    print(f"{'='*80}")
    print(f"{'Name':<30} {'Category':<12} {'Tris':>8} {'Meshes':>7} {'Size':>8}")
    print(f"{'-'*80}")
    
    total_tris = 0
    for r in results:
        print(f"{r['name']:<30} {r['category']:<12} {r['tris']:>8} {r['meshes']:>7} {r['file_size']:>8}B")
        total_tris += r['tris']
    
    print(f"{'-'*80}")
    print(f"{'TOTAL':<30} {'':<12} {total_tris:>8}")
    
    # Flag high-poly assets
    print(f"\n{'='*80}")
    print("HIGH-POLY ASSETS (re-author candidates):")
    print(f"{'='*80}")
    for r in results:
        if r['category'] == 'characters' and r['tris'] > 2000:
            print(f"  {r['name']:<30} {r['tris']:>6} tris — characters should be 1000-2000")
        elif r['category'] == 'props' and r['tris'] > 800:
            print(f"  {r['name']:<30} {r['tris']:>6} tris — props should be <800")
        elif r['category'] == 'foliage' and r['tris'] > 2500:
            print(f"  {r['name']:<30} {r['tris']:>6} tris — foliage should be <2500")
        elif r['category'] == 'buildings' and r['tris'] > 3000:
            print(f"  {r['name']:<30} {r['tris']:>6} tris — buildings should be <3000")

if __name__ == "__main__":
    main()
