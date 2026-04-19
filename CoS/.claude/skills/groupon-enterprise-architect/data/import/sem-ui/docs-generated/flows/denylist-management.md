---
service: "sem-ui"
title: "Denylist Management Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "denylist-management"
flow_type: synchronous
trigger: "SEM operator interacts with the Denylisting page"
participants:
  - "SEM Operator (browser)"
  - "continuumSemUiWebApp"
  - "continuumSemBlacklistService"
architecture_ref: "dynamic-sem-ui-denylist-management"
---

# Denylist Management Flow

## Summary

This flow enables SEM operators to view and administer the SEM keyword denylist (blacklist). The operator uses the `/denylisting` page to review current denylist entries and add or remove suppressed keywords. The Preact UI calls the I-Tier proxy, which forwards all operations to the SEM Blacklist Service (`continuumSemBlacklistService`). This is the only flow with a fully modeled architecture relationship in the central Structurizr workspace.

## Trigger

- **Type**: user-action
- **Source**: SEM operator performing a denylist read or write action on `/denylisting`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEM Operator | Initiates denylist view and modification | — |
| SEM Admin UI | Serves the page and proxies denylist API calls | `continuumSemUiWebApp` |
| SEM Blacklist Service | Persists and returns denylist entries | `continuumSemBlacklistService` |

## Steps

1. **Loads Denylisting page**: SEM operator navigates browser to `/denylisting`.
   - From: Browser
   - To: `continuumSemUiWebApp`
   - Protocol: HTTPS

2. **Serves Preact application**: I-Tier server responds with the Denylisting page HTML and Preact bundle assets.
   - From: `continuumSemUiWebApp`
   - To: Browser
   - Protocol: HTTPS

3. **Requests denylist entries**: Preact UI fetches current denylist state.
   - From: Browser (Preact UI)
   - To: `continuumSemUiWebApp` at `/proxy/denylist`
   - Protocol: HTTPS/JSON

4. **Proxies denylist request upstream**: I-Tier server forwards the request to SEM Blacklist Service.
   - From: `continuumSemUiWebApp`
   - To: `continuumSemBlacklistService`
   - Protocol: HTTP/JSON

5. **Returns denylist entries**: SEM Blacklist Service responds with current denylist data.
   - From: `continuumSemBlacklistService`
   - To: `continuumSemUiWebApp`
   - Protocol: HTTP/JSON

6. **Returns proxied response**: I-Tier server forwards the upstream response to the browser.
   - From: `continuumSemUiWebApp`
   - To: Browser (Preact UI)
   - Protocol: HTTPS/JSON

7. **Operator submits denylist change** (write path): Operator adds or removes a denylist entry.
   - From: Browser (Preact UI)
   - To: `continuumSemUiWebApp` at `/proxy/denylist`
   - Protocol: HTTPS/JSON (POST/DELETE)

8. **Proxies write request upstream**: I-Tier server forwards the mutation to SEM Blacklist Service.
   - From: `continuumSemUiWebApp`
   - To: `continuumSemBlacklistService`
   - Protocol: HTTP/JSON

9. **Confirms change and returns updated state**: SEM Blacklist Service persists the entry and responds.
   - From: `continuumSemBlacklistService`
   - To: `continuumSemUiWebApp` -> Browser
   - Protocol: HTTP/JSON -> HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SEM Blacklist Service unreachable | I-Tier proxy returns upstream error status | Denylisting page shows error; other pages unaffected |
| Duplicate denylist entry | SEM Blacklist Service returns 4xx/409 | Error forwarded to browser UI |
| Authentication failure | `itier-user-auth` rejects session | Operator redirected to login |

## Sequence Diagram

```
SEM Operator -> continuumSemUiWebApp: GET /denylisting
continuumSemUiWebApp -> SEM Operator: Preact app HTML + JS bundle
SEM Operator -> continuumSemUiWebApp: GET /proxy/denylist
continuumSemUiWebApp -> continuumSemBlacklistService: GET denylist entries
continuumSemBlacklistService --> continuumSemUiWebApp: denylist entry list
continuumSemUiWebApp --> SEM Operator: proxied denylist entries
SEM Operator -> continuumSemUiWebApp: POST /proxy/denylist (add entry)
continuumSemUiWebApp -> continuumSemBlacklistService: POST new denylist entry
continuumSemBlacklistService --> continuumSemUiWebApp: updated denylist state
continuumSemUiWebApp --> SEM Operator: proxied confirmation
```

## Related

- Architecture dynamic view: `dynamic-sem-ui-denylist-management`
- Related flows: [Keyword Management](keyword-management.md), [Attribution Analysis](attribution-analysis.md)
