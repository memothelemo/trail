export type FieldSet = Record<string, defined>;
export type SpanId = string;

export interface Metadata {
    // The name of the span described by this metadata.
    name: string;

    // Part of the system that the span that this metadata
    // describes occurred in.
    target: string;

    // The level of verbosity of the described span.
    level: number;

    // The source script where the span occurred.
    scrit: Script;

    // Line number in the source code file where the span occurred
    line: number;

    // The names of the key-value fields attached to the
    // described span or event
    fields: FieldSet;

    // The kind of the callsite.
    kind: "EVENT" | "SPAN";
}

export interface Event {
    fields: FieldSet;
    metadata: Metadata;
}

export enum Level {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warn = 3,
    Error = 4,
}

export enum LevelFilter {
    OFF = 0,
    TRACE = 1,
    DEBUG = 2,
    INFO = 3,
    WARN = 4,
    ERROR = 5,
}

export interface Nil {
    /**
     * @hidden
     * @deprecated
     */
    readonly __nominal_TrailNil: unique symbol;
}

export interface RemoveField {
    /**
     * @hidden
     * @deprecated
     */
    readonly __nominal_TrailRemoveField: unique symbol;
}

/////////////////////////////////////////////////////////////////
export abstract class Subscriber {
    public eventEnabled(event: Event): boolean;
    public maxLevelHint(): Level;

    public abstract enabled(metadata: Metadata): boolean;
    public abstract event(event: Event): void;
    public abstract onSpanEnter(span: EnabledSpan): void;
    public abstract onSpanExit(span: EnabledSpan): void;

    protected currentSpan(): Span;
}


export interface EnabledSpan extends Span {
    id: string;
    metadata: Metadata;

    isEnabled(): this is EnabledSpan;
    isNone(): this is Span;
    isDisabled(): this is Span;
}

export interface Span {
    id?: string;
    metadata?: Metadata;

    enter(): void;
    leave(): void;
    hasField(field: string): boolean;
    inScope(fn: () => void): void;

    isEnabled(): this is EnabledSpan;
    isNone(): void;

    record(field: string, value: unknown | Nil | RemoveField): void;
}

declare namespace Trail {
    export const Span: {
        new (metadata: Metadata): EnabledSpan;
        current(): Span;
        none(): Span;
    };
}

export { Trail };
