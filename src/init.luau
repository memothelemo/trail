--!strict
local Dispatch = require("@src/Dispatch")
local Levels = require("@src/core/level")
local Primitives = require("@src/core/primitives")
local Span = require("@src/Span")
local Subscriber = require("@src/Subscriber")

export type SpanId = Primitives.Id
export type Level = Primitives.Level
export type FieldSet = Primitives.FieldSet

export type Event = Primitives.Event
export type Metadata = Primitives.Metadata

export type Dispatch = Dispatch.Dispatch
export type Span = Span.Span
export type Subscriber = Subscriber.Subscriber

local Trail = {
    Level = Levels.Level,
    LevelFilter = Levels.LevelFilter,

    Nil = Primitives.Nil,
    RemoveField = Primitives.RemoveField,

    Span = Span,
    Subscriber = Subscriber,

    setDefaultSubscriber = Dispatch.setDefaultSubscriber,
    withSubscriber = Dispatch.withSubscriber,
}

function Trail.withDispatch(callback: (dispatch: Dispatch) -> ())
    callback(Dispatch)
end

-----------------------------------------------
-- IMPLEMENTATION OF UNIMPLEMENTED FUNCTIONS --
-----------------------------------------------
function Span.current(): Span
    return Dispatch.currentSpan()
end

-- selene: allow(unused_variable)
function Subscriber.currentSpan(self: Subscriber): Span
    return Dispatch.currentSpan()
end

-- roblox-ts compatibility
Trail.Trail = Trail

return Trail
