--!strict
--!optimize 2

local Registry = require("../registry")
local Trail = require("@Trail/")

local Layer = require(".")
local LayerContext = require("./context")

local Layered = {}
Layered.__index = Layered

type Layer = Layer.Layer
type LayerContext = LayerContext.LayerContext

export type Layered = typeof(Layered) & Layer & {
    -- So we don't have to recreate layer context all the time
    -- which it may memory leak!
    _context: LayerContext,
    _layer: Layer,
    _inner: Trail.Subscriber,
    _inner_is_registry: boolean,
}

function Layered.new(layer: Layer, inner: Trail.Subscriber): Layered
    local self = setmetatable({
        _context = LayerContext.new(inner),
        _layer = layer,
        _inner = inner,
        _inner_is_registry = Registry.is(inner),
    }, Layered)
    return (self :: never) :: Layered
end

-- roblox-ts compatibility
-- selene: allow(unused_variable)
function Layered.constructor(self: Layer, ...) end

function Layered.is(obj: any): boolean
    if type(obj) ~= "table" then
        return false
    end
    return getmetatable(obj) == Layered
end

function Layered._ctx(self: Layered): LayerContext
    return self._context
end

--[[
    Because of type inconsistencies with TypeScript (the way Rust designed their traits),
    we need to differentiate functions for which is layer-compatible and subscriber-compatible
]]
Layered.enabledAsLayer = Layered.enabled
Layered.eventEnabledAsLayer = Layered.eventEnabled

function Layered.enabled(self: Layered, metadata: Trail.Metadata, ctx: LayerContext?): boolean
    -- assuming inner is a Layer or smth
    if Layer.is(self._inner) then
        assert(ctx ~= nil, "")
        if self._layer:enabled(metadata, ctx) then
            return ((self._inner :: never) :: Layer):enabled(metadata, ctx)
        end
        return false
    end

    if self._layer:enabled(metadata, self:_ctx()) then
        -- if the outer layer enables the callsite metadata, ask the subscriber.
        return self._inner:enabled(metadata)
    end
    -- otherwise, the callsite is disabled by the layer

    -- If per-layer filters are in use, and we are short-circuiting
    -- (rather than calling into the inner type), clear the current
    -- per-layer filter `enabled` state.
    return false
end

function Layered.maxLevelHint(_self: Layered): Trail.LevelFilter?
    error("TODO")
end

function Layered.newSpan(self: Layered, span: Trail.Attributes): Trail.Id
    local id = self._inner:newSpan(span)
    self._layer:onNewSpan(span, id, self:_ctx())
    return id
end

function Layered.record(self: Layered, span: Trail.Id, values: Trail.Record)
    self._inner:record(span, values)
    self._layer:onRecord(span, values, self:_ctx())
end

function Layered.recordFollowsFrom(self: Layered, span: Trail.Id, follows: Trail.Id)
    self._inner:recordFollowsFrom(span, follows)
    self._layer:onFollowsFrom(span, follows, self:_ctx())
end

function Layered.eventEnabled(self: Layered, event: Trail.Event, ctx: LayerContext?): boolean
    if ctx ~= nil then
        if self._layer:eventEnabled(event, ctx) then
            return ((self._inner :: never) :: Layer):eventEnabled(event, ctx)
        end
        return false
    end

    if self._layer:eventEnabled(event, self:_ctx()) then
        -- if the outer layer enables the event, ask the inner subscriber.
        return self._inner:eventEnabled(event)
    end
    -- otherwise, the event is disabled by this layer
    return false
end

function Layered.event(self: Layered, event: Trail.Event)
    self._inner:event(event)
    self._layer:onEvent(event, self:_ctx())
end

function Layered.enter(self: Layered, span: Trail.Id)
    self._inner:enter(span)
    self._layer:onEnter(span, self:_ctx())
end

function Layered.exit(self: Layered, span: Trail.Id)
    self._inner:exit(span)
    self._layer:onExit(span, self:_ctx())
end

function Layered.cloneSpan(self: Layered, old: Trail.Id): Trail.Id
    local new = self._inner:cloneSpan(old)
    if new ~= old then
        self._layer:onIdChange(old, new, self:_ctx())
    end
    return new
end

function Layered.dropSpan(self: Layered, id: Trail.Id)
    self:tryClose(id)
end

function Layered.tryClose(self: Layered, id: Trail.Id): boolean
    if self._inner:tryClose(id) then
        self._layer:onClose(id, self:_ctx())
        return true
    end
    return false
end

function Layered.currentSpan(self: Layered): Trail.Id?
    return self._inner:currentSpan()
end

function Layered.onRegisterDispatch(self: Layered, subscriber: Trail.Dispatch)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onRegisterDispatch(subscriber);
    ((self._inner :: never) :: Layer):onRegisterDispatch(subscriber)
end

function Layered.onLayer(self: Layered, subscriber: Trail.Subscriber)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onLayer(subscriber);
    ((self._inner :: never) :: Layer):onLayer(subscriber)
end

function Layered.onNewSpan(self: Layered, attrs: Trail.Attributes, id: Trail.Id, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onNewSpan(attrs, id, ctx);
    ((self._inner :: never) :: Layer):onNewSpan(attrs, id, ctx)
end

function Layered.onRecord(self: Layered, span: Trail.Id, values: Trail.Record, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onRecord(span, values, ctx);
    ((self._inner :: never) :: Layer):onRecord(span, values, ctx)
end

function Layered.onFollowsFrom(self: Layered, span: Trail.Id, follows: Trail.Id, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onFollowsFrom(span, follows, ctx);
    ((self._inner :: never) :: Layer):onFollowsFrom(span, follows, ctx)
end

function Layered.onEvent(self: Layered, event: Trail.Event, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onEvent(event, ctx);
    ((self._inner :: never) :: Layer):onEvent(event, ctx)
end

function Layered.onEnter(self: Layered, id: Trail.Id, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onEnter(id, ctx);
    ((self._inner :: never) :: Layer):onEnter(id, ctx)
end

function Layered.onExit(self: Layered, id: Trail.Id, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onExit(id, ctx);
    ((self._inner :: never) :: Layer):onExit(id, ctx)
end

function Layered.onClose(self: Layered, id: Trail.Id, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onClose(id, ctx);
    ((self._inner :: never) :: Layer):onClose(id, ctx)
end

function Layered.onIdChange(self: Layered, old: Trail.Id, new: Trail.Id, ctx: LayerContext)
    assert(Layer.is(self._layer), "")
    assert(Layer.is(self._inner), "")

    self._layer:onIdChange(old, new, ctx);
    ((self._inner :: never) :: Layer):onIdChange(old, new, ctx)
end

return Layered
