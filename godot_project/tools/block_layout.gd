# BlockLayout — parcel-based block subdivision system.
#
# Phase B.5 (2026-09-14): Replaces the road-adjacent placement logic.
# Instead of "walk along road → place building perpendicular", each block
# (250m × 250m chunk) is subdivided into parcels. Each parcel has:
#   - A front (faces nearest road)
#   - A building slot (at front of parcel)
#   - A yard slot (behind building)
#   - Side boundaries
#
# Interior paths (NOT roads) connect parallel roads through block centers.
# Paths are visual only: a 3m-wide plane at Y=0.01. No is_on_road marking,
# no street lights, no road graph entries.
#
# Layout types per biome:
#   residential_grid: 6 parcels per road edge, house + backyard + fence
#   commercial_perimeter: storefronts flush with road, parking in center
#   industrial_yard: 2×2 large parcels, warehouses + loading docks
#   courtyard_block: buildings on perimeter, courtyard center
#   farmstead: 2-3 large parcels, farmhouse + barn + fields
#   forest_scatter: organic, no grid
#   park_layout: paths + benches + trees
#   marsh_scatter: organic
#
# DeepSeek's two risks:
#   1. Chunk state stays flat — buildings get parcel_id meta, middleware
#      sees no schema change. No silent failure.
#   2. Alleys = paths, not roads. No street lights, no is_on_road, no
#      road graph. Visual + structural only.
class_name BlockLayout
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

# Layout type per biome
const BIOME_LAYOUTS := {
        CityConfig.Biome.SUBURBIA: "residential_grid",
        CityConfig.Biome.PARKS: "park_layout",
        CityConfig.Biome.FOREST: "forest_scatter",
        CityConfig.Biome.FARMLAND: "farmstead",
        CityConfig.Biome.COMMERCIAL: "commercial_perimeter",
        CityConfig.Biome.INDUSTRIAL: "industrial_yard",
        CityConfig.Biome.WETLANDS: "marsh_scatter",
        CityConfig.Biome.DOWNTOWN: "courtyard_block",
        CityConfig.Biome.MILITARY: "checkpoint_grid",
        CityConfig.Biome.COASTAL_BEACH: "beach_strip",
}

# Returns the layout type for a biome.
static func layout_for_biome(biome: int) -> String:
        return BIOME_LAYOUTS.get(biome, "residential_grid")

# A single parcel within a block.
# Each parcel is a rectangular area with:
#   - bounds: AABB in XZ (min, max Vector2)
#   - front_dir: Vector3 direction the building should face (toward nearest road)
#   - building_pos: Vector3 where the building goes (at front of parcel)
#   - yard_pos: Vector3 where the backyard goes (behind building)
#   - parcel_id: unique ID for this parcel (for chunk_state meta)
#   - road_edge: which road edge this parcel faces ("N", "S", "E", "W")
#
# Phase B.7.2: Added road-aware fields (set by chunk_streamer after parcel
# generation, querying road_network.nearest_road_info). These are the ACTUAL
# road geometry, not the chunk-grid assumption. LotStamper uses road_edge_pos
# as the start point for sidewalk + driveway strips.
#   - road_edge_pos: Vector3 — nearest point on road centerline to building_pos
#   - road_distance: float — distance from building_pos to road_edge_pos
#   - road_dir: Vector3 — direction of the nearest road segment
class Parcel:
        var bounds_min: Vector2
        var bounds_max: Vector2
        var front_dir: Vector3
        var building_pos: Vector3
        var yard_pos: Vector3
        var parcel_id: String
        var road_edge: String  # "N", "S", "E", "W"
        # Phase B.7.2: actual road geometry (set by chunk_streamer, not by _init)
        var road_edge_pos: Vector3 = Vector3.ZERO  # nearest point on road centerline
        var road_distance: float = 0.0              # distance from building_pos to road_edge_pos
        var road_dir: Vector3 = Vector3(0, 0, 1)    # direction of nearest road segment

        func _init(min_pos: Vector2, max_pos: Vector2, edge: String, origin: Vector3, chunk_size: float):
                bounds_min = min_pos
                bounds_max = max_pos
                road_edge = edge
                # Calculate building + yard positions
                var center := (min_pos + max_pos) * 0.5
                match edge:
                        "N":  # faces north (toward -Z)
                                front_dir = Vector3(0, 0, -1)
                                building_pos = Vector3(center.x, 0, min_pos.y + (max_pos.y - min_pos.y) * 0.25)
                                yard_pos = Vector3(center.x, 0, min_pos.y + (max_pos.y - min_pos.y) * 0.75)
                        "S":  # faces south (toward +Z)
                                front_dir = Vector3(0, 0, 1)
                                building_pos = Vector3(center.x, 0, max_pos.y - (max_pos.y - min_pos.y) * 0.25)
                                yard_pos = Vector3(center.x, 0, max_pos.y - (max_pos.y - min_pos.y) * 0.75)
                        "E":  # faces east (toward +X)
                                front_dir = Vector3(1, 0, 0)
                                building_pos = Vector3(max_pos.x - (max_pos.x - min_pos.x) * 0.25, 0, center.y)
                                yard_pos = Vector3(max_pos.x - (max_pos.x - min_pos.x) * 0.75, 0, center.y)
                        "W":  # faces west (toward -X)
                                front_dir = Vector3(-1, 0, 0)
                                building_pos = Vector3(min_pos.x + (max_pos.x - min_pos.x) * 0.25, 0, center.y)
                                yard_pos = Vector3(min_pos.x + (max_pos.x - min_pos.x) * 0.75, 0, center.y)
                parcel_id = "%s_%d_%d" % [edge, int(center.x), int(center.y)]

# Generate parcels for a chunk based on its layout type.
# Returns Array[Parcel].
static func generate_parcels(layout_type: String, origin: Vector3, chunk_size: float) -> Array:
        match layout_type:
                "residential_grid":
                        return _gen_residential_grid(origin, chunk_size)
                "commercial_perimeter":
                        return _gen_commercial_perimeter(origin, chunk_size)
                "industrial_yard":
                        return _gen_industrial_yard(origin, chunk_size)
                "courtyard_block":
                        return _gen_courtyard_block(origin, chunk_size)
                "farmstead":
                        return _gen_farmstead(origin, chunk_size)
                "forest_scatter":
                        return _gen_forest_scatter(origin, chunk_size)
                "park_layout":
                        return []  # parks handled by existing _place_park
                "marsh_scatter":
                        return []  # marsh handled by foliage scatter
                "checkpoint_grid":
                        return _gen_checkpoint_grid(origin, chunk_size)
                "beach_strip":
                        return _gen_beach_strip(origin, chunk_size)
                _:
                        return _gen_residential_grid(origin, chunk_size)

# Residential grid: 6 parcels per N/S edge + 4 per E/W edge = 20 parcels.
# Each parcel ~42m wide × ~100m deep. Building at front, yard at back.
# Interior path runs E-W through center.
static func _gen_residential_grid(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 12.0  # margin from chunk edge to first parcel
        var parcel_count_ns := 6  # parcels per north/south edge
        var parcel_count_ew := 4   # parcels per east/west edge (skip corners)
        var usable_w := chunk_size - margin * 2
        var usable_d := chunk_size - margin * 2
        var parcel_w := usable_w / parcel_count_ns
        var parcel_d_ew := usable_w / parcel_count_ew
        var parcel_d := (usable_d - 6.0) * 0.5  # half depth (path takes 6m in center)
        # North edge parcels
        for i in range(parcel_count_ns):
                var x_min := origin.x + margin + i * parcel_w
                var x_max := x_min + parcel_w
                var z_min := origin.z + margin
                var z_max := z_min + parcel_d
                parcels.append(Parcel.new(Vector2(x_min, z_min), Vector2(x_max, z_max), "N", origin, chunk_size))
        # South edge parcels
        for i in range(parcel_count_ns):
                var x_min := origin.x + margin + i * parcel_w
                var x_max := x_min + parcel_w
                var z_max := origin.z + chunk_size - margin
                var z_min := z_max - parcel_d
                parcels.append(Parcel.new(Vector2(x_min, z_min), Vector2(x_max, z_max), "S", origin, chunk_size))
        # East edge parcels (skip corners — already have N/S)
        for i in range(parcel_count_ew):
                var z_min := origin.z + margin + i * parcel_d_ew
                var z_max := z_min + parcel_d_ew
                var x_max := origin.x + chunk_size - margin
                var x_min := x_max - parcel_d
                parcels.append(Parcel.new(Vector2(x_min, z_min), Vector2(x_max, z_max), "E", origin, chunk_size))
        # West edge parcels
        for i in range(parcel_count_ew):
                var z_min := origin.z + margin + i * parcel_d_ew
                var z_max := z_min + parcel_d_ew
                var x_min := origin.x + margin
                var x_max := x_min + parcel_d
                parcels.append(Parcel.new(Vector2(x_min, z_min), Vector2(x_max, z_max), "W", origin, chunk_size))
        return parcels

# Commercial perimeter: storefronts flush with road on all 4 sides.
# Parking lot in center. No backyards.
static func _gen_commercial_perimeter(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 5.0  # commercial buildings close to road
        var store_depth := 25.0  # storefront depth
        # North edge
        for i in range(5):
                var x_min := origin.x + margin + i * (chunk_size - margin * 2) / 5.0
                var x_max := x_min + (chunk_size - margin * 2) / 5.0
                parcels.append(Parcel.new(Vector2(x_min, origin.z + margin), Vector2(x_max, origin.z + margin + store_depth), "N", origin, chunk_size))
        # South edge
        for i in range(5):
                var x_min := origin.x + margin + i * (chunk_size - margin * 2) / 5.0
                var x_max := x_min + (chunk_size - margin * 2) / 5.0
                parcels.append(Parcel.new(Vector2(x_min, origin.z + chunk_size - margin - store_depth), Vector2(x_max, origin.z + chunk_size - margin), "S", origin, chunk_size))
        # East edge
        for i in range(4):
                var z_min := origin.z + margin + store_depth + i * (chunk_size - margin * 2 - store_depth * 2) / 4.0
                var z_max := z_min + (chunk_size - margin * 2 - store_depth * 2) / 4.0
                parcels.append(Parcel.new(Vector2(origin.x + chunk_size - margin - store_depth, z_min), Vector2(origin.x + chunk_size - margin, z_max), "E", origin, chunk_size))
        # West edge
        for i in range(4):
                var z_min := origin.z + margin + store_depth + i * (chunk_size - margin * 2 - store_depth * 2) / 4.0
                var z_max := z_min + (chunk_size - margin * 2 - store_depth * 2) / 4.0
                parcels.append(Parcel.new(Vector2(origin.x + margin, z_min), Vector2(origin.x + margin + store_depth, z_max), "W", origin, chunk_size))
        return parcels

# Industrial yard: 2×2 large parcels, each ~100m × 100m.
static func _gen_industrial_yard(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 15.0
        var half := (chunk_size - margin * 2) * 0.5
        # 4 large parcels
        for row in range(2):
                for col in range(2):
                        var x_min := origin.x + margin + col * half
                        var x_max := x_min + half
                        var z_min := origin.z + margin + row * half
                        var z_max := z_min + half
                        var edge := "N" if row == 0 else "S"
                        parcels.append(Parcel.new(Vector2(x_min, z_min), Vector2(x_max, z_max), edge, origin, chunk_size))
        return parcels

# Courtyard block: buildings on perimeter, courtyard in center.
static func _gen_courtyard_block(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 8.0
        var bldg_depth := 30.0
        # Similar to commercial but with larger buildings
        for i in range(4):
                var x_min := origin.x + margin + i * (chunk_size - margin * 2) / 4.0
                var x_max := x_min + (chunk_size - margin * 2) / 4.0
                parcels.append(Parcel.new(Vector2(x_min, origin.z + margin), Vector2(x_max, origin.z + margin + bldg_depth), "N", origin, chunk_size))
                parcels.append(Parcel.new(Vector2(x_min, origin.z + chunk_size - margin - bldg_depth), Vector2(x_max, origin.z + chunk_size - margin), "S", origin, chunk_size))
        for i in range(2):
                var z_min := origin.z + margin + bldg_depth + i * (chunk_size - margin * 2 - bldg_depth * 2) / 2.0
                var z_max := z_min + (chunk_size - margin * 2 - bldg_depth * 2) / 2.0
                parcels.append(Parcel.new(Vector2(origin.x + margin, z_min), Vector2(origin.x + margin + bldg_depth, z_max), "W", origin, chunk_size))
                parcels.append(Parcel.new(Vector2(origin.x + chunk_size - margin - bldg_depth, z_min), Vector2(origin.x + chunk_size - margin, z_max), "E", origin, chunk_size))
        return parcels

# Farmstead: 2-3 large parcels.
static func _gen_farmstead(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 20.0
        parcels.append(Parcel.new(
                Vector2(origin.x + margin, origin.z + margin),
                Vector2(origin.x + chunk_size * 0.5, origin.z + chunk_size * 0.6),
                "N", origin, chunk_size))
        parcels.append(Parcel.new(
                Vector2(origin.x + chunk_size * 0.55, origin.z + margin),
                Vector2(origin.x + chunk_size - margin, origin.z + chunk_size * 0.5),
                "N", origin, chunk_size))
        return parcels

# Forest scatter: no grid, organic positions.
static func _gen_forest_scatter(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        # 3 random cabin positions
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(origin) ^ 42
        for i in range(3):
                var x := origin.x + rng.randf_range(30, chunk_size - 30)
                var z := origin.z + rng.randf_range(30, chunk_size - 30)
                parcels.append(Parcel.new(
                        Vector2(x - 15, z - 15),
                        Vector2(x + 15, z + 15),
                        "N", origin, chunk_size))
        return parcels

# Military checkpoint grid.
static func _gen_checkpoint_grid(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 15.0
        for row in range(3):
                for col in range(3):
                        var x_min := origin.x + margin + col * (chunk_size - margin * 2) / 3.0
                        var x_max := x_min + (chunk_size - margin * 2) / 3.0
                        var z_min := origin.z + margin + row * (chunk_size - margin * 2) / 3.0
                        var z_max := z_min + (chunk_size - margin * 2) / 3.0
                        var edge := "N" if row == 0 else ("S" if row == 2 else "E")
                        parcels.append(Parcel.new(Vector2(x_min, z_min), Vector2(x_max, z_max), edge, origin, chunk_size))
        return parcels

# Beach strip: buildings along south edge.
static func _gen_beach_strip(origin: Vector3, chunk_size: float) -> Array:
        var parcels: Array = []
        var margin := 10.0
        for i in range(4):
                var x_min := origin.x + margin + i * (chunk_size - margin * 2) / 4.0
                var x_max := x_min + (chunk_size - margin * 2) / 4.0
                parcels.append(Parcel.new(
                        Vector2(x_min, origin.z + chunk_size - margin - 30),
                        Vector2(x_max, origin.z + chunk_size - margin),
                        "S", origin, chunk_size))
        return parcels

# Get the interior path segments for a layout type.
# Paths are visual-only (no collision, no is_on_road, no street lights).
# Returns Array of {start: Vector3, end: Vector3, width: float}.
static func get_interior_paths(layout_type: String, origin: Vector3, chunk_size: float) -> Array:
        match layout_type:
                "residential_grid":
                        # One path running E-W through center
                        var mid_z := origin.z + chunk_size * 0.5
                        return [
                                {"start": Vector3(origin.x + 12, 0, mid_z), "end": Vector3(origin.x + chunk_size - 12, 0, mid_z), "width": 3.0},
                                {"start": Vector3(origin.x + chunk_size * 0.5, 0, origin.z + 12), "end": Vector3(origin.x + chunk_size * 0.5, 0, origin.z + chunk_size - 12), "width": 3.0},
                        ]
                "commercial_perimeter":
                        # Cross paths through center (for pedestrian access to stores)
                        return [
                                {"start": Vector3(origin.x + 10, 0, origin.z + chunk_size * 0.5), "end": Vector3(origin.x + chunk_size - 10, 0, origin.z + chunk_size * 0.5), "width": 4.0},
                                {"start": Vector3(origin.x + chunk_size * 0.5, 0, origin.z + 10), "end": Vector3(origin.x + chunk_size * 0.5, 0, origin.z + chunk_size - 10), "width": 4.0},
                        ]
                "courtyard_block":
                        # Circular-ish path around courtyard
                        return [
                                {"start": Vector3(origin.x + chunk_size * 0.3, 0, origin.z + chunk_size * 0.5), "end": Vector3(origin.x + chunk_size * 0.7, 0, origin.z + chunk_size * 0.5), "width": 4.0},
                        ]
                _:
                        return []  # no paths for other layouts
