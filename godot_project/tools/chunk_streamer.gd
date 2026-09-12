extends Node3D

# ChunkStreamer v6 — unified terrain via Terrain3D (Phase C.5)
#
# CHANGES from v5:
#   - Building/prop/foliage Y now comes from Terrain3D.data.get_height()
#     instead of terrain_height.gd directly. This ensures everything sits
#     on the SAME surface the player walks on (collision = visual mesh).
#   - terrain_height.gd is still used for baking the heightmap (terrain_baker.gd)
#     and for debug visualization, but NOT for runtime placement Y.
#   - Player Y also comes from Terrain3D collision (via move_and_slide).
#
# This fixes the floor alignment issue where buildings/trees were at a
# different Y than the player's feet.

const CityConfig = preload("res://tools/city_config.gd")
const SpatialIndex = preload("res://tools/spatial_index.gd")
const RoadNetwork = preload("res://tools/road_network.gd")
const PlanGrid = preload("res://tools/plan_grid.gd")
const TerrainHeight = preload("res://tools/terrain_height.gd")
const RiverNetwork = preload("res://tools/river_network.gd")

var player: Node3D
var stream_radius: int = 2
var spatial: SpatialIndex
var roads: RoadNetwork
var manifest: Dictionary = {}
var asset_cache: Dictionary = {}
var rng: RandomNumberGenerator
var plan_grid: PlanGrid
var terrain: TerrainHeight
var river: RiverNetwork
var terrain3d: Variant  # Terrain3D node (set in _ready)
var _loaded: Dictionary = {}
var _stats: Dictionary = {}

func _ready() -> void:
        await get_tree().process_frame
        var root := get_tree().current_scene
        player = root.get_node_or_null("Player")
        if player == null:
                for child in root.get_children():
                        if child is CharacterBody3D:
                                player = child
                                break
        if player == null:
                push_error("[ChunkStreamer] No player found!")
                return

        var f := FileAccess.open("res://data/city_manifest.json", FileAccess.READ)
        if f:
                manifest = JSON.parse_string(f.get_as_text())
        print("[ChunkStreamer] manifest: %d assets, player at %s" % [manifest.size(), player.global_position])

        spatial = SpatialIndex.new(CityConfig.SPATIAL_CELL_M)
        roads = RoadNetwork.new()
        rng = RandomNumberGenerator.new()
        rng.seed = 1337
        roads.generate(rng)
        roads.mark_roads_in_index(spatial, CityConfig.SPATIAL_CELL_M)
        plan_grid = PlanGrid.new()
        plan_grid.build(roads, 1337)

        # Phase B: terrain function (for debug viz + fallback)
        river = RiverNetwork.new()
        terrain = TerrainHeight.new(1337, river)

        # Phase C: find the Terrain3D node (created by TerrainBaker)
        # Wait a frame for TerrainBaker to finish
        await get_tree().create_timer(0.1).timeout
        terrain3d = root.get_node_or_null("TerrainBaker/Terrain3D")
        if terrain3d == null:
                push_warning("[ChunkStreamer] Terrain3D not found — using terrain_height.gd fallback")
        else:
                print("[ChunkStreamer] Terrain3D found, using get_height() for unified Y")

        # Auto-set player Y from Terrain3D (or fallback to terrain_height.gd)
        var px: float = player.global_position.x
        var pz: float = player.global_position.z
        var py: float = _get_terrain_y(px, pz) + 2.0
        player.global_position = Vector3(px, py, pz)
        print("[ChunkStreamer] player Y set to %.2f (terrain=%.2f)" % [py, py - 2.0])

# Unified terrain Y query. Uses Terrain3D's get_height() if available
# (matches collision), falls back to terrain_height.gd otherwise.
func _get_terrain_y(x: float, z: float) -> float:
        if terrain3d != null and terrain3d.has_method("data") and terrain3d.data != null:
                var h: float = terrain3d.data.get_height(Vector3(x, 0, z))
                if not is_nan(h):
                        return h
        # Fallback to terrain_height.gd (used during initial bake or if Terrain3D fails)
        return terrain.height_at(x, z)

var _build_queue: Array = []  # Pending chunk builds (frame budget: 1 per frame)
var _builds_this_frame: int = 0

func _process(_delta: float) -> void:
        if player == null or manifest.is_empty():
                return
        var cx: int = int(floor(player.global_position.x / CityConfig.CHUNK_SIZE_M))
        var cy: int = int(floor(player.global_position.z / CityConfig.CHUNK_SIZE_M))
        _builds_this_frame = 0
        _refresh(cx, cy)
        # Frame budget: build at most 1 chunk per frame to prevent hitching
        if not _build_queue.is_empty() and _builds_this_frame == 0:
                var next_key: Vector2i = _build_queue.pop_front()
                _build_chunk(next_key)
                _builds_this_frame += 1

func _refresh(cx: int, cy: int) -> void:
        var unload_r: int = stream_radius + CityConfig.STREAM_UNLOAD_BUFFER
        var wanted: Dictionary = {}

        for dy in range(-stream_radius, stream_radius + 1):
                for dx in range(-stream_radius, stream_radius + 1):
                        var key := Vector2i(cx + dx, cy + dy)
                        wanted[key] = true
                        if not _loaded.has(key) and not _build_queue.has(key):
                                _build_queue.append(key)

        var to_remove: Array = []
        for key in _loaded:
                if abs(key.x - cx) > unload_r or abs(key.y - cy) > unload_r:
                        to_remove.append(key)
        for key in to_remove:
                _unload_chunk(key)

func _build_chunk(key: Vector2i) -> void:
        if key.x < 0 or key.y < 0 or key.x >= CityConfig.CHUNKS_COLS or key.y >= CityConfig.CHUNKS_ROWS:
                return

        var col: int = clamp(int(key.x * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_COLS - 1)
        var row: int = clamp(int(key.y * CityConfig.CHUNK_SIZE_M / CityConfig.CELL_SIZE_M), 0, CityConfig.GRID_ROWS - 1)
        var biome: int = CityConfig.grid_layout()[row][col]

        var profile: Dictionary = CityConfig.biomes().get(biome, {})
        if profile.is_empty() or profile.get("fill", 0.0) <= 0.0:
                return

        var origin: Vector3 = Vector3(key.x * CityConfig.CHUNK_SIZE_M, 0, key.y * CityConfig.CHUNK_SIZE_M)
        var chunk_root := Node3D.new()
        chunk_root.name = "Chunk_%d_%d" % [key.x, key.y]

        var chunk_seed: int = hash(key) ^ 1337
        var crng := RandomNumberGenerator.new()
        crng.seed = chunk_seed

        var b_count := 0
        var p_count := 0
        var f_count := 0
        var s_count := 0
        var l_count := 0

        # === PHASE F: POI / Landmark placement ===
        # Check if any POI from pois.json falls within this chunk.
        # If yes: place the landmark at the POI's exact position (with terrain Y),
        # and suppress procedural placement within the POI's radius.
        var poi_exclusions: Array = []  # Array of {center: Vector3, radius: float}
        var pois := _get_pois_for_chunk(origin, CityConfig.CHUNK_SIZE_M)
        for poi in pois:
                var poi_asset: String = poi.get("type", "")
                var poi_scene: PackedScene = _get_asset(poi_asset)
                if poi_scene == null:
                        push_warning("[ChunkStreamer] POI asset not found in manifest: " + poi_asset)
                        continue
                var poi_pos := Vector3(poi.pos[0], 0, poi.pos[2])
                poi_pos.y = _get_terrain_y(poi_pos.x, poi_pos.z)
                var poi_inst: Node3D = poi_scene.instantiate()
                poi_inst.position = poi_pos
                poi_inst.name = "POI_%s" % poi.get("id", poi_asset)
                chunk_root.add_child(poi_inst)
                spatial.insert(poi_pos, float(poi.get("radius", 30)))
                poi_exclusions.append({"center": poi_pos, "radius": float(poi.get("radius", 30))})
                l_count += 1
                print("[ChunkStreamer] POI placed: %s at %s" % [poi.get("id", poi_asset), poi_pos])

        # === BUILDINGS (lot-based, v3 rules, per-biome density) ===
        # v3 placement: buildings line up in lots that face the nearest road.
        # Each lot is LOT_WIDTH × LOT_DEPTH. Buildings are placed at the
        # building_offset distance from road centerlines, facing the road.
        # See docs/retired_city_builder_v3_extraction.md §3 rules #4.
        var buildings: Array = profile.get("buildings", [])
        if not buildings.is_empty():
                var fill: float = profile.get("fill", 0.5)
                var building_radius: float = max(CityConfig.LOT_WIDTH, CityConfig.LOT_DEPTH) * 0.4

                # Per-biome density: tune target building count per chunk
                # Downtown=fill*60, Commercial=fill*50, Suburbia=fill*30,
                # Farmland=fill*15, Forest=fill*10, Military=fill*8
                var density_mult: float = 30.0
                match biome:
                        CityConfig.Biome.DOWNTOWN: density_mult = 60.0
                        CityConfig.Biome.COMMERCIAL: density_mult = 50.0
                        CityConfig.Biome.SUBURBIA: density_mult = 30.0
                        CityConfig.Biome.INDUSTRIAL: density_mult = 25.0
                        CityConfig.Biome.FARMLAND: density_mult = 15.0
                        CityConfig.Biome.FOREST: density_mult = 10.0
                        CityConfig.Biome.PARKS: density_mult = 5.0
                        CityConfig.Biome.MILITARY: density_mult = 8.0
                        CityConfig.Biome.COASTAL_BEACH: density_mult = 12.0
                        _: density_mult = 20.0

                var target: int = crng.randi_range(int(fill * density_mult * 0.5), int(fill * density_mult))
                target = min(target, 30)  # hard cap per chunk

                # building_offset = road edge + sidewalk + grass strip + setback
                var building_offset: float = CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH + CityConfig.BUILDING_SETBACK

                # Find road grid lines within or near this chunk
                var chunk_x_start: float = origin.x
                var chunk_x_end: float = origin.x + CityConfig.CHUNK_SIZE_M
                var chunk_z_start: float = origin.z
                var chunk_z_end: float = origin.z + CityConfig.CHUNK_SIZE_M

                # Check each road grid line (every CELL_SIZE_M=500m)
                # Place buildings along both sides of roads
                var placed := 0
                for road_z in range(int(chunk_z_start / 500.0) * 500, int(chunk_z_end / 500.0) * 500 + 500, 500):
                        if placed >= target:
                                break
                        # Horizontal road at Z=road_z — place buildings on north + south sides
                        for side in [-1, 1]:
                                if placed >= target:
                                        break
                                var lot_z: float = road_z + float(side) * building_offset + float(side) * CityConfig.LOT_DEPTH * 0.5
                                if lot_z < chunk_z_start or lot_z > chunk_z_end:
                                        continue
                                # Place lots along X at LOT_WIDTH intervals
                                for lot_x in range(int(chunk_x_start / CityConfig.LOT_WIDTH) * int(CityConfig.LOT_WIDTH), int(chunk_x_end / CityConfig.LOT_WIDTH) * int(CityConfig.LOT_WIDTH), int(CityConfig.LOT_WIDTH)):
                                        if placed >= target:
                                                break
                                        if crng.randf() > fill:
                                                continue  # skip lot (empty lot)
                                        var pos := Vector3(
                                                float(lot_x) + CityConfig.LOT_WIDTH * 0.5 + crng.randf_range(-2.0, 2.0),
                                                0,
                                                lot_z
                                        )
                                        if pos.x < chunk_x_start or pos.x > chunk_x_end:
                                                continue
                                        if not spatial.is_free(pos, building_radius) or spatial.is_on_road(pos):
                                                continue
                                        if _is_in_poi_exclusion(pos, poi_exclusions):
                                                continue
                                        var bname: String = buildings[crng.randi() % buildings.size()]
                                        var scene: PackedScene = _get_asset(bname)
                                        if scene == null:
                                                continue
                                        pos.y = _get_terrain_y(pos.x, pos.z)
                                        var inst: Node3D = scene.instantiate()
                                        inst.position = pos
                                        # Face the road: south side faces -Z, north side faces +Z
                                        inst.rotation.y = 0.0 if side < 0 else PI
                                        inst.name = "%s_%d" % [bname, crng.randi() % 100000]
                                        chunk_root.add_child(inst)
                                        spatial.insert(pos, building_radius)
                                        placed += 1
                                        b_count += 1

                # Also place along vertical roads
                for road_x in range(int(chunk_x_start / 500.0) * 500, int(chunk_x_end / 500.0) * 500 + 500, 500):
                        if placed >= target:
                                break
                        for side in [-1, 1]:
                                if placed >= target:
                                        break
                                var lot_x: float = road_x + float(side) * building_offset + float(side) * CityConfig.LOT_DEPTH * 0.5
                                if lot_x < chunk_x_start or lot_x > chunk_x_end:
                                        continue
                                for lot_z in range(int(chunk_z_start / CityConfig.LOT_WIDTH) * int(CityConfig.LOT_WIDTH), int(chunk_z_end / CityConfig.LOT_WIDTH) * int(CityConfig.LOT_WIDTH), int(CityConfig.LOT_WIDTH)):
                                        if placed >= target:
                                                break
                                        if crng.randf() > fill:
                                                continue
                                        var pos := Vector3(
                                                lot_x,
                                                0,
                                                float(lot_z) + CityConfig.LOT_WIDTH * 0.5 + crng.randf_range(-2.0, 2.0)
                                        )
                                        if pos.z < chunk_z_start or pos.z > chunk_z_end:
                                                continue
                                        if not spatial.is_free(pos, building_radius) or spatial.is_on_road(pos):
                                                continue
                                        if _is_in_poi_exclusion(pos, poi_exclusions):
                                                continue
                                        var bname: String = buildings[crng.randi() % buildings.size()]
                                        var scene: PackedScene = _get_asset(bname)
                                        if scene == null:
                                                continue
                                        pos.y = _get_terrain_y(pos.x, pos.z)
                                        var inst: Node3D = scene.instantiate()
                                        inst.position = pos
                                        # Face the road: west side faces +X, east side faces -X
                                        inst.rotation.y = PI * 0.5 if side < 0 else -PI * 0.5
                                        inst.name = "%s_%d" % [bname, crng.randi() % 100000]
                                        chunk_root.add_child(inst)
                                        spatial.insert(pos, building_radius)
                                        placed += 1
                                        b_count += 1

        # === PROPS (denser: 25-50, was 6-16) ===
        var props: Array = profile.get("props", [])
        if not props.is_empty():
                var count: int = crng.randi_range(25, 50)
                for i in range(count):
                        var pname: String = props[crng.randi() % props.size()]
                        var scene: PackedScene = _get_asset(pname)
                        if scene == null:
                                continue
                        var pos: Vector3 = origin + Vector3(
                                crng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0),
                                0,
                                crng.randf_range(2.0, CityConfig.CHUNK_SIZE_M - 2.0)
                        )
                        if not spatial.is_free(pos, 1.5) or spatial.is_on_road(pos):
                                continue
                        # Phase C: unified Y from Terrain3D
                        pos.y = _get_terrain_y(pos.x, pos.z)
                        var inst: Node3D = scene.instantiate()
                        inst.position = pos
                        inst.rotation.y = crng.randf_range(0, TAU)
                        inst.name = "%s_%d" % [pname, crng.randi() % 100000]
                        chunk_root.add_child(inst)
                        spatial.insert(pos, 1.5)
                        p_count += 1

        # === FOLIAGE (keep dense) ===
        var foliage: Array = profile.get("foliage", [])
        if not foliage.is_empty():
                var count: int = crng.randi_range(15, 50)
                for i in range(count):
                        var fname: String = foliage[crng.randi() % foliage.size()]
                        var scene: PackedScene = _get_asset(fname)
                        if scene == null:
                                continue
                        var pos: Vector3 = origin + Vector3(
                                crng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0),
                                0,
                                crng.randf_range(1.0, CityConfig.CHUNK_SIZE_M - 1.0)
                        )
                        var radius: float = 3.0 if "tree" in fname else 1.0
                        if not spatial.is_free(pos, radius) or spatial.is_on_road(pos):
                                continue
                        # Phase C: unified Y from Terrain3D
                        pos.y = _get_terrain_y(pos.x, pos.z)
                        var inst: Node3D = scene.instantiate()
                        inst.position = pos
                        inst.rotation.y = crng.randf_range(0, TAU)
                        inst.name = "%s_%d" % [fname, crng.randi() % 100000]
                        chunk_root.add_child(inst)
                        spatial.insert(pos, radius)
                        f_count += 1

        # === STREET LIGHTS ===
        if profile.get("lights", false):
                var scene: PackedScene = _get_asset("street_light")
                if scene != null:
                        var owned: Array = roads.owned_segments_in_chunk(origin, CityConfig.CHUNK_SIZE_M)
                        var edge_offset: float = CityConfig.ROAD_WIDTH * 0.5 + CityConfig.SIDEWALK_WIDTH + CityConfig.GRASS_STRIP_WIDTH * 0.5
                        for seg in owned:
                                var a: Vector3 = seg["start"]
                                var b: Vector3 = seg["end"]
                                var length: float = a.distance_to(b)
                                var d: float = 0.0
                                while d < length:
                                        var t: float = d / length if length > 0.001 else 0.0
                                        var base: Vector3 = a.lerp(b, t)
                                        var dir: Vector3 = (b - a).normalized() if length > 0.001 else Vector3.FORWARD
                                        var perp: Vector3 = Vector3(-dir.z, 0, dir.x)
                                        var pos: Vector3 = base + perp * edge_offset
                                        if not spatial.is_on_road(pos) and spatial.is_free(pos, 0.5):
                                                pos.y = _get_terrain_y(pos.x, pos.z)
                                                var inst: Node3D = scene.instantiate()
                                                inst.position = pos
                                                inst.name = "street_light_%d" % crng.randi()
                                                chunk_root.add_child(inst)
                                                spatial.insert(pos, 0.5)
                                                s_count += 1
                                        d += CityConfig.STREETLIGHT_SPACING

        add_child(chunk_root)
        _loaded[key] = chunk_root

        # Phase G.2: MultiMesh batching for foliage.
        # Group all MeshInstance3D children by mesh, replace with MultiMeshInstance3D.
        # 80-90% draw call reduction for foliage (200 trees → 1 draw call per species).
        _batch_meshes(chunk_root)

        # Phase E: Add NavigationRegion3D per chunk for zombie pathfinding.
        # Bake is deferred — NavigationServer3D builds navmesh from source geometry.
        # Source geometry = Terrain3D collision (if available) + building static bodies.
        # For now, just add the region node so the hooks exist. Zombies can use
        # NavigationServer3D.map_get_closest_point() once bake completes.
        var nav_region := NavigationRegion3D.new()
        nav_region.name = "NavRegion_%d_%d" % [key.x, key.y]
        chunk_root.add_child(nav_region)

        var bname: String = profile.get("name", "Unknown")
        print("chunk %d_%d: biome=%s buildings=%d props=%d foliage=%d lights=%d landmarks=%d children=%d" % [
                key.x, key.y, bname, b_count, p_count, f_count, s_count, l_count, chunk_root.get_child_count()
        ])

        # Track stats
        if not _stats.has(bname):
                _stats[bname] = {"buildings": 0, "props": 0, "foliage": 0, "lights": 0, "chunks": 0}
        _stats[bname]["buildings"] += b_count
        _stats[bname]["props"] += p_count
        _stats[bname]["foliage"] += f_count
        _stats[bname]["lights"] += s_count
        _stats[bname]["chunks"] += 1

# Phase G.2: Batch identical meshes into MultiMeshInstance3D
# Recursively searches through GLB hierarchy (Node3D → MeshInstance3D children)
# to find all meshes with the same resource_path. Groups them into MultiMesh.
func _batch_meshes(chunk_root: Node3D) -> void:
        var by_mesh: Dictionary = {}  # resource_path → Array[MeshInstance3D]

        # Recursively collect all MeshInstance3D nodes
        _collect_meshes(chunk_root, by_mesh)

        var batched: int = 0
        for mesh_path in by_mesh:
                var list: Array = by_mesh[mesh_path]
                if list.size() < 3:
                        continue  # Only batch if 3+ instances (overhead not worth it for 1-2)

                var mm := MultiMesh.new()
                mm.transform_format = MultiMesh.TRANSFORM_3D
                mm.mesh = list[0].mesh
                mm.instance_count = list.size()

                for i in range(list.size()):
                        var inst: MeshInstance3D = list[i]
                        # Force global transform update before reading it
                        inst.force_update_transform()
                        # Calculate world transform manually: parent chain transform * local
                        # We can't rely on global_transform because the node was just added
                        # and the scene tree hasn't processed it yet.
                        var world_xform: Transform3D = inst.transform
                        var parent: Node = inst.get_parent()
                        while parent != null and parent != chunk_root:
                                if parent is Node3D:
                                        world_xform = (parent as Node3D).transform * world_xform
                                parent = parent.get_parent()
                        # chunk_root has no transform, so world = local of chunk_root * accumulated
                        mm.set_instance_transform(i, world_xform)
                        inst.queue_free()  # Remove the original MeshInstance3D

                var mmi := MultiMeshInstance3D.new()
                mmi.multimesh = mm
                mmi.name = "MultiMesh_%d_%s" % [list.size(), mesh_path.get_file()]
                chunk_root.add_child(mmi)
                batched += list.size()

        if batched > 0:
                print("  [G.2] Batched %d mesh instances into MultiMesh" % batched)

# Recursively find all MeshInstance3D nodes under a node
func _collect_meshes(node: Node, by_mesh: Dictionary) -> void:
        for child in node.get_children():
                if child is MeshInstance3D:
                        var mi: MeshInstance3D = child
                        if mi.mesh != null:
                                var key: String = mi.mesh.resource_path
                                if not key.is_empty():
                                        if not by_mesh.has(key):
                                                by_mesh[key] = []
                                        by_mesh[key].append(mi)
                # Recurse into children (GLB instances have nested meshes)
                _collect_meshes(child, by_mesh)

func _unload_chunk(key: Vector2i) -> void:
        var inst: Node3D = _loaded[key]
        inst.queue_free()
        _loaded.erase(key)

func _face_nearest_road(pos: Vector3, _crng: RandomNumberGenerator) -> float:
        # Phase G.1: O(1) road-facing using grid structure.
        # Roads are on 500m grid (CELL_SIZE_M). Nearest road is the closest
        # grid line in X or Z. No need to iterate all segments.
        var grid: float = CityConfig.CELL_SIZE_M  # 500m
        # Distance to nearest horizontal road (Z = k*500)
        var dz: float = pos.z - grid * round(pos.z / grid)
        # Distance to nearest vertical road (X = k*500)
        var dx: float = pos.x - grid * round(pos.x / grid)

        if abs(dz) < abs(dx):
                # Nearest is a horizontal road — face toward it in Z
                if dz > 0:
                        return PI  # face -Z (toward road at lower Z)
                else:
                        return 0.0  # face +Z (toward road at higher Z)
        else:
                # Nearest is a vertical road — face toward it in X
                if dx > 0:
                        return -PI * 0.5  # face -X
                else:
                        return PI * 0.5  # face +X

static func _point_segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
        var ab: Vector3 = b - a
        if ab.length_squared() < 0.001:
                return p.distance_to(a)
        var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
        return p.distance_to(a + ab * t)

static func _nearest_point_on_segment(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
        var ab: Vector3 = b - a
        if ab.length_squared() < 0.001:
                return a
        var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
        return a + ab * t

func _get_asset(p_name: String) -> PackedScene:
        if asset_cache.has(p_name):
                return asset_cache[p_name]
        if not manifest.has(p_name):
                return null
        var s: PackedScene = load(manifest[p_name]["path"]) as PackedScene
        asset_cache[p_name] = s
        return s

# === Phase F: POI helpers ===
var _pois_cache: Array = []

func _load_pois() -> void:
        if not _pois_cache.is_empty():
                return
        var f := FileAccess.open("res://data/pois.json", FileAccess.READ)
        if f == null:
                return
        var data: Dictionary = JSON.parse_string(f.get_as_text())
        _pois_cache = data.get("pois", [])

func _get_pois_for_chunk(origin: Vector3, chunk_size: float) -> Array:
        _load_pois()
        var result: Array = []
        var cx_min: float = origin.x
        var cx_max: float = origin.x + chunk_size
        var cz_min: float = origin.z
        var cz_max: float = origin.z + chunk_size
        for poi in _pois_cache:
                var px: float = float(poi.pos[0])
                var pz: float = float(poi.pos[2])
                if px >= cx_min and px < cx_max and pz >= cz_min and pz < cz_max:
                        result.append(poi)
        return result

static func _is_in_poi_exclusion(pos: Vector3, exclusions: Array) -> bool:
        for exc in exclusions:
                var center: Vector3 = exc["center"]
                var radius: float = exc["radius"]
                if pos.distance_to(center) < radius:
                        return true
        return false
