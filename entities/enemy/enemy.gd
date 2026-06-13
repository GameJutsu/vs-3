extends CharacterBody2D
## Enemy AI Controller Script
## This script governs the basic behavior of an enemy: chasing a target (the player),
## taking damage with visual feedback (hit flash + damage numbers), and dropping
## an experience (XP) gem upon death.

# --- EXPORTED PARAMETERS ---
@export var speed: float = 100.0           # The speed at which the enemy walks toward the target
@export var max_hp: int = 50               # Total hit points before death

# --- PRELOADED RESOURCES ---
# Preload scenes into RAM at compile time to prevent lag spikes during gameplay.
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
	# Each enemy instance gets its own ShaderMaterial so flashes don't bleed between enemies.
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
# Called by the creature or any other damage source.
# Handles HP reduction, hit flash, damage number spawning, and death.
func take_damage(amount: int) -> void:
	current_hp -= amount
	
	# 1. Spawn a floating damage number at this enemy's position
	_spawn_damage_number(amount)
	
	# 2. Trigger the white flash on the sprite
	_flash_white()
	
	# 3. Check for death
	if current_hp <= 0:
		die()

# --- HIT FLASH ---
# Instantly sets the shader's flash_intensity to 1.0 (pure white),
# then tweens it back to 0.0 over 0.1 seconds for a crisp, punchy flash.
func _flash_white() -> void:
	if sprite.material is ShaderMaterial:
		var mat: ShaderMaterial = sprite.material as ShaderMaterial
		mat.set_shader_parameter("flash_intensity", 1.0)
		
		var tween: Tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_intensity", 0.0, 0.1)

# --- DAMAGE NUMBER ---
# Instantiates a floating label showing the damage dealt, positioned at the enemy's location.
func _spawn_damage_number(amount: int) -> void:
	var dmg_num: Label = DAMAGE_NUMBER_SCENE.instantiate()
	dmg_num.text = str(amount)
	dmg_num.global_position = global_position + Vector2(0, -30)  # Slightly above the enemy
	# Add to the World (parent) so the number persists after the enemy dies
	get_parent().call_deferred("add_child", dmg_num)

# --- DEATH & CLEANUP ---
func die() -> void:
	# Notify the player to increment the kill counter
	if target_node != null and target_node.has_method("register_kill"):
		target_node.register_kill()
	
	var gem: Area2D = XP_GEM_SCENE.instantiate()
	gem.global_position = global_position
	get_parent().call_deferred("add_child", gem)
	queue_free()

