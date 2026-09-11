#!/usr/bin/env python3
"""
Render MoGen GLB files to PNG previews without needing a GPU.

Fix v2: properly apply scene-graph transforms so positioned meshes
appear in their world-space location, not collapsed at origin.

Output is a clean stylized preview, not a PBR render.
For a true PBR render with textures, run `mogen textures` (needs Gemini API key)
and then re-render in Godot/Blender.
"""

import sys
from pathlib import Path

import numpy as np
import trimesh
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection


def load_glb_meshes_world_space(glb_path):
    """Load a GLB and return list of (world_vertices, faces, color) per mesh."""
    scene = trimesh.load(glb_path, force="scene")
    meshes = []

    # Iterate scene graph and apply transforms to each geometry
    for node_name in scene.graph.nodes_geometry:
        # get(frame_to) returns (transform, geometry_name) — transform from node's frame to base_frame (world)
        try:
            transform, geometry_name = scene.graph.get(node_name)
        except Exception:
            # fallback for older API
            try:
                transform, geometry_name = scene.graph.get(frame_to=node_name)
            except Exception:
                continue

        if geometry_name is None or geometry_name not in scene.geometry:
            # the geometry may share the node's name
            if node_name in scene.geometry:
                geometry_name = node_name
            else:
                continue

        geom = scene.geometry[geometry_name]

        if not hasattr(geom, "vertices") or len(geom.vertices) == 0:
            continue

        v_local = np.asarray(geom.vertices)
        v_world = trimesh.transform_points(v_local, transform)
        f = np.asarray(geom.faces)

        # Try to get the material color
        color = (0.7, 0.7, 0.7, 1.0)
        if hasattr(geom, "visual"):
            vis = geom.visual
            if hasattr(vis, "main_color"):
                try:
                    c = vis.main_color
                    if c is not None:
                        color = (c[0] / 255, c[1] / 255, c[2] / 255, 1.0)
                except Exception:
                    pass
            if hasattr(vis, "material") and hasattr(vis.material, "main_color"):
                try:
                    c = vis.material.main_color
                    color = (c[0] / 255, c[1] / 255, c[2] / 255, 1.0)
                except Exception:
                    pass

        meshes.append((v_world, f, color))
    return meshes


def render_meshes_to_png(meshes, out_path, size=1024, title=None, bg="#2a2d33",
                         yaw_deg=45, pitch_deg=25, light_dir=None):
    """Render meshes to a PNG via matplotlib 3D with simple lighting."""
    if not meshes:
        print(f"  X no meshes to render")
        return

    fig = plt.figure(figsize=(size / 100, size / 100), dpi=100, facecolor=bg)
    ax = fig.add_subplot(111, projection="3d")
    ax.set_facecolor(bg)

    # Compute bounds across all meshes
    all_v = np.vstack([m[0] for m in meshes])
    mins = all_v.min(axis=0)
    maxs = all_v.max(axis=0)
    center = (mins + maxs) / 2
    extent = (maxs - mins).max() / 2 * 1.15

    if light_dir is None:
        light_dir = np.array([0.3, 0.85, -0.4])
    light_dir = light_dir / np.linalg.norm(light_dir)

    for v, f, base_color in meshes:
        # Compute per-face normal for simple flat shading
        tri = v[f]
        # face normal = (v1-v0) x (v2-v0)
        a = tri[:, 1] - tri[:, 0]
        b = tri[:, 2] - tri[:, 0]
        normals = np.cross(a, b)
        norm_lens = np.linalg.norm(normals, axis=1, keepdims=True)
        norm_lens[norm_lens == 0] = 1
        normals = normals / norm_lens

        # Lambert shading: intensity = max(0, dot(normal, -light_dir))
        # but flip normals if they face away from light (twoside)
        intensity = np.abs(normals @ light_dir) * 0.6 + 0.4  # 0.4-1.0 range

        # Build per-face colors
        face_colors = np.tile(base_color, (len(tri), 1))
        # apply intensity to rgb
        face_colors[:, 0:3] *= intensity[:, None]
        face_colors[:, 3] = 1.0  # alpha

        poly = Poly3DCollection(
            tri,
            facecolors=face_colors,
            edgecolors=(0.05, 0.05, 0.06, 0.25),
            linewidths=0.1,
        )
        ax.add_collection3d(poly)

    ax.set_xlim(center[0] - extent, center[0] + extent)
    ax.set_ylim(center[2] - extent, center[2] + extent)
    ax.set_zlim(center[1] - extent, center[1] + extent)
    ax.set_box_aspect([1, 1, 1])

    ax.view_init(elev=pitch_deg, azim=yaw_deg)
    ax.set_axis_off()
    try:
        ax.set_proj_type("persp", focal_length=0.9)
    except Exception:
        pass

    if title:
        fig.suptitle(title, color="#e6e6e6", fontsize=12, y=0.96)

    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
    fig.savefig(out_path, facecolor=bg, bbox_inches="tight", pad_inches=0)
    plt.close(fig)


def main():
    in_dir = Path("/home/z/my-project/mogen-examples")
    out_dir = Path("/home/z/my-project/download/mogen-lookbook")
    out_dir.mkdir(parents=True, exist_ok=True)

    scenes = [
        ("chair",                 "chair",              35,  20, "chair.mog — 6 nodes, 1.1k tris"),
        ("table",                 "table",              35,  20, "table.mog — 396 tris"),
        ("cup",                   "cup",                35,  15, "cup.mog — 150 tris"),
        ("fence",                 "fence",              60,  15, "fence.mog — 318 tris, 31 meshes"),
        ("suburban_house",        "suburban_house",     45,  25, "suburban_house.mog — 49 nodes, 2.8k tris, 11 materials"),
        ("suburban_house_aerial", "suburban_house",     45,  70, "suburban_house.mog — aerial"),
        ("suburban_house_street", "suburban_house",     10,   8, "suburban_house.mog — street view"),
        ("simple_house",          "simple_house",       45,  25, "simple_house.mog — 12 nodes"),
        ("broken_window",         "broken_window",      35,  20, "broken_window.mog — CSG difference demo"),
        ("humanoid",              "humanoid",           35,  12, "humanoid.mog — DSL character, skinned rig"),
        ("humanoid_side",         "humanoid",           90,   5, "humanoid.mog — side view"),
    ]

    for out_name, glb_base, yaw, pitch, title in scenes:
        glb_path = in_dir / f"{glb_base}.glb"
        if not glb_path.exists():
            print(f"  X {out_name}: no GLB at {glb_path}")
            continue
        out_path = out_dir / f"{out_name}.png"
        print(f"  -> {out_name} from {glb_path.name}")
        try:
            meshes = load_glb_meshes_world_space(glb_path)
            print(f"     {len(meshes)} meshes loaded")
            render_meshes_to_png(meshes, out_path, size=1024, title=title,
                                 yaw_deg=yaw, pitch_deg=pitch)
            print(f"  OK {out_name} -> {out_path.name} ({out_path.stat().st_size} bytes)")
        except Exception as e:
            import traceback
            print(f"  X {out_name}: {e}")
            traceback.print_exc()


if __name__ == "__main__":
    main()
