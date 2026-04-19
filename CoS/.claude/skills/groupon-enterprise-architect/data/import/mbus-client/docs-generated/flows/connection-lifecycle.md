---
service: "mbus-client"
title: "Connection Lifecycle and Keepalive"
generated: "2026-03-03"
type: flow
flow_name: "connection-lifecycle"
flow_type: asynchronous
trigger: "Periodic timer or connection failure detected by StompServerFetcher or ProducerImpl"
participants:
  - "continuumMbusClientLibrary_consumerApi"
  - "continuumMbusClientLibrary_producerApi"
  - "continuumMbusClientLibrary_stompTransport"
  - "continuumMbusClientLibrary_serverDiscovery"
  - "messageBus"
architecture_ref: "dynamic-continuumMbusClientLibrary"
---

# Connection Lifecycle and Keepalive

## Summary

The MBus client library actively manages the health of its STOMP TCP connections in the background. Both the producer and consumer send periodic keepalive frames to prevent broker-side idle-connection timeouts. On connection failure (TCP IO error, ERROR frame, or disconnection), the library automatically resets and re-establishes the connection without requiring intervention from the embedding application. Producers additionally reconnect on a periodic `connectionLifetime` schedule to rebalance load across the broker cluster. Consumers periodically refresh the active broker host list to adapt to broker cluster topology changes.

## Trigger

- **Type**: schedule and event-driven
- **Source**:
  - **Keepalive**: Internal keepalive thread fires every `keepAlivePeriodSeconds` (default: 60 s) in both producer and consumer
  - **Connection reset**: Detected immediately on `IOException` during send/receive operations or on ERROR frame from broker
  - **Periodic reconnect (producer)**: `connectionLifetime` timer (default: 300000 ms / 5 min) in `ProducerImpl`
  - **Broker host refresh (consumer)**: `connectionLifetime` timer triggers `DynamicServerListGetter` refresh to pick up topology changes
- **Frequency**: Continuous background; escalating on failure

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer API and Implementation | Manages keepalive thread scheduling and consumer-side connection refresh; coordinates `StompServerFetcher` lifecycle | `continuumMbusClientLibrary_consumerApi` |
| Producer API and Implementation | Manages producer-side keepalive and periodic reconnect | `continuumMbusClientLibrary_producerApi` |
| STOMP Transport | Detects IO failures; sends keepalive frames; executes reconnect and re-subscribe | `continuumMbusClientLibrary_stompTransport` |
| Dynamic Server Discovery | Provides updated broker host list on consumer refresh | `continuumMbusClientLibrary_serverDiscovery` |
| MBus Broker | Receives keepalive frames; closes idle connections; accepts reconnects | `messageBus` |

## Steps

### Keepalive (periodic)

1. **Keepalive timer fires**: A scheduled background thread (configured at `keepAlivePeriodSeconds` interval, default 60 s) triggers `ConsumerImpl.keepAlive()` or `ProducerImpl.keepAlive()`.
   - From: Internal keepalive scheduler
   - To: `continuumMbusClientLibrary_consumerApi` or `continuumMbusClientLibrary_producerApi`
   - Protocol: In-process Java timer

2. **Sends STOMP keepalive frame to each broker**: `StompConnection.keepAlive()` writes a keepalive (heartbeat) frame to the TCP socket for each active connection.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP over TCP

3. **On keepalive IO failure, resets connection**: If `keepAlive()` throws `IOException`, `StompServerFetcher` logs an info message, calls `resetConnection()`, and retries the keepalive on the new connection.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP CONNECT + SUBSCRIBE over TCP (reconnect)

### Connection Reset (failure-driven)

4. **IO error detected during prefetch or send**: `StompServerFetcher.receiveOrReconnectIfFailed()` catches `IOException` from `StompConnection.receive()`. `ProducerImpl` catches `IOException` from `StompConnection.send()`.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: Internal error handling

5. **Clears in-flight state**: `resetConnection()` acquires the `connectionAccessLock`, calls `disconnect()`, which: clears `preFetchedCache`, clears `awaitingReceipts` (in-flight receipt futures are abandoned), and closes the TCP socket.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: Internal cache and socket cleanup

6. **Reconnects to broker with retry**: `connect(MAX_RETRY_COUNT=3)` attempts to reopen the TCP socket, send STOMP CONNECT, and re-issue STOMP SUBSCRIBE with the original subscription parameters. Retries up to 3 times with 1-second sleep between attempts.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP CONNECT + SUBSCRIBE over TCP

7. **On retry exhaustion, sleeps and continues**: If all 3 retries fail, `StompServerFetcher.run()` catches `TooManyConnectionRetryAttemptsException`, logs a warning, and sleeps `FAILURE_RETRY_INTERVAL` (60000 ms) before the outer loop retries the full connection sequence.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process sleep

### ERROR Frame Handling (broker-driven disconnect)

8. **Broker sends STOMP ERROR frame**: Broker may send an ERROR frame with body "disconnected by server" when it removes the consumer from the queue (e.g., Artemis idle-consumer timeout).
   - From: `messageBus`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: STOMP over TCP

9. **Library detects ERROR and disconnects**: `StompServerFetcher.handleError()` checks if frame body contains "disconnected by server". If so, calls `disconnect()` to close the socket. On the next `preFetchMessage()` iteration, `refreshConnection()` detects the stale connection and triggers reconnect.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java

### Producer Periodic Reconnect

10. **connectionLifetime timer fires in ProducerImpl**: After `connectionLifetime` ms (default: 5 min), `ProducerImpl` proactively reconnects to the broker. In a clustered environment, this causes the load balancer to assign a potentially different broker, distributing producer load.
    - From: `continuumMbusClientLibrary_producerApi`
    - To: `continuumMbusClientLibrary_stompTransport`
    - Protocol: In-process Java

### Consumer Broker List Refresh

11. **connectionLifetime timer fires in ConsumerImpl**: After `connectionLifetime` ms, `ConsumerImpl` re-fetches the active broker list from the MBus VIP HTTP endpoint via `DynamicServerListGetter`. New brokers are added (new `StompServerFetcher` started); removed brokers have their fetchers stopped.
    - From: `continuumMbusClientLibrary_consumerApi`
    - To: `continuumMbusClientLibrary_serverDiscovery`
    - Protocol: HTTP GET to MBus VIP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Keepalive IO failure | Connection reset; keepalive retried on new connection | Application unaware; message flow briefly interrupted then resumes |
| Connection reset during reconnect (3 retries exhausted) | `TooManyConnectionRetryAttemptsException` logged; `StompServerFetcher` sleeps 60 s then retries outer loop | Messages buffered broker-side; consumer not receiving during outage |
| Broker topology change (new brokers added) | Consumer refresh adds new `StompServerFetcher` threads | Higher throughput from additional parallel connections |
| Broker topology change (broker removed) | Consumer refresh stops the corresponding `StompServerFetcher` | Messages on removed broker rebalanced by MBus cluster |

## Sequence Diagram

```
KeepAliveThread     -> StompConnection     : keepAlive() [every 60s]
StompConnection     -> MBus Broker         : STOMP keepalive frame
MBus Broker         --> StompConnection    : (connection maintained)

-- On IO failure during prefetch --
StompServerFetcher  -> StompServerFetcher  : catch IOException from receive()
StompServerFetcher  -> StompConnection     : disconnect() + close()
StompServerFetcher  -> preFetchedCache     : clear()
StompServerFetcher  -> StompConnection     : open(host, port) [retry x3]
StompConnection     -> MBus Broker         : STOMP CONNECT
MBus Broker         --> StompConnection    : STOMP CONNECTED
StompConnection     -> MBus Broker         : STOMP SUBSCRIBE (destination, subscription params)
MBus Broker         --> StompConnection    : (subscription re-established)
StompServerFetcher  -> StompServerFetcher  : resume preFetchMessage() loop
```

## Related

- Architecture dynamic view: `dynamic-continuumMbusClientLibrary`
- Related flows: [Consumer Startup and Broker Discovery](consumer-startup.md), [Consumer Receive and Acknowledge](consumer-receive-ack.md), [Producer Publish — Safe Send with Receipt](producer-send-safe.md)
