local Security = {
    _tamperAttempts = {},
    _checksumSeed = math.random(1, 1000000)
}

function Security.generateDataSignature(data, player)
    local serial = getPlayerSerial(player)
    local time = getRealTime().timestamp
    return hash("sha3-512", tostring(data) .. serial .. time .. _KEY)
end

function Security.validateRequest(player, key, action)
    local validEvents = {
        ["data:request"] = true,
        ["data:transfer"] = true
    }
    
    if not validEvents[eventName] then
        Security.logTamperAttempt(player, "INVALID_EVENT")
        cancelEvent()
        return false
    end
    
    if not Security.checkRateLimit(player) then
        Security.logTamperAttempt(player, "RATE_LIMIT")
        cancelEvent()
        return false
    end
    
    local playerZone = getElementZoneName(player)
    if not Security.isAllowedZone(playerZone) then
        Security.logTamperAttempt(player, "INVALID_ZONE")
        cancelEvent()
        return false
    end
    
    return true
end

function Security.checkRateLimit(player)
    local now = getTickCount()
    local attempts = Security._tamperAttempts[player] or {}
    
    if #attempts >= 10 then
        local timeDiff = now - attempts[1]
        if timeDiff < 5000 then
            return false
        end
        table.remove(attempts, 1)
    end
    
    table.insert(attempts, now)
    Security._tamperAttempts[player] = attempts
    return true
end

function Security.isAllowedZone(zoneName)
    local forbiddenZones = {
        ["Blueberry Acres"] = true,
        ["Fort Carson"] = true
    }
    return not forbiddenZones[zoneName]
end

function Security.logTamperAttempt(player, reason)
    local log = string.format("[%s] %s (%s) - %s",
        getRealTime().timestamp,
        getPlayerName(player),
        getPlayerSerial(player),
        reason
    )
    outputDebugString(log, 2)
    outputConsole(log)
    
    if Security.countTamperAttempts(player) >= 3 then
        triggerClientEvent(player, "security:injectFakeData", resourceRoot)
        setTimer(kickPlayer, 5000, 1, player, "[AC] Fake Data Injection Detected!")
    end
end

function Security.countTamperAttempts(player)
    return #(Security._tamperAttempts[player] or {})
end

return Security