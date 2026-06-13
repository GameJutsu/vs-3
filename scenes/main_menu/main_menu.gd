extends Control
## Main Menu Script
## Manages play and quit buttons, and presents a stylized title screen with hover sounds.

func _ready() -> void:
	# Ensure the game tree is unpaused when visiting menu
	get_tree().paused = false
	
	# Connect button clicks
	$CenterContainer/VBoxContainer/PlayBtn.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/QuitBtn.pressed.connect(_on_quit_pressed)
	
	# Connect hover sound effects
	$CenterContainer/VBoxContainer/PlayBtn.mouse_entered.connect(_on_hover)
	$CenterContainer/VBoxContainer/QuitBtn.mouse_entered.connect(_on_hover)

func _on_hover() -> void:
	SoundManager.play_sound("ui_hover")

func _on_play_pressed() -> void:
	SoundManager.play_sound("ui_click")
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _on_quit_pressed() -> void:
	SoundManager.play_sound("ui_click")
	# Delay quit briefly so click sound can trigger
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
