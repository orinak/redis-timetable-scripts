return function (key, data)
  return redis.call('zadd', key, unpack(data))
end