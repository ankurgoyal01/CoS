---
service: "sem-ui"
title: "Attribution Analysis Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "attribution-analysis"
flow_type: synchronous
trigger: "SEM operator navigates to the Attribution Lens page"
participants:
  - "SEM Operator (browser)"
  - "continuumSemUiWebApp"
  - "gpnDataApi"
architecture_ref: "dynamic-sem-ui-attribution-analysis"
---

# Attribution Analysis Flow

## Summary

This flow allows SEM operators to analyze order attribution data through the Attribution Lens. The operator loads the `/attribution-lens` page, and the Preact UI fetches attribution order data via the I-Tier server-side proxy, which calls the GPN Data API. The flow is read-only and on-demand — no writes are made to the attribution data source.

## Trigger

- **Type**: user-action
- **Source**: SEM operator loading or querying the `/attribution-lens` page
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEM Operator | Reviews attribution order data | — |
| SEM Admin UI | Serves the page and proxies attribution data requests | `continuumSemUiWebApp` |
| GPN Data API | Supplies order attribution data | `gpnDataApi` |

## Steps

1. **Loads Attribution Lens page**: SEM operator navigates browser to `/attribution-lens`.
   - From: Browser
   - To: `continuumSemUiWebApp`
   - Protocol: HTTPS

2. **Serves Preact application**: I-Tier server responds with the Attribution Lens page HTML and Preact bundle assets.
   - From: `continuumSemUiWebApp`
   - To: Browser
   - Protocol: HTTPS

3. **Requests attribution order data**: Preact UI sends a query for attribution data (optionally with filter parameters).
   - From: Browser (Preact UI)
   - To: `continuumSemUiWebApp` at `/proxy/attribution/orders`
   - Protocol: HTTPS/JSON

4. **Proxies attribution request upstream**: I-Tier server forwards the request to GPN Data API.
   - From: `continuumSemUiWebApp`
   - To: `gpnDataApi`
   - Protocol: HTTP/JSON

5. **Returns attribution data**: GPN Data API responds with order attribution records.
   - From: `gpnDataApi`
   - To: `continuumSemUiWebApp`
   - Protocol: HTTP/JSON

6. **Returns proxied response**: I-Tier server forwards the upstream response to the browser.
   - From: `continuumSemUiWebApp`
   - To: Browser (Preact UI)
   - Protocol: HTTPS/JSON

7. **Renders attribution analysis**: Preact UI displays attribution data for the operator to review.
   - From: Browser (Preact UI)
   - To: SEM Operator
   - Protocol: browser rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GPN Data API unreachable | I-Tier proxy returns upstream error status | Attribution Lens page shows error; other pages unaffected |
| No data for query parameters | GPN Data API returns empty result set | UI shows empty state |
| Authentication failure | `itier-user-auth` rejects session | Operator redirected to login |

## Sequence Diagram

```
SEM Operator -> continuumSemUiWebApp: GET /attribution-lens
continuumSemUiWebApp -> SEM Operator: Preact app HTML + JS bundle
SEM Operator -> continuumSemUiWebApp: GET /proxy/attribution/orders
continuumSemUiWebApp -> gpnDataApi: GET attribution order data
gpnDataApi --> continuumSemUiWebApp: attribution records
continuumSemUiWebApp --> SEM Operator: proxied attribution data
SEM Operator -> SEM Operator: Reviews attribution analysis in UI
```

## Related

- Architecture dynamic view: `dynamic-sem-ui-attribution-analysis`
- Related flows: [Keyword Management](keyword-management.md), [Denylist Management](denylist-management.md)
