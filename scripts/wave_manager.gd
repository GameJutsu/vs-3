extends Node
## Wave Manager — Time-Based Enemy Escalation Director
## Replaces the simple SpawnTimer with an intelligent system that escalates the
## difficulty over time by introducing new enemy types and increasing spawn rates.
## Also handles boss spawning at the climax of the run.

# --- WAVE DATA STRUCTURE ---
# Each wave defines: when it starts, which enemy types to spawn, and how often.
# Waves stack — once a wave activates, its enemies join the existing spawn pool.
class WaveEntry:
	var time_start: float           # Seconds into the run when this wave activates
	var scene: PackedScene          # The enemy scene to spawn
	var weight: float               # Relative probability in the spawn pool (higher = more common)
	
	func _init(t: float, s: PackedScene, w: float = 1.0) -> void:
		time_start = t
		scene = s
		weight = w

# --- PRELOADED ENEMY SCENES ---
const GRUNT_SCENE: PackedScene = preload("res://entities/enemy/enemy.tscn")
const SPRINTER_SCENE: PackedScene = preload("res://entities/enemy/enemy_sprinter.tscn")
const TANK_SCENE: PackedScene = preload("res://entities/enemy/enemy_tank.tscn")
const SPLITTER_SCENE: PackedScene = preload("res://entities/enemy/enemy_splitter.tscn")
const BOSS_SCENE: PackedScene = preload("res://entities/enemy/boss.tscn")

# --- CONFIGURATION ---
@export var spawn_radius: float = 650.0        # Distance from player to spawn enemies
@export var base_spawn_interval: float = 1.0   # Starting seconds between spawns
@export var min_spawn_interval: float = 0.2    # Fastest possible spawn rate
@export var boss_time: float = 600.0           # Seconds before boss spawns (10 minutes)

# --- REFERENCES ---
var player: Node2D = null

# --- INTERNAL STATE ---
var elapsed_time: float = 0.0
var spawn_timer: float = 0.0
var boss_spawned: bool = false
var boss_alive: bool = false

# --- WAVE TABLE ---
# Defines the full escalation curve. Add new entries to expand the game.
var wave_table: Array[WaveEntry] = []

# --- ACTIVE POOL ---
# Built dynamically as waves activate. Holds {scene, weight} pairs for weighted random selection.
var _active_pool: Array[WaveEntry] = []
var _total_weight: float = 0.0

func _ready() -> void:
	# Build the wave table — each entry is (activation_time_seconds, scene, spawn_weight)
	wave_table.append(WaveEntry.new(0.0, GRUNT_SCENE, 5.0))        # Minute 0: Grunts dominate
	wave_table.append(WaveEntry.new(60.0, SPRINTER_SCENE, 2.0))    # Minute 1: Sprinters join
	wave_table.append(WaveEntry.new(120.0, GRUNT_SCENE, 3.0))      # Minute 2: More grunts
	wave_table.append(WaveEntry.new(180.0, TANK_SCENE, 1.5))       # Minute 3: Tanks appear
	wave_table.append(WaveEntry.new(240.0, SPLITTER_SCENE, 2.0))   # Minute 4: Splitters arrive
	wave_table.append(WaveEntry.new(300.0, SPRINTER_SCENE, 3.0))   # Minute 5: Sprinter surge
	wave_table.append(WaveEntry.new(360.0, TANK_SCENE, 2.5))       # Minute 6: Heavy tank wave
	wave_table.append(WaveEntry.new(420.0, SPLITTER_SCENE, 3.0))   # Minute 7: Splitter swarm
	wave_table.append(WaveEntry.new(480.0, GRUNT_SCENE, 5.0))      # Minute 8: Everything ramps
	wave_table.append(WaveEntry.new(540.0, SPRINTER_SCENE, 4.0))   # Minute 9: Final chaos

func _process(delta: float) -> void:
	if player == null:
		return
	
	elapsed_time += delta
	
	# --- Activate new waves as time progresses ---
	_update_active_pool()
	
	# --- Boss spawn check ---
	if not boss_spawned and elapsed_time >= boss_time:
		_spawn_boss()
		return  # Don't spawn regular enemies on the boss frame
	
	# --- Don't spawn regular enemies while boss is alive ---
	if boss_alive:
		return
	
	# --- Calculate current spawn rate (gets faster over time) ---
	# Spawn interval decreases logarithmically: fast improvement early, plateaus later
	var speed_factor: float = 1.0 + (elapsed_time / 60.0) * 0.3
	var current_interval: float = maxf(base_spawn_interval / speed_factor, min_spawn_interval)
	
	# --- Spawn timer ---
	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer -= current_interval
		_spawn_enemy()

# --- WAVE ACTIVATION ---
# Checks the wave table and adds newly activated waves to the spawn pool.
func _update_active_pool() -> void:
	var i: int = 0
	while i < wave_table.size():
		if wave_table[i].time_start <= elapsed_time:
			var entry: WaveEntry = wave_table[i]
			_active_pool.append(entry)
			_total_weight += entry.weight
			wave_table.remove_at(i)
			print("[WaveManager] New wave activated: +", entry.scene.resource_path.get_file())
		else:
			i += 1

# --- WEIGHTED RANDOM SPAWN ---
# Picks an enemy type from the active pool using weighted probability.
func _spawn_enemy() -> void:
	if _active_pool.is_empty():
		return
	
	# Weighted random selection
	var roll: float = randf() * _total_weight
	var cumulative: float = 0.0
	var chosen_scene: PackedScene = _active_pool[0].scene
	
	for entry: WaveEntry in _active_pool:
		cumulative += entry.weight
		if roll <= cumulative:
			chosen_scene = entry.scene
			break
	
	# Instantiate and position
	var enemy: CharacterBody2D = chosen_scene.instantiate()
	var angle: float = randf() * TAU
	var spawn_pos: Vector2 = player.global_position + Vector2(
		cos(angle) * spawn_radius,
		sin(angle) * spawn_radius
	)
	enemy.global_position = spawn_pos
	enemy.target_node = player
	get_parent().call_deferred("add_child", enemy)

# --- BOSS SPAWN ---
func _spawn_boss() -> void:
	boss_spawned = true
	boss_alive = true
	
	var boss: CharacterBody2D = BOSS_SCENE.instantiate()
	var angle: float = randf() * TAU
	boss.global_position = player.global_position + Vector2(
		cos(angle) * spawn_radius,
		sin(angle) * spawn_radius
	)
	boss.target_node = player
	
	# Connect the boss's death signal so we know when to resume normal spawning
	boss.tree_exited.connect(_on_boss_defeated)
	
	get_parent().call_deferred("add_child", boss)
	print("[WaveManager] BOSS SPAWNED!")

func _on_boss_defeated() -> void:
	boss_alive = false
	print("[WaveManager] Boss defeated!")
