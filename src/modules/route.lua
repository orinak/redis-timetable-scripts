local map = require '../utils/map'
local push = require '../utils/push'
local foreach = require '../utils/foreach'

local zadd = require '../utils/zadd'
local zprev = require '../utils/zprev'
local znext = require '../utils/znext'
local geoadd = require '../utils/geoadd'
local geopos = require '../utils/geopos'

local haversine = require '../utils/haversine'
local midpoint  = require '../utils/midpoint'

local function destruct (argv)
  local geo = {}
  local zt  = {}

  local threshold = 0

  local id = 0

  for i = 1, #argv, 3 do
    push(geo, argv[i], argv[i+1], id)

    if i > 1 then
      threshold = threshold + argv[i-1]
    end

    push(zt, threshold, id)

    id = id + 1
  end

  return geo, zt
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

  local geoindex, duration = destruct(data);

  geoadd(self:keyfor 'geoindex', unpack(geoindex))

  zadd(self:keyfor 'duration', unpack(duration))
  return self
end


function Route:keyfor (segment)
  return self.timetable:keyfor(self.id, segment)
end


function Route:get (t)
  local key = self:keyfor 'duration'

  local id_p, t_p = zprev(key, t)
  local id_n, t_n = znext(key, t)

  if not id_p or not id_n then
    return nil
  end

  local fraction = (t - t_p) / (t_n - t_p)

  return id_p, id_n, fraction
end


function Route:locate (t)
  local function locate (...)
    local key = self:keyfor('geoindex')
    return unpack(
      geopos(key, unpack(arg))
    )
  end

  local id_p, id_n, fraction = self:get(t)

  if not id_p or not id_n then
    return nil
  end

  local p, n = locate(id_p, id_n);

  return midpoint(p, n, fraction)
end


return Route