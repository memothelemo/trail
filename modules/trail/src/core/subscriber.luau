--!strict
--!optimize 2

local Subscriber = {}
Subscriber.__name = "Subscriber"

local Primitives = require("@Trail/core/primitives")

export type Subscriber = typeof(Subscriber)

function Subscriber.extend(name: string): Subscriber
    assert(
        type(name) == "string",
        "Name must be a string or you should not use `:new()` in a subscriber."
    )

    local ownSubscriber = {}
    for k, v in pairs(Subscriber) do
        if k ~= "extend" then
            ownSubscriber[k] = v
        end
    end

    return ownSubscriber :: Subscriber
end

-- function Subscriber.new(...): Subscriber
--     assert(
--         type(select(1, ...)) == "string",
--         "Name must be a string or you should not use `:new()` in a subscriber."
--     )
--     local self = (setmetatable({}, Subscriber) :: never) :: Subscriber
--     self:constructor(...)
--     return self
-- end

-- selene: allow(unused_variable)
function Subscriber.setGlobalDefault(subscriber: Subscriber)
    error("Cannot execute `Subscriber.setGlobalDefault()`, maybe it is a bug!")
end

-- selene: allow(unused_variable)
function Subscriber.withDefaultReturned<T>(subscriber: Subscriber, fn: () -> T): T
    error("Cannot execute `Subscriber.setGlobalDefault()`, maybe it is a bug!")
end

-- selene: allow(unused_variable)
function Subscriber.withDefault(subscriber: Subscriber, fn: () -> ()): ()
    error("Cannot execute `Subscriber.setGlobalDefault()`, maybe it is a bug!")
end

-----------------------------------------------------------------------------------------
-- selene: allow(unused_variable)
function Subscriber.enabled(self: Subscriber, metadata: Primitives.Metadata): boolean
    error("[trail::subscriber] Please implement `:enabled(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.maxLevelHint(self: Subscriber): Primitives.LevelFilter?
    return nil
end

-- selene: allow(unused_variable)
function Subscriber.newSpan(self: Subscriber, span: Primitives.Attributes): Primitives.Id
    error("[trail::subscriber] Please implement `:newSpan(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.record(self: Subscriber, span: Primitives.Id, values: Primitives.Record)
    error("[trail::subscriber] Please implement `:record(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.recordFollowsFrom(self: Subscriber, span: Primitives.Id, follows: Primitives.Id)
    error("[trail::subscriber] Please implement `:recordFollowsFrom(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.eventEnabled(self: Subscriber, event: Primitives.Event): boolean
    return true
end

-- selene: allow(unused_variable)
function Subscriber.event(self: Subscriber, event: Primitives.Event)
    error("[trail::subscriber] Please implement `:recordFollowsFrom(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.enter(self: Subscriber, span: Primitives.Id)
    error("[trail::subscriber] Please implement `:enter(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.exit(self: Subscriber, span: Primitives.Id)
    error("[trail::subscriber] Please implement `:exit(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.cloneSpan(self: Subscriber, span: Primitives.Id): Primitives.Id
    return span
end

-- selene: allow(unused_variable)
function Subscriber.currentSpan(self: Subscriber): Primitives.Id?
    return nil
end

return Subscriber
