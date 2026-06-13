extends Node2D
## World Controller Script
## Orchestrates the main game loop: manages the survival timer countdown, handles
## game completion states (GameOver / Victory overlays), and delegates enemy spawning.

# --- MAP & ENVIRONMENT SETTINGS ---
const TREE_SCENE: PackedScene = preload("res://entities/environment/tree_obstacle.tscn")
@export var map_half_size: float = 2000.0  # Map goes from -2000 to +2000 on each axis
@export var tree_count: int = 40
@export var tree_min_distance_from_center: float = 300.0  # No trees near player spawn

# --- CHILD NODE REFERENCES ---
@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: HUDController = $CanvasLayer


# --- INTERNAL STATE ---
var time_remaining: float = 300.0   # 5-minute countdown (300 seconds)
var is_game_over: bool = false
var _boss_spawned: bool = false
var minimap: MinimapDisplay = null

# --- INITIALIZATION ---
func _ready() -> void:
	# Unpause the game tree in case we are restarting
	get_tree().paused = false
	
	# Dependency Injection: Tell the wave manager who the player is
	wave_manager.player = player
	
	# Initialize HUD connections to player
	hud.setup_connections(player)
	
	# Connect player death signal
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
		
	# Connect global EventBus events
	EventBus.float_text_requested.connect(_on_float_text_requested)
	
	# Phase 5: World boundaries, trees, and minimap
	_setup_map_boundaries()
	_scatter_trees()
	_setup_minimap()

# --- FRAME UPDATE ---
func _process(delta: float) -> void:
	if is_game_over:
		return
		
	# Update survival timer countdown
	time_remaining = maxf(time_remaining - delta, 0.0)
	var minutes: int = int(time_remaining) / 60
	var seconds: int = int(time_remaining) % 60
	hud.timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Update boss health bar if a boss is alive
	_update_boss_health_bar()
	
	# Clamp player inside boundaries (safety net)
	var margin = 20.0
	player.global_position.x = clampf(player.global_position.x, -map_half_size + margin, map_half_size - margin)
	player.global_position.y = clampf(player.global_position.y, -map_half_size + margin, map_half_size - margin)

# --- BOSS HEALTH BAR & VICTORY TRIGGER ---
# Scans the scene for any node in the "boss" group.
func _update_boss_health_bar() -> void:
	var bosses: Array[Node] = get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		_boss_spawned = true
		var boss: CharacterBody2D = bosses[0] as CharacterBody2D
		if boss != null and is_instance_valid(boss):
			hud.boss_health_bar.show()
			hud.boss_health_bar.max_value = boss.max_hp
			hud.boss_health_bar.value = boss.current_hp
		else:
			hud.boss_health_bar.hide()
	else:
		if hud.boss_health_bar.visible:
			hud.boss_health_bar.hide()
		# If the boss was spawned but is now gone, player has won!
		if _boss_spawned and not is_game_over:
			_on_victory()

# --- GAME OVER STATE ---
func _on_player_died() -> void:
	is_game_over = true
	get_tree().paused = true
	var time_survived: float = 300.0 - time_remaining
	hud.show_game_over(player.kill_count, time_survived)

# --- VICTORY STATE ---
func _on_victory() -> void:
	is_game_over = true
	get_tree().paused = true
	hud.show_victory(player.kill_count)


# --- MAP BOUNDARIES ---
func _setup_map_boundaries() -> void:
	# Create 4 invisible walls at the edges of the map
	var wall_data = [
		{"name": "WallTop", "pos": Vector2(0, -map_half_size), "size": Vector2(map_half_size * 2 + 100, 50)},
		{"name": "WallBottom", "pos": Vector2(0, map_half_size), "size": Vector2(map_half_size * 2 + 100, 50)},
		{"name": "WallLeft", "pos": Vector2(-map_half_size, 0), "size": Vector2(50, map_half_size * 2 + 100)},
		{"name": "WallRight", "pos": Vector2(map_half_size, 0), "size": Vector2(50, map_half_size * 2 + 100)},
	]
	for data in wall_data:
		var wall = StaticBody2D.new()
		wall.name = data["name"]
		wall.position = data["pos"]
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = data["size"]
		col.shape = shape
		wall.add_child(col)
		add_child(wall)

# --- GLOBAL EVENT BUS CALLBACKS ---
func _on_float_text_requested(text: String, pos: Vector2, color: Color) -> void:
	var label: Label = preload("res://ui/damage_number.tscn").instantiate()
	label.text = text
	label.modulate = color
	label.global_position = pos
	call_deferred("add_child", label)


func _draw() -> void:
	# Draw map border - visible boundary indicator
	var rect = Rect2(-map_half_size, -map_half_size, map_half_size * 2, map_half_size * 2)
	draw_rect(rect, Color(0.4, 0.15, 0.15, 0.6), false, 4.0)
	# Draw a subtle fill for the play area
	draw_rect(rect, Color(0.08, 0.1, 0.06, 0.15), true)

# --- TREE SCATTERING ---
func _scatter_trees() -> void:
	for i in range(tree_count):
		var pos = Vector2(
			randf_range(-map_half_size + 100, map_half_size - 100),
			randf_range(-map_half_size + 100, map_half_size - 100)
		)
		# Don't spawn trees near center where player starts
		if pos.length() < tree_min_distance_from_center:
			continue
		var tree = TREE_SCENE.instantiate()
		tree.global_position = pos
		add_child(tree)

# --- MINIMAP ---
func _setup_minimap() -> void:
	minimap = MinimapDisplay.new()
	minimap.map_half_size = map_half_size
	minimap.player_ref = player
	# Position in top-right corner
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -170
	minimap.offset_top = 45
	minimap.offset_right = -20
	minimap.offset_bottom = 195
	$CanvasLayer.add_child(minimap)
