@tool
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPatrolPath.svg")
extends Node3D
class_name CogitoPatrolPath

## List of patrol points which the enemy will move to in order.
@export var starting_patrol_point : CogitoPatrolPoint
## If true, then once reaching the final patrol point the next point will be the start, rather than traversing back through the previous points
@export var starting_point_as_next_on_end: bool = true

var current_patrol_point: CogitoPatrolPoint

@export_tool_button("Generate Patrol Path", "Path3D") var button = generate_path
## Simulates the patrol path with an NPC rather than a default agent. Its recommended to use this
## since it can be useful in testing if an NPCs nav-agent can complete the patrol path
@export var simulate_with: CogitoNPC

func target_next_patrol_point() -> CogitoPatrolPoint:
	if not current_patrol_point:
		current_patrol_point = starting_patrol_point
	current_patrol_point = current_patrol_point.get_next_point()
	return current_patrol_point

## Generates a patrol path by simulating a path
func generate_path():
	if not Engine.is_editor_hint():
		return
	
	# Clear the existing generated path and failure mesh
	for path in find_children("", "Path3D", false):
		path.free()
	for mesh in find_children("", "MeshInstance3D", false):
		mesh.free()
	
	# Bail out if there is no starting patrol point
	if not starting_patrol_point:
		printerr("No starting patrol path is assigned!")
		return
	
	# Bail out if the starting patrol point has no other links
	var patrol_point: CogitoPatrolPoint = starting_patrol_point
	if patrol_point.next_patrol_points.is_empty():
		printerr("Cannot generate a patrol path from a single point!")
		return
		
	# Clear previous traversal state
	starting_patrol_point.clear_traversals_bools()

	var original_transform = simulate_with.global_transform if simulate_with else null
	
	# Create a blank agent if simulate_with is null, otherwise use the assigned NPC
	var nav_agent = simulate_with.find_children("", "NavigationAgent3D").front() if simulate_with else NavigationAgent3D.new()
	nav_agent.target_position = Vector3.ZERO
	var nav_pointer = simulate_with if simulate_with else Node3D.new()
	if not simulate_with:
		patrol_point.add_child(nav_pointer)
		nav_pointer.add_child(nav_agent)
		nav_agent.owner = get_tree().edited_scene_root
		nav_pointer.owner = get_tree().edited_scene_root
	
	# Create an empty path at the NPC if applicable or at the first patrol point
	var path = create_empty_path()
	path.owner = get_tree().edited_scene_root
	path.global_position = simulate_with.global_position if simulate_with else patrol_point.global_position
	
	# Loop until the path reaches the start position
	while(nav_agent.target_position != starting_patrol_point.global_position):
		# Set the next path to traverse with the nav_agent
		patrol_point = patrol_point.get_next_point()
		nav_pointer.look_at(patrol_point.global_position, Vector3.UP)
		nav_agent.target_position = patrol_point.global_position
		# Add all points in the path to the path curve
		while not nav_agent.is_target_reached():
			await get_tree().physics_frame
			var point = nav_agent.get_next_path_position()
			path.curve.add_point(path.to_local(point))
			nav_pointer.global_position = point
			# Failure state, bail out with a failure mesh node showing the point that can't pathfind
			if not nav_agent.is_target_reachable():
				generate_pathing_failure(point)
				printerr("Unable to generate a complete path. Adjust your NavigationAgent3D or geometry.")
				if simulate_with:
					simulate_with.global_transform = original_transform
				return
			
		# Move the nav agent to the patrol point
		nav_pointer.global_position = patrol_point.global_position
	
	# Delete the nav pointer
	if not simulate_with:
		nav_pointer.free()
	
	# Reset the original NPC transform if applicable
	if simulate_with:
		simulate_with.global_transform = original_transform

func generate_pathing_failure(pos: Vector3):
	var failure_point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_RED
	failure_point.name = "PathfindingFail"
	sphere.radius = 0.5
	sphere.height = 1
	sphere.material = mat
	failure_point.mesh = sphere
	add_child(failure_point)
	failure_point.global_position = pos
	failure_point.owner = get_tree().edited_scene_root

func create_empty_path() -> Path3D:
	var path = Path3D.new()
	path.name = "PatrolPath"
	path.debug_custom_color = Color(1,0,0)	
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3.ZERO)
	add_child(path)
	return path
