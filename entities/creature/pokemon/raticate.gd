extends CompanionBase
## Raticate (Evolved Rattata)
## Bites apply Bleed (10 damage ticks). Inherent double-sized magnet radius.

enum State { FOLLOW, ATTACK }
var state: State = State.FOLLOW
var current_enemy: CharacterBody2D = null

func _custom_ready() -> void:
	$AggroRange.body_entered.connect(_on_aggro_entered)
	$MagnetRange.area_entered.connect(_on_magnet_entered)

func _custom_process(delta: float) -> void:
	match state:
		State.FOLLOW:
			pass
			
		State.ATTACK:
			if current_enemy != null and is_instance_valid(current_enemy):
				var lunge_speed: float = follow_speed * 1.8 * GlobalStats.global_velocity_mult
				global_position = global_position.lerp(current_enemy.global_position, lunge_speed * delta)
				
				# Bite attack
				if global_position.distance_to(current_enemy.global_position) < 30.0:
					if current_cooldown <= 0.0:
						current_cooldown = get_cooldown()
						_bite_attack(current_enemy)
			else:
				current_enemy = null
				state = State.FOLLOW

func _bite_attack(enemy: CharacterBody2D) -> void:
	# Deal base damage + apply Bleed ticks
	enemy.take_damage(get_damage())
	if enemy.has_method("apply_bleed"):
		enemy.apply_bleed(10, 3.0) # 10 bleed damage for 3 seconds
		
	SoundManager.play_sound("brawler_impact")
	
	if not is_instance_valid(enemy) or enemy.current_hp <= 0:
		current_enemy = null
		state = State.FOLLOW

func _on_aggro_entered(body: Node2D) -> void:
	if state == State.FOLLOW and body.is_in_group("enemy") and is_instance_valid(body):
		current_enemy = body as CharacterBody2D
		state = State.ATTACK

func _on_magnet_entered(area: Area2D) -> void:
	if area.is_in_group("gem") and target_node != null:
		# Attract to player
		area.magnetize_to(target_node)
