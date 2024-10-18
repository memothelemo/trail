--!strict
--!optimize 2

local Dispatcher = require("@Trail/core/dispatcher")
local Primitives = require("@Trail/core/primitives")
local Span = require("@Trail/span")
local Subscriber = require("@Trail/core/subscriber")

export type FieldSet = Primitives.FieldSet
export type ValueSet = Primitives.ValueSet

export type Id = Primitives.Id
export type Span = Span.Span
export type Parent = Primitives.Parent

export type Metadata = Primitives.Metadata
export type Attributes = Primitives.Attributes
export type Record = Primitives.Record
export type Event = Primitives.Event

export type Dispatch = Dispatcher.Dispatch
export type Subscriber = Subscriber.Subscriber

local Trail = {
    Event = Primitives.Event,

    Level = Primitives.Level,
    LevelFilter = Primitives.LevelFilter,

    Span = Span,
    Subscriber = Subscriber,
}

-- Implementing unimplemented functions --
function Primitives.Event.dispatch(metadata: Metadata, fields: ValueSet)
    local event = Primitives.Event.new(metadata, fields)
    Dispatcher.getDefault(function(dispatch)
        dispatch:event(event)
    end)
end

function Primitives.Event.childOf(parent: Id, metadata: Metadata, fields: ValueSet)
    local event = Primitives.Event.newChildOf(parent, metadata, fields)
    Dispatcher.getDefault(function(dispatch)
        dispatch:event(event)
    end)
end

function Subscriber.setGlobalDefault(subscriber: Subscriber)
    Dispatcher.setGlobalDefault(Dispatcher.new(subscriber))
end

function Subscriber.withDefaultReturned<T>(subscriber: Subscriber, fn: () -> T): T
    return Dispatcher.withDefaultReturned(Dispatcher.new(subscriber), fn)
end

function Subscriber.withDefault(subscriber: Subscriber, fn: () -> ()): ()
    Dispatcher.withDefault(Dispatcher.new(subscriber), fn)
end

return Trail
