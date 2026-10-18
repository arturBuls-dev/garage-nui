-- The server created the vehicle and asks us to get in
RegisterNetEvent('garage_nui:enterVehicle', function(netId)
    -- Wait up to 5 seconds for the vehicle to appear on this client
    local vehicle = lib.waitFor(function()
        if NetworkDoesNetworkIdExist(netId) then
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh ~= 0 and DoesEntityExist(veh) then
                return veh
            end
        end
    end, 'vehicle did not load', 5000)

    SetPedIntoVehicle(cache.ped, vehicle, -1)
end)

-- Open or close the NUI window (the mouse cursor is enabled through SetNuiFocus)
local function setMenu(open)
    if open then
        -- First ask the server for this character's favorite vehicles
        local favorites = lib.callback.await('garage_nui:getFavorites', false) or {}
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', cars = Config.models, favorites = favorites })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end
end

-- The window asks to add or remove a favorite: the server decides and stores it (database)
RegisterNUICallback('favorite', function(data, cb)
    local favorites = lib.callback.await('garage_nui:toggleFavorite', false, data.model)
    cb(favorites or {})
end)

RegisterCommand('cars', function()
    setMenu(true)
end, false)

-- The window sent the chosen vehicle. The server decides, we only pass the model along
RegisterNUICallback('spawn', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('garage_nui:spawnFromMenu', data.model)
    cb({})
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- If the resource restarts while the window is open, give control back to the player
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
