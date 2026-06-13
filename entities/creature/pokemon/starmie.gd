extends CompanionBase
## Starmie (Evolved Staryu)
## Orbits the player. Fires a continuous laser beam sweeping the screen.

@export var laser_length: float = 350.0
@export var laser_width: float = 8.0

var _angle: float = 0.0
var _laser_line: Line2D = null

func _custom_ready() -> void:
	_angle = randf() * TAU
	
	# Create Line2D for laser beam graphics
	_laser_line = Line2D.new()
	_laser_line.width = laser_width
	_laser_line.default_color = Color(0.9, 0.1, 0.8, 0.6) # Thick glowing purple
	add_child(_laser_line)
	
	set_process(true)

func _custom_process(delta: float) -> void:
	if target_node == null:
		return
		
	# Orbit kinematics
	var speed_multiplier: float = GlobalStats.global_velocity_mult
	_angle += follow_speed * speed_multiplier * delta
	
	var offset: Vector2 = Vector2(cos(_angle), sin(_angle)) * follow_distance
	global_position = target_node.global_position + offset
	
	# Calculate laser line pointing outward away from player
	var laser_dir: Vector2 = target_node.global_position.direction_to(global_position)
	var laser_end_pos: Vector2 = laser_dir * laser_length * GlobalStats.global_aoe_radius
	
	# Render laser
	_laser_line.points = PackedVector2Array([Vector2.ZERO, laser_end_pos])
	
	# Ticking damage along the beam
	if current_cooldown <= 0.0:
		current_cooldown = get_cooldown() * 0.3 # Ticks 3x faster than normal attacks
		_sweep_laser_damage(laser_end_pos)

func _sweep_laser_damage(laser_end_relative: Vector2) -> void:
	var a: Vector2 = global_position
	var b: Vector2 = global_position + laser_end_relative
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var hit_any: bool = false
	
	for enemy in enemies:
		if enemy is CharacterBody2D and is_instance_valid(enemy):
			var dist: float = _get_distance_to_segment(enemy.global_position, a, b)
			# Enemy collision size is roughly 40px radius
			if dist <= (laser_width + 35.0):
				# Deal ticks of damage
				enemy.take_damage(int(get_damage() * 0.4)) # Fast ticking low damage
				hit_any = true
				
	if hit_any:
		SoundManager.play_sound("enemy_hit")

func _get_distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ap: Vector2 = p - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq == 0.0:
		return ap.length()
	var t: float = clampf(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var projection: Vector2 = a + ab * t
	return p.distance_to(projection)

func _exit_tree() -> void:
	if is_instance_valid(_laser_line):
		_laser_line.queue_free()
