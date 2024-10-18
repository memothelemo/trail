local JestGlobals = require("@DevPackages/JestGlobals")

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

local Primitives = require("@src/core/primitives")

describe("generateSpanId", function()
    it("should generate a unique span ID", function()
        local id1 = Primitives.generateSpanId()
        local id2 = Primitives.generateSpanId()

        expect(id1).never.toBe(id2)
    end)

    it("should generate an ID with string type", function()
        local sample = Primitives.generateSpanId()
        expect(typeof(sample)).toBe("string")
    end)

    it("should generate a non-empty span ID", function()
        local sample = Primitives.generateSpanId()

        expect(sample:len()).never.toBe(0)
    end)
end)

return nil
