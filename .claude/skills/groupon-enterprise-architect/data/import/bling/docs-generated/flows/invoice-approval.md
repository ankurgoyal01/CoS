---
service: "bling"
title: "Invoice Approval"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "invoice-approval"
flow_type: synchronous
trigger: "Finance staff submits an approval or rejection action on an invoice detail view"
participants:
  - "continuumBlingWebApp"
  - "blingNginx"
  - "continuumAccountingService"
architecture_ref: "dynamic-finance-operations-flow"
---

# Invoice Approval

## Summary

This flow covers the invoice approval workflow in bling, where a finance staff member reviews an invoice and submits an approve or reject action. The SPA sends a PATCH request through the Nginx proxy to the Accounting Service v3 API, which updates the invoice status record. The updated status is reflected in the UI upon successful response. The Accounting Service owns all approval business logic; bling is responsible only for capturing the user intent and displaying the result.

## Trigger

- **Type**: user-action
- **Source**: Finance staff member clicks the Approve or Reject button on an invoice detail view
- **Frequency**: On-demand; per invoice action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance Staff | Initiates approve or reject action | — |
| bling Web Application | Captures action; constructs PATCH request; renders result | `continuumBlingWebApp` |
| bling Nginx | Proxies PATCH request to Accounting Service | `blingNginx` |
| Accounting Service | Validates and persists invoice status transition | `continuumAccountingService` |

## Steps

1. **Views invoice detail**: Finance staff navigates to an invoice detail view, loading the invoice record via `GET /api/v1/invoices/:id` or `GET /api/v3/invoices`.
   - From: `continuumBlingWebApp`
   - To: `continuumAccountingService` (via `blingNginx`)
   - Protocol: REST/HTTP GET

2. **Submits approval action**: Staff clicks Approve or Reject; the Ember component captures the action and triggers an ember-ajax PATCH request.
   - From: Browser (user)
   - To: `continuumBlingWebApp`
   - Protocol: Browser user interaction

3. **Ember issues PATCH request**: The application sends `PATCH /api/v1/invoices/:id` or `PATCH /api/v3/invoices` with the new status in the request body.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP PATCH, `Content-Type: application/json`, `Authorization: Bearer <okta_token>`

4. **Nginx proxies PATCH to Accounting Service**: `blingNginx` forwards the PATCH request to the Accounting Service upstream.
   - From: `blingNginx`
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP PATCH with Bearer token

5. **Accounting Service validates and persists status transition**: Accounting Service validates the transition (e.g., draft -> approved, approved -> rejected), applies business rules, and persists the updated invoice status.
   - From: `continuumAccountingService` (internal operation)
   - To: Accounting Service data store
   - Protocol: Internal

6. **Accounting Service returns updated invoice**: Returns 200 with the updated invoice record JSON.
   - From: `continuumAccountingService`
   - To: `blingNginx` -> `continuumBlingWebApp`
   - Protocol: REST/HTTP JSON

7. **SPA updates invoice view**: The Ember component updates the displayed invoice status to reflect the new approved/rejected state.
   - From: `continuumBlingWebApp`
   - To: Browser (user)
   - Protocol: Browser DOM update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Accounting Service returns 422 (invalid transition) | ember-ajax rejects; error message surfaced in UI | Invoice status unchanged; staff sees validation error |
| Accounting Service returns 500 | ember-ajax rejects; generic error displayed | Invoice status unchanged; staff notified to retry |
| Nginx 502/503 (Accounting Service unreachable) | PATCH fails; error state rendered | Invoice status unchanged; no data loss — action must be retried |
| OAuth token expired (401) | Hybrid Boundary redirect triggered | Session renewed; staff must re-submit the approval action |
| Concurrent edit conflict | Accounting Service returns 409 (if implemented) | Error displayed; staff must refresh and re-submit |

## Sequence Diagram

```
FinanceStaff -> continuumBlingWebApp: Click Approve/Reject on invoice detail
continuumBlingWebApp -> blingNginx: PATCH /api/v1/invoices/:id {status: "approved"}
blingNginx -> continuumAccountingService: PATCH /api/v1/invoices/:id (proxied, Bearer token)
continuumAccountingService --> blingNginx: 200 OK, updated invoice JSON
blingNginx --> continuumBlingWebApp: 200 OK, updated invoice JSON
continuumBlingWebApp --> FinanceStaff: Render updated invoice status
```

## Related

- Architecture dynamic view: `dynamic-finance-operations-flow`
- Related flows: [Finance Data Viewing](finance-data-viewing.md), [Contract Management](contract-management.md)
