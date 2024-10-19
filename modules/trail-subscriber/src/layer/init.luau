--!strict
--!optimize 2

local LayerContext = require("./context")
local Trail = require("@Trail/")

local Layer = {}
Layer.__index = Layer

export type Layer = typeof(Layer)
type LayerContext = LayerContext.LayerContext

function Layer.is(obj: any): boolean
    if type(obj) ~= "table" then
        return false
    end
    return getmetatable(obj).__index == Layer
end

function Layer:constructor() end
function Layer.onRegisterDispatch(_self: Layer, _subscriber: Trail.Dispatch) end
function Layer.onLayer(_self: Layer, _subscriber: Trail.Subscriber) end
function Layer.enabled(_self: Layer, _metadata: Trail.Metadata, _ctx: LayerContext): boolean
    return true
end
function Layer.onNewSpan(
    _self: Layer,
    _attrs: Trail.Attributes,
    _id: Trail.Id,
    _ctx: LayerContext
)
end
function Layer.maxLevelHint(_self: Layer): Trail.LevelFilter?
    return nil
end
function Layer.onRecord(
    _self: Layer,
    _span: Trail.Id,
    _values: Trail.Record,
    _ctx: LayerContext
)
end
function Layer.onFollowsFrom(
    _self: Layer,
    _span: Trail.Id,
    _follows: Trail.Id,
    _ctx: LayerContext
)
end
function Layer.eventEnabled(_self: Layer, _event: Trail.Event, _ctx: LayerContext): boolean
    return true
end
function Layer.onEvent(_self: Layer, _event: Trail.Event, _ctx: LayerContext) end
function Layer.onEnter(_self: Layer, _id: Trail.Id, _ctx: LayerContext) end
function Layer.onExit(_self: Layer, _id: Trail.Id, _ctx: LayerContext) end
function Layer.onClose(_self: Layer, _id: Trail.Id, _ctx: LayerContext) end
function Layer.onIdChange(_self: Layer, _old: Trail.Id, _new: Trail.Id, _ctx: LayerContext) end

------------------------------------------------------------------------------------------------

return Layer
