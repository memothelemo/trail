--!strict
--!optimize 2

local Layer = require("./layer")
local LayerContext = require("./layer/context")
local Layers = require("./layers")

local Registry = require("./registry")
local RegistrySpanTypes = require("./registry/span")
local SpanStack = require("./registry/stack")

export type LookupSpan = RegistrySpanTypes.LookupSpan
export type SpanData = RegistrySpanTypes.SpanData
export type SpanRef = RegistrySpanTypes.SpanRef

export type Layer = Layer.Layer
export type LayerContext = LayerContext.LayerContext

export type Registry = Registry.Registry
export type SpanStack = SpanStack.SpanStack

return {
    Layer = Layer,
    Layers = Layers,
    LayerContext = LayerContext,
    Registry = Registry,
    SpanData = RegistrySpanTypes.SpanData,
    SpanRef = RegistrySpanTypes.SpanRef,

    implementsLookupSpan = RegistrySpanTypes.implementsLookupSpan,
}
