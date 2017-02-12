local function incr (key, delta)
  return redis.call('incr', key) * 1
end