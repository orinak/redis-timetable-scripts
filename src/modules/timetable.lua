local Route = require 'route'

local incr = require '../utils/incr'
local zadd = require '../utils/zadd'


local Timetable = {}
Timetable.__index = Timetable

function Timetable.init (key)
  local self = setmetatable({}, Timetable)
  self.key = key
  return self
end

function Timetable.keyfor (self, ...)
  local function join (arr)
    return table.concat(arr, ':')
  end

  local segments = { self.key }
  if #arg > 0 then
    table.insert(segments, join(arg))
  end
  return join(segments)
end

function Timetable:uid ()
  return incr(self:keyfor 'luid');
end

function Timetable:index (time, route)
  return zadd(self:keyfor 'timetable', { time, route.id })
end

function Timetable:add (time, argv)
  local route = Route.create(self, time, argv)
  self:index(time, route)
  return route.id
end

return Timetable