---
service: "travel-browse"
title: "Client-Side Experimentation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "client-side-experimentation"
flow_type: synchronous
trigger: "SSR request lifecycle — evaluated on every page render"
participants:
  - "continuumGetawaysBrowseWebApp"
  - "pageModules"
  - "apiClients"
  - "renderingEngine"
  - "optimizeService"
  - "userAuthService"
architecture_ref: "dynamic-client-side-experimentation"
---

# Client-Side Experimentation

## Summary

The client-side experimentation flow describes how travel-browse evaluates A/B experiment assignments and feature flags on every SSR request before rendering a page. The `itier-feature-flags` library (v3.3.0) communicates with the `optimizeService` to retrieve flag and experiment values for the current user and request context. The resulting assignments are embedded in the server-rendered HTML, ensuring the correct experiment variant is served consistently on first load without a client-side flicker.

## Trigger

- **Type**: SSR request lifecycle
- **Source**: Embedded within the browse-page-render and market-rate-inventory-fetch flows; fires on every incoming page request
- **Frequency**: Per-request (on-demand); flag evaluations are synchronous and blocking before render

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Browse Web App | Hosts the SSR pipeline in which experimentation occurs | `continuumGetawaysBrowseWebApp` |
| Page Modules | Initiates flag evaluation as part of page data assembly | `pageModules` |
| API Client Integrations | Calls `optimizeService` via `itier-feature-flags` | `apiClients` |
| Rendering Engine | Consumes flag/experiment values when rendering React components | `renderingEngine` |
| Optimize Service | Evaluates A/B assignments and returns flag values for the request context | `optimizeService` |
| User Auth Service | Provides user identity context used as the experiment subject | `userAuthService` |

## Steps

1. **Enters SSR pipeline**: An incoming HTTP request enters the SSR pipeline (as part of [Browse Page Render](browse-page-render.md) or [Market-Rate Inventory Fetch](market-rate-inventory-fetch.md)).
   - From: Browser / CDN
   - To: `pageModules`
   - Protocol: HTTP (upstream)

2. **Resolves user identity**: `pageModules` calls `userAuthService` to retrieve the user session context, which provides the subject identifier for experiment bucketing.
   - From: `apiClients`
   - To: `userAuthService`
   - Protocol: REST / HTTP

3. **Requests experiment and flag assignments**: `pageModules` calls `optimizeService` via `itier-feature-flags` 3.3.0, passing user context (user ID, session attributes, request metadata such as locale, device type, geo).
   - From: `apiClients`
   - To: `optimizeService`
   - Protocol: REST / HTTP

4. **Receives assignments**: `optimizeService` returns a map of feature flag values and A/B variant assignments for the request context.
   - From: `optimizeService`
   - To: `apiClients` / `pageModules`
   - Protocol: REST / HTTP (JSON response)

5. **Propagates flags to view model**: `pageModules` includes the flag and experiment assignment map in the page view model passed to `renderingEngine`.
   - From: `pageModules`
   - To: `renderingEngine`
   - Protocol: Direct (in-process)

6. **Renders with experiment variants**: `renderingEngine` uses the flag values to conditionally render the appropriate React component variants (e.g., new browse layout vs. control, alternate pricing display, etc.).
   - From: `renderingEngine`
   - To: HTML output
   - Protocol: Direct (in-process)

7. **Embeds assignments in HTML**: The rendered HTML includes the experiment assignment state, allowing client-side React hydration to continue with the same variant without flicker.
   - From: `renderingEngine`
   - To: Browser
   - Protocol: HTTP (embedded in HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `optimizeService` unavailable or timeout | `itier-feature-flags` falls back to default flag values | Default (control) experience rendered; no A/B divergence |
| `userAuthService` unavailable | Treat as anonymous user; bucket by session ID or request attributes | Experiment may not be personalised; default variant served |
| Malformed flag response from Optimize | Ignore malformed flags; use defaults | Default experience rendered for affected flags |
| Experiment definition not found | Return default flag value | Control variant rendered |

## Sequence Diagram

```
pageModules              -> apiClients:              Request user session for experiment subject
apiClients               -> userAuthService:         GET user session context
userAuthService          --> apiClients:             User identity and session attributes
apiClients               -> optimizeService:         GET flag/experiment assignments (user context)
optimizeService          --> apiClients:             Flag values and A/B variant assignments
apiClients               --> pageModules:            Assignments map
pageModules              -> renderingEngine:         View model with flag values embedded
renderingEngine          -> renderingEngine:         Render React variant per flag values
renderingEngine          --> pageModules:            HTML with embedded assignment state
```

## Related

- Architecture dynamic view: `dynamic-client-side-experimentation`
- Related flows: [Browse Page Render](browse-page-render.md), [Market-Rate Inventory Fetch](market-rate-inventory-fetch.md)
- See [Configuration](../configuration.md) for feature flag configuration details
- See [Integrations](../integrations.md) for Optimize Service dependency details
- See [Flows Index](index.md) for all flows
