# Changelog

All notable changes to this project are documented in this file. The project adheres to semantic versioning patterns based on feature stages.

---

## [v1.6.0] - 2026-06-13
### Added
- Expanded companion system in [creature.gd](file:///home/deck/Game%20Dev/vs3/vs-3/entities/creature/creature.gd) with 4 archetypes: Brawler (melee), Sniper (ranged), Orbiter (orbiting blades), and Healer (passive healing pulses).
- Implemented single-input tag-team cycling on [player.gd](file:///home/deck/Game%20Dev/vs3/vs-3/entities/player/player.gd) mapping to Right Mouse Click, Spacebar, or the C Key.
- Added 4 Swap Entrance Effects ("tactical nukes") when cycling companions: Brawler AoE stun blast, Sniper bullet nova, Orbiter rotation speed boost, and Healer burst heal.
- Added 3 new creature unlock `.tres` resource files to [data/upgrades/](file:///home/deck/Game%20Dev/vs3/vs-3/data/upgrades/) and integrated them into the random level-up card pool.
- Added a floating `CompanionLabel` HUD text readout in [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/scenes/world/world.tscn) showing the owned roster and active companion.
- Created Sniper projectile logic in [projectile.gd](file:///home/deck/Game%20Dev/vs3/vs-3/entities/creature/projectile.gd) and [projectile.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/entities/creature/projectile.tscn).

---

## [v1.5.0] - 2026-06-13
### Added
- Created a time-based [wave_manager.gd](file:///home/deck/Game%20Dev/vs3/vs-3/scripts/wave_manager.gd) supporting weighted random spawning, difficulty scaling, and boss encounters.
- Added 4 enemy variants (Sprinter, Tank, Splitter, Splitling) and 1 Boss (Gym Leader) scene to [entities/enemy/](file:///home/deck/Game%20Dev/vs3/vs-3/entities/enemy/).
- Added trauma-based screen shake in [camera_shake.gd](file:///home/deck/Game%20Dev/vs3/vs-3/scripts/camera_shake.gd).
- Implemented sprite hit flashing using [hit_flash.gdshader](file:///home/deck/Game%20Dev/vs3/vs-3/assets/shaders/hit_flash.gdshader).
- Implemented floating damage indicators using [damage_number.gd](file:///home/deck/Game%20Dev/vs3/vs-3/ui/damage_number.gd).
- Integrated `TimerLabel` (survival timer) and `BossHealthBar` UI elements into [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/scenes/world/world.tscn) and [world.gd](file:///home/deck/Game%20Dev/vs3/vs-3/scenes/world/world.gd).

### Refactored
- Swapped `SpawnTimer` with the new `WaveManager` in [world.tscn](file:///home/deck/Game%20Dev/vs3/vs-3/scenes/world/world.tscn).
- Updated [enemy.gd](file:///home/deck/Game%20Dev/vs3/vs-3/entities/enemy/enemy.gd) to support health variables, splitting mechanics on death, and hit flash/damage popups.
- Upgraded XP gem collection in [xp_gem.gd](file:///home/deck/Game%20Dev/vs3/vs-3/items/xp_gem/xp_gem.gd) with a scale-up pop and fade-out animation.

---

## [v1.4.0] - 2026-06-13
### Added
- Created resource class [upgrade_resource.gd](file:///home/deck/Game%20Dev/vs3/vs-3/scripts/upgrade_resource.gd) with custom upgrade types.
- Implemented choice-based level-up pause menu in [upgrade_menu.gd](file:///home/deck/Game%20Dev/vs3/vs-3/ui/upgrade_menu.gd) and [upgrade_card.gd](file:///home/deck/Game%20Dev/vs3/vs-3/ui/upgrade_card.gd).
- Wired player level-ups to trigger the selection menu and apply selected buffs in [player.gd](file:///home/deck/Game%20Dev/vs3/vs-3/entities/player/player.gd).

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
