return function (key, delta)
  return redis.call('incr', key) * 1
end