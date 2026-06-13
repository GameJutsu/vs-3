extends Area2D
class_name CompanionBase
## Companion Base Class
## Standard leashing, processing cooldowns, and global stats scaling for all companions.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://ui/damage_number.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://entities/creature/projectile.tscn")



# --- EXPORTED PARAMETERS ---
@export var follow_speed: float = 5.0
@export var follow_distance: float = 100.0
@export var base_damage: int = 20
@export var base_cooldown: float = 1.0
@export var min_separation: float = 45.0      # Minimum distance from player to prevent overlap

# --- PLAYER REF ---
var target_node: CharacterBody2D = null
var current_cooldown: float = 0.0

# --- ANIMATION STATE ---
var _time_passed: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Add to companions group
	add_to_group("companions")
	_last_position = global_position
	
	# Try to load sprite texture dynamically based on creature_id
	if creature_id != "":
		var sprite_path = "res://assets/sprites/" + creature_id + ".png"
		if sprite != null and ResourceLoader.exists(sprite_path):
			var tex = load(sprite_path)
			if tex != null:
				sprite.texture = tex
				# Scale the sprite so it fits a standard 64x64 boundary box!
				var target_size: float = 64.0
				var tex_size: Vector2 = tex.get_size()
				var max_dim: float = maxf(tex_size.x, tex_size.y)
				if max_dim > 0.0:
					sprite.scale = Vector2(target_size / max_dim, target_size / max_dim)
				_base_scale = sprite.scale
	
	_custom_ready()

func _custom_ready() -> void:
	pass

func _process(delta: float) -> void:
	# Decrement cooldown
	if current_cooldown > 0.0:
		current_cooldown = maxf(current_cooldown - delta, 0.0)
		
	# Follow player leash in world space
	if target_node != null and is_instance_valid(target_node):
		_follow_player(delta)
		
	# Calculate velocity for squash/stretch
	var travel = global_position - _last_position
	_last_position = global_position
	var speed = travel.length() / delta if delta > 0.0 else 0.0
	
	# Procedural animations
	_animate_sprite(delta, speed, travel)
		
	_custom_process(delta)

func _animate_sprite(delta: float, speed: float, travel: Vector2) -> void:
	if sprite == null:
		return
		
	_time_passed += delta
	
	# Flip sprite based on movement direction
	if travel.x > 0.5:
		sprite.flip_h = false
	elif travel.x < -0.5:
		sprite.flip_h = true
		
	if speed > 10.0:
		# Walking animation: fast squash and stretch + translation bounce
		var bob_frequency = 14.0
		var bob_amplitude = 6.0
		var squash_amplitude = 0.12
		
		# Sine wave for bounce and squash
		var cycle = sin(_time_passed * bob_frequency)
		
		sprite.position.y = -abs(cycle) * bob_amplitude
		sprite.scale.x = _base_scale.x * (1.0 + cycle * squash_amplitude)
		sprite.scale.y = _base_scale.y * (1.0 - cycle * squash_amplitude)
		
		# Tilt slightly in movement direction
		var target_rotation = travel.angle()
		if sprite.flip_h:
			target_rotation = target_rotation - PI
		sprite.rotation = lerp_angle(sprite.rotation, clampf(target_rotation, -0.4, 0.4), 10.0 * delta)
	else:
		# Idle animation: gentle float/bounce
		var idle_frequency = 4.0
		var idle_amplitude = 3.0
		var cycle = sin(_time_passed * idle_frequency)
		
		sprite.position.y = cycle * idle_amplitude
		sprite.scale = sprite.scale.lerp(_base_scale, 10.0 * delta)
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 10.0 * delta)

func _follow_player(delta: float) -> void:
	var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
	var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
	
	# Lerp towards player target leash point
	var speed_multiplier: float = GlobalStats.global_velocity_mult
	global_position = global_position.lerp(target_position, follow_speed * speed_multiplier * delta)
	
	# Anti-overlap: enforce minimum separation from player
	var dist_to_player: float = global_position.distance_to(target_node.global_position)
	if dist_to_player < min_separation:
		var push_dir: Vector2 = target_node.global_position.direction_to(global_position)
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.RIGHT  # Fallback if exactly overlapping
		global_position = target_node.global_position + push_dir * min_separation

func _custom_process(_delta: float) -> void:
	pass

# Swapped-in entrance callback (to trigger swap nukes)
func on_swap_in() -> void:
	_custom_swap_in()

func _custom_swap_in() -> void:
	pass

# --- UPGRADE & SCALING SYSTEM ---
var creature_id: String = ""

## Queries the player to find how many upgrades this companion type has received.
## Maps evolved forms back to their base forms so upgrades persist across evolution.
func get_upgrade_count() -> int:
	if target_node != null and target_node.has_method("get_companion_upgrade_count"):
		var base_id: String = creature_id
		match creature_id:
			"raticate": base_id = "rattata"
			"golbat": base_id = "zubat"
			"starmie": base_id = "staryu"
			"graveler": base_id = "geodude"
			"raichu": base_id = "pikachu"
		return target_node.get_companion_upgrade_count(base_id)
	return 0

# Helper to calculate damage scaling with upgrades and global stats
func get_damage() -> int:
	var bonus_mult = 1.0 + (0.4 * get_upgrade_count())
	return int(base_damage * bonus_mult)

func get_cooldown() -> float:
	var bonus_mult = 1.0 + (0.35 * get_upgrade_count())
	return base_cooldown / (GlobalStats.global_fire_rate_mult * bonus_mult)

