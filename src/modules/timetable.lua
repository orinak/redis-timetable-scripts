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

function Timetable.xpath (self, ...)
  local function join (arr)
    return table.concat(arr, ':')
  end

  local segments = { self.key }
  if #arg > 0 then
    table.insert(segments, join(arg))
  end
  return join(segments)
end


function Timetable.uid (self)
  return incr(self:xpath('luid'));
end


function Timetable.add (self, time, data)
  local id = self:uid()

  local function xpath (segment)
    return self:xpath(id, segment)
  end

  local function destruct (argv)
    local geo = {}
    local zt = {}
    local zs = {}

    local threshold = 0
    local magnitude = 0

    local id = 0

    for i = 1, #argv, 4 do
      table.insert(geo, argv[i])
      table.insert(geo, argv[i+1])
      table.insert(geo, id)

      if i > 1 then
        threshold = threshold + argv[i-2]
        magnitude = magnitude + argv[i-1]
      end

      table.insert(zt, threshold)
      table.insert(zt, id)

      table.insert(zs, magnitude)
      table.insert(zs, id)

      id = id + 1
    end

    return geo, zt, zs
  end

  local geoindex, duration, distance = destruct(data);

  geoadd(xpath('geoindex'), geoindex)

  zadd(xpath('duration'), duration)
  zadd(xpath('distance'), distance)

  zadd(self:xpath('timetable'), { time, id })

  return id
end