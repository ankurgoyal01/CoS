---
service: "deal"
title: "Cache Refresh"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cache-refresh"
flow_type: scheduled
trigger: "Akamai CDN TTL expiry or cache invalidation event"
participants:
  - "Akamai CDN"
  - "dealWebApp"
  - "Groupon V2 APIs"
  - "GraphQL APIs"
architecture_ref: "dynamic-continuum-cache-refresh"
---

# Cache Refresh

## Summary

The cache refresh flow is triggered when the Akamai CDN edge cache for a deal page URL expires or is explicitly invalidated. Akamai issues a fresh origin fetch to `dealWebApp`, which re-executes the full deal page load flow (parallel API calls + SSR render) and returns a fresh HTML response. The updated response is then cached at the edge for subsequent consumer requests.

## Trigger

- **Type**: schedule / event
- **Source**: Akamai CDN TTL expiry on a cached deal page URL, or an explicit cache purge/invalidation triggered by operations or a deal update event
- **Frequency**: Per TTL cycle per deal URL; frequency depends on CDN TTL configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Akamai CDN | Detects cache miss; issues origin fetch; caches fresh response | N/A (external CDN) |
| Deal Web App | Receives origin fetch request; re-renders deal page | `dealWebApp` |
| Groupon V2 APIs | Provide fresh deal, pricing, merchant, wishlist data | > No evidence found in codebase. |
| GraphQL APIs | Provide fresh supplemental data | > No evidence found in codebase. |

## Steps

1. **Cache Miss / Expiry**: Akamai CDN determines the cached response for a deal page URL has expired (TTL elapsed) or has been explicitly purged.
   - From: `Akamai CDN` (internal)
   - To: `Akamai CDN` (internal)
   - Protocol: CDN cache management

2. **Origin Fetch**: Akamai sends `GET /deals/:deal-permalink` to `dealWebApp` origin to retrieve a fresh page render.
   - From: `Akamai CDN`
   - To: `dealWebApp`
   - Protocol: HTTP GET

3. **Full Deal Page Load**: `dealWebApp` executes the full [Deal Page Load](deal-page-load.md) flow — parallel API fetches + SSR render.
   - From: `dealWebApp`
   - To: Groupon V2 APIs, GraphQL APIs, etc.
   - Protocol: REST/HTTP, GraphQL/HTTP

4. **Return Fresh Response**: `dealWebApp` returns the freshly rendered HTML to Akamai.
   - From: `dealWebApp`
   - To: `Akamai CDN`
   - Protocol: HTTP 200 (HTML)

5. **Cache Update**: Akamai stores the fresh response in its edge cache and serves it to the consumer who triggered the cache miss (and all subsequent consumers until next TTL expiry).
   - From: `Akamai CDN` (internal)
   - To: `Akamai CDN` (internal)
   - Protocol: CDN cache management

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `dealWebApp` returns 5xx on origin fetch | Akamai may serve stale cached response (if configured) or propagate error to consumer | Stale deal page or error page served |
| Downstream API unavailable during origin fetch | `dealWebApp` renders partial or error page | Partial/error response cached (may be short-TTL) |

## Sequence Diagram

```
Akamai -> Akamai: TTL expired for /deals/:deal-permalink
Akamai -> dealWebApp: GET /deals/:deal-permalink (origin fetch)
dealWebApp -> V2APIs: parallel API calls (deal, pricing, merchant...)
V2APIs --> dealWebApp: data responses
dealWebApp -> dealWebApp: SSR render HTML
dealWebApp --> Akamai: HTTP 200 HTML (fresh render)
Akamai -> Akamai: store in edge cache
Akamai --> Consumer: serve cached HTML response
```

## Related

- Architecture dynamic view: `dynamic-continuum-cache-refresh`
- Related flows: [Deal Page Load](deal-page-load.md)
