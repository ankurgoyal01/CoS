---
service: "travel-browse"
title: "Browse Page Render"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "browse-page-render"
flow_type: synchronous
trigger: "HTTP GET request to /travel/:geo_slug/hotels"
participants:
  - "continuumGetawaysBrowseWebApp"
  - "requestRouting"
  - "pageModules"
  - "apiClients"
  - "travelBrowse_cacheAccess"
  - "renderingEngine"
  - "memcacheCluster"
  - "rapiApi"
  - "continuumGetawaysApi"
  - "geodetailsV2Api"
  - "lpapiPages"
  - "grouponV2Api"
  - "userAuthService"
  - "optimizeService"
  - "remoteLayoutService"
  - "grouponCdn"
architecture_ref: "dynamic-browse-page-render"
---

# Browse Page Render

## Summary

The browse page render flow is the primary SSR pipeline for Getaways hotel browse pages. When a browser or CDN edge node requests `/travel/:geo_slug/hotels`, the service resolves the geo slug, evaluates experiments, fetches deal data from multiple upstream APIs (with Memcache acceleration), assembles a page view model, and server-side renders a fully hydrated React HTML page for delivery. This is the highest-traffic flow in the service.

## Trigger

- **Type**: user-action / CDN cache miss
- **Source**: Browser navigation or CDN edge forwarding an uncached request to `continuumGetawaysBrowseWebApp`
- **Frequency**: Per-request (on-demand); CDN caches rendered HTML to reduce SSR frequency for popular geo-slugs

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Browse Web App | Orchestrates the full SSR pipeline | `continuumGetawaysBrowseWebApp` |
| Routing & Controllers | Receives HTTP request and dispatches to browse page controller | `requestRouting` |
| Page Modules | Coordinates data fetching and view model assembly | `pageModules` |
| API Client Integrations | Executes typed HTTP calls to downstream APIs | `apiClients` |
| Cache Access | Checks and populates Memcache for API responses | `travelBrowse_cacheAccess` |
| Rendering Engine | Executes React SSR to produce HTML | `renderingEngine` |
| Memcache Cluster | Stores and returns cached API responses | `memcacheCluster` |
| RAPI | Returns deal search results for the geo location | `rapiApi` |
| Getaways API | Returns Getaways-specific deal and hotel data | `continuumGetawaysApi` |
| Geodetails V2 API | Resolves geo slug to structured location metadata | `geodetailsV2Api` |
| LPAPI | Provides landing page content blocks | `lpapiPages` |
| Groupon V2 API | Returns Groupon platform data for page composition | `grouponV2Api` |
| User Auth Service | Resolves user session context from request cookie | `userAuthService` |
| Optimize Service | Returns experiment assignments and feature flag values | `optimizeService` |
| Remote Layout Service | Provides shared header/footer layout HTML | `remoteLayoutService` |
| Groupon CDN | Serves static JS/CSS assets to browser after HTML delivery | `grouponCdn` |

## Steps

1. **Receives browse request**: Browser or CDN sends `GET /travel/:geo_slug/hotels` to `continuumGetawaysBrowseWebApp`.
   - From: Browser / CDN
   - To: `requestRouting`
   - Protocol: HTTP

2. **Dispatches to page controller**: `requestRouting` matches the route and dispatches to the browse page module controller.
   - From: `requestRouting`
   - To: `pageModules`
   - Protocol: Direct (in-process)

3. **Resolves user session**: `pageModules` calls `userAuthService` to load session context from the incoming request cookie.
   - From: `apiClients`
   - To: `userAuthService`
   - Protocol: REST / HTTP

4. **Evaluates experiments and feature flags**: `pageModules` calls `optimizeService` via `itier-feature-flags` to resolve A/B assignments for the current user and request context.
   - From: `apiClients`
   - To: `optimizeService`
   - Protocol: REST / HTTP

5. **Resolves geo slug**: `pageModules` checks `travelBrowse_cacheAccess`/`memcacheCluster` for a cached geo resolution; on miss, calls `geodetailsV2Api` to resolve `:geo_slug` to structured location metadata.
   - From: `apiClients` via `travelBrowse_cacheAccess`
   - To: `memcacheCluster` (cache check) then `geodetailsV2Api` (on miss)
   - Protocol: Memcached / REST HTTP

6. **Fetches deal search results**: `apiClients` queries `rapiApi` with the resolved geo and browse parameters; checks `memcacheCluster` first, populates cache on successful response.
   - From: `apiClients` via `travelBrowse_cacheAccess`
   - To: `memcacheCluster` (cache check) then `rapiApi` (on miss)
   - Protocol: Memcached / REST HTTP

7. **Fetches Getaways inventory**: `apiClients` calls `continuumGetawaysApi` via `itier-getaways-client` to retrieve Getaways deal details and hotel metadata.
   - From: `apiClients`
   - To: `continuumGetawaysApi`
   - Protocol: REST / HTTP

8. **Fetches landing page content**: `apiClients` calls `lpapiPages` to retrieve any SEO and marketing content blocks for the geo-specific browse page.
   - From: `apiClients`
   - To: `lpapiPages`
   - Protocol: REST / HTTP

9. **Fetches Groupon V2 data**: `apiClients` calls `grouponV2Api` for any additional Groupon platform data required by the page module.
   - From: `apiClients`
   - To: `grouponV2Api`
   - Protocol: REST / HTTP

10. **Loads shared layout**: `pageModules` calls `remoteLayoutService` to retrieve shared header/footer HTML layout fragments.
    - From: `apiClients`
    - To: `remoteLayoutService`
    - Protocol: REST / HTTP

11. **Assembles view model**: `pageModules` combines geo metadata, deal results, Getaways data, landing page content, experiment assignments, and layout into a unified page view model.
    - From: `pageModules`
    - To: `renderingEngine`
    - Protocol: Direct (in-process)

12. **Renders HTML**: `renderingEngine` executes React 18 server-side rendering of the browse page component tree using the assembled view model.
    - From: `renderingEngine`
    - To: Express response stream
    - Protocol: Direct (in-process)

13. **Returns HTML response**: `continuumGetawaysBrowseWebApp` sends the rendered HTML with appropriate cache-control headers back to the browser/CDN.
    - From: `continuumGetawaysBrowseWebApp`
    - To: Browser / CDN
    - Protocol: HTTP

14. **Loads static assets**: Browser fetches JS/CSS bundles from `grouponCdn`.
    - From: Browser
    - To: `grouponCdn`
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `rapiApi` timeout or error | Render page with empty deal results | User sees browse page with no deal cards |
| `geodetailsV2Api` returns unknown geo | Return HTTP 404 | User sees 404 page |
| `continuumGetawaysApi` error | Render page with partial data | Getaways-specific deal details absent |
| `memcacheCluster` unavailable | Bypass cache; call APIs directly | Page renders correctly but with increased latency |
| `remoteLayoutService` error | Render page without shared layout | Header/footer absent; core content displayed |
| `optimizeService` error | Apply default experiment variants | Default experience served; no A/B divergence |
| `userAuthService` error | Treat as anonymous/unauthenticated user | Page renders for unauthenticated state |
| Unhandled SSR render exception | Return HTTP 500 with error page | User sees error page; alert triggered |

## Sequence Diagram

```
Browser/CDN         -> requestRouting:           GET /travel/:geo_slug/hotels
requestRouting      -> pageModules:              Dispatch to browse controller
pageModules         -> apiClients:               Resolve session, flags, geo, deals
apiClients          -> userAuthService:          GET user session context
userAuthService     --> apiClients:              Session context
apiClients          -> optimizeService:          GET experiment/flag assignments
optimizeService     --> apiClients:              Assignments and flag values
apiClients          -> memcacheCluster:          Check geo cache
memcacheCluster     --> apiClients:              Cache miss
apiClients          -> geodetailsV2Api:          GET /geo/:geo_slug
geodetailsV2Api     --> apiClients:              Geo metadata
apiClients          -> memcacheCluster:          Write geo cache entry
apiClients          -> memcacheCluster:          Check RAPI results cache
memcacheCluster     --> apiClients:              Cache miss
apiClients          -> rapiApi:                  GET deals for geo
rapiApi             --> apiClients:              Deal list
apiClients          -> memcacheCluster:          Write RAPI cache entry
apiClients          -> continuumGetawaysApi:     GET Getaways inventory
continuumGetawaysApi --> apiClients:             Getaways deal data
apiClients          -> lpapiPages:              GET landing page content
lpapiPages          --> apiClients:             Content blocks
apiClients          -> grouponV2Api:            GET Groupon V2 data
grouponV2Api        --> apiClients:             Platform data
apiClients          -> remoteLayoutService:     GET shared layout
remoteLayoutService --> apiClients:             Layout HTML
pageModules         -> renderingEngine:         Assemble view model and render
renderingEngine     --> pageModules:            HTML string
continuumGetawaysBrowseWebApp --> Browser/CDN: HTTP 200 + HTML
Browser             -> grouponCdn:              GET /assets/*.js, *.css
grouponCdn          --> Browser:               Static assets
```

## Related

- Architecture dynamic view: `dynamic-browse-page-render`
- Related flows: [Market-Rate Inventory Fetch](market-rate-inventory-fetch.md), [Client-Side Experimentation](client-side-experimentation.md), [Localization and i18n](localization-i18n.md)
- See [Flows Index](index.md) for all flows
