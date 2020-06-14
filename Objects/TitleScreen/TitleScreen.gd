extends Control

onready var earthRotation = $Earth/EarthRotation
func _ready():
	earthRotation.play("Rotation")
	for button in $Menu/CenterRow/HBox/Buttons.get_children():
		button.connect("pressed", self, "_on_Button_pressed", [button.scene_to_load])
func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
func _on_Button_pressed(scene_to_load):
	get_tree().change_scene_to(scene_to_load)
