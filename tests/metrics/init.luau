--!native
--!strict
--!optimize 2

--[[
    Less capable version of boatbomer's benchmark plugin
]]
local Metrics = {}

local Average = require("./average")
local Tabulator = require("./tabulator")
local prettifyTime = require("./prettifyTime")

local DEFAULT_ITERATIONS = 100

export type Metrics = typeof(Metrics) & {
    _rangeDetail: number,
    _tests: { TestMetadata },

    -- These fields will be used when it is performing tests
    _currentFunction: number?,
    _labels: { LabelMetadata },
}

type TestMetadata = {
    name: string,
    iterations: number?,
    precall: (() -> ())?,
    callback: (Metrics) -> (),
    cleanup: (() -> ())?,
}

type LabelMetadata = {
    -- If there's some delay when marking a label, we can deduct
    -- it to the overall sample time as long as it is not as drastic
    -- as our calulated sample time.
    delay: number,
    name: string,
    -- Timestamp of when a label was marked
    timestamp: number,
}

export type MetricsOptions = {
    rangeDetail: number?,
}

local DEFAULT_OPTIONS = {
    rangeDetail = 10,
}

function Metrics.new(options: MetricsOptions?): Metrics
    if options == nil then
        options = DEFAULT_OPTIONS
    end

    local opts = (options :: never) :: MetricsOptions
    local self = setmetatable({
        _rangeDetail = opts.rangeDetail or DEFAULT_OPTIONS.rangeDetail,
        _tests = {},

        _currentFunction = nil,
        _labels = table.create(5),
    }, {
        __index = Metrics,
    })
    assert(type(self._rangeDetail) == "number", "options.rangeDetail must be a number")
    assert(self._rangeDetail > 0, "options.rangeDetail must be greater than 0")
    return (self :: never) :: Metrics
end

function Metrics.performTests(self: Metrics)
    assert(self._currentFunction == nil, "You cannot perform tests while it is performing tests")

    --[[
        Roblox engine may lag when it is first initialized especially
        when we use Roblox Studio. We give Roblox some time to initialize
        and stabilize themself.

        We can tell if the Roblox engine is stabilized if the physics step
        delta is less than around 120 sps. (physics step/second)
    ]]
    print("[metrics] waiting for Roblox engine to initialize and stabilize itself...")
    self:_waitForRobloxEngine()

    --[[
        Sampling time! The fun part.
    ]]
    local results: { TestResult } = {}
    for id = 1, #self._tests do
        table.insert(results, self:_performTest(id))
        task.wait()
    end

    print("=== TEST RESULTS ===")
    for _, result in results do
        self:_printTestResult(result)
    end
end

function Metrics.label(self: Metrics, name: string)
    local startTimestamp = os.clock()
    assert(
        self._currentFunction ~= nil,
        "Invalid use of `:label(...)` (it must be used within a test function)"
    )
    assert(type(name) == "string", "expected `name` argument")

    local timestamp = os.clock()
    local delay = timestamp - startTimestamp
    table.insert(self._labels, {
        delay = delay,
        name = name,
        timestamp = timestamp,
    })
end

function Metrics.testFunction(
    self: Metrics,
    name: string,
    callback: (metrics: Metrics) -> (),
    precall: (() -> ())?,
    cleanup: (() -> ())?,
    iterations: number?
)
    if iterations ~= nil then
        assert(type(iterations) == "number", "iterations (in the 2nd argument) must be a number")
        assert(iterations > 0, "`iterations` argument must be greater than 0")
    end
    table.insert(self._tests, {
        name = name,
        iterations = iterations or DEFAULT_ITERATIONS,
        precall = precall,
        cleanup = cleanup,
        callback = callback,
    })
end

type TestSampleResult = {
    -- The actual "how long it takes to run a test function"
    elapsed: number,
    labels: { LabelMetadata },
    -- This will go handy with labels later on.
    startTimestamp: number,
}

type TestResult = {
    name: string,
    iterations: number,
    samples: { TestSampleResult },
}

function Metrics._printTestResult(self: Metrics, result: TestResult)
    assert(self._currentFunction == nil, "")

    type UnorganizedLabelData = LabelMetadata & {
        endTimestamp: number,
    }

    local unorganizedLabels: { UnorganizedLabelData } = {}
    local samplesResult = Tabulator.tabulateResults(
        result.samples,
        self._rangeDetail,
        function(sample)
            -- Calculate the ACTUAL TIME SPENT on every sample by deducting some delay with labels
            local totalLabelsDelay = 0
            local endTimestamp = sample.startTimestamp + sample.elapsed
            for _, label in sample.labels do
                totalLabelsDelay += label.delay
                unorganizedLabels[#unorganizedLabels + 1] = {
                    delay = label.delay,
                    name = label.name,
                    timestamp = label.timestamp,
                    endTimestamp = endTimestamp,
                }
            end

            local actualElapsed = sample.elapsed - totalLabelsDelay
            return actualElapsed
        end
    )

    print(`• {result.name} ({result.iterations} iterations)`)
    print(`    > Average: {prettifyTime(samplesResult.average)}`)
    print(`    > Deviation: {prettifyTime(samplesResult.deviation)}`)
    print(`    > 10th %: {prettifyTime(samplesResult.tenthTile)}`)
    print(`    > 50th %: {prettifyTime(samplesResult.fiftiethTile)}`)
    print(`    > 90th %: {prettifyTime(samplesResult.ninetiethTile)}`)
    print(`    > Minimum: {prettifyTime(samplesResult.minimum)}`)
    print(`    > Maximum: {prettifyTime(samplesResult.maximum)}`)
    print(`    > Total: {prettifyTime(samplesResult.total)}`)

    for _, range in samplesResult.ranges do
        if range.counts == 0 then
            continue
        end
        local percentage = string.format("%.2f%s", range.counts / result.iterations * 100, "%")
        print(
            `    \{{prettifyTime(range.min)}-{prettifyTime(range.max)}\}: {range.counts} ({percentage})`
        )
    end

    -- Isolate each labels into groups
    local labels: { [string]: { { value: number, delay: number } } } = {}
    for _, label in unorganizedLabels do
        local array = labels[label.name]
        if array == nil then
            array = table.create(result.iterations)
            labels[label.name] = array
        end
        table.insert(array, {
            value = label.endTimestamp - label.timestamp,
            delay = label.delay,
        })
    end

    for labelName, labelSamples in labels do
        local averageDelay = Average.new()
        local totalDelay = 0

        local labelSampleResult = Tabulator.tabulateResults(
            labelSamples,
            self._rangeDetail,
            function(sample)
                averageDelay:add(sample.delay)
                totalDelay += sample.delay

                if sample.delay >= sample.value then
                    return sample.value
                end
                return sample.value - sample.delay
            end
        )
        print(`    • label: {labelName}`)
        print(`        > Average Delay: {prettifyTime(averageDelay:calculate())}`)
        print(`        > Total Delay: {prettifyTime(totalDelay)}`)
        print(`        > 10th %: {prettifyTime(labelSampleResult.tenthTile)}`)
        print(`        > 50th %: {prettifyTime(labelSampleResult.fiftiethTile)}`)
        print(`        > 90th %: {prettifyTime(labelSampleResult.ninetiethTile)}`)
        print(`        > Average: {prettifyTime(labelSampleResult.average)}`)
        print(`        > Deviation: {prettifyTime(labelSampleResult.deviation)}`)
        print(`        > Minimum: {prettifyTime(labelSampleResult.minimum)}`)
        print(`        > Maximum: {prettifyTime(labelSampleResult.maximum)}`)
        print(`        > Total: {prettifyTime(labelSampleResult.total)}`)
        for _, range in labelSampleResult.ranges do
            if range.counts == 0 then
                continue
            end
            local percentage = string.format("%.2f%s", range.counts / #labelSamples * 100, "%")
            print(
                `        \{{prettifyTime(range.min)}-{prettifyTime(range.max)}\}: {range.counts} ({percentage})`
            )
        end
    end
end

local SHOW_PROGRESS_INTERVAL_SECS = 3

function Metrics._performTest(self: Metrics, id: number, iterations: number?): TestResult
    assert(self._currentFunction == nil, "")

    local metadata = self._tests[id]
    assert(metadata ~= nil, `Unknown test {id}`)

    if iterations ~= nil then
        assert(type(iterations) == "number", "iterations (in the 2nd argument) must be a number")
        assert(iterations > 0, "`iterations` argument must be greater than 0")
    else
        iterations = metadata.iterations
    end

    print(`[metrics] performing benchmark: "{metadata.name}"...`)
    self._currentFunction = id

    local progressTimestamp = os.clock()
    local callback = metadata.callback
    local samples: { TestSampleResult } = table.create(iterations :: never)
    if metadata.precall ~= nil then
        metadata.precall()
    end

    for n = 1, iterations :: never do
        local now = os.clock()
        local progressElapsed = now - progressTimestamp
        if progressElapsed > SHOW_PROGRESS_INTERVAL_SECS then
            progressTimestamp = now
            warn(`[metrics] waiting for "{metadata.name}" to end ({n}/{iterations})`)
        end

        local startTimestamp = os.clock()
        callback(self)

        local endTimestamp = os.clock()
        local elapsed = endTimestamp - startTimestamp
        table.insert(samples, {
            elapsed = elapsed,
            labels = self._labels,
            startTimestamp = startTimestamp,
        })

        self._labels = table.create(5)
    end
    if metadata.cleanup ~= nil then
        metadata.cleanup()
    end

    self._currentFunction = nil
    return {
        name = metadata.name,
        iterations = iterations :: never,
        samples = samples,
    }
end

-- selene: allow(unused_variable)
function Metrics._waitForRobloxEngine(self: Metrics)
    while true do
        local duration = game:GetService("RunService").Heartbeat:Wait()
        if duration < 0.1 then
            break
        end
    end
end

return Metrics
