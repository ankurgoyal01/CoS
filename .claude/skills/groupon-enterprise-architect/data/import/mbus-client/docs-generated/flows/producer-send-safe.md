---
service: "mbus-client"
title: "Producer Publish — Safe Send with Receipt"
generated: "2026-03-03"
type: flow
flow_name: "producer-send-safe"
flow_type: synchronous
trigger: "Application code calls Producer.sendSafe()"
participants:
  - "continuumMbusClientLibrary_producerApi"
  - "continuumMbusClientLibrary_messageSerialization"
  - "continuumMbusClientLibrary_stompTransport"
  - "messageBus"
architecture_ref: "dynamic-continuumMbusClientLibrary"
---

# Producer Publish — Safe Send with Receipt

## Summary

The safe-send flow provides at-least-once delivery guarantees for durable and persistent MBus destinations. The producer sends a STOMP SEND frame with a unique `receipt-id` header, then blocks waiting for the broker to return a STOMP RECEIPT frame confirming persistence. If the receipt is not received within `receiptTimeoutMillis` (default: 5 seconds), the producer retries the send up to `publishMaxRetryAttempts` times (default: 3). This flow trades throughput (150+ QPS vs 1500+ QPS) for delivery reliability.

## Trigger

- **Type**: api-call
- **Source**: Application code calls `Producer.sendSafe(Message message)` or `Producer.sendSafe(Message message, String destinationName, Map<String,String> headers)`
- **Frequency**: On-demand; per message

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Producer API and Implementation | Orchestrates send loop with retry; manages receipt-id generation and timeout handling | `continuumMbusClientLibrary_producerApi` |
| Message and Thrift Serialization | Serializes message payload into Thrift-encoded bytes | `continuumMbusClientLibrary_messageSerialization` |
| STOMP Transport | Builds STOMP SEND frame with `receipt` header; registers `SettableFuture` for receipt; writes frame to socket; matches incoming RECEIPT frame to pending future | `continuumMbusClientLibrary_stompTransport` |
| MBus Broker | Persists message to destination; sends STOMP RECEIPT frame back to producer with matching `receipt-id` | `messageBus` |

## Steps

1. **Application creates message**: Application calls `Message.createJsonMessage()`, `createStringMessage()`, or `createBinaryMessage()` to produce a typed `Message` instance.
   - From: Embedding application
   - To: `continuumMbusClientLibrary_messageSerialization`
   - Protocol: In-process Java call

2. **Producer validates connection and checks retry budget**: `ProducerImpl` confirms `Status` is `RUNNING`. Sets attempt counter to `publishMaxRetryAttempts` (default: 3). Refreshes connection if `connectionLifetime` has elapsed.
   - From: `continuumMbusClientLibrary_producerApi`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java call

3. **Generates unique receipt-id**: For each send attempt, a UUID-based `receipt-id` is generated (using UUID from message ID bytes). A `SettableFuture<StompFrame>` is registered in the `awaitingReceipts` map keyed by this `receipt-id`.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: Internal receipt registry (`awaitingReceipts`)
   - Protocol: In-process Java call

4. **Builds and sends STOMP SEND frame**: `StompConnection` constructs the STOMP SEND frame with `receipt:{receipt-id}` header, destination, and Thrift-serialized body. Writes to TCP socket.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP over TCP (port 61613)

5. **Broker persists message and sends RECEIPT**: MBus broker receives the SEND frame, persists the message to the durable queue or topic, and writes a STOMP RECEIPT frame back with `receipt-id` header matching the request.
   - From: `messageBus`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: STOMP over TCP (port 61613)

6. **Transport resolves future**: `StompServerFetcher` or `ProducerImpl`'s receive loop reads the incoming RECEIPT frame, looks up the matching `SettableFuture` in `awaitingReceipts`, and calls `futureAckReceipt.set(frame)`.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `continuumMbusClientLibrary_producerApi`
   - Protocol: In-process Java (`SettableFuture`)

7. **Producer confirms delivery**: `sendSafe` unblocks, removes the receipt from `awaitingReceipts`, and returns to the caller. Message is confirmed delivered to the broker.
   - From: `continuumMbusClientLibrary_producerApi`
   - To: Embedding application
   - Protocol: In-process Java call

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| RECEIPT not received within `receiptTimeoutMillis` | `SettableFuture.get()` throws `TimeoutException`; `receipt-id` removed from registry; retry attempt decremented | If retries remain, repeat from Step 3; if exhausted, throw `SendFailedException` |
| Broker returns STOMP ERROR frame instead of RECEIPT | Future resolved with ERROR frame; action check fails | `SendFailedException` thrown with broker error message |
| TCP write fails (`IOException`) | `SendFailedException` thrown immediately | Attempt counted; connection refreshed; retry if budget remains |
| Connection exhausted (`TooManyConnectionRetryAttemptsException`) | Propagated to caller | All send attempts failed; no delivery guarantee |
| Maximum retries exhausted | `publishMaxRetryAttempts` reached | `SendFailedException` thrown; caller must handle |

## Sequence Diagram

```
Application         -> ProducerImpl       : sendSafe(message)
ProducerImpl        -> StompConnection    : checkStatus() / refreshIfStale()
ProducerImpl        -> MessageSerializer  : serialize(message.getMessageInternal())
ProducerImpl        -> StompConnection    : registerReceipt(receipt_id, future)
ProducerImpl        -> StompConnection    : send(StompFrame[SEND, dest, receipt-id, body])
StompConnection     -> MBus Broker        : TCP write STOMP SEND frame with receipt header
MBus Broker         -> MBus Broker        : Persist message to destination
MBus Broker         --> StompConnection   : TCP write STOMP RECEIPT frame (receipt-id)
StompConnection     --> ProducerImpl      : future.set(receiptFrame)
ProducerImpl        --> Application       : returns (delivery confirmed)
```

## Related

- Architecture dynamic view: `dynamic-continuumMbusClientLibrary`
- Related flows: [Producer Publish — Fire and Forget](producer-send.md)
