extends CompanionBase
## Pikachu (The Survivor / AoE Lightning Pokémon)
## Calls down random lightning strikes around the player.
## Number of strikes scales with `GlobalStats.global_projectiles`.

func _custom_ready() -> void:
	set_process(true)

func _custom_process(_delta: float) -> void:
	if target_node == null:
		return
		
	# Periodic lightning strikes
	if current_cooldown <= 0.0:
		current_cooldown = get_cooldown()
		_spawn_lightning_strikes()

func _spawn_lightning_strikes() -> void:
	var strike_count: int = GlobalStats.global_projectiles
	
	for i in range(strike_count):
		# Pick a random offset around player
		var angle: float = randf() * TAU
		var dist: float = randf_range(50.0, 220.0)
		var strike_pos: Vector2 = target_node.global_position + Vector2(cos(angle), sin(angle)) * dist
		
		# Spawn warning indicator
		_create_lightning_warning(strike_pos)

func _create_lightning_warning(pos: Vector2) -> void:
	# Create a visual indicator ring
	var indicator: Line2D = Line2D.new()
	indicator.width = 2.0
	indicator.default_color = Color(1.0, 0.9, 0.2, 0.4) # Transparent gold
	
	# Draw outline circle of radius 40
	var points: Array[Vector2] = []
	var segments: int = 16
	var strike_radius: float = 55.0 * GlobalStats.global_aoe_radius
	for i in range(segments + 1):
		var theta: float = i * (TAU / segments)
		points.append(Vector2(cos(theta), sin(theta)) * strike_radius)
	indicator.points = PackedVector2Array(points)
	indicator.global_position = pos
	get_parent().call_deferred("add_child", indicator)
	
	# Transition warning to strike
	var tween: Tween = create_tween()
	tween.tween_property(indicator, "modulate", Color(1.0, 0.9, 0.2, 1.0), 0.35)
	tween.tween_callback(func():
		if is_instance_valid(indicator):
			indicator.queue_free()
		_execute_lightning_strike(pos, strike_radius)
	)

func _execute_lightning_strike(pos: Vector2, radius: float) -> void:
	# 1. Damage all enemies in strike zone
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var hit_any: bool = false
	
	for enemy in enemies:
		if enemy is CharacterBody2D and is_instance_valid(enemy):
			if pos.distance_to(enemy.global_position) <= radius:
				enemy.take_damage(get_damage())
				hit_any = true
				
	# 2. Draw vertical jagged lightning line
	var bolt: Line2D = Line2D.new()
	bolt.width = 4.0
	bolt.default_color = Color(1.0, 0.95, 0.5, 0.9) # Bright white/yellow
	
	# Draw jagged lightning path from sky to ground
	var start_y: float = pos.y - 400.0
	var bolt_points: Array[Vector2] = [Vector2(pos.x, start_y)]
	var steps: int = 5
	for i in range(1, steps):
		var step_y: float = start_y + (400.0 / steps) * i
		var step_x: float = pos.x + randf_range(-25.0, 25.0)
		bolt_points.append(Vector2(step_x, step_y))
	bolt_points.append(pos)
	
	bolt.points = PackedVector2Array(bolt_points)
	get_parent().call_deferred("add_child", bolt)
	
	# Fade out bolt quickly
	var tween: Tween = create_tween()
	tween.tween_property(bolt, "width", 0.0, 0.15)
	tween.tween_callback(bolt.queue_free)
	
	if hit_any:
		SoundManager.play_sound("shoot_projectile")
		# Subtle shake
		var camera = target_node.get_node("Camera2D")
		if camera != null and camera.has_method("add_trauma"):
			camera.add_trauma(0.25)
