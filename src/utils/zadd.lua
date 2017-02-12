return function (key, ...)
  return redis.call('zadd', key, unpack(arg))
end