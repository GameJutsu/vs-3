extends Area2D
## Experience Gem Script
## This script controls the behavior of collectible items (XP gems) in the game world.
## Gems remain stationary until they enter the player's magnet detection zone,
## at which point they accelerate towards the player for collection.

# --- EXPORTED VARIABLES ---
@export var xp_value: int = 10

# --- INTERNAL KINEMATICS ---
var target: Node2D = null                  # The target node we are drawn to (typically the player character)
var current_speed: float = 0.0             # Starts at 0.0; we accelerate this over time
var drift_velocity: Vector2 = Vector2.ZERO # Drift velocity for organic curved movement
var _collected: bool = false               # Guard flag to prevent double-collection

# --- INITIALIZATION ---
func _ready() -> void:
	if xp_value >= 100:
		# Glowing Golden Gem (elites)
		modulate = Color(1.8, 1.4, 0.2, 1.0) # Golden HDR glow
		scale = Vector2(1.5, 1.5)
	elif xp_value >= 50:
		# Medium gem
		modulate = Color(1.5, 0.8, 0.0, 1.0) # Orange
		scale = Vector2(1.2, 1.2)
	else:
		# Standard green gem
		modulate = Color(0.2, 1.0, 0.3, 1.0) # Green
		scale = Vector2(0.8, 0.8)

# --- FRAME-BY-FRAME MOVEMENT ---
func _process(delta: float) -> void:
	if target == null or _collected:
		return
		
	# Accelerate towards the target for a satisfying "vacuum snap" effect
	current_speed += 600.0 * delta 
	
	var dir = global_position.direction_to(target.global_position)
	var target_vel = dir * current_speed
	
	# Decay drift velocity towards zero
	drift_velocity = drift_velocity.move_toward(Vector2.ZERO, 350.0 * delta)
	
	global_position += (target_vel + drift_velocity) * delta
	
	# Spawn sparkling trail particles
	if randf() < 0.3:
		_spawn_sparkle_particle()

# --- PUBLIC INTERFACE ---
func magnetize_to(new_target: Node2D) -> void:
	if target == null: # Set drift only on first magnetization
		target = new_target
		var dir = global_position.direction_to(target.global_position)
		var perp = Vector2(-dir.y, dir.x)
		var side = 1.0 if randf() < 0.5 else -1.0
		drift_velocity = perp * side * randf_range(180.0, 280.0)

# --- COLLECTION WITH VISUAL POP ---
func collect() -> void:
	if _collected:
		return
	_collected = true
	
	$CollisionShape2D.set_deferred("disabled", true)
	set_process(false)
	
	# Play a quick pop: scale up 1.5x and fade out over 0.15 seconds
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

func _spawn_sparkle_particle() -> void:
	var sparkle = Sparkle.new()
	sparkle.color = Color(modulate.r * 1.2, modulate.g * 1.2, modulate.b * 1.2, 0.8)
	sparkle.global_position = global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	get_parent().add_child(sparkle)

# --- NESTED SPARKLE PARTICLE CLASS ---
class Sparkle:
	extends Node2D
	
	var color: Color
	var scale_speed: float
	
	func _ready() -> void:
		scale = Vector2(randf_range(0.4, 0.8), randf_range(0.4, 0.8))
		scale_speed = randf_range(1.5, 3.0)
		rotation = randf() * TAU
		
	func _process(delta: float) -> void:
		scale = scale.move_toward(Vector2.ZERO, scale_speed * delta)
		if scale.is_equal_approx(Vector2.ZERO):
			queue_free()
			
	func _draw() -> void:
		var points = PackedVector2Array([
			Vector2(0, -3), Vector2(0.8, -0.8), Vector2(3, 0), Vector2(0.8, 0.8),
			Vector2(0, 3), Vector2(-0.8, 0.8), Vector2(-3, 0), Vector2(-0.8, -0.8)
		])
		draw_colored_polygon(points, color)

