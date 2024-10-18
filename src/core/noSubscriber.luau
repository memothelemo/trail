--!strict
--!optimize 2

local Primitives = require("@src/core/primitives")
local Subscriber = require("@src/core/subscriber")

--[[
    A no-op NoSubscriber
]]
local NoSubscriber = Subscriber.extend("NoSubscriber")

type Subscriber = Subscriber.Subscriber
export type NoSubscriber = Subscriber

-- selene: allow(unused_variable)
function NoSubscriber.enabled(self: Subscriber, metadata: Primitives.Metadata): boolean
    return false
end

-- selene: allow(unused_variable)
function NoSubscriber.maxLevelHint(self: Subscriber): Primitives.LevelFilter?
    return nil
end

-- selene: allow(unused_variable)
function NoSubscriber.newSpan(self: Subscriber, span: Primitives.Attributes): Primitives.Id
    return "<unknown-span>"
end

-- selene: allow(unused_variable)
function NoSubscriber.record(self: Subscriber, span: Primitives.Id, values: Primitives.Record) end

-- selene: allow(unused_variable)
function NoSubscriber.recordFollowsFrom(
    self: Subscriber,
    span: Primitives.Id,
    follows: Primitives.Id
)
end

-- selene: allow(unused_variable)
function NoSubscriber.event(self: Subscriber, event: Primitives.Event) end

-- selene: allow(unused_variable)
function NoSubscriber.enter(self: Subscriber, span: Primitives.Id) end

-- selene: allow(unused_variable)
function NoSubscriber.exit(self: Subscriber, span: Primitives.Id) end

local object = setmetatable({}, {
    __index = NoSubscriber,
})

return (object :: never) :: Subscriber
