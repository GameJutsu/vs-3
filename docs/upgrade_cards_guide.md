# 🎴 Upgrade Cards & Tech Tree Guide

This reference documents all existing upgrade cards currently implemented in the game's tech trees, the level/roster unlocking rules that govern them, and a list of proposed new cards to expand gameplay variety for you and Rishu.

---

## 1. Existing Tech Tree Upgrades (Strict single-purchase pathways)

The tech tree is structured into 4 columns of 3 tiers. An upgrade is only offered if it has not been purchased yet and its parent node (if any) is owned.

### Column A: Agility
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `speed_boost` | **Swift Wings** | Adds +50 to base Player Speed |
| **Tier 2** | `upgrade_global_velocity` | **Tailwind** | Adds +30% to Global Velocity (projectiles, companions, orbits) |
| **Tier 3** | `buff_zubat` | **Echo-Location** | Doubles Zubat's continuous health-drain beam |

### Column B: Survivability
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `max_health` | **Iron Shell** | Adds +50 to Max Player HP |
| **Tier 2** | `heal` | **Nanite Pulse** | Restores +30 Player HP |
| **Tier 3** | `buff_geodude` | **Solid Rock** | Geodude punches deal knockback and slow enemies by 40% |

### Column C: Firepower
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `upgrade_global_fire_rate` | **Overcharge** | Adds +25% Global Fire Rate (weapons & companions) |
| **Tier 2** | `upgrade_global_projectiles` | **Split Fire** | Adds +1 Global Projectiles (more weapon cards & companion beams) |
| **Tier 3** | `buff_pikachu` | **Volt Tackle** | Pikachu calls down chain-lightning strikes |

### Column D: Space
| Tier | Upgrade ID | Card Title | Description / Effect |
|:---:|:---|:---|:---|
| **Tier 1** | `upgrade_global_aoe_radius` | **Expansion** | Adds +30% Global AoE Radius (blast sizes and tethers) |
| **Tier 2** | `attack_speed` | **Blitz Lunge** | Adds +15% Companion Speed / tracking leash responsiveness |
| **Tier 3** | `buff_staryu` | **Cosmic Star** | Staryu orbits 40% wider and shoots orbital sweeps |

---

## 2. Existing Non-Tree Upgrades

These cards do not belong to the standard tech columns and are offered randomly once their individual prerequisite gates are met:

### Companion Unlocks (Level 7+)
Unlocks the companion and adds them to the roster (cycles via RMB/Space/C). Only offered if the companion is not already unlocked.
*   `unlock_zubat` — **Unlock Zubat**
*   `unlock_staryu` — **Unlock Staryu**
*   `unlock_geodude` — **Unlock Geodude**
*   `unlock_pikachu` — **Unlock Pikachu**

### Starter Buffs
*   `buff_rattata` — **Feral Instinct**: Increases Rattata's bite damage and doubles its XP magnetization pickup radius. Only offered if Rattata is in the roster.

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

*   **Vampiric Chime** (Agility Column Tier 4 - Requires *Echo-Location*)
    *   *Effect*: Evolved Golbat's draining beam chains to +2 additional enemies.
*   **Tectonic Quake** (Survivability Column Tier 4 - Requires *Solid Rock*)
    *   *Effect*: Evolved Graveler's earthquake shockwaves slow enemies by 60% and deal residual damage.
*   **Static Shock** (Firepower Column Tier 4 - Requires *Volt Tackle*)
    *   *Effect*: Evolved Raichu's lingering shock hazard zones on the floor last 6 seconds instead of 3.
*   **Nova Beam** (Space Column Tier 4 - Requires *Cosmic Star*)
    *   *Effect*: Evolved Starmie's sweeping orbital laser beam rotates 50% faster.

### C. Tactical Swap Upgrades
Synergizes with the tag-team active companion swapping mechanic:

*   **Entrance Burst**
    *   *Effect*: Swapping companion triggers a temporary +25% movement speed boost for the player for 1 second.
*   **Swap Shield**
    *   *Effect*: Triggers a brief 0.5-second invulnerability shield upon companion cycling.
