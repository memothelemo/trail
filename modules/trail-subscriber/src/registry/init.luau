--!strict
--!optimize 2

local Trail = require("@Trail/")

local Attributes = Trail.Span.Attributes
local Dispatcher = require("@Trail/core/dispatcher")
local HttpService = game:GetService("HttpService")
local SpanStack = require("./stack")

type SpanStack = SpanStack.SpanStack

-- Registry is a subscriber
local Registry = setmetatable({}, {
    __index = Trail.Subscriber,
})

export type Registry = typeof(Registry) & Trail.Subscriber & {
    _currentSpans: { [thread]: SpanStack },
    _spans: { [Trail.Id]: RegistrySpanData },
}

--[[
    This is our own local copy of a Span because by design,
    tracing doesn't allow us to keep Span values.
]]
export type RegistrySpanData = {
    metadata: Trail.Metadata,
    parent: Trail.Id?,
}

function Registry.new(): Registry
    local self = setmetatable({
        _currentSpans = {},
        _spans = {},
    }, Registry)
    return (self :: never) :: Registry
end

function Registry.is(object: any)
    if type(object) ~= "table" then
        return false
    end
    return getmetatable(object) == Registry
end

function Registry._spanStack(self: Registry): SpanStack
    local currentThread = coroutine.running()
    local stack = self._currentSpans[currentThread]
    if stack == nil then
        stack = SpanStack.new()
        self._currentSpans[currentThread] = stack
    end
    return stack
end

function Registry.getSpan(self: Registry, id: Trail.Id): RegistrySpanData?
    return self._spans[id]
end

function Registry.enabled(_self: Registry): boolean
    return true
end

function Registry.newSpan(self: Registry, attrs: Trail.Attributes): Trail.Id
    local parent: string?
    if Attributes.isRoot(attrs) then
        parent = nil
    elseif Attributes.isContextual(attrs) then
        local id = self:currentSpan()
        if id ~= nil then
            parent = self:cloneSpan(id)
        end
    else
        local itsParent = Trail.Span.Parent.getParentId(attrs.parent)
        parent = itsParent
    end
    local id
    do
        local inner: RegistrySpanData = {
            metadata = attrs.metadata,
            parent = parent,
        }
        id = HttpService:GenerateGUID(false)
        self._spans[id] = inner
    end
    return id
end

local function nop() end

--[[
    This is intentionally not implemented, as recording fields
    on a span is the responsibility of layers atop of this registry.
]]
function Registry.record(_self: Registry, _span: Trail.Id, _values: Trail.Record) end
function Registry.recordFollowsFrom(_self: Registry, _span: Trail.Id, _follows: Trail.Id) end

--[[
    This is intentionally not implemented, as recording events
    on a span is the responsibility of layers atop of this registry.
]]
function Registry.event(_self: Registry, _event: Trail.Event) end

function Registry.eventEnabled(_self: Registry, _event: Trail.Event): boolean
    return true
end

function Registry.enter(self: Registry, id: Trail.Id)
    local stack = self:_spanStack()
    if stack:push(id) then
        self:cloneSpan(id)
    end
end

function Registry.exit(self: Registry, id: Trail.Id)
    if self._currentSpans[coroutine.running()] == nil then
        return
    end
    local stack = self:_spanStack()
    if stack:pop(id) then
        Dispatcher.getDefault(function(dispatch)
            dispatch:tryClose(id)
        end)
    end
end

function Registry.cloneSpan(self: Registry, id: Trail.Id): Trail.Id
    local span = self:getSpan(id)
    if span == nil then
        error(
            `tried to clone {id}, but no span exists with that ID\n\
                This may be caused by consuming a parent span (\`parent: span\`) rather than borrowing it (\`parent: &span\`).`
        )
    end
    return id
end

function Registry.currentSpan(self: Registry): Trail.Id?
    local stack = self._currentSpans[coroutine.running()]
    if stack == nil then
        return nil
    end
    return stack:current()
end

Registry.tryClose = nop

return (Registry :: never) :: Registry
