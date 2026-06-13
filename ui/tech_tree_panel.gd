extends ColorRect
## Tech Tree Panel — Visualizes Upgrade Progression Trees
## Displays four columns: Agility, Survivability, Firepower, and Space.
## Color-codes nodes: Green (Owned), Yellow (Available/Unlocked), Gray (Locked).

const COL_WIDTH: float = 210.0
const ROW_HEIGHT: float = 75.0
const START_X: float = 80.0
const START_Y: float = 140.0
const COL_SEP: float = 50.0
const ROW_SEP: float = 65.0

var current_row_height: float = 75.0

# Define the columns and progression pathways
var columns = [
	{
		"name": "AGILITY",
		"upgrades": [
			{"id": "speed_boost", "title": "Swift Wings", "desc": "+50 Player Speed"},
			{"id": "upgrade_global_velocity", "title": "Tailwind", "desc": "+30% Global Velocity"},
			{"id": "buff_zubat", "title": "Echo-Location", "desc": "Zubat Projectile +1"}
		]
	},
	{
		"name": "SURVIVABILITY",
		"upgrades": [
			{"id": "max_health", "title": "Iron Shell", "desc": "+50 Max HP"},
			{"id": "heal", "title": "Nanite Pulse", "desc": "Restore +30 HP"},
			{"id": "buff_geodude", "title": "Solid Rock", "desc": "Geodude Defense Buff"}
		]
	},
	{
		"name": "FIREPOWER",
		"upgrades": [
			{"id": "upgrade_global_fire_rate", "title": "Overcharge", "desc": "+25% Fire Rate"},
			{"id": "upgrade_global_projectiles", "title": "Split Fire", "desc": "+1 Projectile"},
			{"id": "buff_pikachu", "title": "Volt Tackle", "desc": "Pikachu Bolt Chain +1"}
		]
	},
	{
		"name": "SPACE",
		"upgrades": [
			{"id": "upgrade_global_aoe_radius", "title": "Expansion", "desc": "+30% AoE Radius"},
			{"id": "attack_speed", "title": "Blitz Lunge", "desc": "+15% Companion Speed"},
			{"id": "buff_staryu", "title": "Cosmic Star", "desc": "Staryu AoE +40%"}
		]
	}
]

var node_positions: Dictionary = {} # Maps "col_row" to Vector2 positions for line drawing
var node_states: Dictionary = {}    # Maps "col_row" to state (0=locked, 1=available, 2=owned)

@onready var container: Control = Control.new()

func _ready() -> void:
	# Add container for nodes
	add_child(container)
	
	# Create header title
	var title = Label.new()
	title.text = "UPGRADE PROGRESSION TREES"
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchors_preset = 5 # Top Center
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_top = 35
	title.offset_left = -300
	title.offset_right = 300
	add_child(title)
	
	# Create subtitle
	var subtitle = Label.new()
	subtitle.text = "Plan your build. Unlock prerequisites to access stronger upgrades."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchors_preset = 5
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.offset_top = 75
	subtitle.offset_left = -300
	subtitle.offset_right = 300
	add_child(subtitle)

	# Create close button
	var close_btn = Button.new()
	close_btn.text = "[ Close Tech Trees ]"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
	close_btn.anchors_preset = 7 # Bottom Center
	close_btn.anchor_left = 0.5
	close_btn.anchor_top = 1.0
	close_btn.anchor_right = 0.5
	close_btn.anchor_bottom = 1.0
	close_btn.offset_bottom = -30
	close_btn.offset_left = -100
	close_btn.offset_right = 100
	close_btn.pressed.connect(hide)
	add_child(close_btn)

func open_tree() -> void:
	# 1. Clean up old node boxes
	for child in container.get_children():
		child.queue_free()
		
	node_positions.clear()
	node_states.clear()
	
	# 2. Query player owned upgrades
	var player = get_tree().current_scene.get_node_or_null("Player")
	var owned: Array[String] = []
	if player != null and "owned_upgrades" in player:
		owned = player.owned_upgrades
		
	# Calculate dynamic centering and scaling
	var col_width = COL_WIDTH
	var col_sep = COL_SEP
	var row_height = ROW_HEIGHT
	var row_sep = ROW_SEP
	
	var total_width = columns.size() * col_width + (columns.size() - 1) * col_sep
	
	# Fit viewport if size is smaller than tree width
	if size.x < total_width + 40:
		var ratio = (size.x - 40) / total_width
		col_width = col_width * ratio
		col_sep = col_sep * ratio
		row_height = row_height * ratio
		row_sep = row_sep * ratio
		total_width = size.x - 40
		
	current_row_height = row_height
	var start_x = (size.x - total_width) / 2.0
	var total_height = 3 * row_height + 2 * row_sep
	var start_y = (size.y - total_height) / 2.0 + 30.0 # offset for headers
	
	# 3. Build trees
	for c_idx in range(columns.size()):
		var col = columns[c_idx]
		
		# Draw Column Header Label
		var header = Label.new()
		header.text = col.name
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", clampf(14.0 * (col_width / COL_WIDTH), 10.0, 14.0))
		header.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0))
		header.position = Vector2(start_x + c_idx * (col_width + col_sep), start_y - 25)
		header.size = Vector2(col_width, 20)
		container.add_child(header)
		
		for r_idx in range(col.upgrades.size()):
			var upg = col.upgrades[r_idx]
			var state = 0 # 0 = Locked, 1 = Available, 2 = Owned
			
			# Check state
			if owned.has(upg.id):
				state = 2
			else:
				# Check if parent is owned
				if r_idx == 0:
					state = 1 # Tier 1 always available
				else:
					var parent_id = col.upgrades[r_idx - 1].id
					if owned.has(parent_id):
						state = 1 # Available if parent owned
					else:
						state = 0 # Locked if parent not owned
			
			var key = "%d_%d" % [c_idx, r_idx]
			node_states[key] = state
			
			# Create node container box
			var box = PanelContainer.new()
			box.size = Vector2(col_width, row_height)
			var pos = Vector2(start_x + c_idx * (col_width + col_sep), start_y + r_idx * (row_height + row_sep))
			box.position = pos
			
			# Store center position for line drawing
			node_positions[key] = pos + Vector2(col_width / 2.0, row_height / 2.0)
			
			# Style box flat
			var style = StyleBoxFlat.new()
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			
			# Color codes: Green (Owned), Yellow (Available), Dark Gray (Locked)
			match state:
				2: # OWNED (Green)
					style.bg_color = Color(0.04, 0.15, 0.06, 0.8)
					style.border_color = Color(0.2, 0.8, 0.3, 1.0)
				1: # AVAILABLE (Yellow)
					style.bg_color = Color(0.18, 0.15, 0.05, 0.8)
					style.border_color = Color(0.85, 0.75, 0.15, 1.0)
				0: # LOCKED (Gray)
					style.bg_color = Color(0.06, 0.06, 0.06, 0.8)
					style.border_color = Color(0.25, 0.25, 0.25, 1.0)
			
			box.add_theme_stylebox_override("panel", style)
			container.add_child(box)
			
			# VBox for text content
			var vbox = VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			box.add_child(vbox)
			
			# Title
			var title_lbl = Label.new()
			title_lbl.text = upg.title
			title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title_lbl.add_theme_font_size_override("font_size", 12)
			
			# Title text color
			match state:
				2: title_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6, 1.0))
				1: title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
				0: title_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
				
			vbox.add_child(title_lbl)
			
			# Description
			var desc_lbl = Label.new()
			desc_lbl.text = upg.desc
			desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			desc_lbl.add_theme_font_size_override("font_size", 10)
			desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0) if state > 0 else Color(0.4, 0.4, 0.4, 1.0))
			vbox.add_child(desc_lbl)
	
	show()
	queue_redraw()

func _draw() -> void:
	# Draw pathways connecting nodes in columns
	for c_idx in range(columns.size()):
		var col = columns[c_idx]
		for r_idx in range(col.upgrades.size() - 1):
			var key_from = "%d_%d" % [c_idx, r_idx]
			var key_to = "%d_%d" % [c_idx, r_idx + 1]
			
			if node_positions.has(key_from) and node_positions.has(key_to):
				var pos_from = node_positions[key_from] + Vector2(0, current_row_height / 2.0) # Bottom edge center
				var pos_to = node_positions[key_to] - Vector2(0, current_row_height / 2.0)    # Top edge center
				
				# Get connection state
				var state_to = node_states.get(key_to, 0)
				var line_color = Color(0.25, 0.25, 0.25, 1.0) # Gray line default
				var line_width = 2.0
				
				match state_to:
					2: # Target is owned (Green)
						line_color = Color(0.2, 0.8, 0.3, 0.8)
						line_width = 4.0
					1: # Target is available (Yellow)
						line_color = Color(0.85, 0.75, 0.15, 0.6)
						line_width = 3.0
						
				draw_line(pos_from, pos_to, line_color, line_width)
