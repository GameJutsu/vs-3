extends Node
## Global Event Bus Autoload Singleton
## Decouples entity events from parent scenes, allowing any object to listen or dispatch globally.

signal enemy_died(enemy_node: CharacterBody2D, xp_value: int)
signal boss_health_changed(current_hp: int, max_hp: int)
signal boss_defeated()
signal camera_shake_requested(trauma_amount: float)
signal float_text_requested(text: String, position: Vector2, color: Color)
signal particle_burst_requested(type: String, position: Vector2, color: Color)
