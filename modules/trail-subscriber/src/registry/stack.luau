--!strict
--!optimize 2

local Trail = require("@Trail/")

--[[
    `SpanStack` tracks what spans are currently executing on
    a thread-local basis.
]]
local SpanStack = {}

type ContextId = {
    id: Trail.Id,
    duplicate: boolean,
}

export type SpanStack = typeof(SpanStack) & {
    _currentThreads: { [thread]: SpanStack },
    _stack: { ContextId },
}

function SpanStack.new(): SpanStack
    local self = setmetatable({
        _stack = {},
    }, {
        __index = SpanStack,
    })
    return (self :: never) :: SpanStack
end

function SpanStack.current(self: SpanStack): Trail.Id?
    for i = #self._stack, 1, -1 do
        local context = self._stack[i]
        if not context.duplicate then
            return context.id
        end
    end
    return nil
end

function SpanStack.push(self: SpanStack, id: Trail.Id): boolean
    local duplicate = false
    for _, v in ipairs(self._stack) do
        if v.id == id then
            duplicate = true
            break
        end
    end
    table.insert(self._stack, {
        id = id,
        duplicate = duplicate,
    })
    return not duplicate
end

function SpanStack.pop(self: SpanStack, id: Trail.Id): boolean
    local idx = nil
    for i, v in ipairs(self._stack) do
        if v.id == id then
            idx = i
            break
        end
    end
    if idx == nil then
        return false
    end

    local contextId = self._stack[idx]
    table.remove(self._stack, idx)
    return not contextId.duplicate
end

return SpanStack
