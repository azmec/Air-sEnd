extends Node

# this node only executes if the player signals that their turn is over
var enemies = {}
var player = null
func init(enemies_ref, player_ref):

func process(delta):
	pass 
	# if player signal == true:
		# move enemies


# move enemies:
	# var enemies = {}
	# for enemies in enemies:
		# if enemy is alerted:
			# add to queue list
		# if enemy is in queue list:
			# get enemy position
			# get player position
			# get path from enemy to player
			# if enemy is not on the same coordinates as player:
				#????????????????????????
# some enemy alert function
func get_alerted_enemies():
	# for enemies in enemies.values:
		# var enemy position = world_position_to_map_coordinates(enemy.global_position)
		# if enemy is NOT alerted and it has line of sight of the player:
			# alert the enemy