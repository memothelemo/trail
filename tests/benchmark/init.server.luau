--!optimize 2
--!native

local SpanStack = require("@TrailSubscriber/registry/stack")
local Trail = require("@Trail/")

local metrics = require("../metrics").new({ rangeDetail = 100 })

if _G.__TRAIL_RUN_BENCHMARKS__ ~= true then
    return
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
