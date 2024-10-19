--!strict
--!optimize 2

local Registry = require("../registry")
local Trail = require("@Trail/")

local LayerContext = {}

type RegistrySpanData = Registry.RegistrySpanData
export type LayerContext = typeof(LayerContext) & {
    subscriber: Trail.Subscriber,
}

function LayerContext.new(subscriber: Trail.Subscriber): LayerContext
    local self = setmetatable({
        subscriber = subscriber,
    }, {
        __index = LayerContext,
    })
    return (self :: never) :: LayerContext
end

function LayerContext.currentSpan(self: LayerContext): Trail.Id?
    return self.subscriber:currentSpan()
end

function LayerContext.enabled(self: LayerContext, metadata: Trail.Metadata): boolean
    return self.subscriber:enabled(metadata)
end

function LayerContext.event(self: LayerContext, event: Trail.Event)
    self.subscriber:event(event)
end

function LayerContext.eventSpan(self: LayerContext, event: Trail.Event): any
    if Trail.Event.isRoot(event) then
        return nil
    elseif Trail.Event.isContextual(event) then
        return self:lookupCurrent()
    else
        local parent = Trail.Span.Parent.getParentId(event.parent)
        if parent ~= nil then
            return self:span(parent)
        end
    end
    return nil
end

function LayerContext.metadata(self: LayerContext, id: Trail.Id): Trail.Metadata?
    local span = self:span(id)
    if span ~= nil then
        return span.metadata
    end
    return nil
end

function LayerContext.span(self: LayerContext, id: Trail.Id): any
    if self.subscriber["getSpan"] ~= nil then
        return (self.subscriber :: never):_getSpan(id) :: any
    end
    return nil
end

function LayerContext.exists(self: LayerContext, id: Trail.Id): any
    return self:span(id) ~= nil
end

function LayerContext.lookupCurrent(self: LayerContext): any
    local currentSpanId = self.subscriber:currentSpan()
    if currentSpanId == nil then
        return nil
    end
    local span = self:span(currentSpanId)
    assert(span ~= nil, `the subscriber should have data for the current span ({currentSpanId})!`)
    return span
end

function LayerContext.lookupCurrentFiltered(_self: LayerContext, subscriber: Trail.Subscriber): any
    if not Registry.is(subscriber) then
        return nil
    end
    if subscriber["getSpan"] == nil then
        return nil
    end

    local registry = subscriber :: Registry.Registry
    local stack = registry:_spanStack()
    for i = #stack._stack, 1, -1 do
        local ctx = stack._stack[i]
        if ctx.duplicate then
            continue
        end
        local span = (subscriber :: never):span(ctx.id)
        if span ~= nil then
            return span
        end
    end
    return nil
end

return LayerContext
