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
var _collected: bool = false               # Guard flag to prevent double-collection

# --- FRAME-BY-FRAME MOVEMENT ---
func _process(delta: float) -> void:
	if target == null or _collected:
		return
		
	# Accelerate towards the target for a satisfying "vacuum snap" effect
	current_speed += 400.0 * delta 
	global_position = global_position.move_toward(target.global_position, current_speed * delta)

# --- PUBLIC INTERFACE ---
# Called by the Player's magnet script when the gem enters the magnetic radius.
func magnetize_to(new_target: Node2D) -> void:
	target = new_target

# --- COLLECTION WITH VISUAL POP ---
# Called by the Player when the gem reaches the hurtbox.
# Instead of instantly vanishing, the gem plays a satisfying scale-up pop and fade-out.
func collect() -> void:
	if _collected:
		return
	_collected = true
	
	# Disable the collision shape so we don't get collected twice
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Stop chasing the player
	set_process(false)
	
	# Play a quick pop: scale up 1.5x and fade out over 0.15 seconds
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
