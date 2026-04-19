---
service: "deal-management-api"
title: "Deal Create (Async)"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-create-async"
flow_type: asynchronous
trigger: "HTTP POST to /v2/deals (async path)"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
  - "continuumDealManagementRedis"
  - "continuumDealManagementWorker"
  - "salesForce"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-dealCreateAsync"
---

# Deal Create (Async)

## Summary

The asynchronous deal creation flow decouples the HTTP response from downstream propagation. The API validates the inbound request, persists the deal record to MySQL, enqueues a background job in Redis, and immediately returns a response to the caller. The Resque Worker then independently processes the job to sync the deal to Salesforce and the Deal Catalog Service without blocking the API request.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling or service caller using the v2 async deal creation path
- **Frequency**: On demand (per create request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Receives request, validates, persists, enqueues job | `continuumDealManagementApi` |
| Deal Management MySQL | Stores the new deal record | `continuumDealManagementMysql` |
| Deal Management Redis | Acts as Resque job queue | `continuumDealManagementRedis` |
| Deal Management Worker | Dequeues and processes async job | `continuumDealManagementWorker` |
| Salesforce | Receives async CRM update | `salesForce` |
| Deal Catalog Service | Receives async catalog entry | `continuumDealCatalogService` |

## Steps

1. **Receive create request**: API Controllers accept POST `/v2/deals` with JSON deal payload.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Validate request payload**: Validators check required fields and domain constraints.
   - From: `apiControllers`
   - To: `validationLayer` (internal)
   - Protocol: in-process

3. **Persist deal record**: Repositories write the new deal to MySQL in draft or initial state.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

4. **Enqueue background job**: API enqueues a `deal_created_async` job to Redis with the deal_id and relevant context.
   - From: `continuumDealManagementApi`
   - To: `continuumDealManagementRedis`
   - Protocol: Redis protocol (via Resque client)

5. **Return accepted response**: API Controllers return HTTP 201 or 202 to the caller without waiting for downstream sync.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

6. **Dequeue job**: Worker's Resque Workers pick up the job from the Redis queue.
   - From: `continuumDealManagementRedis`
   - To: `continuumDealManagementWorker` (`resqueWorkers_DeaMan`)
   - Protocol: Redis protocol

7. **Execute job business logic**: Job Services read the deal from MySQL, prepare Salesforce and catalog payloads.
   - From: `resqueWorkers_DeaMan`
   - To: `jobServices_DeaMan` (internal)
   - Protocol: in-process

8. **Sync to Salesforce**: Worker Remote Clients push the deal record to Salesforce.
   - From: `continuumDealManagementWorker` (`workerRemoteClients_DeaMan`)
   - To: `salesForce`
   - Protocol: REST/HTTPS

9. **Update Deal Catalog**: Worker Remote Clients send the catalog entry to Deal Catalog Service.
   - From: `continuumDealManagementWorker` (`workerRemoteClients_DeaMan`)
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Return HTTP 422; job not enqueued | Deal not created |
| MySQL write failure | Return HTTP 500; job not enqueued | Deal not created; transaction rolled back |
| Redis enqueue failure | Return HTTP 500 | Deal persisted but no background job; manual re-queue required |
| Salesforce sync failure (Worker) | Resque retries job up to configured limit | Sync delayed; eventually consistent or lands in Resque failed queue |
| Deal Catalog failure (Worker) | Resque retries job up to configured limit | Catalog update delayed; eventually consistent or lands in failed queue |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST /v2/deals {deal payload}
continuumDealManagementApi -> validationLayer: validate(payload)
validationLayer --> continuumDealManagementApi: valid / errors
continuumDealManagementApi -> continuumDealManagementMysql: INSERT deal record
continuumDealManagementMysql --> continuumDealManagementApi: deal_id
continuumDealManagementApi -> continuumDealManagementRedis: LPUSH deal_created_async job
continuumDealManagementRedis --> continuumDealManagementApi: enqueued
continuumDealManagementApi --> Client: 201 Created {deal_id}
continuumDealManagementWorker -> continuumDealManagementRedis: BRPOP (dequeue job)
continuumDealManagementRedis --> continuumDealManagementWorker: job payload
continuumDealManagementWorker -> continuumDealManagementMysql: SELECT deal
continuumDealManagementMysql --> continuumDealManagementWorker: deal record
continuumDealManagementWorker -> salesForce: POST deal CRM record
salesForce --> continuumDealManagementWorker: 200 OK
continuumDealManagementWorker -> continuumDealCatalogService: POST catalog entry
continuumDealCatalogService --> continuumDealManagementWorker: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-dealCreateAsync`
- Related flows: [Deal Create (Sync)](deal-create-sync.md), [Deal Publish Workflow](deal-publish-workflow.md)
