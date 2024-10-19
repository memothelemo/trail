/* eslint-disable roblox-ts/no-namespace-merging */

import Trail from "@rbxts/trail";

// LookupSpan
declare namespace TrailSubscriber {
    export interface SpanData {
        id(): Trail.SpanId;
        metadata(): Trail.Metadata;
        parent(): Trail.SpanId | undefined;
    }

    export interface SpanRef<Registry extends LookupSpan<SpanData>> {
        id(): Trail.SpanId;
        metadata(): Trail.Metadata;
        name(): string;
        fields(): Trail.FieldSet;
        parent(): SpanRef<Registry> | undefined;
    }

    export interface LookupSpan<Data extends SpanData> {
        /** @hidden */
        spanData(id: Trail.SpanId): Data | undefined;
        span(id: Trail.SpanId): SpanRef<this>;
    }
}

// Registry
declare namespace TrailSubscriber {
    interface RegistrySpanData extends SpanData {
        /**
         * @hidden
         * @deprecated
         */
        readonly __nominal_RegistrySpanData: unique symbol;
    }

    class Registry extends Trail.Subscriber implements LookupSpan<RegistrySpanData> {
        public enabled(metadata: Trail.Metadata): boolean;
        public newSpan(span: Trail.Attributes): Trail.SpanId;
        public record(span: Trail.SpanId, values: Trail.Record): void;
        public recordFollowsFrom(span: Trail.SpanId, follows: Trail.SpanId): void;
        public event(event: Trail.Event): void;
        public enter(span: Trail.SpanId): void;
        public exit(span: Trail.SpanId): void;
        public getSpan(id: Trail.SpanId): RegistrySpanData | undefined;

        public spanData(id: Trail.SpanId): RegistrySpanData | undefined;
        public span(id: Trail.SpanId): SpanRef<this>;
    }

    interface RegistrySpanStack {
        current(): Trail.SpanId | undefined;
        push(id: Trail.SpanId): boolean;
        pop(id: Trail.SpanId): boolean;
    }
}

// Layered
declare namespace TrailSubscriber {
    class Layers<Root extends Trail.Subscriber> extends Trail.Subscriber implements Layer<Root> {
        public constructor(root: Root);

        public withLayer<S extends Root>(layer: Layer<S>): this;

        public enabledAsLayer(metadata: Trail.Metadata, ctx: LayerContext<Root>): void;
        public eventEnabledAsLayer(event: Trail.Event, ctx: LayerContext<Root>): void;
        public onRegisterDispatch(subscriber: Trail.Dispatch): void;
        public onLayer(subscriber: Trail.Subscriber): void;
        public onNewSpan(attrs: Trail.Attributes, id: Trail.SpanId, ctx: LayerContext<Root>): void;
        public onRecord(span: Trail.SpanId, values: Trail.Record, ctx: LayerContext<Root>): void;
        public onFollowsFrom(
            span: Trail.SpanId,
            follows: Trail.SpanId,
            ctx: LayerContext<Root>,
        ): void;
        public onEvent(event: Trail.Event, ctx: LayerContext<Root>): void;
        public onEnter(id: Trail.SpanId, ctx: LayerContext<Root>): void;
        public onExit(id: Trail.SpanId, ctx: LayerContext<Root>): void;
        public onClose(id: Trail.SpanId, ctx: LayerContext<Root>): void;
        public onIdChange(old: Trail.SpanId, newOne: Trail.SpanId, ctx: LayerContext<Root>): void;

        public newSpan(span: Trail.Attributes): Trail.SpanId;
        public record(span: Trail.SpanId, values: Trail.Record): void;
        public recordFollowsFrom(span: Trail.SpanId, follows: Trail.SpanId): void;
        public event(event: Trail.Event): void;
        public enter(span: Trail.SpanId): void;
        public exit(span: Trail.SpanId): void;
        public cloneSpan(span: Trail.SpanId): Trail.SpanId;
        public currentSpan(): Trail.SpanId | undefined;
        public tryClose(id: Trail.SpanId): boolean;

        /** @hidden @deprecated */
        public enabled(metadata: Trail.Metadata): boolean;
        /** @hidden @deprecated */
        public eventEnabled(event: Trail.Event): boolean;
    }
}

// Layers
declare namespace TrailSubscriber {
    abstract class Layer<S extends Trail.Subscriber> {
        public static is: (obj: unknown) => obj is Layer<Trail.Subscriber>;

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
    } & (S extends LookupSpan<infer D>
        ? LookupSpan<D> & {
              eventSpan(event: Trail.Event): SpanRef<S> | undefined;
              metadata(id: Trail.SpanId): Trail.Metadata | undefined;
              exists(id: Trail.SpanId): boolean;
              lookupCurrent(): SpanRef<S> | undefined;
              lookupCurrentFiltered(
                  subscriber: LookupSpan<SpanData> & Trail.Subscriber,
              ): SpanRef<S> | undefined;
          }
        : {});
}

export = TrailSubscriber;
export as namespace TrailSubscriber;
