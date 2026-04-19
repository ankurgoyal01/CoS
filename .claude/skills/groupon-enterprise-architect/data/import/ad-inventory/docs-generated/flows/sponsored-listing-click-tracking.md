---
service: "ad-inventory"
title: "Sponsored Listing Click Tracking"
generated: "2026-03-03"
type: flow
flow_name: "sponsored-listing-click-tracking"
flow_type: synchronous
trigger: "Inbound HTTP GET to /ai/api/v1/slc/{id} from Groupon frontend on user click"
participants:
  - "continuumAdInventoryService_adInventoryPlacementResource"
  - "continuumAdInventoryService_sponsoredListingService"
  - "continuumAdInventoryMySQL"
  - "continuumAdInventoryService_smaMetricsLogger"
  - "continuumSmaMetrics"
architecture_ref: "components-continuum-ad-inventory-service-components"
---

# Sponsored Listing Click Tracking

## Summary

When a user clicks on a sponsored listing on a Groupon page, the frontend calls `GET /ai/api/v1/slc/{id}` to record the click event. The `SponsoredListingService` persists the click in MySQL (including bid context, cookie, and deal UUID), emits SMA click-count metrics, and forwards the click event to CitrusAd for attribution and billing. This flow is critical for advertiser billing accuracy.

## Trigger

- **Type**: api-call (user-action on frontend triggers a tracking pixel / redirect call)
- **Source**: Groupon frontend pages and apps — triggered by user clicking a sponsored listing
- **Frequency**: Per sponsored listing click event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Frontend | Initiates click tracking request | External caller |
| Ad Inventory Placement Resource | Receives the `/slc/` request and delegates to SponsoredListingService | `continuumAdInventoryService_adInventoryPlacementResource` |
| Sponsored Listing Service | Core handler: persists click, forwards to CitrusAd, emits metrics | `continuumAdInventoryService_sponsoredListingService` |
| Ad Inventory MySQL | Persists sponsored click event records | `continuumAdInventoryMySQL` |
| SMA Metrics Logger | Emits click count metrics | `continuumAdInventoryService_smaMetricsLogger` |
| SMA Metrics | Aggregates and stores metrics | `continuumSmaMetrics` |
| CitrusAd | Receives forwarded click for attribution | External (`citrusAdApi`) |

## Steps

1. **Receive click tracking request**: Frontend issues `GET /ai/api/v1/slc/{id}?bc=<bidContext>&cc=<cCookie>&dealuuid=<uuid>`.
   - From: Groupon Frontend
   - To: `continuumAdInventoryService_adInventoryPlacementResource`
   - Protocol: REST / HTTP

2. **Delegate to Sponsored Listing Service**: `AdInventoryPlacementResource` routes the request to `SponsoredListingService.persistClick()`.
   - From: `continuumAdInventoryService_adInventoryPlacementResource`
   - To: `continuumAdInventoryService_sponsoredListingService`
   - Protocol: in-process call

3. **Persist click event in MySQL**: `SponsoredListingService` writes the click record (placement ID, bid context, cookie, deal UUID, timestamp) to MySQL.
   - From: `continuumAdInventoryService_sponsoredListingService`
   - To: `continuumAdInventoryMySQL`
   - Protocol: JDBI / SQL

4. **Forward click to CitrusAd**: `SponsoredListingService` makes an outbound HTTP call to CitrusAd's click reporting endpoint (`citrusAd.baseUrl` + `citrusAd.reportClickPath`) with the click details.
   - From: `continuumAdInventoryService_sponsoredListingService`
   - To: CitrusAd API
   - Protocol: REST / HTTP (OkHttp)

5. **Emit click metrics**: `SponsoredListingService` calls `SMAMetricsLogger` to emit the sponsored listing click counter.
   - From: `continuumAdInventoryService_sponsoredListingService`
   - To: `continuumAdInventoryService_smaMetricsLogger`
   - Protocol: Metrics SDK

6. **Submit metrics to SMA**: `SMAMetricsLogger` submits the counter to Groupon SMA.
   - From: `continuumAdInventoryService_smaMetricsLogger`
   - To: `continuumSmaMetrics`
   - Protocol: HTTP

7. **Return response**: `AdInventoryPlacementResource` returns HTTP response to frontend.
   - From: `continuumAdInventoryService_adInventoryPlacementResource`
   - To: Groupon Frontend
   - Protocol: REST / HTTP response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL write failure | Exception logged; response may return error to caller | Click event lost if MySQL is down |
| CitrusAd HTTP failure | Click still persisted in MySQL; CitrusAd error logged | Attribution gap at CitrusAd; no retry mechanism found |
| Missing required `bc` parameter | HTTP 4xx from JAX-RS validation | Click not recorded |
| SMA metrics failure | Logged; non-blocking | Metric gap; click still processed |

## Sequence Diagram

```
Frontend -> AdInventoryPlacementResource: GET /ai/api/v1/slc/{id}?bc=...&cc=...&dealuuid=...
AdInventoryPlacementResource -> SponsoredListingService: persistClick(id, bc, cc, dealuuid)
SponsoredListingService -> MySQL: INSERT click event record
MySQL --> SponsoredListingService: OK
SponsoredListingService -> CitrusAd: POST click report (HTTP)
CitrusAd --> SponsoredListingService: OK/Error
SponsoredListingService -> SMAMetricsLogger: emit click counter
SMAMetricsLogger -> SMAMetrics: HTTP submit
SponsoredListingService --> AdInventoryPlacementResource: done
AdInventoryPlacementResource --> Frontend: HTTP 200
```

## Related

- Architecture dynamic view: `components-continuum-ad-inventory-service-components`
- Related flows: [Ad Placement Serving](ad-placement-serving.md)
