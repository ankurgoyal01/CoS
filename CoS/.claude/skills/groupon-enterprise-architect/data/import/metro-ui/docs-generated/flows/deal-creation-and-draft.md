---
service: "metro-ui"
title: "Deal Creation and Draft"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-creation-and-draft"
flow_type: synchronous
trigger: "Merchant navigates to /merchant/center/draft"
participants:
  - "continuumMetroUiService"
  - "metroUi_routing"
  - "metroUi_pageRendering"
  - "metroUi_integrationAdapters"
  - "metroUi_frontendBundles"
  - "apiProxy"
  - "continuumDealManagementApi"
  - "googleTagManager"
architecture_ref: "dynamic-metro-ui-draft-edit-flow"
---

# Deal Creation and Draft

## Summary

This flow covers the primary merchant workflow of creating a new deal or resuming an existing draft. The merchant navigates to `/merchant/center/draft`, Metro UI fetches the deal context from the backend, renders the server-side page with the deal form, and serves the frontend bundles that power the interactive deal editor. All deal data is read from and written to `continuumDealManagementApi` via `apiProxy`.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates browser to `/merchant/center/draft`
- **Frequency**: On-demand (per merchant session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (Browser) | Initiates the flow; interacts with the deal creation form | External user |
| Routing and Controllers | Receives the HTTP request and dispatches to page rendering and integration actions | `metroUi_routing` |
| Integration Adapters | Fetches deal context and merchant data from backend services | `metroUi_integrationAdapters` |
| API Proxy | Routes backend API requests to Deal Management API | `apiProxy` |
| Deal Management API | Provides deal draft data and persists deal changes | `continuumDealManagementApi` |
| Page Rendering | Builds the page model and renders the HTML response | `metroUi_pageRendering` |
| Frontend Bundles | Serves interactive React/Preact JS/CSS bundles for the deal editor | `metroUi_frontendBundles` |
| Google Tag Manager | Loads browser-side analytics tags | `googleTagManager` |

## Steps

1. **Receive Page Request**: Merchant browser sends GET request to `/merchant/center/draft`.
   - From: Merchant Browser
   - To: `metroUi_routing`
   - Protocol: HTTPS

2. **Dispatch to Integration Adapters**: The route handler calls the integration adapters to fetch deal context and merchant data.
   - From: `metroUi_routing`
   - To: `metroUi_integrationAdapters`
   - Protocol: Internal

3. **Request Merchant and Deal Context**: Integration adapters request merchant and deal data via the API proxy.
   - From: `metroUi_integrationAdapters`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

4. **Forward to Deal Management API**: API proxy forwards the deal-management request to the Deal Management API.
   - From: `apiProxy`
   - To: `continuumDealManagementApi`
   - Protocol: HTTPS/JSON

5. **Return Deal Data**: Deal Management API returns deal draft and merchant context.
   - From: `continuumDealManagementApi`
   - To: `metroUi_integrationAdapters` (via `apiProxy`)
   - Protocol: HTTPS/JSON

6. **Build Page Model**: Integration adapters return data to routing; routing invokes page rendering with the assembled page model.
   - From: `metroUi_routing`
   - To: `metroUi_pageRendering`
   - Protocol: Internal

7. **Render HTML Response**: Page rendering assembles the HTML page, embedding the deal form data and layout, and references frontend bundle assets.
   - From: `metroUi_pageRendering`
   - To: Merchant Browser (via `metroUi_frontendBundles` assets)
   - Protocol: HTTPS (HTML + JS/CSS)

8. **Load Analytics Tags**: The browser-loaded frontend bundle triggers Google Tag Manager to load analytics tracking tags.
   - From: `metroUi_frontendBundles`
   - To: `googleTagManager`
   - Protocol: HTTPS (browser-side)

9. **Interactive Editing — Save Draft**: As the merchant edits the deal form, changes are submitted back to Metro UI, which updates the deal via `continuumDealManagementApi` through `apiProxy`.
   - From: Merchant Browser
   - To: `metroUi_integrationAdapters` -> `apiProxy` -> `continuumDealManagementApi`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `apiProxy` unreachable | itier-server returns HTTP error response | Deal creation page fails to load; merchant sees error state |
| `continuumDealManagementApi` returns error | Error propagated through `apiProxy` to integration adapters | Page rendering displays error; draft data unavailable |
| Frontend bundle load failure | Browser fallback behavior | Interactive editor unavailable; page may render partially |
| Google Tag Manager timeout | Browser-side failure; non-blocking | Analytics tags not loaded; deal creation functionality unaffected |

## Sequence Diagram

```
Merchant Browser -> metroUi_routing: GET /merchant/center/draft
metroUi_routing -> metroUi_integrationAdapters: Fetch deal context
metroUi_integrationAdapters -> apiProxy: Request merchant and deal context (HTTPS/JSON)
apiProxy -> continuumDealManagementApi: Forward deal-management request (HTTPS/JSON)
continuumDealManagementApi --> apiProxy: Return deal data
apiProxy --> metroUi_integrationAdapters: Return deal data
metroUi_integrationAdapters --> metroUi_routing: Return assembled page model
metroUi_routing -> metroUi_pageRendering: Build and render page
metroUi_pageRendering --> Merchant Browser: HTML + JS/CSS (deal creation form)
Merchant Browser -> googleTagManager: Load analytics tags (HTTPS, browser-side)
```

## Related

- Architecture dynamic view: `dynamic-metro-ui-draft-edit-flow`
- Related flows: [AI Content Generation](ai-content-generation.md), [Deal Publication](deal-publication.md), [Location and Service Area Management](location-service-area-management.md)
