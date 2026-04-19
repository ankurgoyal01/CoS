---
service: "afl-3pgw"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

AFL-3PGW uses Groupon's MBUS (JMS-based message bus) exclusively as a consumer. It reads attributed order events from a single inbound MBUS topic written by the upstream `afl-rta` service. The service does not publish any events back onto the bus. All outbound affiliate submissions are made via synchronous HTTP calls to Commission Junction and Awin, not via async messaging.

## Published Events

> This service does not publish any async events. All outbound data flows are synchronous HTTP calls to external partner APIs (CJ and Awin).

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.afl_rta.attribution.orders` | Affiliate attributed order event | `OrdersMessageHandler` | Enriches order data, submits to CJ or Awin, persists audit record to MySQL |

### Attributed Order Event Detail

- **Topic**: `jms.topic.afl_rta.attribution.orders`
- **Handler**: `OrdersMessageHandler` — routes to `OrderMessageProcessor`, which coordinates enrichment via Orders Service, MDS, and Incentive Service, then calls `CjOrderRegistrationService` or the Awin adapter
- **Idempotency**: The service persists submission state in the `audit_cj_submitted_orders` and related audit tables; re-processing a duplicate event will record a duplicate submission attempt but the external affiliate API is the authoritative deduplication boundary
- **Error handling**: Messages that cannot be processed (e.g., missing `topCategory` field due to upstream MDS issues) are not acknowledged and expire naturally from the MBUS topic; no DLQ is configured
- **Processing order**: Unordered — events are consumed as available from the topic

## Dead Letter Queues

> No dead letter queues are configured for this service. Unprocessable messages expire from the MBUS topic based on topic retention policy. Monitoring alerts fire when no events are consumed for 2 hours (`RealTime CJ Order Not being Sent for 2 Hrs`) or 12 hours (`AFL-3PGW RealTime CJ Order Not being Sent`).
