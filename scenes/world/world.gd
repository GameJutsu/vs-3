extends Node2D
## World Controller Script
## Orchestrates the main game loop: manages the survival timer countdown, handles
## game completion states (GameOver / Victory overlays), and delegates enemy spawning.

# --- CHILD NODE REFERENCES ---
@onready var player: CharacterBody2D = $Player
@onready var creature: Area2D = $Creature
@onready var wave_manager: Node = $WaveManager
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var boss_health_bar: ProgressBar = $CanvasLayer/BossHealthBar

# --- SCREEN OVERLAYS ---
@onready var game_over_screen: ColorRect = $CanvasLayer/GameOverScreen
@onready var victory_screen: ColorRect = $CanvasLayer/VictoryScreen

# --- INTERNAL STATE ---
var time_remaining: float = 300.0   # 5-minute countdown (300 seconds)
var is_game_over: bool = false
var _boss_spawned: bool = false

# --- INITIALIZATION ---
func _ready() -> void:
	# Unpause the game tree in case we are restarting
	get_tree().paused = false
	
	# Dependency Injection: Tell the creature and wave manager who the player is
	creature.target_node = player
	wave_manager.player = player
	
	# Hide overlays and boss HP bar
	game_over_screen.hide()
	victory_screen.hide()
	boss_health_bar.hide()
	
	# Connect player death signal
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
		
	# Connect overlay button signals
	$CanvasLayer/GameOverScreen/VBox/HBox/RetryBtn.pressed.connect(_on_retry_pressed)
	$CanvasLayer/GameOverScreen/VBox/HBox/MenuBtn.pressed.connect(_on_menu_pressed)
	$CanvasLayer/VictoryScreen/VBox/HBox/PlayAgainBtn.pressed.connect(_on_retry_pressed)
	$CanvasLayer/VictoryScreen/VBox/HBox/MenuBtn.pressed.connect(_on_menu_pressed)

# --- FRAME UPDATE ---
func _process(delta: float) -> void:
	if is_game_over:
		return
		
	# Update survival timer countdown
	time_remaining = maxf(time_remaining - delta, 0.0)
	var minutes: int = int(time_remaining) / 60
	var seconds: int = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Update boss health bar if a boss is alive
	_update_boss_health_bar()

# --- BOSS HEALTH BAR & VICTORY TRIGGER ---
# Scans the scene for any node in the "boss" group.
func _update_boss_health_bar() -> void:
	var bosses: Array[Node] = get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		_boss_spawned = true
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
		# If the boss was spawned but is now gone, player has won!
		if _boss_spawned and not is_game_over:
			_on_victory()

# --- GAME OVER STATE ---
func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	
	# Update stats on overlay
	game_over_screen.get_node("VBox/Kills").text = "Total Kills: " + str(player.kill_count)
	
	# Calculate elapsed survival time
	var time_survived: float = 300.0 - time_remaining
	var minutes: int = int(time_survived) / 60
	var seconds: int = int(time_survived) % 60
	game_over_screen.get_node("VBox/Time").text = "Time Survived: %02d:%02d" % [minutes, seconds]
	
	game_over_screen.show()

# --- VICTORY STATE ---
func _on_victory() -> void:
	is_game_over = true
	get_tree().paused = true
	
	# Update stats on overlay
	victory_screen.get_node("VBox/Kills").text = "Final Kills: " + str(player.kill_count)
	victory_screen.show()

# --- BUTTON EVENT HANDLERS ---
func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
