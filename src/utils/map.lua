return function (arr, fn)
  local tmp = {}
  for i,v in ipairs(arr) do
    tmp[i] = fn(v)
  end
  return tmp
end