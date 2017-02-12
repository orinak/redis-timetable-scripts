local Timetable = require "modules/timetable"

local timetable = Timetable.init(KEYS[1])

local time = table.remove(ARGV, 1)

return timetable:add(time, ARGV)