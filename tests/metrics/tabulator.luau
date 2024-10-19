--!native
--!strict
--!optimize 2

local Average = require("./average")
local Tabulator = {}

export type TabulateResult = {
    average: number,
    minimum: number,
    maximum: number,
    total: number,
    ranges: { { min: number, max: number, counts: number } },
    deviation: number,

    tenthTile: number,
    fiftiethTile: number,
    ninetiethTile: number,
}

local function getPercentileOfList<T>(list: { T }, percentile: number): T
    assert(type(list) == "table", "")
    assert(#list > 1, "")

    local rank = percentile / 100
    local totalElements = #list
    local nthNumber = math.round(rank * totalElements)
    assert(nthNumber <= totalElements, "")

    return list[nthNumber]
end

function Tabulator.tabulateResults<T>(
    list: { T },
    rangeDetail: number,
    callback: (T) -> number
): TabulateResult
    local average = Average.new()
    local minimum = math.huge
    local maximum = 0
    local total = 0

    local stdSum = 0

    local tabulated = {}
    local ranges = {}

    for _, element in ipairs(list) do
        table.insert(tabulated, callback(element))
    end

    for _, value in ipairs(tabulated) do
        if value < minimum then
            minimum = value
        end
        if value >= maximum then
            maximum = value
        end
        total += value
        average:add(value)
    end

    local avg = average:calculate()
    for _, value in ipairs(tabulated) do
        stdSum += (value - avg) ^ 2
    end

    local deviation = math.sqrt(stdSum / #list)
    local difference = maximum - minimum
    local stepGap = difference / rangeDetail
    for i = 1, rangeDetail do
        local rangeMin = minimum + stepGap * (i - 1)
        local rangeMax = minimum + stepGap * i
        local counts = 0
        for _, value in ipairs(tabulated) do
            if value >= rangeMin and value <= rangeMax then
                counts += 1
            end
        end
        table.insert(ranges, {
            min = rangeMin,
            max = rangeMax,
            counts = counts,
        })
    end

    -- Calculating 25th, 50th, and 100th percentiles
    table.sort(tabulated, function(a, b)
        return a < b
    end)

    local tenthTile = getPercentileOfList(tabulated, 10)
    local fiftiethTile = getPercentileOfList(tabulated, 50)
    local ninetiethTile = getPercentileOfList(tabulated, 90)

    return {
        average = avg,
        minimum = minimum,
        maximum = maximum,
        total = total,
        ranges = ranges,
        deviation = deviation,

        tenthTile = tenthTile,
        fiftiethTile = fiftiethTile,
        ninetiethTile = ninetiethTile,
    }
end

return Tabulator
