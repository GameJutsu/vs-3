# Game Design Document (GDD): Project Nova Swarm

## 1. Project Philosophy & Scope
* **Core Loop:** Mouse-driven arena survival. The player manually fires a unique weapon while managing an active roster of autonomous companions (Pokémon).
* **The "Nova Drift" Rule:** Base stats are strictly global. A "+1 Projectile" upgrade applies to the player's weapon *and* every active Pokémon's ability simultaneously.
* **Evolution Ruleset:** Every Pokémon has a base form. Earning exactly 2 specific upgrades for that Pokémon triggers an Evolution, significantly altering its mechanics and base stats.
* **Visual Polish First:** All assets are currently greybox squares/shapes. Polish is achieved through game feel (screen shake, lerp easing, particle bursts) before any actual art is imported.

---

## 2. Core Architecture (Godot 4)

### The Source of Truth: `GlobalStats` (Autoload)
A globally accessible dictionary that dictates the math for the entire game. No hardcoded damage numbers exist in individual scenes.
* `global_projectiles`: Base 1
* `global_fire_rate_mult`: Base 1.0
* `global_aoe_radius`: Base 1.0
* `global_velocity_mult`: Base 1.0

### The Input Controller: "The Deadzone Tether"
* **Movement:** Entirely mouse-driven. 
* **The Deadzone:** A small invisible `Area2D` circle around the player. If the mouse cursor is *inside* this circle, the player stops moving and rotates to face the cursor.
* **The Chase:** If the cursor is *outside* the circle, the player moves toward the cursor using `move_and_slide()`.
* **Actions:** `LMB` triggers the Player Weapon. `RMB` retracts the current active Pokémon and deploys the next in the roster (subject to a `Timer` cooldown).

---

## 3. Playable Characters & Weapons

### Character 1: Vaibhav (The Mechanic)
* **Weapon: The Maglev Cube.** * **Behavior:** A floating square object. Holding `LMB` triggers a "solving" wind-up (scaled by `fire_rate`). Once solved, it detaches, rockets toward the nearest enemy, creates a localized blast (`aoe_radius`), and immediately returns to the player in a "scrambled" state.

### Character 2: Rishu (The Tactician)
* **Weapon: The Deck.**
* **Behavior:** Holding `LMB` rapid-fires cards. The cards cycle through suits (visualized by color). Red cards pierce (`global_projectiles` adds more cards per spread); Black cards orbit briefly as a defensive shield before firing outward.

---

## 4. The Starting Roster (Gen 1 & 2)
The player holds a maximum of 3 Pokémon. Switching has a tactical cooldown.

1.  **Rattata (The Scavenger / Melee)**
    * *Base:* Dashes to enemies to bite. Has an inherent `MagnetRadius` to fetch XP gems and bring them to the player.
    * *Evolution (Raticate):* Bites inflict a massive bleed stack, and its pickup radius doubles.
2.  **Zubat (The Vampire / Tether)**
    * *Base:* Latches a draining beam onto an enemy. Heals the player for a fraction of damage dealt. `global_projectiles` increases the number of simultaneous tethers.
    * *Evolution (Golbat):* Tethers now chain from the primary target to secondary nearby targets.
3.  **Staryu (The Orbital Shooter / Projectiles)**
    * *Base:* Orbits the player tightly. Fires water-bullets outward. `global_velocity_mult` dictates its orbit speed, effectively turning it into a physical shield if fast enough.
    * *Evolution (Starmie):* Projectiles are replaced by a continuous laser beam that sweeps the screen as it orbits.
4.  **Geodude (The Brawler / Kinetic)**
    * *Base:* Heavy physical weight. Punches enemies to create domino-effect knockbacks.
    * *Evolution (Graveler):* Every punch creates a localized earthquake (`aoe_radius`) that slows approaching enemies.
5.  **Pikachu (The Survivor / AoE Lightning)**
    * *Base:* Drops delayed lightning strikes randomly around the player's vicinity. `global_aoe_radius` makes the blast zones massive.
    * *Evolution (Raichu):* Lightning strikes leave behind electrified hazard zones that linger on the ground.

---

## 5. Development Roadmap for CLI Agent

### Phase 1: The Mouse Controller & Roster Manager
1. Implement the Mouse Deadzone movement logic in `player.gd`.
2. Build the `RosterManager` node to hold an Array of 3 active Pokémon scenes, handling the `RMB` swap logic and cooldown timer.

### Phase 2: Player Weapons & Global Stats
1. Create the `GlobalStats` autoload script.
2. Build the Rubik's Cube and Playing Card weapon systems, ensuring their timers and damage calculations query `GlobalStats` instead of local variables.

### Phase 3: The Upgrade Pool & Evolution Engine
1. Expand `UpgradeResource` to handle Base Stat upgrades (e.g., "+1 Projectile").
2. Implement a tracking dictionary in `player.gd` to count how many specific upgrades a Pokémon has received. Once the integer hits 2, `queue_free()` the base scene and instantiate the Evolution scene.