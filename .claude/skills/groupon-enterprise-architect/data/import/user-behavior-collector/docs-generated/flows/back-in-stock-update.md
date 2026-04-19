---
service: "user-behavior-collector"
title: "Back-in-Stock Update"
generated: "2026-03-03"
type: flow
flow_name: "back-in-stock-update"
flow_type: batch
trigger: "Daily cron (update_deal_views) as a step within the main batch job"
participants:
  - "continuumUserBehaviorCollectorJob"
  - "continuumDealViewNotificationDb"
  - "visInventoryService_f4b0"
architecture_ref: "continuumUserBehaviorCollectorJob-components"
---

# Back-in-Stock Update

## Summary

The Back-in-Stock Update flow identifies deal options that were previously sold out and checks whether they have become available again. It reads sold-out deal option IDs from the `deal_view_notification` database, calls the VIS (Voucher Inventory Service) to check current availability, and writes back-in-stock status updates to the database. This enables the Audience Publishing flow to subsequently build `BackInStockPush` and `BackInStockEmail` audience segments for targeting users who viewed deals that are now available.

## Trigger

- **Type**: schedule (sequential step within `update_deal_views` batch job)
- **Source**: Job Orchestrator triggers `backInStockUpdater` component after deal info refresh
- **Frequency**: Daily — runs within the same `update_deal_views` invocation as Spark Event Ingestion and Deal Info Refresh

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Triggers back-in-stock step via `backInStockUpdater` | `continuumUserBehaviorCollectorJob` |
| Back-in-Stock Updater | Queries sold-out deals; checks VIS; writes updates | `continuumUserBehaviorCollectorJob` (backInStockUpdater component) |
| Data Access Layer | Reads sold-out deal options; writes back-in-stock results | `continuumUserBehaviorCollectorJob` (userBehaviorCollector_dataAccessLayer component) |
| Deal View Notification DB | Source of sold-out deal options; target for back-in-stock updates | `continuumDealViewNotificationDb` |
| VIS (Voucher Inventory Service) | Checks current voucher availability for deal options | `visInventoryService_f4b0` |

## Steps

1. **Read sold-out deal options from DB**: Back-in-Stock Updater calls `getSoldoutDealIds()` on `AppDataConnection` to retrieve `DealOptionWithCountry` records from `continuumDealViewNotificationDb`
   - From: `continuumUserBehaviorCollectorJob` (backInStockUpdater)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC

2. **Check voucher availability via VIS**: For each sold-out deal option, calls `POST /inventory/v1/products/availability` via `VisClient.checkProductAvailability()` with:
   - `purchaserId` UUID
   - `inventoryProductIds` array of UUIDs
   - `locale` and `inventoryType` from config (`<inventoryType>.inventory.clientId`)
   - From: `continuumUserBehaviorCollectorJob` (backInStockUpdater)
   - To: `visInventoryService_f4b0`
   - Protocol: REST (Retrofit/OkHttp)

3. **Determine availability**: If VIS returns HTTP 200, deal option is considered back-in-stock; non-200 response means still unavailable

4. **Write back-in-stock status to DB**: Back-in-Stock Updater writes the availability result for each deal option back to `continuumDealViewNotificationDb` via Data Access Layer
   - From: `continuumUserBehaviorCollectorJob` (backInStockUpdater)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS returns non-200 | Logs at INFO level with status, request, and response headers; returns `false` | Deal option remains marked as sold-out; not promoted to back-in-stock audience |
| Empty inventoryProductIds | Logs WARN "No inventoryProductIds"; returns `false` | Availability check skipped for that deal |
| VIS call throws IOException | Exception propagates | Back-in-stock step fails; error logged; job may fail depending on caller exception handling |
| DB read/write fails | Exception propagates | Step fails; PagerDuty alert from cron script failure handling |

## Sequence Diagram

```
JobOrchestrator -> BackInStockUpdater: Trigger back-in-stock update
BackInStockUpdater -> DataAccessLayer: getSoldoutDealIds()
DataAccessLayer -> DealViewNotificationDb: Query sold-out deal options
DealViewNotificationDb --> DataAccessLayer: List<DealOptionWithCountry>
DataAccessLayer --> BackInStockUpdater: Sold-out deal option list
loop for each sold-out deal option
  BackInStockUpdater -> VIS: POST /inventory/v1/products/availability (purchaserId, inventoryProductIds, locale, clientId)
  VIS --> BackInStockUpdater: HTTP 200 (available) or non-200 (not available)
  BackInStockUpdater -> BackInStockUpdater: Determine back-in-stock status
  BackInStockUpdater -> DataAccessLayer: Write back-in-stock status
  DataAccessLayer -> DealViewNotificationDb: Update deal option availability record
end
BackInStockUpdater --> JobOrchestrator: Done
```

## Related

- Architecture dynamic view: `continuumUserBehaviorCollectorJob-components`
- Related flows: [Deal Info Refresh](deal-info-refresh.md), [Audience Publishing](audience-publishing.md)
