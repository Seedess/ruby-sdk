# seedess-sdk

Official Seedess SDK for Ruby.

**Server-side only.** The SDK uses a secret API key (`key_…`) to create and control streams.
Never ship it in a browser or a mobile app. Playback uses the separate `@seedess/*-p2p`
packages and a per-stream public token (`pk_…`).

## Install

```bash
gem install seedess-sdk
```

Ruby 2.6+.

## Use

```ruby
require 'seedess'

seedess = Seedess::Client.new(ENV.fetch('SEEDESS_API_KEY'))

stream = seedess.create_stream(
  url: 'https://origin.example/master.m3u8',
  id: 'demo',
  live: true
)

puts stream['publicToken']
puts stream['playback']['master']
```

Pass only the public token and stream id to the page.

## Full working example

See [`examples/`](./examples) for a server that creates a stream and a browser page
that plays it with hls.js + the Seedess P2P adapter.

## Methods

| Method | HTTP | Purpose |
| --- | --- | --- |
| `create_stream(url:, id:, title:, live:)` | `POST /api/v1/streams` | Ingest a manifest, mint the public token. |
| `get_stream(id)` | `GET /api/v1/streams/:id` | Status, variants, segment count. |
| `list_streams` | `GET /api/v1/streams` | All streams in the tenant. |
| `refresh_stream(id)` | `POST /api/v1/streams/:id/refresh` | Pull new live segments. |
| `disable_peers(id)` | `POST /api/v1/streams/:id/kill` | CDN only; playback continues. |
| `enable_peers(id)` | `POST /api/v1/streams/:id/revive` | Re-enable peer delivery. |
| `get_metrics(id)` | `GET /api/v1/streams/:id/metrics` | Offload and delivery counters. |
| `send_telemetry(session_id:, stream_id:, ...)` | `POST /api/v1/telemetry` | One session batch (public, rate limited). |

`request(method, path, body = nil, auth: true)` is available for routes without a helper.

## Errors

```ruby
begin
  seedess.create_stream(url: url)
rescue Seedess::Error => error
  puts error.status, error.code, error.message
end
```

## Links

- Docs: https://seedess.com/docs/
- API: https://seedess.com/docs/api/
- Libraries: https://seedess.com/docs/libraries/

## License

MIT.
