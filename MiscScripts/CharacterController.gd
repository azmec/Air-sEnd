extends Node
var tileMap = null
var worldGenerator = null
var enemies = null

signal no_valid_move

func init(tilemap_ref, worldGenerator_ref, enemies_ref):
	tileMap = tilemap_ref
	worldGenerator = worldGenerator_ref
	enemies = enemies_ref

func move_character(character, sprite, direction):
	# get current character coordinates
	var coordinates = world_position_to_map_position(character.global_position)
	# store these coordinates into a seperate variable
	var past_coordinates = coordinates.duplicate()
	# move character's coordinates on the x axis
	coordinates[0] += direction[0]
	# move character's coordinates on the y axis
	coordinates[1] += direction[1]
	# if we can move there,
	if valid_move(coordinates):
		# actually move the character
		character.global_position = worldGenerator.map_coord_to_world_pos(coordinates)
		return true
	else:
		emit_signal("no_valid_move")
		character.global_position = character.global_position
		return false

# map world coordinates to "map" coordinates
func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates

# check if the move is valid
func valid_move(coordinates):
	# if the tile cell has a value greater than or equal to 0, i.e if it is filled in
	if tileMap.get_cell(coordinates[0], coordinates[1]) >= 0:
		return false
	if coordinates in enemies:
		return false
	else:
		return true

func no_valid_move():
	return true
