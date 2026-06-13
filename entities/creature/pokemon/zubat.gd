extends CompanionBase
## Zubat (The Vampire / Tether Pokémon)
## Latches a draining beam onto closest enemies. Heals player for a fraction of damage.
## Number of tethers scales with `GlobalStats.global_projectiles`.

@export var max_range: float = 250.0
@export var heal_fraction: float = 0.05 # 5% lifesteal heal rate

var _active_tethers: Dictionary = {} # {enemy_instance: Line2D_node}

func _custom_ready() -> void:
	# Enable processing
	set_process(true)

func _custom_process(delta: float) -> void:
	# 1. Clean up invalid/out-of-range tethers
	for enemy in _active_tethers.keys():
		if not is_instance_valid(enemy) or enemy.current_hp <= 0 or global_position.distance_to(enemy.global_position) > max_range:
			_remove_tether(enemy)
			
	# 2. Get closest enemies to tether
	var max_tethers: int = GlobalStats.global_projectiles
	var candidates: Array[Node2D] = _find_closest_enemies(max_range, max_tethers)
	
	# 3. Establish new tethers
	for enemy in candidates:
		if not _active_tethers.has(enemy) and _active_tethers.size() < max_tethers:
			_create_tether(enemy)
			
	# 4. Periodically damage enemies and heal player
	if current_cooldown <= 0.0:
		current_cooldown = get_cooldown()
		_execute_drain()
		
	# 5. Update visual Line2D coordinates
	_update_tether_graphics()

func _create_tether(enemy: Node2D) -> void:
	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.1, 0.2, 0.7) # Glowing blood red
	add_child(line)
	_active_tethers[enemy] = line

func _remove_tether(enemy: Variant) -> void:
	if _active_tethers.has(enemy):
		var line = _active_tethers[enemy]
		if is_instance_valid(line):
			line.queue_free()
		_active_tethers.erase(enemy)

func _execute_drain() -> void:
	if _active_tethers.is_empty():
		return
		
	var dmg: int = get_damage()
	var total_healed: int = 0
	
	for enemy in _active_tethers.keys():
		if is_instance_valid(enemy) and enemy.current_hp > 0:
			enemy.take_damage(dmg)
			total_healed += int(dmg * heal_fraction)
			
	# Heal player
	if total_healed > 0 and target_node != null and target_node.has_method("take_damage"):
		target_node.current_health = clampi(target_node.current_health + total_healed, 0, target_node.max_health)
		target_node.health_bar.value = target_node.current_health
		
		# Spawn a green floating indicator "+X"
		var label: Label = DAMAGE_NUMBER_SCENE.instantiate()
		label.text = "+" + str(total_healed)
		label.modulate = Color(0.2, 0.9, 0.3, 1.0)
		label.global_position = target_node.global_position + Vector2(-10, -50)
		get_parent().call_deferred("add_child", label)
		
		SoundManager.play_sound("healer_pulse")

func _update_tether_graphics() -> void:
	for enemy in _active_tethers.keys():
		var line: Line2D = _active_tethers[enemy]
		if is_instance_valid(line) and is_instance_valid(enemy):
			line.points = PackedVector2Array([
				Vector2.ZERO,
				enemy.global_position - global_position
			])

func _find_closest_enemies(range_limit: float, count: int) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var sorted_enemies: Array = []
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= range_limit:
				sorted_enemies.append({"node": enemy, "dist": dist})
				
	# Sort by distance (closest first)
	sorted_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
	
	for i in range(mini(count, sorted_enemies.size())):
		result.append(sorted_enemies[i]["node"])
		
	return result

func _exit_tree() -> void:
	# Clear lines on remove
	for line in _active_tethers.values():
		if is_instance_valid(line):
			line.queue_free()
	_active_tethers.clear()
