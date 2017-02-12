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
    local luid_key = self.key .. ':luid'
    local id = redis.call('incr', luid_key)
    return tonumber(id);
end

function Timetable.index (self, timestamp)
    local id = self:uid()
    redis.call('zadd', self:xpath('timetable'), timestamp, id)
    return id
end

function Timetable.add (self, timestamp, argv)
    local id = self:index(timestamp)

    local geoindex = {}
    local timeline = {}
    local distance = {}

    local threshold = 0
    local magnitude = 0

    local step_id = 0

    for i = 1, #argv, 4 do
        if i > 1 then
            threshold = threshold + argv[i-2]
            magnitude = magnitude + argv[i-1]
        end

        table.insert(timeline, threshold)
        table.insert(timeline, step_id)

        table.insert(distance, magnitude)
        table.insert(distance, step_id)

        table.insert(geoindex, argv[i])
        table.insert(geoindex, argv[i+1])
        table.insert(geoindex, step_id)

        step_id = step_id + 1
    end

    redis.call('zadd', self:xpath(id, 'timeline'), unpack(timeline))
    redis.call('zadd', self:xpath(id, 'distance'), unpack(distance))
    redis.call('geoadd', self:xpath(id, 'geoindex'), unpack(geoindex))

    return id
end