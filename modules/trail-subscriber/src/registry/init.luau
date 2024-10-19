--!strict
--!optimize 2

local Trail = require("@Trail/")

local Attributes = Trail.Span.Attributes
local SpanStack = require("./stack")

-- Registry is a subscriber
local Registry = setmetatable({}, {
    __index = Trail.Subscriber,
})

--[[
    This is our own local copy of a Span because by design,
    tracing doesn't allow us to keep Span values.
]]
type LocalSpanCopy = {}

export type Registry = typeof(Registry) & Trail.Subscriber & {
    _currentSpans: { [thread]: SpanStack.SpanStack },
    _spans: { [Trail.Id]: Trail.Span },
}

function Registry.new(): Registry
    local self = setmetatable({
        _currentSpans = {},
        _spans = {},
    }, Registry)

    return (self :: never) :: Registry
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
    return ""
end

return (Registry :: never) :: Registry
