---
service: "metro-draft-service"
title: "Signed Deal Event Consumption"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "signed-deal-event-consumption"
flow_type: event-driven
trigger: "MBus event — signed-deal-event published to continuumMetroDraftMessageBus"
participants:
  - "continuumMetroDraftService_signedDealListener"
  - "continuumMetroDraftService_dealOrchestrationService"
  - "continuumMetroDraftService_dealService"
  - "continuumMetroDraftService_dmapiClient"
  - "continuumMetroDraftService_marketingDealClient"
  - "continuumMetroDraftService_dealCatalogClient"
  - "continuumMetroDraftService_inventoryClients"
  - "continuumMetroDraftService_partnerServicesClient"
  - "continuumMetroDraftService_placeServicesClient"
  - "continuumMetroDraftMessageBus"
  - "continuumDealManagementService"
  - "continuumMarketingDealService"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "continuumRedemptionCodePoolService"
architecture_ref: "components-continuum-metro-draft-service"
---

# Signed Deal Event Consumption

## Summary

When a deal is signed — either by the internal publish flow or an external process — a `signed-deal-event` is published to `continuumMetroDraftMessageBus`. The Signed Deal Listener in Metro Draft Service consumes this event and triggers the Deal Orchestration Service to execute the downstream workflow: syncing deal data to DMAPI, MDS, Deal Catalog, reserving inventory, and notifying partners. This event-driven path enables asynchronous deal finalization without requiring a synchronous API call to complete the full publish chain.

## Trigger

- **Type**: event
- **Source**: `signed-deal-event` message on `continuumMetroDraftMessageBus`; produced by the Signed Deal Producer (emitted during deal signing within Metro Draft Service or by an external publisher)
- **Frequency**: Per signed deal — triggered whenever a deal transitions to signed state

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Metro Draft Message Bus | Carries the signed-deal-event to the listener | `continuumMetroDraftMessageBus` |
| Signed Deal Listener | Consumes signed-deal-event from MBus; triggers orchestration | `continuumMetroDraftService_signedDealListener` |
| Deal Orchestration Service | Coordinates the downstream workflow triggered by the signed deal | `continuumMetroDraftService_dealOrchestrationService` |
| Deal Service | Loads deal data needed for orchestration steps | `continuumMetroDraftService_dealService` |
| Deal Management Client | Syncs signed deal to DMAPI | `continuumMetroDraftService_dmapiClient` |
| Marketing Deal Client | Syncs merchandising deal to MDS | `continuumMetroDraftService_marketingDealClient` |
| Deal Catalog Client | Publishes signed deal to Deal Catalog | `continuumMetroDraftService_dealCatalogClient` |
| Inventory Clients | Reserves voucher inventory and code pools | `continuumMetroDraftService_inventoryClients` |
| Partner Services Client | Notifies Partner Service of signed deal | `continuumMetroDraftService_partnerServicesClient` |
| Place Services Client | Updates place data for the signed deal | `continuumMetroDraftService_placeServicesClient` |
| Deal Management Service (DMAPI) | Receives signed deal for pipeline registration | `continuumDealManagementService` |
| Marketing Deal Service (MDS) | Receives merchandising sync for signed deal | `continuumMarketingDealService` |
| Deal Catalog Service | Receives signed deal for consumer catalog | `continuumDealCatalogService` |
| Voucher Inventory Service (VIS) | Reserves vouchers for the signed deal | `continuumVoucherInventoryService` |
| Redemption Code Pool Service | Allocates redemption code pools | `continuumRedemptionCodePoolService` |

## Steps

1. **Receive signed-deal-event**: Signed Deal Listener consumes `signed-deal-event` message from `continuumMetroDraftMessageBus`.
   - From: `continuumMetroDraftMessageBus`
   - To: `continuumMetroDraftService_signedDealListener`
   - Protocol: MBus

2. **Extract deal identifier**: Signed Deal Listener extracts the deal ID and metadata from the event payload.
   - From: `continuumMetroDraftService_signedDealListener` (internal)
   - To: (internal processing)
   - Protocol: Internal

3. **Trigger downstream workflow**: Signed Deal Listener calls Deal Orchestration Service to begin the signed deal workflow.
   - From: `continuumMetroDraftService_signedDealListener`
   - To: `continuumMetroDraftService_dealOrchestrationService`
   - Protocol: Internal call

4. **Load deal data**: Deal Orchestration Service reads current deal state via Deal Service.
   - From: `continuumMetroDraftService_dealOrchestrationService`
   - To: `continuumMetroDraftService_dealService`
   - Protocol: Internal call

5. **Sync to DMAPI**: Deal Orchestration Service calls Deal Management Client to propagate the signed deal.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_dmapiClient`
   - To: `continuumDealManagementService`
   - Protocol: HTTP/Retrofit

6. **Sync to Marketing Deal Service**: Deal Orchestration Service calls Marketing Deal Client to update the merchandising view.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_marketingDealClient`
   - To: `continuumMarketingDealService`
   - Protocol: HTTP/Retrofit

7. **Publish to Deal Catalog**: Deal Orchestration Service calls Deal Catalog Client.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_dealCatalogClient`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/Retrofit

8. **Reserve inventory**: Deal Orchestration Service calls Inventory Clients to reserve vouchers and code pools.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_inventoryClients`
   - To: `continuumVoucherInventoryService`, `continuumRedemptionCodePoolService`
   - Protocol: HTTP/Retrofit

9. **Update place data**: Deal Orchestration Service calls Place Services Client.
   - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_placeServicesClient`
   - To: `continuumPlaceWriteService`
   - Protocol: HTTP/Retrofit

10. **Notify partner services**: Deal Orchestration Service calls Partner Services Client.
    - From: `continuumMetroDraftService_dealOrchestrationService` -> `continuumMetroDraftService_partnerServicesClient`
    - To: `continuumPartnerService`
    - Protocol: HTTP/Retrofit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus consumer disconnection | MBus reconnects on listener restart; events redelivered | Events processed after reconnection; at-least-once delivery |
| DMAPI sync failure | Deal Orchestration Service logs error; deal workflow stalls | Deal not registered in pipeline; Stuck Deal Retry Job will retry the orchestration |
| Inventory reservation failure | Orchestration halts at inventory step | Deal partially processed; requires investigation and retry |
| Deal Catalog publish failure | Logged; orchestration may continue | Deal not consumer-visible; retry required |
| Duplicate event delivery | No explicit idempotency guard evidenced; duplicate processing possible | Confirm idempotency handling with Metro Team |

## Sequence Diagram

```
MetroDraftMessageBus -> SignedDealListener: signed-deal-event (dealId, metadata)
SignedDealListener -> DealOrchestrationService: triggerWorkflow(dealId)
DealOrchestrationService -> DealService: loadDeal(dealId)
DealService --> DealOrchestrationService: deal data
DealOrchestrationService -> DmapiClient: syncToDMAPI(deal)
DmapiClient -> DealManagementService: create/update
DealManagementService --> DmapiClient: ok
DealOrchestrationService -> MarketingDealClient: syncToMDS(deal)
MarketingDealClient -> MarketingDealService: sync
DealOrchestrationService -> DealCatalogClient: publishToCatalog(deal)
DealCatalogClient -> DealCatalogService: publish
DealOrchestrationService -> InventoryClients: reserveInventory(deal)
InventoryClients -> VoucherInventoryService: reserve
InventoryClients -> RedemptionCodePoolService: allocate
DealOrchestrationService -> PlaceServicesClient: updatePlace(deal)
DealOrchestrationService -> PartnerServicesClient: notifyPartner(deal)
```

## Related

- Architecture dynamic view: `components-continuum-metro-draft-service`
- Related flows: [Deal Publishing Orchestration](deal-publishing-orchestration.md), [Merchant Deal Draft Creation](merchant-deal-draft-creation.md)
