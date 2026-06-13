extends ColorRect
## Upgrade Menu — The Tactical Pause Screen
## When the player levels up, this menu pauses the entire game engine, presents 3 random
## upgrade cards, and unpauses once the player picks one. The menu itself continues to
## function because its process_mode is set to ALWAYS (configured in the .tscn).

# --- PRELOADED SCENES ---
# The card UI component we will instantiate for each upgrade option.
const CARD_SCENE: PackedScene = preload("res://ui/upgrade_card.tscn")

# --- UPGRADE POOL ---
# All available upgrades in the game. Preloaded at compile time so there is zero
# disk access during gameplay. To add a new upgrade, create a .tres file and add it here.
var upgrade_pool: Array[UpgradeResource] = [
	preload("res://data/upgrades/speed_boost.tres"),
	preload("res://data/upgrades/attack_speed.tres"),
	preload("res://data/upgrades/heal.tres"),
	preload("res://data/upgrades/max_health.tres"),
	preload("res://data/upgrades/unlock_zubat.tres"),
	preload("res://data/upgrades/unlock_staryu.tres"),
	preload("res://data/upgrades/unlock_geodude.tres"),
	preload("res://data/upgrades/unlock_pikachu.tres"),
]

# --- SIGNALS ---
# Emitted when the player clicks a card. Carries the chosen UpgradeResource
# upstream to the Player script for stat application.
signal upgrade_selected(data: UpgradeResource)

# --- CHILD REFERENCES ---
@onready var card_container: HBoxContainer = $CenterContainer/VBoxContainer/CardContainer
@onready var level_label: Label = $CenterContainer/VBoxContainer/LevelLabel

func _ready() -> void:
	# Start hidden — the menu only appears on level-up
	hide()

# --- PUBLIC API ---
# Called by player.gd when a level-up occurs.
# Freezes the game world, generates 3 random upgrade cards, and displays them.
func open_menu(level: int) -> void:
	# 1. Freeze the entire game physics and processing
	get_tree().paused = true
	
	# 2. Update the level display
	level_label.text = "LEVEL " + str(level) + "!"
	
	# 3. Clear any leftover cards from a previous level-up
	for child in card_container.get_children():
		child.queue_free()
	
	# 4. Wait one frame for queue_free to process before adding new cards
	await get_tree().process_frame
	
	# 5. Shuffle the pool and pick up to 3 unique upgrades
	var available: Array[UpgradeResource] = upgrade_pool.duplicate()
	available.shuffle()
	
	var count: int = mini(3, available.size())
	for i: int in range(count):
		var card: Button = CARD_SCENE.instantiate()
		card_container.add_child(card)
		card.setup(available[i])
		# Connect each card's 'chosen' signal to our handler
		card.chosen.connect(_on_upgrade_chosen)
	
	# 6. Show the menu overlay
	show()

# --- INTERNAL HANDLER ---
# Called when any card is clicked. Forwards the data and unpauses.
func _on_upgrade_chosen(data: UpgradeResource) -> void:
	upgrade_selected.emit(data)
	hide()
	# Unpause the game world — physics and enemy AI resume instantly
	get_tree().paused = false
