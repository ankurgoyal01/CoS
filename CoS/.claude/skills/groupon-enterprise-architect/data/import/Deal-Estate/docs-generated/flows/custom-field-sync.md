---
service: "Deal-Estate"
title: "Custom Field Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "custom-field-sync"
flow_type: batch
trigger: "API call or background worker trigger (manual sync or scheduled job)"
participants:
  - "continuumDealEstateWeb"
  - "continuumDealEstateWorker"
  - "continuumDealEstateScheduler"
  - "continuumDealEstateMysql"
  - "continuumDealEstateRedis"
  - "continuumCustomFieldsService"
architecture_ref: "dynamic-custom-field-sync"
---

# Custom Field Sync

## Summary

Custom fields extend deal records with additional metadata not covered by the core schema. This flow ensures that custom field values are written to the Custom Fields Service when deals are created or updated, and read back from the service to enrich deal responses. Background workers (triggered by API actions, manual `sync_data` requests, or scheduled jobs) handle bulk custom field synchronisation to keep deal metadata current across Deal-Estate and the Custom Fields Service.

## Trigger

- **Type**: api-call or schedule
- **Source**: Custom field writes occur synchronously on deal create/update API calls; bulk syncs are triggered via `POST /deals/:id/sync_data` or via Resque Scheduler recurring jobs
- **Frequency**: Per deal create/update (synchronous path); periodic batch (scheduled path)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Estate Web | Triggers synchronous custom field read/write on API actions | `continuumDealEstateWeb` |
| Deal Estate Workers | Executes bulk custom field sync jobs | `continuumDealEstateWorker` |
| Deal Estate Scheduler | Enqueues recurring custom field sync jobs | `continuumDealEstateScheduler` |
| Deal Estate MySQL | Source of deal records requiring custom field sync | `continuumDealEstateMysql` |
| Deal Estate Redis | Job queue for async sync jobs | `continuumDealEstateRedis` |
| Custom Fields Service | Stores and serves custom field values for deals | `continuumCustomFieldsService` |

## Steps

### Synchronous Path (on deal create/update)

1. **Deal create or update API call completes**: Web layer has persisted deal record to MySQL.
   - From: `caller`
   - To: `continuumDealEstateWeb`
   - Protocol: REST

2. **Write custom fields to Custom Fields Service**: Web layer calls Custom Fields Service to write any custom field values included in the request payload.
   - From: `continuumDealEstateWeb`
   - To: `continuumCustomFieldsService`
   - Protocol: REST (service-client)

3. **Confirm write and return response**: Custom Fields Service acknowledges; web layer returns the deal response.
   - From: `continuumDealEstateWeb`
   - To: `caller`
   - Protocol: REST

### Batch / Scheduled Path

4. **Scheduler enqueues custom field sync job**: Resque Scheduler fires a recurring job definition (from `config/resque_schedule.yml`) for bulk custom field sync.
   - From: `continuumDealEstateScheduler`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

5. **Worker dequeues and processes job**: Worker dequeues the sync job, queries MySQL for deals requiring custom field updates.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

6. **Fetch deals from MySQL**: Worker retrieves the set of deals whose custom fields need refreshing.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

7. **Read and write custom fields**: For each deal, worker calls Custom Fields Service to read current values and/or write updated values.
   - From: `continuumDealEstateWorker`
   - To: `continuumCustomFieldsService`
   - Protocol: REST (service-client)

8. **Update local deal record**: Worker writes synced custom field metadata back to MySQL if local deal records need to reflect custom field state.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Custom Fields Service unavailable (sync path) | service-client timeout/error; deal record still persisted | Custom fields not written; deal created without custom field values |
| Custom Fields Service unavailable (batch path) | Resque retries job with backoff | Sync delayed; eventually consistent once service recovers |
| MySQL unavailable (batch path) | Resque retries job | Job deferred; sync lag increases |
| Job failure after partial batch processing | Resque moves job to failed queue | Partial sync; manual retry required via Resque Web UI |

## Sequence Diagram

```
--- Synchronous path ---
caller -> continuumDealEstateWeb: POST /deals or PUT /deals/:id (with custom fields)
continuumDealEstateWeb -> continuumDealEstateMysql: persist deal record
continuumDealEstateWeb -> continuumCustomFieldsService: write custom field values
continuumCustomFieldsService --> continuumDealEstateWeb: 200 OK
continuumDealEstateWeb --> caller: 201 Created / 200 OK

--- Batch / Scheduled path ---
continuumDealEstateScheduler -> continuumDealEstateRedis: enqueue custom-field-sync job
continuumDealEstateWorker -> continuumDealEstateRedis: dequeue job
continuumDealEstateWorker -> continuumDealEstateMysql: SELECT deals needing sync
continuumDealEstateWorker -> continuumCustomFieldsService: read/write custom fields per deal
continuumDealEstateWorker -> continuumDealEstateMysql: UPDATE deal custom field metadata
```

## Related

- Architecture dynamic view: `dynamic-custom-field-sync`
- Related flows: [Deal Creation and Import](deal-creation-and-import.md), [Deal Scheduling and Publication](deal-scheduling-and-publication.md)
