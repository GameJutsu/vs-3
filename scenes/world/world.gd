extends Node2D
## World Controller Script
## Orchestrates the main game loop: initializes node connections, manages the survival timer,
## and delegates enemy spawning to the WaveManager.

# --- CHILD NODE REFERENCES ---
@onready var player: CharacterBody2D = $Player
@onready var creature: Area2D = $Creature
@onready var wave_manager: Node = $WaveManager
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var boss_health_bar: ProgressBar = $CanvasLayer/BossHealthBar

# --- INTERNAL STATE ---
var elapsed_time: float = 0.0

# --- INITIALIZATION ---
func _ready() -> void:
	# Dependency Injection: Tell the creature and wave manager who the player is
	creature.target_node = player
	wave_manager.player = player
	
	# Hide boss health bar until a boss spawns
	boss_health_bar.hide()

# --- FRAME UPDATE ---
func _process(delta: float) -> void:
	# Update the survival timer display
	elapsed_time += delta
	var minutes: int = int(elapsed_time) / 60
	var seconds: int = int(elapsed_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Update boss health bar if a boss is alive
	_update_boss_health_bar()

# --- BOSS HEALTH BAR ---
# Scans the scene for any node in the "boss" group and displays its HP.
func _update_boss_health_bar() -> void:
	var bosses: Array[Node] = get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		var boss: CharacterBody2D = bosses[0] as CharacterBody2D
		if boss != null and is_instance_valid(boss):
			boss_health_bar.show()
			boss_health_bar.max_value = boss.max_hp
			boss_health_bar.value = boss.current_hp
		else:
			boss_health_bar.hide()
	else:
		if boss_health_bar.visible:
			boss_health_bar.hide()
