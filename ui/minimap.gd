extends Control
## Minimap Display — Overlay showing player, enemies, and companion positions
class_name MinimapDisplay

@export var map_half_size: float = 2000.0
@export var display_size: float = 140.0
var player_ref: Node2D = null

func _ready() -> void:
	custom_minimum_size = Vector2(display_size + 10, display_size + 10)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var center = Vector2(display_size / 2 + 5, display_size / 2 + 5)
	var half = display_size / 2.0

	# Background
	draw_rect(Rect2(5, 5, display_size, display_size), Color(0.05, 0.08, 0.05, 0.6))
	# Border
	draw_rect(Rect2(5, 5, display_size, display_size), Color(0.3, 0.5, 0.3, 0.8), false, 2.0)

	# Draw entities as dots
	if player_ref != null and is_instance_valid(player_ref):
		var player_dot = _world_to_minimap(player_ref.global_position, center, half)
		draw_circle(player_dot, 4.0, Color(1, 1, 1, 1))

	# Enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dot = _world_to_minimap(enemy.global_position, center, half)
			if _in_minimap_bounds(dot):
				draw_circle(dot, 2.0, Color(1, 0.2, 0.2, 0.7))

	# Companions
	var companions = get_tree().get_nodes_in_group("companions")
	for comp in companions:
		if is_instance_valid(comp):
			var dot = _world_to_minimap(comp.global_position, center, half)
			if _in_minimap_bounds(dot):
				draw_circle(dot, 3.0, Color(0.3, 0.6, 1.0, 0.9))

func _world_to_minimap(world_pos: Vector2, center: Vector2, half: float) -> Vector2:
	var normalized = world_pos / map_half_size  # -1 to 1 range
	return center + normalized * half

func _in_minimap_bounds(pos: Vector2) -> bool:
	return pos.x >= 5 and pos.x <= 5 + display_size and pos.y >= 5 and pos.y <= 5 + display_size
