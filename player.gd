extends CharacterBody2D

const SPEED = 300.0

# --- HEALTH ARCHITECTURE ---
var max_health: int = 100
var current_health: int = 100
@onready var health_bar = $"../CanvasLayer/HealthBar"

# --- XP ARCHITECTURE ---
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100 # How much we need to level up
@onready var xp_bar = $"../CanvasLayer/XPBar"

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

# ---------------------------------------------------------
# DAMAGE & DEATH LOGIC
# ---------------------------------------------------------
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		take_damage(20)
		body.die() 

func take_damage(amount: int) -> void:
	current_health -= amount
	health_bar.value = current_health
	if current_health <= 0:
		get_tree().reload_current_scene()

# ---------------------------------------------------------
# LOOT & XP LOGIC
# ---------------------------------------------------------
# 1. The Magnet: Triggered when a gem touches the massive outer circle
func _on_magnet_radius_area_entered(area: Area2D) -> void:
	if area.is_in_group("gem"):
		# Tell the gem to start flying towards this player node
		area.magnetize_to(self)

# 2. The Mouth: Triggered when a flying gem finally hits the player's core hurtbox
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("gem"):
		# Extract the XP, then delete the gem from the world
		gain_xp(area.xp_value)
		area.queue_free()

func gain_xp(amount: int) -> void:
	current_xp += amount
	
	# Check if we crossed the threshold for a level up
	if current_xp >= xp_to_next_level:
		level_up()
	
	# Update the UI
	xp_bar.value = current_xp

func level_up() -> void:
	current_level += 1
	current_xp -= xp_to_next_level # Carry over leftover XP
	
	# Increase the requirement for the next level (scaling difficulty)
	xp_to_next_level = int(xp_to_next_level * 1.5) 
	xp_bar.max_value = xp_to_next_level
	
	print("LEVEL UP! Reached level: ", current_level)
	# TODO: Pause game and show upgrade screen
