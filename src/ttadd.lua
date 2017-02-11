require "modules/timetable"

local function shift (arr)
    return table.remove(arr, 1)
end

local timetable = Timetable.init(KEYS[1])

local timestamp = shift(ARGV)

return timetable:add(timestamp)