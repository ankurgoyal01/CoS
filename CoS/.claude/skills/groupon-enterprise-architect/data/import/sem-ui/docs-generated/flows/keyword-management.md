---
service: "sem-ui"
title: "Keyword Management Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "keyword-management"
flow_type: synchronous
trigger: "SEM operator interacts with the Keyword Manager page"
participants:
  - "SEM Operator (browser)"
  - "continuumSemUiWebApp"
  - "semKeywordsService"
architecture_ref: "dynamic-sem-ui-keyword-management"
---

# Keyword Management Flow

## Summary

This flow enables SEM operators to view and modify keyword assignments for a specific deal permalink. The operator interacts with the `/keyword-manager` page; the Preact UI sends requests to the I-Tier server-side proxy, which forwards them to the SEM Keywords Service. The flow is synchronous and request-driven with no background processing.

## Trigger

- **Type**: user-action
- **Source**: SEM operator submitting a keyword read or write action on `/keyword-manager`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEM Operator | Initiates keyword lookup and modification | — |
| SEM Admin UI | Serves the page and proxies keyword API calls | `continuumSemUiWebApp` |
| SEM Keywords Service | Stores and returns keyword data per deal permalink | `semKeywordsService` |

## Steps

1. **Loads Keyword Manager page**: SEM operator navigates browser to `/keyword-manager`.
   - From: Browser
   - To: `continuumSemUiWebApp`
   - Protocol: HTTPS

2. **Serves Preact application**: I-Tier server responds with the Keyword Manager page HTML and Preact bundle assets.
   - From: `continuumSemUiWebApp`
   - To: Browser
   - Protocol: HTTPS

3. **Requests keyword data**: Preact UI fetches keyword data for a given deal permalink.
   - From: Browser (Preact UI)
   - To: `continuumSemUiWebApp` at `/proxy/keyword/deals/{permalink}/keywords`
   - Protocol: HTTPS/JSON

4. **Proxies keyword request upstream**: I-Tier server forwards the request to SEM Keywords Service.
   - From: `continuumSemUiWebApp`
   - To: `semKeywordsService`
   - Protocol: HTTP/JSON

5. **Returns keyword data**: SEM Keywords Service responds with keyword list for the permalink.
   - From: `semKeywordsService`
   - To: `continuumSemUiWebApp`
   - Protocol: HTTP/JSON

6. **Returns proxied response**: I-Tier server forwards the upstream response to the browser.
   - From: `continuumSemUiWebApp`
   - To: Browser (Preact UI)
   - Protocol: HTTPS/JSON

7. **Operator submits keyword update** (write path): Operator adds or removes keywords and submits the form.
   - From: Browser (Preact UI)
   - To: `continuumSemUiWebApp` at `/proxy/keyword/deals/{permalink}/keywords`
   - Protocol: HTTPS/JSON (POST/PUT/DELETE)

8. **Proxies write request upstream**: I-Tier server forwards the mutation to SEM Keywords Service.
   - From: `continuumSemUiWebApp`
   - To: `semKeywordsService`
   - Protocol: HTTP/JSON

9. **Confirms write and returns updated data**: SEM Keywords Service persists the change and responds.
   - From: `semKeywordsService`
   - To: `continuumSemUiWebApp` -> Browser
   - Protocol: HTTP/JSON -> HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SEM Keywords Service unreachable | I-Tier proxy returns upstream error status | Keyword Manager page shows error; other pages unaffected |
| Invalid permalink supplied | SEM Keywords Service returns 4xx | Error forwarded to browser UI |
| Authentication failure | `itier-user-auth` rejects session | Operator redirected to login |

## Sequence Diagram

```
SEM Operator -> continuumSemUiWebApp: GET /keyword-manager
continuumSemUiWebApp -> SEM Operator: Preact app HTML + JS bundle
SEM Operator -> continuumSemUiWebApp: GET /proxy/keyword/deals/{permalink}/keywords
continuumSemUiWebApp -> semKeywordsService: GET keywords for permalink
semKeywordsService --> continuumSemUiWebApp: keyword list
continuumSemUiWebApp --> SEM Operator: proxied keyword list
SEM Operator -> continuumSemUiWebApp: POST /proxy/keyword/deals/{permalink}/keywords (update)
continuumSemUiWebApp -> semKeywordsService: POST keyword update
semKeywordsService --> continuumSemUiWebApp: updated keyword data
continuumSemUiWebApp --> SEM Operator: proxied confirmation
```

## Related

- Architecture dynamic view: `dynamic-sem-ui-keyword-management`
- Related flows: [Denylist Management](denylist-management.md), [Attribution Analysis](attribution-analysis.md)
