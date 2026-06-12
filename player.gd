extends CharacterBody2D

const SPEED = 300.0

func _physics_process(delta):
	# This grabs input from WASD or Arrow Keys and returns a normalized vector (so diagonal movement isn't faster)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Apply the velocity
	velocity = direction * SPEED
	
	# move_and_slide() is a built-in Godot function that handles delta time and collisions automatically
	move_and_slide()
