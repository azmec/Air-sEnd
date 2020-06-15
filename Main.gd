extends Node2D
#export(PackedScene) var scene_to_load
onready var rooms = preload("res://Assets/Tiles/Layouts.png").get_data()
onready var tileMap = $TileMap
onready var floorTileMap = $GroundTiles
onready var worldGenerator = $WorldGenerator
onready var player = $Player
onready var playerSprite = $Player/Sprite
onready var exit = $Exit
onready var alternateExit = $AlternateExit
onready var camera = $Camera2D
# Get UI elements
onready var keyUI = $CanvasLayer/KeyUI 
onready var oxygenUI = $CanvasLayer/OxygenUI
onready var oxygenTimerUI = $CanvasLayer/OxygenTimerUI
onready var moveTileUI = $CanvasLayer/MoveTileUI
onready var textBubble = $CanvasLayer/TextBubble
onready var deathDisplay = $CanvasLayer/DeathDisplay
onready var skull = $CanvasLayer/DeathDisplay/Skull
onready var deathText = $CanvasLayer/DeathDisplay/DeathText
onready var deathTextGenerator = $DeathTextGenerator
onready var deathPrompt = $CanvasLayer/DeathDisplay/DeathPrompt
onready var levelText = $CanvasLayer/LevelText
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

const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]

func _ready():
	# randomzie the seed
	randomize()
	# initilizing controllers
	worldGenerator.init(self, tileMap, player, exit, rooms, floorTileMap, alternateExit)
	generate_world()
	player.connect("player_turn_taken", self, "_on_Player_turn_taken")
	player.connect("player_is_dead", self, "_on_Player_is_dead")
	player.connect("not_valid_move", self, "_on_Player_not_valid_move")
	player.connect("player_at_exit", self, "_on_Player_at_exit")
	player.connect("treasure_found", self, "_on_Player_treasure_found")

func generate_world():
	$Sounds/NewLevel.play()
	treasure_index = randi() % 4
	death_text = deathTextGenerator.get_death_text()
	player.moves_left = player.MINIMUM_MOVES
	var current_level = player.current_level
	var world_data = worldGenerator.stupid_ass_generator(current_level, treasure_index)
	enemies = world_data.enemies
	treasure_data = world_data.treasure_data
	aStar = world_data.aStar
	aStar_points_cache = world_data.aStar_points_cache
	player.init(treasure_data, alternateExit, exit)
	player.alternateExit_spawned = worldGenerator.alternateExit_spawned
	levelText.text = "Level: " + str(current_level + 1)

func _process(delta):
	#for enemy in enemies.values():
	#	enemy.player_coordinates = player.player_coordinates
	if Input.is_action_just_pressed("ui_accept"):
		$Sounds/Confirm.play()
		$CanvasLayer/TreasureDisplay.hide()
		deathDisplay.hide()
	if Input.is_action_just_pressed("restart"):
		restart()
	if Input.is_action_just_pressed("exit"):
		get_tree().change_scene("res://Objects/TitleScreen/TitleScreen.tscn")
	oxygenTimerUI.rect_size.x = (player.oxygen_timer + 1) * 16
	moveTileUI.rect_size.x = (player.moves_left + 1) * 16
	keyUI.rect_size.x = (player.key_count + 1) * 16
	oxygenUI.rect_size.x = player.oxygen_count * 16
	if player.oxygen_count <= 0:
		oxygenUI.hide()
	else:
		oxygenUI.show()
	for enemy in enemies.values():
		if player.global_position == enemy.global_position:
			player.die()
func restart():
	player.default()
	player.oxygen_count = 5
	player.dead = false
	deathDisplay.hide()
	generate_world()

func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates

func _on_Player_turn_taken(coordinates):
	for i in enemies:
		var enemy = enemies[i]
		enemy.is_enemy_turn = true
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
		generate_world()
#	else:
#		generate_alternate_world()

func _on_Player_treasure_found(treasure_name):
	$Sounds/TreasurePickup.play()
	treasureDisplay.show()
	treasureHeader.text = treasure_data.header
	treasureMessage.text = treasure_data.message
	treasurePortrait.texture = treasure_data.image
	if treasure_name == "MasterKey":
		worldGenerator.spawn_key = false
