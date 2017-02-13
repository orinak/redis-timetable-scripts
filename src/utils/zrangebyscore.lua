return function (key, ...)
  return redis.call('zrangebyscore', key, unpack(arg))
end