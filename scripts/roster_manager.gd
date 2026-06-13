extends Node
class_name RosterManager
## Roster Manager Node
## Attached to the Player. Handles instantiating the active companion in the world
## and swapping them out during tag-team cycling.

# --- PRELOAD DICTIONARY ---
const SCENES: Dictionary = {
	"rattata": preload("res://entities/creature/pokemon/rattata.tscn"),
	"raticate": preload("res://entities/creature/pokemon/raticate.tscn"),
	"zubat": preload("res://entities/creature/pokemon/zubat.tscn"),
	"golbat": preload("res://entities/creature/pokemon/golbat.tscn"),
	"staryu": preload("res://entities/creature/pokemon/staryu.tscn"),
	"starmie": preload("res://entities/creature/pokemon/starmie.tscn"),
	"geodude": preload("res://entities/creature/pokemon/geodude.tscn"),
	"graveler": preload("res://entities/creature/pokemon/graveler.tscn"),
	"pikachu": preload("res://entities/creature/pokemon/pikachu.tscn"),
	"raichu": preload("res://entities/creature/pokemon/raichu.tscn")
}

# --- ACTIVE COMPANION REF ---
var active_companion_node: CompanionBase = null

func deploy_companion(id: String, spawn_position: Vector2, target_player: CharacterBody2D) -> void:
	# 1. Clean up active companion if it exists
	retract_companion()
	
	# 2. Instantiate new one
	if not SCENES.has(id):
		push_error("RosterManager: Unknown companion ID " + id)
		return
		
	var scene: PackedScene = SCENES[id]
	var companion: CompanionBase = scene.instantiate()
	companion.global_position = spawn_position
	companion.target_node = target_player
	
	# Add to World (sibling of Player)
	target_player.get_parent().call_deferred("add_child", companion)
	active_companion_node = companion
	
	# Trigger custom swap entrance effects if any
	if companion.has_method("on_swap_in"):
		companion.on_swap_in()

func retract_companion() -> void:
	if active_companion_node != null and is_instance_valid(active_companion_node):
		active_companion_node.queue_free()
		active_companion_node = null
