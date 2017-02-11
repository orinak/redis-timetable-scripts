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

function Timetable.add (self, timestamp)
    return self:index(timestamp)
end