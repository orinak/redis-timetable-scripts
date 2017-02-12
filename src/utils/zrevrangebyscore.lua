return function (key, ...)
  return redis.call('zrevrangebyscore', unpack(arg))
end