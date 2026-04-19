---
service: "breakage-reduction-service"
title: "Voucher Next-Actions Computation"
generated: "2026-03-03"
type: flow
flow_name: "voucher-next-actions"
flow_type: synchronous
trigger: "POST /voucher/v1/next_actions"
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
  - "continuumBreakageReductionRedis"
architecture_ref: "components-continuum-breakage-reduction-service-components"
---

# Voucher Next-Actions Computation

## Summary

The voucher next-actions flow is the core function of BRS. When a client POSTs to `/voucher/v1/next_actions` with voucher and user context, BRS orchestrates a parallel set of downstream service calls to assemble a complete voucher context, then runs the Notification Workflow Engine to evaluate which breakage reduction actions (notifications, extensions, trade-ins, reminders, modals, etc.) are eligible for that voucher. The response is a prioritized list of next-actions that the caller uses to drive post-purchase engagement.

## Trigger

- **Type**: api-call
- **Source**: Consumer-facing web/mobile clients or internal post-purchase pipeline via Hybrid Boundary
- **Frequency**: On demand, per-request (typically triggered on post-purchase page load or notification delivery)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BRS API Routes | Receives POST request, routes to Voucher Next Actions Handler | `brsApiRoutes` |
| Voucher Next Actions Handler | Orchestrates context loading and workflow evaluation | `voucherNextActionsHandler` |
| Storage Facade | Coordinates all downstream data fetches | `storageFacade` |
| Notification Workflow Engine | Evaluates eligibility rules and computes action list | `workflowEngine` |
| Service Client Adapters | Executes HTTP calls to each downstream service | `serviceClientAdapters` |
| Voucher Inventory Service (VIS) | Provides voucher unit data and inventory product metadata | `continuumVoucherInventoryApi` |
| Third-Party Inventory Service (TPIS) | Provides third-party voucher unit data (alternate inventory) | `continuumThirdPartyInventoryService` |
| Deal Catalog | Resolves deal ID and deal option details | `continuumDealCatalogService` |
| Orders | Provides order details, order summary, and refund/exchange amount | `continuumOrdersService` |
| Users Service | Provides user account details | `continuumUsersService` |
| Merchant (M3) | Provides merchant profile data | `continuumM3MerchantService` |
| Place Read (M3) | Provides redemption location data | `continuumPlaceReadService` |
| UGC | Provides user review ratings | `continuumUgcService` |
| EPODS | Provides booking segment resources for booking deals | `continuumEpodsService` |
| AMS | Provides customer authority attributes | `continuumAudienceManagementService` |
| Redis | Provides cached workflow helper state | `continuumBreakageReductionRedis` |

## Steps

1. **Receive request**: BRS API Routes receives `POST /voucher/v1/next_actions` with voucher ID, inventory service, user ID, country, brand, and existing actions in the JSON body.
   - From: `consumer client`
   - To: `brsApiRoutes`
   - Protocol: HTTPS/JSON

2. **Route to handler**: BRS API Routes passes the request to the Voucher Next Actions Handler.
   - From: `brsApiRoutes`
   - To: `voucherNextActionsHandler`
   - Protocol: direct

3. **Initialize Storage Facade**: The handler initializes the Storage Facade with voucher UUID, inventory service, user ID, country, and existing actions.
   - From: `voucherNextActionsHandler`
   - To: `storageFacade`
   - Protocol: direct

4. **Preload voucher**: Storage Facade fetches the voucher unit from VIS or TPIS (depending on `inventoryService`).
   - From: `storageFacade`
   - To: `continuumVoucherInventoryApi` or `continuumThirdPartyInventoryService`
   - Protocol: HTTPS/JSON (`GET /inventory/v1/units`)

5. **Load booking information**: If the voucher has bookings, Storage Facade fetches booking segment resources from EPODS.
   - From: `storageFacade`
   - To: `continuumEpodsService`
   - Protocol: HTTPS/JSON

6. **Load inventory product**: Storage Facade fetches inventory product details from VIS or TPIS.
   - From: `storageFacade`
   - To: `continuumVoucherInventoryApi` or `continuumThirdPartyInventoryService`
   - Protocol: HTTPS/JSON (`GET /inventory/v1/products`)

7. **Resolve deal**: Storage Facade searches Deal Catalog by inventory product ID to get the deal ID and deal option details.
   - From: `storageFacade`
   - To: `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

8. **Load order summary**: Storage Facade fetches order summary (total orders, resigned, non-paid) from Orders.
   - From: `storageFacade`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

9. **Load customer authority attributes**: Storage Facade fetches AMS attributes (if `customer_authority_attributes` feature flag is enabled).
   - From: `storageFacade`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTPS/JSON

10. **Parallel context load**: Storage Facade concurrently loads user details, order details, merchant profile, redemption locations (if applicable), booking reservations (US only, online booking deals), trade-in exchange amount (US only, tradable vouchers), and gift details history.
    - From: `storageFacade`
    - To: `continuumUsersService`, `continuumOrdersService`, `continuumM3MerchantService`, `continuumPlaceReadService`, appointment engine, `continuumVoucherInventoryApi`
    - Protocol: HTTPS/JSON

11. **Evaluate workflows**: Voucher Next Actions Handler passes the fully populated Storage Facade to the Notification Workflow Engine, which applies eligibility rules for each known action type (EE, trade-in, reminders, gifting, pay-on-redemption, etc.) and computes the ordered action list.
    - From: `voucherNextActionsHandler`
    - To: `workflowEngine`
    - Protocol: direct

12. **Read Redis state**: Workflow Engine reads per-voucher helper state from Redis to determine which actions are already scheduled.
    - From: `workflowEngine`
    - To: `continuumBreakageReductionRedis`
    - Protocol: TCP/Redis

13. **Return next-actions response**: The assembled next-actions list is returned to the caller.
    - From: `voucherNextActionsHandler`
    - To: consumer client
    - Protocol: HTTPS/JSON (200 OK)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Voucher not found in VIS/TPIS | Throws `notFoundError`, propagated as 404 | Caller receives 404 |
| Deal not found in Deal Catalog | Throws `notFoundError` | Caller receives 404 |
| Order summary fetch failure | Falls back to `{totalOrders: 0, totalResigned: 0, nonPaidOrders: 0}` | Flow continues with default |
| AMS fetch failure | Falls back to `{}` (empty attributes) | Flow continues without authority attributes |
| Booking resource fetch failure | Falls back to title-based resource placeholders | Flow continues with placeholder booking data |
| Downstream timeout | `gofer` throws after `connectTimeout` (1000 ms in production) | Error propagated to caller |
| Redis unavailable | Redis offline queue absorbs requests up to `max_attempts: 10` | Workflow state reads fail gracefully if queue exhausted |

## Sequence Diagram

```
Client -> brsApiRoutes: POST /voucher/v1/next_actions
brsApiRoutes -> voucherNextActionsHandler: dispatch
voucherNextActionsHandler -> storageFacade: initialize + preload()
storageFacade -> continuumVoucherInventoryApi: GET /inventory/v1/units
storageFacade -> continuumVoucherInventoryApi: GET /inventory/v1/products
storageFacade -> continuumDealCatalogService: search by inventoryProductId
storageFacade -> continuumOrdersService: getOrderSummary
storageFacade -> continuumAudienceManagementService: getCAAttributes
storageFacade -> continuumUsersService: loadUserDetails
storageFacade -> continuumOrdersService: getOrderInventoryUnit
storageFacade -> continuumM3MerchantService: getMerchant
storageFacade -> continuumPlaceReadService: getPlaces (parallel)
voucherNextActionsHandler -> workflowEngine: evaluate(storage)
workflowEngine -> continuumBreakageReductionRedis: read helper state
workflowEngine --> voucherNextActionsHandler: next-actions list
voucherNextActionsHandler --> Client: 200 OK {next_actions: [...]}
```

## Related

- Architecture dynamic view: `dynamic-brs-reminder-scheduling-flow`
- Related flows: [Voucher Context Preload](voucher-context-preload.md), [Reminder Scheduling](reminder-scheduling.md)
