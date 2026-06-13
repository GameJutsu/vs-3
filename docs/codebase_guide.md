# 📖 Tactical Tag-Team Survivor — Codebase Reference Guide

Welcome to the codebase guide. This document explains the complete architectural design, game mechanics, and data flow of the project in simple, exhaustive terms. It contains no raw code, making it the perfect starting point for understanding how the systems interact and behave.

---

## 1. Core Gameplay Loop

The game is a movement-based horde survival game featuring a unique combination of character collection, character swapping, and global upgrades. 

1. **Survival**: The player survives a 5-minute countdown against an escalating swarm of variant enemies.
2. **Escalation**: As time passes, the spawn rates, speeds, and types of enemies change dynamically.
3. **Loot Collection**: Defeated enemies drop experience gems that are magnetized toward the player.
4. **Tactical Pause & Upgrade**: Filling the experience bar triggers a level-up, pausing the game and prompting the player to choose from a randomized pool of upgrades.
5. **Climax Boss**: At the end of the timer, a massive boss spawn triggers. Defeating this boss wins the game.

---

## 2. Character & Input Architecture

### Movement (The Deadzone Tether)
Player movement is mouse-driven to allow for clean accessibility and precise positioning:
* **The Deadzone**: A circular boundary centered on the player. If the mouse cursor is inside this boundary, the player remains stationary but rotates to face the cursor.
* **Movement Chase**: If the cursor is outside the boundary, the player accelerates toward the cursor.
* **Juice Feedback**: When the player starts moving, the sprite stretches dynamically along the vector of motion. When the player stops, the sprite squashes flat before easing back to its default proportions.

### Weapons (Character Archetypes)
The player select choice dictates the active weapon system:
1. **Vaibhav (Maglev Cube)**: A heavy-ordnance weapon. Holding the fire button "solves" the cube, scaling with attack speed modifiers. Once solved, it detaches and launch-detonates in an area before returning to the player.
2. **Rishu (Playing Cards)**: A high-rate-of-fire weapon. Rapidly shoots cards. Red cards pierce through target chains, while black cards orbit the player as a temporary defensive shield before flying outward.

---

## 3. Companion & Evolution Engine

Companions are autonomous helper entities tethered to the player. Up to three companions can be held in the active roster at any time.

### Companion AI States (Finite State Machine)
All companions implement standard kinematics and switch between two primary states:
1. **FOLLOW**: The companion trails the player, staying within a leash distance. If too close, a soft separation force pushes them away to prevent overlap.
2. **ATTACK**: Triggered when an enemy enters the companion's aggro radius. The companion rockets toward the target, deals damage, and returns to the leash.

### Evolution Engine
Each companion has a base form (such as Pikachu, Rattata, Zubat, Geodude, or Staryu).
* When a player selects a companion-specific upgrade card twice, the evolution engine is triggered.
* An evolution flash overlays the screen, a level-up fanfare sound plays, and the base companion scene is deleted.
* The evolved companion scene (such as Raichu, Raticate, Golbat, Graveler, or Starmie) is instantiated in its place, carrying over all upgrades and activating new, advanced mechanics (like bleeding status effects, chained beam tethers, orbital lasers, shockwave slows, or ground hazard zones).

---

## 4. Decoupled Event & UI Architecture

To ensure the codebase is clean, modular, and easy for multiple developers to edit, the game is built on a **fully decoupled event-driven architecture**:

```text
[Game Entities] ───(Emit Signals)───> [EventBus / Player] ───> [HUDController] ───> [UI Elements]
```

### The EventBus (Global Messaging)
A central global dispatcher that relays game-wide actions without requiring nodes to search for parent paths:
* **Float Text requests**: Spawns damage numbers or alert texts at specific coordinates in the world.
* **Camera Shake requests**: Triggers screen shake with trauma decay.
* **Enemy Deaths**: Alerts systems that an enemy has died, updating kill counts and triggering item drops.

### The HUD Controller (UI Boundary)
The player does not access UI nodes. Instead, the player script emits signals when health, experience, kills, active companion, or stats change.
* A dedicated HUD script attached to the UI CanvasLayer connects to these player signals.
* It formats the variables and updates progress bars, screen overlays (game over, victory), and labels.
* It handles button clicks, scene reloading, and menu navigation directly.

---

## 5. Wave escalations & Spawning

Spawning is managed by a Wave Director:
* **Escalation Profiles**: Spawns are controlled by difficulty tiers. As the timer counts down, spawners rotate through enemy pools.
* **Spawn Zones**: Enemies spawn in a circular ring just outside the player's screen view, preventing them from appearing out of thin air.
* **Boss Event**: When the boss spawns, regular enemy spawning halts, and a dedicated boss health bar is displayed on the HUD.

---

## 6. Sound & Asset Management

* **Sound Pool**: The sound manager maintains a pool of audio players to play sound effects concurrently (polyphony) without clipping.
* **Dynamic Sprites**: Companions programmatically load their textures using their identifier strings, scaling them dynamically to fit a standard boundary box. This allows developers to add new companions by dropping PNG files into the sprites folder.
