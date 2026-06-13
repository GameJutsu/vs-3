extends Camera2D
## Trauma-Based Camera Shake System
## Shaking intensity is driven by a 'trauma' value (0.0–1.0) that decays over time.
## The actual shake offset uses trauma^2 so that small hits feel subtle and big hits feel massive.
## Call add_trauma() from anywhere to trigger a shake.

# --- CONFIGURATION ---
@export var max_offset: Vector2 = Vector2(8.0, 6.0)  # Maximum pixel displacement in each axis
@export var decay_rate: float = 3.0                    # How quickly trauma fades (per second)

# --- INTERNAL STATE ---
var trauma: float = 0.0                                # Current trauma level (0.0 = calm, 1.0 = max)

func _ready() -> void:
	EventBus.camera_shake_requested.connect(add_trauma)

func _process(delta: float) -> void:
	if trauma > 0.0:
		# Decay trauma over time so the shake naturally settles
		trauma = maxf(trauma - decay_rate * delta, 0.0)
		
		# Calculate shake intensity using trauma^2 for a non-linear feel.
		# Small trauma = barely noticeable. High trauma = violent jolt.
		var shake_power: float = trauma * trauma
		
		# Apply random offset within the max range, scaled by shake power
		offset = Vector2(
			randf_range(-max_offset.x, max_offset.x) * shake_power,
			randf_range(-max_offset.y, max_offset.y) * shake_power
		)
	else:
		# Reset to center when calm
		offset = Vector2.ZERO

# --- PUBLIC API ---
# Call this from any script to trigger a shake. Values are additive and clamped to 1.0.
func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)
