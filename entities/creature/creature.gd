extends Area2D
## Creature Companion Behavior Script
## Controls an autonomous companion that follows the player and attacks nearby enemies.
## Uses a Finite State Machine (FOLLOW → ATTACK) with damage, attack cooldown, and
## multi-hit combat against enemies that have HP.

# --- EXPORTED PARAMETERS ---
@export var follow_speed: float = 5.0       # Speed factor for trailing behind the player
@export var attack_speed: float = 8.0       # Speed factor when lunging towards an enemy
@export var follow_distance: float = 60.0   # Distance (pixels) the creature maintains from the player
@export var damage: int = 25                # Damage dealt per hit to the enemy
@export var attack_cooldown: float = 0.4    # Seconds between consecutive hits while in ATTACK state

# --- TARGET REFERENCES ---
var target_node: Node2D = null              # The player (our master to follow)
var current_enemy: Node2D = null            # The active enemy we are attacking

# --- STATE MACHINE ---
enum State { 
	FOLLOW, # Default: trailing behind the player
	ATTACK  # Combat: charging at and hitting an enemy
}
var state: State = State.FOLLOW

# --- ATTACK TIMING ---
# Tracks time since the last hit. When this exceeds attack_cooldown, we can strike again.
var _time_since_last_attack: float = 0.0

# --- FRAME-BY-FRAME UPDATE ---
func _process(delta: float) -> void:
	# Increment attack timer every frame (used in ATTACK state)
	_time_since_last_attack += delta
	
	match state:
		State.FOLLOW:
			if target_node != null:
				var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
				var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
				global_position = global_position.lerp(target_position, follow_speed * delta)

		State.ATTACK:
			# Guard: ensure the enemy still exists in memory
			if current_enemy != null and is_instance_valid(current_enemy):
				# Charge towards the enemy
				global_position = global_position.lerp(current_enemy.global_position, attack_speed * delta)
				
				# When close enough AND the cooldown has elapsed, strike
				if global_position.distance_to(current_enemy.global_position) < 20.0:
					if _time_since_last_attack >= attack_cooldown:
						_time_since_last_attack = 0.0
						
						# Deal damage via the enemy's take_damage() method
						current_enemy.take_damage(damage)
						
						# Check if the enemy died from this hit
						if not is_instance_valid(current_enemy) or current_enemy.current_hp <= 0:
							current_enemy = null
							state = State.FOLLOW
			else:
				# Enemy was killed by something else — return to player
				current_enemy = null
				state = State.FOLLOW

# --- SIGNAL: AGGRO DETECTION ---
# Triggered when a PhysicsBody2D enters the creature's CollisionShape2D detection zone.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and state == State.FOLLOW:
		current_enemy = body
		state = State.ATTACK
		_time_since_last_attack = attack_cooldown  # Allow immediate first strike
