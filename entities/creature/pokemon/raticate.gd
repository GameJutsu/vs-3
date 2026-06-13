extends CompanionBase
## Raticate (Evolved Rattata)
## Bites apply Bleed (10 damage ticks). Inherent double-sized magnet radius.

# --- STATE MACHINE ---
enum State { FOLLOW, ATTACK }
var state: State = State.FOLLOW
var current_enemy: CharacterBody2D = null
var attack_phase_timer: float = 0.0

var attracted_gems: Array[Area2D] = []
var _lunge_trail: CPUParticles2D = null

func _custom_ready() -> void:
	# 30% larger base scale
	_base_scale = _base_scale * 1.3
	
	$AggroRange.body_entered.connect(_on_aggro_entered)
	$MagnetRange.area_entered.connect(_on_magnet_entered)
	
	# Setup dust trail
	_setup_lunge_trail()

func _custom_process(delta: float) -> void:
	queue_redraw()
	
	# Process attracted gems: check if they are close to Raticate
	var i = attracted_gems.size() - 1
	while i >= 0:
		var gem = attracted_gems[i]
		if is_instance_valid(gem) and gem.target == self:
			if global_position.distance_to(gem.global_position) < 45.0:
				# Magnetize to player now!
				gem.magnetize_to(target_node)
				attracted_gems.remove_at(i)
		else:
			attracted_gems.remove_at(i)
		i -= 1
		
	# Manage trail emitting
	if _lunge_trail != null:
		_lunge_trail.emitting = (state == State.ATTACK and attack_phase_timer <= 0.0)

	# Run FSM
	match state:
		State.FOLLOW:
			pass
			
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
					global_position -= dir * 40.0 * delta
				else:
					# 2. Lunge: stretch out (dash)
					if sprite != null:
						sprite.scale = _base_scale * Vector2(1.4, 0.6)
					
					var lunge_speed: float = follow_speed * 2.4 * GlobalStats.global_velocity_mult
					global_position = global_position.lerp(current_enemy.global_position, lunge_speed * delta)
					
					# Bite attack
					if global_position.distance_to(current_enemy.global_position) < 35.0:
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
		
	# Spawn teeth-crunch overlay at enemy position
	var crunch = CrunchEffect.new()
	crunch.global_position = enemy.global_position
	get_parent().add_child(crunch)
	
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
		# Swoop to Raticate first
		if not attracted_gems.has(area):
			area.magnetize_to(self)
			attracted_gems.append(area)

func _setup_lunge_trail() -> void:
	_lunge_trail = CPUParticles2D.new()
	_lunge_trail.name = "LungeTrail"
	_lunge_trail.amount = 16
	_lunge_trail.lifetime = 0.35
	_lunge_trail.local_coords = false
	_lunge_trail.gravity = Vector2.ZERO
	_lunge_trail.spread = 20.0
	_lunge_trail.initial_velocity_min = 15.0
	_lunge_trail.initial_velocity_max = 45.0
	_lunge_trail.scale_amount_min = 3.0
	_lunge_trail.scale_amount_max = 6.0
	_lunge_trail.color = Color(0.8, 0.8, 0.8, 0.45) # Dust gray
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.8, 0.8, 0.8, 0.45), Color(0.8, 0.8, 0.8, 0.0)])
	_lunge_trail.color_ramp = grad
	
	add_child(_lunge_trail)
	_lunge_trail.emitting = false

func _draw() -> void:
	# Draw a subtle glowing dashed circle representing the magnet range
	var radius = 240.0
	if has_node("MagnetRange/CollisionShape2D"):
		var shape = $MagnetRange/CollisionShape2D.shape
		if shape is CircleShape2D:
			radius = shape.radius
			
	var color = Color(0.2, 0.8, 1.0, 0.25) # Glowing cyan/light blue
	var num_dashes = 48
	var dash_len = (TAU * radius) / (num_dashes * 2)
	var angle = 0.0
	for i in range(num_dashes):
		var start_angle = angle
		var end_angle = angle + (dash_len / radius)
		draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 3, color, 1.5, true)
		angle += (dash_len * 2) / radius

# --- NESTED TEETH-CRUNCH EFFECT CLASS ---
class CrunchEffect:
	extends Node2D
	
	var lifetime: float = 0.25
	var elapsed: float = 0.0
	
	func _ready() -> void:
		queue_redraw()
		
	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= lifetime:
			queue_free()
			
	func _draw() -> void:
		var progress = elapsed / lifetime
		var clamp_offset = maxf(15.0 - progress * 60.0, 0.0)
		var alpha = 1.0 - progress
		var teeth_color = Color(1.0, 1.0, 1.0, alpha)
		
		# Draw top tooth pointing down
		var top_points = PackedVector2Array([
			Vector2(-10, -10 - clamp_offset),
			Vector2(10, -10 - clamp_offset),
			Vector2(0, 5 - clamp_offset)
		])
		draw_colored_polygon(top_points, teeth_color)
		
		# Draw bottom tooth pointing up
		var bottom_points = PackedVector2Array([
			Vector2(-10, 10 + clamp_offset),
			Vector2(10, 10 + clamp_offset),
			Vector2(0, -5 + clamp_offset)
		])
		draw_colored_polygon(bottom_points, teeth_color)
