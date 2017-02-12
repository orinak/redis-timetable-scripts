return function (key, score)
  local argv = {
    '('..score, '+inf',
    'withscores',
    'limit', 0, 1
  }
  -- return argv
  local res = redis.call('zrangebyscore', key, unpack(argv))
  return unpack(res)
end