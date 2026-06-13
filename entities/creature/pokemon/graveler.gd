extends CompanionBase
## Graveler (Evolved Geodude)
## Punches release localized earthquake stuns slowing enemies in a radius.

enum State { FOLLOW, ATTACK }
var state: State = State.FOLLOW
var current_enemy: CharacterBody2D = null

func _custom_ready() -> void:
	_base_scale = _base_scale * 1.3
	$AggroRange.body_entered.connect(_on_aggro_entered)

func _custom_process(delta: float) -> void:
	match state:
		State.FOLLOW:
			pass
			
		State.ATTACK:
			if current_enemy != null and is_instance_valid(current_enemy):
				var lunge_speed: float = follow_speed * 1.4 * GlobalStats.global_velocity_mult
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
	var punch_pos: Vector2 = enemy.global_position
	var push_dir: Vector2 = global_position.direction_to(punch_pos).normalized()
	
	# Primary damage & knockback
	enemy.take_damage(get_damage())
	if is_instance_valid(enemy):
		enemy.global_position += push_dir * 100.0
		
	# Trigger localized earthquake shockwave
	var eq_radius: float = 160.0 * GlobalStats.global_aoe_radius
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	
	for other in enemies:
		if other is CharacterBody2D and is_instance_valid(other):
			var dist = punch_pos.distance_to(other.global_position)
			if dist <= eq_radius:
				# Apply domino pushback if close
				if other != enemy and dist <= 100.0:
					other.global_position += push_dir * 50.0
					
				# Deal minor shock damage & apply 40% slow (factor 0.6) for 2s
				if other.has_method("apply_slow"):
					other.apply_slow(0.6, 2.0)
					if other != enemy:
						other.take_damage(int(get_damage() * 0.3))
						
	# Spawn visual earthquake ring particle burst (handled using floating pop text or similar)
	var shock_label: Label = DAMAGE_NUMBER_SCENE.instantiate()
	shock_label.text = "✖ EARTHQUAKE ✖"
	shock_label.modulate = Color(0.7, 0.5, 0.3, 1.0) # Earthy brown/gold
	shock_label.global_position = punch_pos + Vector2(-60, -30)
	get_parent().call_deferred("add_child", shock_label)
	
	SoundManager.play_sound("brawler_impact")
	
	if not is_instance_valid(enemy) or enemy.current_hp <= 0:
		current_enemy = null
		state = State.FOLLOW

func _on_aggro_entered(body: Node2D) -> void:
	if state == State.FOLLOW and body.is_in_group("enemy") and is_instance_valid(body):
		current_enemy = body as CharacterBody2D
		state = State.ATTACK
