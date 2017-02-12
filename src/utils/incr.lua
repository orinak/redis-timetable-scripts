local function incr (key, delta)
    local x = redis.call('incr', key)
    return tonumber(x)
end