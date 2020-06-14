extends Node2D

# this is a terrible idea because it makes this code dependant on tree structure
onready var tileMap = get_tree().get_root().get_node("Main").find_node("TileMap")
onready var player = get_tree().get_root().get_node("Main").find_node("Player")
onready var main = get_tree().get_root().get_node("Main")
onready var worldGenerator = get_tree().get_root().get_node("Main").find_node("WorldGenerator")
onready var characterController = $CharacterController
onready var lineOfSight = $LineOfSight
onready var sprite = $Sprite
var ready_to_move = false
signal killPlayer()
const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]

#func init(player_ref, tilemap_ref ): 
#	player = player_ref 
#	tileMap = tilemap_ref 
func _ready():
	var enemies = main.enemies
	characterController.init(tileMap, worldGenerator, enemies)
func _process(delta):
	var current_coordinates = world_position_to_map_position(self.global_position)
	var player_coordinates = world_position_to_map_position(player.global_position)
	lineOfSight.get_line_of_sight(current_coordinates, player_coordinates, tileMap)
	if ready_to_move:
		var path = lineOfSight.get_grid_path(current_coordinates, player_coordinates, main.aStar, main.aStar_points_cache)
		if path.size() > 1:
			if current_coordinates[0] < int(round(path[1].x)):
				characterController.move_character(self, sprite, RIGHT)
				ready_to_move = false
			if current_coordinates[0] > int(round(path[1].x)):
				characterController.move_character(self, sprite, LEFT)
				ready_to_move = false
			if current_coordinates[1] < int(round(path[1].y)):
				characterController.move_character(self, sprite, DOWN)
				ready_to_move = false
			if current_coordinates[1] > int(round(path[1].y)):
				ready_to_move = false
				characterController.move_character(self, sprite, UP)

func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates
