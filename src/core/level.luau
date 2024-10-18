--!strict
local Level = {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warn = 3,
    Error = 4,
}

-- Similar to TypeScript's enum system
Level[Level.Trace] = "Trace"
Level[Level.Debug] = "Debug"
Level[Level.Info] = "Info"
Level[Level.Warn] = "Warn"
Level[Level.Error] = "Error"

local LevelFilter = {
    OFF = 0,
    TRACE = 1,
    DEBUG = 2,
    INFO = 3,
    WARN = 4,
    ERROR = 5,
}

LevelFilter[LevelFilter.OFF] = "OFF"
LevelFilter[LevelFilter.TRACE] = "TRACE"
LevelFilter[LevelFilter.DEBUG] = "DEBUG"
LevelFilter[LevelFilter.INFO] = "INFO"
LevelFilter[LevelFilter.WARN] = "WARN"
LevelFilter[LevelFilter.ERROR] = "ERROR"

return {
    Level = Level,
    LevelFilter = LevelFilter,
}
