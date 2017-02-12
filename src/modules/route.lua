local map = require '../utils/map'
local push = require '../utils/push'
local foreach = require '../utils/foreach'

local zadd = require '../utils/zadd'
local zprev = require '../utils/zprev'
local znext = require '../utils/znext'
local geoadd = require '../utils/geoadd'
local geopos = require '../utils/geopos'

local haversine = require '../utils/haversine'

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

  geoadd(self:keyfor 'geoindex', unpack(geoindex))

  zadd(self:keyfor 'duration', unpack(duration))
  zadd(self:keyfor 'distance', unpack(distance))

  return self
end


function Route:keyfor (segment)
  return self.timetable:keyfor(self.id, segment)
end

function Route:interval (t)
  local key = self:keyfor 'duration'
  local p, tp = zprev(key, t)
  local n, tn = znext(key, t)

  if not n then
    return p
  end

  local fraction = (t - tp) / (tn - tp)
  return p, n, fraction
end

function Route:locate (t)
  if t < 0 then
    return nil
  end

  local function getpos (...)
    local key = self:keyfor('geoindex')
    return unpack(
      geopos(key, unpack(arg))
    )
  end

  local id_prev, id_next, fraction = self:interval(t)

  if not id_next then
    return getpos(id_prev)
  end

  local function destruct (pos)
    return unpack(
      map(pos, math.rad)
    )
  end

  local p, n = getpos(id_prev, id_next);

  local lng1, lat1 = destruct(p)
  local lng2, lat2 = destruct(n)

  local d = haversine(lng1, lat1, lng2, lat2)

  local A = math.sin(d * (1-fraction)) / math.sin(d)
  local B = math.sin(d * fraction) / math.sin(d)

  local x = A * math.cos(lat1) * math.cos(lng1)
          + B * math.cos(lat2) * math.cos(lng2)
  local y = A * math.cos(lat1) * math.sin(lng1)
          + B * math.cos(lat2) * math.sin(lng2)
  local z = A * math.sin(lat1)
          + B * math.sin(lat2)

  local mid_lat = math.atan(z, math.sqrt(x*x + y*y))
  local mid_lng = math.atan(y, x)

  local lat = math.deg(mid_lat)
  local lng = math.deg(mid_lng)

  return { lng, lat }
end


return Route