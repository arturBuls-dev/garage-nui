Config = {
    -- 'auto' detects the running framework. Or set one: 'qbox', 'esx', 'qb', 'standalone'
    framework = 'auto',

    -- Who gives the player the keys of a spawned vehicle:
    -- 'auto'            qbx_vehiclekeys if it is running, otherwise none
    -- 'qbx_vehiclekeys' Qbox key system
    -- 'custom'          your own function below (for ESX key scripts, qb-vehiclekeys and so on)
    -- 'none'            do not hand out keys, the vehicle stays unlocked
    keys = 'auto',

    -- Used only when keys = 'custom'. Example for another script:
    -- giveKeys = function(src, vehicle) exports['your_keys']:Give(src, GetVehicleNumberPlateText(vehicle)) end,
    giveKeys = nil,

    -- Who may spawn vehicles (ace group)
    permission = 'group.admin',

    -- Minimum seconds between spawns for one player
    cooldown = 5,

    -- Model used when the player does not specify one
    defaultModel = 'adder',

    -- Whitelist: only these models can be spawned
    models = { 'adder', 'sultan', 'kuruma', 'comet2', 'buffalo', 'dominator' },
}
