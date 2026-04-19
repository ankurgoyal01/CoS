---
service: "deal-management-api"
title: "Deal Publish Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-publish-workflow"
flow_type: synchronous
trigger: "HTTP POST to /v1/deals/:id/publish"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
  - "continuumDealManagementRedis"
  - "continuumDealManagementWorker"
  - "continuumDealCatalogService"
  - "salesForce"
  - "continuumVoucherInventoryService"
  - "continuumCouponsInventoryService"
  - "continuumGoodsInventoryService"
  - "continuumThirdPartyInventoryService"
  - "continuumCloInventoryService"
architecture_ref: "dynamic-dealPublishWorkflow"
---

# Deal Publish Workflow

## Summary

The deal publish workflow transitions a deal from a draft or paused state to published, making it available to Groupon customers. The API validates eligibility (required fields populated, approval status, inventory availability), updates deal state in MySQL, triggers inventory reservation checks across the relevant inventory services, and propagates the published deal to the Deal Catalog Service and Salesforce — with downstream sync handled asynchronously via the Worker.

## Trigger

- **Type**: api-call
- **Source**: Internal deal setup tooling or operator action
- **Frequency**: On demand (per publish action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Orchestrates publish validation and state transition | `continuumDealManagementApi` |
| Deal Management MySQL | Stores updated deal state | `continuumDealManagementMysql` |
| Deal Management Redis | Receives async propagation jobs | `continuumDealManagementRedis` |
| Deal Management Worker | Processes async Salesforce and catalog updates | `continuumDealManagementWorker` |
| Deal Catalog Service | Receives published deal catalog entry | `continuumDealCatalogService` |
| Salesforce | Receives CRM update for published deal | `salesForce` |
| Voucher Inventory Service | Validates inventory availability for voucher deals | `continuumVoucherInventoryService` |
| Coupons Inventory Service | Validates inventory for coupon deals | `continuumCouponsInventoryService` |
| Goods Inventory Service | Validates inventory for goods deals | `continuumGoodsInventoryService` |
| Third-Party Inventory Service | Validates inventory for third-party deals | `continuumThirdPartyInventoryService` |
| CLO Inventory Service | Validates inventory for CLO deals | `continuumCloInventoryService` |

## Steps

1. **Receive publish request**: API Controllers accept POST `/v1/deals/:id/publish`.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Load deal record**: Repositories read the current deal state from MySQL.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

3. **Validate publish eligibility**: Validators check deal completeness, approval status, and required field presence.
   - From: `validationLayer` (internal)
   - To: in-process
   - Protocol: in-process

4. **Check inventory availability**: Remote Clients call the relevant inventory service(s) based on deal type to confirm stock is available.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: Applicable inventory service (Voucher / Coupons / Goods / ThirdParty / CLO)
   - Protocol: REST/HTTPS

5. **Transition deal state to published**: Repositories update the deal record state to `published` in MySQL.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

6. **Enqueue async downstream sync jobs**: API enqueues Salesforce sync and Deal Catalog update jobs to Redis.
   - From: `continuumDealManagementApi`
   - To: `continuumDealManagementRedis`
   - Protocol: Redis protocol

7. **Return published deal**: API Controllers return HTTP 200 with updated deal payload.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

8. **Process Salesforce sync job (async)**: Worker dequeues and sends published deal data to Salesforce.
   - From: `continuumDealManagementWorker` (`workerRemoteClients_DeaMan`)
   - To: `salesForce`
   - Protocol: REST/HTTPS

9. **Process catalog update job (async)**: Worker dequeues and sends published deal data to Deal Catalog Service.
   - From: `continuumDealManagementWorker` (`workerRemoteClients_DeaMan`)
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not found | Return HTTP 404 | Publish not performed |
| Validation failure (incomplete deal) | Return HTTP 422 with details | Deal remains in current state |
| Inventory service unavailable | Return HTTP 503 | Publish blocked; deal remains unpublished |
| Insufficient inventory | Return HTTP 422 | Publish blocked; inventory must be resolved |
| MySQL state update failure | Return HTTP 500; transaction rolled back | Deal remains in prior state |
| Async Salesforce failure (Worker) | Resque retry | CRM update delayed; eventually consistent |
| Async catalog failure (Worker) | Resque retry | Catalog update delayed; eventually consistent |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST /v1/deals/:id/publish
continuumDealManagementApi -> continuumDealManagementMysql: SELECT deal by id
continuumDealManagementMysql --> continuumDealManagementApi: deal record
continuumDealManagementApi -> validationLayer: validate publish eligibility
validationLayer --> continuumDealManagementApi: valid / errors
continuumDealManagementApi -> InventoryService: GET inventory availability
InventoryService --> continuumDealManagementApi: availability confirmed
continuumDealManagementApi -> continuumDealManagementMysql: UPDATE deal state = published
continuumDealManagementMysql --> continuumDealManagementApi: updated
continuumDealManagementApi -> continuumDealManagementRedis: LPUSH salesforce_sync job
continuumDealManagementApi -> continuumDealManagementRedis: LPUSH catalog_update job
continuumDealManagementApi --> Client: 200 OK {published deal}
continuumDealManagementWorker -> continuumDealManagementRedis: BRPOP jobs
continuumDealManagementWorker -> salesForce: POST deal update
continuumDealManagementWorker -> continuumDealCatalogService: POST catalog entry
```

## Related

- Architecture dynamic view: `dynamic-dealPublishWorkflow`
- Related flows: [Deal Create (Sync)](deal-create-sync.md), [Deal Approval Workflow](deal-approval-workflow.md), [Inventory Product and Pricing Update](inventory-product-pricing-update.md)
