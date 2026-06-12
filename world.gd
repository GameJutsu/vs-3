extends Node2D

func _ready():
	# Grab the references to the child nodes
	var player = $Player
	var creature = $Creature
	
	# Pass the player's reference into the creature's script
	creature.target_node = player
