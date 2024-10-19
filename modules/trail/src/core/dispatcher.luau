--!strict
--!optimize 2

local NoSubscriber = require("@Trail/core/noSubscriber")
local Primitives = require("@Trail/core/primitives")
local Subscriber = require("@Trail/core/subscriber")

type Subscriber = Subscriber.Subscriber

local Dispatch = {}
Dispatch.__index = Dispatch

export type Dispatch = typeof(Dispatch)

--[[
    Returns a new `Dispatch` that discards events and spans.
]]
function Dispatch.none(): Dispatch
    local self = setmetatable({
        _subscriber = NoSubscriber,
    }, Dispatch)
    return (self :: never) :: Dispatch
end

--[[
    Returns a `Dispatch` with a given `Subscriber`
]]
function Dispatch.new(subscriber: Subscriber)
    local self = setmetatable({
        _subscriber = subscriber,
    }, Dispatch)
    return (self :: never) :: Dispatch
end

local NONE_DISPATCH: Dispatch = Dispatch.none()
local GLOBAL_DISPATCH: Dispatch = Dispatch.none()
local GLOBAL_ALREADY_SET = false

-- TODO: Cleanup unused threads
local DEFAULT_DISPATCHES: { [thread]: { accesses: number, inner: Dispatch } } = {}

--[[
    Executes a callback with a reference to the thread's
    current dispatcher.
]]
function Dispatch.getDefault(f: (dispatch: Dispatch) -> ())
    local currentThread = coroutine.running()
    local entry = DEFAULT_DISPATCHES[currentThread]

    -- fallback
    if entry == nil then
        return f(GLOBAL_DISPATCH)
    end

    --[[
        Alternative way of using:
        CURRENT_STATE
            .try_with(|state| {
                if let Some(entered) = state.enter() {
                    return f(&entered.current());
                }

                f(&NONE)
            })
            .unwrap_or_else(|_| f(&NONE))
    ]]
    if entry.accesses > 0 then
        return f(NONE_DISPATCH)
    end
    entry.accesses += 1

    local result = f(entry.inner) :: never
    entry.accesses -= 1
    return result
end

--[[
    Executes a callback with a reference to the thread's
    current dispatcher.

    The only difference is this function accepts return values
    because of limitations with Luau.
]]
function Dispatch.getDefaultReturned<T>(f: (dispatch: Dispatch) -> T): T
    return (Dispatch.getDefault(f) :: never) :: T
end

--[[
    Sets this dispatch as the global default for the duration of
    the entire server/client session.

    Can only be set once; subsequent attempts to set the global default will fail.
]]
function Dispatch.setGlobalDefault(dispatch: Dispatch)
    if GLOBAL_ALREADY_SET then
        error("a global default trace dispatcher has already been set", 2)
    end
    GLOBAL_DISPATCH = dispatch
end

--[[
    Sets the dispatch as the default dispatch for the duration
    of the callback argument.
]]
function Dispatch.withDefault(dispatch: Dispatch, f: () -> ())
    local currentThread = coroutine.running()
    local defaultDispatch = DEFAULT_DISPATCHES[currentThread]
    if defaultDispatch ~= nil then
        error(
            "a default trace dispatcher for the running thread has already been temporarily set",
            2
        )
    end
    DEFAULT_DISPATCHES[currentThread] = { accesses = 0, inner = dispatch }
    local result = f() :: never
    DEFAULT_DISPATCHES[currentThread] = nil
    return result
end

--[[
    Sets the dispatch as the default dispatch for the duration
    of the callback argument.

    The only difference is this function accepts return values
    because of limitations with Luau.
]]
function Dispatch.withDefaultReturned<T>(dispatch: Dispatch, f: () -> T): T
    return Dispatch.withDefault(dispatch, f) :: T
end

-----------------------------------------------------------------------
-- So that no users can access the internal `_subscriber` field
local function getSubscriber(dispatch: Dispatch): Subscriber
    return (dispatch :: never)._subscriber :: Subscriber
end

--[[
    Returns true if this Dispatch forwards to a Subscriber.
]]
function Dispatch.is(dispatch: Dispatch, value: unknown)
    return getSubscriber(dispatch) == value
end

function Dispatch.maxLevelHint(self: Dispatch): Primitives.LevelFilter?
    return getSubscriber(self):maxLevelHint()
end

function Dispatch.newSpan(self: Dispatch, span: Primitives.Attributes): Primitives.Id
    return getSubscriber(self):newSpan(span)
end

function Dispatch.record(self: Dispatch, span: Primitives.Id, values: Primitives.Record)
    return getSubscriber(self):record(span, values)
end

function Dispatch.recordFollowsFrom(self: Dispatch, span: Primitives.Id, follows: Primitives.Id)
    return getSubscriber(self):recordFollowsFrom(span, follows)
end

function Dispatch.enabled(self: Dispatch, metadata: Primitives.Metadata): boolean
    return getSubscriber(self):enabled(metadata)
end

function Dispatch.event(self: Dispatch, event: Primitives.Event)
    local subscriber = getSubscriber(self)
    if subscriber:eventEnabled(event) then
        subscriber:event(event)
    end
end

function Dispatch.enter(self: Dispatch, span: Primitives.Id)
    return getSubscriber(self):enter(span)
end

function Dispatch.exit(self: Dispatch, span: Primitives.Id)
    return getSubscriber(self):exit(span)
end

function Dispatch.cloneSpan(self: Dispatch, span: Primitives.Id): Primitives.Id
    return getSubscriber(self):cloneSpan(span)
end

function Dispatch.currentSpan(self: Dispatch): Primitives.Id?
    return getSubscriber(self):currentSpan()
end

function Dispatch.tryClose(self: Dispatch, id: Primitives.Id): boolean
    return getSubscriber(self):tryClose(id)
end

return Dispatch
