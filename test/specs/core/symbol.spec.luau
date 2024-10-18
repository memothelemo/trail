local JestGlobals = require("@DevPackages/JestGlobals")

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

local Symbol = require("@src/Symbol")

describe("named", function()
    it("should give an opaque object", function()
        local symbol = Symbol.named("foo")
        
        expect(typeof(symbol)).toBe("userdata")
    end)

    it("should coerce to the given name", function()
        local symbol = Symbol.named("foo")
        local index = tostring(symbol):find("foo")
        
        expect(index).toBeDefined()
    end)

    it("should be unique when constructed", function()
        local symbolA = Symbol.named("abc")
        local symbolB = Symbol.named("abc")

        expect(symbolA).never.toBe(symbolB)
    end)
end)

return nil
