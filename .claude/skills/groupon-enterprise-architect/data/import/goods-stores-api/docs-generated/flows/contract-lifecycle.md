---
service: "goods-stores-api"
title: "Contract Lifecycle"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "contract-lifecycle"
flow_type: asynchronous
trigger: "API request (POST/PUT /v2/contracts) or scheduled Resque job"
participants:
  - "continuumGoodsStoresApi"
  - "continuumGoodsStoresApi_v2Api"
  - "continuumGoodsStoresApi_auth"
  - "continuumGoodsStoresDb"
  - "continuumGoodsStoresRedis"
  - "continuumGoodsStoresWorkers"
  - "continuumGoodsStoresWorkers_contracts"
  - "continuumGoodsStoresWorkers_publishers"
  - "continuumDealManagementApi"
  - "continuumGoodsInventoryService"
architecture_ref: "dynamic-goods-stores-contract-lifecycle"
---

# Contract Lifecycle

## Summary

This flow covers the creation, activation, and termination of merchant-Groupon contracts governing deal terms. A contract is created or updated via the v2 API, persisted to MySQL, and a Resque job is dispatched to the Contract Lifecycle Worker. The worker manages region-aware start and end transitions, coordinates with Deal Management API to publish or unpublish deals, and notifies the Goods Inventory service of availability changes.

## Trigger

- **Type**: api-call or schedule
- **Source**: Merchant tooling via `POST /v2/contracts` (create) or `PUT /v2/contracts/:id` (update); alternatively, scheduled Resque jobs execute contract start/end transitions at the configured dates
- **Frequency**: On-demand for create/update; scheduled for start/end transitions (daily or per-contract schedule)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| V2 Goods Stores API | Receives contract create/update requests | `continuumGoodsStoresApi_v2Api` |
| Authorization & Token Helper | Validates token and role | `continuumGoodsStoresApi_auth` |
| Goods Stores MySQL | Stores contract records and audit history | `continuumGoodsStoresDb` |
| Goods Stores Redis | Receives Resque job enqueue; manages scheduling state | `continuumGoodsStoresRedis` |
| Contract Lifecycle Worker | Executes start/end transitions with region-aware scheduling | `continuumGoodsStoresWorkers_contracts` |
| Event Publishers | Publishes deal state change events | `continuumGoodsStoresWorkers_publishers` |
| Deal Management API | Receives deal publish/unpublish instructions | `continuumDealManagementApi` |
| Goods Inventory Service | Receives availability state updates on contract changes | `continuumGoodsInventoryService` |

## Steps

1. **Receive Contract Request**: Client sends `POST /v2/contracts` or `PUT /v2/contracts/:id`.
   - From: `GPAPI client / merchant tooling`
   - To: `continuumGoodsStoresApi_v2Api`
   - Protocol: REST/HTTP

2. **Validate Authorization**: Token and role checked.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresApi_auth`
   - Protocol: direct (in-process)

3. **Persist Contract**: Contract record written to MySQL with status, start_date, end_date, region, and merchant/product references. Paper Trail records audit entry.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

4. **Enqueue Lifecycle Job**: API enqueues a contract lifecycle Resque job referencing the contract ID.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresRedis`
   - Protocol: Resque over Redis

5. **Return API Response**: API returns 201 Created or 200 OK with contract representation.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `GPAPI client`
   - Protocol: REST/HTTP

6. **Execute Contract Transition**: Contract Lifecycle Worker dequeues job; evaluates start_date/end_date relative to current time and region; updates contract status in MySQL.
   - From: `continuumGoodsStoresWorkers_contracts`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

7. **Coordinate with Deal Management**: Worker calls Deal Management API to publish (on contract start) or unpublish (on contract end) associated deals.
   - From: `continuumGoodsStoresWorkers`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/JSON

8. **Update Inventory Availability**: Worker notifies Goods Inventory service of availability state change tied to the contract transition.
   - From: `continuumGoodsStoresWorkers`
   - To: `continuumGoodsInventoryService`
   - Protocol: HTTP/JSON

9. **Publish Deal Events**: Event Publishers emit `deals/updated` and `inventory/updated` events to downstream consumers.
   - From: `continuumGoodsStoresWorkers_publishers`
   - To: downstream event consumers
   - Protocol: MessageBus/JMS

10. **Schedule Future Transitions**: For contracts with future start/end dates, the worker schedules a Resque job to fire at the appropriate time via Redis-backed scheduling.
    - From: `continuumGoodsStoresWorkers_contracts`
    - To: `continuumGoodsStoresRedis`
    - Protocol: Resque over Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authorization failure | Request rejected by `continuumGoodsStoresApi_auth` | HTTP 401/403; no contract written |
| Contract validation failure | Grape validation returns 422 with errors | HTTP 422; no contract written |
| MySQL write failure | Exception propagates | HTTP 500; contract not persisted |
| Deal Management API failure | Worker retries via Resque | Deal not published/unpublished until retry succeeds |
| Goods Inventory update failure | Worker retries via Resque | Inventory state may be stale until retry |
| Scheduled job missed | Resque schedule re-evaluates on next run | Contract transition delayed; not lost |

## Sequence Diagram

```
Merchant Tooling -> continuumGoodsStoresApi_v2Api: POST/PUT /v2/contracts
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_auth: Validate token and role
continuumGoodsStoresApi_auth --> continuumGoodsStoresApi_v2Api: Authorized
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresDb: Persist contract record
continuumGoodsStoresDb --> continuumGoodsStoresApi_v2Api: Contract saved
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresRedis: Enqueue lifecycle Resque job
continuumGoodsStoresApi_v2Api --> Merchant Tooling: 201/200 contract response
continuumGoodsStoresWorkers_contracts -> continuumGoodsStoresDb: Update contract status
continuumGoodsStoresWorkers -> continuumDealManagementApi: Publish or unpublish deal
continuumGoodsStoresWorkers -> continuumGoodsInventoryService: Update availability state
continuumGoodsStoresWorkers_publishers -> messageBus: Emit deals/updated, inventory/updated
continuumGoodsStoresWorkers_contracts -> continuumGoodsStoresRedis: Schedule future transitions
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-contract-lifecycle`
- Related flows: [Product Create/Update & Sync](product-create-update-sync.md), [Batch Import/Sync](batch-import-sync.md)
