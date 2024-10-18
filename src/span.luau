--!strict
--!optimize 2

local Dispatcher = require("@src/core/dispatcher")
local Primitives = require("@src/core/primitives")

local Span = {}

local ACTIVITY_LOG_TARGET = "trail::span::activity"
local LOG_TARGET = "trail::span"

export type Span = typeof(Span) & {
    -- Used to enter the span when it is not executing
    inner: Inner?,
    --[[
        Metadata describing the span.

        This might be defined or nil, in the case that the
        span is disabled.
    ]]
    metadata: Primitives.Metadata?,
}

--[[
    A handle representing the capacity to enter a span which
    is known to exist.
]]
type Inner = {
    id: Primitives.Id,
    subscriber: Dispatcher.Dispatch,
}

function Span.new(metadata: Primitives.Metadata, values: Primitives.ValueSet): Span
    assert(type(metadata) == "table", "Missing `metadata` parameter")
    assert(type(values) == "table", "Missing `values` parameter")
    return Dispatcher.getDefaultReturned(function(dispatch)
        local newSpan = Primitives.Attributes.new(metadata, values)
        return Span.newWith(metadata, newSpan, dispatch)
    end)
end

function Span.newWith(
    metadata: Primitives.Metadata,
    newSpan: Primitives.Attributes,
    dispatch: Dispatcher.Dispatch
): Span
    assert(type(metadata) == "table", "Missing `metadata` parameter")
    assert(type(newSpan) == "table", "Missing `newSpan` parameter")
    assert(type(dispatch) == "table", "Missing `dispatch` parameter")

    local id = dispatch:newSpan(newSpan)
    local inner: Inner = {
        id = id,
        subscriber = dispatch,
    }

    local self = setmetatable({
        inner = inner,
        metadata = metadata,
    }, {
        __index = Span,
    })

    if _G.__TRAIL_DEV__ == true then
        print(`[{LOG_TARGET}] [{Primitives.Level[metadata.level]}] created new span {id}`)
    end

    return (self :: never) :: Span
end

function Span.newRoot(metadata: Primitives.Metadata, values: Primitives.ValueSet): Span
    assert(type(metadata) == "table", "Missing `metadata` parameter")
    assert(type(values) == "table", "Missing `values` parameter")
    return Dispatcher.getDefaultReturned(function(dispatch)
        return Span.newRootWith(metadata, values, dispatch)
    end)
end

function Span.newRootWith(
    metadata: Primitives.Metadata,
    values: Primitives.ValueSet,
    dispatch: Dispatcher.Dispatch
): Span
    local newSpan = Primitives.Attributes.newRoot(metadata, values)
    return Span.newWith(metadata, newSpan, dispatch)
end

function Span.childOf(
    parent: Primitives.Id?,
    metadata: Primitives.Metadata,
    values: Primitives.ValueSet
): Span
    return Dispatcher.getDefaultReturned(function(dispatch)
        return Span.childOfWith(parent, metadata, values, dispatch)
    end)
end

function Span.childOfWith(
    parent: Primitives.Id?,
    metadata: Primitives.Metadata,
    values: Primitives.ValueSet,
    dispatch: Dispatcher.Dispatch
): Span
    local newSpan = if parent ~= nil
        then Primitives.Attributes.childOf(parent, metadata, values)
        else Primitives.Attributes.newRoot(metadata, values)

    return Span.newWith(metadata, newSpan, dispatch)
end

--[[
    Constructs a new disabled span with the given `Metadata`.

    This should be used when a span is constructed from a known callsite,
    but the subscriber indicates that it is disabled.
]]
function Span.newDisabled(metadata: Primitives.Metadata): Span
    local self = setmetatable({
        inner = nil,
        metadata = metadata,
    }, {
        __index = Span,
    })
    return (self :: never) :: Span
end

--[[
    Constructs a new span that is *completely disabled*.
]]
function Span.none(): Span
    local self = setmetatable({}, { __index = Span })
    return (self :: never) :: Span
end

function Span.enter(self: Span)
    if self.inner == nil then
        return
    end
    self.inner.subscriber:enter(self.inner.id)
    if _G.__TRAIL_DEV__ == true and self.metadata ~= nil then
        print(`[{ACTIVITY_LOG_TARGET}] -> {self.metadata.name};`)
    end
end

function Span.exit(self: Span)
    if self.inner == nil then
        return
    end
    self.inner.subscriber:exit(self.inner.id)
    if _G.__TRAIL_DEV__ == true and self.metadata ~= nil then
        print(`[{ACTIVITY_LOG_TARGET}] <- {self.metadata.name};`)
    end
end

function Span.inScope(self: Span, fn: () -> ())
    self:enter()
    fn()
    self:exit()
end

function Span.hasField(self: Span, field: string): boolean
    if self.metadata == nil then
        return false
    end
    return table.find(self.metadata.fields, field) ~= nil
end

function Span.isDisabled(self: Span): boolean
    return self.inner == nil
end

function Span.isNone(self: Span): boolean
    return self:isDisabled() and self.metadata == nil
end

function Span.followsFrom(self: Span, from: Primitives.Id)
    if self.inner == nil then
        return
    end
    self.inner.subscriber:recordFollowsFrom(self.inner.id, from)
end

Span.Attributes = Primitives.Attributes
Span.Parent = Primitives.Parent

return Span
