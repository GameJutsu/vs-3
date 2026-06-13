extends Area2D
## Health Cherry Script
## Collectible that heals the player by 25 HP. Magnetizes like a gem.

var target: Node2D = null
var current_speed: float = 0.0
var drift_velocity: Vector2 = Vector2.ZERO # Drift velocity for organic curved movement
var _collected: bool = false

func _ready() -> void:
	add_to_group("gem") # So it gets magnetized by player magnet

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

func magnetize_to(new_target: Node2D) -> void:
	if target == null: # Set drift only on first magnetization
		target = new_target
		var dir = global_position.direction_to(target.global_position)
		var perp = Vector2(-dir.y, dir.x)
		var side = 1.0 if randf() < 0.5 else -1.0
		drift_velocity = perp * side * randf_range(180.0, 280.0)

func collect_cherry(player: Node2D) -> void:
	if _collected:
		return
	_collected = true
	$CollisionShape2D.set_deferred("disabled", true)
	set_process(false)
	
	if player.has_method("heal"):
		player.heal(25)
	
	SoundManager.play_sound("healer_pulse")
	
	# Play pop animation
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)

func _spawn_sparkle_particle() -> void:
	var sparkle = Sparkle.new()
	# Bright red/crimson sparkle
	sparkle.color = Color(1.0, 0.2, 0.2, 0.8)
	sparkle.global_position = global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	get_parent().add_child(sparkle)

func _draw() -> void:
	# Draw a cherry!
	# Red circle for the cherry body
	draw_circle(Vector2(0, 4), 8.0, Color(0.9, 0.1, 0.1, 1.0))
	# Draw highlight
	draw_circle(Vector2(-3, 1), 2.5, Color(1.0, 0.6, 0.6, 0.9))
	# Draw green stem
	draw_line(Vector2(0, -2), Vector2(4, -8), Color(0.2, 0.7, 0.1, 1.0), 2.0)
	# Draw a tiny green leaf
	draw_circle(Vector2(4, -8), 3.0, Color(0.3, 0.8, 0.2, 1.0))

# --- NESTED SPARKLE PARTICLE CLASS ---
class Sparkle extends Node2D:
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
