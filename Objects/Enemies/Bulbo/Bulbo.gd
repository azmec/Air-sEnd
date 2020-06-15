extends Node2D

onready var characterController = $CharacterController
onready var lineOfSight = $LineOfSight
onready var sprite = $Sprite
onready var player = get_tree().get_root().get_node("Main").find_node("Player")
var is_enemy_turn = false
var tileMap_ref = null
var aStar_ref = null
var aStar_points_cache_ref = null
const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]
func _initialize(aStar_points_cache_input, aStar_input, tileMap_input):
	aStar_points_cache_ref = aStar_points_cache_input
	aStar_ref= aStar_input 
	tileMap_ref = tileMap_input

func _process(delta):
	var player_coordinates = world_position_to_map_position(player.global_position)
	var current_coordinates = world_position_to_map_position(self.global_position)
	lineOfSight.get_line_of_sight(current_coordinates, player_coordinates, tileMap_ref)
	if is_enemy_turn:
		var path = lineOfSight.get_grid_path(current_coordinates, player_coordinates, aStar_ref, aStar_points_cache_ref)
		if path.size() > 1:
			if current_coordinates[0] < int(round(path[1].x)):
				characterController.move_character(self, sprite, RIGHT)
				is_enemy_turn = false
			if current_coordinates[0] > int(round(path[1].x)):
				characterController.move_character(self, sprite, LEFT)
				is_enemy_turn = false
			if current_coordinates[1] < int(round(path[1].y)):
				characterController.move_character(self, sprite, DOWN)
				is_enemy_turn = false
			if current_coordinates[1] > int(round(path[1].y)):
				is_enemy_turn = false
				characterController.move_character(self, sprite, UP)

func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap_ref.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates
