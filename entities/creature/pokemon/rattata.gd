extends CompanionBase
## Rattata (The Scavenger / Melee Pokémon)
## Dashes at enemies to bite. Magnetizes XP gems in a radius to fetch them for the player.

# --- STATE MACHINE ---
enum State { FOLLOW, ATTACK }
var state: State = State.FOLLOW
var current_enemy: CharacterBody2D = null

func _custom_ready() -> void:
	# Connect Area2D overlapping signals for Aggro and Magnet
	$AggroRange.body_entered.connect(_on_aggro_entered)
	$MagnetRange.area_entered.connect(_on_magnet_entered)

func _custom_process(delta: float) -> void:
	# Run FSM
	match state:
		State.FOLLOW:
			pass # Follow kinematics handled in base class
			
		State.ATTACK:
			if current_enemy != null and is_instance_valid(current_enemy):
				var lunge_speed: float = follow_speed * 1.6 * GlobalStats.global_velocity_mult
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
	enemy.take_damage(get_damage())
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
