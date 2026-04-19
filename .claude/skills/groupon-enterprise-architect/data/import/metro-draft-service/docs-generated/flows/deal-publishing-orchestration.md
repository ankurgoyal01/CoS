---
service: "metro-draft-service"
title: "Deal Publishing Orchestration"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-publishing-orchestration"
flow_type: synchronous
trigger: "HTTP POST /api/deals/{id}/publish — caller requests a draft deal be published"
participants:
  - "continuumMetroDraftService_publishResource"
  - "continuumMetroDraftService_dealOrchestrationService"
  - "continuumMetroDraftService_dealStatusService"
  - "continuumMetroDraftService_dealService"
  - "continuumMetroDraftService_dmapiClient"
  - "continuumMetroDraftService_marketingDealClient"
  - "continuumMetroDraftService_dealCatalogClient"
  - "continuumMetroDraftService_inventoryClients"
  - "continuumMetroDraftService_partnerServicesClient"
  - "continuumMetroDraftService_placeServicesClient"
  - "continuumMetroDraftService_historyEventService"
  - "continuumMetroDraftService_signedDealProducer"
  - "continuumMetroDraftMessageBus"
  - "continuumDealManagementService"
  - "continuumMarketingDealService"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "continuumRedemptionCodePoolService"
  - "continuumPartnerService"
architecture_ref: "dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation"
---

# Deal Publishing Orchestration

## Summary

When a validated draft deal is ready to go live, the publish flow coordinates a multi-step orchestration across DMAPI (Deal Management Service), Marketing Deal Service (MDS), Deal Catalog, and inventory services. The Deal Orchestration Service acts as the central coordinator, sequentially syncing the deal to each downstream system, reserving voucher and code inventory, updating place data, and notifying partner services. A signed deal event is emitted to MBus on successful completion to trigger further downstream workflows.

## Trigger

- **Type**: api-call
- **Source**: Metro internal tooling or merchant self-service portal calling `POST /api/deals/{id}/publish`
- **Frequency**: On demand — when a deal passes eligibility checks and is ready to go live

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Publish Resource | Receives publish request; triggers orchestration | `continuumMetroDraftService_publishResource` |
| Deal Orchestration Service | Central coordinator for all publish steps | `continuumMetroDraftService_dealOrchestrationService` |
| Deal Status Service | Updates deal status to publishing/live states | `continuumMetroDraftService_dealStatusService` |
| Deal Service | Provides deal data to orchestration steps | `continuumMetroDraftService_dealService` |
| Deal Management Client | Propagates deal to DMAPI pipeline | `continuumMetroDraftService_dmapiClient` |
| Marketing Deal Client | Syncs deal to Marketing Deal Service (MDS) | `continuumMetroDraftService_marketingDealClient` |
| Deal Catalog Client | Publishes deal to Deal Catalog | `continuumMetroDraftService_dealCatalogClient` |
| Inventory Clients | Reserves voucher inventory and code pools | `continuumMetroDraftService_inventoryClients` |
| Partner Services Client | Notifies Partner Service and ePODS | `continuumMetroDraftService_partnerServicesClient` |
| Place Services Client | Updates place data in place write service | `continuumMetroDraftService_placeServicesClient` |
| History Event Service | Records publish audit event; delegates to Signed Deal Producer | `continuumMetroDraftService_historyEventService` |
| Signed Deal Producer | Emits signed-deal event to MBus | `continuumMetroDraftService_signedDealProducer` |
| Metro Draft Message Bus | Receives signed-deal event | `continuumMetroDraftMessageBus` |
| Deal Management Service (DMAPI) | Receives and registers deal in the pipeline | `continuumDealManagementService` |
| Marketing Deal Service (MDS) | Receives merchandising deal sync | `continuumMarketingDealService` |
| Deal Catalog Service | Receives and catalogs the published deal | `continuumDealCatalogService` |
| Voucher Inventory Service (VIS) | Reserves voucher inventory for the deal | `continuumVoucherInventoryService` |
| Redemption Code Pool Service | Allocates redemption code pools | `continuumRedemptionCodePoolService` |
| Partner Service | Receives partner onboarding/workflow notification | `continuumPartnerService` |

## Steps

1. **Receive publish request**: Publish Resource receives `POST /api/deals/{id}/publish`.
   - From: Caller (Metro tooling / self-service portal)
   - To: `continuumMetroDraftService_publishResource`
   - Protocol: REST HTTP

2. **Validate publish eligibility**: Publish Resource calls Deal Status Service to confirm the deal is in a publishable state.
   - From: `continuumMetroDraftService_publishResource`
   - To: `continuumMetroDraftService_dealStatusService`
   - Protocol: Internal call

3. **Begin orchestration**: Publish Resource delegates to Deal Orchestration Service.
   - From: `continuumMetroDraftService_publishResource`
   - To: `continuumMetroDraftService_dealOrchestrationService`
   - Protocol: Internal call

4. **Load deal data**: Deal Orchestration Service reads current deal state via Deal Service.
   - From: `continuumMetroDraftService_dealOrchestrationService`
   - To: `continuumMetroDraftService_dealService`
   - Protocol: Internal call

5. **Sync deal to DMAPI**: Deal Orchestration Service calls DMAPI via Deal Management Client to register and propagate the deal in the pipeline.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_dmapiClient`
   - To: `continuumDealManagementService`
   - Protocol: HTTP/Retrofit

6. **Sync merchandising deal to MDS**: Deal Orchestration Service calls Marketing Deal Client to sync the merchandising view.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_marketingDealClient`
   - To: `continuumMarketingDealService`
   - Protocol: HTTP/Retrofit

7. **Publish to Deal Catalog**: Deal Orchestration Service calls Deal Catalog Client to publish the deal for consumer visibility.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_dealCatalogClient`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/Retrofit

8. **Reserve voucher inventory and code pools**: Deal Orchestration Service calls Inventory Clients to reserve the required voucher inventory and allocate redemption code pools.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_inventoryClients`
   - To: `continuumVoucherInventoryService`, `continuumRedemptionCodePoolService`
   - Protocol: HTTP/Retrofit

9. **Update place data**: Deal Orchestration Service calls Place Services Client to write updated merchant place information.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_placeServicesClient`
   - To: `continuumPlaceWriteService`
   - Protocol: HTTP/Retrofit

10. **Notify partner services**: Deal Orchestration Service calls Partner Services Client to trigger partner onboarding/workflow notifications.
    - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_partnerServicesClient`
    - To: `continuumPartnerService`
    - Protocol: HTTP/Retrofit

11. **Update deal status to live**: Deal Status Service persists the final published/live status.
    - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_dealStatusService`
    - To: `continuumMetroDraftService_dealStatusDao` -> `continuumMetroDraftDb`
    - Protocol: JDBI

12. **Record audit and emit signed deal event**: History Event Service records the publish audit event and delegates to Signed Deal Producer.
    - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_historyEventService`
    - To: `continuumMetroDraftService_signedDealProducer` -> `continuumMetroDraftMessageBus`
    - Protocol: MBus

13. **Return publish result**: Publish Resource returns success response to the caller.
    - From: `continuumMetroDraftService_publishResource`
    - To: Caller
    - Protocol: REST HTTP 200 OK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not in publishable state | Deal Status Service rejects; 400 returned | Publish rejected; deal remains in draft |
| DMAPI call failure | Orchestration Service logs error; deal status set to publish-failed | Deal not registered in pipeline; Stuck Deal Retry Job will retry |
| MDS sync failure | Logged; orchestration may continue or halt depending on criticality | Merchandising deal may be out of sync; requires manual retry |
| Inventory reservation failure | Orchestration halts; deal status updated to indicate inventory issue | Deal not published; merchant must resolve inventory before re-publishing |
| Deal Catalog publish failure | Logged; deal not visible to consumers | Deal not consumer-visible; retry required |
| Signed deal MBus publish failure | History Event Service logs error; deal status already updated to live | Deal published but signed-deal event lost; downstream workflows not triggered |

## Sequence Diagram

```
Caller -> PublishResource: POST /api/deals/{id}/publish
PublishResource -> DealStatusService: validatePublishEligibility(dealId)
DealStatusService --> PublishResource: eligible
PublishResource -> DealOrchestrationService: orchestratePublish(dealId)
DealOrchestrationService -> DealService: loadDeal(dealId)
DealService --> DealOrchestrationService: deal data
DealOrchestrationService -> DmapiClient: syncToDMAPI(deal)
DmapiClient -> DealManagementService: create/update deal
DealManagementService --> DmapiClient: ok
DealOrchestrationService -> MarketingDealClient: syncToMDS(deal)
MarketingDealClient -> MarketingDealService: merchandising sync
MarketingDealService --> MarketingDealClient: ok
DealOrchestrationService -> DealCatalogClient: publishToCatalog(deal)
DealCatalogClient -> DealCatalogService: publish
DealCatalogService --> DealCatalogClient: ok
DealOrchestrationService -> InventoryClients: reserveInventory(deal)
InventoryClients -> VoucherInventoryService: reserve vouchers
InventoryClients -> RedemptionCodePoolService: allocate code pools
DealOrchestrationService -> PlaceServicesClient: updatePlaceData(deal)
DealOrchestrationService -> PartnerServicesClient: notifyPartner(deal)
DealOrchestrationService -> DealStatusService: setStatusLive(dealId)
DealStatusService -> DealStatusDao: persist
DealOrchestrationService -> HistoryEventService: recordPublishAudit()
HistoryEventService -> SignedDealProducer: emitSignedDealEvent()
SignedDealProducer -> MetroDraftMessageBus: signed-deal event
DealOrchestrationService --> PublishResource: published
PublishResource --> Caller: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation`
- Related flows: [Merchant Deal Draft Creation](merchant-deal-draft-creation.md), [Signed Deal Event Consumption](signed-deal-event-consumption.md)
