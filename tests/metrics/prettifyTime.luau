--!strict
--!optimize 2
--!native

local UNITS = {
    [-3] = "ns",
    [-2] = "μs",
    [-1] = "ms",
    [0] = "s",
}

local function prettifyNumber(input: number): string
    if input ~= input then
        return "<unknown>"
    end

    if input > 60 then
        -- Do some good calculations
        local mins = math.floor(input / 60)
        local seconds = input % 60
        return `{mins}m {seconds}s`
    end

    local isNegative = math.sign(input) == -1
    local absInput = math.abs(input)

    local paired = false
    local output = ""

    for i in pairs(UNITS) do
        local unitBoundaryMin = 10 ^ (3 * i)
        local unitBoundaryMax = 10 ^ (3 * (i + 1))
        if input >= unitBoundaryMin and input <= unitBoundaryMax then
            local unit = UNITS[i]
            local MULTIPLER = 10 ^ (3 * -i)
            assert(unit ~= nil, "oops, a bug")
            output = string.format("%.2f%s", absInput * MULTIPLER, unit)
            paired = true
            break
        end
    end

    if not paired then
        local rounded = math.floor(input)
        output = tostring(rounded)
    end

    if isNegative then
        output = `-{output}`
    end

    return output
end

return prettifyNumber
