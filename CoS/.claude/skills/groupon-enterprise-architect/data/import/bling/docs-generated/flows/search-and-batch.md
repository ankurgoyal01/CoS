---
service: "bling"
title: "Search and Batch"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "search-and-batch"
flow_type: synchronous
trigger: "User submits a search query or navigates to the batch status view"
participants:
  - "continuumBlingWebApp"
  - "blingNginx"
  - "continuumAccountingService"
architecture_ref: "dynamic-finance-operations-flow"
---

# Search and Batch

## Summary

This flow covers the cross-entity search and payment batch operations in bling. The Search Module allows finance staff to search across accounting records using the Accounting Service search endpoint. The Payment Module provides batch management views, allowing staff to list, create, and inspect payment batches. Both capabilities are serviced by the Accounting Service v1 API via the Nginx proxy.

## Trigger

- **Type**: user-action
- **Source**: Finance staff submits a search query in the Search Module, or navigates to the batch management section
- **Frequency**: On-demand; per user query or navigation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance Staff | Submits search criteria or navigates to batch views | — |
| bling Web Application | Constructs query parameters; issues GET/POST requests; renders results | `continuumBlingWebApp` |
| bling Nginx | Proxies `/api/v1/search` and `/api/v1/batches` to Accounting Service | `blingNginx` |
| Accounting Service | Executes cross-entity search; manages payment batch records | `continuumAccountingService` |

## Steps

### Search Sub-Flow

1. **Staff enters search criteria**: Staff types a query into the Search Module; `ember-select-2` drives filter selection.
   - From: Browser (user)
   - To: `continuumBlingWebApp`
   - Protocol: Browser input event

2. **Ember issues search GET request**: On form submit, the Search Module issues `GET /api/v1/search` with filter parameters as query string.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP GET with `Authorization: Bearer <okta_token>`

3. **Nginx proxies search request**: `blingNginx` forwards the GET to the Accounting Service.
   - From: `blingNginx`
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP GET

4. **Accounting Service executes search and returns results**: Performs cross-entity search across invoices, contracts, payments, and batches; returns matching records as JSON.
   - From: `continuumAccountingService`
   - To: `continuumBlingWebApp` (via `blingNginx`)
   - Protocol: REST/HTTP JSON

5. **SPA renders search results**: The Search Module renders the results in an `ember-table` data grid.
   - From: `continuumBlingWebApp`
   - To: Browser (user)
   - Protocol: Browser DOM rendering

### Batch Sub-Flow

6. **Staff navigates to batch management**: Staff navigates to the batch section; Ember fires `GET /api/v1/batches`.
   - From: `continuumBlingWebApp`
   - To: `continuumAccountingService` (via `blingNginx`)
   - Protocol: REST/HTTP GET

7. **Accounting Service returns batch list**: Returns the list of payment batch records.
   - From: `continuumAccountingService`
   - To: `continuumBlingWebApp` (via `blingNginx`)
   - Protocol: REST/HTTP JSON

8. **Staff creates a new batch (optional)**: Staff submits a new batch via `POST /api/v1/batches`.
   - From: `continuumBlingWebApp`
   - To: `continuumAccountingService` (via `blingNginx`)
   - Protocol: REST/HTTP POST JSON

9. **Staff views batch detail (optional)**: Staff clicks a batch to load `GET /api/v1/batches/:id`.
   - From: `continuumBlingWebApp`
   - To: `continuumAccountingService` (via `blingNginx`)
   - Protocol: REST/HTTP GET

10. **SPA renders batch detail**: Batch detail view is rendered, showing batch status and included records.
    - From: `continuumBlingWebApp`
    - To: Browser (user)
    - Protocol: Browser DOM rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Search returns empty results | Accounting Service returns 200 with empty array | Empty table rendered; no error state |
| Accounting Service returns 500 on search | ember-ajax rejects; error state displayed | No results shown; staff must retry |
| POST /api/v1/batches fails (422 validation) | Error surfaced in UI | Batch not created; staff sees validation error |
| Nginx 502/503 | All requests fail | Search and batch views unavailable |
| System errors (`GET /api/v1/system-errors`) return 500 | Error state in system error review view | Staff cannot view system errors; no impact on other modules |

## Sequence Diagram

```
FinanceStaff -> continuumBlingWebApp: Submit search query
continuumBlingWebApp -> blingNginx: GET /api/v1/search?<filters>
blingNginx -> continuumAccountingService: GET /api/v1/search?<filters> (proxied)
continuumAccountingService --> blingNginx: 200 OK, search results JSON
blingNginx --> continuumBlingWebApp: 200 OK, search results JSON
continuumBlingWebApp --> FinanceStaff: Render results in ember-table

FinanceStaff -> continuumBlingWebApp: Navigate to batch management
continuumBlingWebApp -> blingNginx: GET /api/v1/batches
blingNginx -> continuumAccountingService: GET /api/v1/batches (proxied)
continuumAccountingService --> blingNginx: 200 OK, batch list JSON
blingNginx --> continuumBlingWebApp: 200 OK, batch list JSON
continuumBlingWebApp --> FinanceStaff: Render batch list
```

## Related

- Architecture dynamic view: `dynamic-finance-operations-flow`
- Related flows: [Finance Data Viewing](finance-data-viewing.md), [Invoice Approval](invoice-approval.md)
