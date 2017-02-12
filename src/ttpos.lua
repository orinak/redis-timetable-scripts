local map = require 'utils/map'
local format = require 'utils/format'

local Timetable = require 'modules/timetable'

local timetable = Timetable.init(KEYS[1])

local location = timetable:locate(ARGV[1])

if not location then
  return nil
end

return map(location, format('%.8f'))