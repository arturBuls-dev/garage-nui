# garage-nui

A vehicle garage window for FiveM (Qbox), built with React + TypeScript, with a server-authoritative backend.

Players open a card-based menu, pick a vehicle, and the **server** spawns it, hands out the keys and seats the player. Favorite vehicles are stored in the database per character and shown first.

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

- [qbx_core](https://github.com/Qbox-project/qbx_core), [qbx_vehiclekeys](https://github.com/Qbox-project/qbx_vehiclekeys)
- [ox_lib](https://github.com/overextended/ox_lib), [oxmysql](https://github.com/overextended/oxmysql)
- Node.js (only to build the UI)

Developed and tested on Qbox with FiveM build 3258. There is no ESX or QBCore bridge yet.

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
    permission = 'group.admin',
    cooldown = 5,
    defaultModel = 'adder',
    models = { 'adder', 'sultan', 'kuruma', 'comet2', 'buffalo', 'dominator' },
}
```

To add a vehicle, put its model name into `models`, add `web/public/cars/<model>.webp`, and rebuild the UI.

## UI development

```
cd web
npm run dev
```

The page runs in a normal browser with sample data. Because the in-game browser behaves differently from desktop Chrome, always check the window in the game as well.

## License

All rights reserved. See [LICENSE](LICENSE).
