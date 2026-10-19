-- Framework bridge: the only place that knows about Qbox, ESX or QBCore.
-- The rest of the resource calls Bridge.getIdentifier and Bridge.giveKeys and does not care which framework runs.

Bridge = {}

local function detectFramework()
    if Config.framework ~= 'auto' then return Config.framework end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    return 'standalone'
end

Bridge.framework = detectFramework()
print(('[garage-nui] framework: %s'):format(Bridge.framework))

local ESX, QBCore

if Bridge.framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Bridge.framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
end

--- Stable id of the player's character, used to store favorites per character.
---@param src number
---@return string?
function Bridge.getIdentifier(src)
    if Bridge.framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    elseif Bridge.framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier
    elseif Bridge.framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    end

    -- Standalone: fall back to the license of the player (one favorites list per account)
    return GetPlayerIdentifierByType(src, 'license')
end

--- Gives the player the keys of a vehicle.
--- ESX has no standard key script, so the key provider is chosen in config.lua.
---@param src number
---@param vehicle number server entity handle
function Bridge.giveKeys(src, vehicle)
    local provider = Config.keys

    if provider == 'auto' then
        provider = (GetResourceState('qbx_vehiclekeys') == 'started') and 'qbx_vehiclekeys' or 'none'
    end

    if provider == 'qbx_vehiclekeys' then
        exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true)
    elseif provider == 'custom' and type(Config.giveKeys) == 'function' then
        Config.giveKeys(src, vehicle)
    end
    -- 'none': vehicles spawned by this resource stay unlocked, nothing to hand out
end
