extends Button
## Upgrade Card UI Component
## A reusable card widget that displays one UpgradeResource's data (icon, title, description).
## When the player clicks this card, it emits the 'chosen' signal carrying the resource data
## so the UpgradeMenu knows which upgrade was selected.

# --- DATA BINDING ---
# This variable holds the UpgradeResource (.tres) that was assigned to this card.
var upgrade_data: UpgradeResource

# --- SIGNAL ---
# Emitted when the player clicks this card. Carries the full resource data upstream
# to the UpgradeMenu, which then forwards it to the Player for stat application.
signal chosen(data: UpgradeResource)

# --- PUBLIC SETUP METHOD ---
# Called by the UpgradeMenu when populating cards. Reads the resource and fills the UI labels.
func setup(data: UpgradeResource) -> void:
	upgrade_data = data
	$MarginContainer/VBoxContainer/TitleLabel.text = data.title
	$MarginContainer/VBoxContainer/DescLabel.text = data.description
	if data.icon != null:
		$MarginContainer/VBoxContainer/IconTexture.texture = data.icon

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)

func _on_mouse_entered() -> void:
	SoundManager.play_sound("ui_hover")

# --- BUTTON PRESS HANDLER ---
# Connected to the Button's built-in 'pressed' signal.
# When clicked, we emit our custom 'chosen' signal so the menu can react.
func _on_pressed() -> void:
	SoundManager.play_sound("ui_click")
	chosen.emit(upgrade_data)
