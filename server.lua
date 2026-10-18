-- Whitelist as a lookup table for fast checks: allowed['sultan'] == true
local allowed = {}
for _, name in ipairs(Config.models) do
    allowed[name] = true
end

local lastSpawn = {}  -- [source] = time of the last spawn (ms)
local playerCar = {}  -- [source] = the vehicle this player spawned last

-- Shared spawn logic, used by both the /mycar command and the NUI window
local function spawnVehicle(src, model)
    -- 1. Only models from the whitelist
    if not allowed[model] then
        lib.notify(src, { type = 'error', description = 'Model not allowed: ' .. model })
        return
    end

    -- 2. Spam protection
    local now = GetGameTimer()
    if lastSpawn[src] and now - lastSpawn[src] < Config.cooldown * 1000 then
        lib.notify(src, { type = 'error', description = 'Wait a few seconds' })
        return
    end

    -- 3. The player must exist and must not already be inside a vehicle
    local ped = GetPlayerPed(src)
    if ped == 0 or GetVehiclePedIsIn(ped, false) ~= 0 then
        lib.notify(src, { type = 'error', description = 'Cannot spawn right now' })
        return
    end
    lastSpawn[src] = now

    -- 4. Limit: one vehicle per player, the previous one is deleted
    local old = playerCar[src]
    if old and DoesEntityExist(old) then
        DeleteEntity(old)
    end

    -- 5. The server creates the vehicle, so there is no client sync race
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local vehicle = CreateVehicleServerSetter(joaat(model), 'automobile', coords.x, coords.y, coords.z, heading)

    local tries = 0
    while not DoesEntityExist(vehicle) and tries < 20 do
        Wait(50)
        tries += 1
    end
    if not DoesEntityExist(vehicle) then
        lib.notify(src, { type = 'error', description = 'Spawn failed' })
        return
    end
    playerCar[src] = vehicle

    -- 6. Seat the player and hand out the keys
    TriggerClientEvent('garage_nui:enterVehicle', src, NetworkGetNetworkIdFromEntity(vehicle))
    exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true)
    lib.notify(src, { type = 'success', description = 'Spawned with keys: ' .. model })
end

lib.addCommand('mycar', {
    help = 'Spawn a vehicle with keys',
    params = {
        { name = 'model', type = 'string', help = 'Vehicle model', optional = true },
    },
    restricted = Config.permission, -- ox_lib checks the permission on the server
}, function(source, args)
    spawnVehicle(source, (args.model or Config.defaultModel):lower())
end)

-- Vehicle picked in the NUI window. The client is not trusted: permission and model are checked again
RegisterNetEvent('garage_nui:spawnFromMenu', function(model)
    local src = source
    if type(model) ~= 'string' then return end
    -- Config.permission is a group, and ox_lib grants it the command.mycar ace, so we check that one
    if not IsPlayerAceAllowed(src, 'command.mycar') then
        lib.notify(src, { type = 'error', description = 'No permission' })
        return
    end
    spawnVehicle(src, model:lower())
end)

-- Resource stopped or restarted: remove every vehicle we created
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, vehicle in pairs(playerCar) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
end)

-- ---------- Favorite vehicles (database) ----------

-- The table is created automatically on first start. The (character, model) key prevents duplicates
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS garage_nui_favorites (
            citizenid VARCHAR(50) NOT NULL,
            model VARCHAR(50) NOT NULL,
            PRIMARY KEY (citizenid, model)
        )
    ]])
end)

local function getCitizenId(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData.citizenid
end

local function getFavorites(citizenid)
    local rows = MySQL.query.await('SELECT model FROM garage_nui_favorites WHERE citizenid = ?', { citizenid })
    local list = {}
    for _, row in ipairs(rows or {}) do
        list[#list + 1] = row.model
    end
    return list
end

lib.callback.register('garage_nui:getFavorites', function(source)
    local citizenid = getCitizenId(source)
    if not citizenid then return {} end
    return getFavorites(citizenid)
end)

-- Add or remove a favorite. Returns the updated list
lib.callback.register('garage_nui:toggleFavorite', function(source, model)
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid or type(model) ~= 'string' then return {} end

    model = model:lower()
    if not allowed[model] then return getFavorites(citizenid) end -- whitelisted models only

    local exists = MySQL.scalar.await(
        'SELECT 1 FROM garage_nui_favorites WHERE citizenid = ? AND model = ?', { citizenid, model })
    if exists then
        MySQL.update.await('DELETE FROM garage_nui_favorites WHERE citizenid = ? AND model = ?', { citizenid, model })
    else
        MySQL.insert.await('INSERT INTO garage_nui_favorites (citizenid, model) VALUES (?, ?)', { citizenid, model })
    end
    return getFavorites(citizenid)
end)

-- Player left: clean up their data
AddEventHandler('playerDropped', function()
    lastSpawn[source] = nil
    playerCar[source] = nil
end)
