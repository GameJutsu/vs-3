# 🗺️ Project Nova Swarm — Implementation Plan

This document outlines the refactoring phases and steps to transform the current codebase into **Project Nova Swarm**, aligning with the updated GDD.

---

## 🛠️ Phase 1: Core Architecture & Input Refactor

### 1. `GlobalStats` Autoload Singleton
* **File:** `res://scripts/global_stats.gd`
* **Purpose:** Dictates global math applied to both the player's weapons and companions.
* **Fields:**
  * `global_projectiles` (int, default = 1)
  * `global_fire_rate_mult` (float, default = 1.0)
  * `global_aoe_radius` (float, default = 1.0)
  * `global_velocity_mult` (float, default = 1.0)

### 2. "The Deadzone Tether" Input Controller
* **File:** `res://entities/player/player.gd`
* **Behavior:**
  * Define `deadzone_radius = 50.0` around player.
  * Query mouse position relative to player.
  * If mouse is *inside* radius: stop player movement (`velocity = Vector2.ZERO`), rotate sprite to face mouse cursor.
  * If mouse is *outside* radius: move toward cursor using `move_and_slide()` at player speed.

### 3. Action Mapping
* **LMB:** Triggers the player's active weapon (Maglev Cube or Deck).
* **RMB:** Swaps active companion to the next in the roster (cycles slots 0 → 1 → 2).
* **Swap Cooldown:** Introduce a 1.5-second timer blocking rapid swaps.

---

## 🐾 Phase 2: Roster Manager & Companion Systems

### 1. Roster Manager
* **Location:** Node attached to player or world.
* **Responsibility:** Holds an `Array[Companion]` of size 3. Instantiates the active companion and handles pausing/hiding inactive ones.

### 2. Companion Pokémon (Gen 1 & 2)

#### Rattata → Raticate
* **Rattata:** Dashes to bite. Has a magnet shape that draws in XP gems and pulls them to the player.
* **Raticate (Evolved):** Bites apply a ticking Bleed status (10 damage/sec for 3s). Magnet radius doubled.

#### Zubat → Golbat
* **Zubat:** Fires a continuous health-draining beam at nearest enemy, restoring 2% of damage dealt back to player.
* **Golbat (Evolved):** Draining beam chains to up to 2 additional nearby targets (lightning chain style).

#### Staryu → Starmie
* **Staryu:** Orbits player at a radius dictated by `follow_distance`, firing water bullets outward. Orbit speed scales with `global_velocity_mult`.
* **Starmie (Evolved):** Replaces water bullets with a continuous, sweeping laser beam.

#### Geodude → Graveler
* **Geodude:** Slow, heavy body. Lunges at enemies and delivers high-knockback punches.
* **Graveler (Evolved):** Punches release localized shockwave earthquakes (`global_aoe_radius`) that slow enemy movement by 40% for 2 seconds.

#### Pikachu → Raichu
* **Pikachu:** Calls down random lightning bolts around the player.
* **Raichu (Evolved):** Lightning strikes leave behind static shock hazard zones on the floor for 3 seconds.

---

## ⚔️ Phase 3: Character Selection & Weapon Systems

### 1. Main Menu Expansion
* Add character choice selection buttons to `main_menu.tscn`:
  * **Vaibhav:** Spawns player configured with the **Maglev Cube**.
  * **Rishu:** Spawns player configured with **The Deck**.

### 2. Vaibhav's Weapon: The Maglev Cube
* **Behavior:** 
  * Holds `LMB` to "solve" the cube (wind-up animation scaling with `global_fire_rate_mult`).
  * Once solved, it detaches and rockets toward the nearest enemy.
  * Detonates on impact dealing heavy damage in an area (`global_aoe_radius`).
  * Returns to player in scrambled state.

### 3. Rishu's Weapon: The Deck
* **Behavior:**
  * Holding `LMB` rapid-fires cards (spread scales with `global_projectiles`).
  * Alternates colors:
    * **Red cards:** Pierce through enemies.
    * **Black cards:** Orbit the player as a shield for 1s before firing outward.

---

## 🧪 Phase 4: Upgrade Pool & Evolution Engine

### 1. Upgrade Pool Refactor
* Refactor `UpgradeResource` to support:
  * Global stats modifiers (adds to `GlobalStats` singleton).
  * Companion-specific upgrades (e.g., "Pikachu Attack Speed").

### 2. Evolution Engine
* Track the count of companion-specific upgrades selected.
* When a companion reaches exactly **2 specific upgrades**, trigger the evolution:
  * Play an evolutionary flash & fanfare sound.
  * Delete base companion node, instantiate evolved companion node in its place.
