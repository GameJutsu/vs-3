extends Area2D
## Sniper Projectile Script
## Moves in a straight line, deals damage to the first enemy it hits, and self-destructs.

# --- CONFIGURATION ---
var speed: float = 500.0
var damage: int = 40
var direction: Vector2 = Vector2.RIGHT

# --- LIFE TIME ---
var lifetime: float = 3.0

func _ready() -> void:
	# Self-destruct after lifetime to prevent memory leaks
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
