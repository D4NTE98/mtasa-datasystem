local utils = {}

function utils.deepCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[utils.deepCopy(k)] = utils.deepCopy(v)
    end
    return setmetatable(res, getmetatable(obj))
end

function utils.generateIV()
    local iv = ''
    for i = 1, 16 do
        iv = iv .. string.char(math.random(0, 255))
    end
    return iv
end

function utils.serialize(data)
    return toJSON(data, true)
end

function utils.unserialize(str)
    return fromJSON(str) or {}
end

return utils