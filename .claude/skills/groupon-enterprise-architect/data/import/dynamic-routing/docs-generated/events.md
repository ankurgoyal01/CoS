---
service: "dynamic-routing"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, hornetq, artemis, jms]
---

# Events

## Overview

The dynamic-routing service does not publish or consume fixed, named business events in the traditional sense. Instead, it acts as a **runtime-configurable message bridge**: each active dynamic route consumes messages from a configured JMS source endpoint (queue or topic on a HornetQ or Artemis broker, or an HTTP REST ingestion endpoint) and delivers them to a configured JMS destination endpoint. The specific queues and topics bridged are operator-defined at runtime and persisted in MongoDB. The service is itself the messaging infrastructure layer — it enables arbitrary source-to-destination pairings across brokers and datacenters.

## Published Events

The service does not publish fixed event types. For each active dynamic route, messages received on the source endpoint are forwarded (fire-and-forget, `inOnly` pattern) to the configured destination. Enriched headers are attached before forwarding.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Operator-configured destination (queue or topic on any registered broker) | Pass-through (original message body preserved) | Message received on source endpoint | Original message body; enriched JMS headers (see below) |

### Forwarded Message Detail

- **Destination**: Operator-configured at route creation time — any JMS queue or topic on a registered broker
- **Trigger**: Message arrives on source JMS endpoint or REST ingestion path
- **Payload**: Original message body passed through unchanged (unless a Transformer is applied); headers are enriched
- **Consumers**: Any JMS consumer subscribed to the destination queue/topic on the target broker
- **Guarantees**: At-least-once (idempotent consumer with in-memory deduplication repository of size 500,000; dead-letter channel with 3 redeliveries at 5-second intervals)

### Headers Attached to Forwarded Messages

The following headers are added by Camel processors before delivery:

- **`CopyMbusClientInfoHeadersProcessor`**: Copies mbus-client metadata headers from the incoming message
- **`AddDynamicRoutingHeadersProcessor`**: Adds dynamic routing provenance headers (identifies the route and originating service)
- **`AddChunkHeadersProcessor`**: Adds chunk/tracing headers when tracing chunk size is configured (`> 0`)

## Consumed Events

Each dynamic route subscribes to its configured source endpoint. Source endpoint types supported:

| Endpoint Type | Description | Protocol |
|---------------|-------------|----------|
| JMS Queue (HornetQ) | Durable queue on a HornetQ broker | JMS via HornetQ Netty connector |
| JMS Queue (Artemis) | Durable queue on an Artemis 2.x broker | JMS via Artemis JMS client |
| JMS Topic (HornetQ/Artemis) | Topic subscription, optionally durable | JMS |
| REST endpoint | HTTP POST body ingested as a message | HTTP via Camel servlet |

### Source Endpoint Consumption Detail

- **Handler**: `CamelRouteBuilder` — configures Apache Camel's `from()` with the source URI, idempotent consumer, filter chain, transformer, then `inOnly()` to destination
- **Idempotency**: In-memory idempotent repository (500,000 entry capacity) keyed on message `id`; `skipDuplicate` is configurable per endpoint
- **Error handling**: Dead-letter channel — 3 redelivery attempts with 5-second initial delay (exponential back-off not configured); on exhaustion, message is routed to a log destination named `deadletter.<routeName>`
- **Processing order**: Unordered (single Camel context per route, auto-acknowledge)

## Dead Letter Queues

| DLQ | Source | Retention | Alert |
|-----|--------|-----------|-------|
| `deadletter.<routeName>` (log destination) | Each dynamic route's source endpoint | Log-based (no separate broker queue by default) | No automated alert configured in code; monitored via Wavefront dashboard |

> Dead-letter handling routes failed messages to a Steno log destination (`de.groupon.jms.route.error.<routeName>`), not to a separate JMS queue, unless the `logDestinationProvider` is configured to use a JMS destination.
