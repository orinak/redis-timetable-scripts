return function (key, score)
  local argv = {
    score, 0,
    'withscores',
    'limit', 0, 1
  }
  return unpack(
    redis.call('zrevrangebyscore', key, unpack(argv))
  )
end