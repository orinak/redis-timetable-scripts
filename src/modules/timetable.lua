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

function Timetable:get (time, inclusive)
  local key = self:keyfor 'timetable'
  local id, start = zprev(key, time)

  if not id then
    return nil
  end

  local route = Route.init(self, id)

  if not route:interval(time-start) then
    return nil
  end

  return route, start
end

function Timetable:range (min, max)
  max = max and '('..max or '+inf'

  local key = self:keyfor 'timetable'

  local initial, start = self:get(min)
  if initial then
    min = start
  end

  local range = zrangebyscore(key, min, max)

  -- local initial, start = self:get(min)
  -- if initial then
  --   table.insert(range, initial.id, 1)
  -- end

  return range
end

function Timetable:locate (time)
  local route, start = self:get(time)

  return route and route:locate(time-start)
end

return Timetable