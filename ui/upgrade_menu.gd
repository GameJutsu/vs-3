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
	preload("res://data/upgrades/unlock_rattata.tres"),
	preload("res://data/upgrades/evolve_raticate.tres"),
	preload("res://data/upgrades/evolve_golbat.tres"),
	preload("res://data/upgrades/evolve_starmie.tres"),
	preload("res://data/upgrades/evolve_graveler.tres"),
	preload("res://data/upgrades/evolve_raichu.tres"),
	preload("res://data/upgrades/blink_dash.tres"),
	preload("res://data/upgrades/phoenix_rebirth.tres"),
	preload("res://data/upgrades/fusillade.tres"),
	preload("res://data/upgrades/singularity_pull.tres"),
]

# --- SIGNALS ---
# Emitted when the player clicks a card. Carries the chosen UpgradeResource
# upstream to the Player script for stat application.
signal upgrade_selected(data: UpgradeResource)

# --- CHILD REFERENCES ---
@onready var card_container: HBoxContainer = $CenterContainer/VBoxContainer/CardContainer
@onready var level_label: Label = $CenterContainer/VBoxContainer/LevelLabel
@onready var tech_tree_panel: ColorRect = $TechTreePanel

func _ready() -> void:
	# Start hidden — the menu only appears on level-up
	hide()
	tech_tree_panel.hide()
	
	if has_node("CenterContainer/VBoxContainer/ViewTreeBtn"):
		$CenterContainer/VBoxContainer/ViewTreeBtn.pressed.connect(_on_view_tree_pressed)

# --- PUBLIC API ---
# Called by player.gd when a level-up occurs.
# Freezes the game world, generates 3 filtered upgrade cards, and displays them.
func open_menu(level: int, player_roster: Array[String] = []) -> void:
	# Hide tech tree panel on opening
	tech_tree_panel.hide()
	
	# 1. Freeze the entire game physics and processing
	get_tree().paused = true
	
	# 2. Update the level display
	level_label.text = "LEVEL " + str(level) + "!"
	
	# 3. Clear any leftover cards from a previous level-up
	for child in card_container.get_children():
		child.queue_free()
	
	# 4. Wait one frame for queue_free to process before adding new cards
	await get_tree().process_frame
	
	# Retrieve player owned upgrades
	var player = get_tree().current_scene.get_node_or_null("Player")
	var owned: Array[String] = []
	if player != null and "owned_upgrades" in player:
		owned = player.owned_upgrades
		
	# 5. Build a filtered pool using level-based gating and tech tree progression rules
	var available: Array[UpgradeResource] = _build_filtered_pool(level, player_roster, owned)
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
	
	# 7. Grab focus on the first card for keyboard/controller UI navigation
	if card_container.get_child_count() > 0:
		card_container.get_child(0).grab_focus()

# --- UPGRADE GATING & TECH TREE ---
# Filters the upgrade pool strictly based on prerequisites and tech tree rules.
# Once an upgrade is owned, it is removed from the selection pool.
func _build_filtered_pool(level: int, player_roster: Array[String], owned: Array[String]) -> Array[UpgradeResource]:
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
			
	# Tech Tree Columns progression mapping (All upgrades in a tree)
	var tree_columns = [
		# Global Trees
		["speed_boost", "upgrade_global_velocity", "blink_dash"],
		["max_health", "heal", "phoenix_rebirth"],
		["upgrade_global_fire_rate", "upgrade_global_projectiles", "fusillade"],
		["upgrade_global_aoe_radius", "attack_speed", "singularity_pull"],
		
		# Pokemon Trees (Summon -> Buff -> Evolve)
		["unlock_rattata", "buff_rattata", "evolve_raticate"],
		["unlock_zubat", "buff_zubat", "evolve_golbat"],
		["unlock_staryu", "buff_staryu", "evolve_starmie"],
		["unlock_geodude", "buff_geodude", "evolve_graveler"],
		["unlock_pikachu", "buff_pikachu", "evolve_raichu"]
	]
	
	for upgrade in upgrade_pool:
		var id = upgrade.resource_path.get_file().get_basename()
		
		# 1. If the upgrade is already owned, never offer it again (single purchase)
		if owned.has(id):
			continue
			
		# 2. Check prerequisites via tree columns
		var parent_owned = false
		var found_in_any_tree = false
		
		for col in tree_columns:
			var idx = col.find(id)
			if idx != -1:
				found_in_any_tree = true
				if idx == 0:
					parent_owned = true # Root node, always unlocked
				else:
					var parent_id = col[idx - 1]
					if owned.has(parent_id):
						parent_owned = true
				break
				
		if found_in_any_tree and parent_owned:
			filtered.append(upgrade)
					
	return filtered

# --- INTERNAL HANDLER ---
# Called when any card is clicked. Forwards the data and unpauses.
func _on_upgrade_chosen(data: UpgradeResource) -> void:
	upgrade_selected.emit(data)
	hide()
	tech_tree_panel.hide()
	# Unpause the game world — physics and enemy AI resume instantly
	get_tree().paused = false

func _on_view_tree_pressed() -> void:
	tech_tree_panel.open_tree()
