<p align="center">
    <img alt="trail" src="https://raw.githubusercontent.com/memothelemo/trail/refs/heads/master/assets/logo.svg" width="400">
</p>
<p align="center">
    <b>Event-based diagnostic information inspired from</b>
    <code><a href="https://github.com/tokio-rs/tracing">tokio-rs/tracing</a></code>
</a>

> [!CAUTION]
> _This project is in experimental phase. We advise you to not use this in your production projects. Bugs and unexpecteds output with these modules will occur at any time._
>
> _If you wish to do so, **PLEASE USE IT AT YOUR OWN RISK!**_

## Usage

### **[roblox-ts](https://github.com/roblox-ts/roblox-ts)**
```ts
import { Event, Level, Span, Subscriber, fields, info } from "@rbxts/trail";
import { Layer, LayerContext, Layers } from "@rbxts/trail-subscriber";
import { LookupSpan, Registry, SpanData } from "@rbxts/trail-subscriber";

type RegistrySubscriber = Subscriber & LookupSpan<SpanData>;

class FmtLayer extends Layer<RegistrySubscriber> {
    public onEvent(event: Event, ctx: LayerContext<RegistrySubscriber>): void {
        const timestamp = DateTime.now()
            .FormatLocalTime("YYYY-MM-DDTHH:MM:SSZ", "en-us");

        event.metadata.fields.push("timestamp");
        event.fields.push(timestamp);

        const levelStr = Level[event.metadata.level].lower();
        print(`[${timestamp}] [${levelStr}] ${event.fields[0]}`);
    }
}

const subscriber = new Layers(new Registry())
    .withLayer(new FmtLayer());

Subscriber.setGlobalDefault(subscriber);

const numberOfYaks = 3;
info("preparing to shave yaks", fields({ numberOfYaks: numberOfYaks }));

const numberShaved = yakShave.shaveAll(numberOfYaks);
info("yak shaving completed", fields({
    allYaksShaved: numberOfYaks === numberShaved,
}));
```

### Soon...
```ts
import { Service, OnStart } from "@flamework/core";
import { Players } from "@rbxts/services";
import { Span, info, fields } from "@rbxts/trail";
import { Instrument } from "@rbxts/trail-decorators";

@Service({})
export class TestService implements OnStart {
    @Instrument({
        name = "onPlayerAdded",
        target = "src::services::TestService"
    })
    private onPlayerAdded(player: Player) {
        const span = Span.current();
        span.record("player.DisplayName", player.DisplayName);
        span.record("player.Name", player.Name);
        span.record("player.UserId", player.UserId);

        info("{} ({}) joined the game", player.Name, player.UserId, fields({
            "player.AccountAge": player.UserId,
        }));
    }

    public onStart() {
        Players.PlayerAdded.Connect((player) => {
            task.spawn(() => this.onPlayerAdded(player));
        });
    }
}
```

### Luau
```lua
local FmtLayer = setmetatable({}, TrailSubscriber.Layer)
FmtLayer.__index = FmtLayer

function FmtLayer.new()
    return setmetatable({
        _name = "FmtLayer",
    }, FmtLayer)
end

function FmtLayer:onEvent(event, ctx)
    local timestamp = DateTime.now():FormatLocalTime("YYYY-MM-DDTHH:MM:SSZ", "en-us")
    table.insert(event.metadata.fields, "timestamp")
    table.insert(event.fields, timestamp)

    local levelStr = Trail.Level[event.metadata.level]:lower()
    print(`[{timestamp}] [{levelStr}] {event.fields[1]}`)
end

local subscriber = Layers.new(Registry.new())
    :withLayer(FmtLayer.new())

Subscriber.setGlobalDefault(subscriber)

local numberOfYaks = 3
info("preparing to shave yaks", fields { numberOfYaks = numberOfYaks })

local numberShaved = yakShave.shaveAll(numberOfYaks)
info("yak shaving completed", fields {
    allYaksShaved = numberOfYaks == numberShaved,
})

local function span(number: number)
    info("hi!")
end
span = instrument(span, {
    name = "span_test",
    target = "script",
    fields = function(span, number: number)
        span:record("number", number)
    end,
})

span(123)
```
