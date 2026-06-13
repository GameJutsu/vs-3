extends Area2D
class_name CompanionBase
## Companion Base Class
## Standard leashing, processing cooldowns, and global stats scaling for all companions.

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://ui/damage_number.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://entities/creature/projectile.tscn")



# --- EXPORTED PARAMETERS ---
@export var follow_speed: float = 5.0
@export var follow_distance: float = 60.0
@export var base_damage: int = 20
@export var base_cooldown: float = 1.0

# --- PLAYER REF ---
var target_node: CharacterBody2D = null
var current_cooldown: float = 0.0

func _ready() -> void:
	# Add to companions group
	add_to_group("companions")
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
		
	_custom_process(delta)

func _follow_player(delta: float) -> void:
	var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
	var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
	
	# Lerp towards player target leash point
	var speed_multiplier: float = GlobalStats.global_velocity_mult
	global_position = global_position.lerp(target_position, follow_speed * speed_multiplier * delta)

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

