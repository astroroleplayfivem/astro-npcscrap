# Astro NPC Scrap

## Version 2 Upgrade Notes

## Features

- Mini scrapyard NUI for scan, search, strip, torch, and finish actions

- NPC/local vehicle scrapping loop
- Blocks player-owned vehicles using the `player_vehicles` plate table
- Blacklists emergency/military/air/boat vehicle classes
- Search glovebox rewards
- Search trunk rewards
- Strip engine bay rewards
- Strip wheel/brake rewards
- Torch vehicle rewards with safe visual fire effects
- Clean strip vehicle rewards
- Part-out vehicle rewards
- Quick dump shell option
- Crush vehicle rewards
- Scrap grade scanner
- Scrapyard reputation and orders
- Recycling center trade-in system
- Heat system with police alert chance
- No player cooldown between tasks
- Vehicle-state protection to prevent farming the same vehicle repeatedly
- Configurable required tools
- Configurable rewards/chances
- Inventory bridge for `qb`, `qb-inventory`, `tgiann`, and `ox`
- `qb-target` and `ox_target` support with drawtext fallback

---

## Dependencies

Required:

```lua
qb-core
qb-menu
oxmysql
```

Optional:

```lua
qb-target
ox_target
qb-inventory
tgiann-inventory
ox_inventory
```

Compatibility config is left blank by default so the script can auto-detect what the server is using:

```lua
Config.Inventory = ''
Config.Interaction = ''
Config.TargetName = ''
```

You can also force options manually:

```lua
Config.Inventory = 'qb-inventory' -- qb, qb-inventory, tgiann, ox, auto, or blank
Config.Interaction = 'ox_target' -- qb-target, ox_target, drawtext, auto, or blank
```

---

## Install

1. Drop the folder into your resources:

```text
resources/[astro]/astro-npcscrap
```

2. Add this to `server.cfg`:

```cfg
ensure astro-npcscrap
```

3. Add the items below to your inventory item list.

4. Restart the server.

---
