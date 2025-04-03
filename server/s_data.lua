local SecureDataServer = {
    _storage = {},
    _sessionKeys = {},
    _cache = {}
}

function SecureDataServer.onPlayerJoin()
    local player = source
    SecureDataServer._storage[player] = {}
    SecureDataServer._sessionKeys[player] = crypto.generateSessionKey(player)
    setElementData(player, "sessionKey", SecureDataServer._sessionKeys[player], true)
end

--[[ old version
function SecureDataServer.setPlayerData(player, key, value, options)
    local allowedTypes = {string = true, number = true, table = true, boolean = true}
    if not allowedTypes[type(value)] then
        outputDebugString("Nieprawidłowy typ danych: "..type(value), 2)
        return false
    end
    
    if not Security.validateKey(key) then
        outputDebugString("Nieprawidłowy klucz: "..tostring(key), 2)
        return false
    end
    
    if key == "money" then
        if type(value) ~= "number" or value < 0 or value > 10000000 then
            Security.logTamperAttempt(player, "INVALID_MONEY_VALUE")
            return false
        end
    end
    
    local timestamp = getRealTime().timestamp
    local checksum = Security.generateChecksum(value, timestamp)
    
    local success = dbExec(sql, 
        "INSERT INTO secure_data (player, key, value, checksum) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE value=?, checksum=?",
        player, key, value, checksum, value, checksum
    )
    
    return success
end
]]

function SecureDataServer.setPlayerData(player, key, value, options)
    options = options or { persist = true, cache = true }
    
    local sessionKey = SecureDataServer._sessionKeys[player]
    local encrypted = crypto.encrypt(value, sessionKey)
    local hmac = crypto.generateHMAC(encrypted, sessionKey)
    
    SecureDataServer._storage[player][key] = {
        value = options.persist and encrypted or value,
        hmac = hmac,
        timestamp = getRealTime().timestamp
    }
    
    if options.cache then
        SecureDataServer._cache[player] = SecureDataServer._cache[player] or {}
        SecureDataServer._cache[player][key] = {
            value = value,
            expires = getRealTime().timestamp + config.CACHE_TTL
        }
    end
    
    triggerClientEvent(player, "secureData.update", resourceRoot, key, hmac)
    return true
end

function SecureDataServer.getPlayerData(player, key)
    if SecureDataServer._cache[player] and SecureDataServer._cache[player][key] then
        if getRealTime().timestamp < SecureDataServer._cache[player][key].expires then
            return SecureDataServer._cache[player][key].value
        end
    end
    
    local data = SecureDataServer._storage[player][key]
    if not data then return nil end
    
    local decrypted = crypto.decrypt(data.value, SecureDataServer._sessionKeys[player])
    local calculatedHmac = crypto.generateHMAC(data.value, SecureDataServer._sessionKeys[player])
    
    if calculatedHmac ~= data.hmac then
        outputDebugString("HMAC verification failed!", 2)
        return nil
    end
    
    SecureDataServer._cache[player][key] = {
        value = decrypted,
        expires = getRealTime().timestamp + config.CACHE_TTL
    }
    
    return decrypted
end

function SecureDataServer.cleanupCache()
    local now = getRealTime().timestamp
    for player, cache in pairs(SecureDataServer._cache) do
        if not isElement(player) then
            SecureDataServer._cache[player] = nil
        else
            for key, entry in pairs(cache) do
                if now > entry.expires then
                    cache[key] = nil
                end
            end
        end
    end
end

addEvent("secureData.request", true)
addEventHandler("secureData.request", root,
    function(player, key)
        if client ~= player then return end
        local data = SecureDataServer._storage[player][key]
        if data then
            triggerClientEvent(player, "secureData.receive", resourceRoot, key, data.value)
        end
    end
)