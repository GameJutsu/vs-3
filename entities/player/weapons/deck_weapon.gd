extends Node2D
## Deck Weapon Script
## Attached to Player. Fires spreads of cards: Red (piercing) or Black (orbital shield).

@export var fire_rate: float = 0.28            # Base time between shots in seconds
var cooldown_timer: float = 0.0
var shot_counter: int = 0                      # Alternates shots: Even = Red, Odd = Black

var card_scene: PackedScene = preload("res://entities/player/weapons/card_projectile.tscn")

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	# Check if the player is holding LMB
	if _is_player_firing() and not get_tree().paused:
		if cooldown_timer <= 0.0:
			_fire_shot()

func _fire_shot() -> void:
	# Reset cooldown using global fire rate multiplier
	cooldown_timer = fire_rate / GlobalStats.global_fire_rate_mult
	
	# Determine shot properties
	var is_red_shot: bool = (shot_counter % 2 == 0)
	shot_counter += 1
	
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	var base_angle = to_mouse.angle() if to_mouse.length() > 5.0 else rotation
	
	# Determine projectile count from global stats
	var proj_count: int = GlobalStats.global_projectiles
	var spread_angle_deg: float = 12.0
	
	# Play card whoosh sound
	SoundManager.play_sound("shoot_projectile")
	
	# Spawn card spread
	for i in range(proj_count):
		# Calculate angle for each projectile in the spread
		var offset_angle: float = 0.0
		if proj_count > 1:
			var total_arc = spread_angle_deg * (proj_count - 1)
			offset_angle = deg_to_rad(-total_arc / 2.0 + (i * spread_angle_deg))
			
		var final_angle = base_angle + offset_angle
		var dir = Vector2(cos(final_angle), sin(final_angle))
		
		var card = card_scene.instantiate()
		card.is_red = is_red_shot
		card.direction = dir
		
		if not is_red_shot:
			# Black cards start in orbiting mode around player
			card.orbiting = true
			card.orbit_center = get_parent() # Player is the parent node
			card.orbit_angle = final_angle
			# Distribute initial angles evenly if multiple black cards
			if proj_count > 1:
				card.orbit_angle += (float(i) / proj_count) * TAU
		
		# Spawn card slightly in front of the player
		card.global_position = global_position + dir * 20.0
		
		# Add card to the World scene tree (sibling of Player)
		get_parent().get_parent().add_child(card)

func _is_player_firing() -> bool:
	var p = get_parent()
	if p != null and p.has_method("is_firing"):
		return p.is_firing()
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
