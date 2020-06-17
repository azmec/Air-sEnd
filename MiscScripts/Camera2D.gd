extends Camera2D

onready var screenShake = $ScreenShake
var previous_position = Vector2(0, 0)

func _process(delta):
	var can_drag = false
	var mouse_position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("left_click"):
		$Click.play()
		can_drag = true
	if Input.is_action_just_released("left_click"):
		can_drag = false
	if can_drag:
		self.position = get_global_mouse_position()
	if Input.is_action_just_released("zoom_in"):
		_zoom_camera(-1)
	# Wheel Down Event
	elif Input.is_action_just_released("zoom_out"):
		_zoom_camera(1)
	if Input.is_action_just_pressed("reset_zoom"):
		reset_camera()

# Zoom Camera
func _zoom_camera(dir):
	self.zoom += Vector2(0.1, 0.1) * dir
	if self.zoom.x < 0.1:
		self.zoom.x = 0.1
		self.zoom.y = 0.1

func _on_CharacterController_no_valid_move():
	screenShake.start(0.1, 15, 8, 0)

func reset_camera():
	self.zoom = Vector2(1, 1)
	self.position.x = 0
	self.position.y = 0
