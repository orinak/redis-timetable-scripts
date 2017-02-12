local push = require '../utils/push'

local zadd = require '../utils/zadd'
local geoadd = require '../utils/geoadd'


local function destruct (argv)
  local geo = {}
  local zt  = {}
  local zs  = {}

  local threshold = 0
  local magnitude = 0

  local id = 0

  for i = 1, #argv, 4 do
    push(geo, argv[i], argv[i+1], id)

    if i > 1 then
      threshold = threshold + argv[i-2]
      magnitude = magnitude + argv[i-1]
    end

    push(zt, threshold, id)
    push(zs, magnitude, id)

    id = id + 1
  end

  return geo, zt, zs
end


local Route = {}
Route.__index = Route

function Route.init (timetable, id)
  local self = setmetatable({}, Route)

  self.id = id
  self.timetable = timetable

  return self
end

function Route.create (timetable, time, data)
  local id = timetable:uid()

  local self = Route.init(timetable, id)

  local geoindex, duration, distance = destruct(data);

  geoadd(self:keyfor 'geoindex', geoindex)

  zadd(self:keyfor 'duration', duration)
  zadd(self:keyfor 'distance', distance)

  return self
end


function Route:keyfor (segment)
  return self.timetable:keyfor(self.id, segment)
end


return Route