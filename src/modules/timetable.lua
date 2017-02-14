local Route = require 'route'

local incr = require '../utils/incr'
local zadd = require '../utils/zadd'
local zprev = require '../utils/zprev'
local zrangebyscore = require '../utils/zrangebyscore'


local Timetable = {}
Timetable.__index = Timetable

function Timetable.init (key)
  local self = setmetatable({}, Timetable)
  self.key = key
  return self
end

function Timetable:keyfor (...)
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

function Timetable:set (time, route)
  local key = self:keyfor 'timetable'
  local id = route and route.id
                    or self:uid()
  zadd(key, time, id)
  return id
end

function Timetable:add (time, argv)
  local route = Route.create(self, time, argv)
  return self:set(time, route)
end

function Timetable:get (time)
  local key = self:keyfor 'timetable'
  local id, start = zprev(key, time)

  if not id then
    return nil
  end

  local route = Route.init(self, id)
  if not route:get(time-start) then
    return nil
  end

  return id, start
end

function Timetable:range (min, max)
  local key = self:keyfor 'timetable'

  min = min or '-inf'
  max = max or '+inf'

  local initial, start = self:get(min)

  if min == max then
    return initial and { initial } or nil
  end

  if initial then
    min = start
  end

  return zrangebyscore(key, min, '('..max)
end

function Timetable:locate (time)
  local id, start = self:get(time)

  if not id then
    return nil
  end

  local route = Route.init(self, id)
  return route:locate(time-start)
end

return Timetable