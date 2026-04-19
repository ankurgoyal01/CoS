---
service: "watson-realtime"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for watson-realtime.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Realtime KV Write](realtime-kv-write.md) | event-driven | Janus event on `janus-tier2_snc1` | Writes per-user and per-deal realtime KV feature data to Redis |
| [Analytics Aggregation](analytics-aggregation.md) | event-driven | Janus event on `janus-tier2_snc1` or `janus-impression_snc1` | Aggregates impression and tier2 counters and writes to Cassandra/Keyspaces |
| [Cookie Identity Map](cookie-identity-map.md) | event-driven | Janus event on `janus-tier2_snc1` | Resolves bcookie-to-identity mappings and writes to PostgreSQL |
| [RVD View Aggregation](rvd-view-aggregation.md) | event-driven | Janus event on `janus-tier2_snc1` | Aggregates realtime view data per user/deal and writes to Redis |
| [User Identities Enrich](user-identities-enrich.md) | event-driven | Janus event on `janus-tier2_snc1` | Enriches and writes user identity records to Redis |
| [Dealview Counts](dealview-counts.md) | event-driven | Janus event on `janus-tier2_snc1` | Increments deal view counters and writes to Redis |
| [KS Table Trim](ks-table-trim.md) | scheduled | Timer / scheduled job | Trims aged rows from Cassandra/Keyspaces analytics tables |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 6 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

All six event-driven flows originate from the Janus/Conveyor event infrastructure (`conveyorCloud_7b2c` publishes to `kafkaCluster_9f3c`). The resulting data written by these flows is consumed cross-service by watson-api for search ranking and analytics serving. No dynamic views are defined in the architecture model for this service; flows are described structurally from the container relationship model.
