---
service: "watson-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Watson API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal KV Read](deal-kv-read.md) | synchronous | GET request from Continuum service | Reads a deal-indexed KV bucket value from Redis |
| [Deal KV Write](deal-kv-write.md) | synchronous + event-driven | POST request from Continuum service | Writes a deal KV bucket to Redis and publishes a RealtimeKvEvent to Kafka |
| [User KV Write](user-kv-write.md) | synchronous + event-driven | POST request from Continuum service | Writes a user KV bucket to Redis and publishes a RealtimeKvEvent to Kafka |
| [Email Freshness Retrieval](email-freshness-retrieval.md) | synchronous | GET request from email marketing pipeline | Reads Avro-encoded email send/open freshness data from Redis and returns a scored response |
| [Recently Viewed Deals](recently-viewed-deals.md) | synchronous | GET request from deal display service | Retrieves recently-viewed deal list from Redis sorted sets for a user or bcookie |
| [Janus Event Counter Query](janus-event-counter-query.md) | synchronous | GET request from analytics consumer | Queries time-windowed deal event counters (views, purchases) from Redis with aggregation |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 (Kafka publish is a side effect of synchronous KV write flows) |
| Batch / Scheduled | 0 |

## Cross-Service Flows

Watson API sits at the boundary between operational data stores and Continuum platform consumers. Two flows have a cross-service async component:

- **Deal KV Write** and **User KV Write** both publish `RealtimeKvEvent` records to Kafka upon successful Redis write. The downstream Holmes/Darwin pipeline consumes these events for long-term persistence and ML model feature refresh. This cross-service async path is documented in [Events](../events.md).

The central architecture dynamic view for Watson API container interactions: `continuumWatsonApiService-container`.
