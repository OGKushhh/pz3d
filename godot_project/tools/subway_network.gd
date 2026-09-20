# SubwayNetwork — parallel underground layer beneath the surface world.
#
# Phase A.3 (2026-09-12): Subway is no longer a surface biome (Biome.SUBWAY removed).
# Instead, subway tunnels run beneath ANY surface biome at Y ≈ -8m.
# Stations are POIs placed on the surface (entrance stairs go down).
# Tunnels connect stations.
#
# Status: STUB. Class skeleton only. Implementation deferred to Phase F (POI system).
# When implemented:
#   1. Generate station list from POIs.json (filter type="subway_station")
#   2. Connect stations with tunnel splines (Delaunay triangulation or hand-authored)
#   3. Each tunnel is a subway_tunnel chunk loaded lazily when player enters
#   4. Station entrance (ticket_booth + emergency_exit_stairs) is a surface POI
#   5. Player descends via stairs → loads subway chunk
#
# Asset placement (when implemented):
#   - subway_platform: at each station
#   - subway_tunnel: along tunnel splines
#   - subway_train_car: derelict, placed at random positions along tunnels
#   - ticket_booth: at station entrances (surface)
#   - turnstile: inside station entrances
#   - maintenance_tunnel_junction: at tunnel intersections
#   - emergency_exit_stairs: at intervals along tunnels
#   - subway_pipe_cluster: along tunnel walls
class_name SubwayNetwork
extends RefCounted

const CFG := preload("res://tools/city_config.gd")

# Tunnel depth below surface (m). Surface at Y=0, tunnel ceiling at Y=-6, floor at Y=-10.
const TUNNEL_CEILING_Y := -6.0
const TUNNEL_FLOOR_Y := -10.0
const TUNNEL_RADIUS := 2.5  # half-width of tunnel cross-section

var stations: Array = []  # Array[Dictionary] with keys: id, surface_pos, biome
var tunnels: Array = []   # Array[Dictionary] with keys: from_station, to_station, length, spline_points

func _init() -> void:
	pass

# Generate subway network from POI data.
# Called once at game start (or when POIs.json is loaded).
# TODO Phase F: implement.
func generate_from_pois(pois: Array) -> void:
	stations.clear()
	tunnels.clear()
	for poi in pois:
		if poi.get("type", "") == "subway_station":
			stations.append({
				"id": poi["id"],
				"surface_pos": Vector3(poi["pos"][0], 0.0, poi["pos"][2]),
				"biome": poi.get("biome", CFG.Biome.DOWNTOWN),
			})
	# TODO: connect stations with tunnels (Delaunay or hand-authored graph)
	print("[SubwayNetwork] Generated %d stations (tunnel connections: TODO)" % stations.size())

# Returns the nearest station to a world position.
# TODO Phase F: implement (currently returns null).
func nearest_station_to(world_pos: Vector3) -> Variant:
	if stations.is_empty():
		return null
	var best_dist := INF
	var best: Variant = null
	for s in stations:
		var d: float = s["surface_pos"].distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = s
	return best

# Returns true if the given world position is inside a subway tunnel.
# Used by AI to know if zombies can spawn underground.
# TODO Phase F: implement.
func is_in_tunnel(world_pos: Vector3) -> bool:
	return false

# Returns the tunnel Y at a given XZ position, or NaN if not in a tunnel.
# Used by subway_builder.gd to place tunnel chunks at the correct Y.
# TODO Phase F: implement.
func tunnel_y_at(world_x: float, world_z: float) -> float:
	return NAN
