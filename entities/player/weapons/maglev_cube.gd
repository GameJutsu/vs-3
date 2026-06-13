extends Node2D
## Maglev Cube Weapon Script
## Attached to Player. Orbiting kinetic cube that winds up when holding LMB,
## rockets at the nearest enemy, detonates on impact, and returns scrambled.

# --- STATE MACHINE ---
enum State { IDLE, SOLVING, LAUNCHED, RETURNING }
var state: State = State.IDLE

# --- CORE SETTINGS ---
var base_damage: float = 120.0
var base_launch_speed: float = 1200.0
var base_wind_up_duration: float = 0.85 # Time in seconds to "solve" the cube
var base_explosion_radius: float = 140.0

# --- MATH & LEASHING ---
var idle_orbit_angle: float = 0.0
var idle_orbit_speed: float = 2.5
var idle_orbit_radius: float = 55.0

# --- INTERNAL STATE ---
var wind_up_timer: float = 0.0
var target_enemy: CharacterBody2D = null
var launch_direction: Vector2 = Vector2.RIGHT
var target_pos: Vector2 = Vector2.ZERO
var trail_points: Array[Vector2] = []

# --- REFERENCES ---
var player: CharacterBody2D = null

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	queue_redraw()

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	# Handle states
	match state:
		State.IDLE:
			# Orbit around player
			idle_orbit_angle += idle_orbit_speed * delta * GlobalStats.global_velocity_mult
			var target_offset = Vector2(cos(idle_orbit_angle), sin(idle_orbit_angle)) * idle_orbit_radius
			var target_idle_pos = player.global_position + target_offset
			global_position = global_position.lerp(target_idle_pos, 10.0 * delta)
			
			# Face direction of rotation
			rotation = idle_orbit_angle + PI/4
			scale = scale.lerp(Vector2.ONE, 10.0 * delta)
			
			# Transition to solving if LMB is held
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not get_tree().paused:
				state = State.SOLVING
				wind_up_timer = 0.0
				SoundManager.play_sound("maglev_solve")
				
		State.SOLVING:
			# Stay relative to player while solving
			idle_orbit_angle += idle_orbit_speed * 2.0 * delta * GlobalStats.global_velocity_mult
			var target_offset = Vector2(cos(idle_orbit_angle), sin(idle_orbit_angle)) * (idle_orbit_radius * 0.7)
			var target_idle_pos = player.global_position + target_offset
			global_position = global_position.lerp(target_idle_pos, 15.0 * delta)
			
			# Increment timer
			wind_up_timer += delta
			var progress = clampf(wind_up_timer / (base_wind_up_duration / GlobalStats.global_fire_rate_mult), 0.0, 1.0)
			
			# Visual spin & scale feedback (spinning wild and pulsing)
			rotation += (5.0 + 30.0 * progress) * delta
			scale = Vector2.ONE * (1.0 + 0.5 * sin(wind_up_timer * 25.0) * progress)
			
			# If player releases LMB before solved, revert to idle
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				state = State.IDLE
				scale = Vector2.ONE
			# Once fully solved, launch!
			elif progress >= 1.0:
				_launch()
				
		State.LAUNCHED:
			# Update trail
			trail_points.append(global_position)
			if trail_points.size() > 8:
				trail_points.remove_at(0)
				
			# Lock onto target or mouse direction
			if target_enemy != null and is_instance_valid(target_enemy):
				target_pos = target_enemy.global_position
			
			var to_target = target_pos - global_position
			var dist = to_target.length()
			
			if dist > 15.0:
				var dir = to_target.normalized()
				var speed = base_launch_speed * GlobalStats.global_velocity_mult
				global_position += dir * speed * delta
				rotation += 25.0 * delta
				
				# Detonation collision check (if close enough or hits any enemy)
				if dist <= 30.0:
					_detonate()
			else:
				_detonate()
				
		State.RETURNING:
			# Update trail
			trail_points.append(global_position)
			if trail_points.size() > 6:
				trail_points.remove_at(0)
				
			# Return to player
			var to_player = player.global_position - global_position
			var dist = to_player.length()
			
			if dist > 15.0:
				var dir = to_player.normalized()
				var speed = base_launch_speed * 0.75 * GlobalStats.global_velocity_mult
				global_position += dir * speed * delta
				rotation += 4.0 * delta # slowly rotating scrambled cube
				scale = scale.lerp(Vector2.ONE * 0.7, 10.0 * delta) # looks smaller/scrambled
			else:
				# Reset back to idle
				state = State.IDLE
				trail_points.clear()
				
	queue_redraw()

func _launch() -> void:
	state = State.LAUNCHED
	trail_points.clear()
	
	# Find nearest enemy
	target_enemy = _get_nearest_enemy()
	
	if target_enemy != null:
		target_pos = target_enemy.global_position
	else:
		# If no enemy, launch in direction of mouse cursor
		var mouse_pos = get_global_mouse_position()
		launch_direction = (mouse_pos - global_position).normalized()
		if launch_direction == Vector2.ZERO:
			launch_direction = Vector2.UP
		target_pos = global_position + launch_direction * 400.0

func _detonate() -> void:
	state = State.RETURNING
	SoundManager.play_sound("maglev_explode")
	
	# Trigger camera shake
	if player.camera != null and player.camera.has_method("add_trauma"):
		player.camera.add_trauma(0.55)
		
	# Explode in area
	var radius = base_explosion_radius * GlobalStats.global_aoe_radius
	var damage = int(base_damage)
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is CharacterBody2D and is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= radius:
				enemy.take_damage(damage)
				# Pushback force from center of explosion
				var push_dir = (enemy.global_position - global_position).normalized()
				if push_dir == Vector2.ZERO:
					push_dir = Vector2.RIGHT
				# Apply a strong physical knockback
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(push_dir * 550.0)
					
	# Visual blast feedback
	_spawn_blast_particles(radius)

func _get_nearest_enemy() -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: CharacterBody2D = null
	var min_dist: float = INF
	for enemy in enemies:
		if enemy is CharacterBody2D and is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
	return nearest

func _spawn_blast_particles(radius: float) -> void:
	# Explosion shockwave ring
	var blast: CPUParticles2D = CPUParticles2D.new()
	blast.global_position = global_position
	blast.amount = 35
	blast.one_shot = true
	blast.explosiveness = 0.95
	blast.lifetime = 0.5
	blast.spread = 180.0
	blast.gravity = Vector2.ZERO
	blast.initial_velocity_min = radius * 1.5
	blast.initial_velocity_max = radius * 2.5
	blast.scale_amount_min = 4.0
	blast.scale_amount_max = 8.0
	blast.color = Color(0.0, 0.95, 1.0, 1.0) # bright electric cyan
	
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0.0, 0.95, 1.0, 1.0), Color(0.05, 0.3, 0.7, 0.0)])
	blast.color_ramp = grad
	
	get_parent().get_parent().add_child(blast)
	blast.emitting = true
	
	get_tree().create_timer(0.6).timeout.connect(blast.queue_free)

func _draw() -> void:
	# Draw programmatic neon trails first
	if trail_points.size() > 1:
		for i in range(trail_points.size()):
			var p = trail_points[i]
			var rel_p = p - global_position
			var alpha = float(i) / trail_points.size()
			var trail_size = 14.0 * alpha
			
			# Draw trail node circle
			draw_rect(Rect2(-trail_size/2, -trail_size/2, trail_size, trail_size), Color(0.0, 0.85, 0.9, 0.22 * alpha))
			draw_rect(Rect2(-trail_size/2, -trail_size/2, trail_size, trail_size), Color(0.0, 0.95, 1.0, 0.35 * alpha), false, 1.0)
	
	# Determine visual color based on state
	var fill_color = Color(0.0, 0.85, 0.9, 0.6)
	var line_color = Color(0.0, 0.95, 1.0, 1.0)
	
	match state:
		State.SOLVING:
			# Pulsing orange/yellow when charging
			var pulse = sin(wind_up_timer * 30.0) * 0.5 + 0.5
			fill_color = Color(1.0, 0.5 + 0.3 * pulse, 0.0, 0.7)
			line_color = Color(1.0, 0.8, 0.2, 1.0)
		State.LAUNCHED:
			fill_color = Color(0.0, 0.95, 1.0, 0.8)
			line_color = Color(1.0, 1.0, 1.0, 1.0)
		State.RETURNING:
			# Dark/disabled appearance
			fill_color = Color(0.1, 0.3, 0.5, 0.4)
			line_color = Color(0.2, 0.5, 0.7, 0.8)
			
	# Draw core cube
	draw_rect(Rect2(-12, -12, 24, 24), fill_color)
	draw_rect(Rect2(-12, -12, 24, 24), line_color, false, 2.0)
	
	# Draw a glowing center dot
	draw_circle(Vector2.ZERO, 3.0, line_color)
