local SecureDataClient = {
    _cache = {},
    _pending = {}
}

function SecureDataClient.handleUpdate(key, hmac)
    SecureDataClient._pending[key] = {
        hmac = hmac,
        timestamp = getTickCount()
    }
    triggerServerEvent("secureData.request", localPlayer, key)
end

function SecureDataClient.getLocalData(key)
    if SecureDataClient._cache[key] then
        if (getTickCount() - SecureDataClient._cache[key].timestamp) < config.CACHE_TTL * 1000 then
            return SecureDataClient._cache[key].value
        end
    end
    SecureDataClient.requestData(key)
    return nil
end

addEvent("secureData.receive", true)
addEventHandler("secureData.receive", root,
    function(key, encrypted)
        local sessionKey = getElementData(localPlayer, "sessionKey")
        if not sessionKey then return end
        
        local decrypted = crypto.decrypt(encrypted, sessionKey)
        local calculatedHmac = crypto.generateHMAC(encrypted, sessionKey)
        
        if SecureDataClient._pending[key].hmac ~= calculatedHmac then
            outputDebugString("Client-side HMAC mismatch!", 3)
            return
        end
        
        SecureDataClient._cache[key] = {
            value = decrypted,
            timestamp = getTickCount()
        }
        SecureDataClient._pending[key] = nil
    end
)