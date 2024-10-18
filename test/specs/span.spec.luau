local JestGlobals = require("@DevPackages/JestGlobals")

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

local Trail = require("@src")
local Span = Trail.Span

describe("constructors", function()
    describe("new", function()
        it("should have span.id and span.metadata defined", function()
            local span = Span.new({} :: never)
            expect(span).toBeDefined()
            expect(typeof(span.id)).toBe("string")
            expect(typeof(span.metadata)).toBe("table")
        end)
    
        it("should throw if metadata is not defined", function()
            expect(Span.new).toThrow()
        end)
    end)
    
    describe("none", function()
        it("should not have span.id and span.metadata defined", function()
            local span = Span.none()
            expect(span).toBeDefined()
            expect(span.id).toBeNil()
            expect(span.metadata).toBeNil()
        end)
    end)

    describe("current", function()
        it("should be implemented", function()
            expect(function()
                Span.current()
            end).never.toThrow("Cannot execute `Span.current()`, maybe it is a bug!")
        end)

        it("should return as none if it has not entered on a local thread", function()
            local span = Span.current()
            expect(span.id).toBeNil()
            expect(span.metadata).toBeNil()
        end)
    end)
end)

describe("isNone", function()
    it("should return true if it is made with Span.none()", function()
        local span = Span.none()
        expect(span:isNone()).toBe(true)
    end)

    it("should return false if it is made with Span.new(...)", function()
        local span = Span.new({})
        expect(span:isNone()).toBe(false)
    end)
end)

describe("hasField", function()
    it("should return true if a field does exists", function()
        local span = Span.new({ fields = {} })
        span:record("name", "John")

        expect(span:hasField("name")).toBe(true)
    end)

    it("should return false if a field does not exists", function()
        local span = Span.new({ fields = {} })

        expect(span:hasField("name")).toBe(false)
    end)
end)

describe("record", function()
    it("should record a field if a value is not nil", function()
        local span = Span.new({ fields = {} })
        span:record("name", "John")

        expect(span.metadata).toBeDefined()
        expect(span.metadata.fields["name"]).toBe("John")
    end)

    it("should remove a field if a value passed through with Trail.RemoveField", function()
        local span = Span.new({ fields = {} })
        span:record("name", "John")
        span:record("name", Trail.RemoveField)

        expect(span.metadata).toBeDefined()
        expect(span.metadata.fields["name"]).toBeNil()
    end)

    it("should set in internal field as Trail.Nil if the value argument is nil", function()
        local span = Span.new({ fields = {} })
        span:record("name", nil)

        expect(span.metadata).toBeDefined()
        expect(span.metadata.fields["name"]).toBe(Trail.Nil)
    end)
end)
