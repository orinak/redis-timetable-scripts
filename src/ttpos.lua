local map = require 'utils/map'
local format = require 'utils/format'

local Timetable = require 'modules/timetable'

local timetable = Timetable.init(KEYS[1])

local location = timetable:locate(ARGV[1])

return location and map(location, format('%.8f')) or nil