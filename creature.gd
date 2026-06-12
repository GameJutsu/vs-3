extends Area2D

@export var follow_speed: float = 5.0
@export var attack_speed: float = 8.0 # Attacks faster than it follows
@export var follow_distance: float = 60.0

var target_node: Node2D = null
var current_enemy: Node2D = null

# 1. Define our State Machine
enum State { FOLLOW, ATTACK }
var state = State.FOLLOW

func _process(delta):
	# 2. match is Godot's version of a 'switch' statement. It cleanly separates our logic.
	match state:
		State.FOLLOW:
			if target_node != null:
				var direction_to_target = global_position.direction_to(target_node.global_position)
				var target_position = target_node.global_position - (direction_to_target * follow_distance)
				global_position = global_position.lerp(target_position, follow_speed * delta)

		State.ATTACK:
			# is_instance_valid() prevents the game from crashing if two creatures try to kill the same enemy
			if current_enemy != null and is_instance_valid(current_enemy):
				# Fly toward the enemy
				global_position = global_position.lerp(current_enemy.global_position, attack_speed * delta)
				
				# 3. The "Bite" - If we get close enough, destroy the enemy
				if global_position.distance_to(current_enemy.global_position) < 15.0:
					current_enemy.queue_free() # queue_free() safely deletes a node
					current_enemy = null
					state = State.FOLLOW # Go back to the player
			else:
				# If the enemy died before we got there, return to the player
				state = State.FOLLOW

# This function triggers the moment a Physics Body touches our giant CollisionShape2D
func _on_body_entered(body):
	# Check if the thing that entered is tagged as an enemy, AND make sure we aren't already attacking
	if body.is_in_group("enemy") and state == State.FOLLOW:
		current_enemy = body
		state = State.ATTACK
