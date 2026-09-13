#!/usr/bin/env python3
"""
Spatial Query API — portable position-based queries for the AI middleware.

DeepSeek: "Spatial query is really a portability feature in disguise. It forces
the detectors to say 'what's near this position' instead of 'scan the whole dump.'
That's what lets the middleware run on a different map without rewriting every
detector."

Loads the chunk_states dump once + builds a spatial grid index. Provides:
  - query_nearby(pos, radius) → all buildings within radius of pos
  - query_aabb(min, max) → all buildings whose AABB intersects the box
  - query_chunk(chunk_key) → the full chunk state for a specific chunk
  - count_problems_near(pos, radius) → count of problems (overlaps + too_close
    + semantic_conflict + min_spacing) within radius of pos
  - find_gaps_near(pos, radius) → empty gap positions within radius

Usage:
    from spatial_query import SpatialIndex
    idx = SpatialIndex("chunk_states_auto.json")
    nearby = idx.query_nearby([1250, 0, 2250], radius=50.0)
    problems = idx.count_problems_near([1250, 0, 2250], radius=30.0)
"""
import json
import math
from pathlib import Path
from collections import defaultdict

# Asset semantics (loaded from sidecar)
SEMANTICS_PATH = Path(__file__).parent.parent / "godot_project" / "data" / "asset_semantics.json"
SEMANTICS = {}
if SEMANTICS_PATH.exists():
    SEMANTICS = json.loads(SEMANTICS_PATH.read_text())
    SEMANTICS.pop("_meta", None)

# Landmark types (don't remove/reposition)
LANDMARK_TYPES = {"government_palace", "stadium", "old_royal_palace", "fort_sarran",
    "lighthouse", "broadcast_tower", "grain_silo", "windmill", "railway_station",
    "hospital", "police_station", "school_elementary", "church_small"}


class SpatialIndex:
    """Spatial grid index over all buildings from the chunk_states dump.
    
    Builds a grid with configurable cell size. Each building is indexed in
    the cell(s) it occupies. Queries check only the cells within the query
    radius — O(1) average lookup instead of O(N) scan.
    """
    
    def __init__(self, dump_path: str, cell_size: float = 50.0):
        self.cell_size = cell_size
        self.grid = defaultdict(list)  # (cell_x, cell_z) → [building, ...]
        self.chunks = {}  # (cx, cy) → chunk_state dict
        self.all_buildings = []
        self.all_props = []
        self.all_foliage = []
        self.all_zombies = []
        
        # Load dump
        states = json.loads(Path(dump_path).read_text())
        self._build_index(states)
    
    def _cell_key(self, x: float, z: float) -> tuple:
        """Convert world position to grid cell key."""
        return (int(x // self.cell_size), int(z // self.cell_size))
    
    def _build_index(self, states: list):
        """Build the spatial grid from all buildings across all chunks."""
        for state in states:
            ck = (state["chunk_key"][0], state["chunk_key"][1])
            self.chunks[ck] = state
            
            for b in state.get("buildings", []):
                self.all_buildings.append(b)
                # Index by building's position
                cx, cz = self._cell_key(b["pos"][0], b["pos"][2])
                self.grid[(cx, cz)].append(("building", b))
                # Also index by AABB corners (so queries find it via overlap)
                if "aabb" in b:
                    aabb = b["aabb"]
                    for corner in [aabb["min"], aabb["max"]]:
                        cx2, cz2 = self._cell_key(corner[0], corner[2])
                        if (cx2, cz2) != (cx, cz):
                            self.grid[(cx2, cz2)].append(("building", b))
            
            for p in state.get("props", []):
                self.all_props.append(p)
                cx, cz = self._cell_key(p["pos"][0], p["pos"][2])
                self.grid[(cx, cz)].append(("prop", p))
            
            for f in state.get("foliage", []):
                self.all_foliage.append(f)
                cx, cz = self._cell_key(f["pos"][0], f["pos"][2])
                self.grid[(cx, cz)].append(("foliage", f))
            
            for z in state.get("zombies", []):
                self.all_zombies.append(z)
                cx, cz = self._cell_key(z["pos"][0], z["pos"][2])
                self.grid[(cx, cz)].append(("zombie", z))
    
    def query_nearby(self, pos: list, radius: float = 30.0) -> list:
        """Return all buildings within `radius` meters of `pos`.
        O(1) grid lookup — only checks cells within the query radius."""
        results = []
        cx, cz = self._cell_key(pos[0], pos[2])
        # Check cells in a (radius / cell_size) grid around the query point
        cell_radius = int(math.ceil(radius / self.cell_size))
        seen = set()  # avoid duplicates (a building may be in multiple cells)
        for dx in range(-cell_radius, cell_radius + 1):
            for dz in range(-cell_radius, cell_radius + 1):
                cell = (cx + dx, cz + dz)
                if cell not in self.grid:
                    continue
                for kind, item in self.grid[cell]:
                    if kind != "building":
                        continue
                    item_id = id(item)
                    if item_id in seen:
                        continue
                    seen.add(item_id)
                    # Verify within radius
                    d = math.sqrt((item["pos"][0] - pos[0]) ** 2 +
                                  (item["pos"][2] - pos[2]) ** 2)
                    if d <= radius:
                        results.append(item)
        return results
    
    def query_aabb(self, min_pos: list, max_pos: list) -> list:
        """Return all buildings whose AABB intersects the given box."""
        results = []
        seen = set()
        # Check all cells that the query box overlaps
        cx_min = int(min_pos[0] // self.cell_size)
        cx_max = int(max_pos[0] // self.cell_size)
        cz_min = int(min_pos[2] // self.cell_size)
        cz_max = int(max_pos[2] // self.cell_size)
        for cx in range(cx_min, cx_max + 1):
            for cz in range(cz_min, cz_max + 1):
                cell = (cx, cz)
                if cell not in self.grid:
                    continue
                for kind, item in self.grid[cell]:
                    if kind != "building":
                        continue
                    item_id = id(item)
                    if item_id in seen:
                        continue
                    seen.add(item_id)
                    # Check AABB intersection
                    if "aabb" in item:
                        aabb = item["aabb"]
                        if (aabb["min"][0] < max_pos[0] and aabb["max"][0] > min_pos[0] and
                            aabb["min"][2] < max_pos[2] and aabb["max"][2] > min_pos[2]):
                            results.append(item)
                    else:
                        # No AABB — check position
                        p = item["pos"]
                        if (min_pos[0] <= p[0] <= max_pos[0] and
                            min_pos[2] <= p[2] <= max_pos[2]):
                            results.append(item)
        return results
    
    def query_chunk(self, chunk_key: tuple) -> dict:
        """Return the full chunk state for a specific chunk."""
        return self.chunks.get(chunk_key, {})
    
    def query_chunk_at(self, pos: list, chunk_size: float = 250.0) -> dict:
        """Return the chunk state for the chunk containing `pos`."""
        cx = int(pos[0] // chunk_size)
        cy = int(pos[2] // chunk_size)
        return self.query_chunk((cx, cy))
    
    def count_problems_near(self, pos: list, radius: float = 30.0) -> int:
        """Count problems (overlaps + too_close + semantic_conflict + min_spacing)
        involving any building within `radius` of `pos`.
        
        Uses the spatial index for O(1) grid lookup — only checks buildings
        in nearby cells, not the entire dump. This is the portability win:
        detectors call this instead of scanning all buildings."""
        nearby = self.query_nearby(pos, radius)
        count = 0
        for i, b1 in enumerate(nearby):
            for j, b2 in enumerate(nearby):
                if j <= i:
                    continue
                # Overlaps
                if "aabb" in b1 and "aabb" in b2:
                    if self._aabb_overlaps(b1["aabb"], b2["aabb"]):
                        count += 1
                # too_close
                d = math.sqrt((b1["pos"][0] - b2["pos"][0]) ** 2 +
                               (b1["pos"][2] - b2["pos"][2]) ** 2)
                if d < 3.0:
                    count += 1
                # semantic_conflict (both directions)
                sem1 = SEMANTICS.get(b1["name"], {})
                if b2["name"] in sem1.get("conflicts_with", []):
                    count += 1
                sem2 = SEMANTICS.get(b2["name"], {})
                if b1["name"] in sem2.get("conflicts_with", []):
                    count += 1
                # min_spacing (same asset only)
                min_s = sem1.get("min_spacing", 0)
                if min_s > 0 and b1["name"] == b2["name"] and d < min_s:
                    count += 1
        return count
    
    def find_gaps_near(self, pos: list, radius: float = 50.0) -> list:
        """Find empty gap positions within `radius` of `pos`.
        Returns list of gap dicts with pos + suggested_fill."""
        chunk = self.query_chunk_at(pos)
        gaps = chunk.get("gaps", [])
        result = []
        for gap in gaps:
            d = math.sqrt((gap["pos"][0] - pos[0]) ** 2 +
                          (gap["pos"][2] - pos[2]) ** 2)
            if d <= radius:
                result.append(gap)
        return result
    
    def find_isolated_gaps(self, pos: list, radius: float = 50.0,
                           min_isolation: float = 15.0) -> list:
        """Find gaps that are at least `min_isolation` meters from any building.
        These are safe to fill without creating new overlaps."""
        gaps = self.find_gaps_near(pos, radius)
        result = []
        for gap in gaps:
            nearby_buildings = self.query_nearby(gap["pos"], min_isolation)
            if not nearby_buildings:
                result.append(gap)
        return result
    
    def get_all_buildings(self) -> list:
        """Return all buildings across all chunks (for full-dump analysis)."""
        return self.all_buildings
    
    def get_all_chunks(self) -> list:
        """Return all chunk states (for cross-chunk analysis)."""
        return list(self.chunks.values())
    
    def get_chunk_count(self) -> int:
        return len(self.chunks)
    
    def get_building_count(self) -> int:
        return len(self.all_buildings)
    
    @staticmethod
    def _aabb_overlaps(a: dict, b: dict) -> bool:
        """3D AABB intersection test."""
        return (a["min"][0] < b["max"][0] and a["max"][0] > b["min"][0] and
                a["min"][1] < b["max"][1] and a["max"][1] > b["min"][1] and
                a["min"][2] < b["max"][2] and a["max"][2] > b["min"][2])
