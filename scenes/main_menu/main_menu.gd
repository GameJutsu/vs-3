extends Control
## Main Menu Script
## Manages character selection, play and quit buttons, and play hover/click sounds.

@onready var vaibhav_btn: Button = $CenterContainer/VBoxContainer/CharSelectHBox/VaibhavBtn
@onready var rishu_btn: Button = $CenterContainer/VBoxContainer/CharSelectHBox/RishuBtn
@onready var char_desc: Label = $CenterContainer/VBoxContainer/CharDesc

func _ready() -> void:
	# Ensure the game tree is unpaused when visiting menu
	get_tree().paused = false
	
	# Connect button clicks
	$CenterContainer/VBoxContainer/PlayBtn.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/QuitBtn.pressed.connect(_on_quit_pressed)
	
	# Connect hover sound effects
	$CenterContainer/VBoxContainer/PlayBtn.mouse_entered.connect(_on_hover)
	$CenterContainer/VBoxContainer/QuitBtn.mouse_entered.connect(_on_hover)
	
	# Connect character buttons
	vaibhav_btn.pressed.connect(_select_vaibhav)
	rishu_btn.pressed.connect(_select_rishu)
	vaibhav_btn.mouse_entered.connect(_on_hover)
	rishu_btn.mouse_entered.connect(_on_hover)
	
	# Initialize UI
	_update_selection_ui()

func _on_hover() -> void:
	SoundManager.play_sound("ui_hover")

func _select_vaibhav() -> void:
	SoundManager.play_sound("ui_click")
	GlobalStats.selected_character = "vaibhav"
	_update_selection_ui()

func _select_rishu() -> void:
	SoundManager.play_sound("ui_click")
	GlobalStats.selected_character = "rishu"
	_update_selection_ui()

func _update_selection_ui() -> void:
	var active_color: Color = Color(0.0, 0.85, 0.9, 1.0)
	var inactive_color: Color = Color(0.5, 0.5, 0.5, 1.0)
	
	if GlobalStats.selected_character == "vaibhav":
		vaibhav_btn.modulate = active_color
		vaibhav_btn.text = "🐾 Vaibhav"
		rishu_btn.modulate = inactive_color
		rishu_btn.text = "Rishu"
		char_desc.text = "Vaibhav (The Mechanic) fires the Maglev Cube. Hold LMB to solve/wind-up and launch a high-impact explosive blast."
	else:
		vaibhav_btn.modulate = inactive_color
		vaibhav_btn.text = "Vaibhav"
		rishu_btn.modulate = active_color
		rishu_btn.text = "🐾 Rishu"
		char_desc.text = "Rishu (The Tactician) fires the Deck. Hold LMB to fire cards. Alternates piercing RED cards and shielding orbital BLACK cards."

func _on_play_pressed() -> void:
	SoundManager.play_sound("ui_click")
	# Reset stats for the new run
	GlobalStats.reset_to_defaults()
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _on_quit_pressed() -> void:
	SoundManager.play_sound("ui_click")
	# Delay quit briefly so click sound can trigger
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
