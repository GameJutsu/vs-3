extends CompanionBase
## Staryu (The Orbital Shooter / Projectiles Pokémon)
## Orbits the player tightly. Fires water-bullets outward.
## Orbit speed scales with `GlobalStats.global_velocity_mult`.

var _angle: float = 0.0

func _custom_ready() -> void:
	# Start with a random orbit angle
	_angle = randf() * TAU
	set_process(true)

func _custom_process(delta: float) -> void:
	if target_node == null:
		return
		
	# Orbit kinematics
	var speed_multiplier: float = GlobalStats.global_velocity_mult
	_angle += follow_speed * speed_multiplier * delta
	
	var offset: Vector2 = Vector2(cos(_angle), sin(_angle)) * follow_distance
	global_position = target_node.global_position + offset
	
	# Periodic shooting
	if current_cooldown <= 0.0:
		current_cooldown = get_cooldown()
		_fire_bullets()

func _fire_bullets() -> void:
	var enemy: Node2D = _find_closest_enemy(400.0)
	var fire_dir: Vector2 = Vector2.RIGHT
	
	if enemy != null:
		fire_dir = global_position.direction_to(enemy.global_position)
	else:
		# Shoot outward away from player
		fire_dir = target_node.global_position.direction_to(global_position)
		
	# Number of bullets scales with global_projectiles (spread pattern)
	var count: int = GlobalStats.global_projectiles
	var spread_angle: float = 15.0 # Degrees between shots
	
	for i in range(count):
		# Calculate angle offset for spread
		var offset_deg: float = (i - (count - 1) / 2.0) * spread_angle
		var rad: float = deg_to_rad(offset_deg)
		var dir: Vector2 = fire_dir.rotated(rad)
		
		var bullet: Area2D = PROJECTILE_SCENE.instantiate()
		bullet.global_position = global_position
		bullet.direction = dir
		bullet.speed = 400.0
		bullet.damage = get_damage()
		# Blue tint for water-bullets
		bullet.modulate = Color(0.2, 0.5, 1.0, 1.0)
		
		get_parent().call_deferred("add_child", bullet)
		
	SoundManager.play_sound("shoot_projectile")

func _find_closest_enemy(max_dist: float) -> Node2D:
	var closest_enemy: Node2D = null
	var min_distance: float = max_dist
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_enemy = enemy
				
	return closest_enemy
