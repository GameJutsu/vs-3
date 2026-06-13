extends Node
## Global Stats Autoload Singleton
## Stores base modifiers that apply to both player weapons and active companions.
## As per the "Nova Drift" GDD rules, upgrades affect global stats, affecting all combat systems.

# --- GLOBAL MODIFIERS ---
@export var global_projectiles: int = 1         # Base bullet/projectile count multiplier
@export var global_fire_rate_mult: float = 1.0   # Base attack speed/fire rate multiplier
@export var global_aoe_radius: float = 1.0       # Base explosion/impact radius modifier
@export var global_velocity_mult: float = 1.0    # Base speed/rotation velocity multiplier

var selected_character: String = "vaibhav"      # "vaibhav" or "rishu"

## Reset all stats to default values at the start of a run
func reset_to_defaults() -> void:
	global_projectiles = 1
	global_fire_rate_mult = 1.0
	global_aoe_radius = 1.0
	global_velocity_mult = 1.0

