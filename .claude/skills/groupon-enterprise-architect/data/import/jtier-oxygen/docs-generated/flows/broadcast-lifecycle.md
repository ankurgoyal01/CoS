---
service: "jtier-oxygen"
title: "Broadcast Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "broadcast-lifecycle"
flow_type: asynchronous
trigger: "API call — POST /broadcasts then PUT /broadcasts/{name}/running"
participants:
  - "oxygenHttpApi"
  - "oxygenBroadcastCore"
  - "oxygenDataAccess"
  - "oxygenMessageClient"
  - "continuumOxygenPostgres"
  - "messageBus"
architecture_ref: "dynamic-oxygen-runtime-flow"
---

# Broadcast Lifecycle

## Summary

The broadcast lifecycle is JTier Oxygen's primary message-bus validation flow. A caller creates a named broadcast specifying the number of distinct messages and optional iteration limits. When started, each message is enqueued onto a JMS queue. Every instance of Oxygen that receives a message increments its iteration counter, persists the updated state to Postgres, and re-enqueues the message (with an optional delay). This fanout loop runs until the broadcast is stopped or `maxIterations` is reached.

## Trigger

- **Type**: API call (multi-step)
- **Source**: HTTP client (JTier team engineer or the `oxy-broadcast` CLI script)
- **Frequency**: On-demand; a broadcast may run continuously for hours or be capped by `maxIterations` or `endTime`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP Resources | Accepts create/start/stop/stats API calls | `oxygenHttpApi` |
| Broadcast Core | Orchestrates message publication and consumption logic | `oxygenBroadcastCore` |
| Persistence Adapters | Reads and writes broadcast and message state | `oxygenDataAccess` |
| MessageBus Client | Publishes and consumes queue messages | `oxygenMessageClient` |
| Oxygen Postgres | Persists broadcast records and message iteration state | `continuumOxygenPostgres` |
| MessageBus | Queues and delivers broadcast messages between Oxygen instances | `messageBus` |

## Steps

1. **Create broadcast**: Caller sends `POST /broadcasts` with `name`, `numMessages`, `maxIterations`, `processingTime`, and optional `destination`.
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

2. **Persist broadcast record**: HTTP Resources delegates to Broadcast Core, which calls Persistence Adapters to insert the broadcast and its `numMessages` message records into Postgres.
   - From: `oxygenHttpApi` → `oxygenBroadcastCore`
   - To: `oxygenDataAccess` → `continuumOxygenPostgres`
   - Protocol: Direct (in-process) / JDBC

3. **Start broadcast**: Caller sends `PUT /broadcasts/{name}/running` with body `true`.
   - From: `HTTP client`
   - To: `oxygenHttpApi`
   - Protocol: REST (HTTP)

4. **Enqueue initial messages**: Broadcast Core publishes each of the `numMessages` messages to `jms.queue.JtierOxygen` via the MessageBus Client.
   - From: `oxygenBroadcastCore` → `oxygenMessageClient`
   - To: `messageBus` (`jms.queue.JtierOxygen`)
   - Protocol: STOMP

5. **Receive and process message**: An Oxygen instance (any running instance, including the publisher) dequeues a message from the queue.
   - From: `messageBus`
   - To: `oxygenMessageClient` → `oxygenBroadcastCore`
   - Protocol: STOMP

6. **Persist iteration update**: Broadcast Core increments the message's `maxIteration` counter and updates `updatedAt` in Postgres.
   - From: `oxygenBroadcastCore`
   - To: `oxygenDataAccess` → `continuumOxygenPostgres`
   - Protocol: Direct (in-process) / JDBC

7. **Re-enqueue message**: After optional `processingTimeMillis` wait, Broadcast Core re-publishes the message to the queue (if `maxIterations` not reached and broadcast is still running).
   - From: `oxygenBroadcastCore` → `oxygenMessageClient`
   - To: `messageBus`
   - Protocol: STOMP

8. **Steps 5–7 repeat** for each message until the broadcast is stopped or iteration limits are reached.

9. **Stop broadcast**: Caller sends `DELETE /broadcasts/{name}/running` or `PUT /broadcasts/{name}/running` with body `false`. Broadcast Core sets `running = false` in Postgres; no further re-enqueuing occurs.
   - From: `HTTP client`
   - To: `oxygenHttpApi` → `oxygenBroadcastCore` → `oxygenDataAccess`
   - Protocol: REST → Direct → JDBC

10. **Query stats**: Caller sends `GET /broadcasts/{name}/stats` to retrieve `numSends`, `overallMPS`, `avgPerMessageMPS`, and `totalElapsedSeconds`.
    - From: `HTTP client`
    - To: `oxygenHttpApi` → `oxygenDataAccess` → `continuumOxygenPostgres`
    - Protocol: REST → Direct → JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Broadcast name already exists | `409 Conflict` returned | Caller must delete existing broadcast or use a different name |
| Broadcast not found | `404 Not Found` returned | Caller must create the broadcast first |
| MessageBus broker unavailable | Messages stop circulating; no re-enqueue | Broadcast stalls; `numSends` stops increasing; must be manually restarted after broker recovery |
| Postgres unavailable | Create/start/stop/stats endpoints return `500` | Broadcast cannot be persisted or read |
| `maxIterations` reached | Broadcast Core stops re-enqueuing | Broadcast terminates naturally; `isRunning` becomes `false` |

## Sequence Diagram

```
Client -> oxygenHttpApi: POST /broadcasts {name, numMessages, maxIterations}
oxygenHttpApi -> oxygenBroadcastCore: create(params)
oxygenBroadcastCore -> oxygenDataAccess: insert broadcast + messages
oxygenDataAccess -> continuumOxygenPostgres: SQL INSERT
continuumOxygenPostgres --> oxygenDataAccess: OK
oxygenDataAccess --> oxygenBroadcastCore: broadcast record
oxygenBroadcastCore --> oxygenHttpApi: BroadcastResponse
oxygenHttpApi --> Client: 201 Created

Client -> oxygenHttpApi: PUT /broadcasts/{name}/running (true)
oxygenHttpApi -> oxygenBroadcastCore: start(name)
oxygenBroadcastCore -> oxygenMessageClient: publish(message) x numMessages
oxygenMessageClient -> messageBus: STOMP SEND jms.queue.JtierOxygen

loop until stop or maxIterations
  messageBus -> oxygenMessageClient: STOMP MESSAGE
  oxygenMessageClient -> oxygenBroadcastCore: onMessage(msg)
  oxygenBroadcastCore -> oxygenDataAccess: updateIteration(messageId)
  oxygenDataAccess -> continuumOxygenPostgres: SQL UPDATE
  oxygenBroadcastCore -> oxygenMessageClient: publish(msg, sequence+1)
  oxygenMessageClient -> messageBus: STOMP SEND
end

Client -> oxygenHttpApi: DELETE /broadcasts/{name}/running
oxygenHttpApi -> oxygenBroadcastCore: stop(name)
oxygenBroadcastCore -> oxygenDataAccess: setRunning(false)
oxygenDataAccess -> continuumOxygenPostgres: SQL UPDATE
```

## Related

- Architecture dynamic view: `dynamic-oxygen-runtime-flow`
- Related flows: [MessageBus Roundtrip](messagebus-roundtrip.md)
- API surface: [Broadcasts endpoints](../api-surface.md)
