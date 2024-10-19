--!strict
--!optimize 2

local Trail = require("@Trail/")

-- This data should be cached.
local SpanData = {}
SpanData.__index = SpanData

export type SpanData = typeof(SpanData)

function SpanData:constructor() end

-- selene: allow(unused_variable)
function SpanData.id(self: SpanData): Trail.Id
    error("[trail-subscriber::registry::span] Please implement `:id(...)`")
end

-- selene: allow(unused_variable)
function SpanData.metadata(self: SpanData): Trail.Metadata
    error("[trail-subscriber::registry::span] Please implement `:metadata(...)`")
end

-- selene: allow(unused_variable)
function SpanData.parent(self: SpanData): Trail.Id?
    error("[trail-subscriber::registry::span] Please implement `:metadata(...)`")
end

export type LookupSpan = {
    spanData: (self: LookupSpan, id: Trail.Id) -> any?,
    span: (self: LookupSpan, id: Trail.Id) -> SpanRef,
}

local SpanRef = {}
SpanRef.__index = SpanRef

export type SpanRef = typeof(SpanRef) & {
    _registry: LookupSpan,
    _data: SpanData,
}

function SpanRef.new(registry: LookupSpan, data: any): SpanRef
    local self = setmetatable({
        _registry = registry,
        _data = data,
    }, SpanRef)
    return (self :: never) :: SpanRef
end

function SpanRef.span(registry: LookupSpan, id: Trail.Id): SpanRef?
    local data = registry:spanData(id)
    if data == nil then
        return nil
    end
    return SpanRef.new(registry, data)
end

function SpanRef.id(self: SpanRef): Trail.Id
    return self._data:id()
end

function SpanRef.metadata(self: SpanRef): Trail.Metadata
    return self._data:metadata()
end

function SpanRef.fields(self: SpanRef): Trail.FieldSet
    return self._data:metadata().fields
end

function SpanRef.parent(self: SpanRef): SpanRef?
    local id = self._data:parent()
    if id == nil then
        return nil
    end
    local data = self._registry:spanData(id)
    if data ~= nil then
        return nil
    end
    return SpanRef.new(self._registry, data)
end

return {
    SpanData = SpanData,
    SpanRef = SpanRef,

    implementsLookupSpan = function(obj: any): boolean
        if type(obj) ~= "table" then
            return false
        end
        -- Checks if that obj is a subscriber
        local n = getmetatable(obj)
        while n ~= nil do
            if n == Trail.Subscriber then
                return obj["span"] ~= nil and obj["spanData"] ~= nil
            end
            local mt = getmetatable(n)
            if mt then
                n = mt.__index
            else
                n = nil
            end
        end
        return false
    end,
}
