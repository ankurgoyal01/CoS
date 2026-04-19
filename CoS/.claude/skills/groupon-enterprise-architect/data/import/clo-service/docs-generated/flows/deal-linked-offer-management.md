---
service: "clo-service"
title: "Deal-Linked Offer Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-linked-offer-management"
flow_type: event-driven
trigger: "dealDistribution or dealSnapshot event from Message Bus"
participants:
  - "continuumCloServiceWorker"
  - "continuumCloServiceApi"
  - "cloWorkerMessageConsumers"
  - "cloWorkerAsyncJobs"
  - "cloApiPartnerClients"
  - "cloApiEventPublisher"
  - "continuumCloServicePostgres"
  - "messageBus"
  - "continuumDealCatalogService"
  - "continuumCloInventoryService"
  - "continuumThirdPartyInventoryService"
architecture_ref: "components-clo-service-worker"
---

# Deal-Linked Offer Management

## Summary

This flow describes how CLO offer inventory is kept in sync with the Deal Catalog and distributed to card network partners. When deal distribution or snapshot events arrive via Message Bus, CLO Service processes the updates, applies them to its local offer records, and publishes inventory events (`InventoryUnits.Updated.Clo`, `Products.Updated.Clo`, etc.) for downstream consumers. New offer ingestion can also be triggered via the `/api/v1/offers` and `/api/v1/merchant/ingestion` endpoints.

## Trigger

- **Type**: event (Message Bus) or api-call
- **Source**: `dealDistribution` and `dealSnapshot` events from Message Bus; `POST /api/v1/offers` and `POST /api/v1/merchant/ingestion` for direct ingestion
- **Frequency**: Continuous (event-driven); plus periodic deal snapshot cycles

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO Service Worker | Consumes deal events and processes offer updates | `continuumCloServiceWorker` |
| CLO Service API | Handles direct offer ingestion via REST endpoints | `continuumCloServiceApi` |
| Message Consumers | Receives deal distribution and snapshot events | `cloWorkerMessageConsumers` |
| Async Job Processors | Processes offer sync and distribution jobs | `cloWorkerAsyncJobs` |
| Partner Client Adapters | Calls CLO Inventory and Third-Party Inventory services | `cloApiPartnerClients` |
| Event Publisher | Publishes inventory update events | `cloApiEventPublisher` |
| CLO Service PostgreSQL | Stores and updates offer records | `continuumCloServicePostgres` |
| Message Bus | Carries deal events and inventory update events | `messageBus` |
| Deal Catalog Service | Source of deal distribution and snapshot events | `continuumDealCatalogService` |
| CLO Inventory Service | Receives resolved CLO inventory resources | `continuumCloInventoryService` |
| Third-Party Inventory Service | Coordinates third-party inventory sync | `continuumThirdPartyInventoryService` |

## Steps

1. **Receives deal event**: `cloWorkerMessageConsumers` receives a `dealDistribution` or `dealSnapshot` event from Message Bus.
   - From: `messageBus`
   - To: `cloWorkerMessageConsumers`
   - Protocol: Message Bus

2. **Dispatches to async job**: `cloWorkerMessageConsumers` dispatches the event payload to `cloWorkerAsyncJobs` for processing.
   - From: `cloWorkerMessageConsumers`
   - To: `cloWorkerAsyncJobs`
   - Protocol: Direct (Sidekiq job dispatch)

3. **Reads current offer state**: `cloWorkerAsyncJobs` reads the relevant offer records from `continuumCloServicePostgres` to determine what changes are needed.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

4. **Validates deals with Deal Catalog**: For distribution events, `cloApiPartnerClients` calls `continuumDealCatalogService` to validate deal status and attributes.
   - From: `cloApiPartnerClients`
   - To: `continuumDealCatalogService`
   - Protocol: REST

5. **Resolves CLO inventory resources**: `cloApiPartnerClients` calls `continuumCloInventoryService` to resolve or update CLO inventory unit state.
   - From: `cloApiPartnerClients`
   - To: `continuumCloInventoryService`
   - Protocol: REST

6. **Coordinates third-party inventory sync**: If applicable, `cloApiPartnerClients` calls `continuumThirdPartyInventoryService` to sync third-party offer data.
   - From: `cloApiPartnerClients`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: REST

7. **Persists offer updates**: `cloWorkerAsyncJobs` writes updated offer records to `continuumCloServicePostgres`.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

8. **Publishes inventory events**: `cloApiEventPublisher` publishes `InventoryUnits.Updated.Clo`, `InventoryUnits.Created.Clo`, `Products.Updated.Clo`, or `Products.Created.Clo` events to Message Bus as appropriate.
   - From: `cloApiEventPublisher`
   - To: `messageBus`
   - Protocol: Message Bus

### Alternative: Direct Offer Ingestion via API

1. **Receives ingestion request**: `cloApiControllers` receives `POST /api/v1/offers` or `POST /api/v1/merchant/ingestion` with offer/merchant data.
   - From: Internal caller or merchant integration
   - To: `cloApiControllers`
   - Protocol: REST

2. **Resolves merchant**: `cloApiPartnerClients` calls `continuumM3MerchantService` to resolve the merchant record.
   - From: `cloApiPartnerClients`
   - To: `continuumM3MerchantService`
   - Protocol: REST

3. **Persists offer**: `cloApiClaimDomain` writes the offer to `continuumCloServicePostgres` and publishes inventory events (same as steps 7-8 above).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog validation failure | Job retried with backoff | Offer update delayed; alert on repeated failures |
| CLO Inventory Service unavailable | Job retried; offer state not updated | Inventory sync delayed; auto-recovers on retry |
| Message Bus publish failure after DB write | Async retry or worker reconciliation | Events eventually delivered; possible duplicate events |
| Duplicate deal event | Idempotent offer upsert in database | No duplicate offer records created |

## Sequence Diagram

```
messageBus -> cloWorkerMessageConsumers: dealDistribution event
cloWorkerMessageConsumers -> cloWorkerAsyncJobs: dispatch offer sync job
cloWorkerAsyncJobs -> continuumCloServicePostgres: read current offer records
cloApiPartnerClients -> continuumDealCatalogService: validate deal status
continuumDealCatalogService --> cloApiPartnerClients: deal valid
cloApiPartnerClients -> continuumCloInventoryService: resolve inventory resources
continuumCloInventoryService --> cloApiPartnerClients: inventory resolved
cloWorkerAsyncJobs -> continuumCloServicePostgres: persist offer updates
cloApiEventPublisher -> messageBus: publish InventoryUnits.Updated.Clo
cloApiEventPublisher -> messageBus: publish Products.Updated.Clo
```

## Related

- Architecture dynamic view: `components-clo-service-worker`
- Related flows: [Card Enrollment and CLO Activation](card-enrollment-clo-activation.md), [Claim Processing and Statement Credit](claim-processing-statement-credit.md)
