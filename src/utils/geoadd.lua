return function (key, data)
  return redis.call('geoadd', key, unpack(data))
end