import { Subscriber } from "@rbxts/trail";
import { Layer, LayerContext, Layered, LookupSpan, Registry } from ".";

class MyLayer<S extends LookupSpan<defined> & Subscriber> extends Layer<S> {
    public onEvent(event: Trail.Event, ctx: LayerContext<Registry>): void {}

    public onExit(id: Trail.SpanId, ctx: LayerContext<Registry>): void {}
}
