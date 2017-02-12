local foreach = require 'foreach'

return function (arr, ...)
  local function pushone (x)
    table.insert(arr, x)
  end
  foreach(arg, pushone);
end