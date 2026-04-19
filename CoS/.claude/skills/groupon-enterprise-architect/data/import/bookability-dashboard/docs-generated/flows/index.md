---
service: "bookability-dashboard"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Bookability Dashboard (ConDash).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [User Authentication](user-authentication.md) | synchronous | User accesses dashboard in browser | Internal employee login via Doorman/OKTA OAuth redirect; role verification via Universal Merchant API |
| [Dashboard Data Load](dashboard-data-load.md) | synchronous | Initial page load or manual refresh | Discovers active partners, fetches merchant/deal/health-check data in parallel, enriches and caches all data |
| [Deal Health Check Monitoring](deal-health-check-monitoring.md) | synchronous | User views deal detail or deals overview | Fetches paginated health-check logs from Partner Service using parallel batch fetching via Web Worker |
| [Deal Investigation Workflow](deal-investigation-workflow.md) | synchronous | User acknowledges, categorizes, or resolves a deal issue | Creates or updates deal investigation records in Partner Service with status and issue category |
| [Dashboard Reports and Export](dashboard-reports-export.md) | synchronous | User navigates to Reports view or clicks CSV export | Fetches time-to-bookability aggregated metrics; optionally exports merchant/deal data to CSV |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The **Dashboard Data Load** flow crosses `continuumBookabilityDashboardWeb` → `apiProxy` → `continuumPartnerService`. This is captured in the Structurizr dynamic view: `dynamic-bookability-dashboard-data-fetch`.

The **User Authentication** flow crosses `continuumBookabilityDashboardWeb` → `continuumUniversalMerchantApi` via OAuth redirect (also modeled in `dynamic-bookability-dashboard-data-fetch`).
