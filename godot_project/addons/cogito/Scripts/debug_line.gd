## This is DrawLine3D from https://github.com/klaykree/Godot-3D-Lines, just changed to snake_case rather than CamelCase
## and type hinted all the variables
extends Node2D

class Line:
	var start: Vector3
	var end: Vector3
	var line_color: Color
	var time: float
	
	func _init(start: Vector3, end: Vector3, line_color: Color, time: float):
		self.start = start
		self.end = end
		self.line_color = line_color
		self.time = time

var lines: Array = []
var removed_line: bool = false

func _process(delta):
	for i in range(len(lines)):
		lines[i].time -= delta
	
	if(len(lines) > 0 || removed_line):
		queue_redraw() #Calls _draw
		removed_line = false

func _draw():
	var cam = get_viewport().get_camera_3d()
	for i in range(len(lines)):
		var screen_point_start = cam.unproject_position(lines[i].start)
		var screen_point_end = cam.unproject_position(lines[i].end)
		
		#Dont draw line if either start or end is considered behind the camera
		#this causes the line to not be drawn sometimes but avoids a bug where the
		#line is drawn incorrectly
		if(cam.is_position_behind(lines[i].start) ||
			cam.is_position_behind(lines[i].end)):
			continue
		
		draw_line(screen_point_start, screen_point_end, lines[i].line_color)
	
	#Remove lines that have timed out
	var i = lines.size() - 1
	while (i >= 0):
		if(lines[i].time < 0.0):
			lines.remove_at(i)
			removed_line = true
		i -= 1

func draw_3d_line(start: Vector3, end: Vector3, line_color: Color, time: float = 0.0):
	lines.append(Line.new(start, end, line_color, time))

func draw_ray(start: Vector3, ray: Vector3, line_color: Color, time: float = 0.0):
	lines.append(Line.new(start, start + ray, line_color, time))

func draw_cube(center: Vector3, half_extents: float, line_color: Color, time: float = 0.0):
	#Start at the 'top left'
	var line_point_start = center
	line_point_start.x -= half_extents
	line_point_start.y += half_extents
	line_point_start.z -= half_extents
	
	#Draw top square
	var line_point_end = line_point_start + Vector3(0, 0, half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(0, 0, -half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(-half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	
	#Draw bottom square
	line_point_start = line_point_end + Vector3(0, -half_extents * 2.0, 0)
	line_point_end = line_point_start + Vector3(0, 0, half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(0, 0, -half_extents * 2.0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	line_point_start = line_point_end
	line_point_end = line_point_start + Vector3(-half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, line_point_end, line_color, time);
	
	#Draw vertical lines
	line_point_start = line_point_end
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
	line_point_start += Vector3(0, 0, half_extents * 2.0)
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
	line_point_start += Vector3(half_extents * 2.0, 0, 0)
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
	line_point_start += Vector3(0, 0, -half_extents * 2.0)
	draw_3d_line(line_point_start, Vector3(0, half_extents * 2.0, 0), line_color, time)
