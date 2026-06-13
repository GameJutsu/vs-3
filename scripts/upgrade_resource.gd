extends Resource
## Upgrade Resource — Data Container for Level-Up Upgrades
## This is a "Scriptable Object" in Godot terms. Each .tres file created from this class
## represents one unique upgrade card the player can pick during the Tactical Pause.
## Adding new upgrades to the game requires zero code changes — just create a new .tres file.
class_name UpgradeResource

# --- DISPLAY PROPERTIES ---
# These fields populate the visual upgrade card UI.
@export var title: String = "Upgrade Name"
@export var description: String = "Description of the effect."
@export var icon: Texture2D

# --- MECHANICAL PROPERTIES ---
# The UpgradeType enum maps each upgrade to a specific stat modification in player.gd.
# To add a new upgrade category (e.g., CREATURE_DAMAGE), simply add it to this enum
# and handle the new case in player.gd's match statement.
enum UpgradeType {
	PLAYER_SPEED,            # Increases player movement speed
	CREATURE_ATTACK_SPEED,   # Makes the companion lunge faster
	HEAL_PLAYER,             # Restores HP instantly
	MAX_HEALTH,              # Permanently raises the HP cap
	UNLOCK_CREATURE,         # Unlocks a new companion type
}
@export var type: UpgradeType

# The numerical magnitude of the upgrade effect (e.g., 50.0 for speed, 30 for heal).
@export var value: float = 0.0

# The identifier of the creature being unlocked (used when type is UNLOCK_CREATURE)
@export var creature_id: String = ""
