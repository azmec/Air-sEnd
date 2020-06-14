extends Control

onready var earthRotation = $Earth/EarthRotation
func _ready():
	earthRotation.play("Rotation")

func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().change_scene("res://Objects/TitleScreen/TitleScreen.tscn")