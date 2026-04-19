---
service: "checkout-flow-analyzer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Checkout Flow Analyzer.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [User Authentication](user-authentication.md) | synchronous | User navigates to a protected page or `/login` | Redirects unauthenticated users to Okta, validates the OIDC token, and grants access to the application |
| [Time Window Selection](time-window-selection.md) | synchronous | User selects a date range from the home page time-window picker | Discovers available CSV/ZIP log archives, validates the selection, and stores the active time-window context |
| [Session List Loading](session-list-loading.md) | synchronous | User lands on `/sessions` or applies a filter | Reads session data from the bcookie_summary or PWA log file, filters, paginates, and renders the session table |
| [Session Detail Analysis](session-detail-analysis.md) | synchronous | User clicks a bCookie in the session list | Loads correlated PWA, proxy, Lazlo, and orders log rows for a single browser session and renders the event timeline |
| [Conversion Rate and Platform Metrics](conversion-rate-metrics.md) | synchronous | User navigates to `/top-stats` | Scans PWA log events to compute conversion funnel rates and device platform distribution for the selected time window |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The session analysis flow spans the `continuumCheckoutFlowAnalyzerApp` container and the `continuumCheckoutFlowAnalyzerCsvDataFiles` store, as documented in the Structurizr dynamic view `dynamic-continuumSystem-sessionAnalysisFlow`. Authentication extends to the external Okta Identity Cloud system (represented as the `oktaIdentityCloud` stub in the architecture model).
