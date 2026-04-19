---
service: "mbus-client"
title: "Consumer Receive and Acknowledge"
generated: "2026-03-03"
type: flow
flow_name: "consumer-receive-ack"
flow_type: synchronous
trigger: "Application code calls Consumer.receive() then Consumer.ack() or nack()"
participants:
  - "continuumMbusClientLibrary_consumerApi"
  - "continuumMbusClientLibrary_stompTransport"
  - "continuumMbusClientLibrary_messageSerialization"
  - "messageBus"
architecture_ref: "dynamic-continuumMbusClientLibrary"
---

# Consumer Receive and Acknowledge

## Summary

This flow describes how an embedding service receives messages from MBus and signals processing completion back to the broker. Background `StompServerFetcher` threads continuously prefetch STOMP MESSAGE frames from each connected broker into per-broker in-memory caches. When the application calls `receive()`, the `ConsumerImpl` round-robins across all broker fetchers to pop the next available message, deserializes it, and returns a `Message` to the caller. The application then processes the message and calls `ack()` (to dequeue) or `nack()` (to return for redelivery). This is the core steady-state operation of the consumer.

## Trigger

- **Type**: api-call
- **Source**: Embedding application calls `Consumer.receive()`, `Consumer.receive(long timeout)`, or `Consumer.receiveImmediate()`
- **Frequency**: Per-message; typically in a continuous while-loop for the lifetime of the consumer

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer API and Implementation | Round-robin dispatch across broker fetchers; deserialization; `ack`/`nack` routing | `continuumMbusClientLibrary_consumerApi` |
| STOMP Transport (`StompServerFetcher`) | Prefetches STOMP MESSAGE frames into per-broker cache; sends ACK/NACK STOMP frames to broker | `continuumMbusClientLibrary_stompTransport` |
| Message and Thrift Serialization | Deserializes Thrift-encoded `MessageInternal` from STOMP frame body | `continuumMbusClientLibrary_messageSerialization` |
| MBus Broker | Pushes STOMP MESSAGE frames to consumer; dequeues on ACK; redelivers on NACK or disconnect | `messageBus` |

## Steps

### Prefetch (background, continuous)

1. **Broker pushes STOMP MESSAGE frame**: After subscription, the MBus broker continuously pushes available STOMP `MESSAGE` frames over the TCP connection to each `StompServerFetcher`.
   - From: `messageBus`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: STOMP over TCP (port 61613)

2. **StompServerFetcher reads frame from socket**: The fetcher thread's `preFetchMessage()` calls `StompConnection.receive(0)` (non-blocking) to read the next available frame from the socket.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: Internal `preFetchedCache`
   - Protocol: In-process Java

3. **Frame placed in prefetch cache**: The MESSAGE frame is enqueued into the `LinkedBlockingQueue<StompFrame> preFetchedCache` for this broker connection.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: Internal per-broker cache
   - Protocol: In-process Java (`LinkedBlockingQueue.put()`)

### Receive (application-driven)

4. **Application calls receive()**: `ConsumerImpl.receive()` (blocking) or `receive(long timeout)` loops across all `StompServerFetcher` instances in round-robin order, calling `fetcher.receiveLast()` on each.
   - From: Embedding application
   - To: `continuumMbusClientLibrary_consumerApi`
   - Protocol: In-process Java call

5. **Poll prefetch cache**: `StompServerFetcher.receiveLast()` calls `preFetchedCache.poll()` (non-blocking). Returns the next `StompFrame` from the cache, or `null` if empty.
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java

6. **Auto-ack (if AUTO_CLIENT_ACK)**: If `ConsumerConfig.ackType` is `AUTO_CLIENT_ACK`, `receiveLast()` immediately sends an ACK STOMP frame to the broker before returning the frame to the application.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP ACK over TCP

7. **Deserializes STOMP frame body**: `ConsumerImpl` extracts the frame body bytes, deserializes the Thrift `MessageInternal` struct, and constructs a `Message` object with `messageId`, typed payload (`STRING`/`JSON`/`BINARY`), properties, and STOMP headers.
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: `continuumMbusClientLibrary_messageSerialization`
   - Protocol: In-process Java

8. **Message delivered to application**: `receive()` returns the `Message` to the calling application code. The `ackId` field is set to enable subsequent acknowledgment.
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: Embedding application
   - Protocol: In-process Java return value

### Acknowledgment

9. **Application processes message**: Application inspects `message.getMessagePayloadType()` and reads the appropriate payload (`getStringPayload()`, `getJSONStringPayload()`, or `getBinaryPayload()`). Performs its business logic.

10. **Application calls ack() or nack()**: Based on processing outcome, calls `Consumer.ackSafe(message.getAckId())` (confirmed) or `Consumer.ack(message.getAckId())` (fire-and-forget), or `Consumer.nack(message.getAckId())` on failure.
    - From: Embedding application
    - To: `continuumMbusClientLibrary_consumerApi`
    - Protocol: In-process Java call

11. **StompServerFetcher sends ACK or NACK frame**: The fetcher for the broker that delivered the message sends a STOMP `ACK` (with `message-id` and optional `receipt-id` for `ackSafe`) or `NACK` frame to the broker.
    - From: `continuumMbusClientLibrary_stompTransport`
    - To: `messageBus`
    - Protocol: STOMP ACK/NACK over TCP

12. **Broker dequeues or redelivers**: On ACK, the broker marks the message as consumed and removes it from the queue. On NACK, the broker returns the message for redelivery to any available consumer.
    - From: `messageBus`
    - To: (internal broker state)
    - Protocol: Broker-internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| All prefetch caches empty at receive() call | `ConsumerImpl` sleeps `receiveSleepInterval` (default: 1 ms) and retries; continues until message available or timeout expires | `ReceiveTimeoutException` thrown if `timeout` version used and deadline exceeded |
| `AckFailedException` during AUTO_CLIENT_ACK | Error logged; `lastSentMessage` cleared; `receiveLast()` returns `null` | Message will be redelivered by broker; application receives next message in loop |
| TCP connection broken during ACK | `AckFailedException` thrown; connection reset triggered | Message redelivered by broker to same or different consumer instance |
| NACK over broken connection | `NackFailedException` thrown | Connection reset; broker redelivers message automatically on connection close |
| `receive(long timeout)` expires | `ReceiveTimeoutException` thrown | Application must handle timeout; consumer remains running |

## Sequence Diagram

```
MBus Broker         -> StompServerFetcher  : STOMP MESSAGE frame (pushed)
StompServerFetcher  -> preFetchedCache     : enqueue(frame)
Application         -> ConsumerImpl        : receive() [or receive(timeout)]
ConsumerImpl        -> StompServerFetcher  : receiveLast() [round-robin]
StompServerFetcher  -> preFetchedCache     : poll()
preFetchedCache     --> StompServerFetcher : StompFrame (or null)
StompServerFetcher  --> ConsumerImpl       : StompFrame
ConsumerImpl        -> MessageSerializer   : deserialize(frame.body)
MessageSerializer   --> ConsumerImpl       : Message
ConsumerImpl        --> Application        : Message
Application         -> Application         : processMessage()
Application         -> ConsumerImpl        : ackSafe(message.getAckId())
ConsumerImpl        -> StompServerFetcher  : ackSafe(messageId, connectionId, timeout)
StompServerFetcher  -> MBus Broker         : STOMP ACK (message-id, receipt-id)
MBus Broker         --> StompServerFetcher : STOMP RECEIPT
StompServerFetcher  --> ConsumerImpl       : ack confirmed
ConsumerImpl        --> Application        : true
```

## Related

- Architecture dynamic view: `dynamic-continuumMbusClientLibrary`
- Related flows: [Consumer Startup and Broker Discovery](consumer-startup.md), [Connection Lifecycle and Keepalive](connection-lifecycle.md)
