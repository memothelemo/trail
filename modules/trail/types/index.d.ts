/* eslint-disable roblox-ts/no-namespace-merging */

// Base types
declare namespace Trail {
    enum Level {
        Trace = 0,
        Debug = 1,
        Info = 2,
        Warn = 3,
        Error = 4,
    }

    enum LevelFilter {
        OFF = 0,
        TRACE = 1,
        DEBUG = 2,
        INFO = 3,
        WARN = 4,
        ERROR = 5,
    }
}

// Subscriber
declare namespace Trail {
    abstract class Subscriber {
        public static setGlobalDefault(subscriber: Subscriber): void;
        public static withDefault<T>(subscriber: Subscriber, fn: () => T): T;

        public abstract enabled(metadata: Metadata): boolean;
        public abstract newSpan(span: Attributes): SpanId;

        public abstract record(span: SpanId, values: Trail.Record): void;
        public abstract recordFollowsFrom(span: SpanId, follows: SpanId): void;

        public abstract event(event: Event): void;
        public abstract enter(span: SpanId): void;
        public abstract exit(span: SpanId): void;

        public maxLevelHint(): LevelFilter;
        public eventEnabled(event: Event): boolean;
        public cloneSpan(span: SpanId): SpanId;
        public currentSpan(): SpanId | undefined;
        public tryClose(id: SpanId): boolean;
    }
}

// Dispatcher
declare namespace Trail {
    interface Dispatch {
        is(value: Subscriber): void;
        maxLevelHint(): LevelFilter;
        newSpan(span: Attributes): SpanId;

        record(span: SpanId, values: Trail.Record): void;
        recordFollowsFrom(span: SpanId, follows: SpanId): void;

        enabled(metadata: Metadata): boolean;
        event(event: Event): void;

        enter(span: SpanId): void;
        exit(span: SpanId): void;
        cloneSpan(span: SpanId): SpanId;
        currentSpan(): SpanId | undefined;
    }
}

// Event
declare namespace Trail {
    interface Event {
        fields: ValueSet;
        metadata: Metadata;
        parent: Parent;
    }

    const Event: {
        new (metadata: Metadata, fields: ValueSet): Event;

        dispatch: (metadata: Metadata, fields: ValueSet) => void;
        newChildOf: (parent: SpanId, metadata: Metadata, fields: ValueSet) => Event;
        childOf: (parent: SpanId, metadata: Metadata, fields: ValueSet) => void;

        isRoot(event: Event): boolean;
        isContextual(event: Event): boolean;

        getParentId(event: Event): SpanId | undefined;
    };
}

// Span
declare namespace Trail {
    interface Span {
        inner?: SpanInner;
        metadata?: Metadata;

        enter(): void;
        exit(): void;
        inScope<T>(fn: () => T): void;

        hasField(field: string): boolean;

        isEnabled(): this is Span & { inner: SpanInner };
        isDisabled(): this is Span & { inner: undefined };
        isNone(): this is Span & { inner: undefined; metadata: undefined };

        followsFrom(from: SpanId): void;
    }

    interface SpanInner {
        id: SpanId;
    }

    const Span: {
        new (metadata: Metadata, values: ValueSet): Span;
        newRoot: (metadata: Metadata, values: ValueSet) => Span;
        childOf: (parent: SpanId | undefined, metadata: Metadata, values: ValueSet) => Span;
        newDisabled: (metadata: Metadata) => Span;
        none: () => Span;

        Attributes: {
            new (metadata: Metadata, values: ValueSet): Attributes;

            newRoot(metadata: Metadata, values: ValueSet): Attributes;
            childOf(parent: SpanId, metadata: Metadata, values: ValueSet): Attributes;

            getParent(attributes: Attributes): SpanId | undefined;
        };

        Parent: {
            Root: RootParent;
            Current: CurrentParent;
            Explicit: ExplicitParent;

            isExplicit: (value: Parent) => value is ExplicitParent;
            isRoot: (value: Parent) => value is RootParent;
            isCurrent: (value: Parent) => value is CurrentParent;

            getParentId: <T extends Parent>(
                value: T,
            ) => T extends ExplicitParent ? T["id"] : string | undefined;
        };
    };

    type SpanId = string & {
        /**
         * @hidden
         * @deprecated
         */
        readonly __nominal_SpanId: unique symbol;
    };

    type FieldSet = string[];
    type ValueSet = unknown[];

    interface Metadata {
        // The name of the span described by this metadata.
        name: string;

        // Part of the system that the span that this metadata
        // describes occurred in.
        target: string;

        // The level of verbosity of the described span.
        level: Level;

        // The source script where the span occurred.
        script: Script;

        // Line number in the source code file where the span occurred
        line: number;

        // The names of the key-value fields attached to the
        // described span or event
        fields: FieldSet;

        // The kind of the callsite.
        kind: "EVENT" | "SPAN";
    }

    type RootParent = {
        /**
         * @deprecated
         * @hidden
         */
        readonly __nominal_TrailRootParent: unique symbol;
    };

    type CurrentParent = {
        /**
         * @deprecated
         * @hidden
         */
        readonly __nominal_TrailCurrentParent: unique symbol;
    };

    type ExplicitParent = {
        /**
         * @deprecated
         * @hidden
         */
        readonly __nominal_TrailExplicitParent: unique symbol;
        id: string;
    };

    type Parent = RootParent | CurrentParent | ExplicitParent;

    interface Attributes {
        metadata: Metadata;
        values: ValueSet;
        parent: Parent;
    }

    const Attributes: {
        new (metadata: Metadata, values: ValueSet): Attributes & { parent: CurrentParent };
        newRoot: (metadata: Metadata, values: ValueSet) => Attributes & { parent: RootParent };
        childOf: (
            parent: SpanId,
            metadata: Metadata,
            values: ValueSet,
        ) => Attributes & { parent: ExplicitParent };

        getParent: (attrs: Attributes) => SpanId | undefined;
        isRoot: (attrs: Attributes) => boolean;
        isContextual: (attrs: Attributes) => boolean;
    };

    interface Record {
        values: ValueSet;
    }
}

export = Trail;
export as namespace Trail;
