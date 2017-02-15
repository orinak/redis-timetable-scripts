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


local TIMELINE = 'timeline'
local GEOINDEX = 'geoindex'


local function destruct (argv)
  local geoindex = {}
  local timeline  = {}

  local threshold = 0

  local id = 0

  for i = 1, #argv, 3 do
    push(geoindex, argv[i], argv[i+1], id)

    -- skip first step, starts at 0 moment
    if i > 1 then
      threshold = threshold + argv[i-1]
    end

    push(timeline, threshold, id)

    id = id + 1
  end

  return timeline, geoindex
end


local Route = {}
Route.__index = Route

function Route.init (key, argv)
  local self = setmetatable({}, Route)

  self.key = key

  if argv then
    self:set(argv)
  end

  return self
end

function Route:keyfor (segment)
  segment = segment and ':'..segment or ''
  return self.key .. segment
end

function Route:set (argv)
  local timeline, geoindex = destruct(argv);
  zadd(self:keyfor(TIMELINE), unpack(timeline))
  geoadd(self:keyfor(GEOINDEX), unpack(geoindex))
  return self
end

function Route:get (t)
  local key = self:keyfor(TIMELINE)

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
    local key = self:keyfor(GEOINDEX)
    return unpack(
      geopos(key, unpack(arg))
    )
  end

  local id_p, id_n, fraction = self:get(t)

  if not id_p or not id_n then
    return nil
  end

  local p, n = locate(id_p, id_n)

  return midpoint(p, n, fraction)
end


return Route