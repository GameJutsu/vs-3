extends CharacterBody2D
## Enemy AI Controller Script
## This script governs the basic behavior of an enemy: chasing a target (the player)
## and dropping an experience (XP) gem upon death.

# --- EXPORTED PARAMETERS ---
@export var speed: float = 100.0          # The speed at which the enemy walks toward the target

# --- PRELOADED RESOURCES ---
# 'preload' loads the specified scene (.tscn) into RAM when this script/class compiles (at startup).
# This is much faster than 'load()' (which reads from the disk at runtime).
# Preloading prevents game stuttering/lag spikes when spawning multiple items or enemies dynamically.
const XP_GEM_SCENE: PackedScene = preload("res://items/xp_gem/xp_gem.tscn")

# --- TARGET REFERENCE ---
var target_node: Node2D = null             # Refers to the Node we want to chase (usually the player)

# --- PHYSICS UPDATE LOOP ---
# We use _physics_process for movement because enemies are CharacterBody2D (physics-enabled bodies).
func _physics_process(_delta: float) -> void:
	# Check if we have a valid target to chase
	if target_node != null:
		# 1. global_position.direction_to() calculates a normalized Vector2 pointing at the target
		var direction: Vector2 = global_position.direction_to(target_node.global_position)
		
		# 2. Scale the direction vector by our speed to get velocity
		velocity = direction * speed
		
		# 3. Move the character using Godot's built-in physics handler
		move_and_slide()

# --- DEATH & CLEANUP ---
# Creating a dedicated die() method helps us centralize any cleanup logic (spawning loot,
# updating score/kills, playing death sounds, and playing death animations).
func die() -> void:
	# 1. Instantiate (spawn) a copy of the preloaded XP Gem scene
	var gem: Area2D = XP_GEM_SCENE.instantiate()
	
	# 2. Position the gem exactly where this enemy currently is
	gem.global_position = global_position
	
	# 3. Add the gem to the active scene tree.
	# We must add it to the parent (World) instead of the enemy node itself, because this enemy 
	# is about to be deleted. If we added the gem as a child of the enemy, the gem would be deleted too!
	# We use call_deferred("add_child", gem) instead of add_child(gem).
	# Modifying the active scene tree structure during physics callback calculations is unsafe 
	# and can cause crashes. 'call_deferred' waits until the current frame's physics step is done before execution.
	get_parent().call_deferred("add_child", gem)
	
	# 4. Safely delete this enemy node from memory.
	# queue_free() flags the node for deletion at the end of the frame, giving other active processes
	# time to finish executing their current lines without throwing null reference errors.
	queue_free()

