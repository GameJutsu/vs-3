# 🎴 Upgrade Cards & Tech Tree Guide

This reference documents all existing upgrade cards currently implemented in the game's tech trees, the level/roster unlocking rules that govern them, and a list of proposed new cards to expand gameplay variety for you and Rishu.

---

## 1. Existing Tech Tree Upgrades (Strict single-purchase pathways)

The tech tree is structured into 4 columns of 3 tiers. An upgrade is only offered if it has not been purchased yet and its parent node (if any) is owned.

### Column A: Agility
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `speed_boost` | **Swift Wings** | Increases movement speed by 20%. Outrun the horde. |
| **Tier 2** | `upgrade_global_velocity` | **Kinetic Boost** | Increases global projectile speed and companion velocity by 25%. |
| **Tier 3** | `buff_zubat` | **Vampiric Drain** | Increases Zubat/Golbat's lifesteal rate and damage by 40%. Accumulating 2 specific Zubat upgrades triggers EVOLUTION. |

### Column B: Survivability
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `max_health` | **Iron Constitution** | Permanently raises max HP by 25. Build an unstoppable tank. |
| **Tier 2** | `heal` | **Healing Pulse** | Restores 30 HP instantly. Survive another wave. |
| **Tier 3** | `buff_geodude` | **Tectonic Slam** | Increases Geodude/Graveler's punching damage by 40%. Accumulating 2 specific Geodude upgrades triggers EVOLUTION. |

### Column C: Firepower
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `upgrade_global_fire_rate` | **Overclock** | Increases global fire rate by 35%. Faster weapons and faster companion attacks. |
| **Tier 2** | `upgrade_global_projectiles` | **Split Core** | Adds +1 to global projectiles. Multiplies weapon output and companion count. |
| **Tier 3** | `buff_pikachu` | **Static Spark** | Increases Pikachu/Raichu's lightning damage by 40%. Accumulating 2 specific Pikachu upgrades triggers EVOLUTION. |

### Column D: Space
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `upgrade_global_aoe_radius` | **Nova Expansion** | Increases global area-of-effect radius by 30%. Larger explosions and shockwaves. |
| **Tier 2** | `attack_speed` | **Feral Instinct** | Your companion attacks 30% faster. Shred through the swarm. |
| **Tier 3** | `buff_staryu` | **Hydro Turbine** | Increases Staryu/Starmie's water-projectile/laser damage by 40%. Accumulating 2 specific Staryu upgrades triggers EVOLUTION. |

---

## 2. Existing Non-Tree Upgrades

These cards do not belong to the standard tech columns and are offered randomly once their individual prerequisite gates are met:

### Companion Unlocks (Level 7+)
Unlocks the companion and adds them to the roster (cycles via RMB/Space/C). Only offered if the companion is not already unlocked.
*   `unlock_zubat` — **Summon Zubat** (Unlocks the Zubat companion. Latches health-draining tethers onto nearby enemies.)
*   `unlock_staryu` — **Summon Staryu** (Unlocks the Staryu companion. Orbits you tightly and fires water bullets outward.)
*   `unlock_geodude` — **Summon Geodude** (Unlocks the Geodude companion. Heavy-hitting punches with large domino knockbacks.)
*   `unlock_pikachu` — **Summon Pikachu** (Unlocks the Pikachu companion. Calls down delayed lightning strikes on random enemies.)

### Starter Buffs
*   `buff_rattata` — **Fierce Fangs**: Increases Rattata/Raticate's bite damage by 40%. Accumulating 2 specific Rattata upgrades triggers EVOLUTION. Only offered if Rattata is in the roster.

---

## 3. Proposed New Upgrade Cards (Future Expansion)

To expand build variety and offer weapon/character-specific choices, we can implement the following cards:

### A. Weapon-Specific Upgrades (Character Gated)
These cards are only offered if the player is running a specific character:

*   **Maglev Overclock** (Vaibhav-only)
    *   *Effect*: Speeds up the solving wind-up speed of the Maglev Cube by 40%.
*   **Card Sharp** (Rishu-only)
    *   *Effect*: Cards gain +1 pierce limit, allowing red cards to rip through larger groups.
*   **Deck Buffer** (Rishu-only)
    *   *Effect*: Black defensive cards orbit the player for an additional 1.5 seconds before launching outward.

### B. Tier 4 Tech Tree Extensions (Evolution Enhancements)
Allows further customization after evolving a companion:

*   **Vampiric Chime** (Agility Column Tier 4 - Requires *Vampiric Drain*)
    *   *Effect*: Evolved Golbat's draining beam chains to +2 additional enemies.
*   **Tectonic Quake** (Survivability Column Tier 4 - Requires *Tectonic Slam*)
    *   *Effect*: Evolved Graveler's earthquake shockwaves slow enemies by 60% and deal residual damage.
*   **Static Shock** (Firepower Column Tier 4 - Requires *Static Spark*)
    *   *Effect*: Evolved Raichu's lingering shock hazard zones on the floor last 6 seconds instead of 3.
*   **Nova Beam** (Space Column Tier 4 - Requires *Hydro Turbine*)
    *   *Effect*: Evolved Starmie's sweeping orbital laser beam rotates 50% faster.

### C. Tactical Swap Upgrades
Synergizes with the tag-team active companion swapping mechanic:

*   **Entrance Burst**
    *   *Effect*: Swapping companion triggers a temporary +25% movement speed boost for the player for 1 second.
*   **Swap Shield**
    *   *Effect*: Triggers a brief 0.5-second invulnerability shield upon companion cycling.
