---
service: "ingestion-jtier"
title: "Availability Synchronization"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "availability-synchronization"
flow_type: scheduled
trigger: "Quartz scheduler fires on configured cron, or POST /ingest/v1/availability/start, or POST /ingest/v1/availability/bulk/start"
participants:
  - "continuumIngestionJtierService"
  - "continuumIngestionJtierPostgres"
  - "continuumIngestionJtierRedis"
  - "viatorApi"
  - "mindbodyApi"
  - "bookerApi"
  - "rewardsNetworkApi"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-ingestion-jtier-availability-sync"
---

# Availability Synchronization

## Summary

The availability synchronization flow keeps deal availability windows (start/end times, capacity) current by periodically fetching updated availability data from external partner APIs and pushing changes to active deals via the Deal Management API. Unlike the full feed extraction flow, this flow targets only the availability dimension of existing deals rather than re-extracting complete offer catalogs. It supports both per-partner and bulk multi-partner execution.

## Trigger

- **Type**: schedule / api-call
- **Source**: Quartz scheduler (`ingestionSchedulers`) on a configured cron; `POST /ingest/v1/availability/start` for a single-partner on-demand run; `POST /ingest/v1/availability/bulk/start` for a multi-partner bulk run
- **Frequency**: Periodic scheduled (more frequent than full extraction runs — exact cron not confirmed from inventory); on-demand available

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion JTier Service | Orchestrates availability fetch, comparison, and deal update | `continuumIngestionJtierService` |
| Ingestion PostgreSQL | Stores current availability records; updated after each sync | `continuumIngestionJtierPostgres` |
| Ingestion Redis | Provides distributed lock and cached availability snapshots for delta comparison | `continuumIngestionJtierRedis` |
| Viator API | Source of Viator offer availability windows | `viatorApi` |
| Mindbody API | Source of Mindbody session/class availability | `mindbodyApi` |
| Booker API | Source of Booker appointment availability | `bookerApi` |
| RewardsNetwork API | Source of RewardsNetwork dining availability | `rewardsNetworkApi` |
| Deal Management API | Receives availability update payloads for active deals | `continuumDealManagementApi` |

## Steps

1. **Acquire distributed lock**: `ingestionCache` acquires a Redis lock for the availability sync job to prevent overlapping runs.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (SET NX with TTL)

2. **Load current availability records**: `ingestionPersistence` reads the existing availability records for the target partner(s) from PostgreSQL to establish the baseline for delta comparison.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

3. **Fetch updated availability from partner API**: `ingestionClientGateway` calls the appropriate external partner API to retrieve current availability windows and capacity data.
   - From: `continuumIngestionJtierService`
   - To: `viatorApi` | `mindbodyApi` | `bookerApi` | `rewardsNetworkApi`
   - Protocol: HTTP/REST

4. **Compute availability delta**: `ingestionPipeline` compares fetched availability against the stored baseline to identify changed records (new windows, updated capacities, closed windows).
   - From: `continuumIngestionJtierService` (internal pipeline step)
   - To: `continuumIngestionJtierService`
   - Protocol: direct (in-process)

5. **Push availability updates to Deal Management API**: `ingestionClientGateway` sends availability update payloads for each changed deal to the Deal Management API.
   - From: `continuumIngestionJtierService`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/REST

6. **Persist updated availability records**: `ingestionPersistence` updates the `availability` table in PostgreSQL with the new windows, capacities, and `syncedAt` timestamp.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

7. **Update Redis cache**: `ingestionCache` refreshes the cached availability snapshot for delta comparison on the next sync.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis

8. **Release distributed lock**: `ingestionCache` releases the availability sync lock.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (DEL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner API returns stale or empty availability | Skip update for that partner in this run; log warning | Existing availability preserved; stale data persists until next run |
| Deal Management API returns error for an update | Log error; continue processing remaining deals | Some deals not updated; retried on next sync run |
| Redis lock conflict | Skip this sync run | Logged; next scheduled run will proceed normally |
| PostgreSQL write failure | Log error; sync run marked failed | Availability data inconsistent until next successful run |

## Sequence Diagram

```
ingestionSchedulers -> ingestionPipeline: trigger availability sync
ingestionPipeline -> continuumIngestionJtierRedis: acquire availability sync lock
continuumIngestionJtierRedis --> ingestionPipeline: lock acquired
ingestionPipeline -> continuumIngestionJtierPostgres: read current availability records
continuumIngestionJtierPostgres --> ingestionPipeline: availability baseline
ingestionPipeline -> viatorApi: GET availability for partner
viatorApi --> ingestionPipeline: availability windows
ingestionPipeline -> ingestionPipeline: compute delta (changed records)
ingestionPipeline -> continuumDealManagementApi: PUT availability updates
continuumDealManagementApi --> ingestionPipeline: update confirmation
ingestionPipeline -> continuumIngestionJtierPostgres: update availability records (syncedAt)
ingestionPipeline -> continuumIngestionJtierRedis: refresh cache + release lock
```

## Related

- Architecture dynamic view: `dynamic-ingestion-jtier-availability-sync`
- Related flows: [Partner Feed Extraction](partner-feed-extraction.md), [API Availability Query](api-availability-query.md)
