extends CompanionBase
## Raichu (Evolved Pikachu)
## Lightning strikes leave lingering electrified hazard zones on the ground.

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
		var angle: float = randf() * TAU
		var dist: float = randf_range(50.0, 240.0)
		var strike_pos: Vector2 = target_node.global_position + Vector2(cos(angle), sin(angle)) * dist
		
		_create_lightning_warning(strike_pos)

func _create_lightning_warning(pos: Vector2) -> void:
	var indicator: Line2D = Line2D.new()
	indicator.width = 2.0
	indicator.default_color = Color(1.0, 0.9, 0.2, 0.4)
	
	var points: Array[Vector2] = []
	var segments: int = 16
	var strike_radius: float = 60.0 * GlobalStats.global_aoe_radius
	for i in range(segments + 1):
		var theta: float = i * (TAU / segments)
		points.append(Vector2(cos(theta), sin(theta)) * strike_radius)
	indicator.points = PackedVector2Array(points)
	indicator.global_position = pos
	get_parent().call_deferred("add_child", indicator)
	
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
	bolt.width = 5.0
	bolt.default_color = Color(1.0, 0.95, 0.6, 0.9)
	
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
	
	# Spawn dust burst particles at impact point
	_spawn_lightning_dust(pos)
	
	var tween: Tween = create_tween()
	tween.tween_property(bolt, "width", 0.0, 0.15)
	tween.tween_callback(bolt.queue_free)
	
	# 3. Spawn lingering electric hazard zone
	_spawn_hazard_zone(pos, radius)
	
	if hit_any:
		SoundManager.play_sound("shoot_projectile")
		var camera = target_node.get_node("Camera2D")
		if camera != null and camera.has_method("add_trauma"):
			camera.add_trauma(0.3)

func _spawn_hazard_zone(pos: Vector2, radius: float) -> void:
	# Create a visual electrified ring on floor
	var ring: Line2D = Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(0.2, 0.8, 1.0, 0.6) # Electrical light blue
	
	var points: Array[Vector2] = []
	var segments: int = 12
	for i in range(segments + 1):
		var theta: float = i * (TAU / segments)
		# Add a tiny bit of jagged noise
		var r = radius + randf_range(-5.0, 5.0)
		points.append(Vector2(cos(theta), sin(theta)) * r)
	ring.points = PackedVector2Array(points)
	ring.global_position = pos
	get_parent().call_deferred("add_child", ring)
	
	# Setup tick process
	var lifetime: float = 3.0
	var tick_rate: float = 0.4
	var elapsed: float = 0.0
	
	var tween = create_tween()
	tween.set_loops(int(lifetime / tick_rate))
	tween.tween_callback(func():
		# Ticking damage to enemies in zone
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if enemy is CharacterBody2D and is_instance_valid(enemy):
				if pos.distance_to(enemy.global_position) <= radius:
					enemy.take_damage(int(get_damage() * 0.35))
					
		# Crackle line points slightly for kinetic visual effect
		if is_instance_valid(ring):
			var new_pts: Array[Vector2] = []
			for i in range(segments + 1):
				var theta: float = i * (TAU / segments)
				var r = radius + randf_range(-6.0, 6.0)
				new_pts.append(Vector2(cos(theta), sin(theta)) * r)
			ring.points = PackedVector2Array(new_pts)
	).set_delay(tick_rate)
	
	# Clean up ring
	var fade_tween = create_tween()
	fade_tween.tween_property(ring, "modulate:a", 0.0, lifetime)
	fade_tween.tween_callback(ring.queue_free)

func _spawn_lightning_dust(pos: Vector2) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = pos
	particles.amount = 16
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	# Yellowish electrical dust color
	particles.color = Color(1.0, 0.9, 0.3, 0.8)
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.9, 0.3, 0.8), Color(0.2, 0.2, 0.2, 0.0)])
	particles.color_ramp = grad
	
	get_parent().call_deferred("add_child", particles)
	particles.emitting = true
	
	get_tree().create_timer(0.6).timeout.connect(particles.queue_free)
