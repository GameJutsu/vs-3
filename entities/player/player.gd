extends CharacterBody2D
## Player Character Control Script
## This script manages the player's movement, health, experience (XP), level-up progression,
## and collision interactions with enemies and collectible items (XP gems).

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

# --- INITIALIZATION ---
# _ready() is called once when the node and its children enter the scene tree.
func _ready() -> void:
	# Synchronize our initial stats with the UI Progress Bar values
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp

# --- PHYSICS UPDATE LOOP ---
# _physics_process(delta) is called at a fixed frame rate (default 60Hz) for physics calculations.
# This makes physics calculations deterministic and independent of graphics rendering speed.
func _physics_process(_delta: float) -> void:
	# Input.get_vector() listens for keypresses corresponding to the 4 directions.
	# It automatically returns a normalized direction vector (length <= 1.0).
	# This prevents the diagonal movement cheat where moving diagonally is faster (1.414x) than straight movement.
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 'velocity' is a built-in property of CharacterBody2D.
	velocity = direction * speed
	
	# move_and_slide() is a built-in method that moves the body along the velocity vector,
	# automatically resolving collisions (sliding along walls rather than stopping), 
	# and applying delta internally.
	move_and_slide()

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
	
	# Trigger a heavy camera shake — the player just got hit!
	if camera.has_method("add_trauma"):
		camera.add_trauma(0.6)
	
	if current_health <= 0:
		get_tree().reload_current_scene()

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
	
	# Trigger the Tactical Pause — freeze the world and show upgrade cards
	upgrade_menu.open_menu(current_level)

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
