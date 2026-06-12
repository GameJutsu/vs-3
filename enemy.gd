extends CharacterBody2D

@export var speed: float = 100.0

# Preloading loads the scene into RAM when the game boots, preventing lag spikes when 100 enemies die at once.
const XP_GEM_SCENE = preload("res://xp_gem.tscn")

var target_node: Node2D = null

func _physics_process(delta: float) -> void:
	if target_node != null:
		var direction = global_position.direction_to(target_node.global_position)
		velocity = direction * speed
		move_and_slide()

# We create a dedicated die function rather than just calling queue_free() from the outside.
# This centralizes our cleanup logic.
func die() -> void:
	# 1. Create the gem
	var gem = XP_GEM_SCENE.instantiate()
	
	# 2. Set the gem's starting position to exactly where the enemy died
	gem.global_position = global_position
	
	# 3. Add the gem to the World. 
	# get_parent() grabs the World node, ensuring the gem lives independently in the arena.
	# call_deferred safely waits until the end of the current physics frame to add the node, preventing engine crashes.
	get_parent().call_deferred("add_child", gem)
	
	# 4. Destroy the enemy
	queue_free()
