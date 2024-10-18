export type FieldSet = { [string]: any }
export type Level = number
export type Id = string

export type Event = {
    fields: FieldSet,
    metadata: Metadata,
}

export type Metadata = {
    -- The name of the span described by this metadata.
    name: string,

    -- Part of the system that the span that this metadata
    -- describes occurred in.
    target: string,

    -- The level of verbosity of the described span.
    level: number,

    -- The source script where the span occurred.
    script: Script,

    -- Line number in the source code file where the span occurred
    line: number,

    -- The names of the key-value fields attached to the
    -- described span or event
    fields: FieldSet,

    -- The kind of the callsite.
    kind: "EVENT" | "SPAN",
}

local Symbol = require("@src/Symbol")

return {
    generateSpanId = function(): string
        return game:GetService("HttpService"):GenerateGUID(false)
    end,

    Nil = Symbol.named("<trail.core.Nil>"),
    RemoveField = Symbol.named("<trail.core.RemoveField>"),
}
