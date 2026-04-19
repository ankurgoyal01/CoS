---
service: "goods-promotion-manager"
title: "Import Product Job"
generated: "2026-03-03"
type: flow
flow_name: "import-product-job"
flow_type: scheduled
trigger: "Quartz scheduler (configured schedule) or manual API trigger via POST /v1/jobs/import-products"
participants:
  - "continuumGoodsPromotionManagerService"
  - "continuumDealManagementApi"
  - "continuumGoodsPromotionManagerDb"
architecture_ref: "dynamic-goods-promotion-manager"
---

# Import Product Job

## Summary

The Import Product Job is a Quartz-scheduled background job that synchronizes deal and inventory product data from the Deal Management API into the local PostgreSQL database. This ensures that the Goods Promotion Manager has up-to-date deal metadata (permalink, purchasability region, inventory product UUIDs, unit buy/sell prices) needed for eligibility evaluation and CSV export without making live API calls on every user request. The job can also be triggered on-demand via the REST API or inline during a CSV export.

## Trigger

- **Type**: schedule (Quartz) or api-call (manual or inline)
- **Source**: Quartz trigger configured in `resources/config` YAML files (`triggers` section); or `POST /v1/jobs/import-products` with a list of deal UUIDs; or inline trigger from `PromotionHandler.getPromotionsStreamingOutput()` during CSV export
- **Frequency**: Configured per-environment via Quartz cron triggers; on-demand during CSV export

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Triggers job according to configured schedule | `continuumGoodsPromotionManagerService` |
| Import Product Job | Orchestrates the import loop | `continuumGoodsPromotionManagerService` |
| Quartz Job Handler | Schedules the job; monitors job completion | `continuumGoodsPromotionManagerService` |
| Deal Management API Client | Retrofit2 client for outbound deal data requests | `continuumGoodsPromotionManagerService` |
| Deal Management API | Source of deal and inventory product data | `continuumDealManagementApi` |
| Deal DAO | Persists deal reference data | `continuumGoodsPromotionManagerService` |
| Inventory Product DAO | Persists inventory product reference data | `continuumGoodsPromotionManagerService` |
| Goods Promotion Manager DB | Stores imported deal and inventory product data | `continuumGoodsPromotionManagerDb` |

## Steps

1. **Trigger Job**: Quartz fires the `Import Product Job` according to the configured trigger schedule, or the job is manually triggered via `POST /v1/jobs/import-products` (passing a list of deal UUIDs), or it is triggered inline from `PromotionHandler.runImportProductJob()` when generating a CSV export.
   - From: Quartz Scheduler / API Request / PromotionHandler
   - To: `importProductJob`
   - Protocol: Quartz internal dispatch / direct

2. **Retrieve Deal UUIDs to Import**: The job obtains the set of deal UUIDs to process. For scheduled runs, this is derived from promotion records; for on-demand runs, the UUIDs are passed directly.
   - From: `importProductJob`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

3. **Batch Fetch Deal Data**: The job calls `DealManagementApiClient.getDeal(uuid)` for each deal UUID (batched per `dmapiBatchSize` configuration). This calls `GET /v2/deals/{id}?expand[0]=full` on the Deal Management API, returning full deal and nested inventory product data.
   - From: `importProductJob` / `dealManagementApiClient`
   - To: `continuumDealManagementApi`
   - Protocol: HTTPS/REST

4. **Parse Response**: The job extracts deal fields (UUID, permalink, purchasability region) and inventory product fields (UUID, unit sell price, unit buy price) from the `GetV2DealRes` response object.
   - From: `importProductJob` (in-memory)
   - To: — (pure parsing)
   - Protocol: direct

5. **Persist Deal and Inventory Product Data**: The job writes the parsed data to the `deal` and `inventory_product` tables via `DealDao` and `InventoryProductDao`.
   - From: `importProductJob`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

6. **Signal Completion**: On completion, the Quartz trigger is removed from the `qrtz_triggers` table, signaling that the job has finished. The `PromotionHandler.waitUntilJobFinishes()` polling loop (up to `MAX_WAIT_TIME_IN_SECONDS = 60`) uses this to detect completion during inline CSV-triggered invocations.
   - From: Quartz framework
   - To: `continuumGoodsPromotionManagerDb` (qrtz_triggers table)
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Management API returns error for a deal | Error logged via Steno logger; that deal is skipped | Remaining deals processed; partial import |
| `SchedulerException` when scheduling inline job | Warning logged (`"Unable to schedule importProductJob for: ..."`) | CSV export continues with existing (potentially stale) data |
| Job does not complete within 60-second wait window | `waitUntilJobFinishes()` exits the polling loop | CSV export proceeds with whatever data is available |
| Database write failure | Exception propagated; job marked failed by Quartz | Job logged as failed; Quartz may retry per configuration |

## Sequence Diagram

```
QuartzScheduler -> ImportProductJob: execute()
ImportProductJob -> GoodsPromotionManagerDB: SELECT deal UUIDs to import
GoodsPromotionManagerDB --> ImportProductJob: List<UUID>
ImportProductJob -> DealManagementApiClient: getDeal(uuid) [for each UUID in batches]
DealManagementApiClient -> DealManagementAPI: GET /v2/deals/{id}?expand[0]=full
DealManagementAPI --> DealManagementApiClient: GetV2DealRes (deal + inventory products)
DealManagementApiClient --> ImportProductJob: GetV2DealRes
ImportProductJob -> ImportProductJob: parse deal, inventory products
ImportProductJob -> DealDao: upsert deal record
DealDao -> GoodsPromotionManagerDB: INSERT/UPDATE deal
ImportProductJob -> InventoryProductDao: upsert inventory_product records
InventoryProductDao -> GoodsPromotionManagerDB: INSERT/UPDATE inventory_product
QuartzScheduler -> GoodsPromotionManagerDB: DELETE FROM qrtz_triggers (job done signal)
```

## Related

- Architecture dynamic view: `dynamic-goods-promotion-manager`
- Related flows: [Promotion CSV Export](promotion-csv-export.md), [Promotion Lifecycle](promotion-lifecycle.md)
