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
var total_keys = 1

const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]

func _ready():
	# randomzie the seed
	randomize()
	# initilizing controllers
	worldGenerator.init(self, tileMap, player, exit, rooms, floorTileMap, alternateExit)
	player.init(tileMap, worldGenerator, enemies)
	generate_world()

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
	player.enemies = world_data.enemies
	levelText.text = "Level: " + str(current_level + 1)

func _process(delta):
	var player_coordinates = world_position_to_map_position(player.global_position)
	var sPlayer_coordinates = str(player_coordinates)
	if treasure_data.size() > 0 and str(sPlayer_coordinates) in treasure_data.object_data:
		$Sounds/TreasurePickup.play()
		if treasure_data.object == "OxygenCanister":
			player.oxygen_count += 10
		elif treasure_data.object == "LeatherBoots":
			player.MINIMUM_MOVES += 1
		elif treasure_data.object == "WornHelm":
			player.maximum_oxygen += 1
		elif treasure_data.object == "MasterKey":
			total_keys += 1
			worldGenerator.spawn_key = false
		treasure_data.object_data[sPlayer_coordinates].queue_free()
		treasure_data.object_data.erase(sPlayer_coordinates)
		treasureDisplay.show()
		treasureHeader.text = treasure_data.header
		treasureMessage.text = treasure_data.message
		treasurePortrait.texture = treasure_data.image
	if Input.is_action_just_pressed("ui_accept"):
		$Sounds/Confirm.play()
		$CanvasLayer/TreasureDisplay.hide()
		deathDisplay.hide()
	if Input.is_action_just_pressed("restart"):
		restart()
	if Input.is_action_just_pressed("exit"):
		get_tree().change_scene("res://Objects/TitleScreen/TitleScreen.tscn")
#	if Input.is_action_just_pressed("exit"):
#		get_tree().change_scene_to(scene_to_load)
	oxygenTimerUI.rect_size.x = (player.oxygen_timer + 1) * 16
	moveTileUI.rect_size.x = (player.moves_left + 1) * 16
	keyUI.rect_size.x = total_keys * 16
	oxygenUI.rect_size.x = player.oxygen_count * 16
	if player.oxygen_count == 0:
		oxygenUI.hide()
	for enemy in enemies.values():
		var enemy_position = enemy.global_position
		if player.global_position == enemy.global_position:
			player.die()
	if player.global_position == exit.global_position:
		player.current_level += 1
		generate_world()
	if worldGenerator.alternateExit_spawned:
		if player.global_position == alternateExit.global_position and total_keys != 2:
			$Player/NoMove.play()
			player.characterController.move_character(player, player.sprite, [1, 0])
			camera.screenShake.start(0.1, 15, 8, 0)
		elif player.global_position == alternateExit.global_position:
			player.die()
	if player.moves_left == 0:
		$Sounds/EnemyTurn.play()
		player.moves_left = player.MINIMUM_MOVES
		for i in enemies:
			var enemy = enemies[i]
			enemy.ready_to_move = true
	if player.dead:
		for enemy in enemies.values():
			enemy.set_process(false)
		deathText.text = death_text
		deathDisplay.show()
func restart():
	print(oxygenUI.rect_size.x)
	player.default()
	player.oxygen_count = 5
	oxygenUI.rect_size.x = 80
	player.dead = false
	deathDisplay.hide()
	generate_world()

func world_position_to_map_position(position: Vector2):
	var vCoordinates = tileMap.world_to_map(position)
	var coordinates = [int(round(vCoordinates.x)), int(round(vCoordinates.y))]
	return coordinates
