extends Area2D

@export var follow_speed: float = 5.0
@export var follow_distance: float = 60.0

# This is empty by default. The World will tell the creature who to follow.
var target_node: Node2D = null

func _process(delta):
	if target_node != null:
		# Get the directional vector from the creature to the player
		var direction_to_target = global_position.direction_to(target_node.global_position)
		
		# Calculate the exact coordinate the creature SHOULD stand at (behind the player)
		var target_position = target_node.global_position - (direction_to_target * follow_distance)
		
		# Smoothly glide the creature's current position to that target position
		global_position = global_position.lerp(target_position, follow_speed * delta)
