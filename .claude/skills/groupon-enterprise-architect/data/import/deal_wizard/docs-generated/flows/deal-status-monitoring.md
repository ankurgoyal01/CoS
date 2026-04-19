---
service: "deal_wizard"
title: "Deal Status Monitoring"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-status-monitoring"
flow_type: synchronous
trigger: "Sales representative or admin requests deal adoption rate or outstanding voucher data"
participants:
  - "dealWizardWebUi"
  - "salesforceClient"
  - "salesForce"
architecture_ref: "dynamic-dealStatusMonitoring"
---

# Deal Status Monitoring

## Summary

The Deal Status Monitoring flow provides sales representatives and admins with operational visibility into deal performance metrics. It exposes two read-only reporting endpoints: `/api/v1/adoption_rate` for deal uptake metrics and `/api/v1/outstanding_vouchers` for unredeemed voucher counts. Adoption rate data is sourced from Salesforce; outstanding voucher data may combine Salesforce and internal records. The admin dashboard at `/admin/dashboard` aggregates these metrics alongside Salesforce error counts from `/admin/salesforce_errors`.

## Trigger

- **Type**: api-call (user-action via browser or programmatic API call)
- **Source**: Sales representative or admin requests a status report; may also be polled by internal dashboards
- **Frequency**: On-demand; per reporting request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative / Admin (User) | Requests deal metrics or reviews admin dashboard | — |
| Deal Wizard Web UI | Handles reporting requests; aggregates data for display | `dealWizardWebUi` |
| Salesforce Client | Queries Salesforce for deal adoption and voucher data | `salesforceClient` |
| Salesforce | Source of deal status, adoption, and voucher records | `salesForce` |

## Steps

1. **Receive Monitoring Request**: Web UI receives a request for adoption rate, outstanding vouchers, or admin dashboard.
   - From: `Sales Representative / Admin`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS / `GET /api/v1/adoption_rate` or `GET /api/v1/outstanding_vouchers` or `GET /admin/dashboard`

2. **Query Salesforce for Deal Status** (adoption rate path): Salesforce Client queries Salesforce Opportunities for deal status and adoption metrics.
   - From: `dealWizardWebUi` via `salesforceClient`
   - To: `salesForce`
   - Protocol: REST / APEX API (SOQL query)

3. **Query Salesforce for Voucher Data** (outstanding vouchers path): Salesforce Client queries Salesforce for voucher issuance and redemption records.
   - From: `dealWizardWebUi` via `salesforceClient`
   - To: `salesForce`
   - Protocol: REST / APEX API (SOQL query)

4. **Aggregate Admin Dashboard Data** (admin dashboard path): Web UI combines deal creation metrics from MySQL, Salesforce error counts, and approval status data.
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`) + Salesforce error log
   - Protocol: Direct (ActiveRecord) + Salesforce query

5. **Return Metrics**: Web UI formats and returns the requested metrics as JSON (for API endpoints) or renders the admin dashboard HTML.
   - From: `dealWizardWebUi`
   - To: `Sales Representative / Admin`
   - Protocol: HTTPS response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce unavailable | HTTP error returned from reporting endpoint | Adoption rate and voucher data not available; error displayed |
| Salesforce query timeout | Request times out; error returned | Metrics not available; sales rep must retry |
| MySQL unavailable (admin dashboard) | Admin dashboard partially rendered with Salesforce-only data | Local metrics unavailable; Salesforce data displayed if Salesforce is available |

## Sequence Diagram

```
Sales Rep -> dealWizardWebUi: GET /api/v1/adoption_rate
dealWizardWebUi -> salesforceClient: Fetch adoption metrics
salesforceClient -> salesForce: SOQL: SELECT ... FROM Opportunity WHERE ...
salesForce --> salesforceClient: Opportunity records with adoption data
salesforceClient --> dealWizardWebUi: Adoption rate data
dealWizardWebUi --> Sales Rep: JSON { adoption_rate: ... }

Admin -> dealWizardWebUi: GET /admin/dashboard
dealWizardWebUi -> MySQL: SELECT counts FROM deals, delayed_jobs
dealWizardWebUi -> salesforceClient: Fetch Salesforce error summary
salesforceClient -> salesForce: Query error records
salesForce --> salesforceClient: Error summary
dealWizardWebUi --> Admin: Render admin dashboard HTML
```

## Related

- Architecture dynamic view: `dynamic-dealStatusMonitoring`
- Related flows: [Deal Approval & Submission](deal-approval-and-submission.md), [Deal Inventory Allocation](deal-inventory-allocation.md)
