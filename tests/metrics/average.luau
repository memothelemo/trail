--!strict
--!optimize 2
--!native

local Average = {}
Average.__index = Average

export type Average = typeof(Average) & {
    _samples: { number },
}

function Average.new(): Average
    return setmetatable({
        _samples = {},
    }, Average) :: never
end

function Average.add(self: Average, number: number)
    table.insert(self._samples, number)
end

function Average.calculate(self: Average): number
    -- You're not supposed to divide it by 0 so we let it return to 0
    if #self._samples == 0 then
        return 0
    end

    local sum = 0
    for _, entry in ipairs(self._samples) do
        sum += entry
    end
    return sum / #self._samples
end

return Average
