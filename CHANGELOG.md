# Changelog

All notable changes to this project are documented in this file. The project adheres to semantic versioning patterns based on feature stages.

---

## [v1.3.0] - 2026-06-13
### Added
- Created [xp_gem.gd](file:///home/deck/Game%20Dev/vs3/vs-3/xp_gem.gd) and [xp_gem.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/xp_gem.tscn) files.
- Implemented magnet logic [magnetize_to](file:///home/deck/Game%20Dev/vs3/vs-3/xp_gem.gd#L25) to accelerate XP gems towards the player entity.
- Added a `MagnetRadius` collision area and a core `Hurtbox` to [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/world.tscn) under the Player node.
- Added player mechanics in [player.gd](file:///home/deck/Game%20Dev/vs3/vs-3/player.gd) to attract and collect gems via [_on_magnet_radius_area_entered](file:///home/deck/Game%20Dev/vs3/vs-3/player.gd#L46) and [_on_hurtbox_area_entered](file:///home/deck/Game%20Dev/vs3/vs-3/player.gd#L52).

### Refactored
- Refactored [enemy.gd](file:///home/deck/Game%20Dev/vs3/vs-3/enemy.gd) to replace direct queue freeing with a dedicated [die](file:///home/deck/Game%20Dev/vs3/vs-3/enemy.gd#L18) method.
- Updated creature attack collision interaction in [creature.gd](file:///home/deck/Game%20Dev/vs3/vs-3/creature.gd#L31) to invoke [die](file:///home/deck/Game%20Dev/vs3/vs-3/enemy.gd#L18).

---

## [v1.2.0] - 2026-06-13
### Added
- Added health system to [player.gd](file:///home/deck/Game%20Dev/vs3/vs-3/player.gd) supporting `max_health`, `current_health`, and damage handling functions.
- Integrated `HealthBar` and `XPBar` UI controls to [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/world.tscn) using a CanvasLayer GUI wrapper.
- Implemented [take_damage](file:///home/deck/Game%20Dev/vs3/vs-3/player.gd#L36) logic reload scene on player death.

---

## [v1.1.0] - 2026-06-13
### Added
- Created a finite state machine in [creature.gd](file:///home/deck/Game%20Dev/vs3/vs-3/creature.gd#L11) containing `FOLLOW` and `ATTACK` states.
- Implemented [_process](file:///home/deck/Game%20Dev/vs3/vs-3/creature.gd#L14) logic for chasing enemies and return-to-follow behaviors.
- Adjusted [creature.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/creature.tscn) and [enemy.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/enemy.tscn) scene files to use collision shapes and layers.

---

## [v1.0.0] - 2026-06-13
### Added
- Programmed [enemy.gd](file:///home/deck/Game%20Dev/vs3/vs-3/enemy.gd) physics loop to continuously chase the player.
- Created [world.gd](file:///home/deck/Game%20Dev/vs3/vs-3/world.gd) enemy spawn director using timer signals.
- Configured random radius spawn calculation logic inside [_on_spawn_timer_timeout](file:///home/deck/Game%20Dev/vs3/vs-3/world.gd#L15).

---

## [v0.2.0] - 2026-06-13
### Added
- Created helper companion scene [creature.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/creature.tscn).
- Programmed base player tracking functionality on [creature.gd](file:///home/deck/Game%20Dev/vs3/vs-3/creature.gd).
- Registered companion under [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/world.tscn) root.

---

## [v0.1.0] - 2026-06-13
### Added
- Initial project workspace files: `.editorconfig`, `.gitattributes`, `.gitignore`, and `project.godot`.
- Added standard Godot placeholder icon `icon.svg`.
- Created baseline player character physics script [player.gd](file:///home/deck/Game%20Dev/vs3/vs-3/player.gd) and arena scene template [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/world.tscn).
