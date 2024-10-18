--!strict
local Span = require("@src/Span")
local Subscriber = require("@src/Subscriber")

local Dispatch = {}

export type Dispatch = typeof(Dispatch)
type Span = Span.Span
type Subscriber = Subscriber.Subscriber

local DEFAULT_SUBSCRIBER: Subscriber?
local LOCAL_SUBSCRIBERS: { [thread]: Subscriber } = {}

-- Stores any entered span from every running thread
--
-- A thread can be GC'ed if a thread is considered 'dead'
-- by using `coroutine.running()` function.
local SPAN_TREES: { [thread]: { Span } } = {}

function Dispatch.getLocalSubscriber(): Subscriber?
    -- Get the local subscriber if it is set by the user
    local currentThread = coroutine.running()
    local localSubsriber = LOCAL_SUBSCRIBERS[currentThread]
    if localSubsriber ~= nil then
        return localSubsriber
    end

    -- Try to get the default subscriber
    return DEFAULT_SUBSCRIBER
end

function Dispatch.clearDefaultSubscriber()
    assert(DEFAULT_SUBSCRIBER ~= nil, "Already unset global default subscriber")
    DEFAULT_SUBSCRIBER = nil
end

function Dispatch.setDefaultSubscriber(subscriber: Subscriber)
    assert(DEFAULT_SUBSCRIBER == nil, "Already set global default subscriber")
    DEFAULT_SUBSCRIBER = subscriber
end

function Dispatch.withSubscriber(subscriber: Subscriber, fn: () -> ())
    local currentThread = coroutine.running()
    local localSubscriber = LOCAL_SUBSCRIBERS[currentThread]
    assert(localSubscriber == nil, "Already set local subscriber")
    LOCAL_SUBSCRIBERS[currentThread] = subscriber
    fn()
    LOCAL_SUBSCRIBERS[currentThread] = nil
end

function Dispatch.getLocalSpanTree(): { Span }
    local currentThread = coroutine.running()
	local spanTrees = SPAN_TREES[currentThread]
    -- create one automatically if it is not defined yet.
	if spanTrees == nil then
		spanTrees = {}
		SPAN_TREES[currentThread] = spanTrees
	end
	return spanTrees
end

function Dispatch.currentSpan(): Span
    local localTree = Dispatch.getLocalSpanTree()
    local currentSpan = localTree[#localTree]
    if currentSpan ~= nil then
        return currentSpan
    else
        return Span.none()
    end
end

-- If G.__TRACING_DEV__ set to true, we can monitor any leaking spans
-- that will eventually leak in the production
if _G.__TRACING_DEV__ == true then
	print("[trail::dispatcher] started monitoring for memory leaks")

	local every = require("@src/core/every")
	every(1, function()
		for thread in pairs(SPAN_TREES) do
			if coroutine.status(thread) == "dead" then
				print(`[trail::dispatcher] cleaning dead {tostring(thread)}'s span tree`)
				SPAN_TREES[thread] = nil
			end
		end
	end)
	every(1, function()
		for t, v in pairs(SPAN_TREES) do
			if coroutine.status(t) == "dead" then
				print(`[trail::dispatcher] got leftover span tree from {tostring(t)}`, v)
			end
		end
	end)
end

return Dispatch
