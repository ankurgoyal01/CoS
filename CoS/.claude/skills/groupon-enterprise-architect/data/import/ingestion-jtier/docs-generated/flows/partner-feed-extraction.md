---
service: "ingestion-jtier"
title: "Partner Feed Extraction"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partner-feed-extraction"
flow_type: scheduled
trigger: "Quartz scheduler fires on configured cron, or operator calls POST /ingest/v1/start"
participants:
  - "continuumIngestionJtierService"
  - "continuumIngestionJtierPostgres"
  - "continuumIngestionJtierRedis"
  - "viatorApi"
  - "mindbodyApi"
  - "bookerApi"
  - "rewardsNetworkApi"
  - "mbusPlatform"
architecture_ref: "dynamic-ingestion-jtier-feed-extraction"
---

# Partner Feed Extraction

## Summary

The partner feed extraction flow is the entry point of the ingestion pipeline. It pulls raw offer and inventory data from external third-party partner APIs (Viator, Mindbody, Booker, RewardsNetwork), persists the extracted records to PostgreSQL, and publishes lifecycle events to the Message Bus. This flow runs on a scheduled basis via Quartz and can also be triggered on demand via the REST API.

## Trigger

- **Type**: schedule / api-call
- **Source**: Quartz scheduler (`ingestionSchedulers`) fires on configured cron expression; alternatively `POST /ingest/v1/start` from an operator or Jenkins pipeline
- **Frequency**: Periodic scheduled (exact cron not confirmed from inventory); on-demand available

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion JTier Service | Orchestrates extraction, coordinates locking, persists data, publishes events | `continuumIngestionJtierService` |
| Ingestion PostgreSQL | Stores extracted offer records and ingestion run audit entries | `continuumIngestionJtierPostgres` |
| Ingestion Redis | Provides distributed lock to prevent concurrent extraction for the same partner | `continuumIngestionJtierRedis` |
| Viator API | Source of Viator experience offer data | `viatorApi` |
| Mindbody API | Source of Mindbody fitness/wellness offer data | `mindbodyApi` |
| Booker API | Source of Booker spa/salon offer data | `bookerApi` |
| RewardsNetwork API | Source of RewardsNetwork dining offer data | `rewardsNetworkApi` |
| Message Bus | Receives FeedExtractionCompleteEvent and IngestionOperationalEvent | `mbusPlatform` |

## Steps

1. **Acquire distributed lock**: Before starting extraction for a partner, `ingestionCache` attempts to acquire a Redis lock for `lock:ingest:{partnerId}`.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (SET NX with TTL)

2. **Write ingestion run start record**: `ingestionPersistence` inserts an `ingestion_runs` row with status STARTED.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

3. **Publish IngestionOperationalEvent (START)**: `ingestionMessaging` publishes a START event to the Message Bus.
   - From: `continuumIngestionJtierService`
   - To: `mbusPlatform`
   - Protocol: Message Bus

4. **Fetch partner configuration**: `ingestionClientGateway` retrieves partner credentials and feed configuration from Partner Service or local cache.
   - From: `continuumIngestionJtierService`
   - To: `continuumPartnerService` (or Redis cache)
   - Protocol: HTTP/REST (or Redis)

5. **Extract feed from external partner**: `ingestionClientGateway` calls the appropriate external partner API (Viator / Mindbody / Booker / RewardsNetwork) to retrieve raw offer records. Large JSON feeds are streamed using jsurfer-jackson.
   - From: `continuumIngestionJtierService`
   - To: `viatorApi` | `mindbodyApi` | `bookerApi` | `rewardsNetworkApi`
   - Protocol: HTTP/REST (or SFTP for file-based feeds)

6. **Transform and validate offer data**: `ingestionPipeline` applies FreeMarker templates and business rules to normalize raw partner offer data into Groupon offer model. Blacklisted offers are filtered out.
   - From: `continuumIngestionJtierService` (internal pipeline step)
   - To: `continuumIngestionJtierService`
   - Protocol: direct (in-process)

7. **Persist extracted offers**: `ingestionPersistence` upserts normalized offer records into the `offers` table in PostgreSQL.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

8. **Update ingestion run record**: `ingestionPersistence` updates the `ingestion_runs` row with final status (SUCCESS/PARTIAL/FAILED), record counts, and completion timestamp.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

9. **Publish FeedExtractionCompleteEvent**: `ingestionMessaging` publishes extraction completion details (partnerId, status, recordCount) to the Message Bus.
   - From: `continuumIngestionJtierService`
   - To: `mbusPlatform`
   - Protocol: Message Bus

10. **Release distributed lock**: `ingestionCache` releases the Redis lock for `lock:ingest:{partnerId}`.
    - From: `continuumIngestionJtierService`
    - To: `continuumIngestionJtierRedis`
    - Protocol: Redis (DEL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis lock already held | Skip extraction for that partner in this run | Partner skipped; logged; other partners continue |
| External partner API error (4xx/5xx) | Mark run as FAILED for that partner; release lock | IngestionOperationalEvent ERROR published; offers not updated |
| External partner API timeout | Same as API error — timeout triggers failure path | Run fails; retry on next scheduled execution |
| Partner feed schema change (parse error) | Transformation fails; run marked FAILED | IngestionOperationalEvent ERROR; no partial data written |
| PostgreSQL write failure | Run marked FAILED; lock released | Data not persisted; retry on next execution |
| Message Bus publish failure | Logged as warning; does not fail the run | Events lost for that run; ingestion data still persisted |

## Sequence Diagram

```
ingestionSchedulers -> ingestionPipeline: trigger feed extraction run
ingestionPipeline -> continuumIngestionJtierRedis: acquire lock:ingest:{partnerId}
continuumIngestionJtierRedis --> ingestionPipeline: lock acquired
ingestionPipeline -> continuumIngestionJtierPostgres: insert ingestion_runs (STARTED)
ingestionPipeline -> mbusPlatform: publish IngestionOperationalEvent (START)
ingestionPipeline -> continuumPartnerService: fetch partner config
continuumPartnerService --> ingestionPipeline: partner credentials/config
ingestionPipeline -> viatorApi: GET partner feed
viatorApi --> ingestionPipeline: raw offer records
ingestionPipeline -> ingestionPipeline: transform and validate offers
ingestionPipeline -> continuumIngestionJtierPostgres: upsert offers
ingestionPipeline -> continuumIngestionJtierPostgres: update ingestion_runs (SUCCESS)
ingestionPipeline -> mbusPlatform: publish FeedExtractionCompleteEvent
ingestionPipeline -> continuumIngestionJtierRedis: release lock
```

## Related

- Architecture dynamic view: `dynamic-ingestion-jtier-feed-extraction`
- Related flows: [Offer to Deal Creation](offer-to-deal-creation.md), [Availability Synchronization](availability-synchronization.md)
