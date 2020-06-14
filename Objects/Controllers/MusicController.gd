extends Node


func _ready():
	pick_random_song()

func _on_Turn_finished():
	pick_random_song()

func pick_random_song():
	randomize()
	var index = randi() % 5
	match index:
		0: 
			$Turn.play()
		1:
			$Alchemy.play() 
		2: 
			$Chasm.play() 
		3: 
			$EmptySpace.play() 
		4: 
			$Grace.play() 
		5: 
			$Light.play()