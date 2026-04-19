---
service: "AudiencePayloadSpark"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# Flows

Process and flow documentation for AudiencePayloadSpark.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Attribute Payload Upload](attribute-payload-upload.md) | batch | Manual Fabric command or cron schedule | Reads user/bcookie system attributes from Hive and writes full or delta payloads to Cassandra and Bigtable |
| [PA Membership Upload](pa-membership-upload.md) | batch | Manual Fabric command or cron schedule | Fetches Published Audience membership Hive tables via AMS API search and writes user/bcookie PA memberships to Cassandra with TTL |
| [SAD Aggregation](sad-aggregation.md) | batch | Manual Fabric command or cron schedule | Aggregates SAD PA memberships across a time window and writes combined payload to Cassandra SAD tables and AWS Keyspaces |
| [CA Attributes to Redis](ca-attributes-redis.md) | batch | Daily cron / manual Fabric command | Reads CA consumer attributes from Hive, writes versioned key-value records to Redis, and removes stale keys via delta diff |
| [Hive to Keyspaces Retry](hive-to-keyspaces-retry.md) | batch | Manual / recovery | Loads a previously computed SAD Hive table and writes it directly to AWS Keyspaces with locking semantics |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The overall payload generation and publication flow is modelled as a dynamic view in the architecture:

- **Architecture dynamic view**: `dynamic-payload_generation_flow`
- Participants: `continuumAudiencePayloadOps` -> `continuumAudiencePayloadSpark` -> `yarnCluster` -> `hiveMetastore` -> `amsApi` -> `cassandraKeyspaces` / `gcpBigtable` / `redisCluster`
