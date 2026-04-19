---
service: "mbus-client"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the MBus Java Client Library.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Producer Publish — Fire and Forget](producer-send.md) | synchronous | Application code calls `send()` | Producer builds a message, serializes it, and sends a STOMP SEND frame to the broker without waiting for confirmation |
| [Producer Publish — Safe Send with Receipt](producer-send-safe.md) | synchronous | Application code calls `sendSafe()` | Producer sends a message and blocks until the broker returns a STOMP RECEIPT frame, with retry on timeout |
| [Consumer Startup and Broker Discovery](consumer-startup.md) | synchronous | Application code calls `ConsumerImpl.start()` | Consumer fetches active broker list, opens STOMP connections to each broker, and starts prefetch threads |
| [Consumer Receive and Acknowledge](consumer-receive-ack.md) | synchronous | Application code calls `receive()` and `ack()` or `nack()` | Consumer polls the prefetch cache, delivers a message to the application, and processes the subsequent ack or nack back to the broker |
| [Connection Lifecycle and Keepalive](connection-lifecycle.md) | asynchronous | Time-based (periodic) and failure-driven | Keepalive frames prevent connection timeout; stale connections trigger automatic reconnect and re-subscribe |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows that cross service boundaries involve the MBus broker cluster (`messageBus`). The producer flows terminate at the broker (STOMP SEND). The consumer flows originate at the broker (STOMP MESSAGE pushed to consumer). Dynamic server discovery also crosses to the MBus VIP concierge HTTP endpoint.

For architecture dynamic views, refer to the DSL at `structurizr/import/mbus-client/architecture/views/dynamics.dsl` (currently no dynamic views defined; flows are documented here).
