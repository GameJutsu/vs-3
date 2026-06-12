extends Node2D

# This allows us to drag and drop the enemy scene into the inspector
@export var enemy_scene: PackedScene

# We make player a class-level variable so the timer can access it
@onready var player = $Player
@onready var creature = $Creature

func _ready():
	# Pass the player's reference into the creature's script
	creature.target_node = player

# This function will trigger every time the timer hits 0
func _on_spawn_timer_timeout():
	if enemy_scene == null:
		return # Prevents crashing if we forget to assign the scene
		
	# Create a new instance of the enemy
	var new_enemy = enemy_scene.instantiate()
	
	# Calculate a random position on a circle 600 pixels away from the player
	var spawn_radius = 600.0
	var random_angle = randf() * TAU
	var spawn_x = player.global_position.x + cos(random_angle) * spawn_radius
	var spawn_y = player.global_position.y + sin(random_angle) * spawn_radius
	
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	
	# Tell the new enemy to hunt the player
	new_enemy.target_node = player
	
	# Add the enemy to the world
	add_child(new_enemy)
