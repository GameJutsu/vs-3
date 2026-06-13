extends CharacterBody2D
## Enemy AI Controller Script
## Governs all enemy types: chasing the player, taking damage with visual feedback
## (hit flash + damage numbers), dropping XP gems, and optional split-on-death behavior.
## Different enemy variants (Grunt, Sprinter, Tank, Splitter) share this same script
## but use different @export values configured in their respective .tscn files.

# --- EXPORTED PARAMETERS ---
@export var speed: float = 100.0              # Movement speed toward the player
@export var max_hp: int = 50                  # Total hit points before death
@export var xp_value: int = 10                # XP gem value dropped on death

# --- SPLIT-ON-DEATH (Splitter enemy type) ---
# When enabled, the enemy spawns smaller copies of itself upon death instead of
# (or in addition to) dropping an XP gem. The Splitter archetype uses this.
@export var splits_on_death: bool = false
@export var split_scene: PackedScene = null   # The scene to spawn when splitting
@export var split_count: int = 2              # How many copies to spawn
@export var drops_gem: bool = true            # Set false for splitters (only splitlings drop gems)

# --- PRELOADED RESOURCES ---
const XP_GEM_SCENE: PackedScene = preload("res://items/xp_gem/xp_gem.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://ui/damage_number.tscn")
const HIT_FLASH_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")

# --- INTERNAL STATE ---
var target_node: Node2D = null
var current_hp: int = 0

# --- CHILD REFERENCES ---
@onready var sprite: Sprite2D = $Sprite2D

# --- INITIALIZATION ---
func _ready() -> void:
	current_hp = max_hp
	
	# Apply the hit flash shader to the sprite's material.
	# Each instance gets its own ShaderMaterial so flashes don't bleed between enemies.
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = HIT_FLASH_SHADER
	sprite.material = mat

# --- PHYSICS UPDATE LOOP ---
func _physics_process(_delta: float) -> void:
	if target_node != null:
		var direction: Vector2 = global_position.direction_to(target_node.global_position)
		velocity = direction * speed
		move_and_slide()

# --- DAMAGE SYSTEM ---
func take_damage(amount: int) -> void:
	current_hp -= amount
	_spawn_damage_number(amount)
	_flash_white()
	
	if current_hp <= 0:
		die()

# --- HIT FLASH ---
func _flash_white() -> void:
	if sprite.material is ShaderMaterial:
		var mat: ShaderMaterial = sprite.material as ShaderMaterial
		mat.set_shader_parameter("flash_intensity", 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_intensity", 0.0, 0.1)

# --- DAMAGE NUMBER ---
func _spawn_damage_number(amount: int) -> void:
	var dmg_num: Label = DAMAGE_NUMBER_SCENE.instantiate()
	dmg_num.text = str(amount)
	dmg_num.global_position = global_position + Vector2(0, -30)
	get_parent().call_deferred("add_child", dmg_num)

# --- DEATH & CLEANUP ---
func die() -> void:
	# 1. Notify the player's kill counter
	if target_node != null and target_node.has_method("register_kill"):
		target_node.register_kill()
	
	# 2. Split into smaller enemies if configured (Splitter archetype)
	if splits_on_death and split_scene != null:
		for i: int in range(split_count):
			var child_enemy: CharacterBody2D = split_scene.instantiate()
			# Offset each splitling slightly so they don't stack perfectly
			var offset: Vector2 = Vector2(randf_range(-30, 30), randf_range(-30, 30))
			child_enemy.global_position = global_position + offset
			child_enemy.target_node = target_node
			get_parent().call_deferred("add_child", child_enemy)
	
	# 3. Drop an XP gem (unless this is a splitter that only spawns children)
	if drops_gem:
		var gem: Area2D = XP_GEM_SCENE.instantiate()
		gem.global_position = global_position
		gem.xp_value = xp_value
		get_parent().call_deferred("add_child", gem)
	
	queue_free()
