-- Load Trail module first
require("@Trail")

local Dispatcher = require("@Trail/core/dispatcher")
local NoSubscriber = require("@Trail/core/noSubscriber")
local Primitives = require("@Trail/core/primitives")
local Subscriber = require("@Trail/core/subscriber")

local JestGlobals = require("@DevPackages/JestGlobals")

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

local TEST_META: Primitives.Metadata = {
    name = "test",
    target = "specs::dispatcher.spec",
    level = Primitives.Level.Debug,
    fields = {},
    kind = "EVENT",
    line = 1,
    script = script,
}

local function emptyFn() end

describe("default subscriber", function()
    it("should default to NoSubscriber", function()
        Dispatcher.getDefault(function(dispatch)
            expect(dispatch:is(NoSubscriber)).toBe(true)
        end)
    end)
end)

describe("dispatching events", function()
    it("should not loop indefinitely", function()
        local EVENTS_EMITTED = 0

        local TestSubscriber = Subscriber.extend("TestSubscriber")
        function TestSubscriber:enabled()
            return true
        end

        function TestSubscriber:newSpan()
            return "0xAAA"
        end

        TestSubscriber.record = emptyFn
        TestSubscriber.recordFollowsFrom = emptyFn
        TestSubscriber.enter = emptyFn
        TestSubscriber.exit = emptyFn
        TestSubscriber.newSpan = emptyFn

        function TestSubscriber:event()
            if EVENTS_EMITTED > 0 then
                error("event method called twice!")
            end
            EVENTS_EMITTED += 1
            Primitives.Event.dispatch(TEST_META, {})
        end

        Dispatcher.withDefault(Dispatcher.new(TestSubscriber), function()
            Primitives.Event.dispatch(TEST_META, {})
        end)
    end)
end)

describe("dispatching spans", function()
    it("should not loop indefinitely", function()
        local SPANS_EMITTED = 0

        local function makeSpan()
            Dispatcher.getDefault(function(dispatch)
                dispatch:newSpan(Primitives.Attributes.new(TEST_META, {}))
            end)
        end

        local TestSubscriber = Subscriber.extend("TestSubscriber")
        function TestSubscriber:enabled()
            return true
        end

        function TestSubscriber:newSpan()
            if SPANS_EMITTED > 0 then
                error("newSpan method called twice!")
            end
            SPANS_EMITTED += 1
            makeSpan()
            return "0xAAA"
        end

        TestSubscriber.record = emptyFn
        TestSubscriber.recordFollowsFrom = emptyFn
        TestSubscriber.enter = emptyFn
        TestSubscriber.exit = emptyFn
        TestSubscriber.event = emptyFn

        Dispatcher.withDefault(Dispatcher.new(TestSubscriber), makeSpan)
    end)
end)
