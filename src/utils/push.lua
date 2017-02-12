require 'foreach'

local function push (arr, ...)
  local function pushone (x)
    table.insert(arr, x)
  end
  foreach(arg, pushone);
end