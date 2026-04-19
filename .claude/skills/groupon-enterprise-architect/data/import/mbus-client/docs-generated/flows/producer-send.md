---
service: "mbus-client"
title: "Producer Publish — Fire and Forget"
generated: "2026-03-03"
type: flow
flow_name: "producer-send"
flow_type: synchronous
trigger: "Application code calls Producer.send()"
participants:
  - "continuumMbusClientLibrary_producerApi"
  - "continuumMbusClientLibrary_messageSerialization"
  - "continuumMbusClientLibrary_stompTransport"
  - "messageBus"
architecture_ref: "dynamic-continuumMbusClientLibrary"
---

# Producer Publish — Fire and Forget

## Summary

The fire-and-forget publish flow enables a Groupon service to send a message to an MBus queue or topic with maximum throughput and minimum latency. The producer serializes the message payload using Thrift, encodes it into a STOMP SEND frame, and writes it to the TCP socket without waiting for any broker acknowledgment. Messages may be lost if the broker fails before persisting the frame, making this mode appropriate for high-volume, loss-tolerant use cases.

## Trigger

- **Type**: api-call
- **Source**: Application code in the embedding service calls `Producer.send(Message message)` or `Producer.send(Message message, String destinationName, Map<String,String> headers)`
- **Frequency**: On-demand; per message

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Producer API and Implementation | Receives call from application; manages STOMP connection state; delegates to transport | `continuumMbusClientLibrary_producerApi` |
| Message and Thrift Serialization | Serializes message payload into Thrift-encoded bytes | `continuumMbusClientLibrary_messageSerialization` |
| STOMP Transport | Encodes STOMP SEND frame and writes to TCP socket | `continuumMbusClientLibrary_stompTransport` |
| MBus Broker | Receives STOMP SEND frame and routes to destination queue/topic | `messageBus` |

## Steps

1. **Application creates message**: Application calls `Message.createStringMessage()`, `createJsonMessage()`, or `createBinaryMessage()` to produce a typed `Message` instance with a generated or provided message ID.
   - From: Embedding application
   - To: `continuumMbusClientLibrary_messageSerialization`
   - Protocol: In-process Java call

2. **Producer validates connection state**: `ProducerImpl` checks its `Status` enum (must be `RUNNING`). If `connectionLifetime` has elapsed since last connection, refreshes the STOMP connection before sending.
   - From: `continuumMbusClientLibrary_producerApi`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java call

3. **Serializes message payload**: The `Message`'s internal `MessageInternal` Thrift struct is serialized using the Thrift binary protocol, with `MessagePayloadType` discriminator set.
   - From: `continuumMbusClientLibrary_producerApi`
   - To: `continuumMbusClientLibrary_messageSerialization`
   - Protocol: In-process Java call

4. **Builds STOMP SEND frame**: `StompConnection` constructs a STOMP `SEND` frame with destination header set to the configured `destinationName` (e.g., `jms.topic.myTopic`), optional custom headers merged, and serialized message as frame body.
   - From: `continuumMbusClientLibrary_producerApi`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java call

5. **Writes frame to TCP socket**: `StompConnection` writes the STOMP SEND frame bytes to the TCP socket synchronously. Returns immediately without waiting for broker response.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP over TCP (port 61613)

6. **Broker routes message**: The MBus broker receives the SEND frame and routes the message to the configured topic or queue. No acknowledgment is sent back to the producer.
   - From: `messageBus`
   - To: destination consumers (external to this library)
   - Protocol: STOMP (internal broker routing)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| TCP socket write fails (`IOException`) | `StompConnection` throws `SendFailedException`; `ProducerImpl` propagates to caller | Caller receives `SendFailedException`; must retry manually |
| Connection not established | `ProducerImpl` throws `TooManyConnectionRetryAttemptsException` if unable to reconnect | Caller receives exception; message not sent |
| `Status` not `RUNNING` | `ProducerImpl` throws `InvalidStatusException` | Caller must call `start()` before publishing |

## Sequence Diagram

```
Application         -> ProducerImpl       : send(message)
ProducerImpl        -> StompConnection    : checkStatus() / refreshIfStale()
ProducerImpl        -> MessageSerializer  : serialize(message.getMessageInternal())
ProducerImpl        -> StompConnection    : send(StompFrame[SEND, dest, body])
StompConnection     -> MBus Broker        : TCP write STOMP SEND frame
MBus Broker         --> (no response)     : Routes message to destination
StompConnection     --> ProducerImpl      : returns (no receipt)
ProducerImpl        --> Application       : returns (void)
```

## Related

- Architecture dynamic view: `dynamic-continuumMbusClientLibrary`
- Related flows: [Producer Publish — Safe Send with Receipt](producer-send-safe.md)
