--!strict
local Primitives = require("@src/core/primitives")

local Span = {}

export type Span = typeof(Span) & {
    -- Used to enter the span when it is not executing
	id: string?,
    --[[
        Metadata describing the span.

        This might be defined or nil, in the case that the
        span is disabled.
    ]]
    metadata: Primitives.Metadata?,
}

function Span.new(metadata: Primitives.Metadata)
    assert(type(metadata) == "table", "Missing `metadata` parameter")

    local self = setmetatable({
        id = Primitives.generateSpanId(),
        metadata = metadata,
    }, {
        __index = Span
    })
    return (self :: never) :: Span    
end

function Span.current(): Span
    error("Cannot execute `Span.current()`, maybe it is a bug!")
end

function Span.none()
    return (setmetatable({}, { __index = Span }) :: never) :: Span
end

-- selene: allow(unused_variable)
function Span.enter(self: Span)
    error("Cannot execute `Span.enter()`, maybe it is a bug!")
end

-- selene: allow(unused_variable)
function Span.leave(self: Span)
    error("Cannot execute `Span.leave()`, maybe it is a bug!")
end

function Span.hasField(self: Span, field: string): boolean
    if self.metadata ~= nil then
        return self.metadata.fields[field] ~= nil
    end
    return false
end

function Span.inScope(self: Span, fn: () -> ())
    self:enter()
    fn()
    self:leave()
end

-- roblox-ts compatibility
function Span.isEnabled(self: Span): boolean
    return self.metadata ~= nil
end

function Span.isNone(self: Span): boolean
    return self:isDisabled() and self.id == nil
end

function Span.isDisabled(self: Span): boolean
    return self.metadata == nil
end

function Span.record(self: Span, field: string, value: any)
    if self.metadata == nil then return end
	if value == Primitives.RemoveField then
		self.metadata.fields[field] = nil
		return
	end

	-- we don't have to reference any values
	-- just like tracing crate. :)
	if value == nil then
		value = Primitives.Nil
	else
		value = tostring(value)
	end
	self.metadata.fields[field] = value
end

return Span
