local reputation = {}
local CACHE = {}
local IDENTIFIERS = {}

local config = require 'config.server'

function reputation.CheckSaveState(citizenid)
    if config.saveInterval == 0 then
        reputation.SavePlayerRep(citizenid)
        config.debug('CheckSaveState 1', 'Save Interval push ' .. citizenid)
        return
    end

    if CACHE[citizenid].lastSaved then
        if CACHE[citizenid].lastSaved + config.saveInterval <= os.time() then
            reputation.SavePlayerRep(citizenid)
            config.debug('CheckSaveState 2', 'Save Interval push ' .. citizenid)
        end
    else
        CACHE[citizenid].lastSaved = os.time()
        reputation.SavePlayerRep(citizenid)
        config.debug('CheckSaveState 3', 'Save Interval push ' .. citizenid)
    end
end

function reputation.GetPlayerRep(citizenid)
    local rep = MySQL.single.await("SELECT reputation FROM group_rep WHERE citizenid = ? LIMIT 1", { citizenid })
    if not rep then
        return {}
    else
        return json.decode(rep.reputation)
    end
end

function reputation.SavePlayerRep(citizenid)
    MySQL.Async.execute("INSERT INTO group_rep (citizenid, reputation) VALUES (@citizenid, @reputation) ON DUPLICATE KEY UPDATE reputation = @reputation", {
        ['@citizenid'] = citizenid,
        ['@reputation'] = json.encode(CACHE[citizenid].reputations),
    })
    lib.logger(0, 'SavePlayerRep', ('Saved rep for CID: %s'):format(citizenid))
    config.debug('CheckSaveState', 'Saved reputation for ' .. citizenid)
end

function reputation.GetAllRep(citizenid)
    if CACHE[citizenid] then
        return CACHE[citizenid].reputations
    else
        CACHE[citizenid] = {}
        CACHE[citizenid].lastSaved = os.time()
        CACHE[citizenid].reputations = reputation.GetPlayerRep(citizenid)
        return CACHE[citizenid].reputations
    end
end

function reputation.GetRep(citizenid, name)
    if CACHE[citizenid] then
        if CACHE[citizenid].reputations[name] then
            return CACHE[citizenid].reputations[name]
        else
            reputation.SetRep(citizenid, name, 0)
            return CACHE[citizenid].reputations[name]
        end
    else
        local rep = reputation.GetPlayerRep(citizenid)
        if rep then
            CACHE[citizenid] = rep
            if CACHE[citizenid].reputations[name] then
                return CACHE[citizenid].reputations[name]
            else
                reputation.SetRep(citizenid, name, 0)
                return CACHE[citizenid].reputations[name]
            end
        else
            reputation.SetRep(citizenid, name, 0)
            return CACHE[citizenid].reputations[name]
        end
    end
end

function reputation.SetRep(citizenid, name, value)
    config.debug('SetRep 1', 'Request set reputation for ' .. citizenid .. ' to ' .. value .. ' for ' .. name)
    if CACHE[citizenid] then
        CACHE[citizenid].reputations[name] = value
        config.debug('SetRep 2', 'Check save reputation for ' .. citizenid .. ' to ' .. value .. ' for ' .. name)
        reputation.CheckSaveState(citizenid)
    else
        local rep = reputation.GetPlayerRep(citizenid)
        if rep.reputations then
            CACHE[citizenid] = rep
            CACHE[citizenid].reputations[name] = value
            config.debug('SetRep 3', 'Check save  reputation for ' .. citizenid .. ' to ' .. value .. ' for ' .. name)
            reputation.CheckSaveState(citizenid)
        else
            CACHE[citizenid] = {}
            CACHE[citizenid].reputations = {}
            CACHE[citizenid].reputations[name] = value
            CACHE[citizenid].lastSaved = os.time()
            config.debug('SetRep 4', 'Force saved reputation for ' .. citizenid .. ' to ' .. value .. ' for ' .. name)
            reputation.SavePlayerRep(citizenid)
        end
    end
    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        TriggerClientEvent('reputation:client:update', target.PlayerData.source, CACHE[citizenid].reputations)
    end
end

function reputation.AddRep(citizenid, name, value, limit)
    config.debug('AddRep 1', 'Request add of ' .. value .. ' reputation from ' .. citizenid .. ' for ' .. name)
    if CACHE[citizenid] then
        CACHE[citizenid].reputations[name] = CACHE[citizenid].reputations[name] or 0
        local amount = CACHE[citizenid].reputations[name] += value

        if limit and amount >= limit then
            amount = limit
        end

        config.debug('AddRep 2', 'Request add of ' .. value .. ' reputation from ' .. citizenid .. ' for ' .. name)
        reputation.SetRep(citizenid, name, amount)
    else
        local rep = reputation.GetPlayerRep(citizenid)
        CACHE[citizenid] = {}
        CACHE[citizenid].reputations = {}
        if rep then
            CACHE[citizenid].reputations = rep
            CACHE[citizenid].reputations[name] = CACHE[citizenid].reputations[name] or 0
            local amount = CACHE[citizenid].reputations[name] += value

            if limit and amount >= limit then
                amount = limit
            end
            
            config.debug('AddRep 3', 'Request add of ' .. value .. ' reputation from ' .. citizenid .. ' for ' .. name)
            reputation.SetRep(citizenid, name, amount)
        else
            config.debug('AddRep 4', 'Request add of 0 reputation from ' .. citizenid .. ' for ' .. name)
            reputation.SetRep(citizenid, name, 0)
        end
    end
end

function reputation.AddMultipleRep(citizenid, reputations)
    for name, value in pairs(reputations) do
        reputation.AddRep(citizenid, name, value)
    end
end

function reputation.RemoveRep(citizenid, name, value)
    if CACHE[citizenid] then
        CACHE[citizenid].reputations[name] = CACHE[citizenid].reputations[name] or 0
        local amount = CACHE[citizenid].reputations[name] -= value
        if amount < 0 then amount = 0 end
        config.debug('RemoveRep 1', 'Request removal of ' .. value .. ' reputation from ' .. citizenid .. ' for ' .. name)
        reputation.SetRep(citizenid, name, amount)
    else
        local rep = reputation.GetPlayerRep(citizenid)
        CACHE[citizenid] = {}
        CACHE[citizenid].reputations = {}
        if rep then
            CACHE[citizenid].reputations[name] = CACHE[citizenid].reputations[name] or 0
            local amount = CACHE[citizenid].reputations[name] -= value
            if amount < 0 then amount = 0 end
            config.debug('RemoveRep 2', 'Request removal of ' .. value .. ' reputation from ' .. citizenid .. ' for ' .. name)
            reputation.SetRep(citizenid, name, amount)
        else
            config.debug('RemoveRep 3', 'Setting reputation for ' .. citizenid .. ' to 0 for ' .. name)
            reputation.SetRep(citizenid, name, 0)
        end
    end
end

function reputation.RemoveMultipleRep(citizenid, reputations)
    for name, value in pairs(reputations) do
        reputation.RemoveRep(citizenid, name, value)
    end
end


---@param data table
function reputation.AddBoost(data)

    if not config.enableBoosts then return end

    if not data then return print('No data') end
    if not data.type then return end
    local boostType = data.type

    

end

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    local src = source
    local citizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid
    local rep = reputation.GetAllRep(citizenid)
    IDENTIFIERS[src] = citizenid
end)

AddEventHandler('playerDropped', function()
    local src = source
    if IDENTIFIERS[src] then
        reputation.SavePlayerRep(IDENTIFIERS[src])
    end
end)

AddEventHandler('onResourceStart', function(name)
    if name ~= GetCurrentResourceName() then return end
    local players = GetPlayers()

    for _, player in pairs(players) do
        local citizenid = config.getPlayerCID(tonumber(player))
        IDENTIFIERS[player] = citizenid
    end
end)

AddEventHandler('onResourceStop', function()
    if name ~= GetCurrentResourceName() then return end
    for k,v in pairs(CACHE) do
        reputation.SavePlayerRep(k)
    end
end)

lib.callback.register('groups:GetRep', function(source)
    local citizenid = config.getPlayerCID(source)
    return reputation.GetAllRep(citizenid)
end)

-- EXPORTS

local function GetAllRep(citizenid)
    return reputation.GetAllRep(citizenid)
end
exports('GetAllRep', GetAllRep)

local function GetRep(citizenid, name)
    return reputation.GetRep(citizenid, name)
end
exports('GetRep', GetRep)

local function SetRep(citizenid, name, amount)
    reputation.SetRep(citizenid, name, amount)
end
exports('SetRep', SetRep)

local function RemoveRep(citizenid, name, amount)
    reputation.RemoveRep(citizenid, name, amount)
end
exports('RemoveRep', RemoveRep)

local function AddRep(citizenid, name, amount)
    reputation.AddRep(citizenid, name, amount)
end
exports('AddRep', AddRep)

local function AddMultipleRep(citizenid, reputations)
    reputation.AddMultipleRep(citizenid, reputations)
end
exports('AddMultipleRep', AddMultipleRep)

local function RemoveMultipleRep(citizenid, reputations)
    reputation.RemoveMultipleRep(citizenid, reputations)
end
exports('RemoveMultipleRep', RemoveMultipleRep)

-- COMMANDS
lib.addCommand('setrep', {
    help = 'Set reputation for a player',
    restricted = 'group.admin',
    params = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'reputation', help = 'Reputation', type = 'string'},
        {name = 'value', help = 'Value', type = 'number'},
    }
}, function(source, args)
    local Target = exports.qbx_core:GetPlayer(args.id)
    if not Target then return end

    reputation.SetRep(Target.PlayerData.citizenid, args.reputation, args.value)

    config.notify(source, {
        type = 'info',
        title = 'Repuation',
        description = 'Set ' .. args.value .. ' reputation to ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' for ' .. args.reputation
    })
end)

lib.addCommand('removerep', {
    help = 'Set reputation for a player',
    restricted = 'group.admin',
    params = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'reputation', help = 'Reputation', type = 'string'},
        {name = 'value', help = 'Value', type = 'number'},
    }
}, function(source, args)
    local Target = exports.qbx_core:GetPlayer(args.id)
    if not Target then return end

    reputation.RemoveRep(Target.PlayerData.citizenid, args.reputation, args.value)
    config.notify(source, {
        type = 'info',
        title = 'Repuation',
        description = 'Removed ' .. args.value .. ' reputation from ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' for ' .. args.reputation
    })
end)

lib.addCommand('addrep', {
    help = 'Set reputation for a player',
    restricted = 'group.admin',
    params = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'reputation', help = 'Reputation', type = 'string'},
        {name = 'value', help = 'Value', type = 'number'},
    }
}, function(source, args)
    local Target = exports.qbx_core:GetPlayer(args.id)
    if not Target then return end
    reputation.AddRep(Target.PlayerData.citizenid, args.reputation, args.value)
    config.notify(source, {
        type = 'info',
        title = 'Repuation',
        description = 'Added ' .. args.value .. ' reputation to ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' for ' .. args.reputation
    })
end)

lib.addCommand('addboost', {
    help = 'Set reputation for a player',
    restricted = 'group.admin',
    params = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'boostType', help = 'Type', type = 'string'},
        {name = 'multiplier', help = 'Multiplier', type = 'number'},
        {name = 'time', help = 'Duration', type = 'number'},
    }
}, function(source, args)
    local Target = exports.qbx_core:GetPlayer(args.id)
    if not Target then return end

    MySQL.Async.insert('INSERT INTO group_boosts (transactionId, redeemed, license, type, multiplier, targets, created, activated) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', { 
        'admin',
        1,
        Target.PlayerData.license,
        args.boostType, 
        args.multiplier,
        '',
        args.time,
        os.time(),
        0,
    })
    
    config.notify(source, {
        type = 'info',
        title = 'Repuation',
        description = 'Added ' .. args.value .. ' reputation to ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' for ' .. args.reputation
    })
end)

RegisterCommand("donatorPurchase", function(source, args)
    if source == 0 then
        local data = json.decode(args[1])

        local boostType = 'all'
        local multiplier = 2
        local boostTime = 1

        if data.package == 'supporter' then
            boostType = 'all'
            multiplier = 2
        elseif data.package == 'threehours' then
            boostType = 'all'
            multiplier = 2
            boostTime = 3
        elseif data.package == 'sixhours' then 
            boostType = 'all'
            multiplier = 2
            boostTime = 6
        elseif data.package == 'serverboost' then
            boostType = 'all'
            multiplier = 2
            boostTime = 2
        end

        MySQL.Async.insert('INSERT INTO group_boosts (transactionId, redeemed, license, type, multiplier, targets, created, activated) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', { 
            data.transactionId,
            0,
            '',
            boostType, 
            multiplier,
            '',
            boostTime,
            os.time(),
            0,
        })
        lib.logger(source, 'Boost Purchase', 'Transaction ID: ' .. data.transactionId .. ' Package: ' .. data.package)
    else
        lib.logger(source, 'Boost Purchase', ('ID: %s Tried to create a pending package'):format(source))
    end
end, false)

return reputation