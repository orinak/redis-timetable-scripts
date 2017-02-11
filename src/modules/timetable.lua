local Timetable = {}
Timetable.__index = Timetable


function Timetable.init (key)
    local self = setmetatable({}, Timetable)

    self.key = key

    return self
end


function Timetable.uid (self)
    local luid_key = self.key .. ':luid'
    local id = redis.call('incr', luid_key)
    return tonumber(id);
end

function Timetable.index (self, timestamp)
    local id = self:uid()
    local timetable_key = self.key .. ':timetable'
    redis.call('zadd', timetable_key, timestamp, id)
    return id
end

function Timetable.add (self, timestamp, argv)
    local id = self:index(timestamp)

    local timeline_key = self.key .. ':' .. id .. ':timeline'
    local distance_key = self.key .. ':' .. id .. ':distance'
    local geoindex_key = self.key .. ':' .. id .. ':geoindex'

    local threshold = 0
    local magnitude = 0


    local geoindex = {}
    local timeline = {}
    local distance = {}

    local step_id = 0

    for i = 1, #argv, 4 do
        step_id = step_id + 1

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
    end

    redis.call('zadd', timeline_key, unpack(timeline))
    redis.call('zadd', distance_key, unpack(distance))

    redis.call('geoadd', geoindex_key, unpack(geoindex))

    return id
end