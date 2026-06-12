extends Node2D
## World Controller Script
## This script coordinates the main game loop: initializing connections between nodes,
## managing the player and creature companion, and spawning enemies periodically around the player.

# --- EXPORTED RESOURCES ---
# PackedScene represents a saved scene file (like enemy.tscn) that we can load and instantiate.
# Exporting this allows developers to assign the Enemy scene in the Godot Editor Inspector.
@export var enemy_scene: PackedScene

# --- CHILD NODE REFERENCES ---
# '@onready' variables load when the game starts. 
# The '$Name' syntax is a shorthand shortcut for 'get_node("Name")'.
@onready var player: CharacterBody2D = $Player
@onready var creature: Area2D = $Creature

# --- INITIALIZATION ---
func _ready() -> void:
	# Dependency Injection: Pass the player's object reference to the companion creature.
	# This lets the creature know who to follow and protect without needing hardcoded paths.
	creature.target_node = player

# --- TIMED EVENTS (SPAWNER) ---
# Signal callback: Connected to the Timer node's 'timeout' signal.
# Triggered automatically every time the spawn timer count hits zero.
func _on_spawn_timer_timeout() -> void:
	# Guard clause: Prevents game crashes if the developer forgot to assign the enemy_scene in the Inspector
	if enemy_scene == null:
		return 
		
	# 1. Create a live object instance of the Enemy scene in memory
	var new_enemy: CharacterBody2D = enemy_scene.instantiate()
	
	# 2. Spawning Math: Spawn enemies in a circle around the player just off-screen
	# - spawn_radius: 600 pixels is far enough to hide spawning from the player's view
	var spawn_radius: float = 600.0
	
	# - randf() returns a random float between 0.0 and 1.0
	# - TAU is a math constant equal to 2 * PI (approx. 6.283), representing a full 360-degree circle in radians
	var random_angle: float = randf() * TAU
	
	# - Use Trigonometry (sine and cosine) to convert polar coordinates (angle + radius) into Cartesian coordinates (X + Y)
	#   x = center_x + cos(angle) * radius
	#   y = center_y + sin(angle) * radius
	var spawn_x: float = player.global_position.x + cos(random_angle) * spawn_radius
	var spawn_y: float = player.global_position.y + sin(random_angle) * spawn_radius
	
	# 3. Position the new enemy at the calculated coordinates
	new_enemy.global_position = Vector2(spawn_x, spawn_y)
	
	# 4. Inject the player reference into the enemy so they know whom to hunt
	new_enemy.target_node = player
	
	# 5. Add the enemy node to the World scene tree so it renders and starts running its physics loop
	add_child(new_enemy)

