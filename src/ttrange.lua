local map = require 'utils/map'
local format = require 'utils/format'

local Timetable = require 'modules/timetable'

local timetable = Timetable.init(KEYS[1])

return timetable:range(unpack(ARGV))