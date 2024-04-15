return {

    -- Variables
    debug = true,

    -- Functions

    debug = function(area, text)
        if not debug then return end
        area = area or 'reputation'
        print(('%s: %s'):format(area, text))
    end,

    notify = function(notifData)
        notifData.type = notifData.type or 'info'
        notifData.title = notifData.title or 'Reputation'
        notifData.description = notifData.description or 'No description'
        lib.notify(notifData)
    end
}