--!strict
local Primitives = require("@src/core/primitives")
local Span = require("@src/Span")

type Span = Span.Span

local Subscriber = {}
Subscriber.__name = "Subscriber"

local SUBSCRIBER_METADATA = {
	__index = Subscriber,
	__tostring = function(self: { __name: string })
		return self.__name
	end,
}

export type Subscriber = typeof(Subscriber)

function Subscriber.extend(name: string): Subscriber
	assert(type(name) == "string", "Name must be a string or you should not use `:new()` in a subscriber.")

	local subscriber = {} 
	subscriber.__name = name
	setmetatable(subscriber, SUBSCRIBER_METADATA)

	return (subscriber :: never) :: Subscriber
end

-- selene: allow(unused_variable)
function Subscriber.enabled(self: Subscriber, metadata: Primitives.Metadata): boolean
	error("[trail::subscriber] Please implement `:enabled(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.event(self: Subscriber, event: Primitives.Event)
	error("[trail::subscriber] Please implement `:event(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.eventEnabled(self: Subscriber, event: Primitives.Event)
    return true
end

-- selene: allow(unused_variable)
function Subscriber.onSpanEnter(self: Subscriber, span: Span)
	error("[trail::subscriber] Please implement `:onSpanEnter(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.onSpanExit(self: Subscriber, span: Span)
	error("[trail::subscriber] Please implement `:onSpanExit(...)`")
end

-- selene: allow(unused_variable)
function Subscriber.maxLevelHint(self: Subscriber): Primitives.Level?
    return nil
end

-- selene: allow(unused_variable)
function Subscriber.currentSpan(self: Subscriber): Span
    error("Cannot execute `Subscriber.currentSpan()`, maybe it is a bug!")
end

return Subscriber
