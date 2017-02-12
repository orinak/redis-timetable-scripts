return function (pattern)
  return function (str)
    return string.format(pattern, str)
  end
end