extends Area2D

# --- EXPORTED VARIABLES ---
# Allows designers to create "Big Gems" or "Small Gems" in the inspector
@export var xp_value: int = 10

# --- INTERNAL STATE ---
var target: Node2D = null
var current_speed: float = 0.0

func _process(delta: float) -> void:
	# 1. Idle State: If we have no target, do nothing.
	if target == null:
		return
		
	# 2. Collecting State: Accelerate towards the target.
	# By increasing speed over time (acceleration), the gem "snaps" to the player 
	# instead of floating lazily, creating a much punchier visual feel.
	current_speed += 400.0 * delta 
	
	# move_toward safely pushes a vector towards a target without overshooting it
	global_position = global_position.move_toward(target.global_position, current_speed * delta)

# This is a public method the Player will call when the gem enters the magnet radius
func magnetize_to(new_target: Node2D) -> void:
	target = new_target
