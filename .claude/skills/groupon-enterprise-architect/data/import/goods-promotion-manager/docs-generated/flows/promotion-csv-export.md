---
service: "goods-promotion-manager"
title: "Promotion CSV Export"
generated: "2026-03-03"
type: flow
flow_name: "promotion-csv-export"
flow_type: synchronous
trigger: "API call — internal user or pricing team requests ILS pricing CSV for one or more promotions"
participants:
  - "continuumGoodsPromotionManagerService"
  - "continuumDealManagementApi"
  - "continuumGoodsPromotionManagerDb"
architecture_ref: "dynamic-goods-promotion-manager"
---

# Promotion CSV Export

## Summary

The CSV export flow produces a downloadable ILS pricing spreadsheet for one or more promotions. It is used by pricing and merchandise teams to obtain the final price data needed to drive the Inventory Lifecycle Staging (ILS) grid update process. The flow combines a just-in-time product import (to ensure pricing is current) with a streaming multi-join database query, and applies post-processing logic to merge overlapping inventory product records and sort the output chronologically.

## Trigger

- **Type**: api-call
- **Source**: Internal user or external caller (e.g., pricing team) sends `POST /v1/promotions/csv_data`
- **Frequency**: On-demand; may take minutes for large promotions

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal User / Pricing Team | Requests CSV export with promotion UUID list | — |
| Promotion Resource | Receives request and delegates to handler | `continuumGoodsPromotionManagerService` |
| Promotion Handler | Orchestrates import, DB query, post-processing, and streaming | `continuumGoodsPromotionManagerService` |
| Quartz Job Handler | Schedules and monitors inline Import Product Job | `continuumGoodsPromotionManagerService` |
| Import Product Job | Fetches current pricing from Deal Management API (inline) | `continuumGoodsPromotionManagerService` |
| Deal Management API | Supplies deal and inventory product pricing | `continuumDealManagementApi` |
| Promotion DAO Manager | Executes the multi-join CSV data query | `continuumGoodsPromotionManagerService` |
| Promotion CSV DAO | Provides the raw CSV data query against promotion tables | `continuumGoodsPromotionManagerService` |
| Goods Promotion Manager DB | Source of all promotion and pricing data | `continuumGoodsPromotionManagerDb` |

## Steps

1. **Receive CSV Request**: User sends `POST /v1/promotions/csv_data` with a `PromotionCsvRequestWrapper` body containing a list of promotion UUID strings and an `includeNullIlsPrices` boolean.
   - From: Internal User
   - To: `continuumGoodsPromotionManagerService` (`Promotion Resource`)
   - Protocol: HTTPS/REST

2. **Validate UUID List**: Promotion Handler validates that the UUID list is non-null and non-empty, and parses each string to a valid `UUID`. Throws `ValidationException` on invalid format.
   - From: `promotionHandler` (in-memory)
   - To: — (pure validation)
   - Protocol: direct

3. **Retrieve ILS Deal UUIDs**: Handler calls `PromotionDaoManager.getIlsDealUuidSetFromPromotionUuids()` to get the set of deal UUIDs associated with the promotions' ILS promotion deals.
   - From: `promotionHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

4. **Trigger Inline Import Product Job**: Handler calls `runImportProductJob(dealUuidSet)`, which schedules an immediate Quartz `Import Product Job` execution for the retrieved deal UUIDs. This ensures inventory product pricing is current before the CSV data is queried.
   - From: `promotionHandler` → `quartzJobHandler`
   - To: `importProductJob` → `continuumDealManagementApi`
   - Protocol: Quartz internal / HTTPS/REST

5. **Wait for Job Completion**: Handler polls the `qrtz_triggers` table via `QuartzJobDao.checkIfJobExists()` at one-second intervals, waiting up to 60 seconds (`MAX_WAIT_TIME_IN_SECONDS`) for the job to complete.
   - From: `promotionHandler`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

6. **Query CSV Data**: Handler calls `PromotionDaoManager.getPromotionCsv(promoUuids, includeNullIlsPrices)`, which executes a multi-join SQL query across `promotion`, `promotion_deal`, `promotion_inventory_product`, `deal`, and `inventory_product` tables to assemble the raw CSV rows.
   - From: `promotionHandler` → `promotionCsvDao`
   - To: `continuumGoodsPromotionManagerDb`
   - Protocol: JDBC

7. **Post-Process CSV Data**: Handler calls `postProcessPromotionCsvList()` which: (a) sorts records by `inventory_product_id`, `offer_sell_price`, and `start_date`; (b) merges adjacent rows for the same inventory product and offer price into a single date-range row; (c) re-sorts the merged list by `start_date`, `end_date`, `permalink`, and `offer_sell_price`.
   - From: `promotionHandler` (in-memory)
   - To: — (pure computation)
   - Protocol: direct

8. **Stream CSV Response**: Handler returns a `StreamingOutput` that writes the CSV header row (`start_date,end_date,promotion_name,...,division`) followed by all data rows to the HTTP response output stream, inserting blank lines between date-range groups. Monetary values are rendered as decimals (stored as integers, divided by 100).
   - From: `continuumGoodsPromotionManagerService`
   - To: Internal User
   - Protocol: HTTPS (streaming response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UUID list is null or empty | `ValidationException` thrown | HTTP 400 |
| One or more UUID strings are invalid format | `ValidationException` thrown with the malformed list | HTTP 400 |
| Import Product Job scheduling fails (`SchedulerException`) | Warning logged; flow continues without updated pricing | CSV generated with potentially stale pricing |
| Import Product Job does not finish within 60 seconds | Polling loop exits; flow continues | CSV generated with whatever pricing was available at the 60-second mark |
| DB query fails | Exception propagated | HTTP 500 |
| Forbidden / auth failure (client-ID) | JTier auth bundle rejects request | HTTP 403 (seen as "Failed - Forbidden" by clients) |

## Sequence Diagram

```
InternalUser -> PromotionResource: POST /v1/promotions/csv_data {uuidList, includeNullIlsPrices}
PromotionResource -> PromotionHandler: getPromotionsStreamingOutput(uuidList, includeNullIlsPrices)
PromotionHandler -> PromotionHandler: validateUuidList(), parseUUIDs()
PromotionHandler -> PromotionDaoManager: getIlsDealUuidSetFromPromotionUuids(promoUuids)
PromotionDaoManager -> GoodsPromotionManagerDB: SELECT deal_uuids for ILS promotion deals
GoodsPromotionManagerDB --> PromotionHandler: Set<UUID> dealUuids
PromotionHandler -> QuartzJobHandler: scheduleImportProductJob(dealUuidSet)
QuartzJobHandler -> ImportProductJob: [trigger inline]
ImportProductJob -> DealManagementAPI: GET /v2/deals/{id}?expand[0]=full [for each deal]
DealManagementAPI --> ImportProductJob: GetV2DealRes
ImportProductJob -> GoodsPromotionManagerDB: UPSERT deal, inventory_product
PromotionHandler -> GoodsPromotionManagerDB: poll qrtz_triggers (max 60s)
GoodsPromotionManagerDB --> PromotionHandler: job done (trigger record gone)
PromotionHandler -> PromotionDaoManager: getPromotionCsv(promoUuids, includeNullIlsPrices)
PromotionDaoManager -> GoodsPromotionManagerDB: SELECT (multi-join: promotion, promotion_deal, promotion_inventory_product, deal, inventory_product)
GoodsPromotionManagerDB --> PromotionHandler: List<PromotionCsv>
PromotionHandler -> PromotionHandler: postProcessPromotionCsvList() (sort + merge)
PromotionHandler --> PromotionResource: StreamingOutput
PromotionResource --> InternalUser: HTTP 200 (streaming CSV)
```

## Related

- Architecture dynamic view: `dynamic-goods-promotion-manager`
- Related flows: [Import Product Job](import-product-job.md), [Promotion Lifecycle](promotion-lifecycle.md)
- CSV header format: `start_date,end_date,promotion_name,division_name,category,subcategory,channel,user_id,coop_type,coop_value,option_title,price_change_flag,permalink,inventory_product_id,unit_price,unit_buy_price,offer_sell_price,offer_buy_price,currency_code,country_code,division`
