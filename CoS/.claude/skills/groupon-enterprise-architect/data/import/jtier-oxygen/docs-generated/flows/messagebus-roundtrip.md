---
service: "jtier-oxygen"
title: "MessageBus Roundtrip"
generated: "2026-03-03"
type: flow
flow_name: "messagebus-roundtrip"
flow_type: synchronous
trigger: "API call — POST /messagebus/mass-roundtrip/{count}/{size}"
participants:
  - "oxygenHttpApi"
  - "oxygenBroadcastCore"
  - "oxygenMessageClient"
  - "messageBus"
architecture_ref: "dynamic-oxygen-runtime-flow"
---

# MessageBus Roundtrip

## Summary

The MessageBus roundtrip flow is a synchronous performance measurement tool that publishes a batch of messages to a JMS queue and then consumes them back within the same request, measuring end-to-end throughput. It is used to validate JTier MessageBus integration quality and measure broker performance — particularly useful after broker upgrades or configuration changes.

## Trigger

- **Type**: API call
- **Source**: HTTP client (JTier engineer or performance test harness)
- **Frequency**: On-demand; typically used during performance testing sessions (see `#perf-runs` Slack channel)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP Resources | Accepts roundtrip request; returns stats | `oxygenHttpApi` |
| Broadcast Core | Coordinates the publish-then-consume sequence | `oxygenBroadcastCore` |
| MessageBus Client | Publishes and consumes messages on the queue | `oxygenMessageClient` |
| MessageBus | Queues and delivers messages | `messageBus` |

## Steps

1. **Receive roundtrip request**: Caller sends `POST /messagebus/mass-roundtrip/{count}/{size}` with optional body specifying a `Destination` override (host, port, queue name, type).
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

2. **Delegate to Broadcast Core**: HTTP Resources passes the `count` and `size` parameters (and optional destination) to Broadcast Core for orchestration.
   - From: `oxygenHttpApi`
   - To: `oxygenBroadcastCore`
   - Protocol: Direct (in-process)

3. **Publish `count` messages**: Broadcast Core instructs the MessageBus Client to publish `count` messages, each `size` bytes, to the configured JMS queue destination.
   - From: `oxygenBroadcastCore` → `oxygenMessageClient`
   - To: `messageBus` (`jms.queue.JtierOxygen`)
   - Protocol: STOMP

4. **Consume `count` messages**: Immediately after publishing, Broadcast Core instructs the MessageBus Client to consume the same number of messages from the queue.
   - From: `messageBus`
   - To: `oxygenMessageClient` → `oxygenBroadcastCore`
   - Protocol: STOMP

5. **Collect timing statistics**: Broadcast Core records timestamps for each publish and consume operation; computes throughput statistics (messages per second, average execution time).

6. **Return stats**: HTTP Resources serializes and returns the timing statistics to the caller.
   - From: `oxygenHttpApi`
   - To: `HTTP client`
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MessageBus broker unavailable | Publish or consume throws exception | `500 Internal Server Error` returned; no partial stats returned |
| Count/size parameters invalid | Not explicitly validated in API spec | May result in broker errors or empty responses |
| Consume timeout | If fewer messages than expected arrive | Request may block or return partial stats |

## Sequence Diagram

```
Client -> oxygenHttpApi: POST /messagebus/mass-roundtrip/{count}/{size}
oxygenHttpApi -> oxygenBroadcastCore: roundtrip(count, size, destination?)
loop count times
  oxygenBroadcastCore -> oxygenMessageClient: publish(message, size bytes)
  oxygenMessageClient -> messageBus: STOMP SEND jms.queue.JtierOxygen
  messageBus --> oxygenMessageClient: STOMP ACK
end
loop count times
  oxygenBroadcastCore -> oxygenMessageClient: consume()
  messageBus -> oxygenMessageClient: STOMP MESSAGE
  oxygenMessageClient --> oxygenBroadcastCore: message
end
oxygenBroadcastCore --> oxygenHttpApi: timing stats
oxygenHttpApi --> Client: 200 OK {timing statistics}
```

## Related

- Architecture dynamic view: `dynamic-oxygen-runtime-flow`
- Related flows: [Broadcast Lifecycle](broadcast-lifecycle.md)
- API surface: [MessageBus endpoints](../api-surface.md)
- Events: [Events](../events.md)
