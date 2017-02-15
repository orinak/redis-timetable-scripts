return function (key, ...)
  return redis.call('geoadd', key, unpack(arg))
end