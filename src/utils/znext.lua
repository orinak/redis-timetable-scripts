return function (key, score)
  local argv = {
    '('..score, '+inf',
    'withscores',
    'limit', 0, 1
  }
  return unpack(
    redis.call('zrangebyscore', key, unpack(argv))
  )
end