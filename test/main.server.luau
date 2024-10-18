--!strict

-- roblox libraries are coming too JS..
_G.NOCOLOR = true
_G.__TRACING_DEV__ = true

local Jest = require("@DevPackages/Jest")

local runCLIOptions = {
	verbose = true,
	ci = false,
}

local status, result = Jest
    .runCLI(script, runCLIOptions, {
        script.Parent:WaitForChild("specs")
    })
    :awaitStatus()

if status == "Rejected" then
    print(result)
end
