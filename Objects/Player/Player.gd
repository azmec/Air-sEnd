extends Node2D

var moves_left = 0
var moved = false
var current_level = 0
var tileMap = null
var worldGenerator = null
var enemies = null
var oxygen_count = 5
var oxygen_timer = 5
var oxygen_timer_max = 5
var maximum_oxygen = 5
var dead = false
var can_move = false
var can_add_oxygen = true
var move_direction = [0, 0]
var sound_played = false
var MINIMUM_MOVES = 1

const RIGHT = [1, 0]
const LEFT = [-1, 0]
const UP = [0, -1]
const DOWN = [0, 1]

onready var sprite = $Sprite
onready var characterController = $CharacterController
onready var moveTimer = $MoveTimer
onready var accelerationTimer = $AccelerationTimer

func init(tilemap_ref, worldgenerator_ref, enemies_ref):
	tileMap = tilemap_ref
	worldGenerator = worldgenerator_ref
	moves_left = MINIMUM_MOVES
	characterController.init(tilemap_ref, worldgenerator_ref, enemies_ref)

func default():
	sound_played = false
	current_level = 0
	oxygen_count = 5
	oxygen_timer = 5
	oxygen_timer_max = 5
	maximum_oxygen = 5
	MINIMUM_MOVES = 1
func _process(delta):
	if dead:
		return
	# define move direction as coordinates
	move_direction = [0, 0]
	var time_held = 0
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
	if oxygen_count >= maximum_oxygen:
		oxygen_count = maximum_oxygen
		can_add_oxygen = false
	else:
		can_add_oxygen = true
	if Input.is_action_just_pressed("shift"):
		if can_add_oxygen == true:
			oxygen_count += 1
			moves_left -= 1
			$NoMove.play()
		else:
			moves_left -= 1
			$NoMove.play()
	if move_direction != [0, 0]:
		# call move_character
		moved = characterController.move_character(self, sprite, move_direction)
		if moved:
			get_random_step_sound()
			oxygen_timer -= 1
			moves_left -= 1
		elif !moved:
			$NoMove.play()

	if oxygen_timer == 0:
		oxygen_count -= 1
		oxygen_timer = oxygen_timer_max
	if oxygen_count == 0:
		die()

func die():
	if !sound_played:
		sound_played = true
		$Death.play()
	dead = true

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
