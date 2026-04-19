---
service: "breakage-reduction-service"
title: "Voucher Context Preload"
generated: "2026-03-03"
type: flow
flow_name: "voucher-context-preload"
flow_type: synchronous
trigger: "Internal — invoked by Voucher Next-Actions and Reminder Scheduling flows via Storage Facade"
participants:
  - "continuumBreakageReductionService"
  - "continuumVoucherInventoryApi"
  - "continuumThirdPartyInventoryService"
  - "continuumDealCatalogService"
  - "continuumOrdersService"
  - "continuumUsersService"
  - "continuumM3MerchantService"
  - "continuumPlaceReadService"
  - "continuumUgcService"
  - "continuumEpodsService"
  - "continuumAudienceManagementService"
architecture_ref: "components-continuum-breakage-reduction-service-components"
---

# Voucher Context Preload

## Summary

The voucher context preload is an internal sub-flow executed by the Storage Facade (`common/Storage.js`) to assemble all data required for workflow evaluation before the Notification Workflow Engine runs. It orchestrates a sequenced and partially parallel series of downstream service calls — fetching the voucher unit, inventory product, deal, order summary, customer authority attributes, user details, order, merchant, redemption locations, booking reservations, trade-in exchange amount, and gift details history. This flow is not externally triggered but is invoked as part of every Next-Actions and Reminder scheduling flow.

## Trigger

- **Type**: internal
- **Source**: Voucher Next Actions Handler or Remind-Me-Later Handler calling `storageFacade.preload()`
- **Frequency**: Once per inbound request to `/voucher/v1/next_actions` or remind-me-later endpoints

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Storage Facade | Orchestrates all data fetches and maintains assembled context | `storageFacade` |
| Voucher Inventory Service (VIS) | Provides voucher units, inventory products, product availability, gift details history | `continuumVoucherInventoryApi` |
| Third-Party Inventory Service (TPIS) | Alternative source for third-party voucher units and products | `continuumThirdPartyInventoryService` |
| Deal Catalog | Resolves deal ID from inventory product; loads deal options | `continuumDealCatalogService` |
| Orders | Provides order details, order summary, refund amount | `continuumOrdersService` |
| Users Service | Provides user account details | `continuumUsersService` |
| Merchant (M3) | Provides merchant profile | `continuumM3MerchantService` |
| Place Read (M3) | Provides redemption location data | `continuumPlaceReadService` |
| UGC | Provides user review ratings | `continuumUgcService` |
| EPODS | Provides booking segment resources | `continuumEpodsService` |
| AMS | Provides customer authority attributes | `continuumAudienceManagementService` |

## Steps

1. **Load voucher unit**: Storage Facade calls VIS or TPIS (determined by `inventoryService` parameter) to fetch the voucher unit by UUID or groupon code. Extracts `inventoryProductId`, `userId`, and redemption policy.
   - From: `storageFacade`
   - To: `continuumVoucherInventoryApi` or `continuumThirdPartyInventoryService`
   - Protocol: HTTPS/JSON (`GET /inventory/v1/units`)

2. **Load booking information** (conditional): If the voucher has active bookings and an `externalId` is set, fetches booking segment resources from EPODS.
   - From: `storageFacade`
   - To: `continuumEpodsService`
   - Protocol: HTTPS/JSON

3. **Load inventory product**: Fetches the inventory product record for the voucher's `inventoryProductId`.
   - From: `storageFacade`
   - To: `continuumVoucherInventoryApi` or `continuumThirdPartyInventoryService`
   - Protocol: HTTPS/JSON (`GET /inventory/v1/products`)

4. **Resolve deal**: Calls Deal Catalog search API with `inventoryProductId` to get the deal ID, then loads full deal details and option metadata.
   - From: `storageFacade`
   - To: `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

5. **Load order summary**: Fetches order summary for the voucher's consumer (total orders, resigned, non-paid) to determine first-time purchaser status.
   - From: `storageFacade`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

6. **Load customer authority attributes** (feature-flag gated): Fetches AMS attributes for the consumer if `customer_authority_attributes` flag is enabled.
   - From: `storageFacade`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

7. **Populate deal option data**: Storage Facade computes and stores deal option metadata (price, value, title, redemption location IDs) from the loaded deal and inventory product.

8. **Parallel entity load**: Concurrently loads user account (Users Service), order details (Orders), merchant profile (M3 Merchant), gift details history (VIS), and — conditionally — booking reservations (US online booking deals), redemption locations (Place Read), and trade-in exchange amount (Orders refund API).
   - From: `storageFacade`
   - To: multiple services concurrently
   - Protocol: HTTPS/JSON per service

9. **Return populated Storage context**: Storage Facade instance with all loaded entities is returned to the calling handler for workflow evaluation.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Voucher not found (VIS/TPIS) | `notFoundError` thrown | Request fails with 404 |
| No `recipientConsumerId` or `purchaserConsumerId` on voucher | `notFoundError` thrown | Request fails with 404 |
| Deal not found | `notFoundError` thrown | Request fails with 404 |
| Order summary failure | Defaults to `{totalOrders:0, totalResigned:0, nonPaidOrders:0}` | Flow continues |
| AMS failure | Defaults to `{}` | Flow continues without authority attributes |
| EPODS segment resource failure | Falls back to title-based placeholder resources | Booking context uses placeholder |
| Redemption location load failure | Error propagated | Request fails |
| Gift details history failure | Falls back to `voucher.giftDetails` | Flow continues with voucher-level gift data |
| Trade-in exchange amount failure | `notFoundError` thrown | Request fails if trade-in is required |

## Sequence Diagram

```
voucherNextActionsHandler -> storageFacade: preload()
storageFacade -> continuumVoucherInventoryApi: unitsShow(voucherId)
continuumVoucherInventoryApi --> storageFacade: voucher unit
storageFacade -> continuumEpodsService: getSegmentResources (if booking)
storageFacade -> continuumVoucherInventoryApi: productsShow(inventoryProductId)
storageFacade -> continuumDealCatalogService: search + loadDeal
storageFacade -> continuumOrdersService: getOrderSummary
storageFacade -> continuumAudienceManagementService: getCAAttributes
storageFacade -> continuumUsersService: loadUserDetails [parallel]
storageFacade -> continuumOrdersService: getOrderInventoryUnit [parallel]
storageFacade -> continuumM3MerchantService: getMerchant [parallel]
storageFacade -> continuumVoucherInventoryApi: giftDetailsHistory [parallel]
storageFacade -> continuumPlaceReadService: getPlaces [parallel, if locations]
storageFacade --> voucherNextActionsHandler: fully populated context
```

## Related

- Related flows: [Voucher Next-Actions Computation](voucher-next-actions.md), [Reminder Scheduling](reminder-scheduling.md)
