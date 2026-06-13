extends CharacterBody2D
## Player Character Control Script
## This script manages the player's movement, health, experience (XP), level-up progression,
## and collision interactions with enemies and collectible items (XP gems).

signal died
signal health_changed(current_health: int, max_health: int)
signal xp_changed(current_xp: int, xp_to_next_level: int)
signal level_up_triggered(new_level: int)
signal kills_changed(new_kill_count: int)
signal active_companion_changed(companion_name: String)
signal stats_updated(projectiles: int, fire_rate: float, aoe: float, velocity: float, speed: float, weapon_name: String)

# --- MOVEMENT ---
# Changed from 'const' to 'var' so that upgrades can modify it at runtime.
@export var speed: float = 300.0                  # Movement speed in pixels per second

# --- HEALTH ARCHITECTURE ---
@export var max_health: int = 100
var current_health: int = 100

# --- XP ARCHITECTURE ---
var current_level: int = 1
var current_xp: int = 0
@export var xp_to_next_level: int = 100            # Total XP required to reach the next level

# --- HUD REFERENCES ---
@onready var hud: HUDController = $"../CanvasLayer"

# --- KILL COUNTER ---
var kill_count: int = 0

# --- COMPANION ROSTER ---
var roster: Array[String] = ["rattata"]
var active_creature_index: int = 0
var roster_manager: RosterManager = null
var companion_upgrades: Dictionary = {}         # Tracks companion-specific upgrade counts (base_id -> count)

func get_companion_upgrade_count(base_id: String) -> int:
	return companion_upgrades.get(base_id, 0)


# --- JUICE / SQUASH & STRETCH ---
@onready var sprite: Sprite2D = $Sprite2D
var _was_moving: bool = false
var _base_sprite_scale: Vector2 = Vector2(96, 96)
@export var deadzone_radius: float = 120.0

# --- SWAP & WEAPON STATE ---
var swap_cooldown_timer: float = 0.0
@export var swap_cooldown_duration: float = 1.5
var active_weapon: Node2D = null
var owned_upgrades: Array[String] = []

# --- DEBUG ---
var auto_fire: bool = false
var debug_mode: bool = false


func _ready() -> void:
	# Connect global EventBus events
	EventBus.enemy_died.connect(_on_enemy_died)
	
	# Keep track of original sprite scale for squash/stretch lerping
	_base_sprite_scale = sprite.scale

	# Initialize RosterManager and deploy starting companion
	roster_manager = RosterManager.new()
	add_child(roster_manager)
	roster_manager.deploy_companion(roster[0], global_position, self)

	# Initialize character active weapon
	var weapon_path: String = ""
	if GlobalStats.selected_character == "rishu":
		weapon_path = "res://entities/player/weapons/deck_weapon.tscn"
	else:
		weapon_path = "res://entities/player/weapons/maglev_cube.tscn"
		
	var weapon_scene = load(weapon_path)
	if weapon_scene != null:
		active_weapon = weapon_scene.instantiate()
		add_child(active_weapon)
		print("[Player] Spawned weapon: ", weapon_path)


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
	_update_stats_hud()

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	# Ignore input if game is paused
	if get_tree().paused:
		return
		
	# Cycle companion on RMB Click, Spacebar, or C Key
	var is_right_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
	var is_cycle_key: bool = event is InputEventKey and (event.keycode == KEY_SPACE or event.keycode == KEY_C) and event.pressed
	
	if is_right_click or is_cycle_key:
		cycle_creature()

	# Debug: Toggle auto-fire
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		auto_fire = !auto_fire
		print("[Debug] Auto-fire: ", auto_fire)

	# Debug: Instant level-up
	if event is InputEventKey and event.keycode == KEY_L and event.pressed and not event.echo:
		gain_xp(xp_to_next_level - current_xp)
		print("[Debug] Instant level-up triggered!")

	# Debug: Toggle auto-upgrade
	if event is InputEventKey and event.keycode == KEY_U and event.pressed and not event.echo:
		debug_mode = !debug_mode
		print("[Debug] Auto-upgrade: ", debug_mode)


func cycle_creature() -> void:
	if roster.size() <= 1:
		return
		
	# Check swap cooldown
	if swap_cooldown_timer > 0.0:
		EventBus.float_text_requested.emit("SWAP COOLDOWN!", global_position + Vector2(-60, -50), Color(1.0, 0.3, 0.3, 1.0))
		return
		
	active_creature_index = (active_creature_index + 1) % roster.size()
	var next_creature_type: String = roster[active_creature_index]
	
	# Find active companion position to swap at the exact same location
	var spawn_pos: Vector2 = global_position
	if roster_manager != null and roster_manager.active_companion_node != null and is_instance_valid(roster_manager.active_companion_node):
		spawn_pos = roster_manager.active_companion_node.global_position
		
	if roster_manager != null:
		roster_manager.deploy_companion(next_creature_type, spawn_pos, self)
		print("[Player] Swapped active companion to: ", next_creature_type)
	
	# Reset swap cooldown timer
	swap_cooldown_timer = swap_cooldown_duration
	
	# Play companion cycle sound
	SoundManager.play_sound("swap_companion")
	update_companion_hud()



# =========================================================
# DAMAGE & DEATH LOGIC
# =========================================================

# Signal callback: Triggered when a PhysicsBody2D enters the Player's hurtbox Area2D.
func _on_hurtbox_body_entered(body: Node2D) -> void:
	# Check if the body belongs to the "enemy" group
	if body.is_in_group("enemy"):
		var dmg: int = 20
		if "contact_damage" in body:
			dmg = body.contact_damage
		take_damage(dmg)                     # Apply damage to the player
		body.die()                          # Instantly destroy the enemy (kamikaze style)

# Function to handle player damage and update UI
func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	
	# Play damage sound effect
	SoundManager.play_sound("player_damage")
	
	# Trigger camera shake via EventBus
	EventBus.camera_shake_requested.emit(0.6)
	
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
		if area.has_method("collect_cherry"):
			area.collect_cherry(self)
		else:
			gain_xp(area.xp_value)
			# Trigger the gem's pop-and-fade collection animation instead of instant deletion
			area.collect()
			SoundManager.play_sound("xp_collect")

# Handles HP healing
func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	print("Healed by ", amount, ", HP is now: ", current_health)

# Handles XP gains and progression math
func gain_xp(amount: int) -> void:
	current_xp += amount
	
	# Check if we have met or exceeded the requirements for a level-up
	if current_xp >= xp_to_next_level:
		level_up()
	
	xp_changed.emit(current_xp, xp_to_next_level)

# Progression logic when leveling up
func level_up() -> void:
	current_level += 1
	current_xp -= xp_to_next_level          # Carry over any leftover/excess XP to the next level
	
	# Increase the difficulty/XP required for the next level by 50%
	xp_to_next_level = int(xp_to_next_level * 1.5) 
	
	print("LEVEL UP! Reached level: ", current_level)
	
	# Play level up sound and burst particles
	SoundManager.play_sound("level_up")
	_spawn_level_up_particles()
	
	level_up_triggered.emit(current_level)
	
	# Trigger the Tactical Pause — freeze the world and show upgrade cards
	if debug_mode:
		# Auto-select a random upgrade instead of showing the menu
		if hud != null and hud.upgrade_menu != null:
			var pool = hud.upgrade_menu.upgrade_pool.duplicate()
			pool.shuffle()
			if pool.size() > 0:
				_on_upgrade_menu_upgrade_selected(pool[0])
				print("[Debug] Auto-selected upgrade: ", pool[0].title)
		return

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
	var upgrade_id = data.resource_path.get_file().get_basename()
	if not owned_upgrades.has(upgrade_id):
		owned_upgrades.append(upgrade_id)
		
	match data.type:
		UpgradeResource.UpgradeType.PLAYER_SPEED:
			# Permanently increase movement speed
			speed += data.value
			print("Speed increased to: ", speed)
		
		UpgradeResource.UpgradeType.CREATURE_ATTACK_SPEED:
			# Boost the active companion's speed/leash tracking factor
			if roster_manager != null and roster_manager.active_companion_node != null and is_instance_valid(roster_manager.active_companion_node):
				var companion = roster_manager.active_companion_node
				companion.follow_speed += data.value
				print("Companion follow speed increased to: ", companion.follow_speed)
		
		UpgradeResource.UpgradeType.HEAL_PLAYER:
			current_health = clampi(current_health + int(data.value), 0, max_health)
			health_changed.emit(current_health, max_health)
			print("Healed to: ", current_health)
		
		UpgradeResource.UpgradeType.MAX_HEALTH:
			max_health += int(data.value)
			current_health += int(data.value)
			health_changed.emit(current_health, max_health)
			print("Max health increased to: ", max_health)
			
		UpgradeResource.UpgradeType.UNLOCK_CREATURE:
			unlock_creature(data.creature_id)
			
		UpgradeResource.UpgradeType.GLOBAL_PROJECTILES:
			GlobalStats.global_projectiles += int(data.value)
			print("Global Projectiles upgraded to: ", GlobalStats.global_projectiles)
			
		UpgradeResource.UpgradeType.GLOBAL_FIRE_RATE:
			GlobalStats.global_fire_rate_mult += data.value
			print("Global Fire Rate upgraded to: ", GlobalStats.global_fire_rate_mult)
			
		UpgradeResource.UpgradeType.GLOBAL_AOE_RADIUS:
			GlobalStats.global_aoe_radius += data.value
			print("Global AoE Radius upgraded to: ", GlobalStats.global_aoe_radius)
			
		UpgradeResource.UpgradeType.GLOBAL_VELOCITY:
			GlobalStats.global_velocity_mult += data.value
			print("Global Velocity upgraded to: ", GlobalStats.global_velocity_mult)
			
		UpgradeResource.UpgradeType.COMPANION_BUFF:
			_apply_companion_upgrade(data.creature_id)

func _apply_companion_upgrade(base_id: String) -> void:
	var count = companion_upgrades.get(base_id, 0) + 1
	companion_upgrades[base_id] = count
	print("Companion ", base_id, " upgraded! Current count: ", count)
	
	# Spawn popup warning/message
	var label: Label = preload("res://ui/damage_number.tscn").instantiate()
	label.text = base_id.to_upper() + " POWER UP!"
	label.modulate = Color(0.18, 0.76, 1.0, 1.0) # Light blue neon
	label.global_position = global_position + Vector2(-60, -50)
	get_parent().call_deferred("add_child", label)
	
	# Evolve on exactly 2 upgrades
	if count == 2:
		var evolved_id = ""
		match base_id:
			"rattata": evolved_id = "raticate"
			"zubat": evolved_id = "golbat"
			"staryu": evolved_id = "starmie"
			"geodude": evolved_id = "graveler"
			"pikachu": evolved_id = "raichu"
			
		if evolved_id != "":
			evolve_companion(base_id, evolved_id)

func evolve_companion(base_id: String, evolved_id: String) -> void:
	var idx = roster.find(base_id)
	if idx != -1:
		roster[idx] = evolved_id
		print("[Player] Evolving ", base_id, " -> ", evolved_id)
		
		var spawn_pos = global_position
		var active_was_evolved = false
		if roster_manager != null and roster_manager.active_companion_node != null and is_instance_valid(roster_manager.active_companion_node):
			if roster_manager.active_companion_node.creature_id == base_id:
				spawn_pos = roster_manager.active_companion_node.global_position
				active_was_evolved = true
				
		if active_was_evolved and roster_manager != null:
			roster_manager.deploy_companion(evolved_id, spawn_pos, self)
			
		# Fanfare and visuals
		SoundManager.play_sound("level_up")
		_trigger_evolution_flash()
		_spawn_evolution_particles(spawn_pos)
		
		# Banner text via EventBus
		EventBus.float_text_requested.emit(
			base_id.to_upper() + " EVOLVED INTO " + evolved_id.to_upper() + "!",
			spawn_pos + Vector2(-120, -70),
			Color(1.0, 0.85, 0.1, 1.0)
		)
		
		update_companion_hud()

func _trigger_evolution_flash() -> void:
	if hud != null:
		var flash = ColorRect.new()
		flash.color = Color(1.0, 1.0, 1.0, 1.0)
		flash.anchors_preset = 15 # Full screen
		hud.add_child(flash)
		
		var tween = create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.5)
		tween.tween_callback(flash.queue_free)

func _spawn_evolution_particles(pos: Vector2) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.global_position = pos
	particles.amount = 50
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 180.0
	particles.initial_velocity_max = 350.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 14.0
	
	particles.color = Color(1.0, 0.88, 0.2, 1.0)
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 0.88, 0.2, 1.0),
		Color(1.0, 0.45, 0.0, 1.0),
		Color(0.2, 0.85, 1.0, 0.0)
	])
	particles.color_ramp = grad
	
	get_parent().call_deferred("add_child", particles)
	particles.emitting = true
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(particles.queue_free)


func unlock_creature(new_id: String) -> void:
	if not roster.has(new_id):
		roster.append(new_id)
		print("[Player] UNLOCKED NEW COMPANION: ", new_id)
		
		# Auto-switch to the newly unlocked creature
		active_creature_index = roster.size() - 1
		
		var spawn_pos: Vector2 = global_position
		if roster_manager != null and roster_manager.active_companion_node != null and is_instance_valid(roster_manager.active_companion_node):
			spawn_pos = roster_manager.active_companion_node.global_position
			
		if roster_manager != null:
			roster_manager.deploy_companion(new_id, spawn_pos, self)
			
		# Spawn floating pop message via EventBus
		EventBus.float_text_requested.emit(
			"UNLOCKED: " + new_id.to_upper() + "!",
			global_position + Vector2(-60, -50),
			Color(0.18, 0.76, 1.0, 1.0)
		)
	update_companion_hud()

func update_companion_hud() -> void:
	var companion_name = roster[active_creature_index] if roster.size() > 0 else "NONE"
	active_companion_changed.emit(companion_name)

# =========================================================
# KILL TRACKING
# =========================================================

# Called externally (e.g. by World or signals) when an enemy is confirmed killed.
func register_kill() -> void:
	kill_count += 1
	kills_changed.emit(kill_count)
	
	# Subtle camera shake on each kill for micro-feedback via EventBus
	EventBus.camera_shake_requested.emit(0.1)

# Connected to global EventBus event
func _on_enemy_died(_enemy: CharacterBody2D, _xp: int) -> void:
	register_kill()

# =========================================================
# LIVE STATS HUD
# =========================================================

func _update_stats_hud() -> void:
	var weapon_name = "Maglev Cube" if GlobalStats.selected_character == "vaibhav" else "Deck"
	stats_updated.emit(
		GlobalStats.global_projectiles,
		GlobalStats.global_fire_rate_mult,
		GlobalStats.global_aoe_radius,
		GlobalStats.global_velocity_mult,
		speed,
		weapon_name
	)

# =========================================================
# DEBUG HELPERS
# =========================================================

func is_firing() -> bool:
	return auto_fire or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
