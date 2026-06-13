# 🛠️ Team Collaboration & Dev Workflows Guide

Welcome to the team developer guide. This document is a persistent instruction manual for **Vaibhav** and **Rishu** (and any AI coding assistants working in this repository). Following these workflows ensures a consistent, bug-free, and high-performance vibe-coding experience.

---

## 1. Branching & Git Workflow

To maintain code compilation safety and prevent merge conflicts, always use the following staging lifecycle:

1. **Staging Branch**: `dev` is the integration baseline. **Never commit directly to `main`**.
2. **Feature Branching**: Always create a feature branch off `dev`:
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feat/your-feature-name
   ```
3. **Local Compilation Check**: Before staging and committing any GDScript or TSCN changes, run Godot's headless editor compiler check to find any parse errors:
   ```bash
   /home/deck/Desktop/Godot_v4.6.3-stable_linux.x86_64 --headless --editor --quit
   ```
4. **Staging & Pushing**:
   ```bash
   git add .
   git commit -m "feat: descriptive commit message"
   git push vs-3 feat/your-feature-name
   ```
5. **Merge Pipeline**: Merge your feature branch back into `dev`, test the gameplay, and finally merge `dev` into `main` to deploy.

---

## 2. AI Coding & Architectural Conventions

All AI assistants (like Antigravity) must strictly follow these structural design rules:
1. **Decoupled HUD UI (Pillar A)**: The player and other gameplay entities must never directly modify UI nodes (e.g. progress bars, labels) or paths like `$"../CanvasLayer/HealthBar"`. Instead, they must emit state signals, and the `HUDController` on `CanvasLayer` will handle the rendering.
2. **Global Event Bus (Pillar B)**: Any node spawning floating text, triggering screenshakes, or notifying of deaths must emit signals via the `EventBus` autoload singleton (`scripts/event_bus.gd`) rather than calling `get_parent().add_child()`.
3. **Strict Static Typing**: Always declare type hints for variables, parameters, and return signatures (e.g. `var speed: float = 300.0`, `func heal(amount: int) -> void:`). This facilitates robust autocomplete in VS Code and prevents runtime bugs.

---

## 3. Cohesive Art Style Guide (Pokemon Gen 2 / GSC)

To maintain a consistent retro look across all visual assets, we use a dedicated **Generation 2 Game Boy Color (GSC)** pixel art style.

### The Unified Prompt Template
Use this prompt layout when generating any game sprite:
```text
Retro 8-bit pixel art sprite of [SUBJECT], pokemon gen 2 style, pokemon gold silver crystal gameboy color aesthetic, 56x56 resolution canvas, flat colors, clean dark outlines, isolated on a solid alpha transparent background, centered, full body standing pose, no background, highly detailed retro game asset.
```

### Size & Cohesion Standards
* **Boundary Box**: All sprite assets are generated on a `56x56` canvas to represent classic GSC dimensions.
* **Godot Importing & Scaling**:
  * Import sprites with the **Filter** set to **Nearest** (disable linear mipmaps) to keep pixels crisp.
  * In the sprite script, scale them dynamically to fit the target sizing boundary box:
    * **Player character (Vaibhav/Rishu)**: Tall and slim. Target size = `96x96` pixels (approx 1.5x standard height).
    * **Small Enemies**: Target size = `64x64` pixels (standard size).
    * **Tall/Elite Enemies**: Target size = `96x96` or `128x128` pixels (boss scale).
* **AI Tool Rule**: The AI assistant must present the generated prompt draft to the user and request confirmation *before* invoking the image generator to ensure complete control over the art direction.

---

## 4. Step-by-Step Workflow: How to Add a New Pokémon Companion

If you or Rishu want to introduce a new Pokémon helper:

### Step 4.1: Generate the Sprite
1. Write the GSC style prompt for the Pokémon (e.g. "zubat").
2. Ask for user confirmation.
3. Run the generator, verify transparency, and save it as `assets/sprites/creature_name.png`.

### Step 4.2: Write the Companion Script
Create `entities/creature/pokemon/creature_name.gd` inheriting `CompanionBase`:
```gdscript
extends CompanionBase

func _custom_ready() -> void:
	# Initialize unique variables, aggro ranges, or timers
	pass

func _custom_process(delta: float) -> void:
	# Companion unique logic (e.g. scanning for enemies or applying status effects)
	pass

func _custom_swap_in() -> void:
	# Swapping entrance nuke logic
	pass
```

### Step 4.3: Create the Scene File
Create `entities/creature/pokemon/creature_name.tscn` using this format:
```tscn
[gd_scene format=3]

[ext_resource type="Script" path="res://entities/creature/pokemon/creature_name.gd" id="1_script"]

[sub_resource type="CircleShape2D" id="CircleShape2D_col"]
radius = 20.0

[node name="CreatureName" type="Area2D"]
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_col")
```

### Step 4.4: Register the Companion in RosterManager
Edit `scripts/roster_manager.gd` and append the preloaded scene reference to the `SCENES` dictionary:
```gdscript
const SCENES: Dictionary = {
	...
	"creature_name": preload("res://entities/creature/pokemon/creature_name.tscn")
}
```

### Step 4.5: Add Upgrades to the Pools
1. Create two UpgradeResource files under `data/upgrades/` (e.g. `unlock_creature_name.tres` and `buff_creature_name.tres`).
2. Add these resources to the `upgrade_pool` array in `ui/upgrade_menu.gd`.
3. If they are part of the progression, map them in the `tree_columns` array in `upgrade_menu.gd` and the `columns` array in `tech_tree_panel.gd`.
