---
service: "travel-browse"
title: "Market-Rate Inventory Fetch"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "market-rate-inventory-fetch"
flow_type: synchronous
trigger: "HTTP GET request to /hotels/:dealId/inventory"
participants:
  - "continuumGetawaysBrowseWebApp"
  - "requestRouting"
  - "pageModules"
  - "apiClients"
  - "travelBrowse_cacheAccess"
  - "renderingEngine"
  - "memcacheCluster"
  - "marisApi"
  - "continuumGetawaysApi"
  - "userAuthService"
  - "remoteLayoutService"
architecture_ref: "dynamic-market-rate-inventory-fetch"
---

# Market-Rate Inventory Fetch

## Summary

The market-rate inventory fetch flow handles requests to the hotel detail and inventory page at `/hotels/:dealId/inventory`. The service fetches real-time hotel availability and market-rate pricing from MARIS alongside Getaways deal details from the Getaways API, assembles an inventory view model, and server-side renders the hotel inventory page. Live pricing data from MARIS is the critical path for this flow.

## Trigger

- **Type**: user-action / CDN cache miss
- **Source**: Browser navigating to a hotel detail page, or CDN forwarding an uncached request
- **Frequency**: Per-request (on-demand); market-rate pricing is typically not heavily cached due to real-time availability requirements

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Browse Web App | Orchestrates the inventory SSR pipeline | `continuumGetawaysBrowseWebApp` |
| Routing & Controllers | Receives HTTP request and dispatches to inventory page controller | `requestRouting` |
| Page Modules | Coordinates data fetching and view model assembly for inventory page | `pageModules` |
| API Client Integrations | Executes HTTP calls to MARIS and Getaways API | `apiClients` |
| Cache Access | Checks Memcache for deal metadata; live pricing bypasses cache | `travelBrowse_cacheAccess` |
| Rendering Engine | Executes React SSR to produce inventory page HTML | `renderingEngine` |
| Memcache Cluster | Stores cached Getaways deal metadata | `memcacheCluster` |
| MARIS | Returns real-time hotel availability and market-rate pricing | `marisApi` |
| Getaways API | Returns Getaways deal and hotel metadata | `continuumGetawaysApi` |
| User Auth Service | Resolves user session context | `userAuthService` |
| Remote Layout Service | Provides shared header/footer layout | `remoteLayoutService` |

## Steps

1. **Receives inventory request**: Browser or CDN sends `GET /hotels/:dealId/inventory` to `continuumGetawaysBrowseWebApp`.
   - From: Browser / CDN
   - To: `requestRouting`
   - Protocol: HTTP

2. **Dispatches to inventory controller**: `requestRouting` matches the route and dispatches to the hotel inventory page module.
   - From: `requestRouting`
   - To: `pageModules`
   - Protocol: Direct (in-process)

3. **Resolves user session**: `pageModules` calls `userAuthService` to load the user session context for subscription and personalisation state.
   - From: `apiClients`
   - To: `userAuthService`
   - Protocol: REST / HTTP

4. **Fetches Getaways deal metadata**: `apiClients` checks `memcacheCluster` for cached deal metadata; on miss, calls `continuumGetawaysApi` to retrieve hotel and deal details for `:dealId`.
   - From: `apiClients` via `travelBrowse_cacheAccess`
   - To: `memcacheCluster` (cache check) then `continuumGetawaysApi` (on miss)
   - Protocol: Memcached / REST HTTP

5. **Fetches real-time market-rate availability**: `apiClients` calls `marisApi` with deal and date parameters to retrieve live hotel availability and market-rate pricing. This call is not cached due to real-time pricing requirements.
   - From: `apiClients`
   - To: `marisApi`
   - Protocol: REST / HTTP

6. **Loads shared layout**: `apiClients` calls `remoteLayoutService` to retrieve header/footer layout fragments.
   - From: `apiClients`
   - To: `remoteLayoutService`
   - Protocol: REST / HTTP

7. **Assembles inventory view model**: `pageModules` merges deal metadata, real-time availability, pricing, and layout into the inventory page view model.
   - From: `pageModules`
   - To: `renderingEngine`
   - Protocol: Direct (in-process)

8. **Renders inventory HTML**: `renderingEngine` executes React 18 SSR for the inventory page component tree.
   - From: `renderingEngine`
   - To: Express response stream
   - Protocol: Direct (in-process)

9. **Returns HTML response**: `continuumGetawaysBrowseWebApp` sends the rendered HTML to the browser/CDN with appropriate cache-control headers.
   - From: `continuumGetawaysBrowseWebApp`
   - To: Browser / CDN
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `marisApi` unavailable or timeout | Render inventory page without live pricing; show fallback pricing | User sees hotel page without real-time availability; booking may be unavailable |
| `continuumGetawaysApi` error for deal | Return HTTP 404 or 500 | User sees error page |
| Deal ID not found in Getaways API | Return HTTP 404 | User sees 404 page |
| `memcacheCluster` unavailable | Bypass cache; call `continuumGetawaysApi` directly | Page renders with increased latency |
| `remoteLayoutService` error | Render without shared layout | Header/footer absent; inventory content displayed |
| Unhandled SSR render exception | Return HTTP 500 | User sees error page; alert triggered |

## Sequence Diagram

```
Browser/CDN              -> requestRouting:         GET /hotels/:dealId/inventory
requestRouting           -> pageModules:            Dispatch to inventory controller
pageModules              -> apiClients:             Fetch session, deal, pricing, layout
apiClients               -> userAuthService:        GET user session context
userAuthService          --> apiClients:            Session context
apiClients               -> memcacheCluster:        Check deal metadata cache
memcacheCluster          --> apiClients:            Cache miss
apiClients               -> continuumGetawaysApi:   GET /getaways/deals/:dealId
continuumGetawaysApi     --> apiClients:            Deal and hotel metadata
apiClients               -> memcacheCluster:        Write deal metadata cache entry
apiClients               -> marisApi:               GET hotel availability and pricing
marisApi                 --> apiClients:            Real-time availability and rates
apiClients               -> remoteLayoutService:    GET shared layout
remoteLayoutService      --> apiClients:            Layout HTML
pageModules              -> renderingEngine:        Assemble view model and render
renderingEngine          --> pageModules:           HTML string
continuumGetawaysBrowseWebApp --> Browser/CDN:     HTTP 200 + HTML
```

## Related

- Architecture dynamic view: `dynamic-market-rate-inventory-fetch`
- Related flows: [Browse Page Render](browse-page-render.md), [TripAdvisor Reviews Fetch](tripadvisor-reviews-fetch.md)
- See [Integrations](../integrations.md) for MARIS and Getaways API dependency details
- See [Flows Index](index.md) for all flows
