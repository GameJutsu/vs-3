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
	preload("res://data/upgrades/upgrade_global_projectiles.tres"),
	preload("res://data/upgrades/upgrade_global_fire_rate.tres"),
	preload("res://data/upgrades/upgrade_global_aoe_radius.tres"),
	preload("res://data/upgrades/upgrade_global_velocity.tres"),
	preload("res://data/upgrades/buff_rattata.tres"),
	preload("res://data/upgrades/buff_zubat.tres"),
	preload("res://data/upgrades/buff_staryu.tres"),
	preload("res://data/upgrades/buff_geodude.tres"),
	preload("res://data/upgrades/buff_pikachu.tres"),
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
# Freezes the game world, generates 3 filtered upgrade cards, and displays them.
func open_menu(level: int, player_roster: Array[String] = []) -> void:
	# 1. Freeze the entire game physics and processing
	get_tree().paused = true
	
	# 2. Update the level display
	level_label.text = "LEVEL " + str(level) + "!"
	
	# 3. Clear any leftover cards from a previous level-up
	for child in card_container.get_children():
		child.queue_free()
	
	# 4. Wait one frame for queue_free to process before adding new cards
	await get_tree().process_frame
	
	# 5. Build a filtered pool using level-based gating rules
	var available: Array[UpgradeResource] = _build_filtered_pool(level, player_roster)
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

# --- UPGRADE GATING ---
# Filters the upgrade pool based on player level and roster composition.
# Gating rules:
#   Levels 1-3: Base stats only (Speed, Heal, Max HP, Attack Speed)
#   Levels 4-6: Above + Global modifiers (Projectiles, Fire Rate, AoE, Velocity)
#   Levels 7+:  Above + Companion unlocks
#   Any level:  Companion buffs only if that companion is in the roster
#   Companion unlocks are removed if already owned
func _build_filtered_pool(level: int, player_roster: Array[String]) -> Array[UpgradeResource]:
	var filtered: Array[UpgradeResource] = []
	
	# Map evolved forms back to base forms for roster checking
	var base_roster: Array[String] = []
	for creature in player_roster:
		match creature:
			"raticate": base_roster.append("rattata")
			"golbat": base_roster.append("zubat")
			"starmie": base_roster.append("staryu")
			"graveler": base_roster.append("geodude")
			"raichu": base_roster.append("pikachu")
			_: base_roster.append(creature)
	
	for upgrade in upgrade_pool:
		match upgrade.type:
			# BASE STATS — always available
			UpgradeResource.UpgradeType.PLAYER_SPEED, \
			UpgradeResource.UpgradeType.CREATURE_ATTACK_SPEED, \
			UpgradeResource.UpgradeType.HEAL_PLAYER, \
			UpgradeResource.UpgradeType.MAX_HEALTH:
				filtered.append(upgrade)
			
			# GLOBAL MODIFIERS — available from level 4+
			UpgradeResource.UpgradeType.GLOBAL_PROJECTILES, \
			UpgradeResource.UpgradeType.GLOBAL_FIRE_RATE, \
			UpgradeResource.UpgradeType.GLOBAL_AOE_RADIUS, \
			UpgradeResource.UpgradeType.GLOBAL_VELOCITY:
				if level >= 4:
					filtered.append(upgrade)
			
			# COMPANION UNLOCKS — available from level 7+, only if not already owned
			UpgradeResource.UpgradeType.UNLOCK_CREATURE:
				if level >= 7 and not base_roster.has(upgrade.creature_id):
					filtered.append(upgrade)
			
			# COMPANION BUFFS — only if that companion is in the roster
			UpgradeResource.UpgradeType.COMPANION_BUFF:
				if base_roster.has(upgrade.creature_id):
					filtered.append(upgrade)
	
	return filtered

# --- INTERNAL HANDLER ---
# Called when any card is clicked. Forwards the data and unpauses.
func _on_upgrade_chosen(data: UpgradeResource) -> void:
	upgrade_selected.emit(data)
	hide()
	# Unpause the game world — physics and enemy AI resume instantly
	get_tree().paused = false
