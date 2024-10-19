--!optimize 2
--!native
-- TODO: Cleanup this file

local SpanStack = require("@TrailSubscriber/registry/stack")
local Trail = require("@Trail/")
local TrailSubscriber = require("@TrailSubscriber/")

local metrics = require("../metrics").new({ rangeDetail = 100 })

if _G.__TRAIL_RUN_BENCHMARKS__ ~= true then
    return
end

local MyLayer = setmetatable({}, TrailSubscriber.Layer)
MyLayer.__index = MyLayer

type Layer = TrailSubscriber.Layer
type LayerContext = TrailSubscriber.LayerContext

function MyLayer.new()
    return setmetatable({}, MyLayer)
end

function MyLayer.onRegisterDispatch(_self: Layer, _subscriber: Trail.Dispatch) end
function MyLayer.onLayer(_self: Layer, _subscriber: Trail.Subscriber) end
function MyLayer.enabled(_self: Layer, _metadata: Trail.Metadata, _ctx: LayerContext): boolean
    return true
end
function MyLayer.onNewSpan(
    _self: Layer,
    _attrs: Trail.Attributes,
    _id: Trail.Id,
    _ctx: LayerContext
)
end
function MyLayer.maxLevelHint(_self: Layer): Trail.LevelFilter?
    return nil
end
function MyLayer.onRecord(
    _self: Layer,
    _span: Trail.Id,
    _values: Trail.Record,
    _ctx: LayerContext
)
end
function MyLayer.onFollowsFrom(
    _self: Layer,
    _span: Trail.Id,
    _follows: Trail.Id,
    _ctx: LayerContext
)
end

function MyLayer.eventEnabled(_self: Layer, _event: Trail.Event, _ctx: LayerContext): boolean
    return true
end

function MyLayer.onEvent(_self: Layer, _event: Trail.Event, _ctx: LayerContext) end
function MyLayer.onEnter(_self: Layer, _id: Trail.Id, _ctx: LayerContext) end
function MyLayer.onExit(_self: Layer, _id: Trail.Id, _ctx: LayerContext) end
function MyLayer.onClose(_self: Layer, _id: Trail.Id, _ctx: LayerContext) end
function MyLayer.onIdChange(_self: Layer, _old: Trail.Id, _new: Trail.Id, _ctx: LayerContext) end

do
    local subscriber = TrailSubscriber.Layers
        .new(TrailSubscriber.Registry.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())
        :withLayer(MyLayer.new())

    metrics:testFunction("dispatching event with a multiple layers", function()
        Trail.Subscriber.withDefault(subscriber, function()
            Trail.Event.dispatch({
                name = "test",
                target = "specs::dispatcher.spec",
                level = Trail.Level.Debug,
                fields = {},
                kind = "EVENT",
                line = 1,
                script = script,
            }, {})
        end)
    end, nil, nil, 5000)
end

do
    local subscriber =
        TrailSubscriber.Layers.new(TrailSubscriber.Registry.new()):withLayer(MyLayer.new())

    metrics:testFunction("dispatching event with a layer", function()
        Trail.Subscriber.withDefault(subscriber, function()
            Trail.Event.dispatch({
                name = "test",
                target = "specs::dispatcher.spec",
                level = Trail.Level.Debug,
                fields = {},
                kind = "EVENT",
                line = 1,
                script = script,
            }, {})
        end)
    end, nil, nil, 5000)
end

do
    local subscriber =
        TrailSubscriber.Layers.new(TrailSubscriber.Registry.new()):withLayer(MyLayer.new())

    metrics:testFunction("dispatching span with a layer", function()
        Trail.Subscriber.withDefault(subscriber, function()
            Trail.Span.new({
                name = "test",
                target = "specs::dispatcher.spec",
                level = Trail.Level.Debug,
                fields = {},
                kind = "SPAN",
                line = 1,
                script = script,
            }, {})
        end)
    end, nil, nil, 5000)
end

do
    local stack: SpanStack.SpanStack?
    metrics:testFunction("SpanStack.push (long; 5,000 elements)", function()
        (stack :: SpanStack.SpanStack):push("a")
    end, function()
        stack = SpanStack.new()
        for _ = 1, 5000 do
            (stack :: SpanStack.SpanStack):push(game:GetService("HttpService"):GenerateGUID(false))
        end
    end, function()
        stack = nil
    end, 5000)

    metrics:testFunction("SpanStack.push (duplicated; 5,000 elements)", function()
        (stack :: SpanStack.SpanStack):push("foo")
    end, function()
        stack = SpanStack.new();
        (stack :: SpanStack.SpanStack):push(game:GetService("HttpService"):GenerateGUID(false))
        for _ = 1, 5000 do
            if math.random() > 0.9 then
                (stack :: SpanStack.SpanStack):push("foo")
            else
                (stack :: SpanStack.SpanStack):push(
                    game:GetService("HttpService"):GenerateGUID(false)
                )
            end
        end
    end, function()
        stack = nil
    end, 5000)

    metrics:testFunction("SpanStack.pop (long; 5,000 elements)", function()
        (stack :: SpanStack.SpanStack):pop("a")
    end, function()
        stack = SpanStack.new()
        for _ = 1, 5000 do
            (stack :: SpanStack.SpanStack):push(game:GetService("HttpService"):GenerateGUID(false))
        end
        (stack :: SpanStack.SpanStack):push("a")
    end, function()
        stack = nil
    end, 5000)

    metrics:testFunction("SpanStack.pop (duplicated; 5,000 elements)", function()
        (stack :: SpanStack.SpanStack):pop("foo")
    end, function()
        stack = SpanStack.new();
        (stack :: SpanStack.SpanStack):push(game:GetService("HttpService"):GenerateGUID(false))
        for _ = 1, 5000 do
            if math.random() > 0.9 then
                (stack :: SpanStack.SpanStack):push("foo")
            else
                (stack :: SpanStack.SpanStack):push(
                    game:GetService("HttpService"):GenerateGUID(false)
                )
            end
        end
    end, function()
        stack = nil
    end, 5000)
end

do
    -- selene: allow(shadowing)
    metrics:testFunction("dispatching spans", function(metrics)
        metrics:label("new")
        local span = Trail.Span.new({
            name = "test",
            target = "specs::dispatcher.spec",
            level = Trail.Level.Debug,
            fields = {},
            kind = "SPAN",
            line = 1,
            script = script,
        }, {})

        metrics:label("enter")
        span:enter()

        metrics:label("exit")
        span:exit()
    end, nil, nil, 5000)

    metrics:testFunction("dispatching events", function()
        Trail.Event.dispatch({
            name = "test",
            target = "specs::dispatcher.spec",
            level = Trail.Level.Debug,
            fields = {},
            kind = "EVENT",
            line = 1,
            script = script,
        }, {})
    end, nil, nil, 5000)
end

metrics:performTests()
