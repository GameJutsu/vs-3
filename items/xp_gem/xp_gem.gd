extends Area2D
## Experience Gem Script
## This script controls the behavior of collectible items (XP gems) in the game world.
## Gems remain stationary until they enter the player's magnet detection zone,
## at which point they accelerate towards the player for collection.

# --- EXPORTED VARIABLES ---
# Allows designers to set different XP values (e.g., small green gems = 10 XP, large gold gems = 50 XP)
# directly in the Inspector or when spawning.
@export var xp_value: int = 10

# --- INTERNAL KINEMATICS ---
var target: Node2D = null                  # The target node we are drawn to (typically the player character)
var current_speed: float = 0.0             # Starts at 0.0; we accelerate this over time

# --- FRAME-BY-FRAME MOVEMENT ---
# _process(delta) is used here because the gem does not perform physics collisions
# (like pushing walls or other bodies). It is a simple visual movement calculation.
func _process(delta: float) -> void:
	# 1. Idle State: If no target is set, the gem sits still waiting for the player.
	if target == null:
		return
		
	# 2. Collecting State: Accelerate towards the target.
	# We increment the speed by 400.0 pixels per second squared.
	# By multiplying by delta, we ensure the acceleration is smooth and independent of framerate.
	# Accelerating speed over time creates a satisfying "vacuum snap" effect where the gem 
	# speeds up as it gets closer to the player.
	current_speed += 400.0 * delta 
	
	# 3. Position Calculation:
	# global_position.move_toward() calculates a new position along a straight line 
	# to target.global_position. 
	# Unlike lerp (which slows down near the end), move_toward moves at a constant/accelerating 
	# speed and guarantees it will land exactly on the target without overshooting it.
	global_position = global_position.move_toward(target.global_position, current_speed * delta)

# --- PUBLIC INTERFACE ---
# This method is called by the Player's magnet script when the gem overlaps with the player's
# magnetic radius. It assigns the player as the target, initiating the attraction behavior.
func magnetize_to(new_target: Node2D) -> void:
	target = new_target

