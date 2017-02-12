return function (key, ...)
  return redis.call('geopos', key, unpack(arg))
end