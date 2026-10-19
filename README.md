# garage-nui

A vehicle garage window for FiveM (Qbox, ESX and QBCore), built with React + TypeScript, with a server-authoritative backend.

Players open a card-based menu, pick a vehicle, and the **server** spawns it, hands out the keys and seats the player. Favorite vehicles are stored in the database per character and shown first.

https://github.com/user-attachments/assets/38794720-97bd-45f4-b5d7-ee6c385119f4

## Features

- Modern NUI built with React, Vite and TypeScript (animated cards, black and yellow theme).
- Server-side vehicle spawn (`CreateVehicleServerSetter`), keys through `qbx_vehiclekeys`.
- Favorites saved per character in MariaDB (table is created automatically).
- Everything important is validated on the server, never trusted from the client.
- Open config: allowed models, cooldown, permission group, default model.

## Security model

| Check | Where |
| --- | --- |
| Model must be in the whitelist | server |
| Permission is checked for every spawn request coming from the menu | server |
| Cooldown between spawns | server |
| Player must exist and not already be inside a vehicle | server |
| One vehicle per player, the previous one is deleted | server |
| All spawned vehicles are removed when the resource stops | server |
| SQL uses parameterized queries | server |

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib), [oxmysql](https://github.com/overextended/oxmysql)
- One framework, detected automatically: Qbox ([qbx_core](https://github.com/Qbox-project/qbx_core)), ESX (es_extended) or QBCore (qb-core). Without any of them it runs standalone.
- Keys: [qbx_vehiclekeys](https://github.com/Qbox-project/qbx_vehiclekeys) on Qbox, or your own key script through a small hook (see Configuration).
- Node.js (only to build the UI)

## Framework support

| Framework | Status |
| --- | --- |
| Qbox | Tested in game (FiveM build 3258) |
| ESX | Implemented, **not tested yet** |
| QBCore | Implemented, **not tested yet** |
| Standalone | Implemented, not tested yet (favorites are stored per account license) |

All framework specific code lives in `bridge/server.lua` (two functions: who is this player, and give the keys). Nothing else in the resource knows which framework is running.

## Installation

1. Copy this folder into your `resources` directory.
2. Build the UI:
   ```
   cd web
   npm install
   npm run build
   ```
3. Add one image per vehicle to `web/public/cars/<model>.webp` (for example `adder.webp`) **before** building. Images are not included in this repository. Cards without an image still work.
4. Add `ensure garage-nui` to your `server.cfg`.

## Commands

| Command | Description |
| --- | --- |
| `/cars` | Open the garage window (anyone can open it) |
| `/mycar [model]` | Spawn a vehicle directly |

Spawning, from the window or with `/mycar`, requires the group in `Config.permission` (default `group.admin`). The check runs on the server.

## Configuration

See [config.lua](config.lua).

```lua
Config = {
    framework = "auto",          -- or "qbox", "esx", "qb", "standalone"
    keys = "auto",               -- "qbx_vehiclekeys", "custom" or "none"
    giveKeys = nil,              -- function(src, vehicle) used when keys = "custom"
    permission = "group.admin",
    cooldown = 5,
    defaultModel = "adder",
    models = { "adder", "sultan", "kuruma", "comet2", "buffalo", "dominator" },
}
```

ESX has no standard key script. Use `keys = "custom"` and write the call of your own script in `giveKeys`, or `keys = "none"` to leave the spawned vehicle unlocked.

To add a vehicle, put its model name into `models`, add `web/public/cars/<model>.webp`, and rebuild the UI.

## UI development

```
cd web
npm run dev
```

The page runs in a normal browser with sample data. Because the in-game browser behaves differently from desktop Chrome, always check the window in the game as well.

## License

All rights reserved. See [LICENSE](LICENSE).
