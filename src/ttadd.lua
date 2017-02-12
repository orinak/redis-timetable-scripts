require "modules/timetable"


local timetable = Timetable.init(KEYS[1])

local timestamp = table.remove(ARGV, 1)

return timetable:add(timestamp, ARGV)