extends Area2D
## Creature Companion Behavior Script
## Controls an autonomous companion that cycles between different archetypes:
## - BRAWLER: Charges at nearby enemies and bites them (melee contact).
## - SNIPER: Fires fast projectiles from a distance.
## - ORBITER: Constantly orbits the player, slicing enemies.
## - HEALER: Does not attack; periodically heals the player.
## Swapping between archetypes triggers unique "entrance effects" (tactical nukes).

# --- ARCHETYPE DEFINITION ---
enum Archetype {
	BRAWLER,
	SNIPER,
	ORBITER,
	HEALER
}
@export var archetype: Archetype = Archetype.BRAWLER

# --- EXPORTED PARAMETERS ---
@export var follow_speed: float = 5.0       # Speed factor for trailing the player
@export var attack_speed: float = 8.0       # Speed factor when lunging (Brawler)
@export var follow_distance: float = 60.0   # Target leash distance
@export var damage: int = 25                # Melee/orbit hit damage
@export var attack_cooldown: float = 0.4    # Base cooldown between attacks

# --- TARGET REFERENCES ---
var target_node: Node2D = null              # The player character
var current_enemy: Node2D = null            # Active target for Brawler/Sniper

# --- PRELOADS ---
const PROJECTILE_SCENE: PackedScene = preload("res://entities/creature/projectile.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://ui/damage_number.tscn")

# --- STATE MACHINE (Brawler archetype only) ---
enum State { 
	FOLLOW,
	ATTACK
}
var state: State = State.FOLLOW

# --- TIMERS & INTERNAL STATE ---
var _time_since_last_attack: float = 0.0
var _orbiter_angle: float = 0.0
var _orbiter_enemy_cooldowns: Dictionary = {} # {enemy_instance: time_since_hit}
var _orbiter_boost_time: float = 0.0          # Active swap-in speed boost duration

# --- CHILD REFERENCES ---
@onready var sprite: Sprite2D = $Sprite2D

# --- INITIALIZATION ---
func _ready() -> void:
	# Force initial setup of archetype visuals and collision
	set_archetype("brawler")

# --- PUBLIC INTERFACE ---
# Sets the new archetype, updates color style, configures detection range, and triggers entrance effects.
func set_archetype(type_name: String) -> void:
	match type_name.to_lower():
		"brawler":
			archetype = Archetype.BRAWLER
		"sniper":
			archetype = Archetype.SNIPER
		"orbiter":
			archetype = Archetype.ORBITER
		"healer":
			archetype = Archetype.HEALER
	
	# Reset state variables
	state = State.FOLLOW
	current_enemy = null
	_time_since_last_attack = 0.0
	_orbiter_enemy_cooldowns.clear()
	
	# Configure components dynamically
	_update_archetype_visuals_and_range()
	
	# Fire the tactical entrance effect!
	_trigger_swap_effect()

# --- FRAME-BY-FRAME UPDATE ---
func _process(delta: float) -> void:
	_time_since_last_attack += delta
	
	# Increment internal cooldown timers for orbiter targets
	for key in _orbiter_enemy_cooldowns.keys():
		if is_instance_valid(key):
			_orbiter_enemy_cooldowns[key] += delta
		else:
			_orbiter_enemy_cooldowns.erase(key)
			
	# Update temporary orbiter boost timer
	if _orbiter_boost_time > 0.0:
		_orbiter_boost_time -= delta

	match archetype:
		Archetype.BRAWLER:
			_process_brawler(delta)
		Archetype.SNIPER:
			_process_sniper(delta)
		Archetype.ORBITER:
			_process_orbiter(delta)
		Archetype.HEALER:
			_process_healer(delta)

# --- ARCHETYPE PROCESSORS ---

func _process_brawler(delta: float) -> void:
	match state:
		State.FOLLOW:
			if target_node != null:
				var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
				var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
				global_position = global_position.lerp(target_position, follow_speed * delta)

		State.ATTACK:
			if current_enemy != null and is_instance_valid(current_enemy):
				global_position = global_position.lerp(current_enemy.global_position, attack_speed * delta)
				
				# Bite attack
				if global_position.distance_to(current_enemy.global_position) < 30.0:
					if _time_since_last_attack >= attack_cooldown:
						_time_since_last_attack = 0.0
						current_enemy.take_damage(damage)
						SoundManager.play_sound("brawler_impact")
						
						if not is_instance_valid(current_enemy) or current_enemy.current_hp <= 0:
							current_enemy = null
							state = State.FOLLOW
			else:
				current_enemy = null
				state = State.FOLLOW

func _process_sniper(delta: float) -> void:
	# Keep following player leash
	if target_node != null:
		var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
		var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
		global_position = global_position.lerp(target_position, follow_speed * delta)
		
	# Periodic weapon firing
	if _time_since_last_attack >= attack_cooldown:
		_time_since_last_attack = 0.0
		var enemy: Node2D = _find_closest_enemy(350.0)
		if enemy != null:
			_fire_projectile(enemy)

func _process_orbiter(delta: float) -> void:
	if target_node == null:
		return
		
	# Calculate dynamic radius and speed (applies double on swap boost)
	var active_radius: float = follow_distance
	var active_speed: float = follow_speed
	if _orbiter_boost_time > 0.0:
		active_radius *= 1.5
		active_speed *= 2.0
		
	# Constantly orbit player
	_orbiter_angle += active_speed * delta
	var offset: Vector2 = Vector2(cos(_orbiter_angle), sin(_orbiter_angle)) * active_radius
	global_position = target_node.global_position + offset
	
	# Sweep overlap logic
	var overlapping_bodies: Array[Node2D] = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("enemy") and is_instance_valid(body):
			var last_hit: float = _orbiter_enemy_cooldowns.get(body, attack_cooldown)
			if last_hit >= attack_cooldown:
				_orbiter_enemy_cooldowns[body] = 0.0
				var hit_damage: int = int(damage * 1.5) if _orbiter_boost_time > 0.0 else damage
				body.take_damage(hit_damage)

func _process_healer(delta: float) -> void:
	# Keep close to player
	if target_node != null:
		var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
		var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
		global_position = global_position.lerp(target_position, follow_speed * delta)
		
	# Periodic healing pulses
	if _time_since_last_attack >= attack_cooldown:
		_time_since_last_attack = 0.0
		if target_node != null and target_node.has_method("take_damage"):
			target_node.current_health = clampi(target_node.current_health + 5, 0, target_node.max_health)
			target_node.health_bar.value = target_node.current_health
			SoundManager.play_sound("healer_pulse")
			
			# Floating +5 label
			var label: Label = DAMAGE_NUMBER_SCENE.instantiate()
			label.text = "+5 HP"
			label.modulate = Color(0.2, 0.9, 0.4, 1.0)
			label.global_position = target_node.global_position + Vector2(-20, -50)
			get_parent().call_deferred("add_child", label)

# --- COMBAT UTILITIES ---

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

func _fire_projectile(enemy: Node2D) -> void:
	var bullet: Area2D = PROJECTILE_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = global_position.direction_to(enemy.global_position)
	bullet.damage = damage
	get_parent().call_deferred("add_child", bullet)
	SoundManager.play_sound("shoot_projectile")

# --- SIGNALS: AGGRO DETECTION (Brawler mode only) ---
func _on_body_entered(body: Node2D) -> void:
	if archetype == Archetype.BRAWLER and state == State.FOLLOW:
		if body.is_in_group("enemy") and is_instance_valid(body):
			current_enemy = body
			state = State.ATTACK
			_time_since_last_attack = attack_cooldown

# --- DYNAMIC STYLING & COLLISION CONFIGURATION ---
func _update_archetype_visuals_and_range() -> void:
	if sprite == null:
		return
		
	var grad: Gradient = Gradient.new()
	var new_shape: CircleShape2D = CircleShape2D.new()
	
	match archetype:
		Archetype.BRAWLER:
			grad.colors = PackedColorArray([
				Color(0.0, 0.58, 0.82, 1.0), # Cyan/Blue
				Color(0.0, 0.85, 0.74, 1.0)
			])
			follow_speed = 5.0
			follow_distance = 60.0
			damage = 25
			attack_cooldown = 0.4
			new_shape.radius = 150.0 # Brawler Aggro Range
			
		Archetype.SNIPER:
			grad.colors = PackedColorArray([
				Color(1.0, 0.4, 0.0, 1.0), # Orange/Yellow
				Color(1.0, 0.8, 0.0, 1.0)
			])
			follow_speed = 6.0
			follow_distance = 80.0
			damage = 35 # Snipers deal heavier damage
			attack_cooldown = 1.2 # Sniper shoots every 1.2s
			new_shape.radius = 350.0 # Range detection
			
		Archetype.ORBITER:
			grad.colors = PackedColorArray([
				Color(0.5, 0.0, 0.8, 1.0), # Purple/Magenta
				Color(0.9, 0.2, 0.7, 1.0)
			])
			follow_speed = 4.0 # Orbital angular speed
			follow_distance = 75.0 # Orbital radius
			damage = 15 # Multiple hits, lower damage
			attack_cooldown = 0.5 # Hit interval
			new_shape.radius = 35.0 # Collision size of the spinner itself
			
		Archetype.HEALER:
			grad.colors = PackedColorArray([
				Color(0.0, 0.7, 0.2, 1.0), # Emerald/Green
				Color(0.2, 0.9, 0.5, 1.0)
			])
			follow_speed = 4.0
			follow_distance = 50.0
			attack_cooldown = 8.0 # Heals every 8 seconds
			new_shape.radius = 10.0 # No aggro detection needed
			
	# Update color gradient texture
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 64
	tex.height = 64
	sprite.texture = tex
	
	# Apply collision size change
	var col_shape: CollisionShape2D = $CollisionShape2D
	if col_shape != null:
		col_shape.shape = new_shape

# --- SWAP ENTRANCE EFFECTS (TACTICAL NUKES) ---
func _trigger_swap_effect() -> void:
	if target_node == null:
		return
		
	# Floating notification pop above player
	var notification: Label = DAMAGE_NUMBER_SCENE.instantiate()
	notification.modulate = Color(1.0, 0.85, 0.0, 1.0) # Golden yellow
	notification.global_position = target_node.global_position + Vector2(-40, -60)
	
	match archetype:
		Archetype.BRAWLER:
			notification.text = "BRAWLER AOE IMPACT!"
			get_parent().call_deferred("add_child", notification)
			SoundManager.play_sound("brawler_impact")
			
			# AoE Stun Wave: Damage all enemies in 200px and push them back
			var shockwave_radius: float = 200.0
			var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
			var hit_any: bool = false
			
			for enemy in enemies:
				if enemy is CharacterBody2D and is_instance_valid(enemy):
					var dist: float = target_node.global_position.distance_to(enemy.global_position)
					if dist <= shockwave_radius:
						enemy.take_damage(10)
						var push_dir: Vector2 = target_node.global_position.direction_to(enemy.global_position)
						enemy.global_position += push_dir * 50.0 # pushback
						hit_any = true
						
			if hit_any and target_node.get_node("Camera2D").has_method("add_trauma"):
				target_node.get_node("Camera2D").add_trauma(0.4)
				
		Archetype.SNIPER:
			notification.text = "SNIPER BULLET NOVA!"
			get_parent().call_deferred("add_child", notification)
			SoundManager.play_sound("shoot_projectile")
			
			# Sniper Nova: Fires 8 bullets in a radial circle
			var num_bullets: int = 8
			for i in range(num_bullets):
				var angle: float = i * (TAU / num_bullets)
				var bullet: Area2D = PROJECTILE_SCENE.instantiate()
				bullet.global_position = global_position
				bullet.direction = Vector2(cos(angle), sin(angle))
				bullet.speed = 450.0
				bullet.damage = 20
				get_parent().call_deferred("add_child", bullet)
				
		Archetype.ORBITER:
			notification.text = "ORBIT SHIELD SPEED BOOST!"
			get_parent().call_deferred("add_child", notification)
			SoundManager.play_sound("swap_companion")
			
			# Orbiter Speed Boost: Doubles rotation speed and boosts radius for 2 seconds
			_orbiter_boost_time = 2.0
			
		Archetype.HEALER:
			notification.text = "HEALER 15 HP BURST!"
			get_parent().call_deferred("add_child", notification)
			SoundManager.play_sound("healer_pulse")
			
			# Healer Burst: Heals player for 15 HP instantly
			if target_node.has_method("take_damage"):
				target_node.current_health = clampi(target_node.current_health + 15, 0, target_node.max_health)
				target_node.health_bar.value = target_node.current_health
				
				# Spawn floating burst popup
				var burst_pop: Label = DAMAGE_NUMBER_SCENE.instantiate()
				burst_pop.text = "+15 HP Burst!"
				burst_pop.modulate = Color(0.1, 1.0, 0.4, 1.0)
				burst_pop.global_position = target_node.global_position + Vector2(-30, -30)
				get_parent().call_deferred("add_child", burst_pop)
