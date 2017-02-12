require '../utils/push'

require '../utils/incr'
require '../utils/zadd'
require '../utils/geoadd'

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


function Timetable:add (time, data)
  local id = self:uid()

  local function keyfor (segment)
    return self:keyfor(id, segment)
  end

  local function destruct (argv)
    local geo = {}
    local zt = {}
    local zs = {}

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

  local geoindex, duration, distance = destruct(data);

  geoadd(keyfor 'geoindex', geoindex)

  zadd(keyfor 'duration', duration)
  zadd(keyfor 'distance', distance)

  zadd(self:keyfor('timetable'), { time, id })

  return id
end