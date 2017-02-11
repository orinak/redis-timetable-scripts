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

