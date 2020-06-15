extends Node2D

var sight_points = []
# returns true if we have line of sight
func get_line_of_sight(starting_coordinates, ending_coordinates, tilemap: TileMap):
	# get the (x, y) of point A
	var x1 = starting_coordinates[0]
	var y1 = starting_coordinates[1]
	# get the (x, y) of point B
	var x2 = ending_coordinates[0]
	var y2 = ending_coordinates[1]
	# get the distance between points A and B
	var dx = x2 - x1 
	var dy = y2 - y1
	# determine if the line is steep or not
	var is_steep = abs(dy) > abs(dx)
	var temporary = 0
	# Rotate the line
	var swapped = false
	if is_steep:
		# store x1 in temporary variable
		temporary = x1
		# modify x1 such that it equals y1
		x1 = y1
		# x2 is now equal to what x1 was
		x2 = temporary
		# store y1 in temporary variable
		temporary = y1
		y1 = y2
		y2 = temporary
		swapped = true
	# recalculate distance
	dx = x2 - x1
	dy = y2 - y1 
	# calculate error
	var error = (int(dx / 2.0))
	var ystep = 1 if y1 < y2 else -1
	# iterate over bounding box generated points between start and end
	var y = y1 
	var points = [] 
	# append coordinates to points list
	for x in range(x1, x2 + 1):
		var coordinates = [y, x] if is_steep else [x, y] 
		points.append(coordinates) 
		error -= abs(dy)
		if error < 0:
			y += ystep 
			error += dx 
	# if we swapped the coordinates earlier we need to invert them now
	if swapped: 
		points.invert() 
	sight_points = []
	# append points to sight points, which are relative to tile coordinates ?
	for p in points:
		sight_points.append(to_local(Vector2.ONE * 8 + tilemap.map_to_world(Vector2(p[0], p[1])))) 
	# update
	# go through each point and if they are tiled, return false
	for point in points:
		if tilemap.get_cell(point[0], point[1]) >= 0:
			return false
	# else return true
	return true

# generate path
func get_grid_path(starting_coordinates, ending_coordinates, aStar: AStar2D, aStar_points_cache: Dictionary):
	var path = aStar.get_point_path(aStar_points_cache[str(starting_coordinates)], aStar_points_cache[str(ending_coordinates)])
	if path == null:
		path = starting_coordinates
	return path

# DEBUG
#func _draw(): 
#	for sp in sight_points:
#		draw_circle(sp, 4, Color.red)
