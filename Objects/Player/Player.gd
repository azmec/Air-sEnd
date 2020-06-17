extends Node2D

# our minimum moves
var moves_left = 0
# if we have moved
var moved = false
# our current level
var current_level = 0
# container for tileMap access; needed to pass into CharacterController
#var tileMap = null
# container for treasureData access; needed for treasure contact checks
var treasureData = null
var exit = null
var alternateExit = null
var worldGenerator = null
# oxygen variables
var oxygen_count = 5
var oxygen_timer = 5
var oxygen_timer_max = 5
var maximum_oxygen = 5
var can_add_oxygen = true
var dead = false
var key_count = 0
var can_store_energy = false
var maximum_move_tiles = 3
# used for input grace
var can_move = false
var move_direction = [0, 0]
# used to play death sound once and once only
var sound_played = false
# the minimum amount of moves we have per turn
var MINIMUM_MOVES = 1
var player_coordinates = null
var upgradedPlayer = preload("res://Assets/Player/PlayerButBetter.png")
var basePlayer = preload("res://Assets/Tiles/PlayerButBetter.png")
signal player_turn_taken()
signal player_at_exit(type_of_exit)
signal player_is_dead
signal not_valid_move
signal treasure_found(treasure_name)

const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]

onready var characterController = $CharacterController
onready var moveTimer = $MoveTimer
onready var accelerationTimer = $AccelerationTimer
onready var playerSprite = $Sprite
onready var tileMap = get_tree().get_root().get_node("Main").find_node("WallTiles")

func _ready():
	characterController.init(tileMap)

func init(treasureData_ref, alternateExit_ref, exit_ref):
	#tileMap = tilemap_ref
	treasureData = treasureData_ref
	moves_left = MINIMUM_MOVES
	alternateExit = alternateExit_ref
	exit = exit_ref

func default():
	dead = false
	playerSprite.texture = basePlayer
	sound_played = false
	can_store_energy = false
	key_count = 0
	current_level = 0
	oxygen_count = 5
	oxygen_timer = 5
	oxygen_timer_max = 5
	maximum_oxygen = 5
	MINIMUM_MOVES = 1
func _process(_delta):
	if dead:
		return
	player_coordinates = characterController.world_position_to_map_position(self.global_position)
	# define move direction as coordinates
	move_direction = [0, 0]
	# acceleration based on holding input
	if Input.is_action_just_pressed("ui_left"):
		moveTimer.start()
		accelerationTimer.start()
	if Input.is_action_just_pressed("ui_right"):
		moveTimer.start()
		accelerationTimer.start()
	if Input.is_action_just_pressed("ui_up"):
		accelerationTimer.start()
		moveTimer.start()
	if Input.is_action_just_pressed("ui_down"):
		accelerationTimer.start()
		moveTimer.start()
	if Input.is_action_pressed("ui_left") and can_move:
		move_direction = LEFT
		can_move = false
		moveTimer.start()
	if Input.is_action_pressed("ui_right") and can_move:
		can_move = false
		move_direction = RIGHT 
		moveTimer.start()
	if Input.is_action_pressed("ui_up") and can_move:
		move_direction = UP 
		can_move = false
		moveTimer.start()
	if Input.is_action_pressed("ui_down") and can_move:
		move_direction = DOWN
		can_move = false
		moveTimer.start()
	# if move_direction is modified
	# pass turn function; passing a turn adds oxygen when available
	if Input.is_action_just_pressed("shift"):
		if oxygen_count >= maximum_oxygen:
			oxygen_count = maximum_oxygen
			can_add_oxygen = false
		else:
			can_add_oxygen = true
		if can_store_energy == true:
			moves_left += 2
		if moves_left >= maximum_move_tiles:
			moves_left = maximum_move_tiles
		if can_add_oxygen == true:
			oxygen_count += 1
			moves_left -= 1
			emit_signal("player_turn_taken")
			$NoMove.play()
		else:
			moves_left -= 1
			emit_signal("player_turn_taken")
			$NoMove.play()
	# if there is input
	if move_direction != [0, 0]:
		# call move_character
		moved = characterController.move_character(self, move_direction)
		if moved:
			get_random_step_sound()
			oxygen_timer -= 1
			moves_left -= 1
		elif !moved:
			emit_signal("not_valid_move")
			$NoMove.play()
	# if we have no moves left
	if moves_left <= 0:
		# if our oxygen timer has counted down, subtract from our
		# oxygen count
		if oxygen_timer <= 0:
			oxygen_count -= 1
			# reset the timer
			oxygen_timer = oxygen_timer_max
		# if we no longer have oxygen, die
		if oxygen_count == 0:
			die()
		# signal that our turn was taken
		emit_signal("player_turn_taken")
	else: 
		# if our position matches the alternateExit and we have a key
		if self.global_position == alternateExit.global_position and key_count <= 0:
			$NoMove.play()
			characterController.move_character(self, RIGHT)
			emit_signal("not_valid_move") 
		elif self.global_position == alternateExit.global_position and key_count >= 1:
			emit_signal("player_at_exit", alternateExit)
		if self.global_position == exit.global_position:
			current_level += 1
			emit_signal("player_at_exit", exit)
		if treasureData.size() > 0:
			var self_coordinates = str(player_coordinates)
			if self_coordinates in treasureData.object_data:
				if treasureData.object == "OxygenCanister":
					oxygen_count = maximum_oxygen
				elif treasureData.object == "LeatherBoots":
					MINIMUM_MOVES += 1
					maximum_move_tiles += 1
				elif treasureData.object == "WornHelm":
					maximum_oxygen += 1
					playerSprite.texture = upgradedPlayer
				elif treasureData.object == "EnergyCapacitor":
					can_store_energy = true
				elif treasureData.object == "MasterKey":
					key_count += 1
				treasureData.object_data[self_coordinates].queue_free()
				treasureData.object_data.erase(self_coordinates)
				emit_signal("treasure_found", treasureData.object)
func die():
	if !sound_played:
		sound_played = true
		$Death.play()
	dead = true
	emit_signal("player_is_dead")

func _on_MoveTimer_timeout():
	can_move = true

func _on_AccelerationTimer_timeout():
	moveTimer.wait_time = 0.1

func get_random_step_sound():
	var step = randi() % 3 + 1
	if step == 1:
		$Steps/Step1.play()
	elif step == 2:
		$Steps/Step2.play()
	elif step == 3:
		$Steps/Step3.play()
