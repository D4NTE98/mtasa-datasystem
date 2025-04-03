AdminManager = {
    adminActions = {}
}

function AdminManager.init()
    addEvent("admin:requestPlayerData", true)
    addEvent("admin:requestPlayerDetails", true)
    addEvent("admin:modifyData", true)
    
    addEventHandler("admin:requestPlayerData", resourceRoot, AdminManager.sendPlayerData)
    addEventHandler("admin:requestPlayerDetails", resourceRoot, AdminManager.sendPlayerDetails)
    addEventHandler("admin:modifyData", resourceRoot, AdminManager.handleDataModification)
end

function AdminManager.sendPlayerData()
    if not hasObjectPermissionTo(client, "function.ban") then return end
    
    local playersData = {}
    for _, player in ipairs(getElementsByType("player")) do
        playersData[player] = countElements(SecureDataServer._storage[player] or {})
    end
    triggerClientEvent(client, "admin:receivePlayerData", resourceRoot, playersData)
end

function AdminManager.sendPlayerDetails(player)
    if not hasObjectPermissionTo(client, "function.ban") then return end
    
    local data = {}
    if isElement(player) and SecureDataServer._storage[player] then
        for key, entry in pairs(SecureDataServer._storage[player]) do
            data[key] = SecureDataServer.getPlayerData(player, key)
        end
    end
    triggerClientEvent(client, "admin:receivePlayerDetails", resourceRoot, player, data)
end

function AdminManager.handleDataModification(player, key, value, action)
    if not hasObjectPermissionTo(client, "function.ban") then return end
    
    if action == "add" then
        SecureDataServer.setPlayerData(player, key, value, {persist = true})
        AdminManager.logAction(client, "ADD", player, key, value)
    elseif action == "delete" then
        SecureDataServer._storage[player][key] = nil
        AdminManager.logAction(client, "DELETE", player, key)
    end
    
    AdminManager.sendPlayerDetails(player)
end

function AdminManager.logAction(admin, actionType, target, key, value)
    local logEntry = string.format("[%s] %s %s: %s -> %s (Key: %s)",
        getRealTime().timestamp,
        getPlayerName(admin),
        actionType,
        getPlayerName(target),
        tostring(value) or "N/A",
        key
    )
    outputConsole(logEntry)
end

AdminManager.init()