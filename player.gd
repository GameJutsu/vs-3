extends CharacterBody2D

const SPEED = 300.0
var max_health: int = 100
var current_health: int = 100

# We use @onready to grab the health bar from the UI the moment the game starts
@onready var health_bar = $"../CanvasLayer/HealthBar"

func _ready():
	# Make sure the UI matches our starting health
	health_bar.max_value = max_health
	health_bar.value = current_health

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

# This is the signal function you just connected
func _on_hurtbox_body_entered(body):
	# Did an enemy touch us?
	if body.is_in_group("enemy"):
		take_damage(20) # Take 20 damage
		body.queue_free() # The enemy explodes/dies upon hitting us

func take_damage(amount: int):
	current_health -= amount
	health_bar.value = current_health
	
	# Check for Game Over
	if current_health <= 0:
		die()

func die():
	# For now, dying just instantly restarts the exact scene
	get_tree().reload_current_scene()
