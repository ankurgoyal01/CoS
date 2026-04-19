---
service: "channel-manager-integrator-derbysoft"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

The service uses two async messaging systems: **MBus** (STOMP/JMS) for bidirectional booking workflow messaging with the Groupon Inventory Service Worker (ISW), and **Kafka** for publishing inbound ARI payloads forwarded to downstream consumers. MBus consumption is handled by `IswBookingMessageProcessor` (primary queue) and `DLQMessageProcessor` (dead-letter queue). Kafka publishing is handled by `WorkerKafkaMessageProducer`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Kafka topic (configured via `kafkaConfig.topic`) | `ARIMessage` | Successful validation and processing of a Daily ARI push | Hotel ID, date range, availability status, rates, min-stay rules |
| MBus `cmiBookingResponseProducerConfig.destination` | `ResponseMessageContainer` | Completion of a `RESERVE` or `CANCEL` message processing | Identifier (xRequestId), response message type, booking outcome |

### ARIMessage Detail

- **Topic**: Configured via `kafkaConfig.topic` (runtime YAML; actual topic name is environment-specific)
- **Trigger**: Successful completion of Daily ARI push processing by `ariPushProcessor`
- **Payload**: `ARIMessage` schema from `channel-manager-async-schema` v0.0.22; includes hotel identifier, date-range availability, rates, and min-stay constraints
- **Consumers**: Downstream Getaways services that process ARI data (not directly tracked in this repo)
- **Guarantees**: at-least-once (Kafka producer with configurable `acks` setting)

### ResponseMessageContainer (Booking Response) Detail

- **Topic**: MBus destination configured via `cmiBookingResponseProducerConfig.destination`
- **Trigger**: Completion of `RESERVE` or `CANCEL` processing; emits success or failure response
- **Payload**: `ResponseMessageContainer` wrapping an `AbstractResponseMessage` (success or failure variant); includes `xRequestId` correlation identifier
- **Consumers**: Groupon Inventory Service Worker (ISW)
- **Guarantees**: at-least-once (MBus STOMP; message ack/nack on completion or error)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus `iswBookingMessageListenerConfig.destination` | `RequestMessageContainer` (RESERVE or CANCEL) | `IswBookingMessageProcessor` | Submits prebook/book or cancel to Derbysoft API; persists state; publishes booking response via MBus |
| MBus `dlqMessageListenerConfig.destination` | `RequestMessageContainer` (dead-letter) | `DLQMessageProcessor` | Updates reservation state in DB; publishes failure response via MBus |

### RequestMessageContainer (RESERVE) Detail

- **Topic**: MBus destination configured via `iswBookingMessageListenerConfig.destination`
- **Handler**: `IswBookingMessageProcessor` dispatches to `ReservationProcessor`; runs prebook → book state machine
- **Idempotency**: Not explicitly guaranteed; reservations are tracked by state in the database and re-entrant calls are handled by the state machine
- **Error handling**: Recoverable errors (`RecoverableExecutionException`) and `MessageException` result in `nack`; messages re-queued for retry or forwarded to DLQ
- **Processing order**: unordered (parallel worker threads per `iswBookingMessageListenerConfig.numberOfWorkers`)

### RequestMessageContainer (CANCEL) Detail

- **Topic**: MBus destination configured via `iswBookingMessageListenerConfig.destination` (same queue, `CANCEL` message type)
- **Handler**: `IswBookingMessageProcessor` dispatches to `CancellationProcessor`
- **Idempotency**: Not explicitly guaranteed
- **Error handling**: Same nack/retry strategy as RESERVE; unrecoverable errors forwarded to DLQ listener
- **Processing order**: unordered

### DLQ RequestMessageContainer Detail

- **Topic**: MBus destination configured via `dlqMessageListenerConfig.destination`
- **Handler**: `DLQMessageProcessor` — marks reservation as failed in the database and sends a failure `ResponseMessageContainer` back over MBus
- **Idempotency**: DLQ processing is intended to be terminal; updates state to failure and responds once
- **Error handling**: Errors during DLQ processing are logged; no further retry
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| MBus `dlqMessageListenerConfig.destination` | `iswBookingMessageListenerConfig.destination` | Configured on MBus broker | See [Runbook](runbook.md) for Splunk/Wavefront alerts |
