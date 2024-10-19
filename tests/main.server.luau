--!strict

-- roblox libraries are coming too JS..
_G.NOCOLOR = true
_G.__TRAIL_DEV__ = false

if _G.__TRAIL_UNIT_TESTS__ ~= true then
    return
end

local Jest = require("@DevPackages/Jest")

local runCLIOptions = {
    verbose = true,
    ci = false,
}

local status, result = Jest.runCLI(script, runCLIOptions, {
    script.Parent:WaitForChild("specs"),
}):awaitStatus()

if status == "Rejected" then
    print(result)
end
