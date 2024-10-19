/* eslint-disable roblox-ts/no-namespace-merging */

import Trail from "@rbxts/trail";

// Registry
declare namespace TrailSubscriber {
    interface LookupSpan<D extends defined> extends Trail.Subscriber {
        getSpan(id: Trail.SpanId): D | undefined;
    }

    interface RegistrySpanData {
        metadata: Trail.Metadata;
        parent: Trail.SpanId | undefined;
    }

    class Registry extends Trail.Subscriber implements LookupSpan<RegistrySpanData> {
        protected _spanStack(): SpanStack;
        protected _getSpan(): RegistrySpanData;

        public enabled(metadata: Trail.Metadata): boolean;
        public newSpan(span: Trail.Attributes): Trail.SpanId;
        public record(span: Trail.SpanId, values: Trail.Record): void;
        public recordFollowsFrom(span: Trail.SpanId, follows: Trail.SpanId): void;
        public event(event: Trail.Event): void;
        public enter(span: Trail.SpanId): void;
        public exit(span: Trail.SpanId): void;
        public getSpan(id: Trail.SpanId): RegistrySpanData | undefined;
    }

    interface SpanStack {
        current(): Trail.SpanId | undefined;
        push(id: Trail.SpanId): boolean;
        pop(id: Trail.SpanId): boolean;
    }
}

// Layered
declare namespace TrailSubscriber {
    class Layered<L extends Layer<S>, S extends Trail.Subscriber>
        extends Layer<S>
        implements Trail.Subscriber
    {
        public constructor(layer: L, inner: S);
        public static is(obj: unknown): obj is Layered<Layer<Trail.Subscriber>, Trail.Subscriber>;

        protected _inner: S;
        protected _layer: L;

        protected _ctx(): LayerContext<S>;

        public enabledAsLayer(metadata: Trail.Metadata, ctx: LayerContext<S>): boolean;
        public eventEnabledAsLayer(event: Trail.Event): boolean;

        /** @hidden @deprecated */
        public enabled(metadata: Trail.Metadata): boolean;
        /** @hidden @deprecated */
        public eventEnabled(event: Trail.Event): boolean;

        public maxLevelHint(): Trail.LevelFilter;
        public newSpan(span: Trail.Attributes): Trail.SpanId;
        public record(span: Trail.SpanId, values: Trail.Record): void;
        public recordFollowsFrom(span: Trail.SpanId, follows: Trail.SpanId): void;
        public event(event: Trail.Event): void;
        public enter(span: Trail.SpanId): void;
        public exit(span: Trail.SpanId): void;
        public cloneSpan(old: Trail.SpanId): Trail.SpanId;
        public dropSpan(id: Trail.SpanId): void;
        public tryClose(id: Trail.SpanId): boolean;
        public currentSpan(): Trail.SpanId | undefined;
    }
}

// Layers
declare namespace TrailSubscriber {
    abstract class Layer<S extends Trail.Subscriber> {
        public static is(obj: unknown): obj is Layer<Trail.Subscriber>;

        // TypeScript won't let us use the same method name that implements
        // both Subscriber and Layer unfortunately.
        public enabledAsLayer(metadata: Trail.Metadata, ctx: LayerContext<S>): void;
        public eventEnabledAsLayer(event: Trail.Event, ctx: LayerContext<S>): void;

        public maxLevelHint(): Trail.LevelFilter | undefined;

        public onRegisterDispatch(subscriber: Trail.Dispatch): void;
        public onLayer(subscriber: Trail.Subscriber): void;
        public onNewSpan(attrs: Trail.Attributes, id: Trail.SpanId, ctx: LayerContext<S>): void;
        public onRecord(span: Trail.SpanId, values: Trail.Record, ctx: LayerContext<S>): void;
        public onFollowsFrom(span: Trail.SpanId, follows: Trail.SpanId, ctx: LayerContext<S>): void;

        public onEvent(event: Trail.Event, ctx: LayerContext<S>): void;
        public onEnter(id: Trail.SpanId, ctx: LayerContext<S>): void;
        public onExit(id: Trail.SpanId, ctx: LayerContext<S>): void;
        public onClose(id: Trail.SpanId, ctx: LayerContext<S>): void;
        public onIdChange(old: Trail.SpanId, newOne: Trail.SpanId, ctx: LayerContext<S>): void;
    }

    type LayerContext<S extends Trail.Subscriber = Trail.Subscriber> = {
        subscriber: S;

        currentSpan(): Trail.SpanId | undefined;
        enabled(metadata: Trail.Metadata): boolean;
        event(event: Trail.Event): void;
    } & (S extends LookupSpan<infer D> ? LookupSpan<D> : {});
}

export = TrailSubscriber;
export as namespace TrailSubscriber;
