-- last unique id
local luid_key = KEYS[1] .. ':luid'

return redis.call('incr', luid_key);