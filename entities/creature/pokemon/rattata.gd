extends CompanionBase
## Rattata (The Scavenger / Melee Pokémon)
## Dashes at enemies to bite. Magnetizes XP gems in a radius to fetch them for the player.

# --- STATE MACHINE ---
enum State { FOLLOW, ATTACK }
var state: State = State.FOLLOW
var current_enemy: CharacterBody2D = null
var attack_phase_timer: float = 0.0

var attracted_gems: Array[Area2D] = []

func _custom_ready() -> void:
	# Connect Area2D overlapping signals for Aggro and Magnet
	$AggroRange.body_entered.connect(_on_aggro_entered)
	$MagnetRange.area_entered.connect(_on_magnet_entered)

func _custom_process(delta: float) -> void:
	queue_redraw()
	
	# Process attracted gems: check if they are close to Rattata
	var i = attracted_gems.size() - 1
	while i >= 0:
		var gem = attracted_gems[i]
		if is_instance_valid(gem) and gem.target == self:
			if global_position.distance_to(gem.global_position) < 35.0:
				# Magnetize to player now!
				gem.magnetize_to(target_node)
				attracted_gems.remove_at(i)
		else:
			attracted_gems.remove_at(i)
		i -= 1

	# Run FSM
	match state:
		State.FOLLOW:
			pass # Follow kinematics handled in base class
			
		State.ATTACK:
			if current_enemy != null and is_instance_valid(current_enemy):
				# Face the enemy directly
				var dir = global_position.direction_to(current_enemy.global_position)
				if sprite != null:
					sprite.rotation = dir.angle()
					if dir.x < 0:
						sprite.flip_h = true
						sprite.rotation += PI
					else:
						sprite.flip_h = false
						
				if attack_phase_timer > 0.0:
					attack_phase_timer -= delta
					# 1. Anticipation: squash down (charge)
					if sprite != null:
						sprite.scale = _base_scale * Vector2(0.6, 1.4)
					# Backup slightly to build anticipation
					global_position -= dir * 30.0 * delta
				else:
					# 2. Lunge: stretch out (dash)
					if sprite != null:
						sprite.scale = _base_scale * Vector2(1.4, 0.6)
					
					var lunge_speed: float = follow_speed * 2.2 * GlobalStats.global_velocity_mult
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
		attack_phase_timer = 0.15 # 150ms charge time

func _on_magnet_entered(area: Area2D) -> void:
	if area.is_in_group("gem") and target_node != null:
		# Swoop to Rattata first
		if not attracted_gems.has(area):
			area.magnetize_to(self)
			attracted_gems.append(area)

func _draw() -> void:
	# Draw a subtle glowing dashed circle representing the magnet range
	var radius = 120.0
	if has_node("MagnetRange/CollisionShape2D"):
		var shape = $MagnetRange/CollisionShape2D.shape
		if shape is CircleShape2D:
			radius = shape.radius
			
	var color = Color(0.2, 0.8, 1.0, 0.25) # Glowing cyan/light blue
	var num_dashes = 32
	var dash_len = (TAU * radius) / (num_dashes * 2)
	var angle = 0.0
	for i in range(num_dashes):
		var start_angle = angle
		var end_angle = angle + (dash_len / radius)
		draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 3, color, 1.5, true)
		angle += (dash_len * 2) / radius
