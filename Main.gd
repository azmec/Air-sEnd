extends Node2D
#export(PackedScene) var scene_to_load
onready var rooms = preload("res://Assets/Tiles/Layouts.png").get_data()
onready var tileMap = $WallTiles
onready var floorTileMap = $GroundTiles
onready var worldGenerator = $WorldGenerator
onready var player = $Player
onready var exit = $Exit
onready var alternateExit = $AlternateExit
onready var camera = $Camera2D
# Get UI elements
onready var keyUI = $CanvasLayer/KeyUI 
onready var oxygenUI = $CanvasLayer/OxygenUI
onready var oxygenTimerUI = $CanvasLayer/OxygenTimerUI
onready var moveTileUI = $CanvasLayer/MoveTileUI
onready var deathDisplay = $CanvasLayer/DeathDisplay
onready var deathText = $CanvasLayer/DeathDisplay/DeathText
onready var deathTextGenerator = $DeathTextGenerator
onready var levelText = $CanvasLayer/LevelText
onready var levelTextBubble = $CanvasLayer/LevelTextBubble
onready var vignette = $CanvasLayer/Vignette
onready var treasureDisplay = $CanvasLayer/TreasureDisplay
onready var treasureHeader = $CanvasLayer/TreasureDisplay/Header
onready var treasureMessage = $CanvasLayer/TreasureDisplay/Message
onready var treasurePortrait = $CanvasLayer/TreasureDisplay/Portrait
# onready var turnController = $TurnController

var treasure_index = 0
var treasure_data = {}
var enemies = {} 
var aStar = null
var aStar_points_cache = {}
var death_text = null
var is_alternate = false

const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]

func _ready():
	# randomzie the seed
	randomize()
	# initilizing controllers
	worldGenerator.init(self, tileMap, player, exit, rooms, floorTileMap, alternateExit)
	generate_alternate_world()
	player.connect("player_turn_taken", self, "_on_Player_turn_taken")
	player.connect("player_is_dead", self, "_on_Player_is_dead")
	player.connect("not_valid_move", self, "_on_Player_not_valid_move")
	player.connect("player_at_exit", self, "_on_Player_at_exit")
	player.connect("treasure_found", self, "_on_Player_treasure_found")
	player.current_level = 10

func generate_world():
	$Sounds/NewLevel.play()
	treasure_index = randi() % 5
	death_text = deathTextGenerator.get_death_text()
	player.moves_left = player.MINIMUM_MOVES
	var current_level = 10
	var world_data = worldGenerator.stupid_ass_generator(current_level, treasure_index)
	enemies = world_data.enemies
	treasure_data = world_data.treasure_data
	aStar = world_data.aStar
	aStar_points_cache = world_data.aStar_points_cache
	player.init(treasure_data, alternateExit, exit)
	levelText.text = "Level: " + str(current_level + 1)

func _process(_delta):
	#for enemy in enemies.values():
	#	enemy.player_coordinates = player.player_coordinates
	if Input.is_action_just_pressed("ui_accept"):
		$Sounds/Confirm.play()
		$CanvasLayer/TreasureDisplay.hide()
		deathDisplay.hide()
	if Input.is_action_just_pressed("restart"):
		restart()
	if Input.is_action_just_pressed("exit"):
		restart()
		get_tree().change_scene("res://Objects/TitleScreen/TitleScreen.tscn")
	oxygenTimerUI.rect_size.x = (player.oxygen_timer + 1) * 16
	moveTileUI.rect_size.x = (player.moves_left + 1) * 16
	keyUI.rect_size.x = (player.key_count + 1) * 16
	oxygenUI.rect_size.x = player.oxygen_count * 16
	if player.oxygen_count <= 0:
		oxygenUI.hide()
	for enemy in enemies.values():
		if player.global_position == enemy.global_position:
			player.die()
	if is_alternate:
		for enemy in enemies.values():
			enemy.sprite.material.set_shader_param("amount", ((randi() % 10) * player.current_level))
		levelText.text = "Level: " + str (randi() % 100)
		tileMap.material.set_shader_param("amount", ((randi() % 10) * player.current_level))
		floorTileMap.material.set_shader_param("amount", ((randi() % 10) * player.current_level))
		exit.sprite.material.set_shader_param("amount", ((randi() % 10) * player.current_level))
	else:
		for enemy in enemies.values():
			enemy.sprite.material.set_shader_param("amount", 0)
		tileMap.material.set_shader_param("amount", 0)
		floorTileMap.material.set_shader_param("amount", 0)
		exit.sprite.material.set_shader_param("amount", 0)

func restart():
	VisualServer.set_default_clear_color(Color8(71.0, 45.0, 60.0))
	exit.visible = true
	exit.set_process(true)
	alternateExit.visible = true 
	alternateExit.set_process(true)
	worldGenerator.spawn_note = false
	is_alternate = false
	player.default()
	default_ui()
	deathDisplay.hide()
	set_rooms_to_default()
	generate_world()

func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates

func _on_Player_turn_taken():
	for i in enemies:
		var enemy = enemies[i]
		enemy.is_enemy_turn = true
	if player.moves_left >= 0:
		player.moves_left = player.MINIMUM_MOVES
	$Sounds/EnemyTurn.play()

func _on_Player_is_dead():
	for enemy in enemies.values():
		enemy.set_process(false) 
	deathText.text = death_text 
	deathDisplay.show()

func _on_Player_not_valid_move():
	camera.screenShake.start(0.1, 15, 8, 0)

func _on_Player_at_exit(type_of_exit):
	if type_of_exit == exit:
		if is_alternate:
			generate_end_world()
		else:
			generate_world()
	elif type_of_exit == alternateExit:
		generate_alternate_world()

func _on_Player_treasure_found(treasure_name):
	$Sounds/TreasurePickup.play()
	treasureDisplay.show()
	treasureHeader.text = treasure_data.header
	treasureMessage.text = treasure_data.message
	treasurePortrait.texture = treasure_data.image
	if treasure_name == "MasterKey":
		worldGenerator.spawn_key = false

func generate_alternate_world():
	is_alternate = true
	set_rooms_to_alternative()
	generate_world()
	alternateExit.visible = false 
	alternateExit.set_process(false)

func generate_end_world():
	camera.reset_camera()
	VisualServer.set_default_clear_color(Color8(207, 198, 184))
	set_rooms_to_end()
	worldGenerator.spawn_note = true
	generate_world()
	exit.visible = false
	exit.set_process(false)
	alternateExit.visible = false 
	alternateExit.set_process(false)
	is_alternate = false
	hide_ui()
	make_player_god()

func make_player_god():
	player.oxygen_timer_max = 999
	player.maximum_oxygen = 999
	player.oxygen_timer = 999
	player.oxygen_count = 999
	player.MINIMUM_MOVES = 999

func hide_ui():
	vignette.hide()
	oxygenUI.hide()
	keyUI.hide()
	moveTileUI.hide()
	oxygenTimerUI.hide()
	levelText.hide()
	levelTextBubble.hide()

func default_ui():
	vignette.show()
	oxygenUI.show()
	keyUI.show()
	moveTileUI.show()
	oxygenTimerUI.show()
	levelText.show()
	levelTextBubble.show()

func set_rooms_to_end():
	rooms = preload("res://Assets/Tiles/end_layout.png").get_data()
	floorTileMap.tile_set = load('res://Objects/TileSets/end_floor.tres')
	tileMap.tile_set = load('res://Objects/TileSets/end_wall.tres')
	worldGenerator.init(self, tileMap, player, exit, rooms, floorTileMap, alternateExit)

func set_rooms_to_alternative():
	rooms = preload("res://Assets/Tiles/alternative_layout.png").get_data()
	floorTileMap.tile_set = load('res://Objects/TileSets/final_tileset.tres')
	tileMap.tile_set = load('res://Objects/TileSets/final_room.tres')
	worldGenerator.init(self, tileMap, player, exit, rooms, floorTileMap, alternateExit)

func set_rooms_to_default():
	rooms = preload("res://Assets/Tiles/Layouts.png").get_data()
	floorTileMap.tile_set = load('res://Objects/TileSets/base_floor_tiles.tres')
	tileMap.tile_set = load('res://Objects/TileSets/base_wall_tiles.tres')
	worldGenerator.init(self, tileMap, player, exit, rooms, floorTileMap, alternateExit)