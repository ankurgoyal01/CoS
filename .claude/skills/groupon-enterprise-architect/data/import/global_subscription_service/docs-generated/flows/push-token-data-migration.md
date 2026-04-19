---
service: "global_subscription_service"
title: "Push Token Data Migration"
generated: "2026-03-03"
type: flow
flow_name: "push-token-data-migration"
flow_type: asynchronous
trigger: "MBus data migration event on mbusDataMigrationConfiguration topic"
participants:
  - "globalSubscriptionService"
  - "continuumPushTokenCassandra"
  - "continuumPushTokenPostgres"
  - "messageBus"
architecture_ref: "components-globalSubscriptionService-components"
---

# Push Token Data Migration

## Summary

This flow migrates push device token records from the legacy Cassandra store to the primary PostgreSQL store. It is driven by MBus data migration events and runs as a background asynchronous process alongside normal service operation. Individual token records can also be migrated on demand using the `/push-subscription/migration/{token}` REST endpoint. The goal is to complete the full migration so that Cassandra reads can eventually be decommissioned.

## Trigger

- **Type**: event
- **Source**: MBus data migration topic (configured via `mbusDataMigrationConfiguration`); also triggerable manually via `GET /push-subscription/migration/{token}`
- **Frequency**: Continuous (event-driven for batch migration); on demand (for individual token repair)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers data migration events | `messageBus` |
| Push Token Service | Orchestrates the migration read-write cycle | `pushTokenService` |
| Push Token DAO | Reads from Cassandra and writes to PostgreSQL | `pushTokenDao` |
| Cassandra Client | Reads legacy token record by device token key | `cassandraClient_GloSubSer` |
| Push Token Cassandra | Legacy source data store | `continuumPushTokenCassandra` |
| Postgres Client | Upserts migrated token into PostgreSQL | `postgresClient_GloSubSer` |
| Push Token Postgres | Target data store post-migration | `continuumPushTokenPostgres` |

## Steps

1. **Receive data migration event**: The MBus consumer (configured via `mbusDataMigrationConfiguration`) receives a migration event containing one or more device token values to migrate.
   - From: `messageBus`
   - To: `pushTokenService`
   - Protocol: MBus

2. **Read from Cassandra**: Cassandra Client reads the push token record from `continuumPushTokenCassandra` by device token (partition key). Retrieves device_token, consumer_id, app_type, country_code, status, and all associated metadata.
   - From: `pushTokenDao` → `cassandraClient_GloSubSer`
   - To: `continuumPushTokenCassandra`
   - Protocol: Cassandra protocol

3. **Upsert into PostgreSQL**: Postgres Client upserts the retrieved token record into `continuumPushTokenPostgres`. Uses an upsert pattern (INSERT ... ON CONFLICT DO UPDATE) to ensure idempotency in case the event is replayed.
   - From: `pushTokenDao` → `postgresClient_GloSubSer`
   - To: `continuumPushTokenPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Acknowledge event**: MBus consumer acknowledges the migration event upon successful Postgres write.
   - From: `pushTokenService`
   - To: `messageBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Token not found in Cassandra | Logged; event acknowledged | Migration skipped for that token; token may already be Postgres-only |
| PostgreSQL write failure | Logged; event not acknowledged; MBus retries (at-least-once) | Migration retried on next delivery |
| Cassandra read timeout | Logged; event not acknowledged | Migration retried on next delivery |
| Duplicate migration event | Upsert pattern prevents duplicate rows | Idempotent — no data corruption |
| Manual trigger failure | `GET /push-subscription/migration/{token}` returns 404 if token not in Cassandra | Manual retry not required if token already in Postgres |

## Sequence Diagram

```
messageBus -> pushTokenService: deliver data migration event (device_token list)
pushTokenService -> continuumPushTokenCassandra: READ token record by device_token
continuumPushTokenCassandra --> pushTokenService: token record (or not found)
pushTokenService -> continuumPushTokenPostgres: UPSERT token record
continuumPushTokenPostgres --> pushTokenService: OK
pushTokenService -> messageBus: acknowledge event
```

## Related

- Architecture dynamic view: No dynamic view defined — see `components-globalSubscriptionService-components`
- Related flows: [Push Token Registration](push-token-registration.md)
- Manual repair endpoint: `GET /push-subscription/migration/{token}`, `GET /push-token/device-token/{deviceToken}/replay/create`, `GET /push-token/device-token/{deviceToken}/replay/update`
