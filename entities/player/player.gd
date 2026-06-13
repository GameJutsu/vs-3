extends CharacterBody2D
## Player Character Control Script
## This script manages the player's movement, health, experience (XP), level-up progression,
## and collision interactions with enemies and collectible items (XP gems).

signal died

# --- MOVEMENT ---
# Changed from 'const' to 'var' so that upgrades can modify it at runtime.
var speed: float = 300.0                  # Movement speed in pixels per second

# --- HEALTH ARCHITECTURE ---
var max_health: int = 100
var current_health: int = 100

# @onready variables wait until the scene tree is fully loaded before trying to locate paths.
# This avoids "Node not found" errors when the script initializes.
# Using relative NodePath (`$"../CanvasLayer/HealthBar"`) looks up the tree for the UI element.
@onready var health_bar: ProgressBar = $"../CanvasLayer/HealthBar"

# --- XP ARCHITECTURE ---
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100            # Total XP required to reach the next level
@onready var xp_bar: ProgressBar = $"../CanvasLayer/XPBar"

# --- UPGRADE SYSTEM ---
@onready var upgrade_menu = $"../CanvasLayer/UpgradeMenu"

# --- CAMERA SHAKE ---
# Reference to the Camera2D which has the camera_shake.gd script attached.
@onready var camera: Camera2D = $Camera2D

# --- KILL COUNTER ---
var kill_count: int = 0
@onready var kill_label: Label = $"../CanvasLayer/KillLabel"

# --- COMPANION ROSTER ---
@onready var creature: Area2D = $"../Creature"
@onready var companion_label: Label = $"../CanvasLayer/CompanionLabel"
var roster: Array[String] = ["brawler"]
var active_creature_index: int = 0

# --- JUICE / SQUASH & STRETCH ---
@onready var sprite: Sprite2D = $Sprite2D
var _was_moving: bool = false
var _base_sprite_scale: Vector2 = Vector2(96, 96)
var deadzone_radius: float = 50.0

# --- SWAP & WEAPON STATE ---
var swap_cooldown_timer: float = 0.0
var swap_cooldown_duration: float = 1.5

# --- INITIALIZATION ---
# _ready() is called once when the node and its children enter the scene tree.
func _ready() -> void:
	# Synchronize our initial stats with the UI Progress Bar values
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
	update_companion_hud()
	
	# Keep track of original sprite scale for squash/stretch lerping
	_base_sprite_scale = sprite.scale

# --- PHYSICS UPDATE LOOP ---
# _physics_process(delta) is called at a fixed frame rate (default 60Hz) for physics calculations.
# This makes physics calculations deterministic and independent of graphics rendering speed.
func _physics_process(delta: float) -> void:
	# Decrement swap cooldown timer
	if swap_cooldown_timer > 0.0:
		swap_cooldown_timer = maxf(swap_cooldown_timer - delta, 0.0)
		
	# --- MOUSE DEADZONE MOVEMENT ---
	var mouse_pos: Vector2 = get_global_mouse_position()
	var offset_to_mouse: Vector2 = mouse_pos - global_position
	var dist_to_mouse: float = offset_to_mouse.length()
	var direction: Vector2 = offset_to_mouse.normalized()
	
	var is_moving: bool = dist_to_mouse > deadzone_radius
	
	if is_moving:
		velocity = direction * speed
		# Face mouse cursor
		sprite.rotation = direction.angle()
		
		# Stretch along direction of motion
		if not _was_moving:
			sprite.scale = _base_sprite_scale * Vector2(1.15, 0.85)
	else:
		velocity = Vector2.ZERO
		# Face mouse cursor even when stopped
		if dist_to_mouse > 5.0:
			sprite.rotation = direction.angle()
			
		# Squash when coming to a halt
		if _was_moving:
			sprite.scale = _base_sprite_scale * Vector2(0.82, 1.18)
			
	_was_moving = is_moving
	
	# Lerp scale back to normal base scale
	sprite.scale = sprite.scale.lerp(_base_sprite_scale, 10.0 * delta)
	
	move_and_slide()

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	# Ignore input if game is paused
	if get_tree().paused:
		return
		
	# LMB Weapon Fire Trigger
	var is_left_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if is_left_click:
		trigger_weapon()
		
	# Cycle companion on RMB Click, Spacebar, or C Key
	var is_right_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
	var is_cycle_key: bool = event is InputEventKey and (event.keycode == KEY_SPACE or event.keycode == KEY_C) and event.pressed
	
	if is_right_click or is_cycle_key:
		cycle_creature()

func cycle_creature() -> void:
	if roster.size() <= 1:
		return
		
	# Check swap cooldown
	if swap_cooldown_timer > 0.0:
		var label: Label = preload("res://ui/damage_number.tscn").instantiate()
		label.text = "SWAP COOLDOWN!"
		label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		label.global_position = global_position + Vector2(-60, -50)
		get_parent().call_deferred("add_child", label)
		return
		
	active_creature_index = (active_creature_index + 1) % roster.size()
	var next_creature_type: String = roster[active_creature_index]
	
	if creature != null and is_instance_valid(creature):
		creature.set_archetype(next_creature_type)
		print("[Player] Swapped active companion to: ", next_creature_type)
	
	# Reset swap cooldown timer
	swap_cooldown_timer = swap_cooldown_duration
	
	# Play companion cycle sound
	SoundManager.play_sound("swap_companion")
	update_companion_hud()

func trigger_weapon() -> void:
	print("[Player] Triggered weapon! (Placeholder for Phase 3)")
	var label: Label = preload("res://ui/damage_number.tscn").instantiate()
	label.text = "PEW!"
	label.modulate = Color(0.0, 0.85, 0.9, 1.0)
	label.global_position = global_position + Vector2(-20, -50)
	get_parent().call_deferred("add_child", label)
	SoundManager.play_sound("shoot_projectile")

# =========================================================
# DAMAGE & DEATH LOGIC
# =========================================================

# Signal callback: Triggered when a PhysicsBody2D enters the Player's hurtbox Area2D.
func _on_hurtbox_body_entered(body: Node2D) -> void:
	# Check if the body belongs to the "enemy" group
	if body.is_in_group("enemy"):
		take_damage(20)                     # Apply damage to the player
		body.die()                          # Instantly destroy the enemy (kamikaze style)

# Function to handle player damage and update UI
func take_damage(amount: int) -> void:
	current_health -= amount
	health_bar.value = current_health
	
	# Play damage sound effect
	SoundManager.play_sound("player_damage")
	
	# Trigger a heavy camera shake — the player just got hit!
	if camera.has_method("add_trauma"):
		camera.add_trauma(0.6)
	
	if current_health <= 0:
		died.emit()

# =========================================================
# LOOT & XP LOGIC
# =========================================================

# Phase 1: The Magnet
# Triggered when an Area2D (e.g. Gem) enters the player's large outer Area2D detection shape.
func _on_magnet_radius_area_entered(area: Area2D) -> void:
	# Ensure the overlapping area is indeed a gem
	if area.is_in_group("gem"):
		# Call the gem's custom function to assign this player as its target.
		# This causes the gem to transition to its "magnetized/chase" phase.
		area.magnetize_to(self)

# Phase 2: The Collection (Mouth)
# Triggered when a flying gem successfully reaches the player's core center hitbox.
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("gem"):
		gain_xp(area.xp_value)
		# Trigger the gem's pop-and-fade collection animation instead of instant deletion
		area.collect()
		SoundManager.play_sound("xp_collect")

# Handles XP gains and progression math
func gain_xp(amount: int) -> void:
	current_xp += amount
	
	# Check if we have met or exceeded the requirements for a level-up
	if current_xp >= xp_to_next_level:
		level_up()
	
	# Update the UI progress bar representation
	xp_bar.value = current_xp

# Progression logic when leveling up
func level_up() -> void:
	current_level += 1
	current_xp -= xp_to_next_level          # Carry over any leftover/excess XP to the next level
	
	# Increase the difficulty/XP required for the next level by 50%
	xp_to_next_level = int(xp_to_next_level * 1.5) 
	
	# Update progress bar limits
	xp_bar.max_value = xp_to_next_level
	
	print("LEVEL UP! Reached level: ", current_level)
	
	# Play level up sound and burst particles
	SoundManager.play_sound("level_up")
	_spawn_level_up_particles()
	
	# Trigger the Tactical Pause — freeze the world and show upgrade cards
	upgrade_menu.open_menu(current_level)

func _spawn_level_up_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = global_position
	particles.amount = 40
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 300.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 12.0
	particles.color = Color(1.0, 0.9, 0.2, 1.0)
	
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.9, 0.2, 1.0), Color(1.0, 0.5, 0.0, 0.0)])
	particles.color_ramp = grad
	
	get_parent().call_deferred("add_child", particles)
	particles.emitting = true
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(particles.queue_free)

# =========================================================
# UPGRADE APPLICATION
# =========================================================

# Signal callback: Connected to the UpgradeMenu's 'upgrade_selected' signal in world.tscn.
# When the player clicks a card, this function receives the chosen UpgradeResource
# and applies its effect using a match statement on the UpgradeType enum.
func _on_upgrade_menu_upgrade_selected(data: UpgradeResource) -> void:
	match data.type:
		UpgradeResource.UpgradeType.PLAYER_SPEED:
			# Permanently increase movement speed
			speed += data.value
			print("Speed increased to: ", speed)
		
		UpgradeResource.UpgradeType.CREATURE_ATTACK_SPEED:
			# Boost the companion creature's attack lunge speed.
			# We grab the creature reference from the World node (our parent).
			var creature = get_parent().get_node("Creature")
			if creature != null:
				creature.attack_speed += data.value
				print("Creature attack speed increased to: ", creature.attack_speed)
		
		UpgradeResource.UpgradeType.HEAL_PLAYER:
			# Restore HP instantly, clamped to max_health so we don't overheal
			current_health = clampi(current_health + int(data.value), 0, max_health)
			health_bar.value = current_health
			print("Healed to: ", current_health)
		
		UpgradeResource.UpgradeType.MAX_HEALTH:
			# Permanently raise the HP ceiling and heal by the same amount
			max_health += int(data.value)
			current_health += int(data.value)
			health_bar.max_value = max_health
			health_bar.value = current_health
			print("Max health increased to: ", max_health)
			
		UpgradeResource.UpgradeType.UNLOCK_CREATURE:
			unlock_creature(data.creature_id)

func unlock_creature(new_id: String) -> void:
	if not roster.has(new_id):
		roster.append(new_id)
		print("[Player] UNLOCKED NEW COMPANION: ", new_id)
		
		# Auto-switch to the newly unlocked creature
		active_creature_index = roster.size() - 1
		if creature != null and is_instance_valid(creature):
			creature.set_archetype(new_id)
			
		# Spawn floating pop message on player's position
		var label: Label = preload("res://ui/damage_number.tscn").instantiate()
		label.text = "UNLOCKED: " + new_id.to_upper() + "!"
		label.global_position = global_position + Vector2(-60, -50)
		get_parent().call_deferred("add_child", label)
	update_companion_hud()

func update_companion_hud() -> void:
	if companion_label != null:
		var roster_strings: Array = []
		for i in range(roster.size()):
			var c = roster[i].to_upper()
			if i == active_creature_index:
				roster_strings.append("[" + c + "]")
			else:
				roster_strings.append(c)
		companion_label.text = "🐾 ROSTER: " + ", ".join(roster_strings)

# =========================================================
# KILL TRACKING
# =========================================================

# Called externally (e.g. by World or signals) when an enemy is confirmed killed.
func register_kill() -> void:
	kill_count += 1
	kill_label.text = str(kill_count)
	
	# Subtle camera shake on each kill for micro-feedback
	if camera.has_method("add_trauma"):
		camera.add_trauma(0.1)
