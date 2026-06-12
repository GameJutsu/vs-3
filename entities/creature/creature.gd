extends Area2D
## Creature Companion Behavior Script
## This script controls a companion creature that follows the player and attacks nearby enemies.
## It demonstrates a simple State Machine, linear interpolation (lerp), and signal handling in Godot.

# --- EXPORTED PARAMETERS ---
# @export makes these variables editable directly in the Godot Editor Inspector panel.
# This allows game designers to fine-tune behavior without modifying script files.
@export var follow_speed: float = 5.0      # Speed factor for trailing behind the target (player)
@export var attack_speed: float = 8.0      # Speed factor when lunging towards an enemy (faster for impact)
@export var follow_distance: float = 60.0   # The desired distance (in pixels) the creature maintains from the target

# --- TARGET REFERENCES ---
# We store references to Node2D objects since we need their positions (global_position).
var target_node: Node2D = null             # Refers to the player (our master to follow)
var current_enemy: Node2D = null           # Refers to the active enemy we are attacking

# --- STATE MACHINE ARCHITECTURE ---
# Enums (Enumerations) let us define distinct states using readable names instead of arbitrary numbers.
# This makes our code much more readable and less prone to logic bugs.
enum State { 
	FOLLOW, # State 0: Default state, following behind the player.
	ATTACK  # State 1: Active combat state, charging at an enemy.
}
var state: State = State.FOLLOW             # Initialize the creature in the follow state

# --- FRAME-BY-FRAME UPDATE ---
# _process(delta) runs once every frame. The 'delta' parameter is the time elapsed (in seconds) 
# since the last frame. Multiplying speeds by 'delta' ensures movement is smooth and independent 
# of the game's frame rate (so players with high frame rates don't move faster).
func _process(delta: float) -> void:
	# 'match' is Godot's version of a 'switch' statement. It evaluates our current state.
	match state:
		State.FOLLOW:
			# If we have a player to follow, steer toward a position just behind them
			if target_node != null:
				# 1. Calculate direction vector pointing from the creature to the player
				var direction_to_target: Vector2 = global_position.direction_to(target_node.global_position)
				
				# 2. Calculate the target point: offset by follow_distance in the opposite direction of movement
				var target_position: Vector2 = target_node.global_position - (direction_to_target * follow_distance)
				
				# 3. lerp() (Linear Interpolation) smoothly moves our position towards target_position.
				# It takes (start_value, end_value, weight). By using (follow_speed * delta) as the weight,
				# we get a smooth, easing easing-in/out movement.
				global_position = global_position.lerp(target_position, follow_speed * delta)

		State.ATTACK:
			# is_instance_valid() checks if the enemy node still exists in memory.
			# This is a critical guard: if the player or another companion killed the enemy first,
			# referencing a freed node would cause a game crash (null pointer exception).
			if current_enemy != null and is_instance_valid(current_enemy):
				# Move directly towards the enemy's current position using lerp at a higher speed
				global_position = global_position.lerp(current_enemy.global_position, attack_speed * delta)
				
				# Check the distance to the enemy. 15.0 pixels is close enough to count as a "bite" / hit.
				if global_position.distance_to(current_enemy.global_position) < 15.0:
					current_enemy.die()      # Trigger the enemy's custom death routine (spawns gems, frees memory)
					current_enemy = null     # Clear the target
					state = State.FOLLOW     # Return to following the player
			else:
				# If the enemy became invalid (e.g. died from another source), return to following the player
				state = State.FOLLOW

# --- SIGNAL RESPONSES ---
# This is a signal-connected function. It triggers automatically when a PhysicsBody2D 
# (like our Enemy) enters the Area2D's CollisionShape2D detection zone.
func _on_body_entered(body: Node2D) -> void:
	# Verify that:
	# 1. The entering body is part of the "enemy" group (we ignore the player and gems).
	# 2. We are currently in the FOLLOW state (so we don't switch targets mid-attack).
	if body.is_in_group("enemy") and state == State.FOLLOW:
		current_enemy = body                 # Set the body as our target
		state = State.ATTACK                 # Transition to the attack state

