# CityGenConfig — single source of truth for all city generation tuning values.
#
# Phase F.0 Refactor 1: Extracts shared constants from map_baker.gd + chunk_streamer.gd
# so both drivers read from ONE place. Per-biome tuning moves here.
#
# Usage:
#   var config = CityGenConfig.new()
#   config.seed = 1337
#   var density = config.get_density_mult(CityConfig.Biome.SUBURBIA)
#   var foliage = config.get_foliage_mult(CityConfig.Biome.FOREST)

class_name CityGenConfig
extends RefCounted

const CityConfig = preload("res://tools/city_config.gd")

# === GLOBAL SETTINGS ===
var seed: int = 1337
var map_size_m: Vector2 = CityConfig.MAP_SIZE_M
var chunk_size_m: float = CityConfig.CHUNK_SIZE_M
var chunks_cols: int = CityConfig.CHUNKS_COLS
var chunks_rows: int = CityConfig.CHUNKS_ROWS

# === GLOBAL MULTIPLIERS ===
# Applied on top of per-biome values. Default 1.0 = no change.
var density_mult: float = 1.0
var prop_mult: float = 1.0
var foliage_mult: float = 1.0
var height_mult: float = 1.0

# === Y LAYERING (roads above sidewalks) ===
const Y_GROUND := 0.000
const Y_GRASS := 0.005
const Y_PATH := 0.010
const Y_DRIVEWAY := 0.015
const Y_SIDEWALK := 0.040
const Y_PARKING := 0.050
const Y_ROAD := 0.060
const Y_LANE := 0.065
const Y_BUILDING_SLAB := 0.070
const Y_PARK := 0.005

# === ROAD/SIDEWALK WIDTHS ===
const ROAD_WIDTH := 8.0
const SIDEWALK_WIDTH := 1.5
const GRASS_STRIP_WIDTH := 2.5
const BUILDING_SETBACK := 1.5
const LOT_W := 20.0
const LOT_D := 16.0
const MIN_CLEARANCE_M := 2.0
const HIGHWAY_CLEARANCE_M := 15.0

# === COLORS ===
const C_ROAD := Color(0.12, 0.12, 0.14, 1)
const C_LANE := Color(0.90, 0.88, 0.82, 1)
const C_SIDEWALK := Color(0.70, 0.68, 0.64, 1)
const C_GRASS := Color(0.22, 0.40, 0.16, 1)
const C_PARK := Color(0.18, 0.38, 0.14, 1)
const C_HIGHWAY := Color(0.08, 0.08, 0.10, 1)
const C_LOCAL := Color(0.16, 0.16, 0.18, 1)
const C_WATER := Color(0.15, 0.30, 0.45, 0.7)

# === PER-BIOME DENSITY (buildings target per chunk) ===
# Single source of truth — both map_baker.gd and chunk_streamer.gd read from here.
const BIOME_DENSITY_MULT := {
	CityConfig.Biome.SUBURBIA: 50,
	CityConfig.Biome.PARKS: 5,
	CityConfig.Biome.FOREST: 5,
	CityConfig.Biome.FARMLAND: 10,
	CityConfig.Biome.COMMERCIAL: 100,
	CityConfig.Biome.INDUSTRIAL: 60,
	CityConfig.Biome.WETLANDS: 3,
	CityConfig.Biome.DOWNTOWN: 120,
	CityConfig.Biome.MILITARY: 40,
	CityConfig.Biome.COASTAL_BEACH: 8,
	CityConfig.Biome.WATER: 0,
	CityConfig.Biome.EMPTY: 0,
}

# === PER-BIOME FOLIAGE (foliage target per chunk) ===
const BIOME_FOLIAGE_MULT := {
	CityConfig.Biome.SUBURBIA: 50,
	CityConfig.Biome.PARKS: 200,
	CityConfig.Biome.FOREST: 300,
	CityConfig.Biome.FARMLAND: 80,
	CityConfig.Biome.COMMERCIAL: 15,
	CityConfig.Biome.INDUSTRIAL: 20,
	CityConfig.Biome.WETLANDS: 250,
	CityConfig.Biome.DOWNTOWN: 10,
	CityConfig.Biome.MILITARY: 30,
	CityConfig.Biome.COASTAL_BEACH: 150,
	CityConfig.Biome.WATER: 0,
	CityConfig.Biome.EMPTY: 0,
}

# === PER-BIOME GAP FILLERS (props scattered between buildings) ===
const BIOME_GAP_FILLERS := {
	CityConfig.Biome.SUBURBIA: [
		"picket_fence", "mailbox", "trash_can", "garden_gnome",
		"planter_box", "fire_hydrant", "street_light", "bollard",
		"bench_park", "picnic_table", "water_fountain",
		"playground_slide", "swing_set", "seesaw",
		"shopping_cart", "traffic_cone"
	],
	CityConfig.Biome.COMMERCIAL: [
		"parking_meter", "shopping_cart", "dumpster", "trash_can",
		"bollard", "planter_box", "street_light", "traffic_cone",
		"construction_barrier", "bench_park", "picnic_table",
		"fire_hydrant", "mailbox", "traffic_light"
	],
	CityConfig.Biome.INDUSTRIAL: [
		"shipping_container", "storage_tank", "loading_dock",
		"dumpster", "construction_barrier", "barrier_concrete",
		"guard_rail", "chain_link_fence", "barbed_wire_fence",
		"sandbag", "traffic_cone", "bollard", "street_light",
		"utility_pole", "power_pole"
	],
	CityConfig.Biome.DOWNTOWN: [
		"bollard", "planter_box", "trash_can", "street_light",
		"bench_park", "water_fountain", "parking_meter",
		"traffic_light", "fire_hydrant", "construction_barrier",
		"turnstile", "manhole_cover", "sewer_grate"
	],
	CityConfig.Biome.MILITARY: [
		"barrier_concrete", "sandbag", "barbed_wire_fence",
		"chain_link_fence", "guard_rail", "bollard",
		"traffic_cone", "construction_barrier", "street_light",
		"shipping_container", "storage_tank"
	],
	CityConfig.Biome.FARMLAND: [
		"hay_bale", "wood_fence_post", "picket_fence",
		"irrigation_canal", "planter_box", "trash_can",
		"bench_park", "picnic_table", "fire_hydrant",
		"street_light", "mailbox", "garden_gnome"
	],
	CityConfig.Biome.COASTAL_BEACH: [
		"bench_park", "picnic_table", "trash_can", "planter_box",
		"street_light", "water_fountain", "gazebo", "park_sign",
		"mailbox", "traffic_cone"
	],
	CityConfig.Biome.WETLANDS: [
		"fallen_log", "rocks_small", "boardwalk_section",
		"trash_can", "park_sign"
	],
	CityConfig.Biome.PARKS: [
		"bench_park", "picnic_table", "playground_slide",
		"swing_set", "seesaw", "water_fountain", "park_sign",
		"planter_box", "trash_can", "garden_gnome",
		"fire_hydrant", "street_light"
	],
	CityConfig.Biome.FOREST: [
		"fallen_log", "rocks_small", "bush"
	],
}

# === ACCESSORS ===
func get_density_mult(biome: int) -> int:
	return int(BIOME_DENSITY_MULT.get(biome, 50) * density_mult)

func get_foliage_mult(biome: int) -> int:
	return int(BIOME_FOLIAGE_MULT.get(biome, 50) * foliage_mult)

func get_gap_fillers(biome: int) -> Array:
	return BIOME_GAP_FILLERS.get(biome, [
		"picket_fence", "planter_box", "trash_can", "mailbox",
		"fire_hydrant", "street_light", "bollard", "bench_park"
	])

func get_building_radius() -> float:
	return max(LOT_W, LOT_D) * 0.4

func get_building_offset() -> float:
	return ROAD_WIDTH * 0.5 + SIDEWALK_WIDTH + GRASS_STRIP_WIDTH + BUILDING_SETBACK
