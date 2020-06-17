extends Node2D 

var scene_root = null
var current_level = 1
var player = null 
var exit = null 
var alternateExit = null
var tilemap = null
onready var aStar = AStar2D.new() 
var aStar_points_cache = {}
var treasure_index = 0
var spawn_key = true
var spawn_note = false
var treasures = [
	{
		"object": "OxygenCanister",
		"scene_object": preload("res://Objects/Treasures/OxygenCanister.tscn"),
		"header": "Oxygen Canister.",
		"message": "They made as many as they could.\nRefill oxygen.",
		"image": preload("res://Assets/Treasures/OxygenCanister.png")
	},
	{
		"object": "LeatherBoots",
		"scene_object": preload("res://Objects/Treasures/LeatherBoots.tscn"),
		"header": "Leather Boots.",
		"message": "A fine fit.\n+1 Move Per Turn.",
		"image": preload("res://Assets/Treasures/LeatherBoots.png")
	},
	{
		"object": "WornHelm",
		"scene_object": preload("res://Objects/Treasures/WornHelm.tscn"),
		"header": "Worn Helmet.",
		"message": "Much more effecient.\n+1 Oxygen Capacity.",
		"image": preload("res://Assets/Treasures/BikerHelm.png")
	},
	{
		"object": "EnergyCapacitor",
		"scene_object": preload("res://Objects/Treasures/EnergyCapacitor.tscn"),
		"header": "Energy Capictor.",
		"message": "A much needed upgrade.\n Passing stores movement.",
		"image": preload("res://Assets/Treasures/EnergyCapacitor.png")
	},
	{
		"object": "MasterKey",
		"scene_object": preload("res://Objects/Treasures/MasterKey.tscn"),
		"header": "A Key.",
		"message": "Finally.\nFind the lock.",
		"image": preload("res://Assets/Treasures/MasterKey.png")
	},
	{
		"object": "Note",
		"scene_object": preload("res://Objects/Treasures/Note.tscn"),
		"header": "A Note.",
		"message": "It is... familiar.\nIt reads: You did it. You are in another world. Another time.",
		"image": preload("res://Assets/Treasures/a_note.png")
	}
]
var enemy = null
var TYPES_OF_ENEMIES = 2
onready var rooms_texture_data = null
onready var bulbo = preload("res://Objects/Enemies/Bulbo/Bulbo.tscn")
onready var gubo = preload("res://Objects/Enemies/Gubo/Gubo.tscn")
var floorTileMap = null

const START_ROOM_COUNT = 3
const ROOMS_PER_LEVEL = 2
const EXIT_ROOM_TYPE_INDEX = 0
const START_ROOM_TYPE_INDEX = 1
const CELL_SIZE = 16
const ROOM_SIZE = 8
const ROOM_DATA_IMAGE_ROW_LEN = 4
const ROOM_TYPES = 11

const NUM_OF_WALL_TYPES = 4
const CHANCE_OF_NON_BLANK_WALL = 4
const START_ENEMY_COUNT = 2
const ENEMY_COUNT_INCREASE_PER_LEVEL = 1

const CHANCE_OF_TREASURE_SPAWNING = 1

func init(scene_root_ref, tilemap_ref, player_ref, exit_ref, room_ref, floor_ref, alternate_ref):
	scene_root = scene_root_ref
	tilemap = tilemap_ref
	player = player_ref
	exit = exit_ref
	rooms_texture_data = room_ref
	floorTileMap = floor_ref
	alternateExit = alternate_ref
# generate the whole level
func stupid_ass_generator(level, treasure_ind):
	current_level = level 
	treasure_index = treasure_ind
	if spawn_note == true:
		treasure_index = 5
	# clear everything
	aStar.clear()
	tilemap.clear()
	floorTileMap.clear()
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("doors", "queue_free")
	get_tree().call_group("treasure", "queue_free")
	# set new data
	var rooms_data = generate_rooms_data()
	var spawn_locations = generate_rooms(rooms_data)
	var world_data = generate_objects_in_world(spawn_locations)
	world_data["aStar"] = aStar
	world_data["aStar_points_cache"] = aStar_points_cache
	return world_data
# generates rooms
func generate_rooms_data() -> Dictionary:
	# the given room count will equal the starting room count plus player level 
	# multiplied by the room increase per level
	var room_count = START_ROOM_COUNT + current_level * ROOMS_PER_LEVEL
	# create variable rooms_data, which is [a, b], where a is the room type, and b
	# is the coordinate location
	# also generate starting room at 0, 0
	var rooms_data = {
		str([0, 0]): {"type": START_ROOM_TYPE_INDEX, "coordinates": [0, 0]}
	}
	# gets the open locations of the newly generated starting room
	var open_locations = get_open_adjacent_rooms(rooms_data, [0, 0])
	var generated_rooms = []
	# get random rooms until we reach the desired room count
	for _i in range(room_count):
		# get random room type
		var random_room_type = (randi() % (ROOM_TYPES - 1)) + 1 # remove exit room from selection
		# get random location from the possible open locations
		var random_room_location = select_random_room_location(open_locations, rooms_data)
		# add this new room to the rooms_data data set
		rooms_data[str(random_room_location)] = {"type": random_room_type, "coordinates": random_room_location}
		# add this new room to the generated rooms array
		generated_rooms.append(random_room_location)
		# get the adjacent open locations of this room
		open_locations += get_open_adjacent_rooms(rooms_data, random_room_location)
	# select the exit room from open locations
	var random_room_location = select_random_room_location(open_locations, rooms_data)
	# take this room and define it as the exit room
	rooms_data[str(random_room_location)] = {"type": EXIT_ROOM_TYPE_INDEX, "coordinates": random_room_location}
	if rooms_data.size() < 5:
		print("ERROR")
	return rooms_data
# gets random location from open locations
func select_random_room_location(open_locations: Array, rooms_data: Dictionary):
	# gets random index using the size of the open_locations array
	var random_index = randi() % open_locations.size()
	# a new room is equal to one of the open locations
	var random_room_location = open_locations[random_index]
	# remove this room from the open_locations index, as it is no longer open
	open_locations.remove(random_index)
	# if this location is already present in rooms_data, and therefore already generated, reroll
	# for a new location
	if str(random_room_location) in rooms_data:
		random_room_location = select_random_room_location(open_locations, rooms_data)
	return random_room_location
# gets adjacent rooms of given room
func get_open_adjacent_rooms(rooms_data: Dictionary, coordinates):
	var open_adjacent_rooms = []
	var adjacent_coordinates = [
		[coordinates[0] + 0, coordinates [1] + 1], # adds 1 to y, getting up
		[coordinates[0] + 1, coordinates [1] + 0], # adds 1 to x, getting right
		[coordinates[0] + 0, coordinates [1] - 1], # subtracts 1 from y, getting down
		[coordinates[0] - 1, coordinates [1] + 0], # subtracts 1 from x, getting left
	]
	# for all the adjacent rooms in adjacent_coordinates
	for coordinates in adjacent_coordinates:
		# if is NOT in rooms_data
		if not str(coordinates) in rooms_data:
			# append the coordinates to the adjacent open room list
			open_adjacent_rooms.append(coordinates)
	# return open adjacent rooms list
	return open_adjacent_rooms
# generates rooms using givenr room and image data
func generate_rooms(rooms_data_list: Dictionary) -> Dictionary:
	var spawn_locations = {
		"enemy_spawn_locations": [],
		"pickup_spawn_locations": [],
		"exit_coordinates": [0, 0],
		"alternateExit_coordinates": [0, 0]
	}
	var index = 0
	# defines list of walkable floor tiles
	var walkable_floor_tiles = {}
	# for all the rooms in rooms_data
	for rooms_data in rooms_data_list.values():
		# only true if index is equal to 0
		var only_do_walls = index == 0
		index += 1
		# get room's coordinates for use
		var coordinates = rooms_data.coordinates
		var x_position = coordinates[0] * ROOM_SIZE
		var y_position = coordinates[1] * ROOM_SIZE
		# get room type for use
		var type = rooms_data.type
		var x_position_image = (type % ROOM_DATA_IMAGE_ROW_LEN) * ROOM_SIZE 
		var y_position_image = (type / ROOM_DATA_IMAGE_ROW_LEN) * ROOM_SIZE 
		# for all the tiles on the x axis of the room
		for x in range(ROOM_SIZE):
			# for all the tiles on the y axis of the room
			for y in range(ROOM_SIZE):
				rooms_texture_data.lock()
				# cell_data = room's pixel data, getting the next pixel in the image per iteration
				var cell_data = rooms_texture_data.get_pixel(x_position_image + x, y_position_image + y)
				# get cell coordinates, getting the next pixel in the image per iteration
				var cell_coordinates = [x_position + x, y_position + y]
				var wall_tile = false 
				# if the pixel is black, give it a random wall tile
				if cell_data == Color.black:
					var wall_type = get_random_wall_type() 
					tilemap.set_cell(x_position + x, y_position + y, wall_type, randi() % 2 == 0, randi() % 2 == 0)
					wall_tile = true 
				# if we're not doing walls
				if !only_do_walls:
					# if the pixel is red, make it an enemy spawn location
					if cell_data == Color.red:
						spawn_locations.enemy_spawn_locations.append(cell_coordinates)
					# if the pixel is green, make it an pickup spawn location
					elif cell_data == Color.green:
						spawn_locations.pickup_spawn_locations.append(cell_coordinates) 
					# if the pixel is blue, make it an exit location
					elif cell_data == Color.blue:
						spawn_locations.exit_coordinates = cell_coordinates
					elif cell_data == Color.magenta:
						spawn_locations.alternateExit_coordinates = cell_coordinates
				# if it is not a wall tile, it must be a walkable floor tile, therefore add it
				# to the list
				if !wall_tile: 
					walkable_floor_tiles[str([x_position + x, y_position + y])] = [x_position + x, y_position + y]
					var floor_type = get_random_floor_type()
					floorTileMap.set_cell(x_position + x, y_position + y, floor_type, randi() % 2 == 0, randi() % 2 == 0)
		var sCoords = ""
		# gets the rooms adjacent to the current room iteration that are in rooms_data_list
		var left_room = str([coordinates[0] - 1, coordinates[1]]) in rooms_data_list
		var right_room = str([coordinates[0] + 1, coordinates[1]]) in rooms_data_list
		var top_room = str([coordinates[0], coordinates[1] - 1]) in rooms_data_list
		var bottom_room = str([coordinates[0], coordinates[1] + 1]) in rooms_data_list
		if !left_room:
			# these two equal room openings to the left of the player; we set walls there if there is no room to the left
			tilemap.set_cell(x_position, y_position + 3, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			tilemap.set_cell(x_position, y_position + 4, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			# sCoords is now equal to one of the wall's coordinates
			sCoords = str([x_position, y_position + 3])
			# if sCoords is defined as a walkable floor tile, remove it from the list
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
			# sCoords is now equal to one of the wall's coordinates
			sCoords = str([x_position, y_position + 4])
			# if sCoords is defined as a walkable floor tile, remove it from the list
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
		if !right_room:
			# these two equal room openings to the right of the player; we set walls there if there is no room to the right
			tilemap.set_cell(x_position + ROOM_SIZE - 1, y_position + 3, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			tilemap.set_cell(x_position + ROOM_SIZE - 1, y_position + 4, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			# sCoords is now equal to one of the wall's coordinates
			sCoords = str([x_position + ROOM_SIZE - 1, y_position + 3])
			# if sCoords is defined as a walkable floor tile, remove it from the list
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
			# sCoords is now equal to one of the wall's coordinates
			sCoords = str([x_position + ROOM_SIZE - 1, y_position + 4])
			# if sCoords is defined as a walkable floor tile, remove it from the list
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
		if !top_room:
			# these two equal room openings to the top of the player; we set walls there if there is no room to the top
			tilemap.set_cell(x_position + 3, y_position, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			tilemap.set_cell(x_position + 4, y_position, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			# sCoords is now equal to one of the wall's coordinates
			sCoords = str([x_position + 3, y_position])
			# if sCoords is defined as a walkable floor tile, remove it from the list
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
			# sCoords is now equal to one of the wall's coordinates
			sCoords = str([x_position + 4, y_position])
			# if sCoords is defined as a walkable floor tile, remove it from the list
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
		if !bottom_room:
			tilemap.set_cell(x_position + 3, y_position + ROOM_SIZE - 1, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			tilemap.set_cell(x_position + 4, y_position + ROOM_SIZE - 1, get_random_wall_type(), randi() % 2 == 0, randi() % 2 == 0)
			sCoords = str([x_position + 3, y_position + ROOM_SIZE -1])
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
			sCoords = str([x_position + 4, y_position + ROOM_SIZE -1])
			if sCoords in walkable_floor_tiles:
				walkable_floor_tiles.erase(sCoords)
	generate_aStar_grid(walkable_floor_tiles)
	return spawn_locations

func generate_aStar_grid(walkable_floor_tiles):
	# define aStar_points_cache as a dictionary
	aStar_points_cache = {}
	# for all the tiles in walkable_floor_tiles
	for tile_coordinate in walkable_floor_tiles.values():
		# tile_id is equal to the current tile coordinate in the iteration
		var tile_id = aStar.get_available_point_id()
		# add this point with its coordinates
		aStar.add_point(tile_id, Vector2(tile_coordinate[0], tile_coordinate[1]))
		# current iteration is equal to tile_id
		aStar_points_cache[str([tile_coordinate[0], tile_coordinate[1]])] = tile_id
	# for all the tiles in walkable_floor_tiles
	for tile_coordinate in walkable_floor_tiles.values():
		# tile_id is equal to a point in the cache of this iteration
		var tile_id = aStar_points_cache[str([tile_coordinate[0], tile_coordinate[1]])]
		# the tile to the left of the current iteration's point is equal to left_x_key
		var left_x_key = str([tile_coordinate[0] - 1, tile_coordinate [1]])
		# if left_x_key is in the cache, connect it to the grid
		if left_x_key in aStar_points_cache:
			aStar.connect_points(aStar_points_cache[left_x_key], tile_id)
		# similar to above 
		var up_y_key = str([tile_coordinate[0], tile_coordinate[1] - 1])
		if up_y_key in aStar_points_cache:
			aStar.connect_points(aStar_points_cache[up_y_key], tile_id)

func get_random_floor_type():
	var floor_type = 0
	if randi() % 2 == 0:
		floor_type = randi() % NUM_OF_WALL_TYPES
	return floor_type

func get_random_wall_type():
	var wall_type = 0
	if randi() % CHANCE_OF_NON_BLANK_WALL == 0:
		wall_type = randi() % NUM_OF_WALL_TYPES
	return wall_type

func generate_objects_in_world(spawn_locations: Dictionary) -> Dictionary:
	# maps player position to real level from map
	player.global_position = map_coord_to_world_pos(Vector2.ONE)
	# maps exit position to real level from map
	exit.global_position = map_coord_to_world_pos(spawn_locations.exit_coordinates)
	var alternateExit_chance = randi() % 5 + 1
	if alternateExit_chance == 3:
		alternateExit.visible = true
		alternateExit.set_process(true)
		alternateExit.global_position = map_coord_to_world_pos(spawn_locations.alternateExit_coordinates)
	else:
		alternateExit.visible = false
		alternateExit.set_process(false)
	# sets the enemy count
	var enemy_count = START_ENEMY_COUNT + ENEMY_COUNT_INCREASE_PER_LEVEL * current_level
	# sets enemies 
	var enemies = spawn_objects_at_locations(enemy, spawn_locations.enemy_spawn_locations, enemy_count, "enemies")
	# sets treasure dictionary
	var treasure = {}
	if !spawn_key:
		treasure_index = randi() % 4
	if treasure_index < treasures.size() and randi() % CHANCE_OF_TREASURE_SPAWNING == 0:
		treasure["object"] = treasures[treasure_index].object
		treasure["object_data"] = spawn_objects_at_locations(treasures[treasure_index].scene_object, spawn_locations.pickup_spawn_locations, 1, "treasure")
		treasure["header"] = treasures[treasure_index].header
		treasure["message"] = treasures[treasure_index].message
		treasure["image"] = treasures[treasure_index].image
	# TODO special pickups
	# var potion_count = START_POTION_COUNT + current_level * POTION_COUNT_INCREASE_PER_LEVEL
	# var potions = spawn_objects_at_locations(potion, spawn_locations.pickup_spawn_locations, potion_count, "potions")
	# encapsulates above data into data
	var data = {
		"enemies" : enemies,
		"player" : player,
		"exit" : exit,
		"alternateExit": alternateExit,
		"treasure_data" : treasure
	}
	
	return data

func spawn_objects_at_locations(object_to_spawn, location_list: Array, amount_to_spawn: int, group_name: String, flip_randomly = true):
	var spawned_objects = {}
	for _i in range(amount_to_spawn):
		randomize()
		var random_number = randi() % TYPES_OF_ENEMIES + 1
		var instance = null
		if location_list.size() == 0:
			break
		if object_to_spawn == enemy:
			if random_number == 2:
				instance = gubo.instance()
			if random_number == 1:
				instance = bulbo.instance()
		else:
			instance = object_to_spawn.instance()
		scene_root.add_child(instance) 
		var random_location_index = randi() % location_list.size() 
		var coordinates = location_list[random_location_index]
		instance.global_position = map_coord_to_world_pos(coordinates) 
		location_list.remove(random_location_index) 
		spawned_objects[str(coordinates)] = instance
		instance.add_to_group(group_name) 
		if flip_randomly and instance.has_node("Sprite") and randi() % 2 == 0:
			instance.get_node("Sprite").flip_h = true 
	return spawned_objects 

func map_coord_to_world_pos(coordinates):
	return tilemap.map_to_world(Vector2(coordinates[0], coordinates[1])) + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
