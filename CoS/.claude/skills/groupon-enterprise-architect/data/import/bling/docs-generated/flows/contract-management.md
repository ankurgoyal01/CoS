---
service: "bling"
title: "Contract Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "contract-management"
flow_type: synchronous
trigger: "User navigates to a contract detail view or edits contract line items"
participants:
  - "continuumBlingWebApp"
  - "blingNginx"
  - "continuumAccountingService"
architecture_ref: "dynamic-finance-operations-flow"
---

# Contract Management

## Summary

This flow covers how finance and accounting staff view and update contract records in bling. The SPA fetches contract detail and associated line items from the Accounting Service v1 API, renders them in the Contract Module using `ember-table`, and allows staff to update contract records via PATCH. Contract data in bling may originate from Salesforce (surfaced through the Accounting Service); bling does not contact Salesforce directly.

## Trigger

- **Type**: user-action
- **Source**: Finance or accounting staff member navigates to a contract detail view or submits an edit to contract or line item data
- **Frequency**: On-demand; per user navigation or edit action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance/Accounting Staff | Navigates to contract views; submits edits | — |
| bling Web Application | Renders contract and line item views; issues GET and PATCH requests | `continuumBlingWebApp` |
| bling Nginx | Proxies `/api/v1/contracts/*` requests to Accounting Service | `blingNginx` |
| Accounting Service | Returns contract data; persists contract updates | `continuumAccountingService` |
| Salesforce (indirect) | Source of record for contract and account data; surfaced via Accounting Service | `salesForce` |

## Steps

1. **Navigates to contract list**: Staff navigates to the contracts section; Ember route model hook fires `GET /api/v1/contracts`.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP GET with `Authorization: Bearer <okta_token>`

2. **Nginx proxies request**: `blingNginx` forwards `GET /api/v1/contracts` to the Accounting Service.
   - From: `blingNginx`
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP GET

3. **Accounting Service returns contract list**: Returns JSON array of contract records (which may include Salesforce-originated data).
   - From: `continuumAccountingService`
   - To: `continuumBlingWebApp` (via `blingNginx`)
   - Protocol: REST/HTTP JSON

4. **Staff navigates to contract detail**: Staff clicks a contract to open its detail view; Ember fires `GET /api/v1/contracts/:id`.
   - From: `continuumBlingWebApp`
   - To: `continuumAccountingService` (via `blingNginx`)
   - Protocol: REST/HTTP GET

5. **Ember fetches line items**: The Contract Module also fetches the contract's line items via `GET /api/v1/contracts/:id/line_items`.
   - From: `continuumBlingWebApp`
   - To: `continuumAccountingService` (via `blingNginx`)
   - Protocol: REST/HTTP GET

6. **Accounting Service returns contract detail and line items**: Returns contract record and associated line item array.
   - From: `continuumAccountingService`
   - To: `continuumBlingWebApp` (via `blingNginx`)
   - Protocol: REST/HTTP JSON

7. **Staff submits contract update (optional)**: If staff edits contract data, the Ember component issues `PATCH /api/v1/contracts/:id` with the updated fields.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP PATCH `Content-Type: application/json`

8. **Nginx proxies PATCH to Accounting Service**: `blingNginx` forwards the PATCH to the Accounting Service.
   - From: `blingNginx`
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP PATCH with Bearer token

9. **Accounting Service validates and persists update**: Accounting Service applies the change and returns the updated contract record.
   - From: `continuumAccountingService`
   - To: `continuumBlingWebApp` (via `blingNginx`)
   - Protocol: REST/HTTP JSON 200

10. **SPA renders updated contract**: Contract Module re-renders with the latest data.
    - From: `continuumBlingWebApp`
    - To: Browser (user)
    - Protocol: Browser DOM update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Accounting Service returns 404 for contract | ember-ajax rejects; error route rendered | Staff sees "not found" error; no data displayed |
| Accounting Service returns 422 on PATCH | ember-ajax rejects; validation error shown | Update not persisted; staff sees field-level error feedback |
| Salesforce sync delay | Accounting Service returns stale or incomplete contract data | Staff sees out-of-date contract data; no bling-level error — Accounting Service is source of truth |
| Nginx 502/503 | All requests fail; error state in SPA | No contract data available; staff cannot perform operations |

## Sequence Diagram

```
FinanceStaff -> continuumBlingWebApp: Navigate to contract detail
continuumBlingWebApp -> blingNginx: GET /api/v1/contracts/:id
blingNginx -> continuumAccountingService: GET /api/v1/contracts/:id (proxied)
continuumAccountingService --> blingNginx: 200 OK, contract JSON
blingNginx --> continuumBlingWebApp: 200 OK, contract JSON
continuumBlingWebApp -> blingNginx: GET /api/v1/contracts/:id/line_items
blingNginx -> continuumAccountingService: GET /api/v1/contracts/:id/line_items (proxied)
continuumAccountingService --> blingNginx: 200 OK, line items JSON
blingNginx --> continuumBlingWebApp: 200 OK, line items JSON
continuumBlingWebApp --> FinanceStaff: Render contract detail and line items
FinanceStaff -> continuumBlingWebApp: Submit contract edit
continuumBlingWebApp -> blingNginx: PATCH /api/v1/contracts/:id {updated fields}
blingNginx -> continuumAccountingService: PATCH /api/v1/contracts/:id (proxied)
continuumAccountingService --> blingNginx: 200 OK, updated contract JSON
blingNginx --> continuumBlingWebApp: 200 OK, updated contract JSON
continuumBlingWebApp --> FinanceStaff: Render updated contract
```

## Related

- Architecture dynamic view: `dynamic-finance-operations-flow`
- Related flows: [Finance Data Viewing](finance-data-viewing.md), [Invoice Approval](invoice-approval.md)
