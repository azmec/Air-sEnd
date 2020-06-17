extends Node2D

# this is a terrible idea because it makes this code dependant on tree structure
onready var tileMap = get_tree().get_root().get_node("Main").find_node("WallTiles")
onready var player = get_tree().get_root().get_node("Main").find_node("Player")
onready var main = get_tree().get_root().get_node("Main")
onready var characterController = $CharacterController
onready var lineOfSight = $LineOfSight
onready var sprite = $Sprite
var is_enemy_turn = false
var tileMap_ref = null
var aStar_ref = null
var aStar_points_cache_ref = null
var RIGHT = [1, 0]
var LEFT = [-1, 0]
var UP = [0, -1]
var DOWN = [0, 1]
func _ready():
	characterController.init(tileMap)
func _process(_delta):
	var player_coordinates = world_position_to_map_position(player.global_position)
	var current_coordinates = world_position_to_map_position(self.global_position)
	lineOfSight.get_line_of_sight(current_coordinates, player_coordinates, tileMap)
	if is_enemy_turn:
		var path = lineOfSight.get_grid_path(current_coordinates, player_coordinates, main.aStar, main.aStar_points_cache)
		if path.size() > 1:
			if current_coordinates[0] < int(round(path[1].x)):
				characterController.move_character(self, RIGHT)
				is_enemy_turn = false
			if current_coordinates[0] > int(round(path[1].x)):
				characterController.move_character(self, LEFT)
				is_enemy_turn = false
			if current_coordinates[1] < int(round(path[1].y)):
				characterController.move_character(self, DOWN)
				is_enemy_turn = false
			if current_coordinates[1] > int(round(path[1].y)):
				is_enemy_turn = false
				characterController.move_character(self, UP)
func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates
