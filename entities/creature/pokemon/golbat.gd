extends CompanionBase
## Golbat (Evolved Zubat)
## Latches a draining beam that chains from primary targets to secondary nearby targets.

@export var max_range: float = 250.0
@export var chain_range: float = 160.0
@export var heal_fraction: float = 0.08 # 8% lifesteal heal rate

var _primary_tethers: Dictionary = {} # {primary_enemy: Line2D_node}
var _chains: Dictionary = {}           # {primary_enemy: Array[ChainData]}

class ChainData:
	var target: Node2D
	var line: Line2D
	
	func _init(t: Node2D, l: Line2D) -> void:
		target = t
		line = l

func _custom_ready() -> void:
	set_process(true)

func _custom_process(delta: float) -> void:
	# 1. Clean up invalid/out-of-range primary tethers
	for enemy in _primary_tethers.keys():
		if not is_instance_valid(enemy) or enemy.current_hp <= 0 or global_position.distance_to(enemy.global_position) > max_range:
			_remove_tether(enemy)
			
	# 2. Get closest enemies to tether
	var max_tethers: int = GlobalStats.global_projectiles
	var candidates: Array[Node2D] = _find_closest_enemies(max_range, max_tethers)
	
	# 3. Establish new primary tethers
	for enemy in candidates:
		if not _primary_tethers.has(enemy) and _primary_tethers.size() < max_tethers:
			_create_tether(enemy)
			
	# 4. Update chains (re-scan secondary targets for each primary)
	_update_chains()
			
	# 5. Periodically damage enemies and heal player
	if current_cooldown <= 0.0:
		current_cooldown = get_cooldown()
		_execute_drain()
		
	# 6. Update visual Line2D coordinates
	_update_tether_graphics()

func _create_tether(enemy: Node2D) -> void:
	var line: Line2D = Line2D.new()
	line.width = 3.5
	line.default_color = Color(1.0, 0.2, 0.4, 0.8) # Strong magenta/red
	add_child(line)
	_primary_tethers[enemy] = line
	_chains[enemy] = []

func _remove_tether(enemy: Variant) -> void:
	if _primary_tethers.has(enemy):
		var line = _primary_tethers[enemy]
		if is_instance_valid(line):
			line.queue_free()
		_primary_tethers.erase(enemy)
		
		# Clear chains
		if _chains.has(enemy):
			for chain in _chains[enemy]:
				if is_instance_valid(chain.line):
					chain.line.queue_free()
			_chains.erase(enemy)

func _update_chains() -> void:
	for primary in _primary_tethers.keys():
		if not is_instance_valid(primary):
			continue
			
		# Clean old chain nodes
		var old_chains = _chains[primary]
		for chain in old_chains:
			if is_instance_valid(chain.line):
				chain.line.queue_free()
		_chains[primary] = []
		
		# Find chain targets:
		# Chain 1: Close to primary
		var secondary = _find_chain_target(primary, [primary])
		if secondary != null:
			var line1: Line2D = Line2D.new()
			line1.width = 2.5
			line1.default_color = Color(0.9, 0.4, 0.8, 0.7)
			add_child(line1)
			_chains[primary].append(ChainData.new(secondary, line1))
			
			# Chain 2: Close to secondary
			var tertiary = _find_chain_target(secondary, [primary, secondary])
			if tertiary != null:
				var line2: Line2D = Line2D.new()
				line2.width = 1.8
				line2.default_color = Color(0.8, 0.6, 0.9, 0.6)
				add_child(line2)
				_chains[primary].append(ChainData.new(tertiary, line2))

func _find_chain_target(origin: Node2D, exclude: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist: float = chain_range
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy) and not exclude.has(enemy):
			var dist = origin.global_position.distance_to(enemy.global_position)
			if dist <= min_dist:
				min_dist = dist
				closest = enemy
	return closest

func _execute_drain() -> void:
	if _primary_tethers.is_empty():
		return
		
	var dmg: int = get_damage()
	var total_healed: int = 0
	
	for primary in _primary_tethers.keys():
		if is_instance_valid(primary) and primary.current_hp > 0:
			primary.take_damage(dmg)
			total_healed += int(dmg * heal_fraction)
			
			# Damage chained enemies
			if _chains.has(primary):
				for chain in _chains[primary]:
					if is_instance_valid(chain.target) and chain.target.current_hp > 0:
						chain.target.take_damage(int(dmg * 0.75)) # 75% damage on chain links
						total_healed += int(dmg * 0.75 * heal_fraction)
			
	# Heal player
	if total_healed > 0 and target_node != null and target_node.has_method("take_damage"):
		target_node.current_health = clampi(target_node.current_health + total_healed, 0, target_node.max_health)
		target_node.health_bar.value = target_node.current_health
		
		var label: Label = DAMAGE_NUMBER_SCENE.instantiate()
		label.text = "+" + str(total_healed)
		label.modulate = Color(0.2, 0.9, 0.3, 1.0)
		label.global_position = target_node.global_position + Vector2(-10, -50)
		get_parent().call_deferred("add_child", label)
		
		SoundManager.play_sound("healer_pulse")

func _update_tether_graphics() -> void:
	for primary in _primary_tethers.keys():
		var line: Line2D = _primary_tethers[primary]
		if is_instance_valid(line) and is_instance_valid(primary):
			line.points = PackedVector2Array([
				Vector2.ZERO,
				primary.global_position - global_position
			])
			
		# Update chain lines
		if _chains.has(primary):
			var last_node: Node2D = primary
			for chain in _chains[primary]:
				if is_instance_valid(chain.line) and is_instance_valid(chain.target):
					chain.line.points = PackedVector2Array([
						last_node.global_position - global_position,
						chain.target.global_position - global_position
					])
					last_node = chain.target

func _find_closest_enemies(range_limit: float, count: int) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var sorted_enemies: Array = []
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= range_limit:
				sorted_enemies.append({"node": enemy, "dist": dist})
				
	sorted_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
	
	for i in range(mini(count, sorted_enemies.size())):
		result.append(sorted_enemies[i]["node"])
		
	return result

func _exit_tree() -> void:
	for line in _primary_tethers.values():
		if is_instance_valid(line):
			line.queue_free()
	for list in _chains.values():
		for chain in list:
			if is_instance_valid(chain.line):
				chain.line.queue_free()
	_primary_tethers.clear()
	_chains.clear()
