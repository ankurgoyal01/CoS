---
service: "travel-browse"
title: "TripAdvisor Reviews Fetch"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "tripadvisor-reviews-fetch"
flow_type: synchronous
trigger: "HTTP GET request to /getaways/tripadvisor"
participants:
  - "continuumGetawaysBrowseWebApp"
  - "requestRouting"
  - "pageModules"
  - "apiClients"
  - "travelBrowse_cacheAccess"
  - "memcacheCluster"
  - "continuumGetawaysApi"
architecture_ref: "dynamic-tripadvisor-reviews-fetch"
---

# TripAdvisor Reviews Fetch

## Summary

The TripAdvisor reviews fetch flow handles requests to `/getaways/tripadvisor`, returning TripAdvisor review data for a hotel property. The service retrieves review content from the Getaways API (which acts as a proxy or aggregator for TripAdvisor data), caches the response in Memcache, and returns a JSON payload used to hydrate the TripAdvisor reviews widget on hotel detail pages. This is a lightweight, focused endpoint with no full-page SSR.

## Trigger

- **Type**: user-action / widget initialisation
- **Source**: Browser-side React component fetching review data after initial page load, or direct API call
- **Frequency**: Per-request (on-demand); responses are cacheable in Memcache

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Browse Web App | Handles the TripAdvisor endpoint and orchestrates data fetch | `continuumGetawaysBrowseWebApp` |
| Routing & Controllers | Receives HTTP request and dispatches to TripAdvisor handler | `requestRouting` |
| Page Modules | Coordinates the review data fetch and response assembly | `pageModules` |
| API Client Integrations | Calls Getaways API to retrieve TripAdvisor review data | `apiClients` |
| Cache Access | Checks and populates Memcache for TripAdvisor responses | `travelBrowse_cacheAccess` |
| Memcache Cluster | Stores and returns cached TripAdvisor review responses | `memcacheCluster` |
| Getaways API | Provides TripAdvisor review data for the requested hotel property | `continuumGetawaysApi` |

## Steps

1. **Receives TripAdvisor request**: Browser widget or client sends `GET /getaways/tripadvisor` (with hotel property identifier as query parameter) to `continuumGetawaysBrowseWebApp`.
   - From: Browser (React component) / API consumer
   - To: `requestRouting`
   - Protocol: HTTP

2. **Dispatches to TripAdvisor handler**: `requestRouting` matches the route and dispatches to the TripAdvisor page module handler.
   - From: `requestRouting`
   - To: `pageModules`
   - Protocol: Direct (in-process)

3. **Checks response cache**: `travelBrowse_cacheAccess` looks up the TripAdvisor response in `memcacheCluster` using a cache key derived from the hotel property identifier.
   - From: `travelBrowse_cacheAccess`
   - To: `memcacheCluster`
   - Protocol: Memcached

4. **Fetches TripAdvisor data from Getaways API** (cache miss path): `apiClients` calls `continuumGetawaysApi` via `itier-getaways-client` to retrieve TripAdvisor review data for the hotel property.
   - From: `apiClients`
   - To: `continuumGetawaysApi`
   - Protocol: REST / HTTP

5. **Populates Memcache**: `travelBrowse_cacheAccess` writes the Getaways API response to `memcacheCluster` under the property cache key.
   - From: `travelBrowse_cacheAccess`
   - To: `memcacheCluster`
   - Protocol: Memcached

6. **Returns review data**: `continuumGetawaysBrowseWebApp` serialises the TripAdvisor review payload and returns it to the browser widget caller.
   - From: `continuumGetawaysBrowseWebApp`
   - To: Browser
   - Protocol: HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumGetawaysApi` unavailable | Return HTTP 500 or empty review payload | TripAdvisor widget does not render; rest of page unaffected |
| Hotel property not found in Getaways API | Return HTTP 404 or empty payload | Widget renders empty state |
| `memcacheCluster` unavailable | Bypass cache; call `continuumGetawaysApi` directly | Reviews still returned; increased latency |
| Getaways API returns malformed TripAdvisor data | Return HTTP 500 | Widget renders error state |

## Sequence Diagram

```
Browser (widget)         -> requestRouting:          GET /getaways/tripadvisor?propertyId=...
requestRouting           -> pageModules:             Dispatch to TripAdvisor handler
pageModules              -> travelBrowse_cacheAccess: Check Memcache for property key
travelBrowse_cacheAccess -> memcacheCluster:         GET cache key
memcacheCluster          --> travelBrowse_cacheAccess: Cache miss
travelBrowse_cacheAccess --> pageModules:            No cached data
pageModules              -> apiClients:              Fetch TripAdvisor data
apiClients               -> continuumGetawaysApi:    GET TripAdvisor reviews for property
continuumGetawaysApi     --> apiClients:             Review data payload
apiClients               -> travelBrowse_cacheAccess: Store response
travelBrowse_cacheAccess -> memcacheCluster:         SET cache key with TTL
pageModules              --> continuumGetawaysBrowseWebApp: Assembled review payload
continuumGetawaysBrowseWebApp --> Browser (widget):  HTTP 200 + JSON reviews
```

## Related

- Architecture dynamic view: `dynamic-tripadvisor-reviews-fetch`
- Related flows: [Market-Rate Inventory Fetch](market-rate-inventory-fetch.md), [Browse Page Render](browse-page-render.md)
- See [Integrations](../integrations.md) for Getaways API dependency details
- See [Flows Index](index.md) for all flows
