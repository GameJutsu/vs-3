extends CanvasLayer
class_name HUDController
## HUD Controller Script
## Manages all HUD elements (health, experience, statistics, timers, and overlays)
## by listening to event signals from the Player and handling screen transitions.

# --- NODE REFERENCES ---
@onready var health_bar: ProgressBar = $HealthBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var kill_label: Label = $KillLabel
@onready var timer_label: Label = $TimerLabel
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var companion_label: Label = $CompanionLabel
@onready var stats_label: Label = $StatsLabel
@onready var game_over_screen: ColorRect = $GameOverScreen
@onready var victory_screen: ColorRect = $VictoryScreen
@onready var upgrade_menu: Control = $UpgradeMenu

func _ready() -> void:
	# Hide overlay screens and boss bar by default
	if game_over_screen != null:
		game_over_screen.hide()
	if victory_screen != null:
		victory_screen.hide()
	if boss_health_bar != null:
		boss_health_bar.hide()
		
	# Connect retry/menu button signals directly
	var retry_btn: Button = get_node_or_null("GameOverScreen/VBox/HBox/RetryBtn")
	if retry_btn != null:
		retry_btn.pressed.connect(_on_retry_pressed)
		
	var menu_btn: Button = get_node_or_null("GameOverScreen/VBox/HBox/MenuBtn")
	if menu_btn != null:
		menu_btn.pressed.connect(_on_menu_pressed)
		
	var play_again_btn: Button = get_node_or_null("VictoryScreen/VBox/HBox/PlayAgainBtn")
	if play_again_btn != null:
		play_again_btn.pressed.connect(_on_retry_pressed)
		
	var victory_menu_btn: Button = get_node_or_null("VictoryScreen/VBox/HBox/MenuBtn")
	if victory_menu_btn != null:
		victory_menu_btn.pressed.connect(_on_menu_pressed)

func setup_connections(player: CharacterBody2D) -> void:
	if player == null:
		return
		
	# Connect to player's state signals
	player.health_changed.connect(_on_player_health_changed)
	player.xp_changed.connect(_on_player_xp_changed)
	player.level_up_triggered.connect(_on_player_level_up)
	player.kills_changed.connect(_on_player_kills_changed)
	player.active_companion_changed.connect(_on_player_companion_changed)
	player.stats_updated.connect(_on_player_stats_updated)
	
	# Initial UI state setup
	_on_player_health_changed(player.current_health, player.max_health)
	_on_player_xp_changed(player.current_xp, player.xp_to_next_level)
	_on_player_kills_changed(player.kill_count)
	player.update_companion_hud()

func show_game_over(kills: int, time_survived: float) -> void:
	if game_over_screen != null:
		var kills_lbl: Label = game_over_screen.get_node_or_null("VBox/Kills")
		if kills_lbl != null:
			kills_lbl.text = "Total Kills: " + str(kills)
		
		var time_lbl: Label = game_over_screen.get_node_or_null("VBox/Time")
		if time_lbl != null:
			var minutes: int = int(time_survived) / 60
			var seconds: int = int(time_survived) % 60
			time_lbl.text = "Time Survived: %02d:%02d" % [minutes, seconds]
			
		game_over_screen.show()

func show_victory(kills: int) -> void:
	if victory_screen != null:
		var kills_lbl: Label = victory_screen.get_node_or_null("VBox/Kills")
		if kills_lbl != null:
			kills_lbl.text = "Final Kills: " + str(kills)
		victory_screen.show()

func _on_player_health_changed(current: int, max_hp: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_hp
		health_bar.value = current

func _on_player_xp_changed(current: int, needed: int) -> void:
	if xp_bar != null:
		xp_bar.max_value = needed
		xp_bar.value = current

func _on_player_level_up(level: int) -> void:
	print("[HUD] Player leveled up to level ", level)

func _on_player_kills_changed(count: int) -> void:
	if kill_label != null:
		kill_label.text = "Kills: " + str(count)

func _on_player_companion_changed(comp_name: String) -> void:
	if companion_label != null:
		companion_label.text = "Companion: " + comp_name.to_upper()

func _on_player_stats_updated(projectiles: int, fire_rate: float, aoe: float, velocity: float, speed: float, weapon_name: String) -> void:
	if stats_label != null:
		var txt: String = """🎯 Projectiles: %d
⚡ Fire Rate: %.2fx
💥 AoE: %.2fx
🚀 Velocity: %.2fx
🏃 Speed: %d
⚔️ Weapon: %s""" % [
			projectiles,
			fire_rate,
			aoe,
			velocity,
			int(speed),
			weapon_name
		]
		
		# Append debug markers if they are active on player
		var p = get_parent().get_node_or_null("Player")
		if p != null:
			if p.get("auto_fire"):
				txt += "\n🔫 AUTO-FIRE ON"
			if p.get("debug_mode"):
				txt += "\n🤖 AUTO-UPGRADE ON"
				
		stats_label.text = txt

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
