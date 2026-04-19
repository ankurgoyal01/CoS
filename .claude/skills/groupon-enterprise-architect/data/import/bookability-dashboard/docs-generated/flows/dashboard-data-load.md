---
service: "bookability-dashboard"
title: "Dashboard Data Load"
generated: "2026-03-03"
type: flow
flow_name: "dashboard-data-load"
flow_type: synchronous
trigger: "Initial page load or manual refresh by user"
participants:
  - "continuumBookabilityDashboardWeb"
  - "bookDash_appShell"
  - "bookDash_partnerServiceClient"
  - "bookDash_jsonParserWorkerBridge"
  - "apiProxy"
  - "continuumPartnerService"
architecture_ref: "dynamic-bookability-dashboard-data-fetch"
---

# Dashboard Data Load

## Summary

On initial load and every 5 minutes (auto-refresh), the dashboard discovers active booking partners from the Partner Service API and then concurrently fetches merchant lists, deal connectivity status, merchant product mappings, and health-check logs for each partner. All data is enriched client-side to produce a unified merchant-with-deals model, cached in memory, and rendered across the Merchants, Deals, and Reports views.

## Trigger

- **Type**: user-action / schedule
- **Source**: `MainApp` component mounts (`useEffect` on initial render); or `setInterval` fires every 5 minutes (300,000 ms)
- **Frequency**: On page load + every 5 minutes while the dashboard is open

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dashboard App Shell | Orchestrates data fetch, manages loading state, populates React state | `bookDash_appShell` |
| Partner Service Client | Makes all HTTP requests to Partner Service endpoints | `bookDash_partnerServiceClient` |
| JSON Parser Worker Bridge | Parses large health-check log JSON payloads off the main thread | `bookDash_jsonParserWorkerBridge` |
| API Proxy | Routes requests from browser to Partner Service backend | `apiProxy` |
| Partner Service | Provides all data: partner configurations, merchants, deals, products, health logs | `continuumPartnerService` |

## Steps

1. **Fetch partner configurations**: `DataService.getEnrichedData()` calls `fetchFullPartnerConfigurations()`. Sends `GET /v1/partner_configurations?monitoring=true&clientId=tpis` to Partner Service. Response is parsed, deduplicated by partner name, filtered to partners with an `acquisitionMethodId`, and cached for 5 minutes.
   - From: `bookDash_partnerServiceClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS, credentials: include)

2. **Launch parallel partner data fetches**: For each discovered partner configuration, `DataService.getAllPartnersData()` calls `DataService.getPartnerData()` in parallel via `Promise.all()`. Each partner fetch is itself parallelized into three concurrent calls:
   - `fetchMerchantsByPartner(partnerApiName)` → `GET /v2/partners/{partner}/merchants?clientId=tpis`
   - `fetchConnectivityStatus(acquisitionMethodId)` → `GET /v1/partners/{partnerId}/connectivity_status?clientId=tpis`
   - `fetchMerchantProducts([acquisitionMethodId])` → `GET /v1/partners/merchant_products?acquisitionMethodIds=...&clientId=tpis`
   - From: `bookDash_partnerServiceClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS)

3. **Build deals from merchant products**: For each partner, `DataService.createDealsFromMerchantProducts()` groups merchant products by `grouponDealId`, creating deal objects with `dealOptions` arrays. Active products (`inventoryStatus === 'active'`) are retained.
   - From: `bookDash_appShell` (DataService)
   - To: In-process transformation
   - Protocol: In-process

4. **Enrich deals with connectivity data**: `processDeals()` merges connectivity status records (deal live status, permalink, merchant name, timestamps) onto the deal objects created from merchant products. A connectivity lookup map is used for O(1) joins.
   - From: `bookDash_appShell` (DataService)
   - To: In-process transformation
   - Protocol: In-process

5. **Map merchants to deals**: `mapMerchantsToDeals()` associates enriched deals with their parent merchants, producing a `MerchantWithDeals[]` structure per partner. Merchant lookup is indexed by merchant ID.
   - From: `bookDash_appShell` (DataService)
   - To: In-process transformation
   - Protocol: In-process

6. **Preload health-check data**: `DataService.preloadHealthCheckData()` calls `preloadHealthCheckDataForDeals()`, which fetches the last 24 hours of `deal.health.check` logs from Partner Service using parallel batch pagination (batch size: 15 pages × 5,000 records per page). Large JSON responses are parsed by `bookDash_jsonParserWorkerBridge` (Web Worker, 120 s parse timeout). Health data is indexed by deal entity ID and cached for 10 minutes.
   - From: `bookDash_partnerServiceClient` + `bookDash_jsonParserWorkerBridge`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS)

7. **Enrich merchants and deals with health data**: `enrichDataWithRelationships()` joins health-check data onto `EnrichedDeal` objects, computes `isHealthy`, `problematicDealsCount`, and `healthyDealsCount` per merchant.
   - From: `bookDash_appShell` (DataService)
   - To: In-process transformation
   - Protocol: In-process

8. **Update React state and render**: `setMerchants()`, `setDeals()`, and `setHealthCheckCache()` are called with enriched data. The loading overlay is hidden. Views re-render with live data.
   - From: `bookDash_appShell`
   - To: Browser DOM (React render)
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner configurations fetch fails | Error thrown; caught in `DataService.getEnrichedData()` | Empty state rendered; error logged to console |
| Individual partner data fetch fails | Caught per-partner in `getPartnerData()`; returns `null` for that partner | Other partners' data still loaded; failed partner absent from UI |
| Connectivity or product fetch returns non-array | Guarded with `Array.isArray()` check | Empty deal list for that partner; no crash |
| Health-log page fetch fails | Page marked as failed; logged as warning; other pages continue | Partial health data; some deals may show no health history |
| Web Worker JSON parse timeout (120 s) | Falls back to `JSON.parse()` on main thread | Health log parsed (potentially blocking UI briefly) |
| Text extraction timeout (180 s) | Page fetch rejected; error logged | That log page skipped |
| HTTP 503 from Partner Service | `setDown(true)` in AppContext | Service-unavailable banner displayed |

## Sequence Diagram

```
AppShell -> DataService: getEnrichedData()
DataService -> PartnerService: GET /v1/partner_configurations?monitoring=true
PartnerService --> DataService: [{ name, acquisitionMethodId, ... }]
DataService -> PartnerService: [parallel] GET /v2/partners/{p}/merchants (per partner)
DataService -> PartnerService: [parallel] GET /v1/partners/{id}/connectivity_status (per partner)
DataService -> PartnerService: [parallel] GET /v1/partners/merchant_products?acquisitionMethodIds=... (per partner)
PartnerService --> DataService: merchant lists, connectivity records, product mappings
DataService -> DataService: createDealsFromMerchantProducts()
DataService -> DataService: processDeals() + enrichDealWithConnectivityData()
DataService -> DataService: mapMerchantsToDeals()
DataService -> PartnerService: GET /v1/groupon/simulator/logs (batch pages, parallel)
PartnerService --> DataService: deal.health.check log pages
DataService -> JsonParserWorker: parseJSON(responseText, pageNum)
JsonParserWorker --> DataService: parsed health log data
DataService -> DataService: enrichDataWithRelationships()
DataService --> AppShell: { merchants: EnrichedMerchant[], deals: EnrichedDeal[] }
AppShell -> Browser: setMerchants / setDeals / setHealthCheckCache → re-render
```

## Related

- Architecture dynamic view: `dynamic-bookability-dashboard-data-fetch`
- Related flows: [User Authentication](user-authentication.md), [Deal Health Check Monitoring](deal-health-check-monitoring.md)
