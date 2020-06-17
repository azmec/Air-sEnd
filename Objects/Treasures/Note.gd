extends Node2D


onready var sprite = $Sprite 

func _process(delta):
	sprite.material.set_shader_param("amount", ((randi() % 100)))