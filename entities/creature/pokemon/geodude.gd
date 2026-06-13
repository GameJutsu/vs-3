extends CompanionBase
## Geodude (The Brawler / Kinetic Pokémon)
## Punches enemies to create high knockback. Deals domino pushback to nearby enemies.

enum State { FOLLOW, ATTACK }
var state: State = State.FOLLOW
var current_enemy: CharacterBody2D = null

func _custom_ready() -> void:
	$AggroRange.body_entered.connect(_on_aggro_entered)

func _custom_process(delta: float) -> void:
	match state:
		State.FOLLOW:
			pass
			
		State.ATTACK:
			if current_enemy != null and is_instance_valid(current_enemy):
				# Geodude is heavy, so its lunge is deliberate
				var lunge_speed: float = follow_speed * 1.3 * GlobalStats.global_velocity_mult
				global_position = global_position.lerp(current_enemy.global_position, lunge_speed * delta)
				
				# Punch range
				if global_position.distance_to(current_enemy.global_position) < 35.0:
					if current_cooldown <= 0.0:
						current_cooldown = get_cooldown()
						_punch_attack(current_enemy)
			else:
				current_enemy = null
				state = State.FOLLOW

func _punch_attack(enemy: CharacterBody2D) -> void:
	var push_dir: Vector2 = global_position.direction_to(enemy.global_position).normalized()
	
	# Deal heavy damage
	enemy.take_damage(get_damage())
	
	# Apply strong knockback to primary target
	if is_instance_valid(enemy):
		enemy.global_position += push_dir * 80.0
		
	# Domino knockback: push nearby enemies as well
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for other in enemies:
		if other is CharacterBody2D and is_instance_valid(other) and other != enemy:
			var dist = enemy.global_position.distance_to(other.global_position)
			if dist <= 100.0:
				other.global_position += push_dir * 40.0 # Domino push
				
	SoundManager.play_sound("brawler_impact")
	
	if not is_instance_valid(enemy) or enemy.current_hp <= 0:
		current_enemy = null
		state = State.FOLLOW

func _on_aggro_entered(body: Node2D) -> void:
	if state == State.FOLLOW and body.is_in_group("enemy") and is_instance_valid(body):
		current_enemy = body as CharacterBody2D
		state = State.ATTACK
