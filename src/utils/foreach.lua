return function (arr, fn)
  for i, v in ipairs(arr) do
    fn(v, i)
  end
end