--!strict
--!optimize 2

local Layer = require("./layer")
local LayerContext = require("./layer/context")
local Registry = require("./registry")
local Trail = require("@Trail/")

local Layers = setmetatable({}, Trail.Subscriber)
Layers.__index = Layers
Layers.__tostring = Trail.Subscriber.__tostring

type Layer = Layer.Layer
type LayerContext = LayerContext.LayerContext

export type Layers = typeof(Layers) & Layer & {
    -- We don't have to recreate layer context every time when
    -- it is needed otherwise it will may be memory leaked.
    _context: LayerContext,
    _layers: { Layer },
    _root: Trail.Subscriber,
    _root_is_registry: boolean,
}

function Layers.new(root: Trail.Subscriber): Layers
    local self = setmetatable({
        _context = LayerContext.new(root),
        _layers = {},
        _name = "trail_subscriber::Registry",
        _root = root,
        _root_is_registry = Registry.is(root),
    }, Layers)
    return (self :: never) :: Layers
end

-- Iterates a list of layers in reverse order
function Layers.iter(self: Layers)
    local index = #self._layers
    return function()
        if index == 0 then
            return (nil :: never) :: number, (nil :: never) :: Layer
        end
        local currentLayer = self._layers[index]
        local lastIndex = index
        index -= 1
        return lastIndex, currentLayer
    end
end

function Layers.withLayer(self: Layers, layer: Layer): Layers
    table.insert(self._layers, layer)
    return self
end

-- It has to do with roblox-ts. See in types/index.d.ts
-- (Layer class declaration) for the explanation
Layers.enabledAsLayer = Layers.enabled
Layers.eventEnabledAsLayer = Layers.eventEnabled

function Layers.enabled(self: Layers, metadata: Trail.Metadata, ctx: LayerContext?): boolean
    local context: LayerContext = ctx or self._context
    if not self._root:enabled(metadata) then
        return false
    end

    -- Check for other preceeding layers
    for _, layer in self:iter() do
        if not layer:enabledAsLayer(metadata, context) then
            return false
        end
    end

    return true
end

function Layers.maxLevelHint(_self: Layers): Trail.LevelFilter?
    error("TODO")
end

function Layers.newSpan(self: Layers, span: Trail.Attributes): Trail.Id
    local id = self._root:newSpan(span)
    for _, layer in self:iter() do
        layer:onNewSpan(span, id, self._context)
    end
    return id
end

function Layers.record(self: Layers, span: Trail.Id, values: Trail.Record)
    self._root:record(span, values)
    for _, layer in self:iter() do
        layer:onRecord(span, values, self._context)
    end
end

function Layers.eventEnabled(self: Layers, event: Trail.Event, ctx: LayerContext?): boolean
    local context: LayerContext = ctx or self._context
    if not self._root:eventEnabled(event) then
        return false
    end

    for _, layer in self:iter() do
        if not layer:eventEnabled(event, context) then
            return false
        end
    end

    return true
end

function Layers.event(self: Layers, event: Trail.Event)
    self._root:event(event)
    for _, layer in self:iter() do
        layer:onEvent(event, self._context)
    end
end

function Layers.enter(self: Layers, span: Trail.Id)
    self._root:enter(span)
    for _, layer in self:iter() do
        layer:onEnter(span, self._context)
    end
end

function Layers.exit(self: Layers, span: Trail.Id)
    self._root:exit(span)
    for _, layer in self:iter() do
        layer:onExit(span, self._context)
    end
end

function Layers.cloneSpan(self: Layers, old: Trail.Id): Trail.Id
    local new = self._root:cloneSpan(old)
    if new ~= old then
        for _, layer in self:iter() do
            layer:onIdChange(old, new, self._context)
        end
    end
    return new
end

function Layers.dropSpan(self: Layers, id: Trail.Id)
    self:tryClose(id)
end

function Layers.tryClose(self: Layers, id: Trail.Id): boolean
    if not self._root:tryClose(id) then
        return false
    end

    for _, layer in self:iter() do
        layer:onClose(id, self._context)
    end
    return true
end

function Layers.currentSpan(self: Layers): Trail.Id?
    return self._root:currentSpan()
end

function Layers.onRegisterDispatch(self: Layers, subscriber: Trail.Dispatch)
    for _, layer in self:iter() do
        layer:onRegisterDispatch(subscriber)
    end
end

function Layers.onLayer(self: Layers, subscriber: Trail.Subscriber)
    for _, layer in self:iter() do
        layer:onLayer(subscriber)
    end
end

function Layers.onNewSpan(self: Layers, attrs: Trail.Attributes, id: Trail.Id, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onNewSpan(attrs, id, ctx)
    end
end

function Layers.onRecord(self: Layers, span: Trail.Id, values: Trail.Record, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onRecord(span, values, ctx)
    end
end

function Layers.onFollowsFrom(self: Layers, span: Trail.Id, follows: Trail.Id, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onFollowsFrom(span, follows, ctx)
    end
end

function Layers.onEvent(self: Layers, event: Trail.Event, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onEvent(event, ctx)
    end
end

function Layers.onEnter(self: Layers, id: Trail.Id, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onEnter(id, ctx)
    end
end

function Layers.onExit(self: Layers, id: Trail.Id, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onExit(id, ctx)
    end
end

function Layers.onClose(self: Layers, id: Trail.Id, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onClose(id, ctx)
    end
end

function Layers.onIdChange(self: Layers, old: Trail.Id, new: Trail.Id, ctx: LayerContext)
    for _, layer in self:iter() do
        layer:onIdChange(old, new, ctx)
    end
end

return Layers
