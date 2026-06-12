extends CharacterBody2D

@export var speed: float = 100.0

# The world will tell the enemy who to hunt
var target_node: Node2D = null

func _physics_process(delta):
	if target_node != null:
		# Calculate direction to the player
		var direction = global_position.direction_to(target_node.global_position)
		
		# Apply velocity and move. CharacterBody2D handles the collision bumping!
		velocity = direction * speed
		move_and_slide()
