return {
    -- Variables
    debug = true,
    saveInterval = 120, --  How often to save reputation to the database (in seconds). Set to 0 to disable.
    enableBoosts = true,

    -- Functions

    debug = function(area, text)
        if not debug then return end
        area = area or 'reputation'
        print(('%s: %s'):format(area, text))
    end,

    notify = function(source, notifData)
        notifData.type = notifData.type or 'info'
        notifData.title = notifData.title or 'Reputation'
        notifData.description = notifData.description or 'No description'
        TriggerClientEvent('ox_lib:notify', source, notifData)
    end,
    
    getPlayerCID = function(source)
        return exports.qbx_core:GetPlayer(source).PlayerData.citizenid
    end
}