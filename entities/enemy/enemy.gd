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
var _speed_mult: float = 1.0

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
var knockback_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if target_node != null:
		var direction: Vector2 = global_position.direction_to(target_node.global_position)
		velocity = direction * speed * _speed_mult
		
		if knockback_velocity.length() > 5.0:
			velocity += knockback_velocity
			# Decay velocity over time
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		else:
			knockback_velocity = Vector2.ZERO
			
		move_and_slide()

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force


# --- DAMAGE SYSTEM ---
func take_damage(amount: int) -> void:
	current_hp -= amount
	_spawn_damage_number(amount)
	_flash_white()
	SoundManager.play_sound("enemy_hit")
	
	if current_hp <= 0:
		die()

# --- BLEED STATUS EFFECT ---
func apply_bleed(dmg: int, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.set_loops(int(duration))
	tween.tween_callback(func():
		if is_instance_valid(self) and current_hp > 0:
			take_damage(dmg)
	).set_delay(1.0)

# --- SLOW STATUS EFFECT ---
func apply_slow(factor: float, duration: float) -> void:
	_speed_mult = factor
	var tween: Tween = create_tween()
	tween.tween_callback(func():
		if is_instance_valid(self):
			_speed_mult = 1.0
	).set_delay(duration)

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
		
	# Play death sound and spawn particles
	SoundManager.play_sound("enemy_die")
	_spawn_death_particles()
	
	queue_free()

func _spawn_death_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = global_position
	particles.amount = 12
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	var sprite_color: Color = Color.RED
	if sprite != null and sprite.texture is GradientTexture2D:
		var grad = (sprite.texture as GradientTexture2D).gradient
		if grad != null and grad.colors.size() > 0:
			sprite_color = grad.colors[0]
			
	particles.color = sprite_color
	
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([sprite_color, Color(sprite_color.r, sprite_color.g, sprite_color.b, 0.0)])
	particles.color_ramp = grad
	
	get_parent().call_deferred("add_child", particles)
	particles.emitting = true
	
	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(particles.queue_free)
