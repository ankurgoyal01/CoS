---
service: "bookability-dashboard"
title: "Deal Health Check Monitoring"
generated: "2026-03-03"
type: flow
flow_name: "deal-health-check-monitoring"
flow_type: synchronous
trigger: "User opens a deal detail view or triggers a manual health check"
participants:
  - "continuumBookabilityDashboardWeb"
  - "bookDash_appShell"
  - "bookDash_partnerServiceClient"
  - "bookDash_jsonParserWorkerBridge"
  - "apiProxy"
  - "continuumPartnerService"
architecture_ref: "dynamic-bookability-dashboard-data-fetch"
---

# Deal Health Check Monitoring

## Summary

The Deal Health Check Monitoring flow fetches, parses, and displays health-check results for individual deals. Health-check data is represented as `deal.health.check` log entries in Partner Service. The dashboard reads these logs in parallel batches, parses them using a Web Worker, indexes them by deal ID, and displays a set of platform-specific boolean check results. Users can also manually trigger a fresh health check for any deal product, or trigger an auto-fix for specific check types.

## Trigger

- **Type**: user-action
- **Source**: User navigates to the Deals view or opens a Deal Details page; health-check data is also preloaded during the initial Dashboard Data Load
- **Frequency**: On demand (view navigation); background preload during initial data load (last 24 hours of logs)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dashboard App Shell | Coordinates health-check data retrieval and cache management | `bookDash_appShell` |
| Partner Service Client | Fetches paginated health-check logs; sends trigger and fix requests | `bookDash_partnerServiceClient` |
| JSON Parser Worker Bridge | Parses large JSON log payloads off the main thread | `bookDash_jsonParserWorkerBridge` |
| API Proxy | Routes requests to Partner Service | `apiProxy` |
| Partner Service | Stores and returns `deal.health.check` log entries | `continuumPartnerService` |

## Steps

### Health-check log retrieval (preload)

1. **Collect acquisition method IDs**: `fetchDealHealthLogsWithTimeRange()` calls `fetchPartnerConfigurations()` to get all active partner acquisition method IDs.
   - From: `bookDash_partnerServiceClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (GET `/v1/partner_configurations?monitoring=true&clientId=tpis`)

2. **Build paginated fetch plan**: A cache key is constructed from sorted acquisition method IDs + time range. If a matching in-flight request exists, the existing promise is returned (deduplication).
   - From: `bookDash_partnerServiceClient`
   - To: In-process
   - Protocol: In-process

3. **Fetch log pages in parallel batches**: Pages are fetched in batches of 15 (`PARALLEL_BATCH_SIZE`). Each page request is `GET /v1/groupon/simulator/logs?acquisitionMethodIds=...&logTypes=deal.health.check&clientId=tpis&page=N&size=5000` with optional `earliest` and `latest` time-range parameters.
   - From: `bookDash_partnerServiceClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS, credentials: include)

4. **Extract response text with timeout**: Each page response text is extracted within a 180 s timeout. If the timeout fires, the page is skipped.
   - From: `bookDash_partnerServiceClient`
   - To: In-process
   - Protocol: In-process

5. **Parse JSON via Web Worker**: Each page's response text is sent to `bookDash_jsonParserWorkerBridge` with a 120 s parse timeout. If the Worker times out, `JSON.parse()` is used as a synchronous fallback.
   - From: `bookDash_partnerServiceClient`
   - To: `bookDash_jsonParserWorkerBridge`
   - Protocol: Web Worker message (postMessage / onmessage)

6. **Collect `fieldConfigurations`**: The first successful page response that includes `fieldConfigurations` is cached globally. These configurations define visible health-check fields per partner type.
   - From: `bookDash_partnerServiceClient`
   - To: In-process cache (`fieldConfigurationsCache`)
   - Protocol: In-process

7. **Index health-check data by deal ID**: Parsed `deal.health.check` log entries are grouped by `entityId` (Groupon deal ID). Each log's `message` field is JSON-parsed into a `DealHealthCheckData` object. Results are stored in `DataService.healthCheckDataCache`.
   - From: `bookDash_appShell` (DataService)
   - To: In-process
   - Protocol: In-process

8. **Display health checks**: In the `DealDetailsPage` component, health-check results are retrieved from the cache and displayed as a set of boolean indicators (pass/fail) per check type: `isBookable`, `freeTimeSlots`, `serviceDuration`, `locationMapped`, `merchantConnected`, `serviceExists`, `price`, `redemptionMethodCorrect`, `bookableOnline`, `activeLocation`, `clientLinks`, `checkoutFields`, and platform-specific fields (`mboRequiredFields`, `mboPricingOption`, `mboPaymentMethod`, `locationTreatments`).
   - From: `bookDash_appShell`
   - To: Browser DOM
   - Protocol: In-process

### Manual health-check trigger

9. **User triggers health check**: User clicks the trigger button in `DealDetailsPage`. `triggerDealHealthCheckForProducts()` sends `PUT /v1/deals/health-check/trigger?inventoryProductIds={ids}&acquisitionMethodId={id}&clientId=tpis` with an empty JSON body.
   - From: `bookDash_partnerServiceClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS PUT)

10. **User triggers health-check fix**: User selects a specific check type to fix. `fixHealthCheck()` sends `PUT /v1/deals/health-check/fix?inventoryProductId={id}&acquisitionMethodId={id}&checkType={type}&clientId=tpis`. Valid `checkType` values: `isBookable`, `calendarServiceCorrect`, `clientLinks`, `checkoutFields`.
    - From: `bookDash_partnerServiceClient`
    - To: `continuumPartnerService` (via `apiProxy`)
    - Protocol: REST (HTTPS PUT)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Log page fetch HTTP error | Page skipped; error logged; `failedPages` counter incremented | Remaining pages still processed; partial data displayed |
| Text extraction timeout (180 s) | Page rejected; error logged | That page's logs absent from results |
| Web Worker parse timeout (120 s) | Falls back to synchronous `JSON.parse()` | Health log parsed synchronously; minor UI delay possible |
| Health-check message JSON parse failure | Error logged; that log entry skipped | Other health-check entries for the deal still displayed |
| Trigger/fix PUT returns HTTP error | Error thrown and logged | Toast notification or console error; no automatic retry |
| Health-check cache stale (>10 min) | Cache is cleared; full re-fetch triggered on next `preloadHealthCheckData()` call | Fresh data loaded |

## Sequence Diagram

```
AppShell -> PartnerServiceClient: preloadHealthCheckDataForDeals(deals)
PartnerServiceClient -> PartnerService: GET /v1/partner_configurations?monitoring=true
PartnerService --> PartnerServiceClient: acquisitionMethodIds[]
PartnerServiceClient -> PartnerService: [batch 15x parallel] GET /v1/groupon/simulator/logs?page=N
PartnerService --> PartnerServiceClient: { logs: [...], fieldConfigurations: {...} }
PartnerServiceClient -> JsonParserWorker: parseJSON(responseText, pageNum)
JsonParserWorker --> PartnerServiceClient: parsed log page
PartnerServiceClient -> DataService: healthCheckDataCache.set(dealId, healthData[])
DataService --> AppShell: healthCheckCache
AppShell -> Browser: Render DealDetailsPage with health indicators
--- (manual trigger) ---
User -> AppShell: Click "Trigger Health Check"
AppShell -> PartnerServiceClient: triggerDealHealthCheckForProducts([productIds], acquisitionMethodId)
PartnerServiceClient -> PartnerService: PUT /v1/deals/health-check/trigger?inventoryProductIds=...
PartnerService --> PartnerServiceClient: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-bookability-dashboard-data-fetch`
- Related flows: [Dashboard Data Load](dashboard-data-load.md), [Deal Investigation Workflow](deal-investigation-workflow.md)
