---
service: "ingestion-jtier"
title: "Deal Deletion Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-deletion-processing"
flow_type: batch
trigger: "Quartz scheduler fires on configured cron, or POST /ingest/v1/deal_deletion_processor"
participants:
  - "continuumIngestionJtierService"
  - "continuumIngestionJtierPostgres"
  - "continuumIngestionJtierRedis"
  - "continuumDealManagementApi"
  - "mbusPlatform"
architecture_ref: "dynamic-ingestion-jtier-deal-deletion"
---

# Deal Deletion Processing

## Summary

The deal deletion processing flow drains a queue of deals that have been marked for deletion — typically because the associated partner offer is no longer available, the partner has terminated the relationship, or offer data has been retracted. The flow reads pending deletion records from PostgreSQL, submits deletion requests to the Deal Management API, and marks records as processed. An IngestionOperationalEvent is published for each batch completion.

## Trigger

- **Type**: schedule / api-call
- **Source**: Quartz scheduler (`ingestionSchedulers`) on a configured cron expression; or `POST /ingest/v1/deal_deletion_processor` for an on-demand drain
- **Frequency**: Periodic scheduled batch (exact cron not confirmed from inventory); on-demand available

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion JTier Service | Reads deletion queue, submits deletions, marks records processed | `continuumIngestionJtierService` |
| Ingestion PostgreSQL | Hosts the `deal_deletions` queue table; updated as records are processed | `continuumIngestionJtierPostgres` |
| Ingestion Redis | Provides distributed lock to prevent concurrent deletion batch runs | `continuumIngestionJtierRedis` |
| Deal Management API | Receives deal deletion requests and removes deals from the catalog | `continuumDealManagementApi` |
| Message Bus | Receives IngestionOperationalEvent on batch completion | `mbusPlatform` |

## Steps

1. **Acquire distributed lock**: `ingestionCache` acquires a Redis lock for the deletion processor job to prevent overlapping batch runs.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (SET NX with TTL)

2. **Read pending deletion records**: `ingestionPersistence` queries the `deal_deletions` table for records where `processedAt IS NULL`, ordered by `queuedAt`.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

3. **Submit deletion to Deal Management API**: For each pending deletion, `ingestionClientGateway` calls Deal Management API to remove the deal from the catalog.
   - From: `continuumIngestionJtierService`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/REST

4. **Mark record as processed**: `ingestionPersistence` updates the `deal_deletions` record, setting `processedAt` to the current timestamp.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

5. **Update offer record status**: `ingestionPersistence` updates the corresponding `offers` table record to status DELETED.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

6. **Publish IngestionOperationalEvent (batch complete)**: After processing all pending records, `ingestionMessaging` publishes an operational event indicating the deletion batch result (recordsProcessed, failures).
   - From: `continuumIngestionJtierService`
   - To: `mbusPlatform`
   - Protocol: Message Bus

7. **Release distributed lock**: `ingestionCache` releases the deletion processor Redis lock.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierRedis`
   - Protocol: Redis (DEL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Management API returns 404 (deal already deleted) | Mark record as processed; log info | Record cleaned up; no re-attempt |
| Deal Management API returns 5xx for a record | Skip that record; continue batch; log error | Record remains in queue (processedAt stays null); retried on next batch run |
| Redis lock conflict | Skip this batch run | Logged; next scheduled run will process the queue |
| PostgreSQL read failure | Abort batch; release lock | Queue not processed; retried on next run |
| Empty queue (no pending records) | No-op; release lock | Batch completes immediately; operational event published with recordsProcessed=0 |

## Sequence Diagram

```
ingestionSchedulers -> ingestionPipeline: trigger deletion processor
ingestionPipeline -> continuumIngestionJtierRedis: acquire deletion processor lock
continuumIngestionJtierRedis --> ingestionPipeline: lock acquired
ingestionPipeline -> continuumIngestionJtierPostgres: SELECT deal_deletions WHERE processedAt IS NULL
continuumIngestionJtierPostgres --> ingestionPipeline: pending deletion records
loop for each pending record
  ingestionPipeline -> continuumDealManagementApi: DELETE deal
  continuumDealManagementApi --> ingestionPipeline: 200 OK
  ingestionPipeline -> continuumIngestionJtierPostgres: UPDATE deal_deletions SET processedAt=now()
  ingestionPipeline -> continuumIngestionJtierPostgres: UPDATE offers SET status=DELETED
end loop
ingestionPipeline -> mbusPlatform: publish IngestionOperationalEvent (batch complete)
ingestionPipeline -> continuumIngestionJtierRedis: release lock
```

## Related

- Architecture dynamic view: `dynamic-ingestion-jtier-deal-deletion`
- Related flows: [Offer to Deal Creation](offer-to-deal-creation.md), [Deal State Management](deal-state-management.md)
