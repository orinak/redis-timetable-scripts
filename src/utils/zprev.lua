return function (key, score)
  local argv = {
    score, 0,
    'withscores',
    'limit', 0, 1
  }
  -- return argv
  local res = redis.call('zrevrangebyscore', key, unpack(argv))
  return unpack(res)
end