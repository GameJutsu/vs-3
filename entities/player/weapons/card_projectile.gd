extends Area2D
## Card Projectile Script
## Fired by Rishu's Deck weapon. Red cards pierce. Black cards orbit before firing.

# --- CONFIGURATION ---
@export var speed: float = 600.0
@export var damage: float = 25.0
var direction: Vector2 = Vector2.RIGHT
var is_red: bool = true

# --- ORBIT STATE ---
var orbiting: bool = false
var orbit_center: Node2D = null
var orbit_angle: float = 0.0
@export var orbit_radius: float = 65.0
@export var orbit_speed: float = 6.0
@export var orbit_duration: float = 1.0
var orbit_timer: float = 0.0

# --- DATA TRACKING ---
var lifetime: float = 3.0
var hit_enemies: Array[RID] = [] # Track hit bodies via RID to avoid double hits for piercing Red cards

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Configure visual appearance
	if is_red:
		sprite.modulate = Color(1.0, 0.2, 0.2, 1.0) # Bright Red
	else:
		sprite.modulate = Color(0.12, 0.12, 0.16, 1.0) # Sleek dark grey/black
		# Add a subtle glow/outline to the black card so it's visible in dark mode
		var outline = Sprite2D.new()
		outline.texture = sprite.texture
		outline.scale = Vector2(1.1, 1.1)
		outline.modulate = Color(0.8, 0.8, 1.0, 0.4)
		outline.show_behind_parent = true
		add_child(outline)

	# Set up self-destruct timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_timeout)
	
	# Connect collision signals
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if orbiting and is_instance_valid(orbit_center):
		orbit_timer += delta
		
		# Orbit rotation speed scales with GlobalStats
		var current_orbit_speed: float = orbit_speed * GlobalStats.global_velocity_mult
		orbit_angle += current_orbit_speed * delta
		
		# Calculate orbit position around player
		var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		global_position = orbit_center.global_position + offset
		
		# Rotate card to face tangent of orbit
		rotation = orbit_angle + PI/2
		
		# Check if orbit duration ended
		if orbit_timer >= orbit_duration:
			orbiting = false
			# Launch towards mouse cursor
			var mouse_pos = get_global_mouse_position()
			direction = (mouse_pos - global_position).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.UP
			rotation = direction.angle() + PI/2
	else:
		# Standard flight movement
		global_position += direction * speed * delta * GlobalStats.global_velocity_mult
		rotation = direction.angle() + PI/2

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and is_instance_valid(body):
		var body_rid = body.get_rid()
		if hit_enemies.has(body_rid):
			return # Avoid hitting the same enemy multiple times
			
		hit_enemies.append(body_rid)
		
		if body.has_method("take_damage"):
			body.take_damage(int(damage))
			# Play subtle impact sound
			SoundManager.play_sound("shoot_projectile")
		
		# Spawn small hit spark
		_spawn_hit_spark(body.global_position)
		
		if not is_red and not orbiting:
			# Black cards destroy themselves on first impact when flying
			queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()

func _spawn_hit_spark(pos: Vector2) -> void:
	var spark: CPUParticles2D = CPUParticles2D.new()
	spark.global_position = pos
	spark.amount = 8
	spark.one_shot = true
	spark.explosiveness = 0.9
	spark.lifetime = 0.3
	spark.spread = 180.0
	spark.gravity = Vector2.ZERO
	spark.initial_velocity_min = 80.0
	spark.initial_velocity_max = 160.0
	spark.scale_amount_min = 2.0
	spark.scale_amount_max = 4.0
	spark.color = sprite.modulate
	
	get_parent().call_deferred("add_child", spark)
	spark.emitting = true
	
	get_tree().create_timer(0.4).timeout.connect(spark.queue_free)
