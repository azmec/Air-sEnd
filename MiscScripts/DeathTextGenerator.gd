extends Node

var death_messages = {
	0: "It's your fault.",
	1: "The air is unfit to breathe.",
	2: "The earth revolts.",
	3: "Your body was gone an hour later.",
	4: "You're blue now.",
	5: "Shame.",
	6: "Chance of Percipitation.",
	7: "Simply outclassed.",
	8: "IKGDJMPKTJ."
}
func get_death_text():
	randomize()
	var total_messages = death_messages.size()
	var index = randi() % total_messages 
	var death_text = death_messages[index]
	return death_text
