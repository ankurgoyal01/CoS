---
service: "glive-gia"
title: "Salesforce Deal Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "salesforce-deal-sync"
flow_type: scheduled
trigger: "Resque-scheduler cron job fires on configured schedule"
participants:
  - "continuumGliveGiaWorker"
  - "continuumGliveGiaRedisCache"
  - "continuumGliveGiaMysqlDatabase"
architecture_ref: "dynamic-glive-gia-sf-sync"
---

# Salesforce Deal Sync

## Summary

GIA runs a scheduled Resque job that synchronizes deal contract data from Salesforce into GIA's local deal records. The job queries Salesforce for new or updated deal contracts, maps the Salesforce data to GIA deal attributes, and creates or updates the corresponding deal records in MySQL. Bidirectional sync may also push status updates from GIA back to Salesforce records. This flow ensures that deal metadata in GIA stays consistent with the contracts managed by the sales and supply team in Salesforce.

## Trigger

- **Type**: schedule
- **Source**: resque-scheduler fires the Salesforce sync job on a configured cron schedule (defined in `config/schedule.rb`)
- **Frequency**: Periodic (exact schedule managed in deployment configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Redis (Scheduler) | Triggers the scheduled sync job | `continuumGliveGiaRedisCache` |
| GIA Background Worker | Executes the sync; calls Salesforce; writes to MySQL | `continuumGliveGiaWorker` |
| Salesforce | External CRM; source of deal contracts | External (`salesForce`) |
| GIA MySQL Database | Target for created/updated deal records | `continuumGliveGiaMysqlDatabase` |

## Steps

1. **Scheduler fires sync job**: resque-scheduler enqueues the Salesforce deal sync job onto the Resque queue
   - From: resque-scheduler (within `continuumGliveGiaRedisCache`)
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

2. **Worker dequeues job**: `resqueWorkers_GliGia` picks up the sync job from Redis
   - From: `continuumGliveGiaWorker`
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

3. **Query Salesforce for updated contracts**: `workerRemoteClients_GliGia` calls the Salesforce REST API to retrieve deal contracts that have been created or modified since the last sync
   - From: `continuumGliveGiaWorker` (`workerRepositories_GliGia` -> `workerRemoteClients_GliGia`)
   - To: Salesforce (`salesForce`)
   - Protocol: REST (HTTPS)

4. **Map Salesforce data to deal attributes**: `workerMappers` translate Salesforce contract fields to GIA deal model attributes
   - From: `workerRepositories_GliGia`
   - To: `workerMappers`
   - Protocol: Direct (in-process)

5. **Upsert deal records in MySQL**: `jobServices_GliGia` creates new deal records or updates existing ones in MySQL via `workerDomainModels`, matching on Salesforce deal ID
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia` -> `workerDomainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

6. **Push GIA status updates back to Salesforce** (if applicable): For deals whose status has changed in GIA, `workerRemoteClients_GliGia` updates the corresponding Salesforce record
   - From: `continuumGliveGiaWorker` (`workerRepositories_GliGia` -> `workerRemoteClients_GliGia`)
   - To: Salesforce (`salesForce`)
   - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | HTTP error; Resque job fails and is retried | Deal sync delayed until retry; stale data in GIA |
| Salesforce OAuth token expired | 401 response; token refresh attempted; if fails, job retried | Sync delayed; authentication must be resolved |
| MySQL write failure on upsert | ActiveRecord exception; Resque retries | Partial sync for that batch; retried |
| Salesforce rate limit hit | 429 response; job fails; Resque retries with backoff | Sync delayed; rate limit resolved before retry |

## Sequence Diagram

```
resque-scheduler -> GIA Redis: RPUSH salesforce_deal_sync job
GIA Background Worker -> GIA Redis: LPOP job
GIA Background Worker -> Salesforce: GET /services/data/vXX/sobjects/Opportunity (updated since last sync)
Salesforce --> GIA Background Worker: deal contract records
GIA Background Worker -> GIA MySQL Database: UPSERT deals (create or update by sf_id)
GIA MySQL Database --> GIA Background Worker: records upserted
GIA Background Worker -> Salesforce: PATCH /services/data/vXX/sobjects/Opportunity/:id (status update if applicable)
Salesforce --> GIA Background Worker: 204 No Content
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-sf-sync`
- Related flows: [Deal Creation from DMAPI](deal-creation-from-dmapi.md), [Uninvoiced Deal Detection](uninvoiced-deal-detection.md)
