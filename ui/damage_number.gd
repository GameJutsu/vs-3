extends Label
## Floating Damage Number
## Spawns at a world position, floats upward, and fades out over its lifetime.
## Used for enemy damage indicators and player hit feedback.

# --- CONFIGURATION ---
@export var float_speed: float = 50.0      # Pixels per second upward
@export var lifetime: float = 0.6          # Seconds before disappearing

func _ready() -> void:
	# Anchor the label at its center so it spawns centered on the hit point
	pivot_offset = size / 2.0
	
	# Create a parallel tween for the fade-out and slight scale pop
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# Start slightly larger and shrink to normal over the first 0.1 seconds (impact pop)
	scale = Vector2(1.4, 1.4)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Fade out over the full lifetime
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	
	# After the tween completes, delete this node
	tween.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	# Float upward every frame
	position.y -= float_speed * delta
