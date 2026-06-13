extends StaticBody2D
## Tree Obstacle — Static environmental hazard
## Blocks player and enemy movement. Drawn programmatically.

@export var trunk_color: Color = Color(0.4, 0.25, 0.12, 1.0)
@export var canopy_color: Color = Color(0.15, 0.55, 0.2, 1.0)
@export var canopy_radius: float = 22.0
@export var trunk_width: float = 8.0
@export var trunk_height: float = 16.0

func _ready() -> void:
	# Randomize appearance slightly
	var rand_scale = randf_range(0.8, 1.3)
	scale = Vector2(rand_scale, rand_scale)
	canopy_color = canopy_color.lightened(randf_range(-0.1, 0.15))

func _draw() -> void:
	# Draw trunk
	draw_rect(Rect2(-trunk_width / 2, -trunk_height, trunk_width, trunk_height), trunk_color)
	# Draw canopy (circle on top of trunk)
	draw_circle(Vector2(0, -trunk_height - canopy_radius * 0.5), canopy_radius, canopy_color)
	# Draw canopy highlight
	draw_circle(Vector2(-3, -trunk_height - canopy_radius * 0.5 - 3), canopy_radius * 0.6, canopy_color.lightened(0.2))
