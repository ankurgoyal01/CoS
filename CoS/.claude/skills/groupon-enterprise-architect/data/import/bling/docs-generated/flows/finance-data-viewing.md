---
service: "bling"
title: "Finance Data Viewing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "finance-data-viewing"
flow_type: synchronous
trigger: "User navigates to an invoice, contract, or payment list view in the browser"
participants:
  - "continuumBlingWebApp"
  - "blingNginx"
  - "continuumAccountingService"
architecture_ref: "dynamic-finance-operations-flow"
---

# Finance Data Viewing

## Summary

This flow describes how a finance or accounting staff member loads financial records — invoices, contracts, or payments — from the Accounting Service into the bling SPA. The browser issues REST requests that are intercepted by the Nginx proxy and forwarded to the Accounting Service. Returned data is rendered by the Ember.js application using `ember-table` components. The flow is stateless: bling holds no local cache and fetches data fresh on each navigation.

## Trigger

- **Type**: user-action
- **Source**: Finance or accounting staff member navigates to a list or detail view (invoices, contracts, payments) in the bling browser application
- **Frequency**: On-demand; per user navigation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance/Accounting Staff | Initiates navigation and views returned data | — |
| bling Web Application | Renders views; issues API requests via ember-ajax | `continuumBlingWebApp` |
| bling Nginx | Terminates browser connection; proxies `/api/*` to Accounting Service | `blingNginx` |
| Accounting Service | Queries and returns invoice, contract, or payment records | `continuumAccountingService` |

## Steps

1. **Navigates to list view**: Finance staff member navigates to the invoice, contract, or payment route in the bling SPA.
   - From: Browser (user)
   - To: `continuumBlingWebApp`
   - Protocol: Browser navigation (client-side Ember.js router)

2. **Ember model hook issues API request**: The Ember route's model hook triggers an ember-ajax GET request to the appropriate Accounting Service endpoint.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP — e.g., `GET /api/v1/invoices`, `GET /api/v2/invoices`, `GET /api/v3/invoices`, `GET /api/v1/contracts`, `GET /api/v1/payments`

3. **Nginx proxies request to Accounting Service**: `blingNginx` forwards the request upstream, attaching the OAuth bearer token from the Hybrid Boundary session.
   - From: `blingNginx`
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP with `Authorization: Bearer <okta_token>`

4. **Accounting Service queries and returns records**: Accounting Service queries its data store and returns the list of records as a JSON response.
   - From: `continuumAccountingService`
   - To: `blingNginx`
   - Protocol: REST/HTTP JSON response

5. **Nginx returns response to browser**: `blingNginx` passes the Accounting Service response back to the browser.
   - From: `blingNginx`
   - To: `continuumBlingWebApp`
   - Protocol: REST/HTTP JSON

6. **SPA renders list**: `continuumBlingWebApp` receives the JSON payload and renders the results in an `ember-table` data grid; finance staff views the records.
   - From: `continuumBlingWebApp`
   - To: Browser (user)
   - Protocol: Browser DOM rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Accounting Service returns 500 | ember-ajax surfaces HTTP error; Ember route transitions to error state | Error message displayed in UI; no data shown |
| Nginx returns 502/503 (Accounting Service unreachable) | Browser receives 502/503; ember-ajax rejects promise | Error state rendered in SPA; staff notified service is unavailable |
| OAuth token expired | Accounting Service returns 401; Hybrid Boundary redirect triggered | User redirected through Okta login flow; session renewed |
| Empty result set | Accounting Service returns 200 with empty array | Table rendered as empty; no error state |

## Sequence Diagram

```
FinanceStaff -> continuumBlingWebApp: Navigate to invoice/contract/payment route
continuumBlingWebApp -> blingNginx: GET /api/v1/invoices (or /v2, /v3, /contracts, /payments)
blingNginx -> continuumAccountingService: GET /api/v1/invoices (proxied, Bearer token attached)
continuumAccountingService --> blingNginx: 200 OK, JSON record list
blingNginx --> continuumBlingWebApp: 200 OK, JSON record list
continuumBlingWebApp --> FinanceStaff: Render ember-table with records
```

## Related

- Architecture dynamic view: `dynamic-finance-operations-flow`
- Related flows: [Invoice Approval](invoice-approval.md), [Contract Management](contract-management.md), [Search and Batch](search-and-batch.md)
