local Trail = require("@src")

local Dispatch = require("@src/Dispatch")
local JestGlobals = require("@DevPackages/JestGlobals")

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach

local GlobalSubscriber = Trail.Subscriber.extend("GlobalSubscriber")
local IsolatedSubscriber = Trail.Subscriber.extend("IsolatedSubscriber")

beforeEach(function()
    if Dispatch.getLocalSubscriber() ~= nil then
        Dispatch.clearDefaultSubscriber()
    end
end)

describe("setDefaultSubscriber", function()
    it("should set default subscriber", function()
        Dispatch.setDefaultSubscriber(GlobalSubscriber)
        expect(Dispatch.getLocalSubscriber()).toBe(GlobalSubscriber)
    end)

    it("should throw if default subscriber has already set", function()
        expect(function()
            Dispatch.setDefaultSubscriber(GlobalSubscriber)
        end).never.toThrow()

        expect(function()
            Dispatch.setDefaultSubscriber(GlobalSubscriber)
        end).toThrow()
    end)
end)

describe("withSubscriber", function()
    it("should throw if it is already overriden within a callback", function()
        Dispatch.setDefaultSubscriber(GlobalSubscriber)
        Dispatch.withSubscriber(IsolatedSubscriber, function()
            expect(function()
                Dispatch.withSubscriber(IsolatedSubscriber, function() end)
            end).toThrow()
        end)
    end)
end)

describe("getLocalSubscriber", function()
    it("should return nil if default subscriber has not been set", function()
        expect(Dispatch.getLocalSubscriber()).toBeNil()
    end)

    it("should use default subscriber", function()
        Dispatch.setDefaultSubscriber(GlobalSubscriber)
        expect(Dispatch.getLocalSubscriber()).toBe(GlobalSubscriber)
    end)

    it("should use overriden subscriber if it is used with withSubscriber", function()
        Dispatch.setDefaultSubscriber(GlobalSubscriber)
        Dispatch.withSubscriber(IsolatedSubscriber, function()
            expect(Dispatch.getLocalSubscriber()).toBe(IsolatedSubscriber)
        end)
        expect(Dispatch.getLocalSubscriber()).toBe(GlobalSubscriber)
    end)
end)

return nil
