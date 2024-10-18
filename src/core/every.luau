--!strict

--[[
    It returns a RobloxScriptConnection object and it allows
    to run through a passed function for every N seconds unless
    it is disconnected.
]]
return function(interval: number, callback: (elapsed: number) -> ())
    local conn: RBXScriptConnection
    local lastCall = 0
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        local now = os.clock()
        local elapsed = now - lastCall
        if elapsed >= interval then
            lastCall = now
            callback(elapsed)
        end
    end)
    return conn
end
