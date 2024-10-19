-- Load Trail module first

local SpanStack = require("@TrailSubscriber/registry/stack")

local JestGlobals = require("@DevPackages/JestGlobals")

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

describe("push", function()
    it("should return true if the span ID does not exists", function()
        local myStack = SpanStack.new()
        expect(myStack:push("1234")).toBeTruthy()
    end)

    it("should return false if it has already inserted existing span ID", function()
        local myStack = SpanStack.new()
        expect(myStack:push("1234")).toBeTruthy()
        expect(myStack:push("1234")).toBeFalsy()
    end)
end)

return nil
