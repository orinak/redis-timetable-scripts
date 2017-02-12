return function (key, ...)
  return redis.call('zrangebyscore', unpack(argv))
end