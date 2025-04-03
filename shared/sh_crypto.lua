local crypto = {}
local utils = require("shared/sh_utils")

function crypto.encrypt(data, key)
    local serialized = utils.serialize(data)
    local iv = utils.generateIV()
    local encrypted = encryptString("aes-256-gcm", serialized, key, iv)
    return iv .. ":" .. encrypted
end

function crypto.decrypt(encrypted, key)
    local parts = split(encrypted, ":")
    local iv = parts[1]
    local data = parts[2]
    local decrypted = decryptString("aes-256-gcm", data, key, iv)
    return utils.unserialize(decrypted)
end

function crypto.generateHMAC(data, key)
    local serialized = utils.serialize(data)
    return hash("hmac-sha512", serialized, key)
end

function crypto.generateSessionKey(player)
    local time = getRealTime().timestamp
    return hash("sha256", getPlayerSerial(player) .. time .. config.ENCRYPTION_KEY)
end

return crypto